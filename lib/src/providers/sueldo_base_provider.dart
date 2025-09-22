import 'package:flutter/foundation.dart';
import '../models/sueldo_base.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';
import 'session_handler_mixin.dart';
import 'notification_provider.dart';

class SueldoBaseProvider extends ChangeNotifier with SessionHandlerMixin {
  List<SueldoBaseAgrupado> _sueldosBaseAgrupados = [];
  List<SueldoBase> _sueldosBase = [];
  List<SueldoBase> _sueldosBaseFiltrados = [];
  bool _isLoading = false;
  String? _error;
  String? _idSucursal;
  AuthProvider? _authProvider;
  NotificationProvider? _notificationProvider;

  // Filtros
  String _filtroColaborador = '';
  String _filtroFecha = '';

  // Getters
  List<SueldoBaseAgrupado> get sueldosBaseAgrupados => _sueldosBaseAgrupados;
  List<SueldoBase> get sueldosBase => _sueldosBase;
  List<SueldoBase> get sueldosBaseFiltrados => _sueldosBaseFiltrados;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Getters para filtros
  String get filtroColaborador => _filtroColaborador;
  String get filtroFecha => _filtroFecha;

  // Listas únicas para filtros
  List<String> get colaboradoresUnicos {
    final colaboradores = <String>{};
    for (var sueldo in _sueldosBase) {
      if (sueldo.nombreColaborador != null && sueldo.nombreColaborador!.isNotEmpty) {
        colaboradores.add(sueldo.nombreColaborador!);
      }
    }
    return colaboradores.toList()..sort();
  }

  List<String> get fechasUnicas {
    final fechas = <String>{};
    for (var sueldo in _sueldosBase) {
      fechas.add(sueldo.fechaFormateada);
    }
    return fechas.toList()..sort();
  }

  // Inicializar provider
  void initialize(AuthProvider authProvider, NotificationProvider notificationProvider) {
    _authProvider = authProvider;
    _notificationProvider = notificationProvider;
    _authProvider!.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    _checkAndUpdateSucursal();
  }

  // Verificar si cambió la sucursal y actualizar si es necesario
  void _checkAndUpdateSucursal() {
    if (_authProvider?.userData != null && _authProvider!.userData!['id_sucursal'] != null) {
      final nuevaSucursalId = _authProvider!.userData!['id_sucursal'].toString();
      if (_idSucursal != nuevaSucursalId) {
        _idSucursal = nuevaSucursalId;
        cargarSueldosBase();
      }
    }
  }

  // Setter para la sucursal (mantener para compatibilidad)
  void setIdSucursal(String idSucursal) {
    _idSucursal = idSucursal;
    cargarSueldosBase();
  }

  // Cargar sueldos base
  Future<void> cargarSueldosBase() async {
    if (_idSucursal == null) {
      _error = 'No se ha especificado una sucursal';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      
      final result = await handleApiError(
        () => ApiService.obtenerSueldosBase(),
        _authProvider!,
        _notificationProvider,
      );
      
      
      if (result != null) {
        
        try {
          // Procesar estructura agrupada (ahora con array real)
          _sueldosBaseAgrupados = result.map((json) {
            final grupo = SueldoBaseAgrupado.fromJson(json);
            return grupo;
          }).toList();
          
          // Convertir a lista plana para compatibilidad
          _sueldosBase = [];
          for (var grupo in _sueldosBaseAgrupados) {
            _sueldosBase.addAll(grupo.sueldosBase);
          }
          
          _aplicarFiltros();
          _error = null;
        } catch (parseError) {
          _error = 'Error al procesar datos: $parseError';
        }
      } else {
        return;
      }
    } catch (e) {
      _error = e.toString();
      _sueldosBaseAgrupados = [];
      _sueldosBase = [];
      _sueldosBaseFiltrados = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Métodos para filtros
  void setFiltroColaborador(String value) {
    _filtroColaborador = value;
    _aplicarFiltros();
  }

  void setFiltroFecha(String value) {
    _filtroFecha = value;
    _aplicarFiltros();
  }

  void limpiarFiltros() {
    _filtroColaborador = '';
    _filtroFecha = '';
    _aplicarFiltros();
  }

  void _aplicarFiltros() {
    _sueldosBaseFiltrados = _sueldosBase.where((sueldo) {
      // Filtro por colaborador
      if (_filtroColaborador.isNotEmpty) {
        if (sueldo.nombreColaborador == null || 
            !sueldo.nombreColaborador!.toLowerCase().contains(_filtroColaborador.toLowerCase())) {
          return false;
        }
      }

      // Filtro por fecha
      if (_filtroFecha.isNotEmpty) {
        if (sueldo.fechaFormateada != _filtroFecha) {
          return false;
        }
      }

      return true;
    }).toList();

    notifyListeners();
  }

  // Crear sueldo base
  Future<bool> crearSueldoBase(SueldoBase sueldoBase) async {
    try {
      final result = await handleApiError(
        () => ApiService.crearSueldoBase(sueldoBase.toCreateJson()),
        _authProvider!,
        _notificationProvider,
      );
      
      if (result != null) {
        await cargarSueldosBase();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Actualizar sueldo base
  Future<bool> actualizarSueldoBase(SueldoBase sueldoBase) async {
    try {
      final result = await handleApiError(
        () => ApiService.actualizarSueldoBase(sueldoBase.id.toString(), sueldoBase.toUpdateJson()),
        _authProvider!,
        _notificationProvider,
      );
      
      if (result != null) {
        await cargarSueldosBase();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Eliminar sueldo base
  Future<bool> eliminarSueldoBase(int id) async {
    try {
      await handleApiError(
        () => ApiService.eliminarSueldoBase(id.toString()),
        _authProvider!,
        _notificationProvider,
      );
      
      await cargarSueldosBase();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Obtener sueldo base por ID
  Future<SueldoBase?> obtenerSueldoBasePorId(int id) async {
    try {
      final result = await handleApiError(
        () => ApiService.obtenerSueldoBasePorId(id.toString()),
        _authProvider!,
        _notificationProvider,
      );
      
      if (result != null) {
        return SueldoBase.fromJson(result);
      }
      return null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Obtener sueldos base por colaborador
  Future<List<SueldoBase>?> obtenerSueldosBasePorColaborador(String idColaborador) async {
    try {
      final result = await handleApiError(
        () => ApiService.obtenerSueldosBasePorColaborador(idColaborador),
        _authProvider!,
        _notificationProvider,
      );
      
      if (result != null && result['sueldos_base'] != null) {
        final List<dynamic> sueldosList = result['sueldos_base'];
        return sueldosList.map((json) => SueldoBase.fromJson(json)).toList();
      }
      return null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
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