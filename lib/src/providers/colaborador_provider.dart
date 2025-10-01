import 'package:flutter/material.dart';
import '../models/colaborador.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class ColaboradorProvider extends ChangeNotifier {
  static ColaboradorProvider? _instance;
  List<Colaborador> _colaboradores = [];
  bool _isLoading = false;
  String? _error;
  AuthProvider? _authProvider;
  
  // Singleton pattern
  static ColaboradorProvider get instance {
    _instance ??= ColaboradorProvider._internal();
    return _instance!;
  }
  
  ColaboradorProvider._internal();
  
  // Reset singleton (para testing o logout)
  static void reset() {
    _instance = null;
  }
  
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
      if (_filtroEstado == 'finiquitados') {
        filtrados = filtrados.where((c) => c.fechaFiniquito != null && c.fechaFiniquito!.isNotEmpty).toList();
      } else if (_filtroEstado == 'preenrolados') {
        filtrados = filtrados.where((c) => c.rut == null || c.rut!.isEmpty).toList();
      } else {
        filtrados = filtrados.where((c) => c.idEstado == _filtroEstado).toList();
      }
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
  int get colaboradoresFiniquitados => _colaboradores.where((c) => c.fechaFiniquito != null && c.fechaFiniquito!.isNotEmpty).length;
  int get colaboradoresPreenrolados => _colaboradores.where((c) => c.rut == null || c.rut!.isEmpty).length;

  void setAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;
    // Escuchar cambios en el AuthProvider para recargar colaboradores cuando cambie la sucursal
    _authProvider!.addListener(_onAuthChanged);
  }

  // Cache para evitar recargas múltiples
  String? _lastSucursalId;
  DateTime? _lastLoadTime;
  static const Duration _minInterval = Duration(seconds: 2);

  // Escuchar cambios en el AuthProvider
  void _onAuthChanged() {
    
    // NO reaccionar si el AuthProvider está cambiando sucursal
    if (_authProvider?.isChangingSucursal == true) {
      return;
    }
    
    if (_authProvider?.userData != null) {
      final currentSucursalId = _authProvider!.userData!['id_sucursal']?.toString();
      final now = DateTime.now();
      
      // Verificar si realmente cambió la sucursal y ha pasado suficiente tiempo
      if (currentSucursalId != _lastSucursalId && 
          (_lastLoadTime == null || now.difference(_lastLoadTime!) > _minInterval)) {
        _lastSucursalId = currentSucursalId;
        _lastLoadTime = now;
        cargarColaboradores();
      } else {
      }
    } else {
    }
  }

  // Cargar colaboradores
  Future<void> cargarColaboradores() async {
    
    // Evitar cargas múltiples simultáneas
    if (_isLoading) {
      return;
    }
    
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
  Future<bool> editarColaborador(String colaboradorId, Map<String, dynamic> colaboradorData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.editarColaborador(colaboradorId, colaboradorData);
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



  // Desactivar colaborador
  Future<bool> desactivarColaborador(String colaboradorId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.desactivarColaborador(colaboradorId);
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

  // Activar colaborador
  Future<bool> activarColaborador(String colaboradorId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.activarColaborador(colaboradorId);
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

  @override
  void dispose() {
    _authProvider?.removeListener(_onAuthChanged);
    super.dispose();
  }
}
