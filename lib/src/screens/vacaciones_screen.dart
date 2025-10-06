import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/vacacion.dart';
import '../models/colaborador.dart';
import '../providers/auth_provider.dart';
import '../providers/vacacion_provider.dart';
import '../providers/colaborador_provider.dart';
import '../providers/horas_trabajadas_provider.dart';
import '../providers/horas_extras_provider.dart';
import '../providers/tarja_provider.dart';
import '../theme/app_theme.dart';
import '../theme/dark_theme_colors.dart';
import '../services/api_service.dart';
import 'vacacion_crear_screen.dart';
import 'vacacion_editar_screen.dart';

class VacacionesScreen extends StatefulWidget {
  const VacacionesScreen({super.key});

  @override
  State<VacacionesScreen> createState() => _VacacionesScreenState();
}

class _VacacionesScreenState extends State<VacacionesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showFiltros = false;
  String _filtroActivo = 'todos'; // 'todos', 'programadas', 'en_curso', 'completadas'
  
  // Variables para agrupación
  List<bool> _expansionState = [];
  final GlobalKey _expansionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  void _cargarDatosIniciales() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final vacacionProvider = context.read<VacacionProvider>();
      final colaboradorProvider = context.read<ColaboradorProvider>();
      
      // Configurar el VacacionProvider para escuchar cambios de sucursal
      vacacionProvider.setAuthProvider(authProvider);
      colaboradorProvider.setAuthProvider(authProvider);
      
      // Cargar datos
      vacacionProvider.cargarVacaciones();
      colaboradorProvider.cargarColaboradores();
    });
  }

  // Método para refrescar datos desde el AppBar
  Future<void> _refrescarDatos() async {
    // Actualizar todos los providers relevantes
    final vacacionProvider = Provider.of<VacacionProvider>(context, listen: false);
    final colaboradorProvider = Provider.of<ColaboradorProvider>(context, listen: false);
    final horasTrabajadasProvider = Provider.of<HorasTrabajadasProvider>(context, listen: false);
    final horasExtrasProvider = Provider.of<HorasExtrasProvider>(context, listen: false);
    final tarjaProvider = Provider.of<TarjaProvider>(context, listen: false);
    
    // Cargar datos en paralelo para mejor rendimiento
    await Future.wait([
      vacacionProvider.cargarVacaciones(),
      colaboradorProvider.cargarColaboradores(),
      horasTrabajadasProvider.cargarHorasTrabajadas(),
      horasExtrasProvider.cargarRendimientos(),
      tarjaProvider.cargarTarjas(),
    ]);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _aplicarFiltro(String filtro) {
    setState(() {
      _filtroActivo = filtro;
    });
    
    final vacacionProvider = context.read<VacacionProvider>();
    switch (filtro) {
      case 'programadas':
        vacacionProvider.setFiltroEstado('Programada');
        break;
      case 'en_curso':
        vacacionProvider.setFiltroEstado('En curso');
        break;
      case 'completadas':
        vacacionProvider.setFiltroEstado('Completada');
        break;
      default: // 'todos'
        vacacionProvider.setFiltroEstado('todos');
        break;
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
    final vacacionProvider = context.read<VacacionProvider>();
    vacacionProvider.setFiltroBusqueda(query);
  }

  bool _tieneFiltrosActivos(VacacionProvider vacacionProvider) {
    return vacacionProvider.filtroColaborador != null ||
           vacacionProvider.filtroMes != null ||
           vacacionProvider.filtroAno != null;
  }

  // Funciones para agrupación
  void _resetExpansionState(int groupCount) {
    _expansionState = List.generate(groupCount, (index) => true);
  }

  Map<String, List<Vacacion>> _agruparPorMesAno(List<Vacacion> vacaciones) {
    final grupos = <String, List<Vacacion>>{};
    for (var vacacion in vacaciones) {
      final fecha = vacacion.fechaInicio;
      if (fecha != null && fecha.isNotEmpty) {
        // Usar el método _parseFecha del modelo Vacacion
        final date = _parseFecha(fecha);
        if (date != null) {
          final mesAno = '${date.year}-${date.month.toString().padLeft(2, '0')}';
          if (!grupos.containsKey(mesAno)) {
            grupos[mesAno] = [];
          }
          grupos[mesAno]!.add(vacacion);
        } else {
          // Si no se puede parsear la fecha, usar 'Sin fecha'
          const mesAno = 'Sin fecha';
          if (!grupos.containsKey(mesAno)) {
            grupos[mesAno] = [];
          }
          grupos[mesAno]!.add(vacacion);
        }
      } else {
        // Si no hay fecha, usar 'Sin fecha'
        const mesAno = 'Sin fecha';
        if (!grupos.containsKey(mesAno)) {
          grupos[mesAno] = [];
        }
        grupos[mesAno]!.add(vacacion);
      }
    }
    return grupos;
  }

  // Método para parsear fechas (copiado del modelo Vacacion)
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

  String _formatearMesAno(String mesAno) {
    if (mesAno == 'Sin fecha') return 'Sin fecha';
    try {
      final parts = mesAno.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      
      final meses = [
        'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
      ];
      
      return '${meses[month - 1]} $year';
    } catch (e) {
      return mesAno;
    }
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
              hintText: 'Buscar por colaborador o período',
              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                        setState(() {
                          _filtroActivo = 'todos';
                        });
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
                flex: 4,
                child: Consumer<VacacionProvider>(
                  builder: (context, vacacionProvider, child) {
                    final tieneFiltrosActivos = _tieneFiltrosActivos(vacacionProvider);
                    
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
              Expanded(
                flex: 1,
                child: ElevatedButton.icon(
                  onPressed: () => _mostrarDialogoCrearVacacion(),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Nueva', style: TextStyle(fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
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
    return Consumer2<VacacionProvider, ColaboradorProvider>(
      builder: (context, vacacionProvider, colaboradorProvider, child) {
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
                      value: vacacionProvider.filtroColaborador,
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
                        ...colaboradorProvider.colaboradoresActivosList.map((colaborador) {
                          return DropdownMenuItem<String>(
                            value: colaborador.id,
                            child: Text(colaborador.nombreCompleto),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        vacacionProvider.setFiltroColaborador(value);
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
                      value: vacacionProvider.filtroMes,
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
                        ...vacacionProvider.mesesUnicos.map((mes) {
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
                        vacacionProvider.setFiltroMes(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: vacacionProvider.filtroAno,
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
                        ...vacacionProvider.anosUnicos.map((ano) {
                          return DropdownMenuItem<int>(
                            value: ano,
                            child: Text(ano.toString()),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        vacacionProvider.setFiltroAno(value);
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
                        vacacionProvider.limpiarFiltros();
                        _searchController.clear();
                        _onSearchChanged('');
                        setState(() {
                          _filtroActivo = 'todos';
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
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEstadisticas() {
    return Consumer<VacacionProvider>(
      builder: (context, vacacionProvider, child) {
        return Container(
          margin: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildTarjetaEstadistica(
                  'Total',
                  vacacionProvider.totalVacaciones.toString(),
                  Icons.beach_access,
                  Colors.purple,
                  'todos',
                  vacacionProvider.totalVacaciones > 0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTarjetaEstadistica(
                  'Programadas',
                  vacacionProvider.vacacionesProgramadas.toString(),
                  Icons.schedule,
                  Colors.blue,
                  'programadas',
                  vacacionProvider.vacacionesProgramadas > 0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTarjetaEstadistica(
                  'En curso',
                  vacacionProvider.vacacionesEnCurso.toString(),
                  Icons.play_circle,
                  Colors.orange,
                  'en_curso',
                  vacacionProvider.vacacionesEnCurso > 0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTarjetaEstadistica(
                  'Completadas',
                  vacacionProvider.vacacionesCompletadas.toString(),
                  Icons.check_circle,
                  Colors.green,
                  'completadas',
                  vacacionProvider.vacacionesCompletadas > 0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTarjetaEstadistica(String titulo, String valor, IconData icono, Color color, String filtro, bool tieneDatos) {
    final isActivo = _filtroActivo == filtro;
    
    return GestureDetector(
      onTap: () => _aplicarFiltro(filtro),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActivo ? color.withOpacity(0.2) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActivo ? color : Colors.grey.withOpacity(0.3),
            width: isActivo ? 2 : 1,
          ),
          boxShadow: isActivo ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActivo ? color.withOpacity(0.3) : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icono, color: isActivo ? color : color.withOpacity(0.8), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 12,
                      color: isActivo ? color : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    valor,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isActivo ? color : Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVacacionCard(Vacacion vacacion) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.colorScheme.surface;
    // Color del borde según el estado de la vacación
    Color borderColor;
    switch (vacacion.estadoColor) {
      case 'orange':
        borderColor = Colors.orange[300]!;
        break;
      case 'blue':
        borderColor = Colors.blue[300]!;
        break;
      case 'green':
        borderColor = Colors.green[300]!;
        break;
      default:
        borderColor = Colors.grey[300]!;
    }
    final textColor = theme.colorScheme.onSurface;

    // Determinar color del estado
    Color estadoColor;
    switch (vacacion.estadoColor) {
      case 'orange':
        estadoColor = Colors.orange;
        break;
      case 'blue':
        estadoColor = Colors.blue;
        break;
      case 'green':
        estadoColor = Colors.green;
        break;
      default:
        estadoColor = Colors.grey;
    }

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: borderColor, width: 1),
      ),
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _mostrarDetallesVacacion(vacacion),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título de la vacación
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: estadoColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.beach_access,
                      color: estadoColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      vacacion.nombreCompletoColaborador,
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
              // Contenido en 4 columnas
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Columna 1: Duración
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.schedule, color: Colors.purple, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Duración: ${vacacion.duracionTexto}',
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
                  // Columna 2: Fecha inicio
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.green, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Inicio: ${vacacion.fechaInicioFormateadaEspanol}',
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
                  // Columna 3: Fecha fin
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.event, color: Colors.red, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Fin: ${vacacion.fechaFinFormateadaEspanol}',
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
                  // Columna 4: Estado, Editar, Eliminar
                  Expanded(
                    flex: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: estadoColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: estadoColor,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            vacacion.estado,
                            style: TextStyle(
                              color: estadoColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _mostrarDialogoEditarVacacion(vacacion),
                          icon: Icon(Icons.edit, color: AppTheme.primaryColor, size: 20),
                          tooltip: 'Editar vacación',
                        ),
                        IconButton(
                          onPressed: () => _confirmarEliminarVacacion(vacacion),
                          icon: Icon(Icons.delete, color: Colors.red, size: 20),
                          tooltip: 'Eliminar vacación',
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

  void _mostrarDetallesVacacion(Vacacion vacacion) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surface.withOpacity(0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header moderno
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.beach_access,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detalles de Vacación',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            vacacion.nombreCompletoColaborador,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              
              // Contenido
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Información del colaborador
                      _buildModernInfoRow('Colaborador', vacacion.nombreCompletoColaborador, Icons.person),
                      
                      // Información del período
                      _buildModernInfoRow('Período', vacacion.periodoFormateadoEspanol, Icons.calendar_today),
                      _buildModernInfoRow('Duración', vacacion.duracionTexto, Icons.schedule),
                      
                      // Estado
                      _buildModernInfoRow('Estado', vacacion.estado, Icons.info),
                      
                      // Fechas
                      _buildModernInfoRow('Fecha Inicio', vacacion.fechaInicioFormateadaEspanol, Icons.play_arrow),
                      _buildModernInfoRow('Fecha Fin', vacacion.fechaFinFormateadaEspanol, Icons.stop),
                    ],
                  ),
                ),
              ),
              
              // Botones de acción
              Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text('Cerrar', style: TextStyle(color: Colors.red)),
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
                          Navigator.pop(context);
                          _mostrarDialogoEditarVacacion(vacacion);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar'),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernInfoRow(String label, String value, IconData icon) {
    Color iconColor;
    Color backgroundColor;
    
    if (icon == Icons.person) {
      iconColor = Colors.blue;
      backgroundColor = Colors.blue.withOpacity(0.1);
    } else if (icon == Icons.calendar_today) {
      iconColor = Colors.orange;
      backgroundColor = Colors.orange.withOpacity(0.1);
    } else if (icon == Icons.schedule) {
      iconColor = Colors.green;
      backgroundColor = Colors.green.withOpacity(0.1);
    } else if (icon == Icons.info) {
      iconColor = Colors.purple;
      backgroundColor = Colors.purple.withOpacity(0.1);
    } else if (icon == Icons.play_arrow) {
      iconColor = Colors.green;
      backgroundColor = Colors.green.withOpacity(0.1);
    } else if (icon == Icons.stop) {
      iconColor = Colors.red;
      backgroundColor = Colors.red.withOpacity(0.1);
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

  void _mostrarDialogoCrearVacacion() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const VacacionCrearScreen(),
      ),
    );
    
    // Si se creó exitosamente una vacación, refrescar la lista
    if (result == true) {
      final vacacionProvider = context.read<VacacionProvider>();
      await vacacionProvider.cargarVacaciones();
    }
  }

  void _mostrarDialogoEditarVacacion(Vacacion vacacion) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VacacionEditarScreen(vacacion: vacacion),
      ),
    );
    
    // Si se editó exitosamente una vacación, refrescar la lista
    if (result == true) {
      final vacacionProvider = context.read<VacacionProvider>();
      await vacacionProvider.cargarVacaciones();
    }
  }

  void _confirmarEliminarVacacion(Vacacion vacacion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Estás seguro de que quieres eliminar la vacación de ${vacacion.nombreCompletoColaborador}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final vacacionProvider = context.read<VacacionProvider>();
              final success = await vacacionProvider.eliminarVacacion(vacacion.id);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vacación eliminada correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al eliminar: ${vacacionProvider.error}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
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
          child: Consumer<VacacionProvider>(
            builder: (context, vacacionProvider, child) {
              if (vacacionProvider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (vacacionProvider.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 80,
                        color: Colors.red.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar vacaciones',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        vacacionProvider.error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.red.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => vacacionProvider.cargarVacaciones(),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }

              final vacacionesFiltradas = vacacionProvider.vacacionesFiltradas;

              if (vacacionesFiltradas.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.beach_access_outlined,
                        size: 80,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay vacaciones',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Agrega la primera vacación para comenzar',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _mostrarDialogoCrearVacacion(),
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar Vacación'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return _buildListaVacaciones(vacacionProvider);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildListaVacaciones(VacacionProvider vacacionProvider) {
    final vacacionesFiltradas = vacacionProvider.vacacionesFiltradas.isNotEmpty 
        ? vacacionProvider.vacacionesFiltradas 
        : vacacionProvider.vacaciones;
    final gruposPorMesAno = _agruparPorMesAno(vacacionesFiltradas);
    final mesesOrdenados = gruposPorMesAno.keys.toList()..sort((a, b) {
      if (a == 'Sin fecha') return 1;
      if (b == 'Sin fecha') return -1;
      return b.compareTo(a); // Orden descendente (más reciente primero)
    });

    // Solo reiniciar expansión si cambió la cantidad de grupos
    if (_expansionState.length != mesesOrdenados.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _resetExpansionState(mesesOrdenados.length);
      });
    }

    if (vacacionProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (vacacionProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              vacacionProvider.error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => vacacionProvider.cargarVacaciones(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    
    if (vacacionesFiltradas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.filter_list,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty 
                ? 'No se encontraron vacaciones que coincidan con "$_searchQuery"'
                : 'No hay vacaciones que coincidan con los filtros',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
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
      children: List.generate(mesesOrdenados.length, (i) {
        final mesAno = mesesOrdenados[i];
        final vacaciones = gruposPorMesAno[mesAno]!;
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
              initiallyExpanded: true,
              onExpansionChanged: (isExpanded) {
                if (_expansionState.length > i) {
                  setState(() {
                    _expansionState[i] = isExpanded;
                  });
                }
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
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatearMesAno(mesAno),
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
                      '${vacaciones.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              children: vacaciones.map((vacacion) => _buildVacacionCard(vacacion)).toList(),
            ),
          ),
        );
      }),
    );
  }
}
