import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import 'loading_screen.dart';
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
  AuthProvider? _authProvider;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    
    // Agregar el listener inmediatamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authProvider = context.read<AuthProvider>();
      _authProvider!.addListener(_onAuthChanged);
      _checkInitialAuthStatus();
    });
    
    // Registrar el observer del ciclo de vida
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _checkInitialAuthStatus() async {
    final authProvider = context.read<AuthProvider>();
    
          try {
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
          } catch (e) {
            // Error en verificación de autenticación
          } finally {
      // Marcar como inicializado
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
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

  @override
  void dispose() {
    // Remover el listener y el observer usando la referencia guardada
    if (_authProvider != null) {
      _authProvider!.removeListener(_onAuthChanged);
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onAuthChanged() {
    // Verificar si el widget sigue montado antes de usar context
    if (!mounted || _authProvider == null) return;
    
    
    // Solo redirigir si no está autenticado y no estamos ya en el login
    if (!_authProvider!.isAuthenticated) {
      
      // Verificar si estamos en una pantalla que requiere autenticación
      final currentRoute = ModalRoute.of(context);
      final routeName = currentRoute?.settings.name ?? '';
      
      
      // Solo redirigir si estamos en una pantalla protegida (no login/splash)
      if (!routeName.contains('login') && !routeName.contains('splash') && routeName.isNotEmpty) {
        // Usar un delay para evitar conflictos con navegación manual
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _redirectToLogin();
        });
      } else {
      }
    } else {
    }
  }

  void _redirectToLogin() {
    // Verificar si el widget sigue montado antes de navegar
    if (!mounted) return;
    
    // Navegar al login y limpiar el stack de navegación
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
      (route) => false, // Remover todas las rutas del stack
    );
  }


  @override
  Widget build(BuildContext context) {
    // Mostrar pantalla de carga mientras se inicializa
    if (_isInitializing) {
      return const LoadingScreen(
        message: 'Inicializando aplicación...',
      );
    }
    
    return widget.child;
  }
}
