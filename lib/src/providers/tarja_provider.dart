import 'package:flutter/foundation.dart';
import '../models/tarja.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';
import 'session_handler_mixin.dart';
import 'notification_provider.dart';

class TarjaProvider extends ChangeNotifier with SessionHandlerMixin {
  List<Tarja> _tarjas = [];
  List<Tarja> _tarjasFiltradas = [];
  bool _isLoading = false;
  String? _error;
  String? _idSucursal;
  AuthProvider? _authProvider;
  NotificationProvider? _notificationProvider;
  
  // Cache de usuarios
  Map<String, String> _mapeoUsuarios = {};
  bool _usuariosCargados = false;

  // Filtros
  String _filtroContratista = '';
  String _filtroTipoRendimiento = '';
  String _filtroUsuario = '';
  String _filtroTipoCeco = '';

  // Getters
  List<Tarja> get tarjas => _tarjas;
  List<Tarja> get tarjasFiltradas => _tarjasFiltradas;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Getters para filtros
  String get filtroContratista => _filtroContratista;
  String get filtroTipoRendimiento => _filtroTipoRendimiento;
  String get filtroUsuario => _filtroUsuario;
  String get filtroTipoCeco => _filtroTipoCeco;

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
      } else if (tarja.idTiporendimiento == '3') {
        tipos.add('Múltiple');
      }
    }
    return tipos.toList()..sort();
  }

  List<String> get usuariosUnicos {
    final usuarios = <String>{};
    for (var tarja in _tarjas) {
      if (tarja.nombreUsuario != null && tarja.nombreUsuario!.isNotEmpty) {
        // Usar el nombre completo del usuario si está disponible
        final nombreCompleto = _getNombreCompletoUsuario(tarja.nombreUsuario);
        usuarios.add(nombreCompleto);
      }
    }
    return usuarios.toList()..sort();
  }

  List<String> get tiposCecoUnicos {
    final tiposCeco = <String>{};
    for (var tarja in _tarjas) {
      if (tarja.nombreTipoceco != null && tarja.nombreTipoceco!.isNotEmpty) {
        tiposCeco.add(tarja.nombreTipoceco!);
      }
    }
    return tiposCeco.toList()..sort();
  }

  // Helper para convertir nombre de usuario corto a nombre completo
  String _getNombreCompletoUsuario(String? nombreUsuario) {
    if (nombreUsuario == null || nombreUsuario.isEmpty) {
      return 'No especificado';
    }
    
    // Si el nombre ya parece ser un nombre completo (contiene espacios), usarlo directamente
    if (nombreUsuario.contains(' ')) {
      return nombreUsuario;
    }
    
    // Si tenemos el mapeo dinámico cargado, usarlo
    if (_mapeoUsuarios.isNotEmpty) {
      return _mapeoUsuarios[nombreUsuario.toLowerCase()] ?? nombreUsuario;
    }
    
    // Fallback al mapeo estático para casos de emergencia
    final Map<String, String> mapeoEstatico = {
      'galarcon': 'Gonzalo Alarcón',
      'mbravo': 'Miguel Bravo',
      'jperez': 'Juan Pérez',
      'mgarcia': 'María García',
      'lrodriguez': 'Luis Rodríguez',
      'asanchez': 'Ana Sánchez',
      'cmartinez': 'Carlos Martínez',
      'plopez': 'Patricia López',
      'rgonzalez': 'Roberto González',
      'dhernandez': 'Daniel Hernández',
    };
    
    return mapeoEstatico[nombreUsuario.toLowerCase()] ?? nombreUsuario;
  }

  // Método para configurar el AuthProvider y escuchar cambios
  void setAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;
    _authProvider!.addListener(_onAuthChanged);
    _checkAndUpdateSucursal();
  }

  // Método para configurar el NotificationProvider
  void setNotificationProvider(NotificationProvider notificationProvider) {
    _notificationProvider = notificationProvider;
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

  // Cargar usuarios
  Future<void> cargarUsuarios() async {
    if (_usuariosCargados) return; // Ya están cargados
    
    try {
      final usuarios = await handleApiError(
        () => ApiService.obtenerUsuarios(),
        _authProvider!,
        _notificationProvider,
      );
      
      if (usuarios != null) {
        _mapeoUsuarios.clear();
        for (var usuario in usuarios) {
          final username = usuario['usuario']?.toString().toLowerCase();
          final nombreCompleto = usuario['nombre_completo']?.toString() ?? '';
          
          if (username != null && username.isNotEmpty && nombreCompleto.isNotEmpty) {
            _mapeoUsuarios[username] = nombreCompleto;
          }
        }
        _usuariosCargados = true;
        notifyListeners();
      }
    } catch (e) {
      // Si falla la carga de usuarios, continuar con el mapeo estático
      // print('⚠️ No se pudieron cargar usuarios: $e');
    }
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
      // Cargar usuarios solo si es necesario (no durante cambio de sucursal)
      // if (!_usuariosCargados) {
      //   cargarUsuarios();
      // }
      
      final result = await handleApiError(
        () => ApiService().getTarjasByDate(DateTime.now(), _idSucursal!),
        _authProvider!,
        _notificationProvider,
      );
      
      if (result != null) {
        _tarjas = result;
        _aplicarFiltros();
        _error = null;
      } else {
        // Sesión expirada, no hacer nada más aquí
        return;
      }
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

  void setFiltroUsuario(String value) {
    _filtroUsuario = value;
    _aplicarFiltros();
  }

  void setFiltroTipoCeco(String value) {
    _filtroTipoCeco = value;
    _aplicarFiltros();
  }

  void limpiarFiltros() {
    _filtroContratista = '';
    _filtroTipoRendimiento = '';
    _filtroUsuario = '';
    _filtroTipoCeco = '';
    _aplicarFiltros();
  }

  // Cargar usuarios solo cuando sea necesario
  Future<void> cargarUsuariosSiEsNecesario() async {
    if (!_usuariosCargados) {
      await cargarUsuarios();
    }
  }

  // Forzar recarga de usuarios
  Future<void> recargarUsuarios() async {
    _usuariosCargados = false;
    _mapeoUsuarios.clear();
    await cargarUsuarios();
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
        } else if (tarja.idTiporendimiento == '3') {
          tipoRendimiento = 'Múltiple';
        } else {
          tipoRendimiento = 'Individual'; // Por defecto
        }
        
        if (tipoRendimiento != _filtroTipoRendimiento) {
          return false;
        }
      }

      // Filtro por usuario
      if (_filtroUsuario.isNotEmpty) {
        final nombreCompletoUsuario = _getNombreCompletoUsuario(tarja.nombreUsuario);
        if (nombreCompletoUsuario != _filtroUsuario) {
          return false;
        }
      }

      // Filtro por tipo de CECO
      if (_filtroTipoCeco.isNotEmpty) {
        if (tarja.nombreTipoceco != _filtroTipoCeco) {
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
      await handleApiError(
        () async {
          await ApiService().actualizarTarja(id, datos);
          return true; // Retornar un valor para indicar éxito
        },
        _authProvider!,
        _notificationProvider,
      );
      
      // Si llegamos aquí, la operación fue exitosa
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

  // Limpiar cache de rendimientos (para uso desde MasterLayout)
  void limpiarCacheRendimientos() {
    // Este método será llamado desde las pantallas para limpiar su cache local
    // Las pantallas escucharán este cambio y limpiarán su cache
    notifyListeners();
  }

  @override
  void dispose() {
    _authProvider?.removeListener(_onAuthChanged);
    super.dispose();
  }
} 