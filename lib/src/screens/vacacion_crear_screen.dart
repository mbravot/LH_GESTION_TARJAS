import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/colaborador.dart';
import '../providers/vacacion_provider.dart';
import '../providers/colaborador_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/main_scaffold.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class VacacionCrearScreen extends StatefulWidget {
  const VacacionCrearScreen({super.key});

  @override
  State<VacacionCrearScreen> createState() => _VacacionCrearScreenState();
}

class _VacacionCrearScreenState extends State<VacacionCrearScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String? _colaboradorSeleccionado;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  int _duracionDias = 0;

  List<Colaborador> _colaboradores = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final colaboradorProvider = context.read<ColaboradorProvider>();
      await colaboradorProvider.cargarColaboradores();
      
      setState(() {
        _colaboradores = colaboradorProvider.colaboradoresActivosList;
      });
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
        _isLoading = false;
      });
    }
  }

  Future<void> _seleccionarFechaInicio() async {
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)), // Permitir fechas pasadas
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)), // 2 años
      locale: const Locale('es', 'ES'),
    );

    if (fechaSeleccionada != null) {
      setState(() {
        _fechaInicio = fechaSeleccionada;
        _calcularDuracion();
      });
    }
  }

  Future<void> _seleccionarFechaFin() async {
    if (_fechaInicio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero selecciona la fecha de inicio'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaFin ?? _fechaInicio!,
      firstDate: _fechaInicio!,
      lastDate: _fechaInicio!.add(const Duration(days: 365)), // 1 año máximo
      locale: const Locale('es', 'ES'),
    );

    if (fechaSeleccionada != null) {
      setState(() {
        _fechaFin = fechaSeleccionada;
        _calcularDuracion();
      });
    }
  }

  void _calcularDuracion() {
    if (_fechaInicio != null && _fechaFin != null) {
      setState(() {
        _duracionDias = _fechaFin!.difference(_fechaInicio!).inDays + 1;
      });
    }
  }

  Future<void> _guardarVacacion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_colaboradorSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar un colaborador'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_fechaInicio == null || _fechaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar las fechas de inicio y fin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final vacacionData = {
        'id_colaborador': _colaboradorSeleccionado,
        'fecha_inicio': '${_fechaInicio!.year}-${_fechaInicio!.month.toString().padLeft(2, '0')}-${_fechaInicio!.day.toString().padLeft(2, '0')}',
        'fecha_fin': '${_fechaFin!.year}-${_fechaFin!.month.toString().padLeft(2, '0')}-${_fechaFin!.day.toString().padLeft(2, '0')}',
      };

      final vacacionProvider = context.read<VacacionProvider>();
      final success = await vacacionProvider.crearVacacion(vacacionData);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vacación creada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Retornar true para indicar éxito
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al crear vacación: ${vacacionProvider.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: Colors.red,
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
    setState(() {
      _colaboradorSeleccionado = null;
      _fechaInicio = null;
      _fechaFin = null;
      _duracionDias = 0;
    });
    _formKey.currentState?.reset();
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
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
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
      title: 'Crear Vacación',
      showAppBarElements: true,
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
      body: _isLoading
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
                                  'Información de Vacaciones',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildDropdown(
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
                                _buildSelectorFecha(
                                  label: 'Fecha de Inicio *',
                                  fecha: _fechaInicio,
                                  onTap: _seleccionarFechaInicio,
                                  hintText: 'Seleccionar fecha de inicio',
                                ),
                                const SizedBox(height: 16),
                                _buildSelectorFecha(
                                  label: 'Fecha de Fin *',
                                  fecha: _fechaFin,
                                  onTap: _seleccionarFechaFin,
                                  hintText: 'Seleccionar fecha de fin',
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
                                onPressed: _isSaving ? null : _guardarVacacion,
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
