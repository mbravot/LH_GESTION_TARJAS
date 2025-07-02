import 'package:flutter/foundation.dart';
import '../models/tarja.dart';
import '../services/tarja_service.dart';

class TarjaProvider extends ChangeNotifier {
  final TarjaService _tarjaService = TarjaService();
  List<Tarja> _tarjas = [];
  bool _isLoading = false;
  String? _error;
  String? _idSucursal;

  // Getters
  List<Tarja> get tarjas => _tarjas;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Setter para la sucursal
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
      _tarjas = await _tarjaService.getTarjasByDate(DateTime.now(), _idSucursal!);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _tarjas = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Actualizar tarja
  Future<void> actualizarTarja(String id, Map<String, dynamic> datos) async {
    try {
      await _tarjaService.actualizarTarja(id, datos);
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
} 