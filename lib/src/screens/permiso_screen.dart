import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/permiso_provider.dart';
import '../providers/colaborador_provider.dart';
import '../providers/auth_provider.dart';
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
      colaboradorProvider.setAuthProvider(authProvider);
      
      // Cargar datos
      permisoProvider.inicializar();
      colaboradorProvider.cargarColaboradores();
    });
  }

  // Método para refrescar datos desde el AppBar
  Future<void> _refrescarDatos() async {
    final permisoProvider = context.read<PermisoProvider>();
    final colaboradorProvider = context.read<ColaboradorProvider>();
    await Future.wait([
      permisoProvider.inicializar(),
      colaboradorProvider.cargarColaboradores(),
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
      final date = DateTime(year, month);
      return DateFormat('MMMM yyyy', 'es').format(date);
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
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showFiltros = !_showFiltros;
                    });
                  },
                  icon: Icon(_showFiltros ? Icons.filter_list_off : Icons.filter_list),
                  label: Text(_showFiltros ? 'Ocultar filtros' : 'Mostrar filtros'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
                  Colors.blue,
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
              const SizedBox(width: 8),
              Expanded(
                child: _buildTarjetaEstadistica(
                  'Por Aprobar',
                  stats['porAprobar']?.toString() ?? '0',
                  Icons.pending,
                  Colors.orange,
                  'porAprobar',
                  (stats['porAprobar'] ?? 0) > 0,
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
            Text(
              titulo,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
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

  Widget _buildPermisoCard(Permiso permiso) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: _getColorEstado(permiso.estadoPermiso),
          child: Icon(
            _getIconEstado(permiso.estadoPermiso),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          permiso.nombreCompletoColaborador,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Tipo: ${permiso.tipoPermiso ?? 'N/A'}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Fecha: ${permiso.fechaFormateadaEspanol}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Horas: ${permiso.horas}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Estado: ${permiso.estadoPermiso ?? 'N/A'}',
              style: TextStyle(
                color: _getColorEstado(permiso.estadoPermiso),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _manejarAccionPermiso(value, permiso),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'editar',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'eliminar',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18),
                  SizedBox(width: 8),
                  Text('Eliminar'),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _mostrarDetallesPermiso(permiso),
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
      case 'por aprobar':
        return Colors.orange;
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

  void _mostrarDetallesPermiso(Permiso permiso) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles del Permiso'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Colaborador: ${permiso.nombreCompletoColaborador}'),
              const SizedBox(height: 8),
              Text('Tipo: ${permiso.tipoPermiso ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text('Fecha: ${permiso.fechaFormateadaEspanol}'),
              const SizedBox(height: 8),
              Text('Horas: ${permiso.horas}'),
              const SizedBox(height: 8),
              Text('Estado: ${permiso.estadoPermiso ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text('ID Colaborador: ${permiso.idColaborador}'),
              const SizedBox(height: 8),
              Text('ID Usuario: ${permiso.idUsuario}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
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
                      _formatearMesAno(mesAno),
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
                      '${permisos.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
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


