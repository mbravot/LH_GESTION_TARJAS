import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/tarja_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/main_scaffold.dart';
import '../services/tarja_service.dart';
import 'dart:convert';

class RendimientosPageScreen extends StatefulWidget {
  final String actividadId;
  final String? idTipotrabajador;
  final String? idTiporendimiento;
  final String? idContratista;

  const RendimientosPageScreen({
    Key? key,
    required this.actividadId,
    this.idTipotrabajador,
    this.idTiporendimiento,
    this.idContratista,
  }) : super(key: key);

  @override
  State<RendimientosPageScreen> createState() => _RendimientosPageScreenState();
}

class _RendimientosPageScreenState extends State<RendimientosPageScreen> {
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _rendimientos = [];
  String _tipoActividad = '';
  Map<String, String> _camposRendimiento = {};
  Map<String, dynamic>? _actividadInfo;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _cargarRendimientos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarRendimientos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Determinar el tipo de actividad
      String tipoActividad;
      if (widget.idContratista != null && widget.idContratista!.isNotEmpty) {
        tipoActividad = 'contratista';
      } else if (widget.idTiporendimiento == '2') {
        tipoActividad = 'grupal';
      } else if (widget.idTipotrabajador == '1') {
        tipoActividad = 'propio';
      } else if (widget.idTipotrabajador == '2') {
        tipoActividad = 'contratista';
      } else {
        tipoActividad = 'propio'; // Por defecto
      }

      // Obtener rendimientos del servicio
      final response = await TarjaService.obtenerRendimientos(
        widget.actividadId,
        idTipotrabajador: widget.idTipotrabajador ?? '1',
        idTiporendimiento: widget.idTiporendimiento ?? '',
        idContratista: widget.idContratista,
      );

      // Detección automática de grupal
      bool esGrupal = false;
      if (response.isNotEmpty) {
        final r = response.first;
        if (r is Map<String, dynamic> && r.containsKey('rendimiento_total') && r.containsKey('cantidad_trab')) {
          esGrupal = true;
        }
      }
      if (esGrupal) tipoActividad = 'grupal';

      setState(() {
        _tipoActividad = tipoActividad;
        _camposRendimiento = TarjaService.obtenerCamposRendimiento(tipoActividad);
      });

      // Adaptar para estructura {actividad, rendimientos}
      List<Map<String, dynamic>> rendimientosList = [];
      Map<String, dynamic>? actividadInfo;
      
      print('🔍 Debug _cargarRendimientos:');
      print('   - Response length: ${response.length}');
      if (response.isNotEmpty) {
        print('   - First response keys: ${response.first.keys.toList()}');
        print('   - First response: ${response.first}');
      }
      
      if (response.isNotEmpty && response.first.containsKey('actividad') && response.first.containsKey('rendimientos')) {
        actividadInfo = response.first['actividad'] as Map<String, dynamic>?;
        final rendimientosRaw = response.first['rendimientos'] as List<dynamic>?;
        if (rendimientosRaw != null) {
          rendimientosList = rendimientosRaw.map((e) => Map<String, dynamic>.from(e)).toList();
        }
        print('   - Estructura anidada detectada');
        print('   - Actividad info: $actividadInfo');
        print('   - Rendimientos list length: ${rendimientosList.length}');
      } else {
        rendimientosList = response;
        print('   - Estructura simple detectada');
        print('   - Rendimientos list length: ${rendimientosList.length}');
      }

      setState(() {
        _rendimientos = rendimientosList;
        _actividadInfo = actividadInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar rendimientos: $e';
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        onSubmitted: (_) => FocusScope.of(context).unfocus(),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o apellido',
          hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
          prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                    FocusScope.of(context).unfocus();
                  },
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filtrarRendimientos(List<Map<String, dynamic>> rendimientos) {
    if (_searchQuery.isEmpty) return rendimientos;
    return rendimientos.where((r) {
      final nombreColaborador = (r['nombre_colaborador'] ?? r['colaborador'] ?? r['nombre_trabajador'] ?? r['trabajador'] ?? '').toString().toLowerCase();
      final actividad = (r['labor'] ?? r['nombre_actividad'] ?? '').toString().toLowerCase();
      return nombreColaborador.contains(_searchQuery) || actividad.contains(_searchQuery);
    }).toList();
  }

  Widget _buildRendimientoCard(Map<String, dynamic> r) {
    final theme = Theme.of(context);
    final isGrupal = _tipoActividad == 'grupal';
    final colorBorde = theme.brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[200]!;
    final colorFondo = theme.colorScheme.surface;
    if (isGrupal) {
      final rendimientoTotal = r['rendimiento_total']?.toString() ?? 'N/A';
      final cantidadTrab = r['cantidad_trab']?.toString() ?? 'N/A';
      final porcentajeRaw = r['porcentaje_grupal'];
      String porcentajeStr = 'N/A';
      if (porcentajeRaw != null) {
        final valor = double.tryParse(porcentajeRaw.toString());
        if (valor != null) {
          porcentajeStr = (valor * 100).round().toString();
        }
      }
      final labor = r['labor']?.toString() ?? '';
      return Card(
        color: colorFondo,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: colorBorde, width: 1),
        ),
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Icon(Icons.add_chart, color: Colors.green, size: 36),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (labor.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.work, color: Colors.purple, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(labor, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.groups, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text('Cantidad trabajadores: ', style: TextStyle(color: Colors.black87)),
                        Text(cantidadTrab, style: TextStyle(color: Colors.black87)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.percent, color: Colors.blue, size: 16),
                        const SizedBox(width: 4),
                        Text('Porcentaje: ', style: TextStyle(color: Colors.black87)),
                        Text('${porcentajeStr != 'N/A' ? porcentajeStr + '%' : 'N/A'}', style: TextStyle(color: Colors.black87)),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.eco, color: Colors.green, size: 28),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Rendimiento total', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                      Text(rendimientoTotal, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
          // Obtener info de la actividad si existe
      final fecha = _actividadInfo?['fecha'] ?? r['fecha'] ?? 'N/A';
      
      // Obtener labor - ahora debería estar disponible directamente
      String labor = r['labor']?.toString() ?? '';
      
      final ceco = _actividadInfo?['ceco'] ?? r['ceco'] ?? '';
      
      // Debug logs para labor
      print('🔍 Debug labor en _buildRendimientoCard:');
      print('   - r labor: ${r['labor']}');
      print('   - Labor final: $labor');

    // Mapear campos según tipo
    String colaborador = '';
    String cantidad = '';
    String campo3 = '';
    String total = '';
    String unidad = r['unidad'] ?? '';

    switch (_tipoActividad) {
      case 'propio':
        colaborador = r['nombre_colaborador'] ?? r['colaborador'] ?? 'N/A';
        cantidad = r['rendimiento']?.toString() ?? r['horas_trabajadas']?.toString() ?? r['cantidad']?.toString() ?? '0';
        campo3 = ''; // No mostrar campo3
        total = ''; // No mostrar total
        break;
      case 'contratista':
        colaborador = r['nombre_trabajador'] ?? r['trabajador'] ?? 'N/A';
        cantidad = r['rendimiento']?.toString() ?? r['horas_trabajadas']?.toString() ?? r['cantidad']?.toString() ?? '0';
        campo3 = 'Porcentaje: ' + (r['porcentaje'] != null ? '${(r['porcentaje'] is num ? (r['porcentaje'] * 100).toStringAsFixed(0) : r['porcentaje'].toString())}%' : 'N/A');
        total = ''; // No mostrar total
        break;
      case 'grupal':
        double totalRend = 0;
        int cantidadTrab = 0;
        double porcentajeTotal = 0;
        if (_rendimientos.isNotEmpty) {
          for (var item in _rendimientos) {
            final valorRend = double.tryParse(item['rendimiento']?.toString() ?? '0') ?? 0;
            totalRend += valorRend;
            cantidadTrab++;
            final porc = item['porcentaje'] is num ? item['porcentaje'] : double.tryParse(item['porcentaje']?.toString() ?? '0') ?? 0;
            porcentajeTotal += porc;
          }
        }
        final actividadExtra = (r['nombre_actividad'] != null)
            ? r['nombre_actividad']
            : (labor.isNotEmpty ? labor : null);
        final porcentajeStr = (porcentajeTotal > 0 && cantidadTrab > 0)
            ? (porcentajeTotal / cantidadTrab * 100).toStringAsFixed(0)
            : 'N/A';
        return Card(
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[200]!, width: 1),
          ),
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Icon(Icons.person, color: Colors.green, size: 36),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (labor.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(labor, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calculate, color: Colors.purple, size: 20),
                          const SizedBox(width: 6),
                          Text('Rendimiento total: ', style: TextStyle(color: Colors.black87)),
                          Text(totalRend.toStringAsFixed(0), style: TextStyle(color: Colors.black87)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.groups, color: Colors.blue, size: 20),
                          const SizedBox(width: 6),
                          Text('Cantidad trabajadores: ', style: TextStyle(color: Colors.black87)),
                          Text(cantidadTrab.toString(), style: TextStyle(color: Colors.black87)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.percent, color: Colors.amber, size: 20),
                          const SizedBox(width: 6),
                          Text('Porcentaje: ', style: TextStyle(color: Colors.black87)),
                          Text('${porcentajeStr != 'N/A' ? porcentajeStr + '%' : 'N/A'}', style: TextStyle(color: Colors.black87)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      default:
        colaborador = r['colaborador'] ?? 'N/A';
        cantidad = r['cantidad']?.toString() ?? '0';
        campo3 = '';
        total = '';
    }

    if (_tipoActividad == 'propio' || _tipoActividad == 'contratista') {
      // Ícono grande a la izquierda
      final isContratista = _tipoActividad == 'contratista';
      final nombre = isContratista
          ? (r['nombre_trabajador'] ?? r['trabajador'] ?? 'N/A')
          : (r['nombre_colaborador'] ?? r['colaborador'] ?? 'N/A');
      final rendimientoValor = r['rendimiento']?.toString() ?? r['horas_trabajadas']?.toString() ?? r['cantidad']?.toString() ?? '0';
      final porcentaje = isContratista && r['porcentaje'] != null
          ? ((r['porcentaje'] is num ? (r['porcentaje'] * 100).toStringAsFixed(0) : r['porcentaje'].toString()) + '%')
          : null;
      // Obtener labor - ahora debería estar disponible directamente
      String labor = r['labor']?.toString() ?? '';
      
      // Debug logs para labor en individuales
      print('🔍 Debug labor en individuales:');
      print('   - r labor: ${r['labor']}');
      print('   - Labor final: $labor');
      return Card(
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[200]!, width: 1),
        ),
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Icon(Icons.add_chart, color: Colors.green, size: 36),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                      if (labor.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.work, color: Colors.purple, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(labor, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(nombre, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                        ),
                      ],
                    ),
                    if (porcentaje != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.percent, color: Colors.blue, size: 16),
                          const SizedBox(width: 4),
                          Text('Porcentaje: ', style: TextStyle(color: Colors.black87)),
                          Text(porcentaje, style: TextStyle(color: Colors.black87)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Bloque a la derecha: solo rendimiento
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.eco, color: Colors.green, size: 28),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Rendimiento', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                      Text(rendimientoValor, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[200]!, width: 1),
      ),
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Icon(Icons.person, color: Colors.green, size: 36),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fecha: $fecha',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.show_chart, color: Colors.green, size: 20),
                      const SizedBox(width: 6),
                      Text('Rendimiento: ', style: TextStyle(color: Colors.black87)),
                      Text(cantidad, style: TextStyle(color: Colors.black87)),
                    ],
                  ),
                  if (campo3.isNotEmpty)
                    _buildCampoEspecifico('Porcentaje', campo3.replaceFirst('Porcentaje: ', '')),
                  if (r['observaciones'] != null && r['observaciones'].toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Observaciones: ${r['observaciones']}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampoEspecifico(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
                color: isTotal ? AppTheme.primaryColor : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assessment_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay rendimientos registrados',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los rendimientos aparecerán aquí cuando se registren',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Error al cargar rendimientos',
            style: TextStyle(
              fontSize: 18,
              color: Colors.red[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Error desconocido',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _cargarRendimientos,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rendimientosFiltrados = _filtrarRendimientos(_rendimientos);
    
    // Obtener la labor para mostrar en el título
    String laborTitulo = '';
    if (_rendimientos.isNotEmpty) {
      final primerRendimiento = _rendimientos.first;
      laborTitulo = primerRendimiento['labor']?.toString() ?? '';
    }
    
    // Si no hay labor en los rendimientos, intentar obtenerla de la información de actividad
    if (laborTitulo.isEmpty && _actividadInfo != null) {
      laborTitulo = _actividadInfo!['labor']?.toString() ?? '';
    }
    
    // Si aún no hay labor, usar el ID de actividad como fallback
    final tituloActividad = laborTitulo.isNotEmpty ? laborTitulo : 'Actividad #${widget.actividadId}';
    
    return MainScaffold(
      title: '${_tipoActividad == 'grupal' ? 'Rendimiento Grupal' : _camposRendimiento['titulo'] ?? 'Rendimientos'} - $tituloActividad',
      body: RefreshIndicator(
        onRefresh: _cargarRendimientos,
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildErrorState()
                      : rendimientosFiltrados.isEmpty
                          ? _buildEmptyState()
                          : (_tipoActividad == 'grupal'
                              ? ListView.builder(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  itemCount: rendimientosFiltrados.length,
                                  itemBuilder: (context, index) {
                                    final r = rendimientosFiltrados[index];
                                    final rendimientoTotal = r['rendimiento_total']?.toString() ?? 'N/A';
                                    final cantidadTrab = r['cantidad_trab']?.toString() ?? 'N/A';
                                    final porcentajeRaw = r['porcentaje_grupal'];
                                    String porcentajeStr = 'N/A';
                                    if (porcentajeRaw != null) {
                                      final valor = double.tryParse(porcentajeRaw.toString());
                                      if (valor != null) {
                                        porcentajeStr = (valor * 100).round().toString();
                                      }
                                    }
                                    final labor = r['labor']?.toString() ?? '';
                                    return _buildRendimientoCard(r);
                                  },
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  itemCount: rendimientosFiltrados.length,
                                  itemBuilder: (context, index) {
                                    return _buildRendimientoCard(rendimientosFiltrados[index]);
                                  },
                                )
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
