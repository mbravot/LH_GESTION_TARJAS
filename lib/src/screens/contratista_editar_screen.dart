import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/contratista_provider.dart';
import '../models/contratista.dart';
import '../widgets/main_scaffold.dart';
import '../theme/app_theme.dart';

class ContratistaEditarScreen extends StatefulWidget {
  final Contratista contratista;

  const ContratistaEditarScreen({
    Key? key,
    required this.contratista,
  }) : super(key: key);

  @override
  State<ContratistaEditarScreen> createState() => _ContratistaEditarScreenState();
}

class _ContratistaEditarScreenState extends State<ContratistaEditarScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _rutController;
  late final TextEditingController _nombreController;
  late final TextEditingController _apellidoPaternoController;
  late final TextEditingController _apellidoMaternoController;
  late final TextEditingController _emailController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _direccionController;
  late final TextEditingController _observacionesController;

  late String _estadoSeleccionado;
  DateTime? _fechaNacimiento;
  DateTime? _fechaIncorporacion;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _inicializarControladores();
    _cargarOpciones();
  }

  void _inicializarControladores() {
    _rutController = TextEditingController(text: widget.contratista.rut);
    _nombreController = TextEditingController(text: widget.contratista.nombre);
    _apellidoPaternoController = TextEditingController(text: widget.contratista.apellidoPaterno);
    _apellidoMaternoController = TextEditingController(text: widget.contratista.apellidoMaterno);
    _emailController = TextEditingController(text: widget.contratista.email ?? '');
    _telefonoController = TextEditingController(text: widget.contratista.telefono ?? '');
    _direccionController = TextEditingController(text: widget.contratista.direccion ?? '');
    _observacionesController = TextEditingController(text: widget.contratista.observaciones ?? '');
    
    _estadoSeleccionado = widget.contratista.estado;
    _fechaNacimiento = widget.contratista.fechaNacimiento;
    _fechaIncorporacion = widget.contratista.fechaIncorporacion;
  }

  @override
  void dispose() {
    _rutController.dispose();
    _nombreController.dispose();
    _apellidoPaternoController.dispose();
    _apellidoMaternoController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _cargarOpciones() async {
    final provider = Provider.of<ContratistaProvider>(context, listen: false);
    await provider.cargarOpciones();
  }

  Future<void> _actualizarContratista() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<ContratistaProvider>(context, listen: false);
      
      final datos = {
        'rut': _rutController.text.trim(),
        'nombre': _nombreController.text.trim(),
        'apellido_paterno': _apellidoPaternoController.text.trim(),
        'apellido_materno': _apellidoMaternoController.text.trim(),
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'telefono': _telefonoController.text.trim().isEmpty ? null : _telefonoController.text.trim(),
        'direccion': _direccionController.text.trim().isEmpty ? null : _direccionController.text.trim(),
        'fecha_nacimiento': _fechaNacimiento?.toIso8601String().split('T')[0],
        'fecha_incorporacion': _fechaIncorporacion?.toIso8601String().split('T')[0],
        'estado': _estadoSeleccionado,
        'observaciones': _observacionesController.text.trim().isEmpty ? null : _observacionesController.text.trim(),
      };

      final success = await provider.editarContratista(widget.contratista.id, datos);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Contratista actualizado exitosamente'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar contratista: $e'),
            backgroundColor: AppTheme.errorColor,
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

  Future<void> _seleccionarFecha(BuildContext context, bool esFechaNacimiento) async {
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: esFechaNacimiento 
          ? (_fechaNacimiento ?? DateTime.now().subtract(const Duration(days: 6570)))
          : (_fechaIncorporacion ?? DateTime.now()),
      firstDate: esFechaNacimiento ? DateTime.now().subtract(const Duration(days: 36500)) : DateTime.now().subtract(const Duration(days: 365)),
      lastDate: esFechaNacimiento ? DateTime.now().subtract(const Duration(days: 6570)) : DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
    );

    if (fechaSeleccionada != null) {
      setState(() {
        if (esFechaNacimiento) {
          _fechaNacimiento = fechaSeleccionada;
        } else {
          _fechaIncorporacion = fechaSeleccionada;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Editar Contratista',
      body: Consumer<ContratistaProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Información Personal',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _rutController,
                                  decoration: const InputDecoration(
                                    labelText: 'RUT *',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.badge),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'El RUT es obligatorio';
                                    }
                                    if (value.trim().length < 8) {
                                      return 'El RUT debe tener al menos 8 caracteres';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _nombreController,
                                  decoration: const InputDecoration(
                                    labelText: 'Nombre *',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.person),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'El nombre es obligatorio';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _apellidoPaternoController,
                                  decoration: const InputDecoration(
                                    labelText: 'Apellido Paterno *',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.person_outline),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'El apellido paterno es obligatorio';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _apellidoMaternoController,
                                  decoration: const InputDecoration(
                                    labelText: 'Apellido Materno *',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.person_outline),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'El apellido materno es obligatorio';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _estadoSeleccionado,
                                  decoration: const InputDecoration(
                                    labelText: 'Estado *',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.info_outline),
                                  ),
                                  items: provider.estadosDisponibles.map((estado) {
                                    return DropdownMenuItem<String>(
                                      value: estado,
                                      child: Text(estado),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _estadoSeleccionado = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Información de Contacto',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _emailController,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.email),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value != null && value.trim().isNotEmpty) {
                                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                                      if (!emailRegex.hasMatch(value.trim())) {
                                        return 'Ingrese un email válido';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _telefonoController,
                                  decoration: const InputDecoration(
                                    labelText: 'Teléfono',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.phone),
                                  ),
                                  keyboardType: TextInputType.phone,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _direccionController,
                            decoration: const InputDecoration(
                              labelText: 'Dirección',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_on),
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fechas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => _seleccionarFecha(context, true),
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Fecha de Nacimiento',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.cake),
                                    ),
                                    child: Text(
                                      _fechaNacimiento != null
                                          ? '${_fechaNacimiento!.day.toString().padLeft(2, '0')}/${_fechaNacimiento!.month.toString().padLeft(2, '0')}/${_fechaNacimiento!.year}'
                                          : 'Seleccionar fecha',
                                      style: TextStyle(
                                        color: _fechaNacimiento != null ? Colors.black : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _seleccionarFecha(context, false),
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Fecha de Incorporación',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.work),
                                    ),
                                    child: Text(
                                      _fechaIncorporacion != null
                                          ? '${_fechaIncorporacion!.day.toString().padLeft(2, '0')}/${_fechaIncorporacion!.month.toString().padLeft(2, '0')}/${_fechaIncorporacion!.year}'
                                          : 'Seleccionar fecha',
                                      style: TextStyle(
                                        color: _fechaIncorporacion != null ? Colors.black : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Observaciones',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _observacionesController,
                            decoration: const InputDecoration(
                              labelText: 'Observaciones',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.note),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _actualizarContratista,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Actualizar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
