import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/usuario.dart';
import '../providers/usuario_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/main_scaffold.dart';

class UsuarioEditarScreen extends StatefulWidget {
  final Usuario usuario;

  const UsuarioEditarScreen({
    super.key,
    required this.usuario,
  });

  @override
  State<UsuarioEditarScreen> createState() => _UsuarioEditarScreenState();
}

class _UsuarioEditarScreenState extends State<UsuarioEditarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioController = TextEditingController();
  final _correoController = TextEditingController();
  final _nombreController = TextEditingController();
  final _apellidoPaternoController = TextEditingController();
  final _apellidoMaternoController = TextEditingController();

  int? _idSucursalActiva;
  List<String> _permisosSeleccionados = [];
  List<int> _sucursalesAdicionalesSeleccionadas = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _inicializarDatos();
    _cargarSucursales();
    _cargarSucursalesUsuario();
    _cargarPermisosUsuario();
  }

  @override
  void dispose() {
    _usuarioController.dispose();
    _correoController.dispose();
    _nombreController.dispose();
    _apellidoPaternoController.dispose();
    _apellidoMaternoController.dispose();
    super.dispose();
  }

  void _inicializarDatos() {
    _usuarioController.text = widget.usuario.usuario;
    _correoController.text = widget.usuario.correo;
    _nombreController.text = widget.usuario.nombre;
    _apellidoPaternoController.text = widget.usuario.apellidoPaterno;
    _apellidoMaternoController.text = widget.usuario.apellidoMaterno;
    _idSucursalActiva = widget.usuario.idSucursalActiva;
    _permisosSeleccionados = List<String>.from(widget.usuario.permisos ?? []);
    _sucursalesAdicionalesSeleccionadas = List<int>.from(widget.usuario.sucursalesAdicionales ?? []);
  }

  Future<void> _cargarSucursales() async {
    final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);
    await usuarioProvider.cargarSucursales();
  }

  Future<void> _cargarSucursalesUsuario() async {
    final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);
    try {
      final sucursalesUsuario = await usuarioProvider.cargarSucursalesUsuario(widget.usuario.id);
      if (mounted) {
        setState(() {
          _sucursalesAdicionalesSeleccionadas = sucursalesUsuario.map((s) => s['id_sucursal'] as int).toList();
        });
      }
    } catch (e) {
      print('Error al cargar sucursales del usuario: $e');
    }
  }

  Future<void> _cargarPermisosUsuario() async {
    final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);
    try {
      // Primero cargar los permisos disponibles
      await usuarioProvider.cargarPermisosDisponibles();
      
      // Luego cargar los permisos del usuario específico
      final usuarioPermisos = await usuarioProvider.obtenerPermisosUsuario(widget.usuario.id);
      if (mounted && usuarioPermisos != null) {
        setState(() {
          _permisosSeleccionados = usuarioPermisos.permisos.map((p) => p.id).toList();
        });
      }
    } catch (e) {
      print('Error al cargar permisos del usuario: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Editar Usuario',
      showAppBarElements: true,
      actions: [
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Formulario
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Información del Usuario',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _usuarioController,
                        label: 'Usuario',
                        hint: 'Ingrese el nombre de usuario',
                        icon: Icons.person,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El usuario es obligatorio';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _correoController,
                        label: 'Correo',
                        hint: 'Ingrese el correo electrónico',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El correo es obligatorio';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Ingrese un correo válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _nombreController,
                        label: 'Nombre',
                        hint: 'Ingrese el nombre',
                        icon: Icons.badge,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El nombre es obligatorio';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _apellidoPaternoController,
                        label: 'Apellido Paterno',
                        hint: 'Ingrese el apellido paterno',
                        icon: Icons.badge,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El apellido paterno es obligatorio';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _apellidoMaternoController,
                        label: 'Apellido Materno',
                        hint: 'Ingrese el apellido materno (opcional)',
                        icon: Icons.badge,
                      ),
                      const SizedBox(height: 16),
                      Consumer<UsuarioProvider>(
                        builder: (context, usuarioProvider, child) {
                          return DropdownButtonFormField<int>(
                            value: _idSucursalActiva,
                            decoration: InputDecoration(
                              labelText: 'Sucursal Activa',
                              prefixIcon: Icon(Icons.business, color: AppTheme.primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: usuarioProvider.sucursales.map((sucursal) {
                              return DropdownMenuItem(
                                value: sucursal['id'] as int,
                                child: Text(sucursal['nombre'] as String),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _idSucursalActiva = value!;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Seleccione una sucursal activa';
                              }
                              return null;
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Permisos
              Text(
                'Permisos del Usuario',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              _buildPermisosSelector(),
              const SizedBox(height: 24),

              // Sucursales Adicionales
              Text(
                'Sucursales Adicionales',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              _buildSucursalesSelector(),
              const SizedBox(height: 24),

              // Botones
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _actualizarUsuario,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isLoading ? 'Actualizando...' : 'Actualizar Usuario'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildPermisosSelector() {
    return Consumer<UsuarioProvider>(
      builder: (context, usuarioProvider, child) {
        if (usuarioProvider.permisosDisponibles.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Cargando permisos...'),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seleccione los permisos para el usuario:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                ...usuarioProvider.permisosDisponibles.map((permiso) {
                  return CheckboxListTile(
                    title: Text(permiso.nombre),
                    value: _permisosSeleccionados.contains(permiso.id),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _permisosSeleccionados.add(permiso.id);
                        } else {
                          _permisosSeleccionados.remove(permiso.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSucursalesSelector() {
    return Consumer<UsuarioProvider>(
      builder: (context, usuarioProvider, child) {
        if (usuarioProvider.sucursales.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Cargando sucursales...'),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seleccione sucursales adicionales (opcional):',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: usuarioProvider.sucursales.map((sucursal) {
                    print('Sucursal disponible: $sucursal');
                    final sucursalId = sucursal['id'] ?? sucursal['id_sucursal'];
                    final isSelected = _sucursalesAdicionalesSeleccionadas.contains(sucursalId);
                    return FilterChip(
                      label: Text(sucursal['nombre'] as String),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _sucursalesAdicionalesSeleccionadas.add(sucursalId as int);
                          } else {
                            _sucursalesAdicionalesSeleccionadas.remove(sucursalId);
                          }
                        });
                      },
                      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                      checkmarkColor: AppTheme.primaryColor,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _actualizarUsuario() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_idSucursalActiva == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione una sucursal activa'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final usuarioActualizado = Usuario(
        id: widget.usuario.id,
        usuario: _usuarioController.text.trim(),
        correo: _correoController.text.trim(),
        idSucursalActiva: _idSucursalActiva!,
        nombre: _nombreController.text.trim(),
        apellidoPaterno: _apellidoPaternoController.text.trim(),
        apellidoMaterno: _apellidoMaternoController.text.trim(),
        idEstado: widget.usuario.idEstado,
        idRol: widget.usuario.idRol,
        idPerfil: widget.usuario.idPerfil,
        fechaCreacion: widget.usuario.fechaCreacion,
        nombreSucursal: widget.usuario.nombreSucursal,
        nombreCompleto: widget.usuario.nombreCompleto,
        permisos: _permisosSeleccionados,
        sucursalesAdicionales: _sucursalesAdicionalesSeleccionadas,
      );

      final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);
      final success = await usuarioProvider.actualizarUsuario(usuarioActualizado);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario actualizado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(usuarioProvider.error ?? 'Error al actualizar usuario'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}