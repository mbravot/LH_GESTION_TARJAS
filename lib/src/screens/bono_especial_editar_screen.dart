import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bono_especial_provider.dart';
import '../providers/colaborador_provider.dart';
import '../models/bono_especial.dart';
import '../theme/app_theme.dart';
import '../widgets/main_scaffold.dart';

class BonoEspecialEditarScreen extends StatefulWidget {
  final BonoEspecial bonoEspecial;

  const BonoEspecialEditarScreen({
    Key? key,
    required this.bonoEspecial,
  }) : super(key: key);

  @override
  State<BonoEspecialEditarScreen> createState() => _BonoEspecialEditarScreenState();
}

class _BonoEspecialEditarScreenState extends State<BonoEspecialEditarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadController = TextEditingController();
  
  String? _colaboradorSeleccionado;
  DateTime _fechaSeleccionada = DateTime(DateTime.now().year, DateTime.now().month, 0);
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _inicializarDatos();
    _cargarDatosIniciales();
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }

  void _inicializarDatos() {
    _colaboradorSeleccionado = widget.bonoEspecial.idColaborador;
    _fechaSeleccionada = widget.bonoEspecial.fecha;
    _cantidadController.text = widget.bonoEspecial.cantidad.toString();
  }

  void _cargarDatosIniciales() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final colaboradorProvider = context.read<ColaboradorProvider>();
      colaboradorProvider.cargarColaboradores();
    });
  }

  Future<void> _actualizarBonoEspecial() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_colaboradorSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione un colaborador'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = context.read<BonoEspecialProvider>();
      
      final datos = {
        'id_colaborador': _colaboradorSeleccionado,
        'fecha': _fechaSeleccionada.toIso8601String().split('T')[0],
        'cantidad': double.parse(_cantidadController.text),
      };

      final resultado = await provider.editarBonoEspecial(widget.bonoEspecial.id, datos);

      if (resultado) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bono especial actualizado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.error),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar bono especial: $e'),
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
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Editar Bono Especial',
      showAppBarElements: true,
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
                  'Editar Bono Especial',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Modifique la información del bono especial',
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
            'Información del Bono',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          _buildColaboradorField(),
          const SizedBox(height: 16),
          _buildFechaField(),
          const SizedBox(height: 16),
          _buildCantidadField(),
        ],
      ),
    );
  }

  Widget _buildColaboradorField() {
    return Consumer<ColaboradorProvider>(
      builder: (context, provider, child) {
        return DropdownButtonFormField<String>(
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
          items: provider.colaboradores.map((colaborador) {
            return DropdownMenuItem<String>(
              value: colaborador.id,
              child: Text(colaborador.nombreCompleto),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _colaboradorSeleccionado = value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor seleccione un colaborador';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildFechaField() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _fechaSeleccionada,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          locale: const Locale('es', 'ES'),
        );
        if (date != null) {
          setState(() {
            _fechaSeleccionada = date;
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
          '${_fechaSeleccionada.day.toString().padLeft(2, '0')}/${_fechaSeleccionada.month.toString().padLeft(2, '0')}/${_fechaSeleccionada.year}',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildCantidadField() {
    return TextFormField(
      controller: _cantidadController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Cantidad de Horas *',
        hintText: 'Ej: 2.5',
        prefixIcon: const Icon(Icons.access_time, color: AppTheme.primaryColor),
        suffixText: 'horas',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese la cantidad de horas';
        }
        final cantidad = double.tryParse(value);
        if (cantidad == null) {
          return 'Por favor ingrese un número válido';
        }
        if (cantidad <= 0) {
          return 'La cantidad debe ser mayor a 0';
        }
        return null;
      },
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
            onPressed: _isLoading ? null : _actualizarBonoEspecial,
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
}
