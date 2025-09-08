import 'package:flutter/material.dart';
import '../models/bono_especial.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class BonoEspecialProvider extends ChangeNotifier {
  List<BonoEspecial> _bonosEspeciales = [];
  List<BonoEspecial> _bonosEspecialesFiltradas = [];
  List<ResumenBonoEspecial> _resumenes = [];
  bool _isLoading = false;
  String _error = '';

  // Filtros
  String _filtroBusqueda = '';
  String _filtroColaborador = '';
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  // Getters
  List<BonoEspecial> get bonosEspeciales => _bonosEspeciales;
  List<BonoEspecial> get bonosEspecialesFiltradas => _bonosEspecialesFiltradas;
  List<ResumenBonoEspecial> get resumenes => _resumenes;
  bool get isLoading => _isLoading;
  String get error => _error;

  // Getters para filtros
  String get filtroBusqueda => _filtroBusqueda;
  String get filtroColaborador => _filtroColaborador;
  DateTime? get fechaInicio => _fechaInicio;
  DateTime? get fechaFin => _fechaFin;

  // Estadísticas
  Map<String, int> get estadisticas {
    final futuras = _bonosEspecialesFiltradas.where((b) => b.esFuturo).length;
    final hoy = _bonosEspecialesFiltradas.where((b) => b.esHoy).length;
    final pasadas = _bonosEspecialesFiltradas.where((b) => b.esPasado).length;
    final total = _bonosEspecialesFiltradas.length;

    return {
      'futuras': futuras,
      'hoy': hoy,
      'pasadas': pasadas,
      'total': total,
    };
  }

  // Listas únicas para filtros
  List<String> get colaboradoresUnicos {
    return _bonosEspeciales.map((b) => b.nombreColaborador).toSet().toList()..sort();
  }

  // Métodos para cargar datos
  Future<void> cargarBonosEspeciales() async {
    _setLoading(true);
    try {
      print('🔍 DEBUG: Cargando bonos especiales...');
      final response = await ApiService.obtenerBonosEspeciales(
        idColaborador: _filtroColaborador.isNotEmpty ? _filtroColaborador : null,
        fechaInicio: _fechaInicio?.toIso8601String().split('T')[0],
        fechaFin: _fechaFin?.toIso8601String().split('T')[0],
      );

      print('🔍 DEBUG: Respuesta del API bonos especiales: ${response.length} registros');
      print('🔍 DEBUG: Primer registro: ${response.isNotEmpty ? response.first : "No hay registros"}');

      _bonosEspeciales = response.map((json) => BonoEspecial.fromJson(json)).toList();
      _aplicarFiltros();
      _error = '';
      print('🔍 DEBUG: Bonos especiales cargados: ${_bonosEspeciales.length}');
      print('🔍 DEBUG: Bonos especiales filtrados: ${_bonosEspecialesFiltradas.length}');
    } catch (e) {
      print('🔍 DEBUG: Error al cargar bonos especiales: $e');
      _error = 'Error al cargar bonos especiales: $e';
      _bonosEspeciales = [];
      _bonosEspecialesFiltradas = [];
    } finally {
      _setLoading(false);
    }
  }

  Future<void> cargarResumenes() async {
    try {
      final response = await ApiService.obtenerResumenBonosEspeciales(
        fechaInicio: _fechaInicio?.toIso8601String().split('T')[0],
        fechaFin: _fechaFin?.toIso8601String().split('T')[0],
      );

      _resumenes = response.map((json) => ResumenBonoEspecial.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar resúmenes: $e';
      _resumenes = [];
    }
  }

  // Métodos CRUD
  Future<bool> crearBonoEspecial(Map<String, dynamic> datos) async {
    _setLoading(true);
    try {
      await ApiService.crearBonoEspecial(datos);
      await cargarBonosEspeciales();
      await cargarResumenes();
      _error = '';
      return true;
    } catch (e) {
      _error = 'Error al crear bono especial: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> editarBonoEspecial(String id, Map<String, dynamic> datos) async {
    _setLoading(true);
    try {
      await ApiService.editarBonoEspecial(id, datos);
      await cargarBonosEspeciales();
      await cargarResumenes();
      _error = '';
      return true;
    } catch (e) {
      _error = 'Error al editar bono especial: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> eliminarBonoEspecial(String id) async {
    _setLoading(true);
    try {
      await ApiService.eliminarBonoEspecial(id);
      await cargarBonosEspeciales();
      await cargarResumenes();
      _error = '';
      return true;
    } catch (e) {
      _error = 'Error al eliminar bono especial: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<BonoEspecial?> obtenerBonoEspecialPorId(String id) async {
    try {
      final response = await ApiService.obtenerBonoEspecialPorId(id);
      return BonoEspecial.fromJson(response);
    } catch (e) {
      _error = 'Error al obtener bono especial: $e';
      return null;
    }
  }

  // Métodos para filtros
  void setFiltroBusqueda(String value) {
    _filtroBusqueda = value;
    _aplicarFiltros();
  }

  void setFiltroColaborador(String value) {
    _filtroColaborador = value;
    _aplicarFiltros();
  }

  void setFechaInicio(DateTime? date) {
    _fechaInicio = date;
    _aplicarFiltros();
  }

  void setFechaFin(DateTime? date) {
    _fechaFin = date;
    _aplicarFiltros();
  }

  void limpiarFiltros() {
    _filtroBusqueda = '';
    _filtroColaborador = '';
    _fechaInicio = null;
    _fechaFin = null;
    _aplicarFiltros();
  }

  void _aplicarFiltros() {
    print('🔍 DEBUG: Aplicando filtros a ${_bonosEspeciales.length} registros');
    _bonosEspecialesFiltradas = _bonosEspeciales.where((bono) {
      // Filtro de búsqueda
      if (_filtroBusqueda.isNotEmpty) {
        final busqueda = _filtroBusqueda.toLowerCase();
        final matchColaborador = bono.nombreColaborador.toLowerCase().contains(busqueda);
        final matchFecha = bono.fechaFormateadaCorta.contains(busqueda);
        final matchCantidad = bono.cantidadFormateada.contains(busqueda);

        if (!matchColaborador && !matchFecha && !matchCantidad) {
          return false;
        }
      }

      // Filtro de colaborador
      if (_filtroColaborador.isNotEmpty && bono.nombreColaborador != _filtroColaborador) {
        return false;
      }

      // Filtro de fecha inicio
      if (_fechaInicio != null && bono.fecha.isBefore(_fechaInicio!)) {
        return false;
      }

      // Filtro de fecha fin
      if (_fechaFin != null && bono.fecha.isAfter(_fechaFin!)) {
        return false;
      }

      return true;
    }).toList();

    print('🔍 DEBUG: Registros después del filtrado: ${_bonosEspecialesFiltradas.length}');
    notifyListeners();
  }

  // Métodos de utilidad
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setAuthProvider(AuthProvider authProvider) {
    print('🔍 DEBUG: Configurando AuthProvider...');
    // Configurar el provider para escuchar cambios de sucursal
    authProvider.addListener(_onSucursalChanged);
    print('🔍 DEBUG: AuthProvider configurado correctamente');
  }

  void _onSucursalChanged() {
    print('🔍 DEBUG: Sucursal cambiada, recargando datos...');
    // Recargar datos cuando cambie la sucursal
    cargarBonosEspeciales();
    cargarResumenes();
  }

  void limpiarError() {
    _error = '';
    notifyListeners();
  }
}
