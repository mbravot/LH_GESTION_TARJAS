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
    _userData = await _authService.getCurrentUser();
    _isAuthenticated = _userData != null;
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

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _loadUserData();
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
      _userData = null;
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