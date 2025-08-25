import 'package:flutter/material.dart';
import '../models/permiso.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class PermisoProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  AuthProvider? _authProvider;
  
  List<Permiso> _permisos = [];
  List<Permiso> _permisosFiltrados = [];
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _tiposPermiso = [];
  List<Map<String, dynamic>> _estadosPermiso = [];
  
  // Variables para filtros
  String _filtroBusqueda = '';
  String _filtroEstado = '';
  String _filtroTipo = '';

  // Getters
  List<Permiso> get permisos => _permisos;
  List<Permiso> get permisosFiltrados => _permisosFiltrados;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get tiposPermiso => _tiposPermiso;
  List<Map<String, dynamic>> get estadosPermiso => _estadosPermiso;
  
  // Getters para filtros
  String get filtroBusqueda => _filtroBusqueda;
  String get filtroEstado => _filtroEstado;
  String get filtroTipo => _filtroTipo;

  // Método para configurar el AuthProvider
  void setAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;
    // Escuchar cambios en la sucursal activa
    _authProvider!.addListener(_onSucursalChanged);
  }

  // Método para manejar cambios de sucursal
  void _onSucursalChanged() {
    if (_authProvider != null) {
      cargarPermisos();
    }
  }

  @override
  void dispose() {
    if (_authProvider != null) {
      _authProvider!.removeListener(_onSucursalChanged);
    }
    super.dispose();
  }

  // Método para inicializar (cargar permisos y tipos)
  Future<void> inicializar() async {
    await Future.wait([
      cargarPermisos(),
      cargarTiposPermiso(),
      cargarEstadosPermiso(),
    ]);
  }

  // Método para cargar permisos
  Future<void> cargarPermisos() async {
    _setLoading(true);
    _error = null;
    
    try {
      final response = await _apiService.obtenerPermisos();
      _permisos = response.map((json) => Permiso.fromJson(json)).toList();
      _aplicarFiltros();
      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  // Método para cargar tipos de permiso
  Future<void> cargarTiposPermiso() async {
    try {
      final response = await _apiService.obtenerTiposPermiso();
      _tiposPermiso = response;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Método para cargar estados de permiso
  Future<void> cargarEstadosPermiso() async {
    try {
      final response = await _apiService.obtenerEstadosPermiso();
      _estadosPermiso = response;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Método para crear permiso
  Future<bool> crearPermiso(Map<String, dynamic> datos) async {
    _setLoading(true);
    _error = null;
    
    try {
      await _apiService.crearPermiso(datos);
      await cargarPermisos(); // Recargar la lista
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Método para editar permiso
  Future<bool> editarPermiso(String permisoId, Map<String, dynamic> datos) async {
    _setLoading(true);
    _error = null;
    
    try {
      await _apiService.editarPermiso(permisoId, datos);
      await cargarPermisos(); // Recargar la lista
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Método para eliminar permiso
  Future<bool> eliminarPermiso(String permisoId) async {
    _setLoading(true);
    _error = null;
    
    try {
      await _apiService.eliminarPermiso(permisoId);
      await cargarPermisos(); // Recargar la lista
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Método para obtener permiso por ID
  Future<Permiso?> obtenerPermisoPorId(String permisoId) async {
    try {
      final response = await _apiService.obtenerPermisoPorId(permisoId);
      return Permiso.fromJson(response);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Método para establecer filtro de búsqueda
  void setFiltroBusqueda(String query) {
    _filtroBusqueda = query;
    _aplicarFiltros();
  }

  // Método para establecer filtro de estado
  void setFiltroEstado(String estado) {
    _filtroEstado = estado;
    _aplicarFiltros();
  }

  // Método para establecer filtro de tipo
  void setFiltroTipo(String tipo) {
    _filtroTipo = tipo;
    _aplicarFiltros();
  }

  // Método para aplicar todos los filtros
  void _aplicarFiltros() {
    List<Permiso> filtrados = List.from(_permisos);

    // Aplicar filtro de búsqueda
    if (_filtroBusqueda.isNotEmpty) {
      filtrados = filtrados.where((permiso) {
        final nombreCompleto = permiso.nombreCompletoColaborador.toLowerCase();
        final tipoPermiso = (permiso.tipoPermiso ?? '').toLowerCase();
        final estadoPermiso = (permiso.estadoPermiso ?? '').toLowerCase();
        final fecha = permiso.fechaFormateadaEspanol.toLowerCase();
        
        return nombreCompleto.contains(_filtroBusqueda.toLowerCase()) ||
               tipoPermiso.contains(_filtroBusqueda.toLowerCase()) ||
               estadoPermiso.contains(_filtroBusqueda.toLowerCase()) ||
               fecha.contains(_filtroBusqueda.toLowerCase());
      }).toList();
    }

    // Aplicar filtro de estado
    if (_filtroEstado.isNotEmpty && _filtroEstado != 'todos') {
      filtrados = filtrados.where((permiso) {
        return permiso.estado == _filtroEstado;
      }).toList();
    }

    // Aplicar filtro de tipo
    if (_filtroTipo.isNotEmpty) {
      filtrados = filtrados.where((permiso) {
        return permiso.tipoPermiso == _filtroTipo;
      }).toList();
    }

    _permisosFiltrados = filtrados;
    notifyListeners();
  }

  // Método para filtrar permisos (mantener compatibilidad)
  void filtrarPermisos(String query) {
    setFiltroBusqueda(query);
  }

  // Método para filtrar por estado (mantener compatibilidad)
  void filtrarPorEstado(String estado) {
    setFiltroEstado(estado);
  }

  // Método para filtrar por tipo de permiso (mantener compatibilidad)
  void filtrarPorTipo(String tipoPermiso) {
    setFiltroTipo(tipoPermiso);
  }

  // Método para limpiar filtros
  void limpiarFiltros() {
    _filtroBusqueda = '';
    _filtroEstado = '';
    _filtroTipo = '';
    _permisosFiltrados = List.from(_permisos);
    notifyListeners();
  }

  // Método para obtener estadísticas
  Map<String, int> get estadisticas {
    final creados = _permisos.where((p) => p.estado == 'Creado').length;
    final aprobados = _permisos.where((p) => p.estado == 'Aprobado').length;
    // Los permisos "Por Aprobar" son los mismos que "Creado" pero para aprobación
    final porAprobar = _permisos.where((p) => p.estado == 'Creado').length;
    final total = _permisos.length;

    return {
      'creados': creados,
      'aprobados': aprobados,
      'porAprobar': porAprobar,
      'total': total,
    };
  }

  // Método para obtener tipos de permiso únicos
  List<String> get tiposPermisoUnicos {
    final tipos = _permisos
        .map((p) => p.tipoPermiso)
        .where((tipo) => tipo != null && tipo.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    tipos.sort();
    return tipos;
  }

  // Método para obtener estados únicos
  List<String> get estadosUnicos {
    final estados = _permisos
        .map((p) => p.estado)
        .where((estado) => estado.isNotEmpty)
        .toSet()
        .toList();
    estados.sort();
    return estados;
  }

  // Método privado para establecer loading
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Método para limpiar error
  void limpiarError() {
    _error = null;
    notifyListeners();
  }

  // Método para aprobar permiso
  Future<Map<String, dynamic>?> aprobarPermiso(String id) async {
    try {
      final response = await ApiService.aprobarPermiso(id);
      await cargarPermisos(); // Recargar la lista
      return response;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
