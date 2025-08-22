import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'auth_provider.dart';
import 'notification_provider.dart';

mixin SessionHandlerMixin {
  // Método para manejar errores y detectar sesión expirada
  Future<T?> handleApiError<T>(Future<T> Function() apiCall, AuthProvider authProvider, NotificationProvider? notificationProvider) async {
    try {
      return await apiCall();
    } catch (e) {
      developer.log('🔍 Error capturado: $e');
      
      // Verificar si es una excepción de sesión expirada
      if (e.toString().contains('SESION_EXPIRADA')) {
        developer.log('🔐 Sesión expirada detectada, manejando automáticamente...');
        
        // Manejar la sesión expirada
        await authProvider.handleSessionExpired();
        
        // Mostrar mensaje al usuario
        _showSessionExpiredMessage(notificationProvider);
        
        // Retornar null para indicar que la operación falló por sesión expirada
        return null;
      }
      
      // Re-lanzar otros errores
      rethrow;
    }
  }

  // Método para mostrar mensaje de sesión expirada
  void _showSessionExpiredMessage(NotificationProvider? notificationProvider) {
    developer.log('📱 Mostrando mensaje de sesión expirada al usuario');
    
    // Mostrar notificación si el provider está disponible
    notificationProvider?.showSessionExpiredMessage();
  }
}
