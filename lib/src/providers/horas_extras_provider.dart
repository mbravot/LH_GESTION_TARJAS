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
  String _filtroEstado = '';
  String _filtroColaborador = '';
  String _filtroActividad = '';
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  // Getters
  List<HorasExtras> get rendimientos => _rendimientos;
  List<HorasExtras> get rendimientosFiltrados => _rendimientosFiltrados;
  List<Bono> get bonos => _bonos;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Getters para filtros
  String get filtroBusqueda => _filtroBusqueda;
  String get filtroEstado => _filtroEstado;
  String get filtroColaborador => _filtroColaborador;
  String get filtroActividad => _filtroActividad;
  DateTime? get fechaInicio => _fechaInicio;
  DateTime? get fechaFin => _fechaFin;

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
        idActividad: _filtroActividad.isNotEmpty ? _filtroActividad : null,
        fechaInicio: _fechaInicio?.toIso8601String().split('T')[0],
        fechaFin: _fechaFin?.toIso8601String().split('T')[0],
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

  // Método para establecer filtro de estado
  void setFiltroEstado(String estado) {
    _filtroEstado = estado;
    _aplicarFiltros();
  }

  // Método para establecer filtro de colaborador
  void setFiltroColaborador(String colaborador) {
    _filtroColaborador = colaborador;
    _aplicarFiltros();
  }

  // Método para establecer filtro de actividad
  void setFiltroActividad(String actividad) {
    _filtroActividad = actividad;
    _aplicarFiltros();
  }

  // Método para establecer filtro de fecha inicio
  void setFechaInicio(DateTime? fecha) {
    _fechaInicio = fecha;
    _aplicarFiltros();
  }

  // Método para establecer filtro de fecha fin
  void setFechaFin(DateTime? fecha) {
    _fechaFin = fecha;
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

    // Aplicar filtro de estado
    if (_filtroEstado.isNotEmpty && _filtroEstado != 'todos') {
      filtrados = filtrados.where((rendimiento) {
        if (_filtroEstado == 'CON_HORAS_EXTRAS') {
          return rendimiento.actividadesDetalle.any((actividad) => actividad.horasExtras > 0);
        } else if (_filtroEstado == 'SIN_HORAS_EXTRAS') {
          return rendimiento.actividadesDetalle.every((actividad) => actividad.horasExtras == 0);
        }
        return true;
      }).toList();
    }

    // Aplicar filtro de colaborador
    if (_filtroColaborador.isNotEmpty) {
      filtrados = filtrados.where((rendimiento) {
        return rendimiento.colaborador == _filtroColaborador;
      }).toList();
    }

    // Aplicar filtro de actividad
    if (_filtroActividad.isNotEmpty) {
      filtrados = filtrados.where((rendimiento) {
        return rendimiento.actividadesDetalle.any((actividad) => 
          actividad.nombreActividad.contains(_filtroActividad));
      }).toList();
    }

    _rendimientosFiltrados = filtrados;
    notifyListeners();
  }

  // Método para limpiar filtros
  void limpiarFiltros() {
    _filtroBusqueda = '';
    _filtroEstado = '';
    _filtroColaborador = '';
    _filtroActividad = '';
    _fechaInicio = null;
    _fechaFin = null;
    _rendimientosFiltrados = List.from(_rendimientos);
    notifyListeners();
  }

  // Método para obtener estadísticas
  Map<String, int> get estadisticas {
    final conHorasExtras = _rendimientos.where((r) => 
      r.actividadesDetalle.any((actividad) => actividad.horasExtras > 0)).length;
    final sinHorasExtras = _rendimientos.where((r) => 
      r.actividadesDetalle.every((actividad) => actividad.horasExtras == 0)).length;
    final total = _rendimientos.length;

    return {
      'con_horas_extras': conHorasExtras,
      'sin_horas_extras': sinHorasExtras,
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

  // Método para obtener actividades únicas
  List<String> get actividadesUnicas {
    final actividades = _rendimientos
        .expand((r) => r.actividadesDetalle)
        .map((actividad) => actividad.nombreActividad)
        .where((actividad) => actividad.isNotEmpty)
        .toSet()
        .toList();
    actividades.sort();
    return actividades;
  }

  // Método para obtener estados únicos
  List<String> get estadosUnicos {
    final estados = _rendimientos
        .map((r) => r.estadoTrabajo)
        .where((estado) => estado.isNotEmpty)
        .toSet()
        .toList();
    estados.sort();
    return estados;
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
