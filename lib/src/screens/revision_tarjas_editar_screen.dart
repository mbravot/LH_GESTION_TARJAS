import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tarja.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/main_scaffold.dart';
import '../theme/app_theme.dart';

class RevisionTarjasEditarScreen extends StatefulWidget {
  final Tarja tarja;

  const RevisionTarjasEditarScreen({
    super.key,
    required this.tarja,
  });

  @override
  State<RevisionTarjasEditarScreen> createState() => _RevisionTarjasEditarScreenState();
}

class _RevisionTarjasEditarScreenState extends State<RevisionTarjasEditarScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tarifaController;
  bool _isLoading = false;
  bool _hasChanges = false;
  
  // Estado de edición por campo
  bool _editLabor = false;
  bool _editUnidad = false;
  bool _editTarifa = false;

  // Variables para los dropdowns
  List<Map<String, dynamic>> _labores = [];
  List<Map<String, dynamic>> _unidades = [];
  String? _selectedLaborId;
  String? _selectedUnidadId;
  bool _isLoadingLabores = true;
  bool _isLoadingUnidades = true;
  String? _errorLabores;
  String? _errorUnidades;

  @override
  void initState() {
    super.initState();
    _tarifaController = TextEditingController(text: widget.tarja.tarifa);
    
    // Inicializar valores seleccionados
    _selectedLaborId = widget.tarja.idLabor;
    _selectedUnidadId = widget.tarja.idUnidad;
    
    // Escuchar cambios en el controlador
    _tarifaController.addListener(_onFieldChanged);
    
    // Cargar catálogos
    _cargarLabores();
    _cargarUnidades();
  }

  void _onFieldChanged() {
    final hasChanges = _selectedLaborId != widget.tarja.idLabor ||
                      _selectedUnidadId != widget.tarja.idUnidad ||
                      _tarifaController.text != widget.tarja.tarifa;
    
    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  Future<void> _cargarLabores() async {
    setState(() { _isLoadingLabores = true; _errorLabores = null; });
    try {
      final labores = await ApiService.getLabores();
      setState(() { _labores = labores; });
    } catch (e) {
      setState(() { _errorLabores = e.toString(); });
    } finally {
      setState(() { _isLoadingLabores = false; });
    }
  }

  Future<void> _cargarUnidades() async {
    setState(() { _isLoadingUnidades = true; _errorUnidades = null; });
    try {
      final unidades = await ApiService.getUnidades();
      setState(() { _unidades = unidades; });
    } catch (e) {
      setState(() { _errorUnidades = e.toString(); });
    } finally {
      setState(() { _isLoadingUnidades = false; });
    }
  }

  @override
  void dispose() {
    _tarifaController.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });
    try {
      final datosActualizados = {
        'fecha': widget.tarja.fecha,
        'id_tipotrabajador': widget.tarja.idTipotrabajador,
        'id_tiporendimiento': widget.tarja.idTiporendimiento,
        'id_labor': _selectedLaborId,
        'id_unidad': _selectedUnidadId,
        'id_tipoceco': widget.tarja.idTipoceco,
        'tarifa': double.tryParse(_tarifaController.text) ?? 0.0,
        'hora_inicio': widget.tarja.horaInicio,
        'hora_fin': widget.tarja.horaFin,
        'id_estadoactividad': widget.tarja.idEstadoactividad,
        'id_contratista': widget.tarja.idTipotrabajador == '2' ? widget.tarja.idContratista : null,
      };
      await ApiService().actualizarTarja(widget.tarja.id, datosActualizados);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Actividad actualizada correctamente'), backgroundColor: AppTheme.successColor),
        );
        setState(() {
          _editLabor = false;
          _editUnidad = false;
          _editTarifa = false;
          _hasChanges = false;
        });
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _confirmarSalida() async {
    if (!_hasChanges) {
      Navigator.pop(context);
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir sin guardar?'),
        content: const Text('Tienes cambios sin guardar. ¿Estás seguro de que quieres salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Salir sin guardar'),
          ),
        ],
      ),
    );

    if (result == true) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.colorScheme.surface;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    final textColor = theme.colorScheme.onSurface;
    final iconEdit = Icon(Icons.edit, color: Colors.green[700], size: 20);

    return MainScaffold(
      title: 'Editar Actividad',
      onRefresh: () async {
        // Refrescar datos si es necesario
      },
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información de la actividad (solo lectura)
            Card(
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: borderColor, width: 1),
              ),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                                         Text(
                       'Detalles de la Actividad',
                       style: TextStyle(
                         fontSize: 18,
                         fontWeight: FontWeight.bold,
                         color: textColor,
                       ),
                     ),
                    const SizedBox(height: 16),
                                         _InfoRow(
                       icon: Icons.calendar_today,
                       label: 'Fecha',
                       value: _formatearFecha(widget.tarja.fecha),
                       iconColor: Colors.green,
                     ),
                     const SizedBox(height: 8),
                     _InfoRow(
                       icon: Icons.person,
                       label: 'Usuario',
                       value: _getNombreCompletoUsuario(widget.tarja.nombreUsuario),
                       iconColor: Colors.blue,
                     ),
                     const SizedBox(height: 8),
                     _InfoRow(
                       icon: Icons.work_outline,
                       label: 'Tipo Trabajador',
                       value: _getTipoTrabajadorText(widget.tarja.idTipotrabajador),
                       iconColor: Colors.purple,
                     ),
                     const SizedBox(height: 8),
                     _InfoRow(
                       icon: Icons.business,
                       label: 'Personal',
                       value: _getContratistaText(widget.tarja),
                       iconColor: Colors.indigo,
                     ),
                     const SizedBox(height: 8),
                     _InfoRow(
                       icon: Icons.assessment,
                       label: 'Tipo Rendimiento',
                       value: widget.tarja.tipoRend.isNotEmpty ? widget.tarja.tipoRend : 'No especificado',
                       iconColor: Colors.orange,
                     ),
                     const SizedBox(height: 8),
                     _InfoRow(
                       icon: Icons.work,
                       label: 'Labor',
                       value: widget.tarja.labor,
                       iconColor: AppTheme.primaryColor,
                     ),
                     const SizedBox(height: 8),
                     _InfoRow(
                       icon: Icons.straighten,
                       label: 'Unidad',
                       value: _getUnidadText(widget.tarja),
                       iconColor: Colors.teal,
                     ),
                     const SizedBox(height: 8),
                     _InfoRow(
                       icon: Icons.category,
                       label: 'Tipo CECO',
                       value: _getTipoCecoText(widget.tarja),
                       iconColor: Colors.amber,
                     ),
                     const SizedBox(height: 8),
                     _InfoRow(
                       icon: Icons.attach_money,
                       label: 'Tarifa',
                       value: '\$${widget.tarja.tarifa}',
                       iconColor: Colors.green,
                     ),
                     const SizedBox(height: 8),
                     _InfoRow(
                       icon: Icons.schedule,
                       label: 'Horario',
                       value: '${widget.tarja.horaInicio} - ${widget.tarja.horaFin}',
                       iconColor: Colors.indigo,
                     ),
                     const SizedBox(height: 8),
                     _InfoRow(
                       icon: Icons.assessment,
                       label: 'Estado',
                       value: _getEstadoActividad(widget.tarja.idEstadoactividad)['nombre'],
                       iconColor: _getEstadoActividad(widget.tarja.idEstadoactividad)['color'],
                     ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Formulario de edición
            Card(
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: borderColor, width: 1),
              ),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Editar Campos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Labor
                      Row(
                        children: [
                          Expanded(
                            child: _editLabor
                              ? (_isLoadingLabores
                                  ? const LinearProgressIndicator()
                                  : _errorLabores != null
                                    ? Text('Error: $_errorLabores', style: const TextStyle(color: Colors.red))
                                    : DropdownButtonFormField<String>(
                                        value: _selectedLaborId,
                                        decoration: InputDecoration(
                                          labelText: 'Labor',
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        items: _labores.map((labor) {
                                          return DropdownMenuItem<String>(
                                            value: labor['id']?.toString(),
                                            child: Text(labor['nombre'] ?? labor['descripcion'] ?? 'Sin nombre'),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() { _selectedLaborId = value; });
                                          _onFieldChanged();
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) return 'La labor es requerida';
                                          return null;
                                        },
                                      )
                                )
                              : ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(_labores.firstWhere((l) => l['id'].toString() == _selectedLaborId, orElse: () => {'nombre': widget.tarja.labor})['nombre'] ?? widget.tarja.labor),
                                  leading: Icon(Icons.work, color: AppTheme.primaryColor),
                                  trailing: IconButton(icon: iconEdit, onPressed: _activarEdicionLabor),
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Unidad
                      Row(
                        children: [
                          Expanded(
                            child: _editUnidad
                              ? (_isLoadingUnidades
                                  ? const LinearProgressIndicator()
                                  : _errorUnidades != null
                                    ? Text('Error: $_errorUnidades', style: const TextStyle(color: Colors.red))
                                    : DropdownButtonFormField<String>(
                                        value: _selectedUnidadId,
                                        decoration: InputDecoration(
                                          labelText: 'Unidad',
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        items: _unidades.map((unidad) {
                                          return DropdownMenuItem<String>(
                                            value: unidad['id']?.toString(),
                                            child: Text(unidad['nombre'] ?? unidad['descripcion'] ?? 'Sin nombre'),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() { _selectedUnidadId = value; });
                                          _onFieldChanged();
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) return 'La unidad es requerida';
                                          return null;
                                        },
                                      )
                                )
                              : ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(_unidades.firstWhere((u) => u['id'].toString() == _selectedUnidadId, orElse: () => {'nombre': widget.tarja.nombreUnidad ?? widget.tarja.idUnidad})['nombre'] ?? widget.tarja.nombreUnidad ?? widget.tarja.idUnidad),
                                  leading: Icon(Icons.straighten, color: Colors.orange),
                                  trailing: IconButton(icon: iconEdit, onPressed: _activarEdicionUnidad),
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Tarifa
                      Row(
                        children: [
                          Expanded(
                            child: _editTarifa
                              ? TextFormField(
                                  controller: _tarifaController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Tarifa',
                                    prefixIcon: const Icon(Icons.attach_money, color: Colors.green),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) return 'La tarifa es requerida';
                                    final tarifa = double.tryParse(value);
                                    if (tarifa == null || tarifa < 0) return 'Ingrese una tarifa válida';
                                    return null;
                                  },
                                )
                              : ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(' ${_tarifaController.text}'),
                                  leading: Icon(Icons.attach_money, color: Colors.green),
                                  trailing: IconButton(icon: iconEdit, onPressed: _activarEdicionTarifa),
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Botones de acción
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _confirmarSalida,
                              icon: const Icon(Icons.cancel),
                              label: const Text('Cancelar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading || !_hasChanges ? null : _guardarCambios,
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
                              label: Text(_isLoading ? 'Guardando...' : 'Guardar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
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
            ),
          ],
        ),
      ),
    );
  }

  String _formatearFecha(String fecha) {
    try {
      final date = DateTime.parse(fecha);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return fecha;
    }
  }

  // Helper para convertir nombre de usuario corto a nombre completo
  String _getNombreCompletoUsuario(String? nombreUsuario) {
    if (nombreUsuario == null || nombreUsuario.isEmpty) {
      return 'No especificado';
    }
    
    // Mapeo de nombres de usuario a nombres completos
    final Map<String, String> mapeoNombres = {
      'galarcon': 'Gonzalo Alarcón',
      'mbravo': 'Miguel Bravo',
      'jperez': 'Juan Pérez',
      'mgarcia': 'María García',
      'lrodriguez': 'Luis Rodríguez',
      'asanchez': 'Ana Sánchez',
      'cmartinez': 'Carlos Martínez',
      'plopez': 'Patricia López',
      'rgonzalez': 'Roberto González',
      'dhernandez': 'Daniel Hernández',
      // Agregar más mapeos según sea necesario
    };
    
    return mapeoNombres[nombreUsuario.toLowerCase()] ?? nombreUsuario;
  }

  String _getTipoTrabajadorText(String? id) {
    switch (id) {
      case '1':
        return 'Personal Propio';
      case '2':
        return 'Contratista';
      default:
        return 'No especificado';
    }
  }

  String _getContratistaText(Tarja tarja) {
    if (tarja.idContratista == null || tarja.idContratista!.isEmpty) {
      return 'PERSONAL PROPIO';
    } else {
      return tarja.trabajador.isNotEmpty ? tarja.trabajador : 'Contratista ID: ${tarja.idContratista}';
    }
  }

  String _getTipoCecoText(Tarja tarja) {
    if (tarja.nombreTipoceco != null && tarja.nombreTipoceco!.isNotEmpty) {
      return tarja.nombreTipoceco!;
    } else if (tarja.idTipoceco.isNotEmpty) {
      return 'Tipo CECO ID: ${tarja.idTipoceco}';
    } else {
      return 'No especificado';
    }
  }

  String _getUnidadText(Tarja tarja) {
    // Debug logging
    print('DEBUG - _getUnidadText:');
    print('  nombreUnidad: ${tarja.nombreUnidad}');
    print('  idUnidad: ${tarja.idUnidad}');
    
    if (tarja.nombreUnidad != null && tarja.nombreUnidad!.isNotEmpty) {
      print('  Retornando nombre: ${tarja.nombreUnidad}');
      return tarja.nombreUnidad!;
    } else if (tarja.idUnidad.isNotEmpty) {
      print('  Retornando ID: ${tarja.idUnidad}');
      return 'ID: ${tarja.idUnidad}';
    } else {
      print('  Retornando: No especificado');
      return 'No especificado';
    }
  }

  Map<String, dynamic> _getEstadoActividad(String? id) {
    switch (id) {
      case '1':
        return {"nombre": "CREADA", "color": Colors.orange};
      case '2':
        return {"nombre": "REVISADA", "color": Colors.green};
      case '3':
        return {"nombre": "APROBADA", "color": Colors.green};
      case '4':
        return {"nombre": "FINALIZADA", "color": Colors.blue};
      default:
        return {"nombre": "DESCONOCIDO", "color": Colors.grey};
    }
  }

  void _activarEdicionLabor() async {
    if (!_editLabor) {
      setState(() { _editLabor = true; });
      if (_labores.isEmpty) await _cargarLabores();
    }
  }

  void _activarEdicionUnidad() async {
    if (!_editUnidad) {
      setState(() { _editUnidad = true; });
      if (_unidades.isEmpty) await _cargarUnidades();
    }
  }

  void _activarEdicionTarifa() {
    setState(() { _editTarifa = true; });
  }

  void _cancelarEdicion() {
    setState(() {
      _editLabor = false;
      _editUnidad = false;
      _editTarifa = false;
      _selectedLaborId = widget.tarja.idLabor;
      _selectedUnidadId = widget.tarja.idUnidad;
      _tarifaController.text = widget.tarja.tarifa;
      _hasChanges = false;
    });
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    
    return Row(
      children: [
        Icon(icon, color: iconColor ?? AppTheme.primaryColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: textColor.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
