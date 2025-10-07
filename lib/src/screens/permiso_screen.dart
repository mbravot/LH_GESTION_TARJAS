import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/permiso_provider.dart';
import '../providers/colaborador_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/horas_trabajadas_provider.dart';
import '../providers/horas_extras_provider.dart';
import '../providers/tarja_provider.dart';
import '../models/permiso.dart';
import '../theme/app_theme.dart';
import 'permiso_crear_screen.dart';
import 'permiso_editar_screen.dart';

class PermisoScreen extends StatefulWidget {
  const PermisoScreen({Key? key}) : super(key: key);

  @override
  State<PermisoScreen> createState() => _PermisoScreenState();
}

class _PermisoScreenState extends State<PermisoScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFiltros = false;
  String _filtroActivo = 'todos'; // 'todos', 'hoy', 'programados', 'completados'
  
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
      final permisoProvider = context.read<PermisoProvider>();
      final colaboradorProvider = context.read<ColaboradorProvider>();
      
      // Configurar el PermisoProvider para escuchar cambios de sucursal
      permisoProvider.setAuthProvider(authProvider);
      colaboradorProvider.configureAuthProvider(authProvider);
      
      // Cargar datos
      permisoProvider.inicializar();
      colaboradorProvider.cargarColaboradores();
    });
  }

  Future<void> _refrescarDatos() async {
    // Actualizar todos los providers relevantes
    final permisoProvider = Provider.of<PermisoProvider>(context, listen: false);
    final colaboradorProvider = Provider.of<ColaboradorProvider>(context, listen: false);
    final horasTrabajadasProvider = Provider.of<HorasTrabajadasProvider>(context, listen: false);
    final horasExtrasProvider = Provider.of<HorasExtrasProvider>(context, listen: false);
    final tarjaProvider = Provider.of<TarjaProvider>(context, listen: false);
    
    // Cargar datos en paralelo para mejor rendimiento
    await Future.wait([
      permisoProvider.inicializar(),
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
    
    final permisoProvider = context.read<PermisoProvider>();
    switch (filtro) {
      case 'creados':
        permisoProvider.setFiltroEstado('Creado');
        break;
      case 'aprobados':
        permisoProvider.setFiltroEstado('Aprobado');
        break;
      case 'porAprobar':
        // Los permisos "Por Aprobar" son los mismos que "Creado" pero para aprobación
        permisoProvider.setFiltroEstado('Creado');
        break;
      default: // 'todos'
        permisoProvider.limpiarFiltros();
        break;
    }
  }

  void _onSearchChanged(String query) {
    final permisoProvider = context.read<PermisoProvider>();
    permisoProvider.filtrarPermisos(query);
  }

  bool _tieneFiltrosActivos(PermisoProvider permisoProvider) {
    return permisoProvider.filtroColaborador.isNotEmpty ||
           permisoProvider.filtroTipo.isNotEmpty ||
           permisoProvider.filtroMes != null ||
           permisoProvider.filtroAno != null;
  }

  // Funciones para agrupación
  void _resetExpansionState(int groupCount) {
    _expansionState = List.generate(groupCount, (index) => true);
  }

  Map<String, List<Permiso>> _agruparPorMesAno(List<Permiso> permisos) {
    final grupos = <String, List<Permiso>>{};
    for (var permiso in permisos) {
      final fecha = permiso.fecha;
      if (fecha != null && fecha.isNotEmpty) {
        // Usar el método _parseFecha del modelo Permiso
        final date = _parseFecha(fecha);
        if (date != null) {
          final mesAno = '${date.year}-${date.month.toString().padLeft(2, '0')}';
          if (!grupos.containsKey(mesAno)) {
            grupos[mesAno] = [];
          }
          grupos[mesAno]!.add(permiso);
        } else {
          // Si no se puede parsear la fecha, usar 'Sin fecha'
          const mesAno = 'Sin fecha';
          if (!grupos.containsKey(mesAno)) {
            grupos[mesAno] = [];
          }
          grupos[mesAno]!.add(permiso);
        }
      } else {
        // Si no hay fecha, usar 'Sin fecha'
        const mesAno = 'Sin fecha';
        if (!grupos.containsKey(mesAno)) {
          grupos[mesAno] = [];
        }
        grupos[mesAno]!.add(permiso);
      }
    }
    return grupos;
  }

  // Método para parsear fechas (copiado del modelo Permiso)
  DateTime? _parseFecha(String fechaStr) {
    try {
      // Intentar parsear formato ISO
      if (fechaStr.contains('T') || fechaStr.contains('Z')) {
        return DateTime.parse(fechaStr);
      }
      
      // Intentar parsear formato específico del backend
      if (fechaStr.contains(',')) {
        final regex = RegExp(r'(\w{3}), (\d{1,2}) (\w{3}) (\d{4})');
        final match = regex.firstMatch(fechaStr);
        if (match != null) {
          final diaSemana = match.group(1);
          final dia = int.parse(match.group(2)!);
          final mesStr = match.group(3)!;
          final anio = int.parse(match.group(4)!);
          
          final monthMap = {
            'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
            'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
          };
          
          final month = monthMap[mesStr];
          if (month != null) {
            return DateTime(anio, month, dia);
          }
        }
      }
      
      // Intentar parsear formato YYYY-MM-DD
      if (fechaStr.contains('-')) {
        final parts = fechaStr.split('-');
        if (parts.length == 3) {
          final anio = int.parse(parts[0]);
          final mes = int.parse(parts[1]);
          final dia = int.parse(parts[2]);
          return DateTime(anio, mes, dia);
        }
      }
      
      return null;
    } catch (e) {
      return null;
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
              hintText: 'Buscar por colaborador o tipo de permiso',
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
                child: Consumer<PermisoProvider>(
                  builder: (context, permisoProvider, child) {
                    final tieneFiltrosActivos = _tieneFiltrosActivos(permisoProvider);
                    
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
                  onPressed: () => _mostrarDialogoCrearPermiso(),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Nuevo', style: TextStyle(fontSize: 14)),
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
    return Consumer2<PermisoProvider, ColaboradorProvider>(
      builder: (context, permisoProvider, colaboradorProvider, child) {
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
                      value: permisoProvider.filtroColaborador.isEmpty ? null : permisoProvider.filtroColaborador,
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
                        ...colaboradorProvider.colaboradores.map((colaborador) {
                          return DropdownMenuItem<String>(
                            value: colaborador.nombreCompleto,
                            child: Text(colaborador.nombreCompleto),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          permisoProvider.filtrarPorColaborador(value);
                        } else {
                          permisoProvider.limpiarFiltros();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: permisoProvider.filtroTipo.isEmpty ? null : permisoProvider.filtroTipo,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Permiso',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Todos los tipos'),
                        ),
                        ...permisoProvider.tiposPermisoUnicos.map((tipo) {
                          return DropdownMenuItem<String>(
                            value: tipo,
                            child: Text(tipo),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          permisoProvider.filtrarPorTipo(value);
                        } else {
                          permisoProvider.limpiarFiltros();
                        }
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
                      value: permisoProvider.filtroMes,
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
                        ...permisoProvider.mesesUnicos.map((mes) {
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
                        permisoProvider.setFiltroMes(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: permisoProvider.filtroAno,
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
                        ...permisoProvider.anosUnicos.map((ano) {
                          return DropdownMenuItem<int>(
                            value: ano,
                            child: Text(ano.toString()),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        permisoProvider.setFiltroAno(value);
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
                        permisoProvider.limpiarFiltros();
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
    return Consumer<PermisoProvider>(
      builder: (context, permisoProvider, child) {
        final stats = permisoProvider.estadisticas;
        
        return Container(
          margin: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildTarjetaEstadistica(
                  'Total',
                  stats['total']?.toString() ?? '0',
                  Icons.assignment,
                  Colors.purple,
                  'todos',
                  (stats['total'] ?? 0) > 0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTarjetaEstadistica(
                  'Creados',
                  stats['creados']?.toString() ?? '0',
                  Icons.create,
                  Colors.orange,
                  'creados',
                  (stats['creados'] ?? 0) > 0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTarjetaEstadistica(
                  'Aprobados',
                  stats['aprobados']?.toString() ?? '0',
                  Icons.check_circle,
                  Colors.green,
                  'aprobados',
                  (stats['aprobados'] ?? 0) > 0,
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

  Widget _buildPermisoCard(Permiso permiso) {
    final cardColor = Theme.of(context).colorScheme.surface;
    // Color del borde según el estado del permiso
    final borderColor = _getColorEstado(permiso.estadoPermiso).withOpacity(0.6);
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: borderColor, width: 1),
      ),
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _mostrarDetallesPermiso(permiso),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título del permiso
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: _getColorEstado(permiso.estadoPermiso).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      _getIconEstado(permiso.estadoPermiso),
                      color: _getColorEstado(permiso.estadoPermiso),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      permiso.nombreCompletoColaborador,
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
                  // Columna 1: Tipo de permiso
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.category, color: Colors.blue, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tipo: ${permiso.tipoPermiso ?? 'N/A'}',
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
                  const SizedBox(width: 12),
                  // Columna 2: Fecha
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
                                'Fecha: ${permiso.fechaFormateadaEspanol}',
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
                  const SizedBox(width: 12),
                  // Columna 3: Horas
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.access_time, color: Colors.orange, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Horas: ${permiso.horas}',
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
                  const SizedBox(width: 12),
                  // Columna 4: Estado, Editar, Eliminar
                  Expanded(
                    flex: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getColorEstado(permiso.estadoPermiso).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getColorEstado(permiso.estadoPermiso),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            permiso.estadoPermiso ?? 'N/A',
                            style: TextStyle(
                              color: _getColorEstado(permiso.estadoPermiso),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Botón para cambiar estado (solo si es Creado o Aprobado)
                        if (permiso.estadoPermiso?.toLowerCase() == 'creado' || 
                            permiso.estadoPermiso?.toLowerCase() == 'aprobado')
                          IconButton(
                            onPressed: () => _cambiarEstadoPermiso(permiso),
                            icon: Icon(
                              permiso.estadoPermiso?.toLowerCase() == 'creado' 
                                ? Icons.check_circle 
                                : Icons.replay,
                              color: permiso.estadoPermiso?.toLowerCase() == 'creado' 
                                ? Colors.green 
                                : Colors.orange,
                              size: 20,
                            ),
                            tooltip: permiso.estadoPermiso?.toLowerCase() == 'creado' 
                              ? 'Aprobar permiso' 
                              : 'Marcar como creado',
                          ),
                        IconButton(
                          onPressed: () => _manejarAccionPermiso('editar', permiso),
                          icon: Icon(Icons.edit, color: AppTheme.primaryColor, size: 20),
                          tooltip: 'Editar permiso',
                        ),
                        IconButton(
                          onPressed: () => _manejarAccionPermiso('eliminar', permiso),
                          icon: Icon(Icons.delete, color: Colors.red, size: 20),
                          tooltip: 'Eliminar permiso',
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

  Color _getColorEstado(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'aprobado':
        return Colors.green;
      case 'rechazado':
        return Colors.red;
      case 'creado':
        return Colors.orange;
      case 'por aprobar':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconEstado(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'aprobado':
        return Icons.check_circle;
      case 'rechazado':
        return Icons.cancel;
      case 'creado':
      case 'por aprobar':
        return Icons.pending;
      default:
        return Icons.help;
    }
  }

  void _manejarAccionPermiso(String accion, Permiso permiso) {
    switch (accion) {
      case 'editar':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PermisoEditarScreen(permiso: permiso),
          ),
        );
        break;
      case 'eliminar':
        _mostrarDialogoConfirmarEliminacion(permiso);
        break;
    }
  }

  void _cambiarEstadoPermiso(Permiso permiso) {
    final nuevoEstado = permiso.estadoPermiso?.toLowerCase() == 'creado' ? 'Aprobado' : 'Creado';
    final accion = permiso.estadoPermiso?.toLowerCase() == 'creado' ? 'aprobar' : 'desaprobar';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${accion == 'aprobar' ? 'Aprobar' : 'Desaprobar'} Permiso'),
        content: Text(
          '¿Está seguro de que desea ${accion == 'aprobar' ? 'aprobar' : 'desaprobar'} el permiso de ${permiso.nombreCompletoColaborador} para el ${permiso.fechaFormateadaEspanol}?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _actualizarEstadoPermiso(permiso, nuevoEstado);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accion == 'aprobar' ? Colors.green : Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text(accion == 'aprobar' ? 'Aprobar' : 'Desaprobar'),
          ),
        ],
      ),
    );
  }

  Future<void> _actualizarEstadoPermiso(Permiso permiso, String nuevoEstado) async {
    try {
      final permisoProvider = context.read<PermisoProvider>();
      
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      Map<String, dynamic>? response;
      
      // Usar el método apropiado según el estado
      if (nuevoEstado.toLowerCase() == 'aprobado') {
        // Usar el método existente para aprobar
        response = await permisoProvider.aprobarPermiso(permiso.id);
      } else if (nuevoEstado.toLowerCase() == 'creado') {
        // Para cambiar a "Creado", usar el método de edición
        final datosEdicion = {
          'id_estadopermiso': '1', // ID para estado "Creado"
          'id_tipopermiso': permiso.idTipopermiso,
          'fecha': permiso.fecha,
          'horas': permiso.horas,
          'id_colaborador': permiso.idColaborador,
          'id_usuario': permiso.idUsuario,
        };
        final exito = await permisoProvider.editarPermiso(permiso.id, datosEdicion);
        response = exito ? {'success': true} : null;
      } else {
        // Para otros estados, usar el método de actualización genérico
        response = await permisoProvider.actualizarEstadoPermiso(permiso.id, nuevoEstado);
      }
      
      // Cerrar loading
      Navigator.pop(context);
      
      if (response != null) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Permiso ${nuevoEstado.toLowerCase()} exitosamente'),
            backgroundColor: nuevoEstado.toLowerCase() == 'aprobado' ? Colors.green : Colors.orange,
          ),
        );
      } else {
        // Mostrar error del provider
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${permisoProvider.error ?? 'Error desconocido'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
    } catch (e) {
      // Cerrar loading si está abierto
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Mostrar error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar el permiso: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarDetallesPermiso(Permiso permiso) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 500),
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
                      AppTheme.primaryColor.withOpacity(0.1),
                      AppTheme.primaryColor.withOpacity(0.05),
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
                          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.7)],
                        ),
                      ),
                      child: const Icon(
                        Icons.work_outline,
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
                            'Permiso',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            permiso.nombreCompletoColaborador,
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                      // Información del permiso
                      _buildInfoSection(
                        'Información del Permiso',
                        Icons.work_outline,
                        [
                          _buildModernInfoRow('Tipo', permiso.tipoPermiso ?? 'N/A', Icons.category),
                          _buildModernInfoRow('Fecha', permiso.fechaFormateadaEspanol, Icons.calendar_today),
                          _buildModernInfoRow('Horas', '${permiso.horas} horas', Icons.schedule),
                          _buildModernInfoRow('Estado', permiso.estadoPermiso ?? 'N/A', Icons.info),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Botones de acción
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                ),
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
    // Definir colores para diferentes tipos de iconos
    Color iconColor;
    Color backgroundColor;
    
    // Comparar directamente con los iconos
    if (icon == Icons.calendar_today) {
      iconColor = Colors.blue;
      backgroundColor = Colors.blue.withOpacity(0.1);
    } else if (icon == Icons.schedule) {
      iconColor = Colors.orange;
      backgroundColor = Colors.orange.withOpacity(0.1);
    } else if (icon == Icons.info) {
      iconColor = Colors.purple;
      backgroundColor = Colors.purple.withOpacity(0.1);
    } else if (icon == Icons.category) {
      iconColor = Colors.green;
      backgroundColor = Colors.green.withOpacity(0.1);
    } else if (icon == Icons.badge) {
      iconColor = Colors.red;
      backgroundColor = Colors.red.withOpacity(0.1);
    } else if (icon == Icons.person_outline) {
      iconColor = Colors.teal;
      backgroundColor = Colors.teal.withOpacity(0.1);
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

  void _mostrarDialogoConfirmarEliminacion(Permiso permiso) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar el permiso de ${permiso.nombreCompletoColaborador}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _eliminarPermiso(permiso);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarPermiso(Permiso permiso) async {
    try {
      final permisoProvider = context.read<PermisoProvider>();
      await permisoProvider.eliminarPermiso(permiso.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permiso eliminado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar permiso: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarDialogoCrearPermiso() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PermisoCrearScreen(),
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
          child: Consumer<PermisoProvider>(
            builder: (context, permisoProvider, child) {
              if (permisoProvider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (permisoProvider.error != null) {
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
                        'Error al cargar permisos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        permisoProvider.error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.red.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => permisoProvider.cargarPermisos(),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }

              final permisosFiltrados = permisoProvider.permisosFiltrados;

              if (permisosFiltrados.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 80,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay permisos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Agrega el primer permiso para comenzar',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _mostrarDialogoCrearPermiso(),
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar Permiso'),
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

              return _buildListaPermisos(permisoProvider);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildListaPermisos(PermisoProvider permisoProvider) {
    final permisosFiltrados = permisoProvider.permisosFiltrados.isNotEmpty 
        ? permisoProvider.permisosFiltrados 
        : permisoProvider.permisos;
    final gruposPorMesAno = _agruparPorMesAno(permisosFiltrados);
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

    if (permisoProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (permisoProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              permisoProvider.error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => permisoProvider.cargarPermisos(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    
    if (permisosFiltrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron permisos que coincidan con los filtros',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta cambiar los filtros o refrescar los datos',
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
        final permisos = gruposPorMesAno[mesAno]!;
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
                      '${permisos.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              children: permisos.map((permiso) => _buildPermisoCard(permiso)).toList(),
            ),
          ),
        );
      }),
    );
  }
}


