import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/trabajador.dart';
import '../providers/trabajador_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/main_scaffold.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class TrabajadorCrearScreen extends StatefulWidget {
  const TrabajadorCrearScreen({super.key});

  @override
  State<TrabajadorCrearScreen> createState() => _TrabajadorCrearScreenState();
}

class _TrabajadorCrearScreenState extends State<TrabajadorCrearScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoPaternoController = TextEditingController();
  final _apellidoMaternoController = TextEditingController();
  final _rutController = TextEditingController();
  final _codigoVerificadorController = TextEditingController();
  
  // Para el cálculo automático del DV
  bool _calculandoDV = false;

  String? _contratistaSeleccionado;
  String? _porcentajeSeleccionado;
  String? _estadoSeleccionado;

  List<Map<String, dynamic>> _contratistas = [];
  List<Map<String, dynamic>> _porcentajes = [];
  List<Map<String, dynamic>> _estados = [];

  bool _isLoading = false;
  bool _isSaving = false;

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

  Future<void> _cargarDatosIniciales() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Cargar opciones usando el nuevo endpoint
      final opcionesData = await ApiService.obtenerOpcionesCrearTrabajador();

      setState(() {
        _contratistas = List<Map<String, dynamic>>.from(opcionesData['contratistas'] ?? []);
        _porcentajes = List<Map<String, dynamic>>.from(opcionesData['porcentajes'] ?? []);
        _estados = List<Map<String, dynamic>>.from(opcionesData['estados'] ?? []);
        
        // Establecer valores por defecto
        if (_estados.isNotEmpty) {
          // Buscar el estado "Activo" (generalmente id = 1)
          final estadoActivo = _estados.firstWhere(
            (estado) => estado['nombre']?.toString().toLowerCase() == 'activo' || 
                       estado['id']?.toString() == '1',
            orElse: () => _estados.first,
          );
          _estadoSeleccionado = estadoActivo['id']?.toString();
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar datos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _guardarTrabajador() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final trabajadorData = {
        'nombre': _nombreController.text.trim(),
        'apellido_paterno': _apellidoPaternoController.text.trim(),
        'apellido_materno': _apellidoMaternoController.text.trim(),
        'rut': _rutController.text.trim().isNotEmpty ? _rutController.text.trim() : null,
        'codigo_verificador': _codigoVerificadorController.text.trim().isNotEmpty 
            ? _codigoVerificadorController.text.trim() 
            : null,
        'id_contratista': _contratistaSeleccionado,
        'id_porcentaje': _porcentajeSeleccionado,
        'id_estado': _estadoSeleccionado,
      };

      final trabajadorProvider = context.read<TrabajadorProvider>();
      final success = await trabajadorProvider.crearTrabajador(trabajadorData);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Trabajador creado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Retornar true para indicar éxito
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al crear trabajador: ${trabajadorProvider.error}'),
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
    _formKey.currentState?.reset();
    _nombreController.clear();
    _apellidoPaternoController.clear();
    _apellidoMaternoController.clear();
    _rutController.clear();
    _codigoVerificadorController.clear();
    setState(() {
      _contratistaSeleccionado = null;
      _porcentajeSeleccionado = null;
      // Mantener el estado activo por defecto
      if (_estados.isNotEmpty) {
        final estadoActivo = _estados.firstWhere(
          (estado) => estado['nombre']?.toString().toLowerCase() == 'activo' || 
                     estado['id']?.toString() == '1',
          orElse: () => _estados.first,
        );
        _estadoSeleccionado = estadoActivo['id']?.toString();
      }
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
    String Function(String?)? displayFormatter,
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
            final formattedValue = displayFormatter != null 
                ? displayFormatter(displayValue)
                : displayValue;
            return DropdownMenuItem<String>(
              value: item[valueField]?.toString(),
              child: Text(formattedValue),
            );
          }),
        ],
        onChanged: onChanged,
        validator: validator,
      ),
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
      title: 'Crear Trabajador',
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                                label: 'Contratista',
                                value: _contratistaSeleccionado,
                                items: _contratistas,
                                displayField: 'nombre',
                                valueField: 'id',
                                onChanged: (value) {
                                  setState(() {
                                    _contratistaSeleccionado = value;
                                  });
                                },
                                isRequired: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Debe seleccionar un contratista';
                                  }
                                  return null;
                                },
                              ),
                                                                                      _buildDropdown(
                                label: 'Porcentaje de Ganancia',
                                value: _porcentajeSeleccionado,
                                items: _porcentajes,
                                displayField: 'porcentaje',
                                valueField: 'id',
                                onChanged: (value) {
                                  setState(() {
                                    _porcentajeSeleccionado = value;
                                  });
                                },
                                isRequired: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Debe seleccionar un porcentaje';
                                  }
                                  return null;
                                },
                                displayFormatter: (value) {
                                  if (value == null) return 'Sin nombre';
                                  final porcentaje = double.tryParse(value.toString());
                                  if (porcentaje != null) {
                                    return '${(porcentaje * 100).toInt()}%';
                                  }
                                  return value.toString();
                                },
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

                    // Botones de acción
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
                            onPressed: _isSaving ? null : _guardarTrabajador,
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
