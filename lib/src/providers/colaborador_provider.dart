import 'package:flutter/material.dart';
import '../models/colaborador.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class ColaboradorProvider extends ChangeNotifier {
  List<Colaborador> _colaboradores = [];
  bool _isLoading = false;
  String? _error;
  AuthProvider? _authProvider;
  String _filtroEstado = 'todos';
  String _filtroBusqueda = '';

  List<Colaborador> get colaboradores => _colaboradores;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filtroEstado => _filtroEstado;
  String get filtroBusqueda => _filtroBusqueda;

  // Colaboradores filtrados
  List<Colaborador> get colaboradoresFiltrados {
    List<Colaborador> filtrados = _colaboradores;

    // Filtrar por estado
    if (_filtroEstado != 'todos') {
      filtrados = filtrados.where((c) => c.idEstado == _filtroEstado).toList();
    }

    // Filtrar por búsqueda
    if (_filtroBusqueda.isNotEmpty) {
      final busqueda = _filtroBusqueda.toLowerCase();
      filtrados = filtrados.where((c) {
        return c.nombreCompleto.toLowerCase().contains(busqueda) ||
               c.rutCompleto.toLowerCase().contains(busqueda);
      }).toList();
    }

    return filtrados;
  }

  // Estadísticas
  int get totalColaboradores => _colaboradores.length;
  int get colaboradoresActivos => _colaboradores.where((c) => c.idEstado == '1').length;
  int get colaboradoresInactivos => _colaboradores.where((c) => c.idEstado == '2').length;

  void setAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;
    // Escuchar cambios en el AuthProvider para recargar colaboradores cuando cambie la sucursal
    _authProvider!.addListener(_onAuthChanged);
  }

  // Escuchar cambios en el AuthProvider
  void _onAuthChanged() {
    // Recargar colaboradores cuando cambie la sucursal
    if (_authProvider?.userData != null) {
      cargarColaboradores();
    }
  }

  // Cargar colaboradores
  Future<void> cargarColaboradores() async {
    if (_authProvider == null) {
      _error = 'AuthProvider no configurado';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.obtenerColaboradores();
      _colaboradores = data.map((json) => Colaborador.fromJson(json)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Crear colaborador
  Future<bool> crearColaborador(Map<String, dynamic> colaboradorData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.crearColaborador(colaboradorData);
      await cargarColaboradores(); // Recargar la lista
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

  // Obtener colaborador por ID
  Future<Colaborador?> obtenerColaboradorPorId(String id) async {
    try {
      final data = await ApiService.obtenerColaboradorPorId(id);
      return Colaborador.fromJson(data);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Editar colaborador
  Future<bool> editarColaborador(String id, Map<String, dynamic> colaboradorData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.editarColaborador(id, colaboradorData);
      await cargarColaboradores(); // Recargar la lista
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
  void setFiltroEstado(String estado) {
    _filtroEstado = estado;
    notifyListeners();
  }

  void setFiltroBusqueda(String busqueda) {
    _filtroBusqueda = busqueda;
    notifyListeners();
  }

  void limpiarFiltros() {
    _filtroEstado = 'todos';
    _filtroBusqueda = '';
    notifyListeners();
  }

  // Obtener colaboradores activos
  List<Colaborador> get colaboradoresActivosList {
    return _colaboradores.where((c) => c.idEstado == '1').toList();
  }

  // Obtener colaboradores inactivos
  List<Colaborador> get colaboradoresInactivosList {
    return _colaboradores.where((c) => c.idEstado == '2').toList();
  }

  @override
  void dispose() {
    _authProvider?.removeListener(_onAuthChanged);
    super.dispose();
  }
}
