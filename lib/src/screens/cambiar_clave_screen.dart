import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class CambiarClaveScreen extends StatefulWidget {
  const CambiarClaveScreen({super.key});

  @override
  State<CambiarClaveScreen> createState() => _CambiarClaveScreenState();
}

class _CambiarClaveScreenState extends State<CambiarClaveScreen> {
  final TextEditingController _claveActualController = TextEditingController();
  final TextEditingController _nuevaClaveController = TextEditingController();
  final TextEditingController _confirmarClaveController = TextEditingController();
  bool _cargando = false;
  String? _errorMensaje;
  bool _mostrarClaveActual = false;
  bool _mostrarNuevaClave = false;
  bool _mostrarConfirmarClave = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _claveActualController.dispose();
    _nuevaClaveController.dispose();
    _confirmarClaveController.dispose();
    super.dispose();
  }

  String? _validarClave(String? value) {
    if (value == null || value.isEmpty) {
      return 'Este campo es requerido';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  void _cambiarClave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _errorMensaje = null;
      _cargando = true;
    });

    try {
      String claveActual = _claveActualController.text;
      String nuevaClave = _nuevaClaveController.text;
      String confirmarClave = _confirmarClaveController.text;

      if (nuevaClave != confirmarClave) {
        setState(() {
          _errorMensaje = "Las nuevas contraseñas no coinciden";
          _cargando = false;
        });
        return;
      }

      await AuthService().cambiarClave(claveActual, nuevaClave);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text("Contraseña cambiada con éxito"),
            ],
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMensaje = "Error al cambiar la contraseña: ${e.toString()}";
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Cambiar Contraseña',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Campo de contraseña actual
              TextFormField(
                controller: _claveActualController,
                obscureText: !_mostrarClaveActual,
                decoration: InputDecoration(
                  labelText: 'Contraseña Actual',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _mostrarClaveActual ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _mostrarClaveActual = !_mostrarClaveActual;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: _validarClave,
              ),
              const SizedBox(height: 16),
              
              // Campo de nueva contraseña
              TextFormField(
                controller: _nuevaClaveController,
                obscureText: !_mostrarNuevaClave,
                decoration: InputDecoration(
                  labelText: 'Nueva Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _mostrarNuevaClave ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _mostrarNuevaClave = !_mostrarNuevaClave;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: _validarClave,
              ),
              const SizedBox(height: 16),
              
              // Campo de confirmar contraseña
              TextFormField(
                controller: _confirmarClaveController,
                obscureText: !_mostrarConfirmarClave,
                decoration: InputDecoration(
                  labelText: 'Confirmar Nueva Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _mostrarConfirmarClave ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _mostrarConfirmarClave = !_mostrarConfirmarClave;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: _validarClave,
              ),
              const SizedBox(height: 24),
              
              // Mensaje de error
              if (_errorMensaje != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMensaje!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              
              // Botón de cambiar contraseña
              ElevatedButton(
                onPressed: _cargando ? null : _cambiarClave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _cargando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Cambiar Contraseña',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 