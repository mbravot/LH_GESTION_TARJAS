import 'package:flutter/material.dart';
import '../models/vacacion.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class VacacionProvider extends ChangeNotifier {
  List<Vacacion> _vacaciones = [];
  bool _isLoading = false;
  String? _error;
  AuthProvider? _authProvider;
  String _filtroEstado = 'todos';
  String _filtroBusqueda = '';
  String? _filtroColaborador;

  List<Vacacion> get vacaciones => _vacaciones;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filtroEstado => _filtroEstado;
  String get filtroBusqueda => _filtroBusqueda;
  String? get filtroColaborador => _filtroColaborador;

  // Vacaciones filtradas
  List<Vacacion> get vacacionesFiltradas {
    List<Vacacion> filtradas = _vacaciones;

    // Filtrar por estado
    if (_filtroEstado != 'todos') {
      filtradas = filtradas.where((v) => v.estado == _filtroEstado).toList();
    }

    // Filtrar por colaborador
    if (_filtroColaborador != null && _filtroColaborador!.isNotEmpty) {
      filtradas = filtradas.where((v) => v.idColaborador == _filtroColaborador).toList();
    }

    // Filtrar por búsqueda
    if (_filtroBusqueda.isNotEmpty) {
      final busqueda = _filtroBusqueda.toLowerCase();
      filtradas = filtradas.where((v) {
        return v.nombreCompletoColaborador.toLowerCase().contains(busqueda) ||
               v.periodoFormateado.toLowerCase().contains(busqueda);
      }).toList();
    }

    return filtradas;
  }

  // Estadísticas
  int get totalVacaciones => _vacaciones.length;
  int get vacacionesProgramadas => _vacaciones.where((v) => v.estado == 'Programada').length;
  int get vacacionesEnCurso => _vacaciones.where((v) => v.estado == 'En curso').length;
  int get vacacionesCompletadas => _vacaciones.where((v) => v.estado == 'Completada').length;

  void setAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;
    // Escuchar cambios en el AuthProvider para recargar vacaciones cuando cambie la sucursal
    _authProvider!.addListener(_onAuthChanged);
  }

  // Escuchar cambios en el AuthProvider
  void _onAuthChanged() {
    // Recargar vacaciones cuando cambie la sucursal
    if (_authProvider?.userData != null) {
      cargarVacaciones();
    }
  }

  // Cargar vacaciones
  Future<void> cargarVacaciones({String? idColaborador}) async {
    if (_authProvider == null) {
      _error = 'AuthProvider no configurado';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.obtenerVacaciones(idColaborador: idColaborador);
      _vacaciones = data.map((json) => Vacacion.fromJson(json)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Crear vacación
  Future<bool> crearVacacion(Map<String, dynamic> vacacionData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.crearVacacion(vacacionData);
      await cargarVacaciones(); // Recargar la lista
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

  // Obtener vacación por ID
  Future<Vacacion?> obtenerVacacionPorId(String id) async {
    try {
      final data = await ApiService.obtenerVacacionPorId(id);
      return Vacacion.fromJson(data);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Editar vacación
  Future<bool> editarVacacion(String id, Map<String, dynamic> vacacionData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.editarVacacion(id, vacacionData);
      await cargarVacaciones(); // Recargar la lista
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

  // Eliminar vacación
  Future<bool> eliminarVacacion(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.eliminarVacacion(id);
      await cargarVacaciones(); // Recargar la lista
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

  // Obtener vacaciones de un colaborador específico
  Future<List<Vacacion>> obtenerVacacionesColaborador(String colaboradorId) async {
    try {
      final data = await ApiService.obtenerVacacionesColaborador(colaboradorId);
      return data.map((json) => Vacacion.fromJson(json)).toList();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Filtros
  void setFiltroEstado(String estado) {
    _filtroEstado = estado;
    notifyListeners();
  }

  void setFiltroBusqueda(String busqueda) {
    _filtroBusqueda = busqueda;
    notifyListeners();
  }

  void setFiltroColaborador(String? colaboradorId) {
    _filtroColaborador = colaboradorId;
    notifyListeners();
  }

  void limpiarFiltros() {
    _filtroEstado = 'todos';
    _filtroBusqueda = '';
    _filtroColaborador = null;
    notifyListeners();
  }

  // Obtener vacaciones por estado
  List<Vacacion> get vacacionesProgramadasList {
    return _vacaciones.where((v) => v.estado == 'Programada').toList();
  }

  List<Vacacion> get vacacionesEnCursoList {
    return _vacaciones.where((v) => v.estado == 'En curso').toList();
  }

  List<Vacacion> get vacacionesCompletadasList {
    return _vacaciones.where((v) => v.estado == 'Completada').toList();
  }

  @override
  void dispose() {
    _authProvider?.removeListener(_onAuthChanged);
    super.dispose();
  }
}
