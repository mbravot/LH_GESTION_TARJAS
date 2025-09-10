import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/permisos_provider.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioController = TextEditingController();
  final _claveController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;
  PermisosProvider? _permisosProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _permisosProvider = context.read<PermisosProvider>();
    });
  }

  @override
  void dispose() {
    _usuarioController.dispose();
    _claveController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
          _usuarioController.text,
          _claveController.text,
        );

        if (!mounted) return;

        if (success) {
          // Cargar permisos del usuario
          try {
            if (_permisosProvider != null) {
              await _permisosProvider!.cargarPermisos();
            }
          } catch (e) {
          }

          // Navegar a HomeScreen y reemplazar la página actual
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        } else {
          // Mostrar el mensaje de error del AuthProvider
          final mensaje = authProvider.error ?? 'Usuario o clave incorrectos o sin acceso a la app!';
          final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
          if (scaffoldMessenger != null) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(child: Text(mensaje)),
                  ],
                ),
                backgroundColor: AppTheme.errorColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      } catch (e) {
        if (!mounted) return;
        String mensaje = 'Usuario o clave incorrectos o sin acceso a la app!';
        // Si la excepción contiene el mensaje del backend, úsalo
        if (e is Exception && e.toString().contains('Exception:')) {
          mensaje = e.toString().replaceFirst('Exception:', '').trim();
        }
        final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
        if (scaffoldMessenger != null) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(mensaje)),
                ],
              ),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 📸 Fondo
          Positioned.fill(
            child: Image.asset(
              'assets/images/fondo.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // 🟤 Overlay oscuro
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.4),
                  ],
                ),
              ),
            ),
          ),
          // 🧾 Contenido principal
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Form(
                  key: _formKey,
                  child: Column(
                  children: [
                    // 🟢 Logo con animación de escala
                    TweenAnimationBuilder(
                      duration: const Duration(milliseconds: 600),
                      tween: Tween<double>(begin: 0.5, end: 1.0),
                      curve: Curves.easeOutBack,
                      builder: (context, double value, child) {
                        return Transform.scale(
                          scale: value,
                          child: child,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/lh.jpg',
                          height: 80,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // 🟢 Título con animación de opacidad
                    TweenAnimationBuilder(
                      duration: const Duration(milliseconds: 800),
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      builder: (context, double value, child) {
                        return Opacity(
                          opacity: value,
                          child: child,
                        );
                      },
                      child: Column(
                    children: [
                      const Text(
                            "Bienvenido a LH Gestión Tarjas",
                        style: TextStyle(
                              fontSize: 26,
                          fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 3,
                                  offset: Offset(1, 1),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Inicia sesión para continuar 🌿",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              shadows: [
                                Shadow(
                                  color: Colors.black38,
                                  blurRadius: 2,
                                  offset: Offset(0.5, 0.5),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                      ),
                    const SizedBox(height: 40),
                    // 📨 Campo usuario con animación de slide
                    TweenAnimationBuilder(
                      duration: const Duration(milliseconds: 1000),
                      tween: Tween<Offset>(
                        begin: const Offset(-1, 0),
                        end: Offset.zero,
                      ),
                      builder: (context, Offset offset, child) {
                        return Transform.translate(
                          offset: offset,
                          child: child,
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _usuarioController,
                          style: const TextStyle(color: Colors.black),
                        decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.person, color: AppTheme.primaryColor),
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'Usuario',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                              return 'Por favor ingrese su usuario';
                          }
                          return null;
                        },
                      ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 🔑 Campo clave con animación de slide
                    TweenAnimationBuilder(
                      duration: const Duration(milliseconds: 1200),
                      tween: Tween<Offset>(
                        begin: const Offset(1, 0),
                        end: Offset.zero,
                      ),
                      builder: (context, Offset offset, child) {
                        return Transform.translate(
                          offset: offset,
                          child: child,
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _claveController,
                          obscureText: _obscureText,
                          style: const TextStyle(color: Colors.black),
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _login(),
                        decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock, color: AppTheme.primaryColor),
                          suffixIcon: IconButton(
                            icon: Icon(
                                _obscureText ? Icons.visibility : Icons.visibility_off,
                                color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                  _obscureText = !_obscureText;
                              });
                            },
                          ),
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'Clave',
                            hintStyle: const TextStyle(color: Colors.grey),
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                              return 'Por favor ingrese su clave';
                          }
                          return null;
                        },
                      ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // 🟢 Botón de login con animación de opacidad
                    TweenAnimationBuilder(
                      duration: const Duration(milliseconds: 1400),
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      builder: (context, double value, child) {
                        return Opacity(
                          opacity: value,
                          child: child,
                        );
                      },
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 5,
                        ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Iniciar Sesión',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                      ),
                        ),
                  ),
                    ),
                    const SizedBox(height: 30),
                    // Footer con animación de opacidad
                    TweenAnimationBuilder(
                      duration: const Duration(milliseconds: 1600),
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      builder: (context, double value, child) {
                        return Opacity(
                          opacity: value,
                          child: child,
                        );
                      },
                      child: const Text(
                        "© 2025 La Hornilla - Departamento de TI",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 