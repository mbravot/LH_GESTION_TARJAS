import 'package:flutter/material.dart';
import '../models/sueldo_base.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class SueldoBaseProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  AuthProvider? _authProvider;
  
  List<SueldoBase> _sueldosBase = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<SueldoBase> get sueldosBase => _sueldosBase;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Método para configurar el AuthProvider
  void setAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;
    // Escuchar cambios en la sucursal activa
    _authProvider!.addListener(_onSucursalChanged);
  }

  // Método para manejar cambios de sucursal
  void _onSucursalChanged() {
    if (_authProvider != null) {
      // Recargar sueldos base si es necesario
    }
  }

  @override
  void dispose() {
    if (_authProvider != null) {
      _authProvider!.removeListener(_onSucursalChanged);
    }
    super.dispose();
  }

  // Método para cargar sueldos base de un colaborador
  Future<void> cargarSueldosBase(String colaboradorId) async {
    _setLoading(true);
    _error = null;
    
    try {
      final response = await _apiService.obtenerSueldosBaseColaborador(colaboradorId);
      _sueldosBase = response.map((json) => SueldoBase.fromJson(json)).toList();
      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  // Método para crear un nuevo sueldo base
  Future<bool> crearSueldoBase(String colaboradorId, Map<String, dynamic> datos) async {
    try {
      final response = await _apiService.crearSueldoBase(colaboradorId, datos);
      // Recargar la lista después de crear
      await cargarSueldosBase(colaboradorId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Método para editar un sueldo base
  Future<bool> editarSueldoBase(int sueldoBaseId, Map<String, dynamic> datos) async {
    try {
      final response = await _apiService.editarSueldoBase(sueldoBaseId, datos);
      // Recargar la lista después de editar
      if (_sueldosBase.isNotEmpty) {
        await cargarSueldosBase(_sueldosBase.first.idColaborador);
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Método para eliminar un sueldo base
  Future<bool> eliminarSueldoBase(int sueldoBaseId) async {
    try {
      final response = await _apiService.eliminarSueldoBase(sueldoBaseId);
      // Recargar la lista después de eliminar
      if (_sueldosBase.isNotEmpty) {
        await cargarSueldosBase(_sueldosBase.first.idColaborador);
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Método para limpiar la lista
  void limpiarSueldosBase() {
    _sueldosBase.clear();
    _error = null;
    notifyListeners();
  }

  // Método privado para establecer el estado de carga
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
