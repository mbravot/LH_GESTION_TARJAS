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
  
  // Estadísticas por estado
  int get totalTarjas => _tarjasPropios.length;
  int get tarjasCreadas => _tarjasPropios.where((t) => t.idEstadoActividad == 1).length;
  int get tarjasRevisadas => _tarjasPropios.where((t) => t.idEstadoActividad == 2).length;
  int get tarjasAprobadas => _tarjasPropios.where((t) => t.idEstadoActividad == 3).length;
  
  DateTime? get fechaDesde => _fechaDesde;
  DateTime? get fechaHasta => _fechaHasta;
  String? get idColaborador => _idColaborador;
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

  // Obtener labores únicas de los datos
  List<Map<String, dynamic>> get laboresUnicas {
    final labores = <String, Map<String, dynamic>>{};
    for (var tarja in _tarjasPropios) {
      if (tarja.labor != null && tarja.labor!.isNotEmpty) {
        labores[tarja.labor!] = {
          'id': tarja.idLabor,
          'nombre': tarja.labor,
        };
      }
    }
    return labores.values.toList()..sort((a, b) => a['nombre'].compareTo(b['nombre']));
  }

  void _onAuthChanged() {
    if (_authProvider.isAuthenticated) {
      cargarTarjasPropios();
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
