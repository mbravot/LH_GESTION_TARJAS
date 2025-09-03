import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import 'dart:async';

class SessionHandlerWrapper extends StatefulWidget {
  final Widget child;

  const SessionHandlerWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<SessionHandlerWrapper> createState() => _SessionHandlerWrapperState();
}

class _SessionHandlerWrapperState extends State<SessionHandlerWrapper> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    // Verificar el estado de autenticación al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialAuthStatus();
    });
    
    // Registrar el observer del ciclo de vida
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _checkInitialAuthStatus() async {
    final authProvider = context.read<AuthProvider>();
    
    // Verificar si hay un token almacenado y si es válido
    final token = await authProvider.getToken();
    
    if (token != null) {
      // Si hay token, verificar si es válido
      final isValid = await authProvider.isTokenValid();
      if (!isValid) {
        // Si el token no es válido, limpiar la sesión
        await authProvider.handleSessionExpired();
      }
    } else {
      // Si no hay token, asegurar que el estado sea no autenticado
      if (authProvider.isAuthenticated) {
        await authProvider.handleSessionExpired();
      }
    }
    
    // Agregar el listener después de la verificación inicial
    authProvider.addListener(_onAuthChanged);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      // Cuando la aplicación vuelve a estar activa, verificar el estado de autenticación
      _checkAuthStatusOnResume();
    }
  }

  Future<void> _checkAuthStatusOnResume() async {
    final authProvider = context.read<AuthProvider>();
    
    // Solo verificar si ya está autenticado
    if (authProvider.isAuthenticated) {
      final isValid = await authProvider.isTokenValid();
      if (!isValid) {
        // Si el token ya no es válido, limpiar la sesión
        await authProvider.handleSessionExpired();
      }
    }
  }

  void _onAuthChanged() {
    final authProvider = context.read<AuthProvider>();
    
    // Solo redirigir si no está autenticado y no estamos ya en el login
    if (!authProvider.isAuthenticated) {
      // Verificar si estamos en una pantalla que requiere autenticación
      final currentRoute = ModalRoute.of(context);
      final routeName = currentRoute?.settings.name ?? '';
      
      // Redirigir si no estamos en login o splash
      if (currentRoute != null && 
          !routeName.contains('login') &&
          !routeName.contains('splash')) {
        _redirectToLogin();
      } else if (currentRoute == null) {
        // Si no hay ruta actual (aplicación recién iniciada), redirigir al login
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
    // Solo remover el listener si el widget aún está montado
    if (mounted) {
      try {
        final authProvider = context.read<AuthProvider>();
        authProvider.removeListener(_onAuthChanged);
      } catch (e) {
        // Ignorar errores si el context ya no es válido
      }
    }
    
    // Remover el observer del ciclo de vida
    WidgetsBinding.instance.removeObserver(this);
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
