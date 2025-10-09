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
  String _filtroEstado = 'todos'; // 'todos', 'futuras', 'hoy', 'pasadas'
  int? _filtroMes;
  int? _filtroAno;

  // Getters
  List<BonoEspecial> get bonosEspeciales => _bonosEspeciales;
  List<BonoEspecial> get bonosEspecialesFiltradas => _bonosEspecialesFiltradas;
  List<ResumenBonoEspecial> get resumenes => _resumenes;
  bool get isLoading => _isLoading;
  String get error => _error;

  // Getters para filtros
  String get filtroBusqueda => _filtroBusqueda;
  String get filtroColaborador => _filtroColaborador;
  String get filtroEstado => _filtroEstado;
  int? get filtroMes => _filtroMes;
  int? get filtroAno => _filtroAno;

  // Estadísticas - se calculan sobre todos los datos, no sobre los filtrados
  Map<String, int> get estadisticas {
    // Aplicar filtros de búsqueda, colaborador, mes y año, pero NO el filtro de estado
    final datosParaEstadisticas = _bonosEspeciales.where((bono) {
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

      // Filtro de mes
      if (_filtroMes != null && bono.fecha.month != _filtroMes) {
        return false;
      }

      // Filtro de año
      if (_filtroAno != null && bono.fecha.year != _filtroAno) {
        return false;
      }

      return true;
    }).toList();

    final futuras = datosParaEstadisticas.where((b) => b.esFuturo).length;
    final hoy = datosParaEstadisticas.where((b) => b.esHoy).length;
    final pasadas = datosParaEstadisticas.where((b) => b.esPasado).length;
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
    return _bonosEspeciales.map((b) => b.nombreColaborador).toSet().toList()..sort();
  }

  // Listas únicas para filtros de mes y año
  List<int> get mesesUnicos {
    final meses = <int>{};
    for (var bono in _bonosEspeciales) {
      meses.add(bono.fecha.month);
    }
    return meses.toList()..sort();
  }

  List<int> get anosUnicos {
    final anos = <int>{};
    for (var bono in _bonosEspeciales) {
      anos.add(bono.fecha.year);
    }
    return anos.toList()..sort((a, b) => b.compareTo(a)); // Orden descendente
  }

  // Métodos para cargar datos
  Future<void> cargarBonosEspeciales() async {
    // Si ya hay datos, no recargar
    if (_bonosEspeciales.isNotEmpty && !_isLoading) {
      return;
    }

    _setLoading(true);
    try {
      final response = await ApiService.obtenerBonosEspeciales(
        idColaborador: _filtroColaborador.isNotEmpty ? _filtroColaborador : null,
      );

      _bonosEspeciales = response.map((json) => BonoEspecial.fromJson(json)).toList();
      _aplicarFiltros();
      _error = '';
    } catch (e) {
      _error = 'Error al cargar bonos especiales: $e';
      _bonosEspeciales = [];
      _bonosEspecialesFiltradas = [];
    } finally {
      _setLoading(false);
    }
  }

  Future<void> cargarResumenes() async {
    try {
      final response = await ApiService.obtenerResumenBonosEspeciales();

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
    _filtroEstado = 'todos';
    _filtroMes = null;
    _filtroAno = null;
    _aplicarFiltros();
  }

  void _aplicarFiltros() {
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

      // Filtro de mes
      if (_filtroMes != null && bono.fecha.month != _filtroMes) {
        return false;
      }

      // Filtro de año
      if (_filtroAno != null && bono.fecha.year != _filtroAno) {
        return false;
      }

      // Filtro de estado
      if (_filtroEstado != 'todos') {
        switch (_filtroEstado) {
          case 'futuras':
            if (!bono.esFuturo) return false;
            break;
          case 'hoy':
            if (!bono.esHoy) return false;
            break;
          case 'pasadas':
            if (!bono.esPasado) return false;
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
    // Solo limpiar datos, no cargar automáticamente
    _bonosEspeciales = [];
    _resumenes = [];
    notifyListeners();
  }

  void limpiarError() {
    _error = '';
    notifyListeners();
  }
}
