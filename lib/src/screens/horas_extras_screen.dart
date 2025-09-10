import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/horas_extras_provider.dart';
import '../providers/horas_trabajadas_provider.dart';
import '../providers/tarja_provider.dart';
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
  
  // Variables para agrupación por mes-año
  Map<String, List<HorasExtras>> _horasExtrasAgrupadas = {};
  List<String> _mesesAnos = [];

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  bool _tieneFiltrosActivos(HorasExtrasProvider provider) {
    return provider.filtroColaborador.isNotEmpty ||
           provider.filtroMes != null ||
           provider.filtroAno != null;
  }

  void _aplicarFiltro(String filtro) {
    setState(() {
      _filtroActivo = filtro;
    });
    
    final provider = Provider.of<HorasExtrasProvider>(context, listen: false);
    provider.setFiltroEstado(filtro);
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
    // Actualizar todos los providers relevantes
    final horasExtrasProvider = Provider.of<HorasExtrasProvider>(context, listen: false);
    final horasTrabajadasProvider = Provider.of<HorasTrabajadasProvider>(context, listen: false);
    final tarjaProvider = Provider.of<TarjaProvider>(context, listen: false);
    
    // Cargar datos en paralelo para mejor rendimiento
    await Future.wait([
      horasExtrasProvider.cargarRendimientos(),
      horasTrabajadasProvider.cargarHorasTrabajadas(),
      tarjaProvider.cargarTarjas(),
    ]);
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

  // Función para parsear fechas (similar a horas trabajadas)
  DateTime? _parseFecha(String fechaStr) {
    try {
      // Intentar parsear como ISO primero
      return DateTime.parse(fechaStr);
    } catch (e) {
      try {
        // Si falla, intentar con el formato específico del backend
        // "Mon, 18 Aug 2025 00:00:00 GMT"
        final regex = RegExp(r'(\w{3}), (\d{1,2}) (\w{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2}) GMT');
        final match = regex.firstMatch(fechaStr);
        
        if (match != null) {
          final day = int.parse(match.group(2)!);
          final monthStr = match.group(3)!;
          final year = int.parse(match.group(4)!);
          final hour = int.parse(match.group(5)!);
          final minute = int.parse(match.group(6)!);
          final second = int.parse(match.group(7)!);
          
          // Mapear nombres de meses a números
          final monthMap = {
            'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
            'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
          };
          
          final month = monthMap[monthStr];
          if (month != null) {
            return DateTime(year, month, day, hour, minute, second);
          }
        }
        return null;
      } catch (e) {
        return null;
      }
    }
  }

  // Función para formatear mes-año
  String _formatearMesAno(DateTime fecha) {
    final meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${meses[fecha.month - 1]} ${fecha.year}';
  }

  // Función para agrupar por mes-año
  void _agruparPorMesAno(List<HorasExtras> horasExtras) {
    _horasExtrasAgrupadas.clear();
    _mesesAnos.clear();
    
    for (final hora in horasExtras) {
      final fecha = _parseFecha(hora.fecha);
      if (fecha != null) {
        final mesAno = _formatearMesAno(fecha);
        if (!_horasExtrasAgrupadas.containsKey(mesAno)) {
          _horasExtrasAgrupadas[mesAno] = [];
          _mesesAnos.add(mesAno);
        }
        _horasExtrasAgrupadas[mesAno]!.add(hora);
      }
    }
    
    // Ordenar meses de más reciente a más antiguo
    _mesesAnos.sort((a, b) {
      final fechaA = _parseFecha(_horasExtrasAgrupadas[a]!.first.fecha);
      final fechaB = _parseFecha(_horasExtrasAgrupadas[b]!.first.fecha);
      if (fechaA != null && fechaB != null) {
        return fechaB.compareTo(fechaA);
      }
      return 0;
    });
  }

  // Función para resetear estado de expansión
  void _resetExpansionState() {
    _expansionState = List.filled(_mesesAnos.length, false);
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
                flex: 4,
                child: Consumer<HorasExtrasProvider>(
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
                          backgroundColor: tieneFiltrosActivos ? Colors.orange : AppTheme.primaryColor,
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiltrosAvanzados() {
    return Consumer<HorasExtrasProvider>(
      builder: (context, provider, child) {
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
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: provider.filtroMes,
                      decoration: const InputDecoration(
                        labelText: 'Mes',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('Todos los meses'),
                        ),
                        ...provider.mesesUnicos.map((mes) {
                          final nombresMeses = [
                            '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
                            'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
                          ];
                          return DropdownMenuItem<int>(
                            value: mes,
                            child: Text(nombresMeses[mes]),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        provider.setFiltroMes(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: provider.filtroAno,
                      decoration: const InputDecoration(
                        labelText: 'Año',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('Todos los años'),
                        ),
                        ...provider.anosUnicos.map((ano) {
                          return DropdownMenuItem<int>(
                            value: ano,
                            child: Text(ano.toString()),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        provider.setFiltroAno(value);
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

    // Agrupar por mes-año
    _agruparPorMesAno(rendimientos);
    _resetExpansionState();

    return _buildListaHorasExtrasAgrupadas();
  }

  Widget _buildListaHorasExtrasAgrupadas() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _mesesAnos.length,
      itemBuilder: (context, index) {
        final mesAno = _mesesAnos[index];
        final horasExtras = _horasExtrasAgrupadas[mesAno]!;
        
        return ExpansionTile(
          key: ValueKey(mesAno),
          initiallyExpanded: true,
          onExpansionChanged: (expanded) {
            setState(() {
              if (index < _expansionState.length) {
                _expansionState[index] = expanded;
              }
            });
          },
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          shape: Border(),
          collapsedShape: Border(),
          collapsedIconColor: AppTheme.primaryColor,
          iconColor: AppTheme.primaryColor,
          title: Row(
            children: [
              Icon(
                Icons.calendar_month,
                size: 20,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                mesAno,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${horasExtras.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          children: horasExtras.map((hora) => _buildHorasCard(hora)).toList(),
        );
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
    final cardColor = theme.colorScheme.surface;
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
        onTap: () => _alternarExpansion(rendimiento.idColaborador),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título de la actividad
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: _getColorHorasExtras(rendimiento.totalHorasExtras).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.person,
                      color: _getColorHorasExtras(rendimiento.totalHorasExtras),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      rendimiento.colaborador,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Columna 1: Fecha
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.purple, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Fecha: ${rendimiento.fechaFormateadaEspanolCompleta}',
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
                  // Columna 2: Horas trabajadas
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.access_time, color: Colors.orange, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Trabajadas: ${rendimiento.totalHorasFormateadas}h',
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
                  // Columna 3: Horas esperadas
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.schedule, color: Colors.blue, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Esperadas: ${rendimiento.horasEsperadasFormateadas}h',
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
                  // Columna 4: Horas extras
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.add_circle_outline, 
                              color: _getColorHorasExtras(rendimiento.totalHorasExtras), 
                              size: 16
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Extras: ${rendimiento.totalHorasExtras.toStringAsFixed(1)}h',
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
                ],
              ),
              
              // Contenido expandible
              if (isExpanded) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? DarkThemeColors.containerColor : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildDetalleActividades(rendimiento),
                ),
              ],
            ],
          ),
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
                     if (actividad.nombreCeco.isNotEmpty) ...[
                       const SizedBox(height: 2),
                       Text(
                         'CECO: ${actividad.nombreCeco}',
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
             ],
           ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildActividadInfo(
                  'Horas Trabajadas',
                  '${actividad.horasTrabajadasFormateadas}h',
                  Icons.access_time,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActividadInfo(
                  'Horas Extras',
                  '${actividad.horasExtrasFormateadas}h',
                  Icons.timer,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
             if (actividad.nombreCeco.isNotEmpty) ...[
               const SizedBox(height: 4),
               Text(
                 'CECO: ${actividad.nombreCeco}',
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
              
              // Validaciones
              if (horasExtras < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Las horas extras deben ser un número positivo'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              if (horasExtras > 2.0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('El máximo legal de horas extras en Chile es de 2 horas por día'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              
              Navigator.of(context).pop();
              await _asignarHorasExtras(actividad, horasExtras);
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

  Widget _buildActividadInfo(String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.2) : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _asignarHorasExtras(ActividadDetalle actividad, double horasExtras) async {
    try {
      final provider = Provider.of<HorasExtrasProvider>(context, listen: false);
      final success = await provider.asignarHorasExtras(actividad.idRendimiento, horasExtras);
      
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
        final errorMessage = provider.error ?? 'Error desconocido';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al asignar horas extras: $errorMessage'),
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

  // Función para determinar el color según las horas extras y límite legal
  Color _getColorHorasExtras(double horasExtras) {
    if (horasExtras <= 0) {
      return Colors.red; // No hay horas extras
    } else if (horasExtras <= 2.0) {
      return Colors.green; // Horas extras legales (máximo 2h por día)
    } else {
      return Colors.orange; // Excede el límite legal (más de 2h por día)
    }
  }
}


