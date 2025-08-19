import 'package:flutter/material.dart';
import '../models/horas_extras_otroscecos.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class HorasExtrasOtrosCecosProvider extends ChangeNotifier {
  List<HorasExtrasOtrosCecos> _horasExtras = [];
  List<HorasExtrasOtrosCecos> _horasExtrasFiltradas = [];
  List<CecoTipo> _tiposCeco = [];
  List<Ceco> _cecos = [];
  bool _isLoading = false;
  String _error = '';

  // Filtros
  String _filtroBusqueda = '';
  String _filtroColaborador = '';
  String _filtroCecoTipo = '';
  String _filtroCeco = '';
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  // Getters
  List<HorasExtrasOtrosCecos> get horasExtras => _horasExtras;
  List<HorasExtrasOtrosCecos> get horasExtrasFiltradas => _horasExtrasFiltradas;
  List<CecoTipo> get tiposCeco => _tiposCeco;
  List<Ceco> get cecos => _cecos;
  bool get isLoading => _isLoading;
  String get error => _error;

  // Getters para filtros
  String get filtroBusqueda => _filtroBusqueda;
  String get filtroColaborador => _filtroColaborador;
  String get filtroCecoTipo => _filtroCecoTipo;
  String get filtroCeco => _filtroCeco;
  DateTime? get fechaInicio => _fechaInicio;
  DateTime? get fechaFin => _fechaFin;

  // Estadísticas
  Map<String, int> get estadisticas {
    final futuras = _horasExtrasFiltradas.where((h) => h.esFuturo).length;
    final hoy = _horasExtrasFiltradas.where((h) => h.esHoy).length;
    final pasadas = _horasExtrasFiltradas.where((h) => h.esPasado).length;
    final total = _horasExtrasFiltradas.length;

    return {
      'futuras': futuras,
      'hoy': hoy,
      'pasadas': pasadas,
      'total': total,
    };
  }

  // Listas únicas para filtros
  List<String> get colaboradoresUnicos {
    return _horasExtras.map((h) => h.nombreColaborador).toSet().toList()..sort();
  }

  List<String> get tiposCecoUnicos {
    return _horasExtras.map((h) => h.nombreCecoTipo).toSet().toList()..sort();
  }

  List<String> get cecosUnicos {
    return _horasExtras.map((h) => h.nombreCeco).toSet().toList()..sort();
  }

  // Métodos para cargar datos
  Future<void> cargarHorasExtras() async {
    _setLoading(true);
    try {
      final response = await ApiService.obtenerHorasExtrasOtrosCecos(
        idColaborador: _filtroColaborador.isNotEmpty ? _filtroColaborador : null,
        fechaInicio: _fechaInicio?.toIso8601String().split('T')[0],
        fechaFin: _fechaFin?.toIso8601String().split('T')[0],
        idCecoTipo: _filtroCecoTipo.isNotEmpty ? int.tryParse(_filtroCecoTipo) : null,
        idCeco: _filtroCeco.isNotEmpty ? int.tryParse(_filtroCeco) : null,
      );

      _horasExtras = response.map((json) => HorasExtrasOtrosCecos.fromJson(json)).toList();
      _aplicarFiltros();
      _error = '';
    } catch (e) {
      _error = 'Error al cargar horas extras: $e';
      _horasExtras = [];
      _horasExtrasFiltradas = [];
    } finally {
      _setLoading(false);
    }
  }

  Future<void> cargarOpciones() async {
    try {
      final response = await ApiService.obtenerOpcionesHorasExtrasOtrosCecos();
      
      if (response['tipos_ceco'] != null) {
        _tiposCeco = (response['tipos_ceco'] as List)
            .map((json) => CecoTipo.fromJson(json))
            .toList();
      }
      
      if (response['cecos'] != null) {
        _cecos = (response['cecos'] as List)
            .map((json) => Ceco.fromJson(json))
            .toList();
      }
      
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar opciones: $e';
    }
  }

  // Métodos CRUD
  Future<bool> crearHorasExtras(Map<String, dynamic> datos) async {
    _setLoading(true);
    try {
      await ApiService.crearHorasExtrasOtrosCecos(datos);
      await cargarHorasExtras();
      _error = '';
      return true;
    } catch (e) {
      _error = 'Error al crear horas extras: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> editarHorasExtras(String id, Map<String, dynamic> datos) async {
    _setLoading(true);
    try {
      await ApiService.editarHorasExtrasOtrosCecos(id, datos);
      await cargarHorasExtras();
      _error = '';
      return true;
    } catch (e) {
      _error = 'Error al editar horas extras: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> eliminarHorasExtras(String id) async {
    _setLoading(true);
    try {
      await ApiService.eliminarHorasExtrasOtrosCecos(id);
      await cargarHorasExtras();
      _error = '';
      return true;
    } catch (e) {
      _error = 'Error al eliminar horas extras: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<HorasExtrasOtrosCecos?> obtenerHorasExtrasPorId(String id) async {
    try {
      final response = await ApiService.obtenerHorasExtrasOtrosCecosPorId(id);
      return HorasExtrasOtrosCecos.fromJson(response);
    } catch (e) {
      _error = 'Error al obtener horas extras: $e';
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

  void setFiltroCecoTipo(String value) {
    _filtroCecoTipo = value;
    _aplicarFiltros();
  }

  void setFiltroCeco(String value) {
    _filtroCeco = value;
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
    _filtroCecoTipo = '';
    _filtroCeco = '';
    _fechaInicio = null;
    _fechaFin = null;
    _aplicarFiltros();
  }

  void _aplicarFiltros() {
    _horasExtrasFiltradas = _horasExtras.where((horasExtras) {
      // Filtro de búsqueda
      if (_filtroBusqueda.isNotEmpty) {
        final busqueda = _filtroBusqueda.toLowerCase();
        final matchColaborador = horasExtras.nombreColaborador.toLowerCase().contains(busqueda);
        final matchCecoTipo = horasExtras.nombreCecoTipo.toLowerCase().contains(busqueda);
        final matchCeco = horasExtras.nombreCeco.toLowerCase().contains(busqueda);
        final matchFecha = horasExtras.fechaFormateadaCorta.contains(busqueda);
        
        if (!matchColaborador && !matchCecoTipo && !matchCeco && !matchFecha) {
          return false;
        }
      }

      // Filtro de colaborador
      if (_filtroColaborador.isNotEmpty && horasExtras.nombreColaborador != _filtroColaborador) {
        return false;
      }

      // Filtro de tipo CECO
      if (_filtroCecoTipo.isNotEmpty && horasExtras.nombreCecoTipo != _filtroCecoTipo) {
        return false;
      }

      // Filtro de CECO
      if (_filtroCeco.isNotEmpty && horasExtras.nombreCeco != _filtroCeco) {
        return false;
      }

      // Filtro de fecha inicio
      if (_fechaInicio != null && horasExtras.fecha.isBefore(_fechaInicio!)) {
        return false;
      }

      // Filtro de fecha fin
      if (_fechaFin != null && horasExtras.fecha.isAfter(_fechaFin!)) {
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
    cargarHorasExtras();
    cargarOpciones();
  }

  void limpiarError() {
    _error = '';
    notifyListeners();
  }
}
