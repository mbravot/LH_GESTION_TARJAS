import 'package:flutter/material.dart';
import '../models/licencia.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class LicenciaProvider extends ChangeNotifier {
  List<Licencia> _licencias = [];
  bool _isLoading = false;
  String? _error;
  AuthProvider? _authProvider;
  String _filtroEstado = 'todos';
  String _filtroBusqueda = '';
  String? _filtroColaborador;

  List<Licencia> get licencias => _licencias;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filtroEstado => _filtroEstado;
  String get filtroBusqueda => _filtroBusqueda;
  String? get filtroColaborador => _filtroColaborador;

  // Licencias filtradas
  List<Licencia> get licenciasFiltradas {
    List<Licencia> filtradas = _licencias;

    // Filtrar por estado
    if (_filtroEstado != 'todos') {
      filtradas = filtradas.where((l) => l.estado == _filtroEstado).toList();
    }

    // Filtrar por colaborador
    if (_filtroColaborador != null && _filtroColaborador!.isNotEmpty) {
      filtradas = filtradas.where((l) => l.idColaborador == _filtroColaborador).toList();
    }

    // Filtrar por búsqueda
    if (_filtroBusqueda.isNotEmpty) {
      final busqueda = _filtroBusqueda.toLowerCase();
      filtradas = filtradas.where((l) {
        return l.nombreCompletoColaborador.toLowerCase().contains(busqueda) ||
               l.periodoFormateado.toLowerCase().contains(busqueda);
      }).toList();
    }

    return filtradas;
  }

  // Estadísticas
  int get totalLicencias => _licencias.length;
  int get licenciasProgramadas => _licencias.where((l) => l.estado == 'Programada').length;
  int get licenciasEnCurso => _licencias.where((l) => l.estado == 'En curso').length;
  int get licenciasCompletadas => _licencias.where((l) => l.estado == 'Completada').length;

  void setAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;
    // Escuchar cambios en el AuthProvider para recargar licencias cuando cambie la sucursal
    _authProvider!.addListener(_onAuthChanged);
  }

  // Escuchar cambios en el AuthProvider
  void _onAuthChanged() {
    // Recargar licencias cuando cambie la sucursal
    if (_authProvider?.userData != null) {
      cargarLicencias();
    }
  }

  // Cargar licencias
  Future<void> cargarLicencias({String? idColaborador}) async {
    if (_authProvider == null) {
      _error = 'AuthProvider no configurado';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.obtenerLicencias(idColaborador: idColaborador);
      _licencias = data.map((json) => Licencia.fromJson(json)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Crear licencia
  Future<bool> crearLicencia(Map<String, dynamic> licenciaData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.crearLicencia(licenciaData);
      await cargarLicencias(); // Recargar la lista
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

  // Obtener licencia por ID
  Future<Licencia?> obtenerLicenciaPorId(String id) async {
    try {
      final data = await ApiService.obtenerLicenciaPorId(id);
      return Licencia.fromJson(data);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Editar licencia
  Future<bool> editarLicencia(String id, Map<String, dynamic> licenciaData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.editarLicencia(id, licenciaData);
      await cargarLicencias(); // Recargar la lista
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

  // Eliminar licencia
  Future<bool> eliminarLicencia(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.eliminarLicencia(id);
      await cargarLicencias(); // Recargar la lista
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

  // Obtener licencias de un colaborador específico
  Future<List<Licencia>> obtenerLicenciasColaborador(String colaboradorId) async {
    try {
      final data = await ApiService.obtenerLicenciasColaborador(colaboradorId);
      return data.map((json) => Licencia.fromJson(json)).toList();
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

  // Obtener licencias por estado
  List<Licencia> get licenciasProgramadasList {
    return _licencias.where((l) => l.estado == 'Programada').toList();
  }

  List<Licencia> get licenciasEnCursoList {
    return _licencias.where((l) => l.estado == 'En curso').toList();
  }

  List<Licencia> get licenciasCompletadasList {
    return _licencias.where((l) => l.estado == 'Completada').toList();
  }

  @override
  void dispose() {
    _authProvider?.removeListener(_onAuthChanged);
    super.dispose();
  }
}
