import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/horas_extras_provider.dart';
import '../providers/auth_provider.dart';
import '../models/horas_extras.dart';
import '../theme/app_theme.dart';
import '../theme/dark_theme_colors.dart';

class HorasExtrasScreen extends StatefulWidget {
  const HorasExtrasScreen({Key? key}) : super(key: key);

  @override
  State<HorasExtrasScreen> createState() => _HorasExtrasScreenState();
}

class _HorasExtrasScreenState extends State<HorasExtrasScreen> {
  String _searchQuery = '';
  bool _showFiltros = false;
  String _filtroActivo = 'todos'; // 'todos', 'con_horas_extras', 'sin_horas_extras'
  Set<String> _tarjetasExpandidas = {};
  
  // Variables para agrupación
  List<bool> _expansionState = [];
  final GlobalKey _expansionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  void _aplicarFiltro(String filtro) {
    setState(() {
      _filtroActivo = filtro;
    });
    
    final provider = Provider.of<HorasExtrasProvider>(context, listen: false);
    switch (filtro) {
      case 'con_horas_extras':
        provider.setFiltroEstado('CON_HORAS_EXTRAS');
        break;
      case 'sin_horas_extras':
        provider.setFiltroEstado('SIN_HORAS_EXTRAS');
        break;
      default: // 'todos'
        provider.setFiltroEstado('');
        break;
    }
  }

  Future<void> _cargarDatosIniciales() async {
    final provider = Provider.of<HorasExtrasProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    provider.setAuthProvider(authProvider);
    
    // Usar Future.delayed para evitar el error de setState durante build
    Future.delayed(Duration.zero, () async {
      await provider.cargarRendimientos();
      await provider.cargarBonos();
    });
  }

  Future<void> _refrescarDatos() async {
    final provider = Provider.of<HorasExtrasProvider>(context, listen: false);
    await provider.cargarRendimientos();
  }

  void _alternarExpansion(String rendimientoId) {
    setState(() {
      if (_tarjetasExpandidas.contains(rendimientoId)) {
        _tarjetasExpandidas.remove(rendimientoId);
      } else {
        _tarjetasExpandidas.add(rendimientoId);
      }
    });
  }



  @override
  Widget build(BuildContext context) {
    return Consumer<HorasExtrasProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          body: Column(
            children: [
              _buildSearchBar(),
              if (_showFiltros) ...[
                const SizedBox(height: 12),
                _buildFiltrosAvanzados(),
              ],
              _buildEstadisticas(provider),
              Expanded(
                child: _buildListaHorasExtras(provider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
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
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              final provider = Provider.of<HorasExtrasProvider>(context, listen: false);
              provider.setFiltroBusqueda(value);
            },
            decoration: InputDecoration(
              hintText: 'Buscar por colaborador, actividad o fecha...',
              hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
              prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                        final provider = Provider.of<HorasExtrasProvider>(context, listen: false);
                        provider.setFiltroBusqueda('');
                        FocusScope.of(context).unfocus();
                      },
                    )
                  : null,
              filled: true,
              fillColor: theme.colorScheme.surface,
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
    final theme = Theme.of(context);
    return Consumer<HorasExtrasProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.dividerColor,
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
                      value: provider.filtroColaborador.isEmpty ? null : provider.filtroColaborador,
                      decoration: InputDecoration(
                        labelText: 'Colaborador',
                        labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        fillColor: theme.colorScheme.surface,
                        filled: true,
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Todos los colaboradores'),
                        ),
                        ...provider.colaboradoresUnicos.map((colaborador) {
                          return DropdownMenuItem<String>(
                            value: colaborador,
                            child: Text(colaborador),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        provider.setFiltroColaborador(value ?? '');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: provider.filtroEstado.isEmpty ? null : provider.filtroEstado,
                      decoration: InputDecoration(
                        labelText: 'Estado',
                        labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        fillColor: theme.colorScheme.surface,
                        filled: true,
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Todos los estados'),
                        ),
                        ...provider.estadosUnicos.map((estado) {
                          return DropdownMenuItem<String>(
                            value: estado,
                            child: Text(estado == 'CON_HORAS_EXTRAS' ? 'Con horas extras' : 'Sin horas extras'),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        provider.setFiltroEstado(value ?? '');
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
                      value: provider.filtroActividad.isEmpty ? null : provider.filtroActividad,
                      decoration: InputDecoration(
                        labelText: 'Actividad',
                        labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        fillColor: theme.colorScheme.surface,
                        filled: true,
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Todas las actividades'),
                        ),
                        ...provider.actividadesUnicas.map((actividad) {
                          return DropdownMenuItem<String>(
                            value: actividad,
                            child: Text(actividad),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        provider.setFiltroActividad(value ?? '');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDatePicker(
                      label: 'Fecha Inicio',
                      value: provider.fechaInicio,
                      onChanged: (date) {
                        provider.setFechaInicio(date);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDatePicker(
                      label: 'Fecha Fin',
                      value: provider.fechaFin,
                      onChanged: (date) {
                        provider.setFechaFin(date);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        provider.limpiarFiltros();
                        setState(() {
                          _searchQuery = '';
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
                        provider.cargarRendimientos();
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

  Widget _buildDatePicker({
    required String label,
    required DateTime? value,
    required Function(DateTime?) onChanged,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          locale: const Locale('es', 'ES'),
        );
        onChanged(date);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          suffixIcon: const Icon(Icons.calendar_today),
          fillColor: theme.colorScheme.surface,
          filled: true,
        ),
        child: Text(
          value != null
              ? '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}'
              : 'Seleccionar fecha',
          style: TextStyle(
            color: value != null ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildEstadisticas(HorasExtrasProvider provider) {
    final stats = provider.estadisticas;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildTarjetaEstadistica(
              titulo: 'Total',
              valor: stats['total'].toString(),
              color: Colors.orange,
              icono: Icons.list,
              filtro: 'todos',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTarjetaEstadistica(
              titulo: 'Con Horas Extras',
              valor: stats['con_horas_extras'].toString(),
              color: Colors.green,
              icono: Icons.add_circle,
              filtro: 'con_horas_extras',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTarjetaEstadistica(
              titulo: 'Sin Horas Extras',
              valor: stats['sin_horas_extras'].toString(),
              color: Colors.red,
              icono: Icons.remove_circle,
              filtro: 'sin_horas_extras',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaEstadistica({
    required String titulo,
    required String valor,
    required Color color,
    required IconData icono,
    required String filtro,
  }) {
    final isActivo = _filtroActivo == filtro;
    
    return GestureDetector(
      onTap: () => _aplicarFiltro(filtro),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActivo ? color.withOpacity(0.2) : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActivo ? color : color.withOpacity(0.3),
            width: isActivo ? 2 : 1,
          ),
          boxShadow: isActivo ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Column(
          children: [
            Icon(icono, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              valor,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.8),
                fontWeight: isActivo ? FontWeight.w600 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (isActivo) ...[
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
    );
  }

  Widget _buildListaHorasExtras(HorasExtrasProvider provider) {
    final rendimientos = provider.rendimientosFiltrados;
    
    if (rendimientos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_off,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No hay rendimientos disponibles',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rendimientos.length,
      itemBuilder: (context, index) {
        final rendimiento = rendimientos[index];
        return _buildHorasCard(rendimiento);
      },
    );
  }

  Widget _buildListaRendimientos(List<HorasExtras> rendimientos) {
    if (rendimientos.isEmpty) {
      final theme = Theme.of(context);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.work_off,
                size: 64,
                color: Colors.grey[400],
              ),
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
              'Los rendimientos aparecerán aquí cuando se carguen datos',
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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rendimientos.length,
      itemBuilder: (context, index) {
        final rendimiento = rendimientos[index];
        return _buildHorasCard(rendimiento);
      },
    );
  }

  Widget _buildHorasCard(HorasExtras rendimiento) {
    final isExpanded = _tarjetasExpandidas.contains(rendimiento.idColaborador);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getEstadoColor(rendimiento.estadoTrabajo).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Header de la tarjeta
            InkWell(
              onTap: () => _alternarExpansion(rendimiento.idColaborador),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getEstadoColor(rendimiento.estadoTrabajo).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getEstadoIcono(rendimiento.estadoTrabajo),
                            color: _getEstadoColor(rendimiento.estadoTrabajo),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rendimiento.colaborador,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? DarkThemeColors.primaryTextColor : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: Colors.purple,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    rendimiento.fechaFormateadaEspanolCompleta,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark ? DarkThemeColors.secondaryTextColor : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${rendimiento.totalHorasFormateadas}h',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _getEstadoColor(rendimiento.estadoTrabajo),
                              ),
                            ),
                            Text(
                              'vs ${rendimiento.horasEsperadasFormateadas}h',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? DarkThemeColors.secondaryTextColor : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                                                         Icon(
                               isExpanded ? Icons.expand_less : Icons.expand_more,
                               color: isDark ? DarkThemeColors.secondaryTextColor : Colors.grey[600],
                             ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getEstadoColor(rendimiento.estadoTrabajo).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.trending_up,
                                size: 16,
                                color: _getEstadoColor(rendimiento.estadoTrabajo),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Diferencia: ${rendimiento.diferenciaHorasFormateadas}h',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _getEstadoColor(rendimiento.estadoTrabajo),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getEstadoColor(rendimiento.estadoTrabajo).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              rendimiento.estadoTexto,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _getEstadoColor(rendimiento.estadoTrabajo),
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
            
            // Contenido expandible
            if (isExpanded) ...[
                             Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: isDark ? DarkThemeColors.containerColor : Colors.grey[50],
                   borderRadius: const BorderRadius.only(
                     bottomLeft: Radius.circular(12),
                     bottomRight: Radius.circular(12),
                   ),
                 ),
                child: _buildDetalleActividades(rendimiento),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetalleActividades(HorasExtras rendimiento) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    if (rendimiento.actividadesDetalle.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No hay actividades detalladas disponibles',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                 Row(
           children: [
                          Icon(
                Icons.list_alt,
                size: 16,
                color: Colors.purple,
              ),
              const SizedBox(width: 8),
                             Text(
                 'Detalle de Actividades (${rendimiento.actividadesDetalle.length})',
                 style: TextStyle(
                   fontWeight: FontWeight.bold,
                   fontSize: 14,
                   color: isDark ? DarkThemeColors.primaryTextColor : Colors.black87,
                 ),
               ),
           ],
         ),
        const SizedBox(height: 12),
        ...rendimiento.actividadesDetalle.map((actividad) => _buildActividadItem(actividad)),
      ],
    );
  }

  Widget _buildActividadItem(ActividadDetalle actividad) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[700] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.grey[600]! : Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                     Row(
             children: [
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                                           Text(
                        actividad.labor.isNotEmpty ? actividad.labor : 'Sin labor',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? DarkThemeColors.primaryTextColor : Colors.black87,
                        ),
                      ),
                     if (actividad.ceco.isNotEmpty) ...[
                       const SizedBox(height: 2),
                       Text(
                         'CECO: ${actividad.ceco}',
                         style: TextStyle(
                           fontSize: 12,
                           color: isDark ? Colors.grey[400] : Colors.grey[600],
                           fontWeight: FontWeight.w500,
                         ),
                       ),
                     ],
                   ],
                 ),
               ),
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                 decoration: BoxDecoration(
                   color: Colors.blue.withOpacity(0.1),
                   borderRadius: BorderRadius.circular(12),
                 ),
                 child: Text(
                   '${actividad.rendimientoFormateado}%',
                   style: TextStyle(
                     fontSize: 12,
                     fontWeight: FontWeight.bold,
                     color: Colors.blue[700],
                   ),
                 ),
               ),
             ],
           ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                                       Icon(Icons.access_time, size: 14, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                   const SizedBox(width: 4),
                   Text(
                     '${actividad.horasTrabajadasFormateadas}h',
                     style: TextStyle(
                       fontSize: 12,
                       color: isDark ? Colors.grey[400] : Colors.grey[600],
                     ),
                   ),
                   const SizedBox(width: 12),
                   Icon(Icons.timer, size: 14, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                   const SizedBox(width: 4),
                   Text(
                     '${actividad.horasExtrasFormateadas}h',
                     style: TextStyle(
                       fontSize: 12,
                       color: isDark ? Colors.grey[400] : Colors.grey[600],
                     ),
                   ),
                  ],
                ),
              ),
                                                               Row(
                    children: [
                                    Icon(Icons.schedule, size: 14, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${actividad.horaInicioFormateada} - ${actividad.horaFinFormateada}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
               ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => _mostrarDialogoAsignarHorasExtras(actividad),
                icon: const Icon(Icons.add_circle, size: 16),
                label: const Text('Asignar Horas Extras'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoAsignarHorasExtras(ActividadDetalle actividad) {
    final TextEditingController horasController = TextEditingController(
      text: actividad.horasExtras.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.add_circle,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Asignar Horas Extras',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                         Text(
               'Actividad: ${actividad.labor.isNotEmpty ? actividad.labor : 'Sin labor'}',
               style: const TextStyle(
                 fontWeight: FontWeight.bold,
                 fontSize: 16,
               ),
             ),
             if (actividad.ceco.isNotEmpty) ...[
               const SizedBox(height: 4),
               Text(
                 'CECO: ${actividad.ceco}',
                 style: TextStyle(
                   fontSize: 14,
                   color: Colors.grey[600],
                 ),
               ),
             ],
            const SizedBox(height: 16),
            TextField(
              controller: horasController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Horas Extras',
                border: OutlineInputBorder(),
                suffixText: 'horas',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Horas actuales: ${actividad.horasExtrasFormateadas}h',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final horasExtras = double.tryParse(horasController.text) ?? 0.0;
              if (horasExtras >= 0) {
                Navigator.of(context).pop();
                await _asignarHorasExtras(actividad, horasExtras);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Las horas extras deben ser un número positivo'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Asignar'),
          ),
        ],
      ),
    );
  }

  Future<void> _asignarHorasExtras(ActividadDetalle actividad, double horasExtras) async {
    try {
      final provider = Provider.of<HorasExtrasProvider>(context, listen: false);
      final success = await provider.asignarHorasExtras(actividad.idActividad, horasExtras);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Horas extras asignadas correctamente: ${horasExtras}h'),
            backgroundColor: Colors.green,
          ),
        );
        // Recargar datos
        await _refrescarDatos();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al asignar horas extras'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toUpperCase()) {
      case 'MÁS':
        return DarkThemeColors.getStateColor(Colors.red);
      case 'MENOS':
        return DarkThemeColors.getStateColor(Colors.red);
      case 'EXACTO':
        return DarkThemeColors.getStateColor(Colors.green);
      default:
        return DarkThemeColors.getStateColor(Colors.grey);
    }
  }

  IconData _getEstadoIcono(String estado) {
    switch (estado.toUpperCase()) {
      case 'MÁS':
        return Icons.arrow_upward;
      case 'MENOS':
        return Icons.arrow_downward;
      case 'EXACTO':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }
}


