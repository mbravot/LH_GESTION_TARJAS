import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';

class SessionHandlerWrapper extends StatefulWidget {
  final Widget child;

  const SessionHandlerWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<SessionHandlerWrapper> createState() => _SessionHandlerWrapperState();
}

class _SessionHandlerWrapperState extends State<SessionHandlerWrapper> {
  @override
  void initState() {
    super.initState();
    // Escuchar cambios en el AuthProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      authProvider.addListener(_onAuthChanged);
    });
  }

  void _onAuthChanged() {
    final authProvider = context.read<AuthProvider>();
    
    // Solo redirigir si no está autenticado y no estamos ya en el login
    if (!authProvider.isAuthenticated) {
      // Verificar si estamos en una pantalla que requiere autenticación
      final currentRoute = ModalRoute.of(context);
      final routeName = currentRoute?.settings.name ?? '';
      if (currentRoute != null && 
          !routeName.contains('login') &&
          !routeName.contains('splash')) {
        _redirectToLogin();
      }
    }
  }

  void _redirectToLogin() {
    // Navegar al login y limpiar el stack de navegación
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
      (route) => false, // Remover todas las rutas del stack
    );
  }

  @override
  void dispose() {
    final authProvider = context.read<AuthProvider>();
    authProvider.removeListener(_onAuthChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
