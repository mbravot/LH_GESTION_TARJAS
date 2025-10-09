import 'package:flutter/material.dart';
import 'api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';

class DataManager {
  static final DataManager _instance = DataManager._internal();
  factory DataManager() => _instance;
  DataManager._internal();

  AuthProvider? _authProvider;
  NotificationProvider? _notificationProvider;
  
  // Cache de datos cargados
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiration = Duration(minutes: 5);

  void initialize(AuthProvider authProvider, NotificationProvider notificationProvider) {
    _authProvider = authProvider;
    _notificationProvider = notificationProvider;
  }

  // Cargar datos solo cuando se necesiten
  Future<T?> loadData<T>(String key, Future<T> Function() loader) async {
    // Verificar cache
    if (_cache.containsKey(key) && _isCacheValid(key)) {
      return _cache[key] as T?;
    }

    // Cargar datos
    try {
      final data = await loader();
      _cache[key] = data;
      _cacheTimestamps[key] = DateTime.now();
      return data;
    } catch (e) {
      print('Error cargando datos para $key: $e');
      return null;
    }
  }

  bool _isCacheValid(String key) {
    if (!_cacheTimestamps.containsKey(key)) return false;
    final timestamp = _cacheTimestamps[key]!;
    return DateTime.now().difference(timestamp) < _cacheExpiration;
  }

  // Limpiar cache cuando cambie la sucursal
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  // Cargar datos esenciales solo
  Future<void> loadEssentialData() async {
    if (_authProvider == null || !_authProvider!.isAuthenticated) return;

    // Solo cargar datos críticos para el dashboard
    await Future.wait([
      loadData('permisos', () => ApiService.obtenerPermisosUsuarioActual()),
      loadData('sucursales', () => ApiService.obtenerSucursalesUsuario()),
    ]);
  }

  // Cargar datos específicos bajo demanda
  Future<void> loadScreenData(String screenName) async {
    if (_authProvider == null || !_authProvider!.isAuthenticated) return;

    switch (screenName) {
      case 'usuarios':
        await loadData('usuarios', () => ApiService.obtenerUsuarios());
        break;
      case 'colaboradores':
        await loadData('colaboradores', () => ApiService.obtenerColaboradores());
        break;
      case 'trabajadores':
        await loadData('trabajadores', () => ApiService.obtenerTrabajadores());
        break;
      case 'licencias':
        await loadData('licencias', () => ApiService.obtenerLicencias());
        break;
      case 'vacaciones':
        await loadData('vacaciones', () => ApiService.obtenerVacaciones());
        break;
      case 'sueldos':
        await loadData('sueldos', () => ApiService.obtenerSueldosBase());
        break;
      // Agregar más pantallas según necesidad
    }
  }
}
