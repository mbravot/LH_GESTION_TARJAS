import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/tarja.dart';
import '../providers/auth_provider.dart';
import '../providers/tarja_provider.dart';
import '../widgets/main_scaffold.dart';
import '../theme/app_theme.dart';
import '../services/tarja_service.dart';
import 'revision_tarjas_editar_screen.dart';

class RevisionTarjasScreen extends StatefulWidget {
  const RevisionTarjasScreen({super.key});

  @override
  State<RevisionTarjasScreen> createState() => _RevisionTarjasScreenState();
}

class _RevisionTarjasScreenState extends State<RevisionTarjasScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;
  List<bool> _expansionState = [];
  Key _expansionKey = UniqueKey();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Nuevo estado para manejar la expansión de rendimientos por tarja
  Map<String, bool> _rendimientosExpansionState = {};
  Map<String, List<Map<String, dynamic>>> _rendimientosCache = {};
  Map<String, bool> _rendimientosLoadingState = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);
    _cargarDatosIniciales();
  }

  void _cargarDatosIniciales() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final tarjaProvider = context.read<TarjaProvider>();
      
      // Configurar el TarjaProvider para escuchar cambios de sucursal
      tarjaProvider.setAuthProvider(authProvider);
    });
  }

  // Método para refrescar datos desde el AppBar
  Future<void> _refrescarDatos() async {
    final tarjaProvider = context.read<TarjaProvider>();
    await tarjaProvider.cargarTarjas();
    
    // Resetear el estado de expansión después de cargar los datos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tarjasFiltradas = _filtrarTarjas(tarjaProvider.tarjas);
      final gruposPorFecha = _agruparPorFecha(tarjasFiltradas);
      _resetExpansionState(gruposPorFecha.length);
    });
  }

  void _resetExpansionState(int groupCount) {
    setState(() {
      _expansionState = List.generate(groupCount, (_) => true);
      _expansionKey = UniqueKey();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    setState(() {
      _selectedTab = _tabController.index;
      final tarjaProvider = context.read<TarjaProvider>();
      final tarjasFiltradas = _filtrarTarjas(tarjaProvider.tarjas);
      final gruposPorFecha = _agruparPorFecha(tarjasFiltradas);
      _resetExpansionState(gruposPorFecha.length);
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  List<Tarja> _filtrarTarjas(List<Tarja> tarjas) {
    // Primero filtrar por tab
    List<Tarja> tarjasFiltradasPorTab;
    switch (_selectedTab) {
      case 1: // Creadas
        tarjasFiltradasPorTab = tarjas.where((t) => t.idEstadoactividad == '1').toList();
        break;
      case 2: // Revisadas
        tarjasFiltradasPorTab = tarjas.where((t) => t.idEstadoactividad == '2').toList();
        break;
      case 3: // Propio
        tarjasFiltradasPorTab = tarjas.where((t) => 
          t.idTipotrabajador == '1' && (t.idEstadoactividad == '1' || t.idEstadoactividad == '2')
        ).toList();
        break;
      case 4: // Contratista
        tarjasFiltradasPorTab = tarjas.where((t) => 
          t.idTipotrabajador == '2' && (t.idEstadoactividad == '1' || t.idEstadoactividad == '2')
        ).toList();
        break;
      default: // Todas (solo estado 1 y 2)
        tarjasFiltradasPorTab = tarjas.where((t) => 
          t.idEstadoactividad == '1' || t.idEstadoactividad == '2'
        ).toList();
    }

    // Luego filtrar por búsqueda si hay query
    if (_searchQuery.isEmpty) {
      return tarjasFiltradasPorTab;
      }
      
    return tarjasFiltradasPorTab.where((tarja) {
      return tarja.actividad.toLowerCase().contains(_searchQuery) ||
             tarja.trabajador.toLowerCase().contains(_searchQuery) ||
             tarja.lugar.toLowerCase().contains(_searchQuery) ||
             tarja.tipo.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  Map<String, List<Tarja>> _agruparPorFecha(List<Tarja> tarjas) {
    final grupos = <String, List<Tarja>>{};
    for (var tarja in tarjas) {
      final fecha = tarja.fecha;
      if (!grupos.containsKey(fecha)) {
        grupos[fecha] = [];
      }
      grupos[fecha]!.add(tarja);
    }
    return grupos;
  }

  String _formatearFecha(String fecha) {
    try {
      final date = DateTime.parse(fecha);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return fecha;
    }
  }

  String _getTipoPersonalText(Tarja tarja) {
    // Si no hay id_contratista, es personal propio
    if (tarja.idContratista == null || tarja.idContratista!.isEmpty) {
      return 'PROPIO';
    } else {
      return 'Contratista';
    }
  }

  String _formatearTarifa(String tarifa) {
    try {
      final double valor = double.parse(tarifa);
      return valor.toInt().toString();
    } catch (e) {
      return '0';
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

  String obtenerNombreCeco(Tarja tarja) {
    // Si tenemos el nombre del CECO directamente del endpoint, lo usamos
    if (tarja.nombreCeco != null && tarja.nombreCeco!.isNotEmpty) {
      return tarja.nombreCeco!;
    }
    
    // Fallback: si no hay nombre específico, mostramos el tipo
    if (tarja.nombreTipoceco != null && tarja.nombreTipoceco!.isNotEmpty) {
      return tarja.nombreTipoceco!;
    } else if (tarja.idTipoceco.isNotEmpty) {
      return 'Tipo CECO ID: ${tarja.idTipoceco}';
    }
    
    return 'Sin CECO';
  }

  String obtenerNombreUnidad(Tarja tarja) {
    // Debug logging
    print('DEBUG - obtenerNombreUnidad:');
    print('  nombreUnidad: ${tarja.nombreUnidad}');
    print('  idUnidad: ${tarja.idUnidad}');
    print('  nombreUsuario: ${tarja.nombreUsuario}');
    
    if (tarja.nombreUnidad != null && tarja.nombreUnidad!.isNotEmpty) {
      print('  Retornando nombre: ${tarja.nombreUnidad}');
      return tarja.nombreUnidad!;
    } else if (tarja.idUnidad.isNotEmpty) {
      print('  Retornando ID: ${tarja.idUnidad}');
      return 'ID: ${tarja.idUnidad}';
    } else {
      print('  Retornando: Sin unidad');
      return 'Sin unidad';
    }
  }

  // Método para cargar rendimientos de una actividad específica
  Future<void> _cargarRendimientos(Tarja tarja) async {
    final tarjaId = tarja.id;
    
    // Si ya están cargados, no hacer nada
    if (_rendimientosCache.containsKey(tarjaId)) {
      return;
    }

    setState(() {
      _rendimientosLoadingState[tarjaId] = true;
    });

    try {
      final response = await TarjaService.obtenerRendimientos(
        tarjaId,
        idTipotrabajador: tarja.idTipotrabajador,
        idTiporendimiento: tarja.idTiporendimiento,
        idContratista: tarja.idContratista,
      );

      List<Map<String, dynamic>> rendimientosList = [];
      Map<String, dynamic>? actividadInfo;
      
      if (response.isNotEmpty && response.first.containsKey('actividad') && response.first.containsKey('rendimientos')) {
        actividadInfo = response.first['actividad'] as Map<String, dynamic>?;
        final rendimientosRaw = response.first['rendimientos'] as List<dynamic>?;
        if (rendimientosRaw != null) {
          rendimientosList = rendimientosRaw.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      } else {
        rendimientosList = response;
      }

      setState(() {
        _rendimientosCache[tarjaId] = rendimientosList;
        _rendimientosLoadingState[tarjaId] = false;
      });
    } catch (e) {
      setState(() {
        _rendimientosCache[tarjaId] = [];
        _rendimientosLoadingState[tarjaId] = false;
      });
      print('Error al cargar rendimientos: $e');
    }
  }

  // Método para alternar la expansión de rendimientos
  void _toggleRendimientosExpansion(Tarja tarja) {
    final tarjaId = tarja.id;
    setState(() {
      _rendimientosExpansionState[tarjaId] = !(_rendimientosExpansionState[tarjaId] ?? false);
    });
    
    // Si se está expandiendo y no hay rendimientos cargados, cargarlos
    if (_rendimientosExpansionState[tarjaId] == true && !_rendimientosCache.containsKey(tarjaId)) {
      _cargarRendimientos(tarja);
    }
  }

  Widget _buildActividadCard(Tarja tarja) {
    final estadoData = _getEstadoActividad(tarja.idEstadoactividad);
    final String estadoNombre = estadoData['nombre'];
    final Color estadoColor = estadoData['color'];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.colorScheme.surface;
    final borderColor = isDark ? Colors.grey[800]! : Colors.green[400]!;
    final textColor = theme.colorScheme.onSurface;
    final tarjaId = tarja.id;
    final isRendimientosExpanded = _rendimientosExpansionState[tarjaId] ?? false;
    final rendimientos = _rendimientosCache[tarjaId] ?? [];
    final isLoadingRendimientos = _rendimientosLoadingState[tarjaId] ?? false;

    return Card(
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: isDark ? Colors.grey[600]! : Colors.green[400]!, width: 1.5),
        ),
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        children: [
          // Contenido principal de la card
          InkWell(
            onTap: () => _toggleRendimientosExpansion(tarja),
            borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.work, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tarja.actividad,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                  ),
                      // Mostrar el estado actual como texto informativo
                      Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: tarja.idEstadoactividad == '1' ? Colors.orange : 
                                 tarja.idEstadoactividad == '2' ? Colors.green : 
                                 estadoColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: estadoColor, width: 1),
                      ),
                      child: Text(
                        estadoNombre,
                          style: TextStyle(
                            color: tarja.idEstadoactividad == '1' ? Colors.white : 
                                   tarja.idEstadoactividad == '2' ? Colors.white : 
                                   estadoColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.straighten, color: Colors.teal, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Unidad: ${obtenerNombreUnidad(tarja)}',
                    style: TextStyle(color: textColor.withOpacity(0.7)),
                  ),
                      const Spacer(),
                      // Indicador de rendimientos al lado de la unidad
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: tarja.tieneRendimiento ? Colors.green[100] : Colors.red[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              tarja.tieneRendimiento ? Icons.check_circle : Icons.cancel,
                              size: 14,
                              color: tarja.tieneRendimiento ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              tarja.tieneRendimiento ? 'Con rendimientos' : 'Sin rendimientos',
                              style: TextStyle(
                                color: tarja.tieneRendimiento ? Colors.green[800] : Colors.red[800],
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Usuario: ${tarja.nombreUsuario ?? 'No especificado'}',
                    style: TextStyle(color: textColor.withOpacity(0.7)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.category, color: Colors.purple, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Tipo CECO: ${tarja.nombreTipoceco ?? 'ID: ${tarja.idTipoceco}'}',
                    style: TextStyle(color: textColor.withOpacity(0.7)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.folder, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'CECO: ${obtenerNombreCeco(tarja)}',
                      style: TextStyle(color: textColor.withOpacity(0.7)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.business, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Personal:${tarja.trabajador} ${_getTipoPersonalText(tarja)}',
                      style: TextStyle(color: textColor.withOpacity(0.7)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                  Icon(Icons.assessment, color: Colors.purple, size: 20),
                  const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                      'Tipo Rendimiento: ${tarja.tipo}',
                      style: TextStyle(color: textColor.withOpacity(0.7)),
                                  ),
                                ),
                      // Botón "Editar" - siempre azul, independiente de si tiene rendimientos
                                    GestureDetector(
                    onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RevisionTarjasEditarScreen(tarja: tarja),
                            ),
                          ).then((_) {
                            // Refrescar datos cuando regrese de la pantalla de edición
                            final tarjaProvider = context.read<TarjaProvider>();
                            tarjaProvider.cargarTarjas();
                          });
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                              color: Colors.blue,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                  Icons.edit,
                                            size: 16,
                                  color: Colors.white,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                  'Editar',
                                            style: TextStyle(
                                    color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.attach_money, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Tarifa: \$${_formatearTarifa(tarja.tarifa)}',
                    style: TextStyle(
                      color: textColor.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.schedule, color: Colors.indigo, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                                      child: Text(
                      'Horario: ${tarja.horaInicio} - ${tarja.horaFin}',
                      style: TextStyle(color: textColor.withOpacity(0.7)),
                                      ),
                                    ),
                      // Indicador de expansión
                      Icon(
                        isRendimientosExpanded ? Icons.expand_less : Icons.expand_more,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                                  ],
                                ),
                              ],
                            ),
        ),
      ),
          // Sección expandible de rendimientos
          if (isRendimientosExpanded)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.assessment, color: AppTheme.primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Rendimientos',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (isLoadingRendimientos)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (rendimientos.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.assessment_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No hay rendimientos registrados',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                       Column(
                         children: [
                           // Determinar el tipo de actividad de manera más robusta
                           Builder(
                             builder: (context) {
                               String tipoActividad;
                               if (tarja.idContratista != null && tarja.idContratista!.isNotEmpty) {
                                 tipoActividad = 'contratista';
                               } else if (tarja.idTiporendimiento == '2') {
                                 tipoActividad = 'grupal';
                               } else if (tarja.idTipotrabajador == '1') {
                                 tipoActividad = 'propio';
                               } else if (tarja.idTipotrabajador == '2') {
                                 tipoActividad = 'contratista';
                               } else {
                                 tipoActividad = 'propio'; // Por defecto
                               }
                               
                               // Detección automática de grupal basada en los datos
                               if (rendimientos.isNotEmpty) {
                                 final primerRendimiento = rendimientos.first;
                                 if (primerRendimiento.containsKey('rendimiento_total') && primerRendimiento.containsKey('cantidad_trab')) {
                                   tipoActividad = 'grupal';
                                 }
                               }
                               
                               // Para todos los tipos, mostrar rendimientos individuales
                               return Column(
                                 children: rendimientos.asMap().entries.map((entry) {
                                   final index = entry.key;
                                   final rendimiento = entry.value;
                                   return Column(
                                     children: [
                                       _buildRendimientoCardCompleto(rendimiento, tarja),
                                       if (index < rendimientos.length - 1) 
                                         const SizedBox(height: 12),
                                     ],
                                   );
                                 }).toList(),
                               );
                             },
                           ),
                         ],
                       ),
                    // Resumen del total de rendimientos de la actividad
                    if (rendimientos.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.calculate, color: AppTheme.primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Total Rendimiento de la Actividad:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _calcularTotalRendimientos(rendimientos, tarja),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.attach_money, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Total Pago de la Actividad:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.green[700],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green[600],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '\$${_calcularTotalPago(rendimientos, tarja)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Botón de cambio de estado - solo mostrar si hay rendimientos
                    if (rendimientos.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.verified, color: AppTheme.primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Estado actual: $estadoNombre',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () async {
                              // Lógica para cambiar estado entre CREADA y REVISADA
                              final nuevoEstado = tarja.idEstadoactividad == '1' ? '2' : '1';
                              final nuevoNombre = _getEstadoActividad(nuevoEstado)['nombre'];
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Confirmar cambio de estado'),
                                  content: Text('¿Deseas cambiar el estado a "$nuevoNombre"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: const Text('Cancelar'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: const Text('Confirmar'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                try {
                                  await TarjaService().cambiarEstadoActividad(
                                    tarja.id, nuevoEstado,
                                  );
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Estado actualizado a "$nuevoNombre"'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    // Refrescar la lista usando el provider
                                    final tarjaProvider = context.read<TarjaProvider>();
                                    await tarjaProvider.cargarTarjas();
                                    
                                    // Resetear el estado de expansión después de cargar los datos
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      final tarjasFiltradas = _filtrarTarjas(tarjaProvider.tarjas);
                                      final gruposPorFecha = _agruparPorFecha(tarjasFiltradas);
                                      _resetExpansionState(gruposPorFecha.length);
                                    });
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error al actualizar: $e')),
                                    );
                                  }
                                }
                              }
                            },
                            icon: Icon(
                              tarja.idEstadoactividad == '1' ? Icons.check_circle : Icons.undo,
                              size: 18,
                            ),
                            label: Text(
                              tarja.idEstadoactividad == '1' ? 'Marcar como Revisada' : 'Marcar como Creada',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: tarja.idEstadoactividad == '1' ? Colors.green : Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Widget para mostrar un item de rendimiento
  Widget _buildRendimientoItem(Map<String, dynamic> rendimiento) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.colorScheme.surface;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: borderColor, width: 1),
      ),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.person, color: Colors.green, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rendimiento['nombre_colaborador']?.toString() ?? 
                    rendimiento['nombre_trabajador']?.toString() ?? 
                    rendimiento['colaborador']?.toString() ?? 
                    rendimiento['trabajador']?.toString() ?? 
                    'Sin nombre',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rendimiento: ${rendimiento['rendimiento']?.toString() ?? rendimiento['cantidad']?.toString() ?? '0'}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (rendimiento['porcentaje'] != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(rendimiento['porcentaje'] is num ? (rendimiento['porcentaje'] * 100).toStringAsFixed(0) : rendimiento['porcentaje'].toString())}%',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Widget para mostrar rendimientos con la misma lógica que RendimientosPageScreen
  Widget _buildRendimientoCardCompleto(Map<String, dynamic> r, Tarja tarja) {
    // Determinar el tipo de actividad
    String tipoActividad;
    if (tarja.idContratista != null && tarja.idContratista!.isNotEmpty) {
      tipoActividad = 'contratista';
    } else if (tarja.idTiporendimiento == '2') {
      tipoActividad = 'grupal';
    } else if (tarja.idTipotrabajador == '1') {
      tipoActividad = 'propio';
    } else if (tarja.idTipotrabajador == '2') {
      tipoActividad = 'contratista';
    } else {
      tipoActividad = 'propio'; // Por defecto
    }
    
    // Detección automática de grupal basada en los datos del rendimiento
    if (r.containsKey('rendimiento_total') && r.containsKey('cantidad_trab')) {
      tipoActividad = 'grupal';
    }

    final theme = Theme.of(context);
    final isGrupal = tipoActividad == 'grupal';
    final colorBorde = theme.brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[200]!;
    final colorFondo = theme.colorScheme.surface;

    if (isGrupal) {
      // Debug: ver qué datos están llegando
      print('🔍 Debug rendimiento grupal:');
      print('   - Datos completos: $r');
      print('   - Keys disponibles: ${r.keys.toList()}');
      
      // Para grupal, usar los datos del grupo completo
      final rendimientoTotal = r['rendimiento_total']?.toString() ?? r['rendimiento']?.toString() ?? '0';
      final cantidadTrab = r['cantidad_trab']?.toString() ?? '1';
      final porcentajeRaw = r['porcentaje_grupal'] ?? r['porcentaje'];
      String porcentajeStr = 'N/A';
      if (porcentajeRaw != null) {
        final valor = double.tryParse(porcentajeRaw.toString());
        if (valor != null) {
          porcentajeStr = (valor * 100).round().toString();
        }
      }
      final labor = r['labor']?.toString() ?? '';
      
      print('   - Rendimiento total: $rendimientoTotal');
      print('   - Cantidad trabajadores: $cantidadTrab');
      print('   - Porcentaje: $porcentajeStr');
      print('   - Labor: $labor');
      
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
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                          Text(tarja.nombreUnidad ?? 'Unidad', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Total estimado por trabajador
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person, color: Colors.orange, size: 20),
                      const SizedBox(width: 4),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Pago estimado por trabajador', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 12)),
                          Text(
                            '\$${_calcularTotalEstimadoPorTrabajador(rendimientoTotal, cantidadTrab, tarja.tarifa)}',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange[700]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Para tipo propio y contratista
    if (tipoActividad == 'propio' || tipoActividad == 'contratista') {
      final isContratista = tipoActividad == 'contratista';
      final nombre = isContratista
          ? (r['nombre_trabajador'] ?? r['trabajador'] ?? 'N/A')
          : (r['nombre_colaborador'] ?? r['colaborador'] ?? 'N/A');
      final rendimientoValor = r['rendimiento']?.toString() ?? r['horas_trabajadas']?.toString() ?? r['cantidad']?.toString() ?? '0';
      final porcentaje = isContratista && r['porcentaje'] != null
          ? ((r['porcentaje'] is num ? (r['porcentaje'] * 100).toStringAsFixed(0) : r['porcentaje'].toString()) + '%')
          : null;
      String labor = r['labor']?.toString() ?? '';
      
      return Card(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: theme.brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[200]!, width: 1),
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
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                          Text(tarja.nombreUnidad ?? 'Unidad', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Pago a trabajador
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person, color: Colors.orange, size: 20),
                      const SizedBox(width: 4),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Pago a trabajador', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 12)),
                          Text(
                            '\$${_calcularPagoTrabajador(rendimientoValor, tarja.tarifa)}',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange[700]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Caso por defecto
    return Card(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: theme.brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[200]!, width: 1),
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
                    'Rendimiento: ${r['rendimiento']?.toString() ?? r['cantidad']?.toString() ?? '0'}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    tarja.nombreUnidad ?? 'Unidad',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Pago a trabajador para caso por defecto
                  Row(
                    children: [
                      Icon(Icons.attach_money, color: Colors.orange, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Pago a trabajador: ',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '\$${_calcularPagoTrabajador(r['rendimiento']?.toString() ?? r['cantidad']?.toString() ?? '0', tarja.tarifa)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (r['observaciones'] != null && r['observaciones'].toString().isNotEmpty) ...[
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

  // Widget para mostrar resumen grupal
  Widget _buildResumenGrupal(List<Map<String, dynamic>> rendimientos, Tarja tarja) {
    final theme = Theme.of(context);
    final colorBorde = theme.brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[200]!;
    final colorFondo = theme.colorScheme.surface;

    // Para grupal, usar los datos del primer rendimiento que contiene la info del grupo
    if (rendimientos.isNotEmpty) {
      final r = rendimientos.first;
      final rendimientoTotal = r['rendimiento_total']?.toString() ?? '0';
      final cantidadTrab = r['cantidad_trab']?.toString() ?? '0';
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
                      Text(tarja.nombreUnidad ?? 'Unidad', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    
    // Fallback si no hay rendimientos
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
        child: Center(
          child: Text(
            'No hay datos del grupo disponibles',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      ),
    );
  }

  // Método para calcular el total de rendimientos de una actividad
  String _calcularTotalRendimientos(List<Map<String, dynamic>> rendimientos, Tarja tarja) {
    double totalRendimiento = 0;
    
    // Determinar el tipo de actividad - priorizar idTiporendimiento para detectar grupal
    String tipoActividad;
    if (tarja.idTiporendimiento == '2') {
      tipoActividad = 'grupal';
    } else if (tarja.idContratista != null && tarja.idContratista!.isNotEmpty) {
      tipoActividad = 'contratista';
    } else if (tarja.idTipotrabajador == '1') {
      tipoActividad = 'propio';
    } else if (tarja.idTipotrabajador == '2') {
      tipoActividad = 'contratista';
    } else {
      tipoActividad = 'propio'; // Por defecto
    }
    
    print('🔍 Debug _calcularTotalRendimientos:');
    print('   - Tipo actividad: $tipoActividad');
    print('   - idTiporendimiento: ${tarja.idTiporendimiento}');
    print('   - idTipotrabajador: ${tarja.idTipotrabajador}');
    print('   - idContratista: ${tarja.idContratista}');
    print('   - Cantidad rendimientos: ${rendimientos.length}');
    
    for (var rendimiento in rendimientos) {
      double valorRendimiento = 0;
      
      if (tipoActividad == 'grupal') {
        // Para rendimientos grupales, usar rendimiento_total
        // El valor puede venir como num o string
        var rendimientoTotal = rendimiento['rendimiento_total'];
        if (rendimientoTotal is num) {
          valorRendimiento = rendimientoTotal.toDouble();
        } else {
          final rendimientoTotalStr = rendimientoTotal?.toString() ?? rendimiento['rendimiento']?.toString() ?? '0';
          valorRendimiento = double.tryParse(rendimientoTotalStr) ?? 0;
        }
        print('   - Rendimiento grupal raw: $rendimientoTotal -> $valorRendimiento');
      } else {
        // Para rendimientos individuales, usar rendimiento o cantidad
        final rendimientoValor = rendimiento['rendimiento']?.toString() ?? rendimiento['cantidad']?.toString() ?? '0';
        valorRendimiento = double.tryParse(rendimientoValor) ?? 0;
        print('   - Rendimiento individual: $rendimientoValor -> $valorRendimiento');
      }
      
      totalRendimiento += valorRendimiento;
    }
    
    print('   - Total final: $totalRendimiento');
    return totalRendimiento.toStringAsFixed(2);
  }

  // Método para calcular el total de pago de una actividad
  String _calcularTotalPago(List<Map<String, dynamic>> rendimientos, Tarja tarja) {
    // Obtener el total de rendimientos
    final totalRendimientoStr = _calcularTotalRendimientos(rendimientos, tarja);
    final totalRendimiento = double.tryParse(totalRendimientoStr) ?? 0;
    
    // Obtener la tarifa de la actividad
    final tarifa = double.tryParse(tarja.tarifa) ?? 0;
    
    // Calcular el total de pago: tarifa * rendimiento total
    final totalPago = tarifa * totalRendimiento;
    
    print('💰 Debug _calcularTotalPago:');
    print('   - Total rendimiento: $totalRendimiento');
    print('   - Tarifa: $tarifa');
    print('   - Total pago: $totalPago');
    
    // Formatear como número entero con separación de miles
    final totalPagoEntero = totalPago.round();
    return _formatearNumeroConSeparadores(totalPagoEntero);
  }

  // Método para formatear números con separadores de miles
  String _formatearNumeroConSeparadores(int numero) {
    return numero.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]},'
    );
  }

  // Método para calcular el pago a trabajador individual
  String _calcularPagoTrabajador(String rendimientoValor, String tarifa) {
    // Convertir el rendimiento a double
    final rendimiento = double.tryParse(rendimientoValor) ?? 0;
    
    // Convertir la tarifa a double
    final tarifaDouble = double.tryParse(tarifa) ?? 0;
    
    // Calcular el pago: tarifa * rendimiento
    final pago = tarifaDouble * rendimiento;
    
    print('💰 Debug _calcularPagoTrabajador:');
    print('   - Rendimiento: $rendimiento');
    print('   - Tarifa: $tarifaDouble');
    print('   - Pago: $pago');
    
    // Formatear como número entero con separación de miles
    final pagoEntero = pago.round();
    return _formatearNumeroConSeparadores(pagoEntero);
  }

  // Método para calcular el total estimado por trabajador en rendimientos grupales
  String _calcularTotalEstimadoPorTrabajador(String rendimientoTotal, String cantidadTrab, String tarifa) {
    // Convertir valores a double
    final rendimiento = double.tryParse(rendimientoTotal) ?? 0;
    final cantidad = double.tryParse(cantidadTrab) ?? 1;
    final tarifaDouble = double.tryParse(tarifa) ?? 0;
    
    // Calcular: (rendimiento_total ÷ cantidad_trabajadores) × tarifa
    final rendimientoPorTrabajador = rendimiento / cantidad;
    final totalEstimado = rendimientoPorTrabajador * tarifaDouble;
    
    print('👥 Debug _calcularTotalEstimadoPorTrabajador:');
    print('   - Rendimiento total: $rendimiento');
    print('   - Cantidad trabajadores: $cantidad');
    print('   - Rendimiento por trabajador: $rendimientoPorTrabajador');
    print('   - Tarifa: $tarifaDouble');
    print('   - Total estimado por trabajador: $totalEstimado');
    
    // Formatear como número entero con separación de miles
    final totalEntero = totalEstimado.round();
    return _formatearNumeroConSeparadores(totalEntero);
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
          hintText: 'Buscar por labor, contratista, CECO o tipo de rendimiento',
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

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Revisión de Tarjas',
      onRefresh: _refrescarDatos,
      bottom: _TabBarWithCounters(tabController: _tabController),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: Consumer<TarjaProvider>(
              builder: (context, tarjaProvider, child) {
                final tarjasFiltradas = _filtrarTarjas(tarjaProvider.tarjas);
                final gruposPorFecha = _agruparPorFecha(tarjasFiltradas);
                final fechasOrdenadas = gruposPorFecha.keys.toList()..sort((a, b) => b.compareTo(a));

                // Solo reiniciar expansión si cambió la cantidad de grupos
                if (_expansionState.length != fechasOrdenadas.length) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _resetExpansionState(fechasOrdenadas.length);
                  });
                }

                if (tarjaProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (tarjaProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tarjaProvider.error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => tarjaProvider.cargarTarjas(),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }
                if (tarjasFiltradas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                        Icon(
                          _searchQuery.isNotEmpty ? Icons.search_off : Icons.filter_list,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty 
                            ? 'No se encontraron actividades que coincidan con "$_searchQuery"'
                            : 'No hay actividades que coincidan con los filtros',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty
                            ? 'Intenta con otros términos de búsqueda'
                            : 'Intenta cambiar los filtros o refrescar los datos',
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

                return ListView(
                  key: _expansionKey,
                  padding: const EdgeInsets.all(16.0),
                  children: List.generate(fechasOrdenadas.length, (i) {
                    final fecha = fechasOrdenadas[i];
                    final tarjas = gruposPorFecha[fecha]!;
                    final expanded = (_expansionState.length > i) ? _expansionState[i] : true;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                          splashColor: AppTheme.primaryLightColor.withOpacity(0.1),
                          highlightColor: AppTheme.primaryLightColor.withOpacity(0.05),
                          colorScheme: Theme.of(context).colorScheme.copyWith(
                            primary: AppTheme.primaryColor,
                            secondary: AppTheme.primaryLightColor,
                          ),
                        ),
                        child: ExpansionTile(
                          key: ValueKey('expansion_$i'),
                          initiallyExpanded: expanded,
                          onExpansionChanged: (isExpanded) {
                            print('DEBUG - ExpansionTile $i changed to: $isExpanded');
                            if (_expansionState.length > i) {
                              setState(() {
                                _expansionState[i] = isExpanded;
                              });
                            }
                          },
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          backgroundColor: Colors.white,
                          collapsedBackgroundColor: AppTheme.primaryColor.withOpacity(0.07),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _formatearFecha(fecha),
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${tarjas.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'actividades',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          children: tarjas.map((tarja) => _buildActividadCard(tarja)).toList(),
                        ),
                      ),
              );
                  }),
          );
        },
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBarWithCounters extends StatelessWidget implements PreferredSizeWidget {
  final TabController tabController;

  const _TabBarWithCounters({required this.tabController});

  @override
  Size get preferredSize => const Size.fromHeight(48.0);

  // Métodos para calcular contadores de cada tab
  int _getContadorTodas(List<Tarja> tarjas) {
    return tarjas.where((t) => 
      t.idEstadoactividad == '1' || t.idEstadoactividad == '2'
    ).length;
  }

  int _getContadorCreadas(List<Tarja> tarjas) {
    return tarjas.where((t) => t.idEstadoactividad == '1').length;
  }

  int _getContadorRevisadas(List<Tarja> tarjas) {
    return tarjas.where((t) => t.idEstadoactividad == '2').length;
  }

  int _getContadorPropio(List<Tarja> tarjas) {
    return tarjas.where((t) => 
      t.idTipotrabajador == '1' && (t.idEstadoactividad == '1' || t.idEstadoactividad == '2')
    ).length;
  }

  int _getContadorContratista(List<Tarja> tarjas) {
    return tarjas.where((t) => 
      t.idTipotrabajador == '2' && (t.idEstadoactividad == '1' || t.idEstadoactividad == '2')
    ).length;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TarjaProvider>(
      builder: (context, tarjaProvider, child) {
        return TabBar(
          controller: tabController,
          isScrollable: true,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.accentColor,
          unselectedLabelColor: Colors.white,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Todas'),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_getContadorTodas(tarjaProvider.tarjas)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Creadas'),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_getContadorCreadas(tarjaProvider.tarjas)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Revisadas'),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_getContadorRevisadas(tarjaProvider.tarjas)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Propio'),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_getContadorPropio(tarjaProvider.tarjas)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Contratista'),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_getContadorContratista(tarjaProvider.tarjas)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
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
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor ?? Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
} 