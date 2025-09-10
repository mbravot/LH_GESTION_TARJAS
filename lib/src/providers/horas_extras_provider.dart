import 'package:flutter/material.dart';
import '../models/horas_extras.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class HorasExtrasProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  AuthProvider? _authProvider;
  
  List<HorasExtras> _rendimientos = [];
  List<HorasExtras> _rendimientosFiltrados = [];
  List<Bono> _bonos = [];
  bool _isLoading = false;
  String? _error;
  
  // Variables para filtros
  String _filtroBusqueda = '';
  String _filtroColaborador = '';
  String _filtroEstado = 'todos'; // 'todos', 'futuras', 'hoy', 'pasadas'
  int? _filtroMes;
  int? _filtroAno;

  // Getters
  List<HorasExtras> get rendimientos => _rendimientos;
  List<HorasExtras> get rendimientosFiltrados => _rendimientosFiltrados;
  List<Bono> get bonos => _bonos;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Getters para filtros
  String get filtroBusqueda => _filtroBusqueda;
  String get filtroColaborador => _filtroColaborador;
  String get filtroEstado => _filtroEstado;
  int? get filtroMes => _filtroMes;
  int? get filtroAno => _filtroAno;

  // Método para configurar el AuthProvider
  void setAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;
    // Escuchar cambios en la sucursal activa
    _authProvider!.addListener(_onSucursalChanged);
  }

  // Método para manejar cambios de sucursal
  void _onSucursalChanged() {
    if (_authProvider != null) {
      cargarRendimientos();
    }
  }

  @override
  void dispose() {
    if (_authProvider != null) {
      _authProvider!.removeListener(_onSucursalChanged);
    }
    super.dispose();
  }

  // Método para cargar rendimientos
  Future<void> cargarRendimientos() async {
    _setLoading(true);
    _error = null;
    
    try {
      final response = await _apiService.obtenerRendimientosHorasExtras(
        idColaborador: _filtroColaborador.isNotEmpty ? _filtroColaborador : null,
      );
      
      _rendimientos = response.map((json) => HorasExtras.fromJson(json)).toList();
      _aplicarFiltros();
      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  // Método para cargar bonos
  Future<void> cargarBonos() async {
    try {
      final response = await _apiService.obtenerBonos();
      _bonos = response.map((json) => Bono.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Método para asignar horas extras
  Future<bool> asignarHorasExtras(String rendimientoId, double horasExtras) async {
    try {
      await _apiService.asignarHorasExtras(rendimientoId, horasExtras);
      // Recargar los datos después de asignar horas extras
      await cargarRendimientos();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Método para crear nuevo rendimiento
  Future<bool> crearRendimiento({
    required String idActividad,
    required String idColaborador,
    required double rendimiento,
    required double horasTrabajadas,
    required double horasExtras,
    required int idBono,
  }) async {
    try {
      await _apiService.crearRendimientoHorasExtras(
        idActividad: idActividad,
        idColaborador: idColaborador,
        rendimiento: rendimiento,
        horasTrabajadas: horasTrabajadas,
        horasExtras: horasExtras,
        idBono: idBono,
      );
      // Recargar los datos después de crear el rendimiento
      await cargarRendimientos();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Método para establecer filtro de búsqueda
  void setFiltroBusqueda(String query) {
    _filtroBusqueda = query;
    _aplicarFiltros();
  }

  // Método para establecer filtro de colaborador
  void setFiltroColaborador(String colaborador) {
    _filtroColaborador = colaborador;
    _aplicarFiltros();
  }

  // Método para establecer filtro de estado
  void setFiltroEstado(String estado) {
    _filtroEstado = estado;
    _aplicarFiltros();
  }

  // Método para establecer filtro de mes
  void setFiltroMes(int? mes) {
    _filtroMes = mes;
    _aplicarFiltros();
  }

  // Método para establecer filtro de año
  void setFiltroAno(int? ano) {
    _filtroAno = ano;
    _aplicarFiltros();
  }

  // Método para aplicar todos los filtros
  void _aplicarFiltros() {
    List<HorasExtras> filtrados = List.from(_rendimientos);

    // Aplicar filtro de búsqueda
    if (_filtroBusqueda.isNotEmpty) {
      filtrados = filtrados.where((rendimiento) {
        final colaborador = rendimiento.colaborador.toLowerCase();
        final fecha = rendimiento.fechaFormateadaEspanolCompleta.toLowerCase();
        final dia = rendimiento.nombreDia.toLowerCase();
        
        return colaborador.contains(_filtroBusqueda.toLowerCase()) ||
               fecha.contains(_filtroBusqueda.toLowerCase()) ||
               dia.contains(_filtroBusqueda.toLowerCase());
      }).toList();
    }

    // Aplicar filtro de colaborador
    if (_filtroColaborador.isNotEmpty) {
      filtrados = filtrados.where((rendimiento) {
        return rendimiento.colaborador == _filtroColaborador;
      }).toList();
    }

    // Filtrar por mes
    if (_filtroMes != null) {
      filtrados = filtrados.where((rendimiento) => rendimiento.fechaDateTime?.month == _filtroMes).toList();
    }

    // Filtrar por año
    if (_filtroAno != null) {
      filtrados = filtrados.where((rendimiento) => rendimiento.fechaDateTime?.year == _filtroAno).toList();
    }

    // Aplicar filtro de estado
    if (_filtroEstado != 'todos') {
      filtrados = filtrados.where((rendimiento) {
        switch (_filtroEstado) {
          case 'con_horas_extras':
            return rendimiento.actividadesDetalle.any((actividad) => actividad.horasExtras > 0);
          case 'sin_horas_extras':
            return rendimiento.actividadesDetalle.every((actividad) => actividad.horasExtras == 0);
          case 'horas_extras_sobre_permitido':
            return rendimiento.totalHorasExtras > 2;
          default:
            return true;
        }
      }).toList();
    }

    _rendimientosFiltrados = filtrados;
    notifyListeners();
  }

  // Método para limpiar filtros
  void limpiarFiltros() {
    _filtroBusqueda = '';
    _filtroColaborador = '';
    _filtroEstado = 'todos';
    _filtroMes = null;
    _filtroAno = null;
    _rendimientosFiltrados = List.from(_rendimientos);
    notifyListeners();
  }

  // Método para obtener estadísticas
  Map<String, int> get estadisticas {
    // Calcular estadísticas sobre los datos filtrados (excluyendo el filtro de estado)
    List<HorasExtras> datosParaEstadisticas = List.from(_rendimientos);
    
    // Aplicar solo los filtros avanzados, no el filtro de estado
    if (_filtroBusqueda.isNotEmpty) {
      datosParaEstadisticas = datosParaEstadisticas.where((rendimiento) {
        final colaborador = rendimiento.colaborador.toLowerCase();
        final fecha = rendimiento.fechaFormateadaEspanolCompleta.toLowerCase();
        final dia = rendimiento.nombreDia.toLowerCase();
        
        return colaborador.contains(_filtroBusqueda.toLowerCase()) ||
               fecha.contains(_filtroBusqueda.toLowerCase()) ||
               dia.contains(_filtroBusqueda.toLowerCase());
      }).toList();
    }

    if (_filtroColaborador.isNotEmpty) {
      datosParaEstadisticas = datosParaEstadisticas.where((rendimiento) {
        return rendimiento.colaborador == _filtroColaborador;
      }).toList();
    }

    if (_filtroMes != null) {
      datosParaEstadisticas = datosParaEstadisticas.where((rendimiento) => rendimiento.fechaDateTime?.month == _filtroMes).toList();
    }

    if (_filtroAno != null) {
      datosParaEstadisticas = datosParaEstadisticas.where((rendimiento) => rendimiento.fechaDateTime?.year == _filtroAno).toList();
    }

    final conHorasExtras = datosParaEstadisticas.where((r) => 
      r.actividadesDetalle.any((actividad) => actividad.horasExtras > 0)).length;
    final sinHorasExtras = datosParaEstadisticas.where((r) => 
      r.actividadesDetalle.every((actividad) => actividad.horasExtras == 0)).length;
    final horasExtrasSobrePermitido = datosParaEstadisticas.where((r) => 
      r.totalHorasExtras > 2).length; // Más de 2 horas extras en total por día
    final total = datosParaEstadisticas.length;

    return {
      'con_horas_extras': conHorasExtras,
      'sin_horas_extras': sinHorasExtras,
      'horas_extras_sobre_permitido': horasExtrasSobrePermitido,
      'total': total,
    };
  }

  // Método para obtener colaboradores únicos
  List<String> get colaboradoresUnicos {
    final colaboradores = _rendimientos
        .map((r) => r.colaborador)
        .where((colaborador) => colaborador.isNotEmpty)
        .toSet()
        .toList();
    colaboradores.sort();
    return colaboradores;
  }

  // Listas únicas para filtros
  List<int> get mesesUnicos {
    final meses = <int>{};
    for (var rendimiento in _rendimientos) {
      final fecha = rendimiento.fechaDateTime;
      if (fecha != null) {
        meses.add(fecha.month);
      }
    }
    return meses.toList()..sort();
  }

  List<int> get anosUnicos {
    final anos = <int>{};
    for (var rendimiento in _rendimientos) {
      final fecha = rendimiento.fechaDateTime;
      if (fecha != null) {
        anos.add(fecha.year);
      }
    }
    return anos.toList()..sort((a, b) => b.compareTo(a)); // Orden descendente
  }

  // Método privado para establecer loading
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Método para limpiar error
  void limpiarError() {
    _error = null;
    notifyListeners();
  }
}
