import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vacacion.dart';
import '../models/colaborador.dart';
import '../providers/auth_provider.dart';
import '../providers/vacacion_provider.dart';
import '../providers/colaborador_provider.dart';
import '../widgets/main_scaffold.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class VacacionesScreen extends StatefulWidget {
  const VacacionesScreen({super.key});

  @override
  State<VacacionesScreen> createState() => _VacacionesScreenState();
}

class _VacacionesScreenState extends State<VacacionesScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showFiltros = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
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
    final vacacionProvider = context.read<VacacionProvider>();
    final colaboradorProvider = context.read<ColaboradorProvider>();
    await Future.wait([
      vacacionProvider.cargarVacaciones(),
      colaboradorProvider.cargarColaboradores(),
    ]);
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
      _actualizarFiltrosPorTab();
    });
  }

  void _actualizarFiltrosPorTab() {
    final vacacionProvider = context.read<VacacionProvider>();
    switch (_selectedTab) {
      case 1: // Programadas
        vacacionProvider.setFiltroEstado('Programada');
        break;
      case 2: // En curso
        vacacionProvider.setFiltroEstado('En curso');
        break;
      case 3: // Completadas
        vacacionProvider.setFiltroEstado('Completada');
        break;
      default: // Todos
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
                onPressed: () => _mostrarDialogoCrearVacacion(),
                icon: const Icon(Icons.add),
                label: const Text('Nueva'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
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
    return Consumer2<VacacionProvider, ColaboradorProvider>(
      builder: (context, vacacionProvider, colaboradorProvider, child) {
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
                    child: OutlinedButton.icon(
                      onPressed: () {
                        vacacionProvider.limpiarFiltros();
                        _searchController.clear();
                        _onSearchChanged('');
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
                  Icons.calendar_month,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTarjetaEstadistica(
                  'Programadas',
                  vacacionProvider.vacacionesProgramadas.toString(),
                  Icons.schedule,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTarjetaEstadistica(
                  'En curso',
                  vacacionProvider.vacacionesEnCurso.toString(),
                  Icons.play_circle,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTarjetaEstadistica(
                  'Completadas',
                  vacacionProvider.vacacionesCompletadas.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTarjetaEstadistica(String titulo, String valor, IconData icono, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVacacionCard(Vacacion vacacion) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.colorScheme.surface;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vacacion.nombreCompletoColaborador,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          vacacion.periodoFormateado,
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
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.purple, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${vacacion.duracionDias} días',
                    style: TextStyle(
                      color: textColor.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
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
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDetallesVacacion(Vacacion vacacion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles de Vacación'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Colaborador', vacacion.nombreCompletoColaborador),
              _buildInfoRow('Período', vacacion.periodoFormateado),
              _buildInfoRow('Duración', '${vacacion.duracionDias} días'),
              _buildInfoRow('Estado', vacacion.estado),
              _buildInfoRow('Fecha Inicio', vacacion.fechaInicioFormateada),
              _buildInfoRow('Fecha Fin', vacacion.fechaFinFormateada),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _mostrarDialogoEditarVacacion(vacacion);
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
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoCrearVacacion() {
    // TODO: Implementar diálogo de creación
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Vacación'),
        content: const Text('Funcionalidad en desarrollo...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoEditarVacacion(Vacacion vacacion) {
    // TODO: Implementar diálogo de edición
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Vacación'),
        content: Text('Editar vacación de ${vacacion.nombreCompletoColaborador} - Funcionalidad en desarrollo...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
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
    return MainScaffold(
      title: 'Vacaciones',
      onRefresh: _refrescarDatos,
      bottom: _TabBarWithCounters(tabController: _tabController),
      body: Column(
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

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: vacacionesFiltradas.length,
                  itemBuilder: (context, index) {
                    return _buildVacacionCard(vacacionesFiltradas[index]);
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

class _TabBarWithCounters extends StatelessWidget implements PreferredSizeWidget {
  final TabController tabController;

  const _TabBarWithCounters({required this.tabController});

  @override
  Size get preferredSize => const Size.fromHeight(48.0);

  @override
  Widget build(BuildContext context) {
    return Consumer<VacacionProvider>(
      builder: (context, vacacionProvider, child) {
        return TabBar(
          controller: tabController,
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
                      '${vacacionProvider.totalVacaciones}',
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
                  const Text('Programadas'),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${vacacionProvider.vacacionesProgramadas}',
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
                  const Text('En curso'),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${vacacionProvider.vacacionesEnCurso}',
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
                  const Text('Completadas'),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${vacacionProvider.vacacionesCompletadas}',
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
