import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/colaborador.dart';
import '../providers/auth_provider.dart';
import '../providers/colaborador_provider.dart';
import '../widgets/main_scaffold.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'colaborador_crear_screen.dart';
import 'colaborador_editar_screen.dart';

class ColaboradorScreen extends StatefulWidget {
  const ColaboradorScreen({super.key});

  @override
  State<ColaboradorScreen> createState() => _ColaboradorScreenState();
}

class _ColaboradorScreenState extends State<ColaboradorScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showFiltros = false;
  String _filtroActivo = 'todos'; // 'todos', 'activos', 'inactivos'

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  void _cargarDatosIniciales() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final colaboradorProvider = context.read<ColaboradorProvider>();
      
      // Configurar el ColaboradorProvider para escuchar cambios de sucursal
      colaboradorProvider.setAuthProvider(authProvider);
      colaboradorProvider.cargarColaboradores();
    });
  }

  // Método para refrescar datos desde el AppBar
  Future<void> _refrescarDatos() async {
    final colaboradorProvider = context.read<ColaboradorProvider>();
    await colaboradorProvider.cargarColaboradores();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
    final colaboradorProvider = context.read<ColaboradorProvider>();
    colaboradorProvider.setFiltroBusqueda(query);
  }

  void _aplicarFiltro(String filtro) {
    setState(() {
      _filtroActivo = filtro;
    });
    
    final colaboradorProvider = context.read<ColaboradorProvider>();
    switch (filtro) {
      case 'activos':
        colaboradorProvider.setFiltroEstado('1');
        break;
      case 'inactivos':
        colaboradorProvider.setFiltroEstado('2');
        break;
      default: // 'todos'
        colaboradorProvider.setFiltroEstado('todos');
        break;
    }
  }

  List<Colaborador> _filtrarColaboradores(List<Colaborador> colaboradores) {
    if (_searchQuery.isEmpty) {
      return colaboradores;
    }
    
    return colaboradores.where((colaborador) {
      return colaborador.nombreCompleto.toLowerCase().contains(_searchQuery) ||
             colaborador.rutCompleto.toLowerCase().contains(_searchQuery);
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
              hintText: 'Buscar por nombre o RUT',
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
              SizedBox(
                width: 120,
                child: ElevatedButton.icon(
                  onPressed: () => _mostrarDialogoCrearColaborador(),
                  icon: const Icon(Icons.person_add, size: 20),
                  label: const Text('Nuevo', style: TextStyle(fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
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
    return Consumer<ColaboradorProvider>(
      builder: (context, colaboradorProvider, child) {
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
                      value: colaboradorProvider.filtroEstado,
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
                          colaboradorProvider.setFiltroEstado(value);
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
                        colaboradorProvider.limpiarFiltros();
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
    return Consumer<ColaboradorProvider>(
      builder: (context, colaboradorProvider, child) {
        return Container(
          margin: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildTarjetaEstadistica(
                  'Total',
                  colaboradorProvider.totalColaboradores.toString(),
                  Icons.people,
                  Colors.orange,
                  'todos',
                  colaboradorProvider.totalColaboradores > 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTarjetaEstadistica(
                  'Activos',
                  colaboradorProvider.colaboradoresActivos.toString(),
                  Icons.check_circle,
                  Colors.green,
                  'activos',
                  colaboradorProvider.colaboradoresActivos > 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTarjetaEstadistica(
                  'Inactivos',
                  colaboradorProvider.colaboradoresInactivos.toString(),
                  Icons.cancel,
                  Colors.red,
                  'inactivos',
                  colaboradorProvider.colaboradoresInactivos > 0,
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
        padding: const EdgeInsets.all(16),
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
              size: 32,
            ),
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

  Widget _buildColaboradorCard(Colaborador colaborador) {
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
        onTap: () => _mostrarDetallesColaborador(colaborador),
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
                      color: colaborador.idEstado == '1' ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      colaborador.idEstado == '1' ? Icons.person : Icons.person_off,
                      color: colaborador.idEstado == '1' ? Colors.green : Colors.red,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          colaborador.nombreCompleto,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'RUT: ${colaborador.rutCompleto}',
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
                      color: colaborador.idEstado == '1' ? Colors.green[100] : Colors.red[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colaborador.idEstado == '1' ? Colors.green : Colors.red,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      colaborador.estadoText,
                      style: TextStyle(
                        color: colaborador.idEstado == '1' ? Colors.green[800] : Colors.red[800],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (colaborador.cargoText != 'Sin cargo') ...[
                Row(
                  children: [
                    Icon(Icons.work, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cargo: ${colaborador.cargoText}',
                        style: TextStyle(
                          color: textColor.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (colaborador.sucursalText != 'Sucursal ${colaborador.idSucursal}') ...[
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.purple, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sucursal: ${colaborador.sucursalText}',
                        style: TextStyle(
                          color: textColor.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (colaborador.fechaIncorporacion != null) ...[
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Incorporación: ${colaborador.fechaIncorporacionFormateadaEspanol}',
                      style: TextStyle(
                        color: textColor.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _mostrarDialogoEditarColaborador(colaborador),
                      icon: Icon(Icons.edit, color: AppTheme.primaryColor, size: 20),
                      tooltip: 'Editar colaborador',
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    const Spacer(),
                    IconButton(
                      onPressed: () => _mostrarDialogoEditarColaborador(colaborador),
                      icon: Icon(Icons.edit, color: AppTheme.primaryColor, size: 20),
                      tooltip: 'Editar colaborador',
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDetallesColaborador(Colaborador colaborador) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles de ${colaborador.nombreCompleto}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Nombre', colaborador.nombreCompleto),
              _buildInfoRow('RUT', colaborador.rutCompleto),
              _buildInfoRow('Estado', colaborador.estadoText),
              _buildInfoRow('Sucursal', colaborador.sucursalText),
              if (colaborador.sucursalContratoText != 'Sin sucursal de contrato')
                _buildInfoRow('Sucursal Contrato', colaborador.sucursalContratoText),
              if (colaborador.cargoText != 'Sin cargo')
                _buildInfoRow('Cargo', colaborador.cargoText),
              if (colaborador.fechaNacimiento != null)
                _buildInfoRow('Fecha Nacimiento', colaborador.fechaNacimientoFormateadaEspanol),
              if (colaborador.fechaIncorporacion != null)
                _buildInfoRow('Fecha Incorporación', colaborador.fechaIncorporacionFormateadaEspanol),
              if (colaborador.previsionText != 'Sin previsión')
                _buildInfoRow('Previsión', colaborador.previsionText),
              if (colaborador.afpText != 'Sin AFP')
                _buildInfoRow('AFP', colaborador.afpText),
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
              _mostrarDialogoEditarColaborador(colaborador);
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

  void _mostrarDialogoEditarColaborador(Colaborador colaborador) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ColaboradorEditarScreen(colaborador: colaborador),
      ),
    );
    
    // Si se editó exitosamente un colaborador, refrescar la lista
    if (result == true) {
      final colaboradorProvider = context.read<ColaboradorProvider>();
      await colaboradorProvider.cargarColaboradores();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Colaboradores',
      onRefresh: _refrescarDatos,
      body: Column(
        children: [
          _buildSearchBar(),
          _buildEstadisticas(),
          Expanded(
            child: Consumer<ColaboradorProvider>(
              builder: (context, colaboradorProvider, child) {
                if (colaboradorProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (colaboradorProvider.error != null) {
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
                          'Error al cargar colaboradores',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          colaboradorProvider.error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.red.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => colaboradorProvider.cargarColaboradores(),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                final colaboradoresFiltrados = colaboradorProvider.colaboradoresFiltrados;

                if (colaboradoresFiltrados.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 80,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay colaboradores',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Agrega tu primer colaborador para comenzar',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _mostrarDialogoCrearColaborador(),
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar Colaborador'),
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
                  itemCount: colaboradoresFiltrados.length,
                  itemBuilder: (context, index) {
                    return _buildColaboradorCard(colaboradoresFiltrados[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoCrearColaborador() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ColaboradorCrearScreen(),
      ),
    );
    
    // Si se creó exitosamente un colaborador, refrescar la lista
    if (result == true) {
      final colaboradorProvider = context.read<ColaboradorProvider>();
      await colaboradorProvider.cargarColaboradores();
    }
  }
}
