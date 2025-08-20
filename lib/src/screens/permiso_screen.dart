import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/permiso_provider.dart';
import '../providers/colaborador_provider.dart';
import '../providers/auth_provider.dart';
import '../models/permiso.dart';
import '../widgets/main_scaffold.dart';
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
      case 'hoy':
        permisoProvider.filtrarPorEstado('Hoy');
        break;
      case 'programados':
        permisoProvider.filtrarPorEstado('Programado');
        break;
      case 'completados':
        permisoProvider.filtrarPorEstado('Completado');
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
              const SizedBox(width: 12),
              ElevatedButton.icon(
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
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
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
                      value: permisoProvider.filtroEstado.isEmpty ? null : permisoProvider.filtroEstado,
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
                        ...permisoProvider.estadosUnicos.map((estado) {
                          return DropdownMenuItem<String>(
                            value: estado,
                            child: Text(estado),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          permisoProvider.filtrarPorEstado(value);
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
                  'Hoy',
                  stats['hoy']?.toString() ?? '0',
                  Icons.today,
                  Colors.orange,
                  'hoy',
                  (stats['hoy'] ?? 0) > 0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTarjetaEstadistica(
                  'Programados',
                  stats['programados']?.toString() ?? '0',
                  Icons.schedule,
                  Colors.blue,
                  'programados',
                  (stats['programados'] ?? 0) > 0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTarjetaEstadistica(
                  'Completados',
                  stats['completados']?.toString() ?? '0',
                  Icons.check_circle,
                  Colors.green,
                  'completados',
                  (stats['completados'] ?? 0) > 0,
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
      onTap: tieneDatos ? () => _aplicarFiltro(filtro) : null,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.colorScheme.surface;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    final textColor = theme.colorScheme.onSurface;

    // Determinar color del estado
    Color estadoColor;
    switch (permiso.estadoColor) {
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
        onTap: () => _mostrarDetallesPermiso(permiso),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: estadoColor.withOpacity(0.2),
                    radius: 20,
                    child: Icon(
                      _getEstadoIcon(permiso.estado),
                      color: estadoColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          permiso.nombreCompletoColaborador,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${permiso.tipoPermiso ?? 'Sin tipo'} - ${permiso.horas} horas',
                          style: TextStyle(
                            color: textColor.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: estadoColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: estadoColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      permiso.estado,
                      style: TextStyle(
                        color: estadoColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: textColor.withOpacity(0.6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    permiso.fechaFormateadaEspanol,
                    style: TextStyle(
                      color: textColor.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: AppTheme.infoColor, size: 20),
                        onPressed: () => _mostrarDialogoEditarPermiso(permiso),
                        tooltip: 'Editar',
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: AppTheme.errorColor, size: 20),
                        onPressed: () => _mostrarDialogoEliminarPermiso(permiso),
                        tooltip: 'Eliminar',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado) {
      case 'Hoy':
        return Icons.today;
      case 'Programado':
        return Icons.schedule;
      case 'Completado':
        return Icons.check_circle;
      default:
        return Icons.assignment;
    }
  }

  void _mostrarDetallesPermiso(Permiso permiso) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles del Permiso'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Colaborador:', permiso.nombreCompletoColaborador),
            _buildInfoRow('Tipo de Permiso:', permiso.tipoPermiso ?? 'Sin especificar'),
            _buildInfoRow('Fecha:', permiso.fechaFormateadaEspanol),
            _buildInfoRow('Horas:', '${permiso.horas} horas'),
            _buildInfoRow('Estado:', permiso.estadoPermiso ?? 'Sin especificar'),
            _buildInfoRow('Creado:', permiso.timestampFormateadoEspanol),
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
              _mostrarDialogoEditarPermiso(permiso);
            },
            child: const Text('Editar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoCrearPermiso() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PermisoCrearScreen(),
      ),
    );
    
    // Si se creó exitosamente un permiso, refrescar la lista
    if (result == true) {
      final permisoProvider = context.read<PermisoProvider>();
      await permisoProvider.cargarPermisos();
    }
  }

  void _mostrarDialogoEditarPermiso(Permiso permiso) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PermisoEditarScreen(permiso: permiso),
      ),
    );
    
    // Si se editó exitosamente un permiso, refrescar la lista
    if (result == true) {
      final permisoProvider = context.read<PermisoProvider>();
      await permisoProvider.cargarPermisos();
    }
  }

  void _mostrarDialogoEliminarPermiso(Permiso permiso) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Estás seguro de que quieres eliminar el permiso de ${permiso.nombreCompletoColaborador}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final permisoProvider = context.read<PermisoProvider>();
              final success = await permisoProvider.eliminarPermiso(permiso.id);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Permiso eliminado correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al eliminar: ${permisoProvider.error}'),
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
    return MainScaffold(
      title: 'Gestión de Permisos',
      onRefresh: _refrescarDatos,
      body: Column(
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

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: permisosFiltrados.length,
                  itemBuilder: (context, index) {
                    return _buildPermisoCard(permisosFiltrados[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }


}


