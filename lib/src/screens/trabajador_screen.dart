import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/trabajador.dart';
import '../providers/auth_provider.dart';
import '../providers/trabajador_provider.dart';
import '../widgets/main_scaffold.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class TrabajadorScreen extends StatefulWidget {
  const TrabajadorScreen({super.key});

  @override
  State<TrabajadorScreen> createState() => _TrabajadorScreenState();
}

class _TrabajadorScreenState extends State<TrabajadorScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showFiltros = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _cargarDatosIniciales();
  }

  void _cargarDatosIniciales() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final trabajadorProvider = context.read<TrabajadorProvider>();
      
      // Configurar el TrabajadorProvider para escuchar cambios de sucursal
      trabajadorProvider.setAuthProvider(authProvider);
      trabajadorProvider.cargarTrabajadores();
    });
  }

  // Método para refrescar datos desde el AppBar
  Future<void> _refrescarDatos() async {
    final trabajadorProvider = context.read<TrabajadorProvider>();
    await trabajadorProvider.cargarTrabajadores();
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
    final trabajadorProvider = context.read<TrabajadorProvider>();
    switch (_selectedTab) {
      case 1: // Activos
        trabajadorProvider.setFiltroEstado('1');
        break;
      case 2: // Inactivos
        trabajadorProvider.setFiltroEstado('2');
        break;
      default: // Todos
        trabajadorProvider.setFiltroEstado('todos');
        break;
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
    final trabajadorProvider = context.read<TrabajadorProvider>();
    trabajadorProvider.setFiltroBusqueda(query);
  }

  List<Trabajador> _filtrarTrabajadores(List<Trabajador> trabajadores) {
    if (_searchQuery.isEmpty) {
      return trabajadores;
    }
    
    return trabajadores.where((trabajador) {
      return trabajador.nombreCompleto.toLowerCase().contains(_searchQuery) ||
             trabajador.rutCompleto.toLowerCase().contains(_searchQuery) ||
             (trabajador.nombreContratista?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();
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
              hintText: 'Buscar por nombre, RUT o contratista',
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
                onPressed: () => _mostrarDialogoCrearTrabajador(),
                icon: const Icon(Icons.person_add),
                label: const Text('Nuevo'),
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
    return Consumer<TrabajadorProvider>(
      builder: (context, trabajadorProvider, child) {
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
                      value: trabajadorProvider.filtroContratista,
                      decoration: const InputDecoration(
                        labelText: 'Contratista',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Todos los contratistas'),
                        ),
                        ...trabajadorProvider.contratistasUnicos.map((contratista) {
                          return DropdownMenuItem<String>(
                            value: contratista,
                            child: Text(contratista),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        trabajadorProvider.setFiltroContratista(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: trabajadorProvider.filtroEstado,
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem<String>(
                          value: 'todos',
                          child: Text('Todos'),
                        ),
                        DropdownMenuItem<String>(
                          value: '1',
                          child: Text('Activo'),
                        ),
                        DropdownMenuItem<String>(
                          value: '2',
                          child: Text('Inactivo'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          trabajadorProvider.setFiltroEstado(value);
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
                        trabajadorProvider.limpiarFiltros();
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
    return Consumer<TrabajadorProvider>(
      builder: (context, trabajadorProvider, child) {
        return Container(
          margin: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildTarjetaEstadistica(
                  'Total',
                  trabajadorProvider.totalTrabajadores.toString(),
                  Icons.people,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTarjetaEstadistica(
                  'Activos',
                  trabajadorProvider.trabajadoresActivos.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTarjetaEstadistica(
                  'Inactivos',
                  trabajadorProvider.trabajadoresInactivos.toString(),
                  Icons.cancel,
                  Colors.red,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icono, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrabajadorCard(Trabajador trabajador) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.colorScheme.surface;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
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
        onTap: () => _mostrarDetallesTrabajador(trabajador),
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
                      color: trabajador.idEstado == '1' ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      trabajador.idEstado == '1' ? Icons.person : Icons.person_off,
                      color: trabajador.idEstado == '1' ? Colors.green : Colors.red,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trabajador.nombreCompleto,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'RUT: ${trabajador.rutCompleto}',
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
                      color: trabajador.idEstado == '1' ? Colors.green[100] : Colors.red[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: trabajador.idEstado == '1' ? Colors.green : Colors.red,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      trabajador.estadoText,
                      style: TextStyle(
                        color: trabajador.idEstado == '1' ? Colors.green[800] : Colors.red[800],
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
                  Icon(Icons.business, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Contratista: ${trabajador.nombreContratista ?? 'No asignado'}',
                      style: TextStyle(
                        color: textColor.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.percent, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Porcentaje: ${trabajador.porcentajeFormateado}',
                    style: TextStyle(
                      color: textColor.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _mostrarDialogoEditarTrabajador(trabajador),
                    icon: Icon(Icons.edit, color: AppTheme.primaryColor, size: 20),
                    tooltip: 'Editar trabajador',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDetallesTrabajador(Trabajador trabajador) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.person, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            const Text('Detalles del Trabajador'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetalleItem('Nombre completo', trabajador.nombreCompleto),
              _buildDetalleItem('RUT', trabajador.rutCompleto),
              _buildDetalleItem('Estado', trabajador.estadoText),
              _buildDetalleItem('Contratista', trabajador.nombreContratista ?? 'No asignado'),
              _buildDetalleItem('Porcentaje', trabajador.porcentajeFormateado),
              _buildDetalleItem('ID Trabajador', trabajador.id),
              _buildDetalleItem('ID Contratista', trabajador.idContratista),
              _buildDetalleItem('ID Porcentaje', trabajador.idPorcentaje),
              _buildDetalleItem('ID Estado', trabajador.idEstado),
              _buildDetalleItem('ID Sucursal', trabajador.idSucursalActiva),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _mostrarDialogoEditarTrabajador(trabajador);
            },
            child: const Text('Editar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
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

  void _mostrarDialogoCrearTrabajador() {
    // Implementar diálogo para crear trabajador
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Nuevo Trabajador'),
        content: const Text('Funcionalidad en desarrollo...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoEditarTrabajador(Trabajador trabajador) {
    // Implementar diálogo para editar trabajador
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Trabajador'),
        content: const Text('Funcionalidad en desarrollo...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Gestión de Trabajadores',
      onRefresh: _refrescarDatos,
      bottom: _TabBarWithCounters(tabController: _tabController),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildEstadisticas(),
          Expanded(
            child: Consumer<TrabajadorProvider>(
              builder: (context, trabajadorProvider, child) {
                if (trabajadorProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (trabajadorProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar trabajadores',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          trabajadorProvider.error!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => trabajadorProvider.cargarTrabajadores(),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                final trabajadoresFiltrados = trabajadorProvider.trabajadoresFiltrados;
                
                if (trabajadoresFiltrados.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isNotEmpty ? Icons.search_off : Icons.people_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty 
                            ? 'No se encontraron trabajadores que coincidan con "$_searchQuery"'
                            : 'No hay trabajadores registrados',
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
                            : 'Agrega el primer trabajador usando el botón "Nuevo"',
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
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: trabajadoresFiltrados.length,
                  itemBuilder: (context, index) {
                    return _buildTrabajadorCard(trabajadoresFiltrados[index]);
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
    return Consumer<TrabajadorProvider>(
      builder: (context, trabajadorProvider, child) {
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
                  const Text('Todos'),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${trabajadorProvider.totalTrabajadores}',
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
                  const Text('Activos'),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${trabajadorProvider.trabajadoresActivos}',
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
                  const Text('Inactivos'),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${trabajadorProvider.trabajadoresInactivos}',
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
