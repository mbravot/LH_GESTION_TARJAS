import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/colaborador_provider.dart';
import '../models/colaborador.dart';
import '../models/horas_extras_otroscecos.dart';
import '../widgets/main_scaffold.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class HorasExtrasOtrosCecosEditarScreen extends StatefulWidget {
  final HorasExtrasOtrosCecos horasExtrasOtrosCecos;

  const HorasExtrasOtrosCecosEditarScreen({
    Key? key,
    required this.horasExtrasOtrosCecos,
  }) : super(key: key);

  @override
  State<HorasExtrasOtrosCecosEditarScreen> createState() => _HorasExtrasOtrosCecosEditarScreenState();
}

class _HorasExtrasOtrosCecosEditarScreenState extends State<HorasExtrasOtrosCecosEditarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadController = TextEditingController();
  
  String? _colaboradorSeleccionado;
  int? _cecoTipoSeleccionado;
  int? _cecoSeleccionado;
  DateTime _fechaSeleccionada = DateTime.now();
  
  List<Colaborador> _colaboradores = [];
  List<CecoTipo> _cecoTipos = [];
  List<Ceco> _cecos = [];
  List<Ceco> _cecosFiltrados = [];
  
  final _cecoSearchController = TextEditingController();
  
  bool _isSaving = false;
  bool _isLoadingData = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cecoSearchController.addListener(_filtrarCecos);
    _inicializarDatos();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatosIniciales();
    });
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _cecoSearchController.dispose();
    super.dispose();
  }

  void _inicializarDatos() {
    _colaboradorSeleccionado = widget.horasExtrasOtrosCecos.idColaborador;
    _cecoTipoSeleccionado = widget.horasExtrasOtrosCecos.idCecoTipo;
    _cecoSeleccionado = widget.horasExtrasOtrosCecos.idCeco;
    _fechaSeleccionada = widget.horasExtrasOtrosCecos.fecha;
    _cantidadController.text = widget.horasExtrasOtrosCecos.cantidad.toString();
  }

  Future<void> _cargarDatosIniciales() async {
    setState(() {
      _isLoadingData = true;
      _error = null;
    });

    try {
      final colaboradorProvider = Provider.of<ColaboradorProvider>(context, listen: false);
      await colaboradorProvider.cargarColaboradores();
      
      // Cargar tipos de CECO directamente
      final tiposData = await ApiService.obtenerTiposCeco();
      
      setState(() {
        _colaboradores = colaboradorProvider.colaboradores;
        _cecoTipos = tiposData
            .map((item) => CecoTipo.fromJson(item))
            .toList();
        _isLoadingData = false;
      });

      // Cargar CECOs del tipo seleccionado si ya hay uno
      if (_cecoTipoSeleccionado != null) {
        await _cargarCecosPorTipo(_cecoTipoSeleccionado.toString());
      }
    } catch (e) {
      setState(() {
        _error = 'Error al cargar datos: $e';
        _isLoadingData = false;
      });
    }
  }

  Future<void> _cargarCecosPorTipo(String tipoCecoId) async {
    if (tipoCecoId.isEmpty) {
      setState(() {
        _cecos = [];
        _cecosFiltrados = [];
        _cecoSeleccionado = null;
        _cecoSearchController.clear();
      });
      return;
    }

    try {
      // Cargar CECOs del tipo seleccionado directamente
      final cecosData = await ApiService.obtenerCecosPorTipo(tipoCecoId);
      
      setState(() {
        _cecos = cecosData
            .map((item) => Ceco.fromJson(item))
            .toList();
        _cecosFiltrados = _cecos; // Inicializar lista filtrada
        // No resetear _cecoSeleccionado en edición para mantener la selección actual
        if (_cecoSeleccionado != null) {
          try {
            final cecoSeleccionado = _cecos.firstWhere((c) => c.id == _cecoSeleccionado);
            _cecoSearchController.text = cecoSeleccionado.nombre;
          } catch (e) {
            // Si no se encuentra el CECO, limpiar la selección
            _cecoSeleccionado = null;
            _cecoSearchController.clear();
          }
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar CECOs: $e';
        _cecos = [];
        _cecosFiltrados = [];
      });
    }
  }

  void _filtrarCecos() {
    final query = _cecoSearchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _cecosFiltrados = _cecos;
      } else {
        _cecosFiltrados = _cecos.where((ceco) =>
          ceco.nombre.toLowerCase().contains(query) ||
          ceco.id.toString().contains(query)
        ).toList();
      }
    });
  }

  Future<double> _obtenerHorasExistentesDelDia() async {
    if (_colaboradorSeleccionado == null) return 0.0;
    
    try {
      final fechaStr = _fechaSeleccionada.toIso8601String().split('T')[0];
      final response = await ApiService.obtenerHorasExtrasOtrosCecos(
        idColaborador: _colaboradorSeleccionado,
        fechaInicio: fechaStr,
        fechaFin: fechaStr,
      );
      
      // Sumar todas las horas extras del colaborador para esa fecha
      // Excluir el registro actual que se está editando
      double totalHoras = 0.0;
      for (final item in response) {
        if (item['id'] != widget.horasExtrasOtrosCecos.id) {
          totalHoras += (item['cantidad'] as num?)?.toDouble() ?? 0.0;
        }
      }
      
      return totalHoras;
    } catch (e) {
      print('Error al obtener horas existentes: $e');
      return 0.0;
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_colaboradorSeleccionado == null || 
        _cecoTipoSeleccionado == null || 
        _cecoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, complete todos los campos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar horas máximas permitidas (2 por día por colaborador)
    final cantidadNueva = double.parse(_cantidadController.text);
    final horasExistentes = await _obtenerHorasExistentesDelDia();
    final totalHoras = horasExistentes + cantidadNueva;
    
    if (totalHoras > 2.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('El colaborador ya tiene $horasExistentes horas extras registradas para esta fecha. El máximo permitido es 2 horas por día. Horas disponibles: ${2.0 - horasExistentes}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final datos = {
        'id_colaborador': _colaboradorSeleccionado,
        'fecha': _fechaSeleccionada.toIso8601String().split('T')[0],
        'id_cecotipo': _cecoTipoSeleccionado,
        'id_ceco': _cecoSeleccionado,
        'cantidad': cantidadNueva,
      };

      await ApiService.editarHorasExtrasOtrosCecos(widget.horasExtrasOtrosCecos.id, datos);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Horas extras otros CECOs actualizadas exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar horas extras otros CECOs: $e'),
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

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (fecha != null) {
      setState(() {
        _fechaSeleccionada = fecha;
      });
    }
  }

  Widget _buildCampoFecha() {
    return GestureDetector(
      onTap: _seleccionarFecha,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Text(
              _fechaSeleccionada != null
                  ? '${_fechaSeleccionada!.day.toString().padLeft(2, '0')}/${_fechaSeleccionada!.month.toString().padLeft(2, '0')}/${_fechaSeleccionada!.year}'
                  : 'Seleccionar fecha',
              style: TextStyle(
                color: _fechaSeleccionada != null ? Colors.black87 : Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Editar Horas Extras Otros CECOs',
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _cargarDatosIniciales,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Información del Registro
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info_outline, color: AppTheme.primaryColor),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Información del Registro',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                
                                // Colaborador
                                DropdownButtonFormField<String>(
                                  value: _colaboradorSeleccionado,
                                  decoration: const InputDecoration(
                                    labelText: 'Colaborador *',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.person),
                                  ),
                                  items: _colaboradores.map((colaborador) {
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
                                      return 'Seleccione un colaborador';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                
                                // Fecha
                                Text(
                                  'Fecha *',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildCampoFecha(),
                                const SizedBox(height: 16),
                                
                                // Tipo de CECO
                                DropdownButtonFormField<int>(
                                  value: _cecoTipoSeleccionado,
                                  decoration: const InputDecoration(
                                    labelText: 'Tipo de CECO *',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.category),
                                  ),
                                  items: _cecoTipos.map((tipo) {
                                    return DropdownMenuItem<int>(
                                      value: tipo.id,
                                      child: Text(tipo.nombre),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _cecoTipoSeleccionado = value;
                                      _cecoSeleccionado = null; // Reset CECO selection
                                    });
                                    // Cargar CECOs del tipo seleccionado
                                    if (value != null) {
                                      _cargarCecosPorTipo(value.toString());
                                    } else {
                                      _cargarCecosPorTipo('');
                                    }
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Seleccione un tipo de CECO';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                
                                // CECO
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CECO *',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _cecoSearchController,
                                      decoration: InputDecoration(
                                        hintText: 'Buscar CECO...',
                                        border: const OutlineInputBorder(),
                                        prefixIcon: const Icon(Icons.search),
                                        suffixIcon: _cecoSeleccionado != null
                                            ? IconButton(
                                                icon: const Icon(Icons.clear),
                                                onPressed: () {
                                                  setState(() {
                                                    _cecoSeleccionado = null;
                                                  });
                                                },
                                              )
                                            : null,
                                      ),
                                      readOnly: _cecoSeleccionado != null,
                                    ),
                                    if (_cecosFiltrados.isNotEmpty && _cecoSeleccionado == null)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey[300]!),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        constraints: const BoxConstraints(maxHeight: 200),
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: _cecosFiltrados.length,
                                          itemBuilder: (context, index) {
                                            final ceco = _cecosFiltrados[index];
                                            return ListTile(
                                              title: Text(ceco.nombre),
                                              subtitle: Text('ID: ${ceco.id}'),
                                              onTap: () {
                                                setState(() {
                                                  _cecoSeleccionado = ceco.id;
                                                  _cecoSearchController.text = ceco.nombre;
                                                });
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    if (_cecoSeleccionado != null)
                                      Container(
                                        margin: const EdgeInsets.only(top: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.green[50],
                                          border: Border.all(color: Colors.green[300]!),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.green[600]),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _cecos.isNotEmpty && _cecoSeleccionado != null
                                                    ? _cecos.firstWhere((c) => c.id == _cecoSeleccionado, orElse: () => Ceco(id: 0, nombre: 'No encontrado', idCecoTipo: 0, idSucursal: 0, idEstado: 0)).nombre
                                                    : 'No seleccionado',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.green[800],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (_cecosFiltrados.isEmpty && _cecoSearchController.text.isNotEmpty)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          border: Border.all(color: Colors.grey[300]!),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'No se encontraron CECOs',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                
                                // Cantidad
                                TextFormField(
                                  controller: _cantidadController,
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Cantidad (horas) *',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.access_time),
                                    suffixText: 'horas',
                                    helperText: 'Máximo 2 horas por día por colaborador',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Ingrese la cantidad de horas';
                                    }
                                    final cantidad = double.tryParse(value);
                                    if (cantidad == null || cantidad <= 0) {
                                      return 'Ingrese una cantidad válida mayor a 0';
                                    }
                                    if (cantidad > 2.0) {
                                      return 'El máximo permitido es 2 horas por día';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Botones
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Cancelar'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _guardar,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _isSaving
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
                ),
    );
  }
}
