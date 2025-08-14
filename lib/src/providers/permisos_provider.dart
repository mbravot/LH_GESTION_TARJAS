import 'package:flutter/foundation.dart';
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _permisos = await ApiService.obtenerPermisosUsuario();
      print('🔍 Permisos cargados: ${_permisos.length}');
      for (var permiso in _permisos) {
        print('   - ID: ${permiso['id']}, Nombre: ${permiso['nombre']}');
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('❌ Error al cargar permisos: $e');
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
      print('🔍 No hay permisos cargados, cargando automáticamente...');
      cargarPermisos();
      return false; // Retornar false temporalmente mientras se cargan
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
    print('🔍 Verificando permiso ID $idPermiso: $tiene');
    print('   - Permisos disponibles: ${_permisos.map((p) => '${p['id']} (${p['id'].runtimeType})').toList()}');
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
    print('🔍 Recargando permisos...');
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