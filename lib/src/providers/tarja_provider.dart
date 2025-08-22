import 'package:flutter/foundation.dart';
import '../models/tarja.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class TarjaProvider extends ChangeNotifier {
  List<Tarja> _tarjas = [];
  List<Tarja> _tarjasFiltradas = [];
  bool _isLoading = false;
  String? _error;
  String? _idSucursal;
  AuthProvider? _authProvider;

  // Filtros
  String _filtroContratista = '';
  String _filtroTipoRendimiento = '';

  // Getters
  List<Tarja> get tarjas => _tarjas;
  List<Tarja> get tarjasFiltradas => _tarjasFiltradas;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Getters para filtros
  String get filtroContratista => _filtroContratista;
  String get filtroTipoRendimiento => _filtroTipoRendimiento;

  // Listas únicas para filtros
  List<String> get contratistasUnicos {
    final contratistas = <String>{};
    for (var tarja in _tarjas) {
      if (tarja.idContratista != null && tarja.idContratista!.isNotEmpty) {
        contratistas.add(tarja.contratista ?? 'Contratista');
      } else {
        contratistas.add('PROPIO');
      }
    }
    return contratistas.toList()..sort();
  }

  List<String> get tiposRendimientoUnicos {
    final tipos = <String>{};
    for (var tarja in _tarjas) {
      if (tarja.idTiporendimiento == '1') {
        tipos.add('Individual');
      } else if (tarja.idTiporendimiento == '2') {
        tipos.add('Grupal');
      }
    }
    return tipos.toList()..sort();
  }

  // Método para configurar el AuthProvider y escuchar cambios
  void setAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;
    _authProvider!.addListener(_onAuthChanged);
    _checkAndUpdateSucursal();
  }

  // Escuchar cambios en el AuthProvider
  void _onAuthChanged() {
    _checkAndUpdateSucursal();
  }

  // Verificar si cambió la sucursal y actualizar si es necesario
  void _checkAndUpdateSucursal() {
    if (_authProvider?.userData != null && _authProvider!.userData!['id_sucursal'] != null) {
      final nuevaSucursalId = _authProvider!.userData!['id_sucursal'].toString();
      if (_idSucursal != nuevaSucursalId) {
        _idSucursal = nuevaSucursalId;
        cargarTarjas();
      }
    }
  }

  // Setter para la sucursal (mantener para compatibilidad)
  void setIdSucursal(String idSucursal) {
    _idSucursal = idSucursal;
    cargarTarjas();
  }

  // Cargar tarjas
  Future<void> cargarTarjas() async {
    if (_idSucursal == null) {
      _error = 'No se ha especificado una sucursal';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tarjas = await ApiService().getTarjasByDate(DateTime.now(), _idSucursal!);
      _aplicarFiltros();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _tarjas = [];
      _tarjasFiltradas = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Métodos para filtros
  void setFiltroContratista(String value) {
    _filtroContratista = value;
    _aplicarFiltros();
  }

  void setFiltroTipoRendimiento(String value) {
    _filtroTipoRendimiento = value;
    _aplicarFiltros();
  }

  void limpiarFiltros() {
    _filtroContratista = '';
    _filtroTipoRendimiento = '';
    _aplicarFiltros();
  }

  void _aplicarFiltros() {
    _tarjasFiltradas = _tarjas.where((tarja) {
      // Filtro por contratista
      if (_filtroContratista.isNotEmpty) {
        final esPropio = tarja.idContratista == null || tarja.idContratista!.isEmpty;
        final nombreContratista = esPropio ? 'PROPIO' : (tarja.contratista ?? 'Contratista');
        
        if (nombreContratista != _filtroContratista) {
          return false;
        }
      }

      // Filtro por tipo de rendimiento
      if (_filtroTipoRendimiento.isNotEmpty) {
        String tipoRendimiento;
        if (tarja.idTiporendimiento == '1') {
          tipoRendimiento = 'Individual';
        } else if (tarja.idTiporendimiento == '2') {
          tipoRendimiento = 'Grupal';
        } else {
          tipoRendimiento = 'Individual'; // Por defecto
        }
        
        if (tipoRendimiento != _filtroTipoRendimiento) {
          return false;
        }
      }

      return true;
    }).toList();

    notifyListeners();
  }

  // Actualizar tarja
  Future<void> actualizarTarja(String id, Map<String, dynamic> datos) async {
    try {
      await ApiService().actualizarTarja(id, datos);
      await cargarTarjas();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Limpiar error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authProvider?.removeListener(_onAuthChanged);
    super.dispose();
  }
} 