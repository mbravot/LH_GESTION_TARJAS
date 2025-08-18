import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/permiso_provider.dart';
import '../providers/colaborador_provider.dart';
import '../models/colaborador.dart';
import '../widgets/main_scaffold.dart';
import '../theme/app_theme.dart';

class PermisoCrearScreen extends StatefulWidget {
  const PermisoCrearScreen({Key? key}) : super(key: key);

  @override
  State<PermisoCrearScreen> createState() => _PermisoCrearScreenState();
}

class _PermisoCrearScreenState extends State<PermisoCrearScreen> {
  final _formKey = GlobalKey<FormState>();
  final _horasController = TextEditingController();
  
  String? _colaboradorSeleccionado;
  String? _tipoPermisoSeleccionado;
  String? _estadoPermisoSeleccionado;
  DateTime? _fechaSeleccionada;
  
  List<Map<String, dynamic>> _tiposPermiso = [];
  List<Map<String, dynamic>> _estadosPermiso = [];
  List<Colaborador> _colaboradores = [];
  
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isLoadingData = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  @override
  void dispose() {
    _horasController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosIniciales() async {
    setState(() {
      _isLoadingData = true;
      _error = null;
    });

    try {
      final permisoProvider = Provider.of<PermisoProvider>(context, listen: false);
      final colaboradorProvider = Provider.of<ColaboradorProvider>(context, listen: false);

      await Future.wait([
        permisoProvider.cargarTiposPermiso(),
        permisoProvider.cargarEstadosPermiso(),
        colaboradorProvider.cargarColaboradores(),
      ]);

      setState(() {
        _tiposPermiso = permisoProvider.tiposPermiso;
        _estadosPermiso = permisoProvider.estadosPermiso;
        _colaboradores = colaboradorProvider.colaboradores.where((c) => c.estadoText == 'Activo').toList();
      });
      
      // Establecer valores por defecto
      if (_tiposPermiso.isNotEmpty) {
        _tipoPermisoSeleccionado = _tiposPermiso.first['id'].toString();
      }
      if (_colaboradores.isNotEmpty) {
        _colaboradorSeleccionado = _colaboradores.first.id;
      }
      if (_estadosPermiso.isNotEmpty) {
        _estadoPermisoSeleccionado = _estadosPermiso.first['id'].toString();
      }
      _fechaSeleccionada = DateTime.now();
      
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)), // Permitir fechas pasadas
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
    );

    if (fechaSeleccionada != null) {
      setState(() {
        _fechaSeleccionada = fechaSeleccionada;
      });
    }
  }

  Future<void> _guardarPermiso() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_colaboradorSeleccionado == null ||
        _tipoPermisoSeleccionado == null ||
        _estadoPermisoSeleccionado == null ||
        _fechaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final datos = {
        'fecha': _fechaSeleccionada!.toIso8601String().split('T')[0], // Formato YYYY-MM-DD
        'id_tipopermiso': _tipoPermisoSeleccionado,
        'id_colaborador': _colaboradorSeleccionado,
        'horas': _horasController.text,
        'id_estadopermiso': _estadoPermisoSeleccionado,
      };

      final permisoProvider = Provider.of<PermisoProvider>(context, listen: false);
      final success = await permisoProvider.crearPermiso(datos);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permiso creado correctamente'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.of(context).pop(true); // Retornar true para indicar éxito
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear permiso: ${permisoProvider.error}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _limpiarFormulario() {
    _formKey.currentState?.reset();
    _horasController.clear();
    setState(() {
      _colaboradorSeleccionado = _colaboradores.isNotEmpty ? _colaboradores.first.id : null;
      _tipoPermisoSeleccionado = _tiposPermiso.isNotEmpty ? _tiposPermiso.first['id'].toString() : null;
      _estadoPermisoSeleccionado = _estadosPermiso.isNotEmpty ? _estadosPermiso.first['id'].toString() : null;
      _fechaSeleccionada = DateTime.now();
    });
  }

  Widget _buildCampoTexto({
    required String label,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    int? maxLines = 1,
    String? hintText,
    int? maxLength,
    bool readOnly = false,
    VoidCallback? onTap,
    TextEditingController? controller,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        maxLength: maxLength,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          counterText: '',
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<Map<String, dynamic>> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
        ),
        items: [
          DropdownMenuItem<String>(
            value: null,
            child: Text('Seleccionar $label'),
          ),
          ...items.map((item) {
            return DropdownMenuItem<String>(
              value: item['id'].toString(),
              child: Text(item['nombre'] ?? 'Sin nombre'),
            );
          }),
        ],
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  Widget _buildDropdownColaborador({
    required String label,
    required String? value,
    required List<Colaborador> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
        ),
        items: [
          DropdownMenuItem<String>(
            value: null,
            child: Text('Seleccionar $label'),
          ),
          ...items.map((colaborador) {
            return DropdownMenuItem<String>(
              value: colaborador.id,
              child: Text(colaborador.nombreCompleto),
            );
          }),
        ],
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  Widget _buildSelectorFecha({
    required String label,
    required DateTime? fecha,
    required VoidCallback onTap,
    required String hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            suffixIcon: const Icon(Icons.calendar_today),
          ),
          child: Text(
            fecha != null
                ? '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}'
                : '',
            style: TextStyle(
              color: fecha != null
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Crear Permiso',
      actions: [
        if (_isSaving)
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
      body: _isLoadingData
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar datos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red[600]),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _cargarDatosIniciales,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Información del Permiso',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildDropdownColaborador(
                                  label: 'Colaborador',
                                  value: _colaboradorSeleccionado,
                                  items: _colaboradores,
                                  onChanged: (value) {
                                    setState(() {
                                      _colaboradorSeleccionado = value;
                                    });
                                  },
                                  isRequired: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Debes seleccionar un colaborador';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildDropdown(
                                  label: 'Tipo de Permiso',
                                  value: _tipoPermisoSeleccionado,
                                  items: _tiposPermiso,
                                  onChanged: (value) {
                                    setState(() {
                                      _tipoPermisoSeleccionado = value;
                                    });
                                  },
                                  isRequired: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Debes seleccionar un tipo de permiso';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildSelectorFecha(
                                  label: 'Fecha *',
                                  fecha: _fechaSeleccionada,
                                  onTap: _seleccionarFecha,
                                  hintText: 'Seleccionar fecha',
                                ),
                                const SizedBox(height: 16),
                                _buildCampoTexto(
                                  label: 'Horas *',
                                  hintText: 'Ej: 4',
                                  keyboardType: TextInputType.number,
                                  controller: _horasController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor ingresa las horas';
                                    }
                                    final horas = double.tryParse(value);
                                    if (horas == null || horas <= 0) {
                                      return 'Por favor ingresa un número válido de horas';
                                    }
                                    if (horas > 24) {
                                      return 'Las horas no pueden ser mayores a 24';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildDropdown(
                                  label: 'Estado',
                                  value: _estadoPermisoSeleccionado,
                                  items: _estadosPermiso,
                                  onChanged: (value) {
                                    setState(() {
                                      _estadoPermisoSeleccionado = value;
                                    });
                                  },
                                  isRequired: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Debes seleccionar un estado';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isSaving ? null : _limpiarFormulario,
                                icon: const Icon(Icons.clear),
                                label: const Text('Limpiar'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isSaving ? null : _guardarPermiso,
                                icon: _isSaving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.save),
                                label: Text(_isSaving ? 'Guardando...' : 'Guardar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
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
    );
  }
}
