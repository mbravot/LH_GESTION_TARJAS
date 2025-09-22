import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/contratista_provider.dart';
import '../widgets/main_scaffold.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class ContratistaCrearScreen extends StatefulWidget {
  const ContratistaCrearScreen({Key? key}) : super(key: key);

  @override
  State<ContratistaCrearScreen> createState() => _ContratistaCrearScreenState();
}

class _ContratistaCrearScreenState extends State<ContratistaCrearScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rutController = TextEditingController();
  final _codigoVerificadorController = TextEditingController();
  final _nombreController = TextEditingController();

  String _estadoSeleccionado = 'ACTIVO';
  bool _isLoading = false;
  bool _isSaving = false;
  bool _calculandoDV = false;

  @override
  void initState() {
    super.initState();
    _cargarOpciones();
    _configurarListeners();
  }

  @override
  void dispose() {
    _rutController.dispose();
    _codigoVerificadorController.dispose();
    _nombreController.dispose();
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

  Future<void> _cargarOpciones() async {
    final provider = Provider.of<ContratistaProvider>(context, listen: false);
    await provider.cargarOpciones();
  }

  int _getEstadoId(String estado) {
    switch (estado.toUpperCase()) {
      case 'ACTIVO':
        return 1;
      case 'INACTIVO':
        return 2;
      case 'SUSPENDIDO':
        return 3;
      default:
        return 1;
    }
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

  Future<void> _guardarContratista() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final provider = Provider.of<ContratistaProvider>(context, listen: false);
      
      final datos = {
        'rut': int.tryParse(_rutController.text.trim()) ?? 0,
        'codigo_verificador': _codigoVerificadorController.text.trim(),
        'nombre': _nombreController.text.trim(),
        'id_estado': _getEstadoId(_estadoSeleccionado),
      };

      final success = await provider.crearContratista(datos);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contratista creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear contratista: $e'),
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
    _rutController.clear();
    _codigoVerificadorController.clear();
    _nombreController.clear();
    setState(() {
      _estadoSeleccionado = 'ACTIVO';
    });
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
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: items.contains(value) ? value : (items.isNotEmpty ? items.first : null),
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
        ),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
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
          'RUT',
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
                label: 'Número *',
                controller: _rutController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El RUT es requerido';
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return 'El RUT debe ser solo números';
                  }
                  if (value.trim().length < 7 || value.trim().length > 8) {
                    return 'El RUT debe tener entre 7 y 8 dígitos';
                  }
                  return null;
                },
                keyboardType: TextInputType.number,
                hintText: 'Ej: 12345678',
                maxLength: 8,
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
      title: 'Crear Contratista',
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
      body: Consumer<ContratistaProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información del Contratista
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
                            'Información del Contratista',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildSeccionRut(),
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
                            hintText: 'Ej: CONTRATISTA SANTA VICTORIA',
                          ),
                          _buildDropdown(
                            label: 'Estado',
                            value: _estadoSeleccionado,
                            items: provider.estadosDisponibles,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _estadoSeleccionado = value;
                                });
                              }
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
                          onPressed: _isSaving ? null : _guardarContratista,
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
          );
        },
      ),
    );
  }
}
