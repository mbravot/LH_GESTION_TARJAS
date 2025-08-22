import 'package:flutter/material.dart';
import 'dart:developer' as developer;

class NotificationProvider extends ChangeNotifier {
  String? _message;
  String? _type; // 'success', 'error', 'warning', 'info'
  bool _show = false;

  String? get message => _message;
  String? get type => _type;
  bool get show => _show;

  void showNotification(String message, {String type = 'info'}) {
    _message = message;
    _type = type;
    _show = true;
    notifyListeners();
    
    developer.log('📢 Notificación mostrada: $message (tipo: $type)');
  }

  void hideNotification() {
    _show = false;
    _message = null;
    _type = null;
    notifyListeners();
  }

  void showSessionExpiredMessage() {
    showNotification(
      'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.',
      type: 'warning',
    );
  }

  void showSuccessMessage(String message) {
    showNotification(message, type: 'success');
  }

  void showErrorMessage(String message) {
    showNotification(message, type: 'error');
  }

  void showInfoMessage(String message) {
    showNotification(message, type: 'info');
  }
}
