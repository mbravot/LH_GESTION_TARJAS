import 'package:flutter/foundation.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';
import 'session_handler_mixin.dart';
import 'notification_provider.dart';

class UsuarioProvider extends ChangeNotifier with SessionHandlerMixin {
  List<Usuario> _usuarios = [];
  List<Permiso> _permisosDisponibles = [];
  List<Map<String, dynamic>> _sucursales = [];
  bool _isLoading = false;
  String? _error;
  AuthProvider? _authProvider;
  NotificationProvider? _notificationProvider;

  // Filtros
  String _filtroBusqueda = '';
  String _filtroSucursal = '';
  String _filtroEstado = 'todos';

  // Getters
  List<Usuario> get usuarios => _usuarios;
  List<Permiso> get permisosDisponibles => _permisosDisponibles;
  List<Map<String, dynamic>> get sucursales => _sucursales;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Getters para filtros
  String get filtroBusqueda => _filtroBusqueda;
  String get filtroSucursal => _filtroSucursal;
  String get filtroEstado => _filtroEstado;

  // Usuarios filtrados
  List<Usuario> get usuariosFiltrados {
    return _usuarios.where((usuario) {
      // Filtro por búsqueda
      if (_filtroBusqueda.isNotEmpty) {
        final busqueda = _filtroBusqueda.toLowerCase();
        if (!usuario.nombreCompletoDisplay.toLowerCase().contains(busqueda) &&
            !usuario.usuario.toLowerCase().contains(busqueda) &&
            !usuario.correo.toLowerCase().contains(busqueda)) {
          return false;
        }
      }

      // Filtro por sucursal
      if (_filtroSucursal.isNotEmpty) {
        if (usuario.idSucursalActiva.toString() != _filtroSucursal) {
          return false;
        }
      }

      // Filtro por estado
      if (_filtroEstado != 'todos') {
        if (usuario.idEstado.toString() != _filtroEstado) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // Inicializar provider
  void initialize(AuthProvider authProvider, NotificationProvider notificationProvider) {
    _authProvider = authProvider;
    _notificationProvider = notificationProvider;
    _authProvider!.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    // Solo limpiar cache, no cargar datos automáticamente
    if (_authProvider!.isAuthenticated) {
      // Los datos se cargarán cuando el usuario navegue a la pantalla
      _usuarios = [];
      _sucursales = [];
      notifyListeners();
    }
  }

  // Cargar usuarios
  Future<void> cargarUsuarios() async {
    // Si ya hay datos, no recargar
    if (_usuarios.isNotEmpty && !_isLoading) {
      print('UsuarioProvider: Usuarios ya cargados, saltando carga...');
      return;
    }

    // Si ya está cargando, no hacer nada
    if (_isLoading) {
      print('UsuarioProvider: Ya está cargando usuarios...');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('UsuarioProvider: Intentando cargar usuarios...');
      final result = await handleApiError(
        () => ApiService.obtenerUsuarios(),
        _authProvider!,
        _notificationProvider,
      );

      if (result != null) {
        _usuarios = result.map((json) => Usuario.fromJson(json)).toList();
        _error = null;
      }
    } catch (e) {
      _error = e.toString();
      _usuarios = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Cargar permisos disponibles
  Future<void> cargarPermisosDisponibles() async {
    // Si ya hay datos, no recargar
    if (_permisosDisponibles.isNotEmpty) {
      print('UsuarioProvider: Permisos ya cargados, saltando carga...');
      return;
    }

    try {
      final result = await handleApiError(
        () => ApiService.obtenerPermisosDisponibles(),
        _authProvider!,
        _notificationProvider,
      );

      if (result != null) {
        _permisosDisponibles = result.map((json) => Permiso.fromJson(json)).toList();
      }
    } catch (e) {
      _permisosDisponibles = [];
    }
  }

  // Cargar sucursales disponibles
  Future<void> cargarSucursales() async {
    // Si ya hay datos, no recargar
    if (_sucursales.isNotEmpty) {
      print('UsuarioProvider: Sucursales ya cargadas, saltando carga...');
      return;
    }

    try {
      print('UsuarioProvider: Cargando sucursales...');
      final result = await handleApiError(
        () => ApiService.obtenerSucursales(),
        _authProvider!,
        _notificationProvider,
      );

      if (result != null) {
        _sucursales = result;
        print('UsuarioProvider: Sucursales cargadas: ${_sucursales.length}');
      }
    } catch (e) {
      print('UsuarioProvider: Error al cargar sucursales: $e');
      _sucursales = [];
    }
    notifyListeners();
  }

  // Cargar sucursales de un usuario específico
  Future<List<Map<String, dynamic>>> cargarSucursalesUsuario(String usuarioId) async {
    try {
      print('UsuarioProvider: Cargando sucursales del usuario $usuarioId...');
      final result = await handleApiError(
        () => ApiService.obtenerSucursalesUsuario(usuarioId),
        _authProvider!,
        _notificationProvider,
      );

      if (result != null) {
        final List<dynamic> sucursales = result['sucursales'] ?? [];
        print('UsuarioProvider: Sucursales del usuario cargadas: ${sucursales.length}');
        return sucursales.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('UsuarioProvider: Error al cargar sucursales del usuario: $e');
      _notificationProvider?.showErrorMessage('Error al cargar sucursales del usuario: $e');
      return [];
    }
  }

  // Crear usuario
  Future<bool> crearUsuario(Usuario usuario, String clave) async {
    try {
      final result = await handleApiError(
        () => ApiService.crearUsuario(usuario.toCreateJson(clave: clave)),
        _authProvider!,
        _notificationProvider,
      );

      if (result != null) {
        await cargarUsuarios();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Actualizar usuario
  Future<bool> actualizarUsuario(Usuario usuario) async {
    try {
      final updateData = usuario.toUpdateJson();
      print('UsuarioProvider: Datos de actualización: $updateData');
      print('UsuarioProvider: ID del usuario: ${usuario.id}');
      
      final result = await handleApiError(
        () => ApiService.actualizarUsuario(usuario.id, updateData),
        _authProvider!,
        _notificationProvider,
      );

      if (result != null) {
        await cargarUsuarios();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Eliminar usuario
  Future<bool> eliminarUsuario(String usuarioId) async {
    try {
      await handleApiError(
        () => ApiService.eliminarUsuario(usuarioId),
        _authProvider!,
        _notificationProvider,
      );

      await cargarUsuarios();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Obtener permisos de un usuario
  Future<UsuarioPermisos?> obtenerPermisosUsuario(String usuarioId) async {
    try {
      print('UsuarioProvider: Obteniendo permisos del usuario $usuarioId...');
      final result = await handleApiError(
        () => ApiService.obtenerPermisosUsuarioEspecifico(usuarioId),
        _authProvider!,
        _notificationProvider,
      );

      if (result != null) {
        print('UsuarioProvider: Permisos del usuario obtenidos: $result');
        return UsuarioPermisos.fromJson(result);
      }
      return null;
    } catch (e) {
      print('UsuarioProvider: Error al obtener permisos del usuario: $e');
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Métodos para filtros
  void setFiltroBusqueda(String value) {
    _filtroBusqueda = value;
    notifyListeners();
  }

  void setFiltroSucursal(String value) {
    _filtroSucursal = value;
    notifyListeners();
  }

  void setFiltroEstado(String value) {
    print('UsuarioProvider: Estableciendo filtro de estado: $value');
    _filtroEstado = value;
    notifyListeners();
    print('UsuarioProvider: Filtro establecido. Total usuarios filtrados: ${usuariosFiltrados.length}');
  }

  void limpiarFiltros() {
    _filtroBusqueda = '';
    _filtroSucursal = '';
    _filtroEstado = 'todos';
    notifyListeners();
  }

  // Limpiar error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Desactivar usuario
  Future<bool> desactivarUsuario(String usuarioId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.desactivarUsuario(usuarioId);
      await cargarUsuarios(); // Recargar la lista
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Activar usuario
  Future<bool> activarUsuario(String usuarioId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.activarUsuario(usuarioId);
      await cargarUsuarios(); // Recargar la lista
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authProvider?.removeListener(_onAuthChanged);
    super.dispose();
  }
}
