import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:developer' as developer;
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final _storage = const FlutterSecureStorage();
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;
  Map<String, dynamic>? _userData;
  
  // Cache de sucursales para evitar llamadas repetidas
  List<Map<String, dynamic>>? _cachedSucursales;
  DateTime? _sucursalesCacheTime;
  static const Duration _cacheExpiration = Duration(minutes: 5);
  
  // Control para evitar notificaciones múltiples durante cambio de sucursal
  bool isChangingSucursal = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get userData => _userData;

  AuthProvider() {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final startTime = DateTime.now();
    
    try {
      _userData = await _authService.getCurrentUser();
      
      if (_userData != null) {
        // Validar que el token siga siendo válido haciendo una petición de prueba
        final isValid = await _authService.validateToken();
        
        if (isValid) {
          _isAuthenticated = true;
        } else {
          // Token expirado, limpiar datos
          _isAuthenticated = false;
          _userData = null;
          await _authService.logout();
        }
      } else {
        _isAuthenticated = false;
      }
    } catch (e) {
      // Si hay error al validar, asumir que la sesión expiró
      _isAuthenticated = false;
      _userData = null;
      await _authService.logout();
    }
    
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    final startTime = DateTime.now();
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔄 [AuthProvider] Iniciando login para: $email');
      final response = await _authService.login(email, password);
      _isAuthenticated = true;
      
      print('🔄 [AuthProvider] Obteniendo datos del usuario...');
      // Cargar solo los datos básicos del usuario sin validación adicional
      _userData = await _authService.getCurrentUser();
      
      _isLoading = false;
      notifyListeners();
      
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      print('✅ [AuthProvider] Login exitoso en ${duration.inMilliseconds}ms');
      
      return true;
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
      _userData = null;
      final duration = DateTime.now().difference(startTime);
      print('❌ [AuthProvider] Error en login: $e (${duration.inMilliseconds}ms)');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _authService.logout();
      
      // Limpiar cache de sucursales
      _cachedSucursales = null;
      _sucursalesCacheTime = null;
      
      _isAuthenticated = false;
      _userData = null;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método para manejar sesión expirada automáticamente
  Future<void> handleSessionExpired() async {
    developer.log('🔐 Manejando sesión expirada automáticamente...');
    
    try {
      await _authService.logout();
      _isAuthenticated = false;
      _userData = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      developer.log('Error al manejar sesión expirada: $e');
    }
  }

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Verificar si hay un token almacenado
      final token = await getToken();
      if (token == null) {
        _isAuthenticated = false;
        _userData = null;
        return;
      }

      // Intentar cargar los datos del usuario para verificar si el token es válido
      await _loadUserData();
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
      _userData = null;
      
      // Si hay error, limpiar el token inválido
      try {
        await _authService.logout();
      } catch (logoutError) {
        // Ignorar errores del logout
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    if (_userData == null) {
      await _loadUserData();
    }
    return _userData;
  }

  Future<String?> getToken() async {
    return await _authService.getToken();
  }

  // Verificar si el token actual es válido
  Future<bool> isTokenValid() async {
    try {
      final token = await getToken();
      if (token == null) return false;
      
      // Intentar hacer una llamada simple al servidor para verificar el token
      await _loadUserData();
      return true;
    } catch (e) {
      return false;
    }
  }


  // Obtener las sucursales disponibles del usuario
  Future<List<Map<String, dynamic>>> getSucursalesDisponibles() async {
    // Verificar si tenemos cache válido
    if (_cachedSucursales != null && 
        _sucursalesCacheTime != null && 
        DateTime.now().difference(_sucursalesCacheTime!) < _cacheExpiration) {
      return _cachedSucursales!;
    }
    
    try {
      final sucursales = await _authService.getSucursalesDisponibles();
      
      // Actualizar cache
      _cachedSucursales = sucursales;
      _sucursalesCacheTime = DateTime.now();
      
      return sucursales;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Cambiar la sucursal activa del usuario
  Future<bool> cambiarSucursal(String idSucursal) async {
    final startTime = DateTime.now();
    
    // Marcar que estamos cambiando sucursal para evitar notificaciones múltiples
    isChangingSucursal = true;
    _isLoading = true;
    _error = null;

    try {
      print('🔄 [AuthProvider] Cambiando sucursal a: $idSucursal');
      final result = await _authService.cambiarSucursal(idSucursal);
      final resultStr = result.toString();
      
      // Actualizar datos del usuario directamente desde la respuesta (más rápido)
      if (result['sucursal_nombre'] != null) {
        if (_userData != null) {
          _userData!['id_sucursal'] = int.tryParse(idSucursal);
          _userData!['nombre_sucursal'] = result['sucursal_nombre'];
        }
      } else {
        print('🔄 [AuthProvider] Fallback: recargando datos completos del usuario...');
        // Fallback: recargar datos completos si no hay información en la respuesta
        await _loadUserData();
      }
      
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      print('✅ [AuthProvider] Cambio de sucursal exitoso en ${duration.inMilliseconds}ms');
      
      _isLoading = false;
      isChangingSucursal = false;
      // Notificar UNA SOLA VEZ al final
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      isChangingSucursal = false;
      notifyListeners();
      return false;
    }
  }
} 