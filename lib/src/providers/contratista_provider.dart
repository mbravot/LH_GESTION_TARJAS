import 'package:flutter/material.dart';
import '../models/contratista.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class ContratistaProvider extends ChangeNotifier {
  List<Contratista> _contratistas = [];
  List<Contratista> _contratistasFiltradas = [];
  List<String> _estadosDisponibles = [];
  bool _isLoading = false;
  String _error = '';

  // Filtros
  String _filtroBusqueda = '';
  String _filtroEstado = '';

  // Getters
  List<Contratista> get contratistas => _contratistas;
  List<Contratista> get contratistasFiltradas => _contratistasFiltradas;
  List<String> get estadosDisponibles => _estadosDisponibles;
  bool get isLoading => _isLoading;
  String get error => _error;

  // Getters para filtros
  String get filtroBusqueda => _filtroBusqueda;
  String get filtroEstado => _filtroEstado;

  // Estadísticas
  Map<String, int> get estadisticas {
    final activos = _contratistasFiltradas.where((c) => c.esActivo).length;
    final inactivos = _contratistasFiltradas.where((c) => c.esInactivo).length;
    final suspendidos = _contratistasFiltradas.where((c) => c.estado.toUpperCase() == 'SUSPENDIDO').length;
    final total = _contratistasFiltradas.length;

    return {
      'activos': activos,
      'inactivos': inactivos,
      'suspendidos': suspendidos,
      'total': total,
    };
  }

  // Listas únicas para filtros
  List<String> get estadosUnicos {
    return _contratistas.map((c) => c.estado).toSet().toList()..sort();
  }

  // Métodos para cargar datos
  Future<void> cargarContratistas() async {
    _setLoading(true);
    try {
      final response = await ApiService.obtenerContratistas();
      _contratistas = response.map((json) => Contratista.fromJson(json)).toList();
      _aplicarFiltros();
      _error = '';
    } catch (e) {
      _error = 'Error al cargar contratistas: $e';
      _contratistas = [];
      _contratistasFiltradas = [];
    } finally {
      _setLoading(false);
    }
  }

  Future<void> cargarOpciones() async {
    try {
      final response = await ApiService.obtenerOpcionesContratistas();
      _estadosDisponibles = response['estados']?.cast<String>() ?? [];
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar opciones: $e';
      _estadosDisponibles = [];
    }
  }

  // Métodos CRUD
  Future<bool> crearContratista(Map<String, dynamic> datos) async {
    _setLoading(true);
    try {
      await ApiService.crearContratista(datos);
      await cargarContratistas();
      _error = '';
      return true;
    } catch (e) {
      _error = 'Error al crear contratista: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> editarContratista(String id, Map<String, dynamic> datos) async {
    _setLoading(true);
    try {
      await ApiService.editarContratista(id, datos);
      await cargarContratistas();
      _error = '';
      return true;
    } catch (e) {
      _error = 'Error al editar contratista: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> eliminarContratista(String id) async {
    _setLoading(true);
    try {
      await ApiService.eliminarContratista(id);
      await cargarContratistas();
      _error = '';
      return true;
    } catch (e) {
      _error = 'Error al eliminar contratista: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<Contratista?> obtenerContratistaPorId(String id) async {
    try {
      final response = await ApiService.obtenerContratistaPorId(id);
      return Contratista.fromJson(response);
    } catch (e) {
      _error = 'Error al obtener contratista: $e';
      return null;
    }
  }

  // Métodos para filtros
  void setFiltroBusqueda(String value) {
    _filtroBusqueda = value;
    _aplicarFiltros();
  }

  void setFiltroEstado(String value) {
    _filtroEstado = value;
    _aplicarFiltros();
  }

  void limpiarFiltros() {
    _filtroBusqueda = '';
    _filtroEstado = '';
    _aplicarFiltros();
  }

  void _aplicarFiltros() {
    _contratistasFiltradas = _contratistas.where((contratista) {
      // Filtro de búsqueda
      if (_filtroBusqueda.isNotEmpty) {
        final busqueda = _filtroBusqueda.toLowerCase();
        final matchNombre = contratista.nombreCompleto.toLowerCase().contains(busqueda);
        final matchRut = contratista.rut.toLowerCase().contains(busqueda);
        final matchEmail = contratista.email?.toLowerCase().contains(busqueda) ?? false;
        final matchTelefono = contratista.telefono?.toLowerCase().contains(busqueda) ?? false;

        if (!matchNombre && !matchRut && !matchEmail && !matchTelefono) {
          return false;
        }
      }

      // Filtro de estado
      if (_filtroEstado.isNotEmpty && contratista.estado != _filtroEstado) {
        return false;
      }

      return true;
    }).toList();

    notifyListeners();
  }

  // Métodos de utilidad
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setAuthProvider(AuthProvider authProvider) {
    // Configurar el provider para escuchar cambios de sucursal
    authProvider.addListener(_onSucursalChanged);
  }

  void _onSucursalChanged() {
    // Recargar datos cuando cambie la sucursal
    cargarContratistas();
    cargarOpciones();
  }

  void limpiarError() {
    _error = '';
    notifyListeners();
  }
}
