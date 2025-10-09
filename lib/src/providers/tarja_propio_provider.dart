import 'package:flutter/material.dart';
import '../models/tarja_propio.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class TarjaPropioProvider extends ChangeNotifier {
  final AuthProvider _authProvider;
  
  List<TarjaPropio> _tarjasPropios = [];
  List<TarjaPropioResumen> _resumenColaboradores = [];
  bool _isLoading = false;
  String? _error;
  int _total = 0;

  // Filtros
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  String? _idColaborador;
  String? _idSupervisor;
  int? _idLabor;
  int? _idCeco;
  int? _idEstadoActividad;
  int? _filtroMes;
  int? _filtroAno;

  TarjaPropioProvider(this._authProvider) {
    _authProvider.addListener(_onAuthChanged);
  }

  // Getters
  List<TarjaPropio> get tarjasPropios => _tarjasPropios;
  List<TarjaPropioResumen> get resumenColaboradores => _resumenColaboradores;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get total => _total;
  
  // Estadísticas por estado - igual que Colaboradores: solo filtro por búsqueda, NO por indicadores
  int get totalTarjas {
    // Solo usar filtros de búsqueda, NO filtros de indicadores
    return _tarjasPropios.length;
  }
  
  int get tarjasCreadas {
    // Solo usar filtros de búsqueda, NO filtros de indicadores
    return _tarjasPropios.where((t) => t.idEstadoActividad == 1).length;
  }
  
  int get tarjasRevisadas {
    // Solo usar filtros de búsqueda, NO filtros de indicadores
    return _tarjasPropios.where((t) => t.idEstadoActividad == 2).length;
  }
  
  int get tarjasAprobadas {
    // Solo usar filtros de búsqueda, NO filtros de indicadores
    return _tarjasPropios.where((t) => t.idEstadoActividad == 3).length;
  }
  
  // Datos únicos para filtros (actualizados dinámicamente)
  List<Map<String, dynamic>> get supervisoresUnicos {
    final supervisores = <String, Map<String, dynamic>>{};
    for (final tarja in _tarjasPropios) {
      // Aplicar filtros existentes
      if (_aplicaFiltros(tarja) && tarja.usuario.isNotEmpty) {
        supervisores[tarja.usuario] = {
          'id': tarja.usuario,
          'nombre': tarja.usuario,
        };
      }
    }
    return supervisores.values.toList()
      ..sort((a, b) => a['nombre'].compareTo(b['nombre']));
  }
  
  List<Map<String, dynamic>> get cecosUnicos {
    final cecos = <String, Map<String, dynamic>>{};
    for (final tarja in _tarjasPropios) {
      // Aplicar filtros existentes
      if (_aplicaFiltros(tarja) && tarja.centroDeCosto.isNotEmpty) {
        cecos[tarja.centroDeCosto] = {
          'id': tarja.idCeco,
          'nombre': tarja.centroDeCosto,
        };
      }
    }
    return cecos.values.toList()
      ..sort((a, b) => a['nombre'].compareTo(b['nombre']));
  }

  List<Map<String, dynamic>> get laboresUnicas {
    final labores = <String, Map<String, dynamic>>{};
    for (final tarja in _tarjasPropios) {
      // Aplicar filtros existentes
      if (_aplicaFiltros(tarja) && tarja.labor.isNotEmpty) {
        labores[tarja.labor] = {
          'id': tarja.idLabor,
          'nombre': tarja.labor,
        };
      }
    }
    return labores.values.toList()
      ..sort((a, b) => a['nombre'].compareTo(b['nombre']));
  }

  // Getter público para obtener tarjas filtradas (sin incluir filtro de estado)
  List<TarjaPropio> get tarjasPropiosFiltradasSinEstado {
    return _tarjasPropios.where((tarja) => _aplicaFiltrosSinEstado(tarja)).toList();
  }

  // Método auxiliar para verificar si una tarja aplica a los filtros actuales
  bool _aplicaFiltros(TarjaPropio tarja) {
    // Si hay filtro de colaborador, verificar que coincida
    if (_idColaborador != null && tarja.idColaborador != _idColaborador) {
      return false;
    }
    
    // Si hay filtro de supervisor, verificar que coincida
    if (_idSupervisor != null && tarja.usuario != _idSupervisor) {
      return false;
    }
    
    // Si hay filtro de labor, verificar que coincida
    if (_idLabor != null && tarja.idLabor != _idLabor) {
      return false;
    }
    
    // Si hay filtro de CECO, verificar que coincida
    if (_idCeco != null && tarja.idCeco != _idCeco) {
      return false;
    }
    
    // Si hay filtro de mes, verificar que coincida
    if (_filtroMes != null) {
      try {
        final fecha = DateTime.parse(tarja.fecha);
        if (fecha.month != _filtroMes) {
          return false;
        }
      } catch (e) {
        return false;
      }
    }
    
    // Si hay filtro de año, verificar que coincida
    if (_filtroAno != null) {
      try {
        final fecha = DateTime.parse(tarja.fecha);
        if (fecha.year != _filtroAno) {
          return false;
        }
      } catch (e) {
        return false;
      }
    }
    
    return true;
  }

  // Método auxiliar para verificar si una tarja aplica a los filtros actuales (sin incluir estado)
  bool _aplicaFiltrosSinEstado(TarjaPropio tarja) {
    // Si hay filtro de colaborador, verificar que coincida
    if (_idColaborador != null && tarja.idColaborador != _idColaborador) {
      return false;
    }
    
    // Si hay filtro de supervisor, verificar que coincida
    if (_idSupervisor != null && tarja.usuario != _idSupervisor) {
      return false;
    }
    
    // Si hay filtro de labor, verificar que coincida
    if (_idLabor != null && tarja.idLabor != _idLabor) {
      return false;
    }
    
    // Si hay filtro de CECO, verificar que coincida
    if (_idCeco != null && tarja.idCeco != _idCeco) {
      return false;
    }
    
    // Si hay filtro de mes, verificar que coincida
    if (_filtroMes != null) {
      try {
        final fecha = DateTime.parse(tarja.fecha);
        if (fecha.month != _filtroMes) {
          return false;
        }
      } catch (e) {
        return false;
      }
    }
    
    // Si hay filtro de año, verificar que coincida
    if (_filtroAno != null) {
      try {
        final fecha = DateTime.parse(tarja.fecha);
        if (fecha.year != _filtroAno) {
          return false;
        }
      } catch (e) {
        return false;
      }
    }
    
    return true;
  }

  // Método auxiliar para verificar si hay filtros avanzados activos (sin incluir estado)
  bool _tieneFiltrosAvanzados() {
    return _idColaborador != null || 
           _idSupervisor != null || 
           _idLabor != null || 
           _idCeco != null || 
           _filtroMes != null || 
           _filtroAno != null;
  }

  // Método auxiliar para aplicar filtros sin incluir el filtro de estado
  List<TarjaPropio> _aplicarFiltrosSinEstado() {
    return _tarjasPropios.where((tarja) {
      // Si hay filtro de colaborador, verificar que coincida
      if (_idColaborador != null && tarja.idColaborador != _idColaborador) {
        return false;
      }
      
      // Si hay filtro de supervisor, verificar que coincida
      if (_idSupervisor != null && tarja.usuario != _idSupervisor) {
        return false;
      }
      
      // Si hay filtro de labor, verificar que coincida
      if (_idLabor != null && tarja.idLabor != _idLabor) {
        return false;
      }
      
      // Si hay filtro de CECO, verificar que coincida
      if (_idCeco != null && tarja.idCeco != _idCeco) {
        return false;
      }
      
      // Si hay filtro de mes, verificar que coincida
      if (_filtroMes != null) {
        try {
          final fecha = DateTime.parse(tarja.fecha);
          if (fecha.month != _filtroMes) {
            return false;
          }
        } catch (e) {
          return false;
        }
      }
      
      // Si hay filtro de año, verificar que coincida
      if (_filtroAno != null) {
        try {
          final fecha = DateTime.parse(tarja.fecha);
          if (fecha.year != _filtroAno) {
            return false;
          }
        } catch (e) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }
  
  DateTime? get fechaDesde => _fechaDesde;
  DateTime? get fechaHasta => _fechaHasta;
  String? get idColaborador => _idColaborador;
  String? get idSupervisor => _idSupervisor;
  int? get idLabor => _idLabor;
  int? get idCeco => _idCeco;
  int? get idEstadoActividad => _idEstadoActividad;
  int? get filtroMes => _filtroMes;
  int? get filtroAno => _filtroAno;

  // Obtener meses únicos de los datos
  List<int> get mesesUnicos {
    final meses = <int>{};
    for (var tarja in _tarjasPropios) {
      final fecha = TarjaPropio.parseFecha(tarja.fecha);
      if (fecha != null) {
        meses.add(fecha.month);
      }
    }
    return meses.toList()..sort();
  }

  // Obtener años únicos de los datos
  List<int> get anosUnicos {
    final anos = <int>{};
    for (var tarja in _tarjasPropios) {
      final fecha = TarjaPropio.parseFecha(tarja.fecha);
      if (fecha != null) {
        anos.add(fecha.year);
      }
    }
    return anos.toList()..sort();
  }


  void _onAuthChanged() {
    if (_authProvider.isAuthenticated) {
      // Solo limpiar datos, no cargar automáticamente
      _tarjasPropios = [];
      _resumenColaboradores = [];
      notifyListeners();
    } else {
      _clearData();
    }
  }

  void _clearData() {
    _tarjasPropios.clear();
    _resumenColaboradores.clear();
    _total = 0;
    _error = null;
    notifyListeners();
  }

  Future<void> cargarTarjasPropios() async {
    if (_isLoading) return;
    
    // Si ya hay datos, no recargar
    if (_tarjasPropios.isNotEmpty && !_isLoading) {
      return;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.obtenerTarjasPropios(
        fechaDesde: _fechaDesde,
        fechaHasta: _fechaHasta,
        idColaborador: _idColaborador,
        idLabor: _idLabor,
        idCeco: _idCeco,
        idEstadoActividad: _idEstadoActividad,
      );

      _tarjasPropios = (response['tarjas_propios'] as List)
          .map((json) => TarjaPropio.fromJson(json))
          .toList();
      _total = response['total'] ?? 0;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _tarjasPropios.clear();
      _total = 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cargarResumenColaboradores() async {
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.obtenerTarjasPropiosResumen(
        fechaDesde: _fechaDesde,
        fechaHasta: _fechaHasta,
        idColaborador: _idColaborador,
        idLabor: _idLabor,
        idCeco: _idCeco,
        idEstadoActividad: _idEstadoActividad,
      );

      _resumenColaboradores = (response['resumen'] as List)
          .map((json) => TarjaPropioResumen.fromJson(json))
          .toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _resumenColaboradores.clear();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Métodos para manejar filtros
  void setFechaDesde(DateTime? fecha) {
    _fechaDesde = fecha;
    notifyListeners();
  }

  void setFechaHasta(DateTime? fecha) {
    _fechaHasta = fecha;
    notifyListeners();
  }

  void setIdColaborador(String? id) {
    _idColaborador = id;
    // Limpiar supervisor cuando se selecciona colaborador
    if (id != null) {
      _idSupervisor = null;
    }
    // Notificar cambios inmediatamente para actualizar la UI
    notifyListeners();
    aplicarFiltros();
  }

  void setIdSupervisor(String? id) {
    _idSupervisor = id;
    // Limpiar colaborador cuando se selecciona supervisor
    if (id != null) {
      _idColaborador = null;
    }
    // Notificar cambios inmediatamente para actualizar la UI
    notifyListeners();
    aplicarFiltros();
  }

  void setIdLabor(int? id) {
    _idLabor = id;
    aplicarFiltros();
  }

  void setIdCeco(int? id) {
    _idCeco = id;
    aplicarFiltros();
  }

  void setIdEstadoActividad(int? id) {
    _idEstadoActividad = id;
    aplicarFiltros();
  }

  void setFiltroMes(int? mes) {
    _filtroMes = mes;
    aplicarFiltros();
  }

  void setFiltroAno(int? ano) {
    _filtroAno = ano;
    aplicarFiltros();
  }

  void limpiarFiltros() {
    _fechaDesde = null;
    _fechaHasta = null;
    _idColaborador = null;
    _idSupervisor = null;
    _idLabor = null;
    _idCeco = null;
    _idEstadoActividad = null;
    _filtroMes = null;
    _filtroAno = null;
    aplicarFiltros();
  }

  void aplicarFiltros() {
    cargarTarjasPropios();
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthChanged);
    super.dispose();
  }
}
