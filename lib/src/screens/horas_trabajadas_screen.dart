
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/horas_trabajadas_provider.dart';
import '../providers/auth_provider.dart';
import '../models/horas_trabajadas.dart';
import '../theme/app_theme.dart';
import '../theme/dark_theme_colors.dart';

class HorasTrabajadasScreen extends StatefulWidget {
  const HorasTrabajadasScreen({Key? key}) : super(key: key);

  @override
  State<HorasTrabajadasScreen> createState() => _HorasTrabajadasScreenState();
}

class _HorasTrabajadasScreenState extends State<HorasTrabajadasScreen> {
  String _searchQuery = '';
  bool _showFiltros = false;
  String _filtroActivo = 'todos'; // 'todos', 'mas_horas', 'menos_horas', 'exactas'
  Set<String> _tarjetasExpandidas = {}; // Para controlar qué tarjetas están expandidas
  
  // Variables para agrupación por mes-año
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
    
    final provider = Provider.of<HorasTrabajadasProvider>(context, listen: false);
    switch (filtro) {
      case 'mas_horas':
        provider.setFiltroEstado('MÁS');
        break;
      case 'menos_horas':
        provider.setFiltroEstado('MENOS');
        break;
      case 'exactas':
        provider.setFiltroEstado('EXACTO');
        break;
      default: // 'todos'
        provider.setFiltroEstado('');
        break;
    }
  }

  // Funciones helper para agrupación por mes-año
  void _resetExpansionState(int length) {
    _expansionState = List.generate(length, (index) => true);
  }

  Map<String, List<HorasTrabajadas>> _agruparPorMesAno(List<HorasTrabajadas> horas) {
    final Map<String, List<HorasTrabajadas>> grupos = {};
    
    for (final hora in horas) {
      // Usar el método del modelo para parsear la fecha
      final fecha = _parseFechaModelo(hora.fecha);
      if (fecha != null) {
        final mesAno = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}';
        grupos.putIfAbsent(mesAno, () => []).add(hora);
      } else {
        // Si no se puede parsear la fecha, agrupar como "Sin fecha"
        grupos.putIfAbsent('sin_fecha', () => []).add(hora);
      }
    }
    
    return grupos;
  }

  String _formatearMesAno(String mesAno) {
    if (mesAno == 'sin_fecha') return 'Sin fecha';
    
    try {
      final parts = mesAno.split('-');
      if (parts.length == 2) {
        final anio = int.parse(parts[0]);
        final mes = int.parse(parts[1]);
        
        final meses = [
          '', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
          'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
        ];
        
        return '${meses[mes]} ${anio}';
      }
    } catch (e) {
      // Error al parsear
    }
    
    return mesAno;
  }

  DateTime? _parseFechaModelo(String fechaStr) {
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

  Future<void> _cargarDatosIniciales() async {
    final provider = Provider.of<HorasTrabajadasProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    provider.setAuthProvider(authProvider);
    
    // Usar Future.delayed para evitar el error de setState durante build
    Future.delayed(Duration.zero, () async {
      await provider.cargarHorasTrabajadas();
    });
  }

  Future<void> _refrescarDatos() async {
    final provider = Provider.of<HorasTrabajadasProvider>(context, listen: false);
    await provider.cargarHorasTrabajadas();
  }

  // Método para alternar la expansión de una tarjeta
  void _alternarExpansion(String idTarjeta) {
    setState(() {
      if (_tarjetasExpandidas.contains(idTarjeta)) {
        _tarjetasExpandidas.remove(idTarjeta);
      } else {
        _tarjetasExpandidas.add(idTarjeta);
      }
    });
  }

  // Método para verificar si una tarjeta está expandida
  bool _estaExpandida(String idTarjeta) {
    return _tarjetasExpandidas.contains(idTarjeta);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HorasTrabajadasProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // Barra de búsqueda y filtros
            _buildSearchBar(),
            
            // Estadísticas
            _buildEstadisticas(provider),
            
            // Lista de horas trabajadas
            Expanded(
              child: _buildListaHorasTrabajadas(provider),
            ),
          ],
        );
      },
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
      child: Column(
        children: [
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              final provider = Provider.of<HorasTrabajadasProvider>(context, listen: false);
              provider.setFiltroBusqueda(value);
            },
            decoration: InputDecoration(
              hintText: 'Buscar por colaborador, fecha o día...',
              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                        final provider = Provider.of<HorasTrabajadasProvider>(context, listen: false);
                        provider.setFiltroBusqueda('');
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
    return Consumer<HorasTrabajadasProvider>(
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
                      decoration: const InputDecoration(
                        labelText: 'Colaborador',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Todos los estados'),
                        ),
                        ...provider.estadosUnicos.map((estado) {
                          return DropdownMenuItem<String>(
                            value: estado,
                            child: Text(estado),
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
                        provider.cargarHorasTrabajadas();
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          value != null
              ? '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}'
              : 'Seleccionar fecha',
          style: TextStyle(
            color: value != null ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildEstadisticas(HorasTrabajadasProvider provider) {
    final stats = provider.estadisticas;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildTarjetaEstadistica(
              titulo: 'Más Horas',
              valor: stats['mas_horas'].toString(),
              color: Colors.red,
              icono: Icons.arrow_upward,
              filtro: 'mas_horas',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTarjetaEstadistica(
              titulo: 'Menos Horas',
              valor: stats['menos_horas'].toString(),
              color: Colors.red,
              icono: Icons.arrow_downward,
              filtro: 'menos_horas',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTarjetaEstadistica(
              titulo: 'Exactas',
              valor: stats['exactas'].toString(),
              color: Colors.green,
              icono: Icons.check_circle,
              filtro: 'exactas',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTarjetaEstadistica(
              titulo: 'Total',
              valor: stats['total'].toString(),
              color: Colors.orange,
              icono: Icons.list,
              filtro: 'todos',
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

  Widget _buildListaHorasTrabajadas(HorasTrabajadasProvider provider) {
    
    if (provider.horasTrabajadasFiltradas.isEmpty) {
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
                Icons.hourglass_empty,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay registros de horas trabajadas',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Los registros aparecerán aquí cuando se carguen datos',
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

    // Agrupar por mes-año
    final gruposPorMesAno = _agruparPorMesAno(provider.horasTrabajadasFiltradas);
    final mesesOrdenados = gruposPorMesAno.keys.toList()..sort((a, b) {
      if (a == 'sin_fecha') return 1;
      if (b == 'sin_fecha') return -1;
      return b.compareTo(a); // Orden descendente (más reciente primero)
    });

    // Resetear estado de expansión si es necesario
    if (_expansionState.length != mesesOrdenados.length) {
      _resetExpansionState(mesesOrdenados.length);
    }

    return ListView.builder(
      key: _expansionKey,
      padding: const EdgeInsets.all(16),
      itemCount: mesesOrdenados.length,
      itemBuilder: (context, index) {
        final mesAno = mesesOrdenados[index];
        final horas = gruposPorMesAno[mesAno]!;
        final expanded = (_expansionState.length > index) ? _expansionState[index] : true;

        return ExpansionTile(
          initiallyExpanded: expanded,
          onExpansionChanged: (isExpanded) {
            if (_expansionState.length > index) {
              setState(() {
                _expansionState[index] = isExpanded;
              });
            }
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 0),
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          collapsedBackgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]
              : Colors.grey[100],
          backgroundColor: Theme.of(context).colorScheme.surface,
          iconColor: AppTheme.primaryColor,
          collapsedIconColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          title: Row(
            children: [
              Icon(
                Icons.calendar_month,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _formatearMesAno(mesAno),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${horas.length}',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          children: horas.map((hora) => _buildHorasCard(hora)).toList(),
        );
      },
    );
  }

  Widget _buildHorasCard(HorasTrabajadas hora) {
    final idTarjeta = '${hora.idColaborador}_${hora.fecha}';
    final estaExpandida = _estaExpandida(idTarjeta);
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
        onTap: () => _alternarExpansion(idTarjeta),
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
                      color: _getEstadoColor(hora.estadoTrabajo).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      _getEstadoIcono(hora.estadoTrabajo),
                      color: _getEstadoColor(hora.estadoTrabajo),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      hora.colaborador,
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
                                'Fecha: ${hora.fechaFormateadaEspanolCompleta}',
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
                                'Trabajadas: ${hora.totalHorasFormateadas}h',
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
                                'Esperadas: ${hora.horasEsperadasFormateadas}h',
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
                  // Columna 4: Diferencia
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.trending_up, color: Colors.green, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Diferencia: ${hora.diferenciaHorasFormateadas}h',
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
                  // Columna 5: Estado y acciones
                  Expanded(
                    flex: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getEstadoColor(hora.estadoTrabajo).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            hora.estadoTexto,
                            style: TextStyle(
                              color: _getEstadoColor(hora.estadoTrabajo),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          estaExpandida ? Icons.expand_less : Icons.expand_more,
                          color: _getEstadoColor(hora.estadoTrabajo),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Sección expandible con detalles de actividades
              if (estaExpandida) ...[
                const SizedBox(height: 16),
                _buildDetalleActividades(hora),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetalleActividades(HorasTrabajadas hora) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getEstadoColor(hora.estadoTrabajo).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del detalle
          Row(
            children: [
              Icon(
                Icons.list_alt,
                size: 20,
                color: _getEstadoColor(hora.estadoTrabajo),
              ),
              const SizedBox(width: 8),
              Text(
                'Detalle de Actividades',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _getEstadoColor(hora.estadoTrabajo),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getEstadoColor(hora.estadoTrabajo).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${hora.cantidadActividades} actividades',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _getEstadoColor(hora.estadoTrabajo),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
                     // Información resumida
           Container(
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(
               color: isDark ? Colors.grey[700] : Colors.white,
               borderRadius: BorderRadius.circular(8),
               border: Border.all(color: isDark ? Colors.grey[600]! : Colors.grey[300]!),
             ),
                         child: Row(
               children: [
                 Expanded(
                   child: _buildInfoResumen('Horas Trabajadas', '${hora.totalHorasTrabajadasFormateadas}h', Icons.access_time, Colors.blue),
                 ),
                 Expanded(
                   child: _buildInfoResumen('Horas Extras', '${hora.totalHorasExtrasFormateadas}h', Icons.add_circle, Colors.orange),
                 ),
                 Expanded(
                   child: _buildInfoResumen('Horas Esperadas', '${hora.horasEsperadasFormateadas}h', Icons.timer, Colors.green),
                 ),
               ],
             ),
          ),
          const SizedBox(height: 16),
          
          // Lista de actividades
          if (hora.actividadesDetalle.isNotEmpty) ...[
                         Text(
               'Actividades realizadas:',
               style: TextStyle(
                 fontWeight: FontWeight.w600,
                 fontSize: 14,
                 color: isDark ? Colors.grey[300] : Colors.grey[700],
               ),
             ),
            const SizedBox(height: 12),
                         ...hora.actividadesDetalle.map((actividad) => _buildActividadItem(actividad)),
          ] else ...[
                         Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: isDark ? Colors.grey[700] : Colors.grey[100],
                 borderRadius: BorderRadius.circular(8),
               ),
               child: Row(
                 children: [
                   Icon(Icons.info_outline, size: 16, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                   const SizedBox(width: 8),
                   Text(
                     'No hay detalles de actividades disponibles',
                     style: TextStyle(
                       fontSize: 14,
                       color: isDark ? Colors.grey[400] : Colors.grey[600],
                     ),
                   ),
                 ],
               ),
             ),
          ],
        ],
      ),
    );
  }

           Widget _buildInfoResumen(String label, String value, IconData icon, [Color? color]) {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      final iconColor = color ?? (isDark ? Colors.grey[400]! : Colors.grey[600]!);
      final textColor = color ?? (isDark ? Colors.grey[200]! : Colors.grey[800]!);
      
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color?.withOpacity(0.1) ?? (isDark ? Colors.grey[600] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(8),
        ),
       child: Column(
         children: [
           Icon(icon, size: 16, color: iconColor),
           const SizedBox(height: 4),
           Text(
             value,
             style: TextStyle(
               fontSize: 14,
               fontWeight: FontWeight.bold,
               color: textColor,
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

  Color _getEstadoColor(String estado) {
    final theme = Theme.of(context);
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

       // Método para obtener el color del estado de una actividad
    Color _getActividadEstadoColor(ActividadDetalle actividad) {
      final theme = Theme.of(context);
      // Basado en el rendimiento para determinar el estado
      if (actividad.rendimiento >= 95 && actividad.rendimiento <= 105) {
        return DarkThemeColors.getStateColor(Colors.green); // EXACTO
      } else if (actividad.rendimiento > 105) {
        return DarkThemeColors.getStateColor(Colors.red); // MÁS
      } else {
        return DarkThemeColors.getStateColor(Colors.red); // MENOS
      }
    }

   // Método para obtener el texto del estado de una actividad
   String _getActividadEstadoTexto(ActividadDetalle actividad) {
     // Basado en el rendimiento para determinar el estado
     if (actividad.rendimiento >= 95 && actividad.rendimiento <= 105) {
       return 'EXACTO';
     } else if (actividad.rendimiento > 105) {
       return 'MÁS';
     } else {
       return 'MENOS';
     }
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
                        // Header de la actividad
             Row(
               children: [
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                                              Text(
                          actividad.labor.isNotEmpty ? actividad.labor : 'Sin labor',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
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
                           const SizedBox(height: 2),
                           Text(
                             'Rendimiento: ${actividad.rendimientoFormateado}',
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
                 Row(
                   children: [
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                       decoration: BoxDecoration(
                         color: _getActividadEstadoColor(actividad).withOpacity(0.1),
                         borderRadius: BorderRadius.circular(12),
                       ),
                       child: Text(
                         _getActividadEstadoTexto(actividad),
                         style: TextStyle(
                           fontSize: 12,
                           fontWeight: FontWeight.w500,
                           color: _getActividadEstadoColor(actividad),
                         ),
                       ),
                     ),
                     const SizedBox(width: 8),
                                           IconButton(
                        icon: Icon(Icons.edit, size: 16, color: Colors.green),
                        onPressed: () => _mostrarDialogoEditarHoras(actividad),
                        tooltip: 'Editar horas',
                      ),


                   ],
                 ),
               ],
             ),
                       const SizedBox(height: 8),
            
                         // Información de horario
             Row(
               children: [
                 Expanded(
                   child: Text(
                     'Horario: ${actividad.horaInicioFormateada} - ${actividad.horaFinFormateada}',
                     style: TextStyle(
                       fontSize: 12,
                       color: isDark ? Colors.grey[400] : Colors.grey[600],
                     ),
                   ),
                 ),
               ],
             ),
            const SizedBox(height: 8),
           
           // Información de horas - Solo Horas Trabajadas
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
             ],
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

    // Método para mostrar diálogo de edición de horas
    void _mostrarDialogoEditarHoras(ActividadDetalle actividad) {
      final horasTrabajadasController = TextEditingController(
        text: actividad.horasTrabajadas.toString(),
      );
      final horasExtrasController = TextEditingController(
        text: actividad.horasExtras.toString(),
      );
      final formKey = GlobalKey<FormState>();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Editar Horas Trabajadas'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Actividad: ${actividad.labor}',
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
                TextFormField(
                  controller: horasTrabajadasController,
                  decoration: const InputDecoration(
                    labelText: 'Horas Trabajadas',
                    border: OutlineInputBorder(),
                    suffixText: 'horas',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese las horas trabajadas';
                    }
                    final horas = double.tryParse(value);
                    if (horas == null || horas < 0) {
                      return 'Ingrese un valor válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: horasExtrasController,
                  decoration: const InputDecoration(
                    labelText: 'Horas Extras',
                    border: OutlineInputBorder(),
                    suffixText: 'horas',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese las horas extras';
                    }
                    final horas = double.tryParse(value);
                    if (horas == null || horas < 0) {
                      return 'Ingrese un valor válido';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context);
                  
                  final horasTrabajadas = double.parse(horasTrabajadasController.text);
                  final horasExtras = double.parse(horasExtrasController.text);
                  
                  final provider = Provider.of<HorasTrabajadasProvider>(context, listen: false);
                                     final response = await provider.actualizarHorasColaborador(
                     rendimientoId: actividad.rendimientoId,
                     horasTrabajadas: horasTrabajadas,
                     horasExtras: horasExtras,
                   );
                  
                  if (response != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Horas actualizadas correctamente'),
                        backgroundColor: AppTheme.successColor,
                        duration: const Duration(seconds: 3),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al actualizar horas: ${provider.error}'),
                        backgroundColor: AppTheme.errorColor,
                        duration: const Duration(seconds: 4),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      );
    }
}
