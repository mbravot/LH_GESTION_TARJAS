import 'package:flutter/material.dart';
import '../models/trabajador.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class TrabajadorProvider extends ChangeNotifier {
  List<Trabajador> _trabajadores = [];
  bool _isLoading = false;
  String? _error;
  AuthProvider? _authProvider;
  String? _filtroContratista;
  String _filtroEstado = 'todos';
  String _filtroBusqueda = '';
  String? _filtroPorcentaje;

  List<Trabajador> get trabajadores => _trabajadores;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get filtroContratista => _filtroContratista;
  String get filtroEstado => _filtroEstado;
  String get filtroBusqueda => _filtroBusqueda;
  String? get filtroPorcentaje => _filtroPorcentaje;

  // Trabajadores filtrados
  List<Trabajador> get trabajadoresFiltrados {
    List<Trabajador> filtrados = _trabajadores;

    // Filtrar por contratista
    if (_filtroContratista != null && _filtroContratista!.isNotEmpty) {
      filtrados = filtrados.where((t) => t.nombreContratista == _filtroContratista).toList();
    }

    // Filtrar por estado
    if (_filtroEstado != 'todos') {
      filtrados = filtrados.where((t) => t.idEstado == _filtroEstado).toList();
    }

    // Filtrar por búsqueda
    if (_filtroBusqueda.isNotEmpty) {
      final busqueda = _filtroBusqueda.toLowerCase();
      filtrados = filtrados.where((t) {
        return t.nombreCompleto.toLowerCase().contains(busqueda) ||
               t.rutCompleto.toLowerCase().contains(busqueda) ||
               (t.nombreContratista?.toLowerCase().contains(busqueda) ?? false);
      }).toList();
    }

    // Filtrar por porcentaje
    if (_filtroPorcentaje != null && _filtroPorcentaje!.isNotEmpty) {
      filtrados = filtrados.where((t) {
        final porcentajeTrabajador = t.porcentajeFormateado;
        return porcentajeTrabajador == _filtroPorcentaje;
      }).toList();
    }

    return filtrados;
  }

  // Estadísticas - usar trabajadores filtrados si hay filtros activos
  int get totalTrabajadores {
    final trabajadores = _filtroBusqueda.isNotEmpty || _filtroContratista != null || _filtroPorcentaje != null 
        ? trabajadoresFiltrados 
        : _trabajadores;
    return trabajadores.length;
  }
  
  int get trabajadoresActivos {
    final trabajadores = _filtroBusqueda.isNotEmpty || _filtroContratista != null || _filtroPorcentaje != null 
        ? trabajadoresFiltrados 
        : _trabajadores;
    return trabajadores.where((t) => t.idEstado == '1').length;
  }
  
  int get trabajadoresInactivos {
    final trabajadores = _filtroBusqueda.isNotEmpty || _filtroContratista != null || _filtroPorcentaje != null 
        ? trabajadoresFiltrados 
        : _trabajadores;
    return trabajadores.where((t) => t.idEstado == '2').length;
  }

  void setAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;
    // Escuchar cambios en el AuthProvider para recargar trabajadores cuando cambie la sucursal
    _authProvider!.addListener(_onAuthChanged);
  }

  // Escuchar cambios en el AuthProvider
  void _onAuthChanged() {
    // Solo limpiar datos, no cargar automáticamente
    if (_authProvider?.userData != null) {
      _trabajadores = [];
      notifyListeners();
    }
  }

  // Cargar trabajadores
  Future<void> cargarTrabajadores() async {
    if (_authProvider == null) {
      _error = 'AuthProvider no configurado';
      notifyListeners();
      return;
    }

    // Si ya hay datos, no recargar
    if (_trabajadores.isNotEmpty && !_isLoading) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.obtenerTrabajadores();
      _trabajadores = data.map((json) => Trabajador.fromJson(json)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cargar trabajadores por contratista
  Future<void> cargarTrabajadoresPorContratista(String idContratista) async {
    if (_authProvider == null) {
      _error = 'AuthProvider no configurado';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.obtenerTrabajadores(idContratista: idContratista);
      _trabajadores = data.map((json) => Trabajador.fromJson(json)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Obtener trabajador por ID
  Future<Trabajador?> obtenerTrabajadorPorId(String id) async {
    try {
      final data = await ApiService.obtenerTrabajadorPorId(id);
      return Trabajador.fromJson(data);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Crear trabajador
  Future<bool> crearTrabajador(Map<String, dynamic> trabajadorData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.crearTrabajador(trabajadorData);
      await cargarTrabajadores(); // Recargar la lista
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

  // Editar trabajador
  Future<bool> editarTrabajador(String id, Map<String, dynamic> trabajadorData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.editarTrabajador(id, trabajadorData);
      await cargarTrabajadores(); // Recargar la lista
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



  // Desactivar trabajador
  Future<bool> desactivarTrabajador(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.desactivarTrabajador(id);
      await cargarTrabajadores(); // Recargar la lista
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

  // Activar trabajador
  Future<bool> activarTrabajador(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.activarTrabajador(id);
      await cargarTrabajadores(); // Recargar la lista
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

  // Filtros
  void setFiltroContratista(String? idContratista) {
    _filtroContratista = idContratista;
    notifyListeners();
  }

  void setFiltroEstado(String estado) {
    _filtroEstado = estado;
    notifyListeners();
  }

  void setFiltroBusqueda(String busqueda) {
    _filtroBusqueda = busqueda;
    notifyListeners();
  }

  void setFiltroPorcentaje(String? porcentaje) {
    _filtroPorcentaje = porcentaje;
    notifyListeners();
  }

  void limpiarFiltros() {
    _filtroContratista = null;
    _filtroEstado = 'todos';
    _filtroBusqueda = '';
    _filtroPorcentaje = null;
    notifyListeners();
  }

  // Obtener contratistas únicos
  List<String> get contratistasUnicos {
    final contratistas = _trabajadores
        .map((t) => t.nombreContratista)
        .where((c) => c != null && c.isNotEmpty)
        .cast<String>()
        .toSet();
    return contratistas.toList()..sort();
  }

  List<String> get porcentajesUnicos {
    final porcentajes = _trabajadores
        .map((t) => t.porcentajeFormateado)
        .toSet();
    return porcentajes.toList()..sort();
  }

  // Obtener trabajadores por contratista
  List<Trabajador> getTrabajadoresPorContratista(String idContratista) {
    return _trabajadores.where((t) => t.idContratista == idContratista).toList();
  }

  // Obtener trabajadores activos
  List<Trabajador> get trabajadoresActivosList {
    return _trabajadores.where((t) => t.idEstado == '1').toList();
  }

  // Obtener trabajadores inactivos
  List<Trabajador> get trabajadoresInactivosList {
    return _trabajadores.where((t) => t.idEstado == '2').toList();
  }

  @override
  void dispose() {
    _authProvider?.removeListener(_onAuthChanged);
    super.dispose();
  }
}
