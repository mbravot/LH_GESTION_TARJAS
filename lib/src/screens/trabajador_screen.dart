import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/trabajador.dart';
import '../providers/auth_provider.dart';
import '../providers/trabajador_provider.dart';
import '../widgets/app_layout.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'trabajador_crear_screen.dart';
import 'trabajador_editar_screen.dart';

class TrabajadorScreen extends StatefulWidget {
  const TrabajadorScreen({super.key});

  @override
  State<TrabajadorScreen> createState() => _TrabajadorScreenState();
}

class _TrabajadorScreenState extends State<TrabajadorScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showFiltros = false;
  String _filtroActivo = 'todos'; // 'todos', 'activos', 'inactivos'

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  void _aplicarFiltro(String filtro) {
    setState(() {
      _filtroActivo = filtro;
    });
    
    final trabajadorProvider = context.read<TrabajadorProvider>();
    switch (filtro) {
      case 'activos':
        trabajadorProvider.setFiltroEstado('1');
        break;
      case 'inactivos':
        trabajadorProvider.setFiltroEstado('2');
        break;
      default: // 'todos'
        trabajadorProvider.setFiltroEstado('todos');
        break;
    }
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
    _searchController.dispose();
    super.dispose();
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
                icon: const Icon(Icons.person_add, size: 20),
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
    return Consumer<TrabajadorProvider>(
      builder: (context, trabajadorProvider, child) {
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
                   Colors.purple,
                   'todos',
                 ),
               ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTarjetaEstadistica(
                  'Activos',
                  trabajadorProvider.trabajadoresActivos.toString(),
                  Icons.check_circle,
                  Colors.green,
                  'activos',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTarjetaEstadistica(
                  'Inactivos',
                  trabajadorProvider.trabajadoresInactivos.toString(),
                  Icons.cancel,
                  Colors.red,
                  'inactivos',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTarjetaEstadistica(String titulo, String valor, IconData icono, Color color, String filtro) {
    final isActivo = _filtroActivo == filtro;
    
    return GestureDetector(
      onTap: () => _aplicarFiltro(filtro),
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
                fontWeight: isActivo ? FontWeight.w600 : FontWeight.w500,
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
                   if (trabajador.idEstado == '1') ...[
                     IconButton(
                       onPressed: () => _confirmarDesactivarTrabajador(trabajador),
                       icon: Icon(Icons.person_off, color: Colors.orange, size: 20),
                       tooltip: 'Desactivar trabajador',
                     ),
                   ] else ...[
                     IconButton(
                       onPressed: () => _confirmarActivarTrabajador(trabajador),
                       icon: Icon(Icons.person_add, color: Colors.green, size: 20),
                       tooltip: 'Activar trabajador',
                     ),
                   ],
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
                      child: Icon(
                        Icons.work,
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
                            trabajador.nombreCompleto,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: trabajador.estadoText == 'ACTIVO' 
                                ? Colors.green.withOpacity(0.2) 
                                : Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: trabajador.estadoText == 'ACTIVO' 
                                  ? Colors.green 
                                  : Colors.orange,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              trabajador.estadoText,
                              style: TextStyle(
                                color: trabajador.estadoText == 'ACTIVO' 
                                  ? Colors.green[700] 
                                  : Colors.orange[700],
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
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
                      // Información personal
                      _buildInfoSection(
                        'Información Personal',
                        Icons.person_outline,
                        [
                          _buildModernInfoRow('RUT', trabajador.rutCompleto, Icons.badge),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                                             // Información laboral
                       _buildInfoSection(
                         'Información Laboral',
                         Icons.work_outline,
                         [
                           _buildModernInfoRow('Contratista', trabajador.nombreContratista ?? 'No asignado', Icons.business),
                           _buildModernInfoRow('Porcentaje', trabajador.porcentajeFormateado, Icons.percent),
                                                       _buildModernInfoRow('Sucursal', trabajador.nombreSucursalFormateado, Icons.location_on),
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
                        icon: const Icon(Icons.close),
                        label: const Text('Cerrar'),
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
                          _mostrarDialogoEditarTrabajador(trabajador);
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: Colors.grey[600],
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

  void _mostrarDialogoCrearTrabajador() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TrabajadorCrearScreen(),
      ),
    );
    
    // Si se creó exitosamente un trabajador, refrescar la lista
    if (result == true) {
      final trabajadorProvider = context.read<TrabajadorProvider>();
      await trabajadorProvider.cargarTrabajadores();
    }
  }

  void _mostrarDialogoEditarTrabajador(Trabajador trabajador) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrabajadorEditarScreen(
          trabajadorId: trabajador.id,
        ),
      ),
    ).then((result) {
      // Si la edición fue exitosa, refrescar la lista
      if (result == true) {
        final trabajadorProvider = context.read<TrabajadorProvider>();
        trabajadorProvider.cargarTrabajadores();
      }
    });
  }

  void _confirmarDesactivarTrabajador(Trabajador trabajador) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Desactivación'),
        content: Text(
          '¿Estás seguro de que quieres desactivar a ${trabajador.nombreCompleto}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final trabajadorProvider = context.read<TrabajadorProvider>();
              final success = await trabajadorProvider.desactivarTrabajador(trabajador.id);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Trabajador desactivado correctamente'),
                    backgroundColor: Colors.orange,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al desactivar: ${trabajadorProvider.error}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
  }

  void _confirmarActivarTrabajador(Trabajador trabajador) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Activación'),
        content: Text(
          '¿Estás seguro de que quieres activar a ${trabajador.nombreCompleto}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final trabajadorProvider = context.read<TrabajadorProvider>();
              final success = await trabajadorProvider.activarTrabajador(trabajador.id);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Trabajador activado correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al activar: ${trabajadorProvider.error}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Activar'),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Trabajadores',
      onRefresh: _refrescarDatos,
      currentScreen: 'trabajadores',
      child: Column(
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


