import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/sueldo_base.dart';
import '../models/colaborador.dart';
import '../providers/sueldo_base_provider.dart';
import '../providers/colaborador_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/main_scaffold.dart';
import '../theme/app_theme.dart';

class SueldoBaseEditarScreen extends StatefulWidget {
  final SueldoBase sueldo;

  const SueldoBaseEditarScreen({
    super.key,
    required this.sueldo,
  });

  @override
  State<SueldoBaseEditarScreen> createState() => _SueldoBaseEditarScreenState();
}

class _SueldoBaseEditarScreenState extends State<SueldoBaseEditarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sueldoController = TextEditingController();
  final _fechaController = TextEditingController();
  
  Colaborador? _colaboradorSeleccionado;
  DateTime? _fechaSeleccionada;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _inicializarDatos();
    _cargarDatos();
  }

  void _inicializarDatos() {
    _sueldoController.text = widget.sueldo.sueldobase.toString();
    _fechaSeleccionada = widget.sueldo.fecha;
    _fechaController.text = DateFormat('dd/MM/yyyy').format(widget.sueldo.fecha);
  }

  Future<void> _cargarDatos() async {
    final colaboradorProvider = Provider.of<ColaboradorProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

    // Cargar colaboradores directamente

    // Cargar colaboradores
    await colaboradorProvider.cargarColaboradores();

    // Buscar el colaborador actual
    if (mounted) {
      final colaboradores = colaboradorProvider.colaboradores;
      _colaboradorSeleccionado = colaboradores.firstWhere(
        (col) => col.id == widget.sueldo.idColaborador,
        orElse: () => colaboradores.first,
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Editar Sueldo Base',
      showAppBarElements: false,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildFormulario(),
                    const SizedBox(height: 24),
                    // Cálculos automáticos
                    if (_sueldoController.text.isNotEmpty)
                      _buildCalculosAutomaticos(),
                    const SizedBox(height: 32),
                    _buildBotones(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.edit,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Editar Sueldo Base',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Modifique la información del sueldo base',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulario() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información del Sueldo Base',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          _buildSelectorColaborador(),
          const SizedBox(height: 16),
          _buildCampoSueldo(),
          const SizedBox(height: 16),
          _buildCampoFecha(),
        ],
      ),
    );
  }

  Widget _buildSelectorColaborador() {
    return Consumer<ColaboradorProvider>(
      builder: (context, colaboradorProvider, child) {
        if (colaboradorProvider.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (colaboradorProvider.error != null) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(Icons.error_outline, color: Colors.red[600]),
                const SizedBox(height: 8),
                Text(
                  'Error al cargar colaboradores',
                  style: TextStyle(color: Colors.red[600], fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  colaboradorProvider.error!,
                  style: TextStyle(color: Colors.red[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => colaboradorProvider.cargarColaboradores(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        final colaboradores = colaboradorProvider.colaboradores;

        return DropdownButtonFormField<Colaborador>(
          value: _colaboradorSeleccionado,
          decoration: InputDecoration(
            labelText: 'Colaborador *',
            hintText: 'Seleccione un colaborador',
            prefixIcon: const Icon(Icons.person, color: AppTheme.primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
          ),
          items: colaboradores.map((colaborador) {
            return DropdownMenuItem<Colaborador>(
              value: colaborador,
              child: Text(colaborador.nombreCompleto),
            );
          }).toList(),
          onChanged: (Colaborador? value) {
            setState(() {
              _colaboradorSeleccionado = value;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Debe seleccionar un colaborador';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildCampoSueldo() {
    return TextFormField(
      controller: _sueldoController,
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      decoration: InputDecoration(
        labelText: 'Sueldo Base *',
        hintText: 'Ej: 500000',
        prefixIcon: const Icon(Icons.attach_money, color: AppTheme.primaryColor),
        suffixText: 'CLP',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
      onChanged: (value) {
        setState(() {}); // Para actualizar los cálculos automáticos
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'El sueldo base es obligatorio';
        }
        final sueldo = int.tryParse(value);
        if (sueldo == null || sueldo <= 0) {
          return 'El sueldo base debe ser un número positivo';
        }
        return null;
      },
    );
  }

  Widget _buildCampoFecha() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _fechaSeleccionada ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          locale: const Locale('es', 'ES'),
        );
        if (date != null) {
          setState(() {
            _fechaSeleccionada = date;
            _fechaController.text = DateFormat('dd/MM/yyyy').format(date);
          });
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Fecha *',
          prefixIcon: const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
        ),
        child: Text(
          _fechaSeleccionada != null
              ? DateFormat('dd/MM/yyyy').format(_fechaSeleccionada!)
              : 'Seleccione la fecha',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildCalculosAutomaticos() {
    final sueldo = int.tryParse(_sueldoController.text) ?? 0;
    final baseDia = (sueldo / 30).round();
    final horaDia = (sueldo / 264).round();

    return Card(
      color: Colors.blue.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calculate, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  'Cálculos Automáticos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildCalculoItem(
                    'Base Día',
                    '\$${baseDia.toString().replaceAllMapped(
                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                      (Match m) => '${m[1]}.',
                    )}',
                    Icons.calendar_today,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCalculoItem(
                    'Hora Día',
                    '\$${horaDia.toString().replaceAllMapped(
                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                      (Match m) => '${m[1]}.',
                    )}',
                    Icons.access_time,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculoItem(String titulo, String valor, IconData icono) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icono, color: Colors.blue[600], size: 20),
          const SizedBox(height: 8),
          Text(
            valor,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.blue[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotones() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: const BorderSide(color: Colors.grey),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _guardar,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
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
                : const Text(
                    'Actualizar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }


  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_colaboradorSeleccionado == null || _fechaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor complete todos los campos obligatorios'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final sueldo = int.parse(_sueldoController.text);
      
      final sueldoActualizado = SueldoBase(
        id: widget.sueldo.id,
        sueldobase: sueldo,
        idColaborador: _colaboradorSeleccionado!.id,
        fecha: _fechaSeleccionada!,
        baseDia: 0, // Se calculará automáticamente en el backend
        horaDia: 0, // Se calculará automáticamente en el backend
        nombreColaborador: _colaboradorSeleccionado!.nombreCompleto,
        rut: _colaboradorSeleccionado!.rut,
      );

      final sueldoBaseProvider = Provider.of<SueldoBaseProvider>(context, listen: false);
      final success = await sueldoBaseProvider.actualizarSueldoBase(sueldoActualizado);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sueldo base actualizado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al actualizar sueldo base: ${sueldoBaseProvider.error ?? 'Error desconocido'}'),
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

  @override
  void dispose() {
    _sueldoController.dispose();
    _fechaController.dispose();
    super.dispose();
  }
}
