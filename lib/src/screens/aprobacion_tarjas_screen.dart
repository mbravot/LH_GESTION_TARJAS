import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/tarja.dart';
import '../providers/auth_provider.dart';
import '../providers/tarja_provider.dart';
import '../widgets/main_scaffold.dart';
import '../theme/app_theme.dart';
import '../services/tarja_service.dart';
import 'aprobacion_tarjas_editar_screen.dart';
import '../screens/rendimientos_page_screen.dart';

class AprobacionTarjasScreen extends StatefulWidget {
  const AprobacionTarjasScreen({super.key});

  @override
  State<AprobacionTarjasScreen> createState() => _AprobacionTarjasScreenState();
}

class _AprobacionTarjasScreenState extends State<AprobacionTarjasScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;
  List<bool> _expansionState = [];
  Key _expansionKey = UniqueKey();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
      case 1: // Revisadas
        tarjasFiltradasPorTab = tarjas.where((t) => t.idEstadoactividad == '2').toList();
        break;
      case 2: // Aprobadas
        tarjasFiltradasPorTab = tarjas.where((t) => t.idEstadoactividad == '3').toList();
        break;
      case 3: // Propio
        tarjasFiltradasPorTab = tarjas.where((t) => 
          t.idTipotrabajador == '1' && (t.idEstadoactividad == '2' || t.idEstadoactividad == '3')
        ).toList();
        break;
      case 4: // Contratista
        tarjasFiltradasPorTab = tarjas.where((t) => 
          t.idTipotrabajador == '2' && (t.idEstadoactividad == '2' || t.idEstadoactividad == '3')
        ).toList();
        break;
      default: // Todas (solo estado 2 y 3)
        tarjasFiltradasPorTab = tarjas.where((t) => 
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
    // Debug logging
    print('DEBUG - obtenerNombreUnidad:');
    print('  nombreUnidad: ${tarja.nombreUnidad}');
    print('  idUnidad: ${tarja.idUnidad}');
    print('  nombreUsuario: ${tarja.nombreUsuario}');
    
    if (tarja.nombreUnidad != null && tarja.nombreUnidad!.isNotEmpty) {
      print('  Retornando nombre: ${tarja.nombreUnidad}');
      return tarja.nombreUnidad!;
    }
    
    // Fallback: si no hay nombre específico, mostramos el ID
    if (tarja.idUnidad.isNotEmpty) {
      return 'Unidad ID: ${tarja.idUnidad}';
    }
    
    return 'Sin Unidad';
  }

  Widget _buildActividadCard(Tarja tarja) {
    final estadoData = _getEstadoActividad(tarja.idEstadoactividad);
    final String estadoNombre = estadoData['nombre'];
    final Color estadoColor = estadoData['color'];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.colorScheme.surface;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    final textColor = theme.colorScheme.onSurface;

    return GestureDetector(
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
      child: Card(
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: borderColor, width: 1),
        ),
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  InkWell(
                    onTap: () async {
                      if (!tarja.tieneRendimiento) {
                        // Mostrar diálogo informativo cuando no hay rendimientos
                        await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('No se puede cambiar el estado'),
                            content: const Text(
                              'La actividad debe tener rendimientos asociados para poder aprobarla.',
                              style: TextStyle(fontSize: 16),
                            ),
                            icon: const Icon(
                              Icons.info_outline,
                              color: Colors.orange,
                              size: 48,
                            ),
                            actions: [
                              ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Entendido'),
                              ),
                            ],
                          ),
                        );
                        return;
                      }

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
                          await TarjaService().cambiarEstadoActividad(
                            tarja.id, nuevoEstado,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Estado actualizado a "$nuevoNombre"'), backgroundColor: Colors.green,),
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
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: estadoColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        estadoNombre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
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
                  // Indicador de rendimiento
                  GestureDetector(
                    onTap: () {
                      if (tarja.tieneRendimiento) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RendimientosPageScreen(
                              actividadId: tarja.id,
                              idTipotrabajador: tarja.idTipotrabajador,
                              idTiporendimiento: tarja.idTiporendimiento,
                              idContratista: tarja.idContratista,
                            ),
                          ),
                        );
                      } else {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Sin rendimientos'),
                            content: const Text(
                              'La actividad no posee rendimientos.',
                              style: TextStyle(fontSize: 16),
                            ),
                            icon: const Icon(
                              Icons.info_outline,
                              color: Colors.orange,
                              size: 48,
                            ),
                            actions: [
                              ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Entendido'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: tarja.tieneRendimiento ? Colors.green : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              tarja.tieneRendimiento ? Icons.check_circle : Icons.pending_outlined,
                              size: 16,
                              color: tarja.tieneRendimiento ? Colors.white : Colors.grey[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              tarja.tieneRendimiento ? 'Con rendimiento' : 'Sin rendimiento',
                              style: TextStyle(
                                color: tarja.tieneRendimiento ? Colors.white : Colors.grey[700],
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
      title: 'Aprobación de Tarjas',
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
    // Solo contar tarjas con estado 2 o 3 (revisadas o aprobadas)
    return tarjas.where((t) => t.idEstadoactividad == '2' || t.idEstadoactividad == '3').length;
  }

  int _getContadorRevisadas(List<Tarja> tarjas) {
    return tarjas.where((t) => t.idEstadoactividad == '2').length;
  }

  int _getContadorAprobadas(List<Tarja> tarjas) {
    return tarjas.where((t) => t.idEstadoactividad == '3').length;
  }

  int _getContadorPropio(List<Tarja> tarjas) {
    // Solo contar tarjas propias con estado 2 o 3
    return tarjas.where((t) => 
      t.idTipotrabajador == '1' && (t.idEstadoactividad == '2' || t.idEstadoactividad == '3')
    ).length;
  }

  int _getContadorContratista(List<Tarja> tarjas) {
    // Solo contar tarjas de contratista con estado 2 o 3
    return tarjas.where((t) => 
      t.idTipotrabajador == '2' && (t.idEstadoactividad == '2' || t.idEstadoactividad == '3')
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
                  const Text('Revisadas'),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
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
                  const Text('Aprobadas'),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_getContadorAprobadas(tarjaProvider.tarjas)}',
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