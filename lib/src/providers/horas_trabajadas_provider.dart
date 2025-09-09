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
  String _filtroColaborador = '';
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  int? _filtroMes;
  int? _filtroAno;

  // Getters
  List<HorasTrabajadas> get horasTrabajadas => _horasTrabajadas;
  List<HorasTrabajadas> get horasTrabajadasFiltradas => _horasTrabajadasFiltradas;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Getters para filtros
  String get filtroBusqueda => _filtroBusqueda;
  String get filtroColaborador => _filtroColaborador;
  DateTime? get fechaInicio => _fechaInicio;
  DateTime? get fechaFin => _fechaFin;
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

    // Aplicar filtro de colaborador
    if (_filtroColaborador.isNotEmpty) {
      filtrados = filtrados.where((horas) {
        return horas.colaborador == _filtroColaborador;
      }).toList();
    }

    // Filtrar por mes
    if (_filtroMes != null) {
      filtrados = filtrados.where((horas) => horas.fechaDateTime?.month == _filtroMes).toList();
    }

    // Filtrar por año
    if (_filtroAno != null) {
      filtrados = filtrados.where((horas) => horas.fechaDateTime?.year == _filtroAno).toList();
    }

    _horasTrabajadasFiltradas = filtrados;
    notifyListeners();
  }

  // Listas únicas para filtros
  List<int> get mesesUnicos {
    final meses = <int>{};
    for (var horas in _horasTrabajadas) {
      final fecha = horas.fechaDateTime;
      if (fecha != null) {
        meses.add(fecha.month);
      }
    }
    return meses.toList()..sort();
  }

  List<int> get anosUnicos {
    final anos = <int>{};
    for (var horas in _horasTrabajadas) {
      final fecha = horas.fechaDateTime;
      if (fecha != null) {
        anos.add(fecha.year);
      }
    }
    return anos.toList()..sort((a, b) => b.compareTo(a)); // Orden descendente
  }

  // Método para limpiar filtros
  void limpiarFiltros() {
    _filtroBusqueda = '';
    _filtroColaborador = '';
    _fechaInicio = null;
    _fechaFin = null;
    _filtroMes = null;
    _filtroAno = null;
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

  // Método para actualizar horas trabajadas de un colaborador en una actividad
  Future<Map<String, dynamic>?> actualizarHorasColaborador({
    required String rendimientoId,
    required double horasTrabajadas,
    required double horasExtras,
  }) async {
    try {
      final response = await ApiService.actualizarHorasColaborador(
        rendimientoId: rendimientoId,
        horasTrabajadas: horasTrabajadas,
        horasExtras: horasExtras,
      );
      
      // Recargar los datos para reflejar los cambios
      await cargarHorasTrabajadas();
      
      return response;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
