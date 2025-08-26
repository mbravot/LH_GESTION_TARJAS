import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/permiso_provider.dart';
import '../providers/colaborador_provider.dart';
import '../providers/auth_provider.dart';
import '../models/permiso.dart';
import '../widgets/main_scaffold.dart';
import '../theme/app_theme.dart';
import '../theme/dark_theme_colors.dart';
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
        final theme = Theme.of(context);
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DarkThemeColors.containerColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: DarkThemeColors.borderColor,
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
    final theme = Theme.of(context);
    final stateColor = DarkThemeColors.getStateColor(color);
    
    return GestureDetector(
      onTap: () => _aplicarFiltro(filtro),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActivo ? DarkThemeColors.getBackgroundWithOpacity(stateColor, 0.2) : DarkThemeColors.getBackgroundWithOpacity(stateColor, 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActivo ? stateColor : stateColor.withOpacity(0.3),
            width: isActivo ? 2 : 1,
          ),
          boxShadow: isActivo ? [
            BoxShadow(
              color: stateColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Column(
          children: [
            Icon(
              icono, 
              color: stateColor, 
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              valor,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: stateColor,
              ),
            ),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 10,
                color: stateColor.withOpacity(0.8),
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
                  color: stateColor,
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
                    color: Colors.purple,
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
                       // Si estamos en la vista "Por Aprobar", mostrar botón de aprobar
                       if (_filtroActivo == 'porAprobar' && permiso.estado == 'Creado')
                         IconButton(
                           icon: Icon(Icons.check_circle, color: AppTheme.successColor, size: 20),
                           onPressed: () => _mostrarDialogoAprobarPermiso(permiso),
                           tooltip: 'Aprobar',
                         )
                       else ...[
                         // Botón de editar (solo para Creados y Aprobados)
                         if (permiso.sePuedeEditar)
                           IconButton(
                             icon: Icon(Icons.edit, color: Colors.green, size: 20),
                             onPressed: () => _mostrarDialogoEditarPermiso(permiso),
                             tooltip: 'Editar',
                           ),
                         // Botón de eliminar (solo para Creados y Aprobados)
                         if (permiso.sePuedeEliminar)
                           IconButton(
                             icon: Icon(Icons.delete, color: AppTheme.errorColor, size: 20),
                             onPressed: () => _mostrarDialogoEliminarPermiso(permiso),
                             tooltip: 'Eliminar',
                           ),
                       ],
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
      case 'Creado':
        return Icons.create;
      case 'Aprobado':
        return Icons.check_circle;
      case 'Por Aprobar':
        return Icons.pending;
      default:
        return Icons.assignment;
    }
  }

  void _mostrarDetallesPermiso(Permiso permiso) {
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
                        Icons.access_time,
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
                            'Detalles del Permiso',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            permiso.nombreCompletoColaborador,
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
                      _buildModernInfoRow('Colaborador', permiso.nombreCompletoColaborador, Icons.person),
                      
                      // Información del permiso
                      _buildModernInfoRow('Tipo de Permiso', permiso.tipoPermiso ?? 'Sin especificar', Icons.category),
                      _buildModernInfoRow('Fecha', permiso.fechaFormateadaEspanol, Icons.calendar_today),
                      _buildModernInfoRow('Horas', '${permiso.horas} horas', Icons.schedule),
                      
                      // Estado
                      _buildModernInfoRow('Estado', permiso.estadoPermiso ?? 'Sin especificar', Icons.info),
                      
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
                          _mostrarDialogoEditarPermiso(permiso);
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
    } else if (icon == Icons.category) {
      iconColor = Colors.purple;
      backgroundColor = Colors.purple.withOpacity(0.1);
    } else if (icon == Icons.calendar_today) {
      iconColor = Colors.orange;
      backgroundColor = Colors.orange.withOpacity(0.1);
    } else if (icon == Icons.schedule) {
      iconColor = Colors.green;
      backgroundColor = Colors.green.withOpacity(0.1);
    } else if (icon == Icons.info) {
      iconColor = Colors.indigo;
      backgroundColor = Colors.indigo.withOpacity(0.1);
    } else if (icon == Icons.access_time) {
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

  void _mostrarDialogoAprobarPermiso(Permiso permiso) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Aprobación'),
        content: Text(
          '¿Estás seguro de que quieres aprobar el permiso de ${permiso.nombreCompletoColaborador}?',
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
              final response = await permisoProvider.aprobarPermiso(permiso.id);
              if (response != null) {
                // Mostrar información detallada del permiso aprobado
                final permisoAprobado = response['permiso_aprobado'];
                final colaborador = permisoAprobado['colaborador'] ?? permiso.nombreCompletoColaborador;
                final fecha = permisoAprobado['fecha'] ?? permiso.fecha;
                final estadoAnterior = permisoAprobado['estado_anterior'] ?? 'Pendiente';
                final estadoNuevo = permisoAprobado['estado_nuevo'] ?? 'Aprobado';
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '✅ Permiso aprobado correctamente',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text('Colaborador: $colaborador'),
                        Text('Fecha: $fecha'),
                        Text('Estado: $estadoAnterior → $estadoNuevo'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 4),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al aprobar: ${permisoProvider.error}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Permisos',
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


