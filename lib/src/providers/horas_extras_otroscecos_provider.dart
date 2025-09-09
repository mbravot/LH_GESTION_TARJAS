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
  String _filtroEstado = 'todos'; // 'todos', 'futuras', 'hoy', 'pasadas'
  int? _filtroMes;
  int? _filtroAno;

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
  String get filtroEstado => _filtroEstado;
  int? get filtroMes => _filtroMes;
  int? get filtroAno => _filtroAno;

  // Estadísticas
  Map<String, int> get estadisticas {
    // Calcular estadísticas sobre datos filtrados por búsqueda, colaborador, tipo CECO, mes y año
    // pero sin aplicar el filtro de estado
    final datosParaEstadisticas = _horasExtras.where((horasExtras) {
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

      // Filtro de mes
      if (_filtroMes != null && horasExtras.fecha.month != _filtroMes) {
        return false;
      }

      // Filtro de año
      if (_filtroAno != null && horasExtras.fecha.year != _filtroAno) {
        return false;
      }

      return true;
    }).toList();

    final futuras = datosParaEstadisticas.where((h) => h.esFuturo).length;
    final hoy = datosParaEstadisticas.where((h) => h.esHoy).length;
    final pasadas = datosParaEstadisticas.where((h) => h.esPasado).length;
    final total = datosParaEstadisticas.length;

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

  // Listas únicas para filtros de mes y año
  List<int> get mesesUnicos {
    final meses = <int>{};
    for (var horas in _horasExtras) {
      meses.add(horas.fecha.month);
    }
    return meses.toList()..sort();
  }

  List<int> get anosUnicos {
    final anos = <int>{};
    for (var horas in _horasExtras) {
      anos.add(horas.fecha.year);
    }
    return anos.toList()..sort((a, b) => b.compareTo(a)); // Orden descendente
  }

  // Métodos para cargar datos
  Future<void> cargarHorasExtras() async {
    _setLoading(true);
    try {
      final response = await ApiService.obtenerHorasExtrasOtrosCecos();

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

  void setFiltroEstado(String value) {
    _filtroEstado = value;
    _aplicarFiltros();
  }

  void setFiltroMes(int? value) {
    _filtroMes = value;
    _aplicarFiltros();
  }

  void setFiltroAno(int? value) {
    _filtroAno = value;
    _aplicarFiltros();
  }

  void limpiarFiltros() {
    _filtroBusqueda = '';
    _filtroColaborador = '';
    _filtroCecoTipo = '';
    _filtroEstado = 'todos';
    _filtroMes = null;
    _filtroAno = null;
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

      // Filtro de mes
      if (_filtroMes != null && horasExtras.fecha.month != _filtroMes) {
        return false;
      }

      // Filtro de año
      if (_filtroAno != null && horasExtras.fecha.year != _filtroAno) {
        return false;
      }

      // Filtro de estado
      if (_filtroEstado != 'todos') {
        switch (_filtroEstado) {
          case 'futuras':
            if (!horasExtras.esFuturo) return false;
            break;
          case 'hoy':
            if (!horasExtras.esHoy) return false;
            break;
          case 'pasadas':
            if (!horasExtras.esPasado) return false;
            break;
        }
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
