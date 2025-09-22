import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/colaborador.dart';
import '../providers/colaborador_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/main_scaffold.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class ColaboradorEditarScreen extends StatefulWidget {
  final Colaborador colaborador;
  
  const ColaboradorEditarScreen({
    super.key,
    required this.colaborador,
  });

  @override
  State<ColaboradorEditarScreen> createState() => _ColaboradorEditarScreenState();
}

class _ColaboradorEditarScreenState extends State<ColaboradorEditarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoPaternoController = TextEditingController();
  final _apellidoMaternoController = TextEditingController();
  final _rutController = TextEditingController();
  final _codigoVerificadorController = TextEditingController();
  final _fechaNacimientoController = TextEditingController();
  final _fechaIncorporacionController = TextEditingController();
  final _fechaFiniquitoController = TextEditingController();
  
  // Para el cálculo automático del DV
  bool _calculandoDV = false;
  String? _cargoSeleccionado;
  String? _previsionSeleccionada;
  String? _afpSeleccionada;
  String? _estadoSeleccionado;

  List<Map<String, dynamic>> _cargos = [];
  List<Map<String, dynamic>> _previsiones = [];
  List<Map<String, dynamic>> _afps = [];
  List<Map<String, dynamic>> _estados = [];

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isLoadingData = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
    _configurarListeners();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoPaternoController.dispose();
    _apellidoMaternoController.dispose();
    _rutController.dispose();
    _codigoVerificadorController.dispose();
    _fechaNacimientoController.dispose();
    _fechaIncorporacionController.dispose();
    _fechaFiniquitoController.dispose();
    super.dispose();
  }

  void _configurarListeners() {
    // Listener para calcular automáticamente el DV cuando cambie el RUT
    _rutController.addListener(() {
      // Solo calcular si el RUT tiene la longitud correcta
      final rut = _rutController.text.trim();
      if (rut.length >= 7 && rut.length <= 8 && int.tryParse(rut) != null) {
        _calcularDigitoVerificador();
      } else if (rut.isEmpty) {
        // Si el RUT está vacío, limpiar el DV
        _codigoVerificadorController.clear();
      }
    });
  }

  // Función para formatear fechas para mostrar en el formulario
  String _formatearFechaParaMostrar(String? fechaStr) {
    if (fechaStr == null || fechaStr.isEmpty) return '';
    
    try {
      // Si es un formato GMT, parsearlo
      if (fechaStr.contains('GMT')) {
        final regex = RegExp(r'(\w{3}), (\d{1,2}) (\w{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2}) GMT');
        final match = regex.firstMatch(fechaStr);
        
        if (match != null) {
          final day = int.parse(match.group(2)!);
          final monthStr = match.group(3)!;
          final year = int.parse(match.group(4)!);
          
          final monthMap = {
            'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
            'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
          };
          
          final month = monthMap[monthStr];
          if (month != null) {
            final fecha = DateTime(year, month, day);
            return '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
          }
        }
      } else {
        // Intentar parsear como ISO o formato YYYY-MM-DD
        final fecha = DateTime.parse(fechaStr);
        return '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      // Si no se puede parsear, devolver string vacío
      return '';
    }
    
    return '';
  }

  Future<void> _cargarDatosIniciales() async {
    setState(() {
      _isLoadingData = true;
      _error = null;
    });

    try {
      // Cargar opciones para editar colaborador
      final opcionesData = await ApiService.obtenerOpcionesEditarColaborador(widget.colaborador.id);
      
      setState(() {
        _cargos = List<Map<String, dynamic>>.from(opcionesData['cargos'] ?? []);
        _previsiones = List<Map<String, dynamic>>.from(opcionesData['previsiones'] ?? []);
        _afps = List<Map<String, dynamic>>.from(opcionesData['afps'] ?? []);
        _estados = List<Map<String, dynamic>>.from(opcionesData['estados'] ?? []);
        
        // Pre-llenar los campos con los datos existentes
        _nombreController.text = widget.colaborador.nombre;
        _apellidoPaternoController.text = widget.colaborador.apellidoPaterno;
        _apellidoMaternoController.text = widget.colaborador.apellidoMaterno ?? '';
        _rutController.text = widget.colaborador.rut ?? '';
        _codigoVerificadorController.text = widget.colaborador.codigoVerificador ?? '';
        _fechaNacimientoController.text = _formatearFechaParaMostrar(widget.colaborador.fechaNacimiento);
        _fechaIncorporacionController.text = _formatearFechaParaMostrar(widget.colaborador.fechaIncorporacion);
        _fechaFiniquitoController.text = _formatearFechaParaMostrar(widget.colaborador.fechaFiniquito);
        
        // Asignar valores seleccionados, asegurándose de que no sean null si existen
        _cargoSeleccionado = widget.colaborador.idCargo?.isNotEmpty == true 
            ? widget.colaborador.idCargo 
            : null;
        _previsionSeleccionada = widget.colaborador.idPrevision?.isNotEmpty == true 
            ? widget.colaborador.idPrevision 
            : null;
        _afpSeleccionada = widget.colaborador.idAfp?.isNotEmpty == true 
            ? widget.colaborador.idAfp 
            : null;
        _estadoSeleccionado = widget.colaborador.idEstado?.isNotEmpty == true 
            ? widget.colaborador.idEstado 
            : '1'; // Estado por defecto
            

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
        _isLoadingData = false;
      });
    }
  }

  Future<void> _guardarColaborador() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Función helper para formatear fechas para MySQL
      String? _formatearFechaParaMySQL(String? fechaStr) {
        if (fechaStr == null || fechaStr.isEmpty) return null;
        
        try {
          // Intentar parsear la fecha
          DateTime fecha;
          
          // Si es un formato GMT, parsearlo
          if (fechaStr.contains('GMT')) {
            final regex = RegExp(r'(\w{3}), (\d{1,2}) (\w{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2}) GMT');
            final match = regex.firstMatch(fechaStr);
            
            if (match != null) {
              final day = int.parse(match.group(2)!);
              final monthStr = match.group(3)!;
              final year = int.parse(match.group(4)!);
              
              final monthMap = {
                'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
                'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
              };
              
              final month = monthMap[monthStr];
              if (month != null) {
                fecha = DateTime(year, month, day);
              } else {
                return null;
              }
            } else {
              return null;
            }
          } else {
            // Intentar parsear como ISO
            fecha = DateTime.parse(fechaStr);
          }
          
          // Formatear para MySQL (YYYY-MM-DD)
          return '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
        } catch (e) {
          return null;
        }
      }

      final colaboradorData = {
        'nombre': _nombreController.text.trim(),
        'apellido_paterno': _apellidoPaternoController.text.trim(),
        'apellido_materno': _apellidoMaternoController.text.trim(),
        'rut': _rutController.text.trim().isNotEmpty ? _rutController.text.trim() : null,
        'codigo_verificador': _codigoVerificadorController.text.trim().isNotEmpty 
            ? _codigoVerificadorController.text.trim() 
            : null,
        'fecha_nacimiento': _formatearFechaParaMySQL(_fechaNacimientoController.text.trim()),
        'fecha_incorporacion': _formatearFechaParaMySQL(_fechaIncorporacionController.text.trim()),
        'fecha_finiquito': _formatearFechaParaMySQL(_fechaFiniquitoController.text.trim()),
        'id_cargo': _cargoSeleccionado,
        'id_prevision': _previsionSeleccionada,
        'id_afp': _afpSeleccionada,
        'id_estado': _estadoSeleccionado,
      };

      final colaboradorProvider = context.read<ColaboradorProvider>();
      final success = await colaboradorProvider.editarColaborador(widget.colaborador.id, colaboradorData);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Colaborador actualizado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Retornar true para indicar éxito
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al actualizar colaborador: ${colaboradorProvider.error}'),
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
    // Restaurar los valores originales del colaborador
    _nombreController.text = widget.colaborador.nombre;
    _apellidoPaternoController.text = widget.colaborador.apellidoPaterno;
    _apellidoMaternoController.text = widget.colaborador.apellidoMaterno ?? '';
    _rutController.text = widget.colaborador.rut ?? '';
    _codigoVerificadorController.text = widget.colaborador.codigoVerificador ?? '';
    _fechaNacimientoController.text = widget.colaborador.fechaNacimiento ?? '';
    _fechaIncorporacionController.text = widget.colaborador.fechaIncorporacion ?? '';
    _fechaFiniquitoController.text = widget.colaborador.fechaFiniquito ?? '';
    
    setState(() {
          // Restaurar valores seleccionados con la misma lógica
    _cargoSeleccionado = widget.colaborador.idCargo?.isNotEmpty == true 
        ? widget.colaborador.idCargo 
        : null;
    _previsionSeleccionada = widget.colaborador.idPrevision?.isNotEmpty == true 
        ? widget.colaborador.idPrevision 
        : null;
    _afpSeleccionada = widget.colaborador.idAfp?.isNotEmpty == true 
        ? widget.colaborador.idAfp 
        : null;
    _estadoSeleccionado = widget.colaborador.idEstado?.isNotEmpty == true 
        ? widget.colaborador.idEstado 
        : '1';
    });
  }

  // Calcular automáticamente el dígito verificador
  Future<void> _calcularDigitoVerificador() async {
    final rut = _rutController.text.trim();
    
    // Validar que el RUT tenga entre 7 y 8 dígitos
    if (rut.length >= 7 && rut.length <= 8 && int.tryParse(rut) != null) {
      setState(() {
        _calculandoDV = true;
      });

      // Pequeño delay para evitar demasiadas llamadas
      await Future.delayed(const Duration(milliseconds: 300));

      // Verificar que el RUT no haya cambiado durante el delay
      if (_rutController.text.trim() != rut) {
        setState(() {
          _calculandoDV = false;
        });
        return;
      }

      try {
        // Intentar obtener el DV del backend primero
        final dv = await ApiService.calcularDigitoVerificador(rut);
        if (mounted && _rutController.text.trim() == rut) {
          _codigoVerificadorController.text = dv;
        }
      } catch (e) {
        // Si falla el backend, calcular localmente
        if (mounted && _rutController.text.trim() == rut) {
          final dvLocal = _calcularDVLocal(rut);
          _codigoVerificadorController.text = dvLocal;
        }
      } finally {
        if (mounted) {
          setState(() {
            _calculandoDV = false;
          });
        }
      }
    } else {
      // Si el RUT no es válido, limpiar el DV
      _codigoVerificadorController.clear();
    }
  }

  // Calcular DV localmente como fallback
  String _calcularDVLocal(String rut) {
    if (rut.isEmpty || rut.length < 7 || rut.length > 8) {
      return '';
    }

    int suma = 0;
    int multiplicador = 2;

    // Calcular suma ponderada
    for (int i = rut.length - 1; i >= 0; i--) {
      suma += int.parse(rut[i]) * multiplicador;
      multiplicador++;
      if (multiplicador > 7) {
        multiplicador = 2;
      }
    }

    // Calcular dígito verificador
    int resto = suma % 11;
    int dv = 11 - resto;

    if (dv == 11) {
      return '0';
    } else if (dv == 10) {
      return 'K';
    } else {
      return dv.toString();
    }
  }

  Widget _buildCampoTexto({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    int? maxLines = 1,
    String? hintText,
    int? maxLength,
    bool readOnly = false,
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
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          counterText: '', // Ocultar contador de caracteres
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<Map<String, dynamic>> items,
    required String displayField,
    required String valueField,
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
            final displayValue = item[displayField]?.toString() ?? 'Sin nombre';
            return DropdownMenuItem<String>(
              value: item[valueField]?.toString(),
              child: Text(displayValue),
            );
          }),
        ],
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  Future<void> _seleccionarFecha(TextEditingController controller, String titulo) async {
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      locale: const Locale('es', 'ES'),
      helpText: titulo,
      cancelText: 'Cancelar',
      confirmText: 'Seleccionar',
    );

    if (fechaSeleccionada != null) {
      final fechaFormateada = '${fechaSeleccionada.year}-${fechaSeleccionada.month.toString().padLeft(2, '0')}-${fechaSeleccionada.day.toString().padLeft(2, '0')}';
      controller.text = fechaFormateada;
    }
  }

  Widget _buildCampoFecha({
    required String label,
    required TextEditingController controller,
    required String titulo,
    bool isRequired = false,
    bool allowClear = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Seleccionar $label',
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (allowClear && controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        controller.clear();
                      });
                    },
                    tooltip: 'Limpiar fecha',
                  ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _seleccionarFecha(controller, titulo),
                  tooltip: 'Seleccionar fecha',
                ),
              ],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
          ),
          onTap: () => _seleccionarFecha(controller, titulo),
          validator: isRequired
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'Este campo es obligatorio';
                  }
                  return null;
                }
              : null,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSeccionRut() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RUT (Opcional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildCampoTexto(
                label: 'Número',
                controller: _rutController,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    // Validar que sea solo números
                    if (int.tryParse(value) == null) {
                      return 'El RUT debe ser solo números';
                    }
                    // Validar longitud entre 7 y 8 dígitos
                    if (value.length < 7 || value.length > 8) {
                      return 'El RUT debe tener entre 7 y 8 dígitos';
                    }
                  }
                  return null;
                },
                keyboardType: TextInputType.number,
                hintText: 'Ej: 12345678',
                maxLength: 8, // Máximo 8 dígitos
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: _buildCampoTexto(
                label: 'DV',
                controller: _codigoVerificadorController,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (value.length != 1) {
                      return 'El dígito verificador debe ser un carácter';
                    }
                    // Validar que sea un dígito o 'K'
                    if (!RegExp(r'^[0-9K]$').hasMatch(value.toUpperCase())) {
                      return 'DV debe ser un número o K';
                    }
                  }
                  return null;
                },
                keyboardType: TextInputType.text,
                hintText: _calculandoDV ? 'Calculando...' : 'K',
                readOnly: true, // Solo lectura ya que se calcula automáticamente
              ),
            ),
          ],
        ),
        if (_calculandoDV)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Calculando dígito verificador...',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Editar Colaborador',
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
                        // Información del colaborador
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
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person,
                                      color: AppTheme.primaryColor,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Editando: ${widget.colaborador.nombreCompleto}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'ID: ${widget.colaborador.id}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Información Personal
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
                                  'Información Personal',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildCampoTexto(
                                  label: 'Nombre *',
                                  controller: _nombreController,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'El nombre es requerido';
                                    }
                                    return null;
                                  },
                                  hintText: 'Ingrese el nombre',
                                ),
                                _buildCampoTexto(
                                  label: 'Apellido Paterno *',
                                  controller: _apellidoPaternoController,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'El apellido paterno es requerido';
                                    }
                                    return null;
                                  },
                                  hintText: 'Ingrese el apellido paterno',
                                ),
                                _buildCampoTexto(
                                  label: 'Apellido Materno',
                                  controller: _apellidoMaternoController,
                                  validator: (value) => null, // Opcional
                                  hintText: 'Ingrese el apellido materno (opcional)',
                                ),
                                const SizedBox(height: 16),
                                _buildSeccionRut(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Información Laboral
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
                                  'Información Laboral',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildDropdown(
                                  label: 'Cargo',
                                  value: _cargoSeleccionado,
                                  items: _cargos,
                                  displayField: 'nombre',
                                  valueField: 'id',
                                  onChanged: (value) {
                                    setState(() {
                                      _cargoSeleccionado = value;
                                    });
                                  },
                                  isRequired: false,
                                ),
                                _buildDropdown(
                                  label: 'Previsión',
                                  value: _previsionSeleccionada,
                                  items: _previsiones,
                                  displayField: 'nombre',
                                  valueField: 'id',
                                  onChanged: (value) {
                                    setState(() {
                                      _previsionSeleccionada = value;
                                    });
                                  },
                                  isRequired: false,
                                ),
                                _buildDropdown(
                                  label: 'AFP',
                                  value: _afpSeleccionada,
                                  items: _afps,
                                  displayField: 'nombre',
                                  valueField: 'id',
                                  onChanged: (value) {
                                    setState(() {
                                      _afpSeleccionada = value;
                                    });
                                  },
                                  isRequired: false,
                                ),
                                _buildDropdown(
                                  label: 'Estado',
                                  value: _estadoSeleccionado,
                                  items: _estados,
                                  displayField: 'nombre',
                                  valueField: 'id',
                                  onChanged: (value) {
                                    setState(() {
                                      _estadoSeleccionado = value;
                                    });
                                  },
                                  isRequired: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Debe seleccionar un estado';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Sección de Fechas
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
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
                                _buildCampoFecha(
                                  label: 'Fecha de Nacimiento',
                                  controller: _fechaNacimientoController,
                                  titulo: 'Seleccionar Fecha de Nacimiento',
                                ),
                                _buildCampoFecha(
                                  label: 'Fecha de Incorporación',
                                  controller: _fechaIncorporacionController,
                                  titulo: 'Seleccionar Fecha de Incorporación',
                                ),
                                _buildCampoFecha(
                                  label: 'Fecha de Finiquito',
                                  controller: _fechaFiniquitoController,
                                  titulo: 'Seleccionar Fecha de Finiquito',
                                  allowClear: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Botones de acción
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isSaving ? null : _limpiarFormulario,
                                icon: const Icon(Icons.undo),
                                label: const Text('Restaurar'),
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
                                onPressed: _isSaving ? null : _guardarColaborador,
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
                                label: Text(_isSaving ? 'Guardando...' : 'Actualizar'),
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
