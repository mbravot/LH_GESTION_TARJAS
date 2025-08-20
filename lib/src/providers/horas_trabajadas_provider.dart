import 'package:flutter/material.dart';
import '../models/horas_trabajadas.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class HorasTrabajadasProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  AuthProvider? _authProvider;
  
  List<HorasTrabajadas> _horasTrabajadas = [];
  List<HorasTrabajadas> _horasTrabajadasFiltradas = [];
  bool _isLoading = false;
  String? _error;
  
  // Variables para filtros
  String _filtroBusqueda = '';
  String _filtroEstado = '';
  String _filtroColaborador = '';
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  // Getters
  List<HorasTrabajadas> get horasTrabajadas => _horasTrabajadas;
  List<HorasTrabajadas> get horasTrabajadasFiltradas => _horasTrabajadasFiltradas;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Getters para filtros
  String get filtroBusqueda => _filtroBusqueda;
  String get filtroEstado => _filtroEstado;
  String get filtroColaborador => _filtroColaborador;
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
      cargarHorasTrabajadas();
    }
  }

  @override
  void dispose() {
    if (_authProvider != null) {
      _authProvider!.removeListener(_onSucursalChanged);
    }
    super.dispose();
  }

  // Método para cargar horas trabajadas
  Future<void> cargarHorasTrabajadas() async {
    _setLoading(true);
    _error = null;
    
    try {
      final response = await _apiService.obtenerResumenHorasDiarias(
        fechaInicio: _fechaInicio?.toIso8601String().split('T')[0],
        fechaFin: _fechaFin?.toIso8601String().split('T')[0],
        idColaborador: _filtroColaborador.isNotEmpty ? _filtroColaborador : null,
      );
      
      _horasTrabajadas = response.map((json) => HorasTrabajadas.fromJson(json)).toList();
      _aplicarFiltros();
      
      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
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
    List<HorasTrabajadas> filtrados = List.from(_horasTrabajadas);

    // Aplicar filtro de búsqueda
    if (_filtroBusqueda.isNotEmpty) {
      filtrados = filtrados.where((horas) {
        final colaborador = horas.colaborador.toLowerCase();
        final fecha = horas.fechaFormateadaEspanol.toLowerCase();
        final dia = horas.nombreDia.toLowerCase();
        
        return colaborador.contains(_filtroBusqueda.toLowerCase()) ||
               fecha.contains(_filtroBusqueda.toLowerCase()) ||
               dia.contains(_filtroBusqueda.toLowerCase());
      }).toList();
    }

    // Aplicar filtro de estado
    if (_filtroEstado.isNotEmpty && _filtroEstado != 'todos') {
      filtrados = filtrados.where((horas) {
        return horas.estadoTrabajo == _filtroEstado;
      }).toList();
    }

    // Aplicar filtro de colaborador
    if (_filtroColaborador.isNotEmpty) {
      filtrados = filtrados.where((horas) {
        return horas.idColaborador == _filtroColaborador;
      }).toList();
    }

    _horasTrabajadasFiltradas = filtrados;
    notifyListeners();
  }

  // Método para limpiar filtros
  void limpiarFiltros() {
    _filtroBusqueda = '';
    _filtroEstado = '';
    _filtroColaborador = '';
    _fechaInicio = null;
    _fechaFin = null;
    _horasTrabajadasFiltradas = List.from(_horasTrabajadas);
    notifyListeners();
  }

  // Método para obtener estadísticas
  Map<String, int> get estadisticas {
    final masHoras = _horasTrabajadas.where((h) => h.estadoTrabajo == 'MÁS').length;
    final menosHoras = _horasTrabajadas.where((h) => h.estadoTrabajo == 'MENOS').length;
    final exactas = _horasTrabajadas.where((h) => h.estadoTrabajo == 'EXACTO').length;
    final total = _horasTrabajadas.length;

    return {
      'mas_horas': masHoras,
      'menos_horas': menosHoras,
      'exactas': exactas,
      'total': total,
    };
  }

  // Método para obtener colaboradores únicos
  List<String> get colaboradoresUnicos {
    final colaboradores = _horasTrabajadas
        .map((h) => h.colaborador)
        .where((colaborador) => colaborador.isNotEmpty)
        .toSet()
        .toList();
    colaboradores.sort();
    return colaboradores;
  }

  // Método para obtener estados únicos
  List<String> get estadosUnicos {
    final estados = _horasTrabajadas
        .map((h) => h.estadoTrabajo)
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
