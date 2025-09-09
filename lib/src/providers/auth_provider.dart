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

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get userData => _userData;

  AuthProvider() {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
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
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.login(email, password);
      _isAuthenticated = true;
      await _loadUserData(); // Cargar los datos del usuario después del login
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
      _userData = null;
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

  // Método para manejar sesión expirada
  Future<void> handleSessionExpired() async {
    developer.log('🔄 Manejando sesión expirada...');
    
    // Limpiar el estado de autenticación
    _isAuthenticated = false;
    _userData = null;
    _error = null;
    
    // Notificar a los listeners
    notifyListeners();
    
    // El logout ya se realizó en el ApiService, solo necesitamos limpiar el estado local
    developer.log('✅ Sesión expirada manejada correctamente');
  }

  // Obtener las sucursales disponibles del usuario
  Future<List<Map<String, dynamic>>> getSucursalesDisponibles() async {
    try {
      return await _authService.getSucursalesDisponibles();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Cambiar la sucursal activa del usuario
  Future<bool> cambiarSucursal(String idSucursal) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.cambiarSucursal(idSucursal);
      
      // Recargar los datos del usuario para reflejar el cambio
      await _loadUserData();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
} 