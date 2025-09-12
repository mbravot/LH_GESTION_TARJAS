import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/sueldo_base.dart';
import '../providers/sueldo_base_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/main_scaffold.dart';
import '../theme/app_theme.dart';
import 'sueldo_base_crear_screen.dart';
import 'sueldo_base_editar_screen.dart';

class SueldoBaseScreen extends StatefulWidget {
  const SueldoBaseScreen({super.key});

  @override
  State<SueldoBaseScreen> createState() => _SueldoBaseScreenState();
}

class _SueldoBaseScreenState extends State<SueldoBaseScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showFiltros = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatos();
    });
  }

  Future<void> _cargarDatos() async {
    final sueldoBaseProvider = Provider.of<SueldoBaseProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

    // Inicializar provider si no está inicializado
    sueldoBaseProvider.initialize(authProvider, notificationProvider);

    // Establecer la sucursal del usuario autenticado
    if (authProvider.userData != null && authProvider.userData!['id_sucursal'] != null) {
      sueldoBaseProvider.setIdSucursal(authProvider.userData!['id_sucursal'].toString());
    }

    // Cargar sueldos base
    await sueldoBaseProvider.cargarSueldosBase();
  }

  Future<void> _refrescarDatos() async {
    final sueldoBaseProvider = Provider.of<SueldoBaseProvider>(context, listen: false);
    await sueldoBaseProvider.cargarSueldosBase();
  }

  void _filtrarSueldos() {
    final sueldoBaseProvider = Provider.of<SueldoBaseProvider>(context, listen: false);
    sueldoBaseProvider.setFiltroColaborador(_searchQuery);
  }

  void _limpiarFiltros() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
    final sueldoBaseProvider = Provider.of<SueldoBaseProvider>(context, listen: false);
    sueldoBaseProvider.limpiarFiltros();
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      showAppBarElements: false,
      body: Consumer<SueldoBaseProvider>(
        builder: (context, sueldoBaseProvider, child) {
          if (sueldoBaseProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (sueldoBaseProvider.error != null) {
            return Center(
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
                    'Error al cargar los sueldos base',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sueldoBaseProvider.error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _refrescarDatos,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Barra de búsqueda y filtros
              _buildSearchAndFilters(sueldoBaseProvider),
              
              // Estadísticas
              _buildEstadisticas(sueldoBaseProvider),
              
              // Lista de sueldos base
              Expanded(
                child: _buildListaSueldosBase(sueldoBaseProvider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilters(SueldoBaseProvider sueldoBaseProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por colaborador...',
              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                        _filtrarSueldos();
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
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _filtrarSueldos();
            },
          ),
          
          const SizedBox(height: 12),
          
          // Botones de acción (Nuevo y Filtros)
          Row(
            children: [
              // Botón de filtros
              Expanded(
                flex: 4,
                child: Consumer<SueldoBaseProvider>(
                  builder: (context, provider, child) {
                    final tieneFiltrosActivos = _tieneFiltrosActivos(provider);

                    return Container(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showFiltros = !_showFiltros;
                          });
                        },
                        icon: Icon(_showFiltros ? Icons.filter_list_off : Icons.filter_list),
                        label: Text(_showFiltros ? 'Ocultar filtros' : 'Mostrar filtros'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tieneFiltrosActivos ? Colors.orange : Colors.grey[500],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Botón Nuevo
              Expanded(
                flex: 1,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SueldoBaseCrearScreen(),
                      ),
                    ).then((_) => _refrescarDatos());
                  },
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Nuevo Sueldo', style: TextStyle(fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
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
          
          // Filtros expandibles
          if (_showFiltros) ...[
            const SizedBox(height: 16),
            _buildFiltros(sueldoBaseProvider),
          ],
        ],
      ),
    );
  }

  Widget _buildFiltros(SueldoBaseProvider sueldoBaseProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtros',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Filtro por colaborador
          DropdownButtonFormField<String>(
            value: sueldoBaseProvider.filtroColaborador.isEmpty 
                ? null 
                : sueldoBaseProvider.filtroColaborador,
            decoration: const InputDecoration(
              labelText: 'Colaborador',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: '',
                child: Text('Todos los colaboradores'),
              ),
              ...sueldoBaseProvider.colaboradoresUnicos.map((colaborador) {
                return DropdownMenuItem<String>(
                  value: colaborador,
                  child: Text(colaborador),
                );
              }),
            ],
            onChanged: (value) {
              sueldoBaseProvider.setFiltroColaborador(value ?? '');
            },
          ),
          
          const SizedBox(height: 16),
          
          // Filtro por fecha
          DropdownButtonFormField<String>(
            value: sueldoBaseProvider.filtroFecha.isEmpty 
                ? null 
                : sueldoBaseProvider.filtroFecha,
            decoration: const InputDecoration(
              labelText: 'Fecha',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: '',
                child: Text('Todas las fechas'),
              ),
              ...sueldoBaseProvider.fechasUnicas.map((fecha) {
                return DropdownMenuItem<String>(
                  value: fecha,
                  child: Text(fecha),
                );
              }),
            ],
            onChanged: (value) {
              sueldoBaseProvider.setFiltroFecha(value ?? '');
            },
          ),
          
          const SizedBox(height: 16),
          
          // Botón limpiar filtros
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _limpiarFiltros,
              icon: const Icon(Icons.clear_all),
              label: const Text('Limpiar filtros'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticas(SueldoBaseProvider sueldoBaseProvider) {
    final grupos = sueldoBaseProvider.sueldosBaseAgrupados;
    final totalColaboradores = grupos.length;
    final totalSueldos = sueldoBaseProvider.sueldosBaseFiltrados.length;
    final totalMonto = sueldoBaseProvider.sueldosBaseFiltrados
        .fold<int>(0, (sum, sueldo) => sum + sueldo.sueldobase);
    final promedioSueldo = totalSueldos > 0 ? totalMonto / totalSueldos : 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildTarjetaEstadistica(
              'Colaboradores',
              totalColaboradores.toString(),
              Icons.people,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildTarjetaEstadistica(
              'Total Sueldos',
              totalSueldos.toString(),
              Icons.attach_money,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildTarjetaEstadistica(
              'Promedio',
              '\$${promedioSueldo.round().toString().replaceAllMapped(
                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                (Match m) => '${m[1]}.',
              )}',
              Icons.trending_up,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaEstadistica(String titulo, String valor, IconData icono, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icono, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            valor,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildListaSueldosBase(SueldoBaseProvider sueldoBaseProvider) {
    final grupos = sueldoBaseProvider.sueldosBaseAgrupados;
    final sueldos = sueldoBaseProvider.sueldosBaseFiltrados;
    
    print('🎨 [UI] Construyendo lista - Grupos: ${grupos.length}, Sueldos filtrados: ${sueldos.length}');
    print('🎨 [UI] Estado de carga: ${sueldoBaseProvider.isLoading}');
    print('🎨 [UI] Error: ${sueldoBaseProvider.error}');

    if (grupos.isNotEmpty) {
      // Usar estructura agrupada
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: grupos.length,
        itemBuilder: (context, index) {
          final grupo = grupos[index];
          return _buildTarjetaSueldoBaseAgrupado(grupo);
        },
      );
    } else if (sueldos.isNotEmpty) {
      // Fallback a estructura plana
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sueldos.length,
        itemBuilder: (context, index) {
          final sueldo = sueldos[index];
          return _buildTarjetaSueldoBase(sueldo);
        },
      );
    } else {
      // Sin datos
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.attach_money_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay sueldos base registrados',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega un nuevo sueldo base para comenzar',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTarjetaSueldoBaseAgrupado(SueldoBaseAgrupado grupo) {
    final theme = Theme.of(context);
    final cardColor = theme.colorScheme.surface;
    final borderColor = Colors.green[300]!;
    final textColor = theme.colorScheme.onSurface;
    final sueldoReciente = grupo.sueldoMasReciente;

    if (sueldoReciente == null) return const SizedBox.shrink();

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: borderColor, width: 1),
      ),
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _mostrarDetallesSueldoAgrupado(grupo),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título con icono
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.attach_money,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      grupo.nombreColaborador,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Contenido en columnas (mismo estilo que colaboradores)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Columna 1: Sueldo Base
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.attach_money, color: Colors.green, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Sueldo: ${sueldoReciente.sueldobaseFormateado}',
                                style: TextStyle(
                                  color: textColor.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Columna 2: Base Día
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.orange, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Base Día: ${sueldoReciente.baseDiaFormateado}',
                                style: TextStyle(
                                  color: textColor.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Columna 3: Hora Día
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.access_time, color: Colors.purple, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Hora Día: ${sueldoReciente.horaDiaFormateado}',
                                style: TextStyle(
                                  color: textColor.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Columna 4: Fecha
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.event, color: Colors.indigo, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Fecha: ${sueldoReciente.fechaFormateada}',
                                style: TextStyle(
                                  color: textColor.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Columna 5: Acciones
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: () => _editarSueldo(sueldoReciente),
                          icon: Icon(Icons.edit, color: AppTheme.primaryColor, size: 20),
                          tooltip: 'Editar sueldo base',
                        ),
                        IconButton(
                          onPressed: () => _eliminarSueldo(sueldoReciente),
                          icon: Icon(Icons.delete, color: Colors.red, size: 20),
                          tooltip: 'Eliminar sueldo base',
                        ),
                      ],
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

  Widget _buildTarjetaSueldoBase(SueldoBase sueldo) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.colorScheme.surface;
    // Color del borde - verde para sueldos base
    final borderColor = Colors.green[300]!;
    final textColor = theme.colorScheme.onSurface;

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: borderColor, width: 1),
      ),
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _mostrarDetallesSueldo(sueldo),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título con icono
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.attach_money,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      sueldo.nombreColaborador ?? 'Colaborador no disponible',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
               // Contenido en 5 columnas
               Row(
                 children: [
                   // 1. Columna: Nombre y Fecha
                   Expanded(
                     flex: 3,
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Row(
                           children: [
                             Icon(Icons.person, color: AppTheme.primaryColor, size: 16),
                             const SizedBox(width: 8),
                             Expanded(
                               child: Text(
                                 sueldo.nombreColaborador ?? 'Colaborador no disponible',
                                 style: TextStyle(
                                   fontSize: 14,
                                   fontWeight: FontWeight.w600,
                                   color: textColor,
                                 ),
                               ),
                             ),
                           ],
                         ),
                         const SizedBox(height: 4),
                         Row(
                           children: [
                             Icon(Icons.event, color: Colors.indigo[600], size: 16),
                             const SizedBox(width: 8),
                             Expanded(
                               child: Text(
                                 sueldo.fechaFormateada,
                                 style: TextStyle(
                                   fontSize: 12,
                                   color: Colors.indigo[700],
                                   fontWeight: FontWeight.w500,
                                 ),
                               ),
                             ),
                           ],
                         ),
                       ],
                     ),
                   ),
                   
                   // 2. Columna: Sueldo Base
                   Expanded(
                     flex: 2,
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Row(
                           children: [
                             Icon(Icons.attach_money, color: Colors.green[600], size: 16),
                             const SizedBox(width: 8),
                             Expanded(
                               child: Text(
                                 'Sueldo Base',
                                 style: TextStyle(
                                   fontSize: 12,
                                   color: Colors.grey[600],
                                   fontWeight: FontWeight.w500,
                                 ),
                               ),
                             ),
                           ],
                         ),
                         const SizedBox(height: 4),
                         Text(
                           sueldo.sueldobaseFormateado,
                           style: TextStyle(
                             fontSize: 14,
                             fontWeight: FontWeight.w600,
                             color: Colors.green[700],
                           ),
                         ),
                       ],
                     ),
                   ),
                   
                   // 3. Columna: Base Día
                   Expanded(
                     flex: 2,
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Row(
                           children: [
                             Icon(Icons.calendar_today, color: Colors.orange[600], size: 16),
                             const SizedBox(width: 8),
                             Expanded(
                               child: Text(
                                 'Base Día',
                                 style: TextStyle(
                                   fontSize: 12,
                                   color: Colors.grey[600],
                                   fontWeight: FontWeight.w500,
                                 ),
                               ),
                             ),
                           ],
                         ),
                         const SizedBox(height: 4),
                         Text(
                           sueldo.baseDiaFormateado,
                           style: TextStyle(
                             fontSize: 14,
                             fontWeight: FontWeight.w600,
                             color: Colors.orange[700],
                           ),
                         ),
                       ],
                     ),
                   ),
                   
                   // 4. Columna: Hora Día
                   Expanded(
                     flex: 2,
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Row(
                           children: [
                             Icon(Icons.access_time, color: Colors.purple[600], size: 16),
                             const SizedBox(width: 8),
                             Expanded(
                               child: Text(
                                 'Hora Día',
                                 style: TextStyle(
                                   fontSize: 12,
                                   color: Colors.grey[600],
                                   fontWeight: FontWeight.w500,
                                 ),
                               ),
                             ),
                           ],
                         ),
                         const SizedBox(height: 4),
                         Text(
                           sueldo.horaDiaFormateado,
                           style: TextStyle(
                             fontSize: 14,
                             fontWeight: FontWeight.w600,
                             color: Colors.purple[700],
                           ),
                         ),
                       ],
                     ),
                   ),
                   
                   // 5. Columna: Acciones
                   Expanded(
                     flex: 1,
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.end,
                       children: [
                         IconButton(
                           onPressed: () => _editarSueldo(sueldo),
                           icon: Icon(Icons.edit, color: AppTheme.primaryColor, size: 20),
                           tooltip: 'Editar sueldo base',
                         ),
                         IconButton(
                           onPressed: () => _eliminarSueldo(sueldo),
                           icon: Icon(Icons.delete, color: Colors.red, size: 20),
                           tooltip: 'Eliminar sueldo base',
                         ),
                       ],
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

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildDetalleSueldo(String titulo, String valor, IconData icono) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icono, size: 16, color: Colors.grey[600]),
          const SizedBox(height: 4),
          Text(
            valor,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            titulo,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDetallesSueldoAgrupado(SueldoBaseAgrupado grupo) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 600),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surface.withOpacity(0.95),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header con avatar y nombre
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.green.withOpacity(0.1),
                      Colors.green.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.green, Colors.green.withOpacity(0.7)],
                        ),
                      ),
                      child: Icon(
                        Icons.attach_money,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            grupo.nombreColaborador,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '${grupo.sueldosBase.length} sueldo${grupo.sueldosBase.length != 1 ? 's' : ''}',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Contenido con información
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Información del colaborador
                      _buildInfoSection(
                        'Información del Colaborador',
                        Icons.person_outline,
                        [
                          _buildModernInfoRow('RUT', grupo.rut, Icons.badge),
                          _buildModernInfoRow('Sucursal', grupo.nombreSucursal, Icons.business),
                          _buildModernInfoRow('Total Sueldos', grupo.sueldosBase.length.toString(), Icons.attach_money),
                          _buildModernInfoRow('Promedio', '\$${grupo.promedioSueldos.round().toString().replaceAllMapped(
                            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                            (Match m) => '${m[1]}.',
                          )}', Icons.trending_up),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Historial de sueldos
                      _buildInfoSection(
                        'Historial de Sueldos Base',
                        Icons.history,
                        grupo.sueldosBase.map((sueldo) => 
                          _buildSueldoHistoryItem(sueldo)
                        ).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Botones de acción
              Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cerrar',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildModernInfoRow(String label, String value, IconData icon) {
    Color iconColor;
    Color backgroundColor;
    
    if (icon == Icons.badge) {
      iconColor = Colors.blue;
      backgroundColor = Colors.blue.withOpacity(0.1);
    } else if (icon == Icons.business) {
      iconColor = Colors.green;
      backgroundColor = Colors.green.withOpacity(0.1);
    } else if (icon == Icons.attach_money) {
      iconColor = Colors.green;
      backgroundColor = Colors.green.withOpacity(0.1);
    } else if (icon == Icons.trending_up) {
      iconColor = Colors.orange;
      backgroundColor = Colors.orange.withOpacity(0.1);
    } else {
      iconColor = AppTheme.primaryColor;
      backgroundColor = AppTheme.primaryColor.withOpacity(0.1);
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSueldoHistoryItem(SueldoBase sueldo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.attach_money,
              color: Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sueldo.sueldobaseFormateado,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sueldo.fechaFormateada,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Base Día: ${sueldo.baseDiaFormateado}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Hora Día: ${sueldo.horaDiaFormateado}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _editarSueldo(sueldo);
                },
                icon: Icon(Icons.edit, color: AppTheme.primaryColor, size: 20),
                tooltip: 'Editar',
              ),
              IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _eliminarSueldo(sueldo);
                },
                icon: Icon(Icons.delete, color: Colors.red, size: 20),
                tooltip: 'Eliminar',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _mostrarDetallesSueldo(SueldoBase sueldo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles del Sueldo Base'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetalleDialog('Colaborador', sueldo.nombreColaborador ?? 'No disponible'),
            _buildDetalleDialog('RUT', sueldo.rut ?? 'No disponible'),
            _buildDetalleDialog('Sueldo Base', sueldo.sueldobaseFormateado),
            _buildDetalleDialog('Base Día', sueldo.baseDiaFormateado),
            _buildDetalleDialog('Hora Día', sueldo.horaDiaFormateado),
            _buildDetalleDialog('Fecha', sueldo.fechaFormateada),
            if (sueldo.nombreSucursal != null)
              _buildDetalleDialog('Sucursal', sueldo.nombreSucursal!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _editarSueldo(sueldo);
            },
            child: const Text('Editar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleDialog(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$titulo:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(valor),
          ),
        ],
      ),
    );
  }

  void _editarSueldo(SueldoBase sueldo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SueldoBaseEditarScreen(sueldo: sueldo),
      ),
    ).then((_) => _refrescarDatos());
  }

  void _eliminarSueldo(SueldoBase sueldo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Sueldo Base'),
        content: Text(
          '¿Está seguro de que desea eliminar el sueldo base de ${sueldo.nombreColaborador ?? 'este colaborador'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              final sueldoBaseProvider = Provider.of<SueldoBaseProvider>(context, listen: false);
              final success = await sueldoBaseProvider.eliminarSueldoBase(sueldo.id);
              
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sueldo base eliminado correctamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar: ${sueldoBaseProvider.error ?? 'Error desconocido'}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // Método para verificar si hay filtros activos
  bool _tieneFiltrosActivos(SueldoBaseProvider sueldoBaseProvider) {
    return sueldoBaseProvider.filtroColaborador.isNotEmpty || 
           sueldoBaseProvider.filtroFecha.isNotEmpty ||
           _searchQuery.isNotEmpty;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
