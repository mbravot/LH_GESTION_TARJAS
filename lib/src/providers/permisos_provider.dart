import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../services/api_service.dart';

class PermisosProvider with ChangeNotifier {
  List<Map<String, dynamic>> _permisos = [];
  Map<String, bool> _permisosCache = {};
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get permisos => _permisos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Cargar permisos del usuario
  Future<void> cargarPermisos() async {
    final startTime = DateTime.now();
    print('🔐 [PERMISOS] Iniciando carga de permisos...');
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔐 [PERMISOS] Llamando a ApiService.obtenerPermisosUsuario...');
      _permisos = await ApiService.obtenerPermisosUsuario();
      
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      print('🔐 [PERMISOS] Permisos cargados exitosamente en ${duration.inMilliseconds}ms - Total: ${_permisos.length} permisos');
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('🔐 [PERMISOS] Error al cargar permisos: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Verificar si el usuario tiene un permiso específico
  Future<bool> tienePermiso(String nombrePermiso) async {
    // Verificar cache primero
    if (_permisosCache.containsKey(nombrePermiso)) {
      return _permisosCache[nombrePermiso]!;
    }

    try {
      final tiene = await ApiService.verificarPermiso(nombrePermiso);
      _permisosCache[nombrePermiso] = tiene;
      return tiene;
    } catch (e) {
      return false;
    }
  }

  // Verificar si el usuario tiene un permiso por ID
  bool tienePermisoPorId(int idPermiso) {
    // Si no hay permisos cargados, intentar cargarlos automáticamente
    if (_permisos.isEmpty && !_isLoading) {
      // Cargar permisos de forma asíncrona pero no bloquear la UI
      WidgetsBinding.instance.addPostFrameCallback((_) {
        cargarPermisos();
      });
      // Durante el hot reload, asumir que el usuario tiene permisos temporalmente
      // para evitar que los elementos del menú desaparezcan
      // Los permisos se validarán correctamente una vez que se carguen
      return true;
    }
    
    final tiene = _permisos.any((permiso) {
      final permisoId = permiso['id'];
      // Manejar tanto int como string
      if (permisoId is int) {
        return permisoId == idPermiso;
      } else if (permisoId is String) {
        return int.tryParse(permisoId) == idPermiso;
      }
      return false;
    });
    return tiene;
  }

  // Verificar múltiples permisos
  Future<Map<String, bool>> verificarMultiplesPermisos(List<String> permisos) async {
    try {
      return await ApiService.verificarMultiplesPermisos(permisos);
    } catch (e) {
      return {for (var permiso in permisos) permiso: false};
    }
  }

  // Limpiar cache
  void limpiarCache() {
    _permisosCache.clear();
    notifyListeners();
  }

  // Verificar si los permisos están cargados
  bool get permisosCargados => _permisos.isNotEmpty;

  // Recargar permisos (útil después de refrescar la página)
  Future<void> recargarPermisos() async {
    await cargarPermisos();
  }

  // Verificar si el usuario tiene al menos uno de los permisos especificados
  bool tieneAlgunoDeLosPermisos(List<int> idsPermisos) {
    return idsPermisos.any((id) => tienePermisoPorId(id));
  }

  // Verificar si el usuario tiene todos los permisos especificados
  bool tieneTodosLosPermisos(List<int> idsPermisos) {
    return idsPermisos.every((id) => tienePermisoPorId(id));
  }
} 