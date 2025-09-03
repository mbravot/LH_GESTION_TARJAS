import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/tarja.dart';
import '../providers/auth_provider.dart';
import '../providers/tarja_provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'aprobacion_tarjas_editar_screen.dart';

class AprobacionTarjasScreen extends StatefulWidget {
  const AprobacionTarjasScreen({super.key});

  @override
  State<AprobacionTarjasScreen> createState() => _AprobacionTarjasScreenState();
}

class _AprobacionTarjasScreenState extends State<AprobacionTarjasScreen> {
  String? _filtroActivo;
  List<bool> _expansionState = [];
  Key _expansionKey = UniqueKey();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showFiltros = false;
  
  // Nuevo estado para manejar la expansión de rendimientos por tarja
  Map<String, bool> _rendimientosExpansionState = {};
  Map<String, List<Map<String, dynamic>>> _rendimientosCache = {};
  Map<String, bool> _rendimientosLoadingState = {};

  // Helper para obtener colores adaptativos al tema
  Color _getAdaptiveColor(BuildContext context, {Color? lightColor, Color? darkColor}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (isDark) {
      return darkColor ?? theme.colorScheme.onSurface.withOpacity(0.7);
    } else {
      return lightColor ?? theme.colorScheme.onSurface;
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

  @override
  void initState() {
    super.initState();
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
    _searchController.dispose();
    super.dispose();
  }

  void _aplicarFiltro(String? filtro) {
    setState(() {
      _filtroActivo = filtro;
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
    // Usar las tarjas filtradas del provider si hay filtros avanzados aplicados
    final tarjaProvider = context.read<TarjaProvider>();
    List<Tarja> tarjasBase = tarjaProvider.filtroContratista.isNotEmpty || 
                             tarjaProvider.filtroTipoRendimiento.isNotEmpty ||
                             tarjaProvider.filtroUsuario.isNotEmpty
        ? tarjaProvider.tarjasFiltradas
        : tarjas;
    
    // Primero filtrar por filtro activo
    List<Tarja> tarjasFiltradasPorTab;
    switch (_filtroActivo) {
      case 'revisadas':
        tarjasFiltradasPorTab = tarjasBase.where((t) => t.idEstadoactividad == '2').toList();
        break;
      case 'aprobadas':
        tarjasFiltradasPorTab = tarjasBase.where((t) => t.idEstadoactividad == '3').toList();
        break;
      case 'propio':
        tarjasFiltradasPorTab = tarjasBase.where((t) => 
          t.idTipotrabajador == '1' && (t.idEstadoactividad == '2' || t.idEstadoactividad == '3')
        ).toList();
        break;
      case 'contratista':
        tarjasFiltradasPorTab = tarjasBase.where((t) => 
          t.idTipotrabajador == '2' && (t.idEstadoactividad == '2' || t.idEstadoactividad == '3')
        ).toList();
        break;
      default: // Todas (solo estado 2 y 3)
        tarjasFiltradasPorTab = tarjasBase.where((t) => 
          t.idEstadoactividad == '2' || t.idEstadoactividad == '3'
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
        return {"nombre": "REVISADA", "color": Colors.orange};
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
    if (tarja.nombreUnidad != null && tarja.nombreUnidad!.isNotEmpty) {
      return tarja.nombreUnidad!;
    } else if (tarja.idUnidad.isNotEmpty) {
      return 'ID: ${tarja.idUnidad}';
    } else {
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
      final response = await ApiService.obtenerRendimientos(
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
    // Cambiar el color del borde según si tiene rendimientos o no
    final borderColor = tarja.tieneRendimiento 
        ? (isDark ? Colors.green[600]! : Colors.green[400]!)
        : (isDark ? Colors.red[600]! : Colors.red[400]!);
    final textColor = theme.colorScheme.onSurface;
    final tarjaId = tarja.id;
    final isRendimientosExpanded = _rendimientosExpansionState[tarjaId] ?? false;
    final rendimientos = _rendimientosCache[tarjaId] ?? [];
    final isLoadingRendimientos = _rendimientosLoadingState[tarjaId] ?? false;

    // Cargar rendimientos automáticamente si tiene rendimientos y no están cargados
    if (tarja.tieneRendimiento && !_rendimientosCache.containsKey(tarjaId) && !isLoadingRendimientos) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _cargarRendimientos(tarja);
      });
    }

    return Card(
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: borderColor, width: 1.5),
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
                      const SizedBox(width: 8),
                      // Mostrar el estado actual como texto informativo
                      Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: tarja.idEstadoactividad == '1' ? Colors.orange : 
                                 tarja.idEstadoactividad == '2' ? Colors.orange : 
                                 tarja.idEstadoactividad == '3' ? Colors.green : 
                                 estadoColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: estadoColor, width: 1),
                      ),
                      child: Text(
                        estadoNombre,
                          style: TextStyle(
                            color: tarja.idEstadoactividad == '1' ? Colors.white : 
                                   tarja.idEstadoactividad == '2' ? Colors.white : 
                                   tarja.idEstadoactividad == '3' ? Colors.white : 
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
                           border: Border.all(
                             color: tarja.tieneRendimiento ? Colors.green[400]! : Colors.red[400]!,
                             width: 1,
                           ),
                         ),
                         child: Row(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             Icon(
                               tarja.tieneRendimiento ? Icons.check_circle : Icons.cancel,
                               size: 14,
                               color: tarja.tieneRendimiento ? Colors.green[700] : Colors.red[700],
                             ),
                             const SizedBox(width: 4),
                             Text(
                               tarja.tieneRendimiento 
                                   ? (isLoadingRendimientos 
                                       ? 'Con rendimientos (cargando...)' 
                                       : 'Con rendimientos (${rendimientos.length})')
                                   : 'Sin rendimientos',
                               style: TextStyle(
                                 color: tarja.tieneRendimiento ? Colors.green[700] : Colors.red[700],
                                 fontSize: 11,
                                 fontWeight: FontWeight.w500,
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
                    'Usuario: ${_getNombreCompletoUsuario(tarja.nombreUsuario)}',
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
                               builder: (context) => AprobacionTarjasEditarScreen(tarja: tarja),
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
                color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey[850] 
                  : Colors.grey[50],
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
                                  color: _getAdaptiveColor(context),
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
                              // Lógica para cambiar estado entre REVISADA y APROBADA
                              final nuevoEstado = tarja.idEstadoactividad == '2' ? '3' : '2';
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
                                  await ApiService().cambiarEstadoActividad(
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
                              tarja.idEstadoactividad == '2' ? Icons.check_circle : Icons.undo,
                              size: 18,
                            ),
                            label: Text(
                              tarja.idEstadoactividad == '2' ? 'Marcar como Aprobada' : 'Marcar como Revisada',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: tarja.idEstadoactividad == '2' ? Colors.green : Colors.orange,
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
                  color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.green[800]!.withOpacity(0.3) 
                  : Colors.green[50],
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
                        Text('Cantidad trabajadores: ', style: TextStyle(color: _getAdaptiveColor(context))),
                        Text(cantidadTrab, style: TextStyle(color: _getAdaptiveColor(context))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.percent, color: Colors.blue, size: 16),
                        const SizedBox(width: 4),
                        Text('Porcentaje: ', style: TextStyle(color: _getAdaptiveColor(context))),
                        Text('${porcentajeStr != 'N/A' ? porcentajeStr + '%' : 'N/A'}', style: TextStyle(color: _getAdaptiveColor(context))),
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
                                                Text('Rendimiento total', style: TextStyle(fontWeight: FontWeight.w600, color: _getAdaptiveColor(context))),
                      Text(rendimientoTotal, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _getAdaptiveColor(context))),
                      Text(tarja.nombreUnidad ?? 'Unidad', style: TextStyle(fontSize: 12, color: _getAdaptiveColor(context))),
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
                          Text('Pago estimado por trabajador', style: TextStyle(fontWeight: FontWeight.w600, color: _getAdaptiveColor(context), fontSize: 12)),
                          Text(
                            '\$${_calcularTotalEstimadoPorTrabajador(rendimientoTotal, cantidadTrab, tarja.tarifa, r)}',
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
                  color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.green[800]!.withOpacity(0.3) 
                  : Colors.green[50],
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
                            child: Text(labor, style: TextStyle(color: _getAdaptiveColor(context), fontSize: 13)),
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
                          child: Text(nombre, style: TextStyle(color: _getAdaptiveColor(context), fontSize: 13)),
                        ),
                      ],
                    ),
                    if (porcentaje != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.percent, color: Colors.blue, size: 16),
                          const SizedBox(width: 4),
                          Text('Porcentaje: ', style: TextStyle(color: _getAdaptiveColor(context))),
                          Text(porcentaje, style: TextStyle(color: _getAdaptiveColor(context))),
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
                          Text('Rendimiento', style: TextStyle(fontWeight: FontWeight.w600, color: _getAdaptiveColor(context))),
                          Text(rendimientoValor, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _getAdaptiveColor(context))),
                          Text(tarja.nombreUnidad ?? 'Unidad', style: TextStyle(fontSize: 12, color: _getAdaptiveColor(context))),
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
                          Text('Pago a trabajador', style: TextStyle(fontWeight: FontWeight.w600, color: _getAdaptiveColor(context), fontSize: 12)),
                          Text(
                            '\$${_calcularPagoTrabajador(rendimientoValor, tarja.tarifa, r)}',
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
                color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.green[800]!.withOpacity(0.3) 
                  : Colors.green[50],
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
                      color: _getAdaptiveColor(context),
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
                          color: _getAdaptiveColor(context),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '\$${_calcularPagoTrabajador(r['rendimiento']?.toString() ?? r['cantidad']?.toString() ?? '0', tarja.tarifa, r)}',
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
                        color: _getAdaptiveColor(context),
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
      final rendimientoTotal = r['rendimiento_total']?.toString() ?? r['rendimiento']?.toString() ?? '0';
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
                  color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.green[800]!.withOpacity(0.3) 
                  : Colors.green[50],
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
                            child: Text(labor, style: TextStyle(color: _getAdaptiveColor(context), fontSize: 13)),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.groups, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text('Cantidad trabajadores: ', style: TextStyle(color: _getAdaptiveColor(context))),
                        Text(cantidadTrab, style: TextStyle(color: _getAdaptiveColor(context))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.percent, color: Colors.blue, size: 16),
                        const SizedBox(width: 4),
                        Text('Porcentaje: ', style: TextStyle(color: _getAdaptiveColor(context))),
                        Text('${porcentajeStr != 'N/A' ? porcentajeStr + '%' : 'N/A'}', style: TextStyle(color: _getAdaptiveColor(context))),
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
                      Text('Rendimiento total', style: TextStyle(fontWeight: FontWeight.w600, color: _getAdaptiveColor(context))),
                      Text(rendimientoTotal, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _getAdaptiveColor(context))),
                      Text(tarja.nombreUnidad ?? 'Unidad', style: TextStyle(fontSize: 12, color: _getAdaptiveColor(context))),
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
        // Valor ya calculado arriba
      } else {
        // Para rendimientos individuales, usar rendimiento o cantidad
        final rendimientoValor = rendimiento['rendimiento']?.toString() ?? rendimiento['cantidad']?.toString() ?? '0';
        valorRendimiento = double.tryParse(rendimientoValor) ?? 0;
      }
      
      totalRendimiento += valorRendimiento;
    }
    return totalRendimiento.toStringAsFixed(2);
  }

  // Método para calcular el total de pago de una actividad
  String _calcularTotalPago(List<Map<String, dynamic>> rendimientos, Tarja tarja) {
    // Determinar el tipo de actividad
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
    
    // Obtener la tarifa de la actividad
    final tarifa = double.tryParse(tarja.tarifa) ?? 0;
    
    double totalPago = 0;
    

    
    if (tipoActividad == 'propio') {
      // Para propios: tarifa * rendimiento total (sin porcentaje)
      final totalRendimientoStr = _calcularTotalRendimientos(rendimientos, tarja);
      final totalRendimiento = double.tryParse(totalRendimientoStr) ?? 0;
      totalPago = tarifa * totalRendimiento;
      

    } else if (tipoActividad == 'contratista') {
      // Para contratistas individuales: suma de (rendimiento × tarifa × (1 + porcentaje))
      for (var rendimiento in rendimientos) {
        final rendimientoValor = rendimiento['rendimiento']?.toString() ?? rendimiento['cantidad']?.toString() ?? '0';
        final rendimientoDouble = double.tryParse(rendimientoValor) ?? 0;
        
        // Obtener el porcentaje del trabajador
        final porcentajeRaw = rendimiento['porcentaje'];
        double porcentaje = 0;
        if (porcentajeRaw != null) {
          if (porcentajeRaw is num) {
            porcentaje = porcentajeRaw.toDouble();
          } else {
            porcentaje = double.tryParse(porcentajeRaw.toString()) ?? 0;
          }
        }
        
        final pagoIndividual = rendimientoDouble * tarifa * (1 + porcentaje);
        totalPago += pagoIndividual;
        

      }
    } else if (tipoActividad == 'grupal') {
      // Para grupales: suma de (rendimiento del grupo × tarifa × (1 + porcentaje)) para cada registro
      for (var rendimiento in rendimientos) {
        final rendimientoTotal = rendimiento['rendimiento_total']?.toString() ?? rendimiento['rendimiento']?.toString() ?? '0';
        final rendimientoTotalDouble = double.tryParse(rendimientoTotal) ?? 0;
        
        // Obtener el porcentaje del grupo
        final porcentajeRaw = rendimiento['porcentaje_grupal'] ?? rendimiento['porcentaje'];
        double porcentaje = 0;
        if (porcentajeRaw != null) {
          if (porcentajeRaw is num) {
            porcentaje = porcentajeRaw.toDouble();
          } else {
            porcentaje = double.tryParse(porcentajeRaw.toString()) ?? 0;
          }
        }
        
        final pagoGrupal = rendimientoTotalDouble * tarifa * (1 + porcentaje);
        totalPago += pagoGrupal;
        
        print('   - Rendimiento grupal: $rendimientoTotalDouble, Porcentaje: $porcentaje, Pago: $pagoGrupal');
      }
      
      print('   - Total pago (grupal): $totalPago');
    }
    
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
  String _calcularPagoTrabajador(String rendimientoValor, String tarifa, [Map<String, dynamic>? rendimientoData]) {
    // Convertir el rendimiento a double
    final rendimiento = double.tryParse(rendimientoValor) ?? 0;
    
    // Convertir la tarifa a double
    final tarifaDouble = double.tryParse(tarifa) ?? 0;
    
    // Determinar si es contratista y obtener el porcentaje
    double porcentaje = 0;
    if (rendimientoData != null) {
      final porcentajeRaw = rendimientoData['porcentaje'];
      if (porcentajeRaw != null) {
        if (porcentajeRaw is num) {
          porcentaje = porcentajeRaw.toDouble();
        } else {
          porcentaje = double.tryParse(porcentajeRaw.toString()) ?? 0;
        }
      }
    }
    
    // Calcular el pago: tarifa * rendimiento * (1 + porcentaje)
    final pago = tarifaDouble * rendimiento * (1 + porcentaje);
    

    
    // Formatear como número entero con separación de miles
    final pagoEntero = pago.round();
    return _formatearNumeroConSeparadores(pagoEntero);
  }

  // Método para calcular el total estimado por trabajador en rendimientos grupales
  String _calcularTotalEstimadoPorTrabajador(String rendimientoTotal, String cantidadTrab, String tarifa, [Map<String, dynamic>? rendimientoData]) {
    // Convertir valores a double
    final rendimiento = double.tryParse(rendimientoTotal) ?? 0;
    final cantidad = double.tryParse(cantidadTrab) ?? 1;
    final tarifaDouble = double.tryParse(tarifa) ?? 0;
    
    // Obtener el porcentaje del grupo
    double porcentaje = 0;
    if (rendimientoData != null) {
      final porcentajeRaw = rendimientoData['porcentaje_grupal'] ?? rendimientoData['porcentaje'];
      if (porcentajeRaw != null) {
        if (porcentajeRaw is num) {
          porcentaje = porcentajeRaw.toDouble();
        } else {
          porcentaje = double.tryParse(porcentajeRaw.toString()) ?? 0;
        }
      }
    }
    
    // Calcular: (rendimiento_total ÷ cantidad_trabajadores) × tarifa × (1 + porcentaje)
    final rendimientoPorTrabajador = rendimiento / cantidad;
    final totalEstimado = rendimientoPorTrabajador * tarifaDouble * (1 + porcentaje);
    

    
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
      child: Column(
        children: [
          TextField(
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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showFiltros = !_showFiltros;
                    });
                  },
                  icon: Icon(_showFiltros ? Icons.filter_list_off : Icons.filter_list),
                  label: Text(_showFiltros ? 'Ocultar filtros' : 'Mostrar filtros'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
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
          if (_showFiltros) ...[
            const SizedBox(height: 12),
            _buildFiltrosAvanzados(),
          ],
        ],
      ),
    );
  }

  Widget _buildFiltrosAvanzados() {
    return Consumer<TarjaProvider>(
      builder: (context, tarjaProvider, child) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filtros Avanzados',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: tarjaProvider.filtroContratista.isEmpty ? null : tarjaProvider.filtroContratista,
                      decoration: const InputDecoration(
                        labelText: 'Contratista',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Todos los contratistas'),
                        ),
                        ...tarjaProvider.contratistasUnicos.map((contratista) {
                          return DropdownMenuItem<String>(
                            value: contratista,
                            child: Text(contratista),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        tarjaProvider.setFiltroContratista(value ?? '');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: tarjaProvider.filtroTipoRendimiento.isEmpty ? null : tarjaProvider.filtroTipoRendimiento,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Rendimiento',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Todos los tipos'),
                        ),
                        ...tarjaProvider.tiposRendimientoUnicos.map((tipo) {
                          return DropdownMenuItem<String>(
                            value: tipo,
                            child: Text(tipo),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        tarjaProvider.setFiltroTipoRendimiento(value ?? '');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: tarjaProvider.filtroUsuario.isEmpty ? null : tarjaProvider.filtroUsuario,
                      decoration: const InputDecoration(
                        labelText: 'Usuario',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Todos los usuarios'),
                        ),
                        ...tarjaProvider.usuariosUnicos.map((usuario) {
                          return DropdownMenuItem<String>(
                            value: usuario,
                            child: Text(usuario),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        tarjaProvider.setFiltroUsuario(value ?? '');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: SizedBox()), // Espacio vacío para mantener el layout
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        tarjaProvider.limpiarFiltros();
                        _searchController.clear();
                        _onSearchChanged('');
                        setState(() {
                          _filtroActivo = null;
                        });
                      },
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Limpiar filtros'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        tarjaProvider.cargarTarjas();
                      },
                      icon: const Icon(Icons.search),
                      label: const Text('Aplicar filtros'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
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
        );
      },
    );
  }

  Widget _buildEstadisticas() {
    return Consumer<TarjaProvider>(
      builder: (context, tarjaProvider, child) {
        final tarjas = tarjaProvider.tarjas;
        
        // Calcular estadísticas
        final total = tarjas.where((t) => t.idEstadoactividad == '2' || t.idEstadoactividad == '3').length;
        final revisadas = tarjas.where((t) => t.idEstadoactividad == '2').length;
        final aprobadas = tarjas.where((t) => t.idEstadoactividad == '3').length;
        final propio = tarjas.where((t) => 
          t.idTipotrabajador == '1' && (t.idEstadoactividad == '2' || t.idEstadoactividad == '3')
        ).length;
        final contratista = tarjas.where((t) => 
          t.idTipotrabajador == '2' && (t.idEstadoactividad == '2' || t.idEstadoactividad == '3')
        ).length;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: _buildTarjetaEstadistica(
                  'Total',
                  total.toString(),
                  Icons.assessment,
                  Colors.purple,
                  _filtroActivo == null,
                  () => _aplicarFiltro(null),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTarjetaEstadistica(
                  'Revisadas',
                  revisadas.toString(),
                  Icons.check_circle,
                  Colors.orange,
                  _filtroActivo == 'revisadas',
                  () => _aplicarFiltro('revisadas'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTarjetaEstadistica(
                  'Aprobadas',
                  aprobadas.toString(),
                  Icons.verified,
                  Colors.green,
                  _filtroActivo == 'aprobadas',
                  () => _aplicarFiltro('aprobadas'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTarjetaEstadistica(
                  'Propio',
                  propio.toString(),
                  Icons.person,
                  Colors.blue,
                  _filtroActivo == 'propio',
                  () => _aplicarFiltro('propio'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTarjetaEstadistica(
                  'Contratista',
                  contratista.toString(),
                  Icons.people,
                  Colors.purple,
                  _filtroActivo == 'contratista',
                  () => _aplicarFiltro('contratista'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTarjetaEstadistica(
    String titulo,
    String valor,
    IconData icono,
    Color color,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.2) : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? color : color.withOpacity(0.3),
              width: isActive ? 2 : 1,
            ),
            boxShadow: isActive ? [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Column(
            children: [
              Icon(
                icono,
                color: color,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                valor,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 12,
                  color: color.withOpacity(0.8),
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
              if (isActive) ...[
                const SizedBox(height: 4),
                Container(
                  width: 20,
                  height: 3,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        _buildEstadisticas(),
        Expanded(
          child: Consumer<TarjaProvider>(
            builder: (context, tarjaProvider, child) {
              final tarjasFiltradas = _filtrarTarjas(tarjaProvider.tarjasFiltradas.isNotEmpty ? tarjaProvider.tarjasFiltradas : tarjaProvider.tarjas);
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
                          if (_expansionState.length > i) {
                            setState(() {
                              _expansionState[i] = isExpanded;
                            });
                          }
                        },
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        collapsedBackgroundColor: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.grey[800]!.withOpacity(0.3)
                          : AppTheme.primaryColor.withOpacity(0.07),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _formatearFecha(fecha),
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _getAdaptiveColor(context, lightColor: AppTheme.primaryColor, darkColor: AppTheme.primaryColor),
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
                            Text(
                              'actividades',
                              style: TextStyle(
                                color: _getAdaptiveColor(context, lightColor: AppTheme.primaryColor, darkColor: AppTheme.primaryColor),
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
    );
  }
}

 