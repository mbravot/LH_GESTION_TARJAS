import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/usuario.dart';
import '../providers/usuario_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/main_scaffold.dart';
import '../theme/app_theme.dart';
import 'usuario_crear_screen.dart';
import 'usuario_editar_screen.dart';

class UsuarioScreen extends StatefulWidget {
  const UsuarioScreen({super.key});

  @override
  State<UsuarioScreen> createState() => _UsuarioScreenState();
}

class _UsuarioScreenState extends State<UsuarioScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showFiltros = false;
  String _filtroActivo = 'todos'; // 'todos', 'activos', 'inactivos'

  @override
  void initState() {
    super.initState();
    // Cargar datos cuando el usuario navegue a la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatos();
    });
  }

  Future<void> _cargarDatos() async {
    final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

    // Inicializar provider si no está inicializado
    usuarioProvider.initialize(authProvider, notificationProvider);

    // Cargar datos solo si no están cargados
    if (usuarioProvider.usuarios.isEmpty) {
      await usuarioProvider.cargarUsuarios();
    }
    if (usuarioProvider.sucursales.isEmpty) {
      await usuarioProvider.cargarSucursales();
    }
    // Cargar permisos solo si es necesario
    await usuarioProvider.cargarPermisosDisponibles();
  }

  // Método para refrescar datos desde el AppBar
  Future<void> _refrescarDatos() async {
    final usuarioProvider = context.read<UsuarioProvider>();
    await usuarioProvider.cargarUsuarios();
    await usuarioProvider.cargarSucursales();
  }

  void _filtrarUsuarios() {
    final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);
    usuarioProvider.setFiltroBusqueda(_searchQuery);
  }

  void _limpiarFiltros() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _filtroActivo = 'todos';
    });
    final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);
    usuarioProvider.limpiarFiltros();
  }

  void _aplicarFiltro(String filtro) {
    setState(() {
      _filtroActivo = filtro;
    });
    
    final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);
    switch (filtro) {
      case 'activos':
        usuarioProvider.setFiltroEstado('1');
        break;
      case 'inactivos':
        usuarioProvider.setFiltroEstado('2');
        break;
      default: // 'todos'
        usuarioProvider.setFiltroEstado('todos');
        break;
    }
  }

  String _formatearFechaCreacion(String? fechaStr) {
    if (fechaStr == null || fechaStr.isEmpty) return 'Sin fecha';
    
    try {
      // El backend envía formato "Mon, 15 Sep 2025 00:00:00 GMT"
      // Extraer solo la parte de fecha: "15 Sep 2025"
      final partes = fechaStr.split(', ')[1].split(' ')[0]; // "15"
      final mesStr = fechaStr.split(', ')[1].split(' ')[1]; // "Sep"
      final anio = fechaStr.split(', ')[1].split(' ')[2]; // "2025"
      
      // Convertir mes abreviado a número
      final meses = {
        'Jan': '01', 'Feb': '02', 'Mar': '03', 'Apr': '04',
        'May': '05', 'Jun': '06', 'Jul': '07', 'Aug': '08',
        'Sep': '09', 'Oct': '10', 'Nov': '11', 'Dec': '12'
      };
      
      final mes = meses[mesStr] ?? '01';
      final dia = partes.padLeft(2, '0');
      
      return '$dia/$mes/$anio';
    } catch (e) {
      return fechaStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchAndFilters(),
        _buildEstadisticas(),
        Expanded(
          child: Consumer<UsuarioProvider>(
            builder: (context, usuarioProvider, child) {
              if (usuarioProvider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (usuarioProvider.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar los usuarios',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        usuarioProvider.error!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _refrescarDatos,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }

              return _buildListaUsuarios(usuarioProvider);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, usuario o correo...',
              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                        _filtrarUsuarios();
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
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _filtrarUsuarios();
            },
          ),
          
          const SizedBox(height: 12),
          
          // Botones de acción (Nuevo y Filtros)
          Row(
            children: [
              // Botón de filtros
              Expanded(
                flex: 4,
                child: Consumer<UsuarioProvider>(
                  builder: (context, provider, child) {
                    final tieneFiltrosActivos = _tieneFiltrosActivos(provider);

                    return ElevatedButton.icon(
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
                    );
                  },
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Botón Nuevo
              Expanded(
                flex: 1,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const UsuarioCrearScreen(),
                      ),
                    ).then((_) => _refrescarDatos());
                  },
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Nuevo Usuario', style: TextStyle(fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
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
          
          // Filtros expandibles
          if (_showFiltros) ...[
            const SizedBox(height: 16),
            _buildFiltros(),
          ],
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Consumer<UsuarioProvider>(
      builder: (context, usuarioProvider, child) {
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
          
          // Filtro por sucursal
          DropdownButtonFormField<String>(
            value: usuarioProvider.filtroSucursal.isEmpty 
                ? null 
                : usuarioProvider.filtroSucursal,
            decoration: const InputDecoration(
              labelText: 'Sucursal',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: '',
                child: Text('Todas las sucursales'),
              ),
              ...usuarioProvider.sucursales.map((sucursal) => DropdownMenuItem<String>(
                value: sucursal['id'].toString(),
                child: Text(sucursal['nombre'] ?? 'Sucursal ${sucursal['id']}'),
              )),
            ],
            onChanged: (value) {
              usuarioProvider.setFiltroSucursal(value ?? '');
            },
          ),
          
          const SizedBox(height: 16),
          
          // Botón limpiar filtros
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _limpiarFiltros,
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
    return Consumer<UsuarioProvider>(
      builder: (context, usuarioProvider, child) {
        final usuarios = usuarioProvider.usuarios; // Usar la lista completa, no filtrada
        final totalUsuarios = usuarios.length;
        final usuariosActivos = usuarios.where((u) => u.idEstado == 1).length;
        final usuariosInactivos = usuarios.where((u) => u.idEstado != 1).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildTarjetaEstadistica(
              'Total Usuarios',
              totalUsuarios.toString(),
              Icons.people,
              Colors.blue,
              filtro: 'todos',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildTarjetaEstadistica(
              'Usuarios Activos',
              usuariosActivos.toString(),
              Icons.check_circle,
              Colors.green,
              filtro: 'activos',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildTarjetaEstadistica(
              'Usuarios Inactivos',
              usuariosInactivos.toString(),
              Icons.cancel,
              Colors.red,
              filtro: 'inactivos',
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildTarjetaEstadistica(String titulo, String valor, IconData icono, Color color, {String? filtro}) {
    final isActivo = filtro != null && _filtroActivo == filtro;
    
    return GestureDetector(
      onTap: filtro != null ? () => _aplicarFiltro(filtro) : null,
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
              child: Icon(
                icono, 
                color: isActivo ? color : color.withOpacity(0.8), 
                size: 20
              ),
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
                      color: isActivo ? color.withOpacity(0.8) : Colors.grey[600],
                      fontWeight: isActivo ? FontWeight.w600 : FontWeight.w500,
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
            if (filtro != null)
              Icon(
                Icons.filter_list,
                color: isActivo ? color : Colors.grey[400],
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildListaUsuarios(UsuarioProvider usuarioProvider) {
    final usuarios = usuarioProvider.usuariosFiltrados;

    if (usuarios.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: usuarios.length,
        itemBuilder: (context, index) {
          final usuario = usuarios[index];
          return _buildTarjetaUsuario(usuario);
        },
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay usuarios registrados',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega un nuevo usuario para comenzar',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTarjetaUsuario(Usuario usuario) {
    final theme = Theme.of(context);
    final cardColor = theme.colorScheme.surface;
    final borderColor = usuario.idEstado == 1 ? Colors.green[300]! : Colors.red[300]!;
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
        onTap: () => _mostrarDetallesUsuario(usuario),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título con icono
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: usuario.idEstado == 1 ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.person,
                      color: usuario.idEstado == 1 ? Colors.green : Colors.red,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      usuario.nombreCompletoDisplay,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                  ),
                  // Estado
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: usuario.idEstado == 1 ? Colors.green[100] : Colors.red[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      usuario.estadoText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: usuario.idEstado == 1 ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Contenido en columnas
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Columna 1: Usuario y Correo
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.account_circle, color: AppTheme.primaryColor, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Usuario: ${usuario.usuario}',
                                style: TextStyle(
                                  color: textColor.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.email, color: Colors.blue, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Correo: ${usuario.correo}',
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
                  // Columna 2: Sucursal
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.business, color: Colors.orange, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Sucursal: ${usuario.nombreSucursal ?? usuario.idSucursalActiva}',
                                style: TextStyle(
                                  color: textColor.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (usuario.fechaCreacion != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.purple, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Creado: ${_formatearFechaCreacion(usuario.fechaCreacion)}',
                                  style: TextStyle(
                                    color: textColor.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Columna 3: Estado, Desactivar/Activar, Editar
                  Expanded(
                    flex: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (usuario.idEstado == 1) ...[
                          IconButton(
                            onPressed: () => _confirmarDesactivarUsuario(usuario),
                            icon: Icon(Icons.person_off, color: Colors.orange, size: 20),
                            tooltip: 'Desactivar usuario',
                          ),
                        ] else ...[
                          IconButton(
                            onPressed: () => _confirmarActivarUsuario(usuario),
                            icon: Icon(Icons.person_add, color: Colors.green, size: 20),
                            tooltip: 'Activar usuario',
                          ),
                        ],
                        IconButton(
                          onPressed: () => _editarUsuario(usuario),
                          icon: Icon(Icons.edit, color: AppTheme.primaryColor, size: 20),
                          tooltip: 'Editar usuario',
                        ),
                        IconButton(
                          onPressed: () => _eliminarUsuario(usuario),
                          icon: Icon(Icons.delete, color: Colors.red, size: 20),
                          tooltip: 'Eliminar usuario',
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

  void _mostrarDetallesUsuario(Usuario usuario) {
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
                        Icons.person,
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
                            usuario.nombreCompletoDisplay,
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
                              color: usuario.idEstado == 1 
                                ? Colors.green.withOpacity(0.2) 
                                : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: usuario.idEstado == 1 
                                  ? Colors.green 
                                  : Colors.red,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              usuario.estadoText,
                              style: TextStyle(
                                color: usuario.idEstado == 1 
                                  ? Colors.green[700] 
                                  : Colors.red[700],
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
              
              // Contenido del modal
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildModernInfoRow('Usuario', usuario.usuario, Icons.person_outline),
                    _buildModernInfoRow('Correo', usuario.correo, Icons.email),
                    _buildModernInfoRow('Sucursal', usuario.nombreSucursal ?? usuario.idSucursalActiva.toString(), Icons.business),
                    if (usuario.fechaCreacion != null)
                      _buildModernInfoRow('Fecha de Creación', _formatearFechaCreacion(usuario.fechaCreacion), Icons.calendar_today),
                  ],
                ),
              ),
              
              // Botones
              Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cerrar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _editarUsuario(usuario);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Editar'),
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

  Widget _buildModernInfoRow(String titulo, String valor, IconData icono) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icono,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editarUsuario(Usuario usuario) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UsuarioEditarScreen(usuario: usuario),
      ),
    ).then((_) => _refrescarDatos());
  }

  void _eliminarUsuario(Usuario usuario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Usuario'),
        content: Text(
          '¿Está seguro de que desea eliminar el usuario ${usuario.nombreCompleto}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);
              final success = await usuarioProvider.eliminarUsuario(usuario.id);
              
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Usuario eliminado correctamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar: ${usuarioProvider.error ?? 'Error desconocido'}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // Método para verificar si hay filtros activos
  bool _tieneFiltrosActivos(UsuarioProvider usuarioProvider) {
    return usuarioProvider.filtroSucursal.isNotEmpty || 
           usuarioProvider.filtroEstado != 'todos';
  }

  void _confirmarDesactivarUsuario(Usuario usuario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Desactivación'),
        content: Text(
          '¿Estás seguro de que quieres desactivar a ${usuario.nombreCompletoDisplay}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final usuarioProvider = context.read<UsuarioProvider>();
              final success = await usuarioProvider.desactivarUsuario(usuario.id);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Usuario desactivado correctamente'),
                    backgroundColor: Colors.orange,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al desactivar: ${usuarioProvider.error}'),
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

  void _confirmarActivarUsuario(Usuario usuario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Activación'),
        content: Text(
          '¿Estás seguro de que quieres activar a ${usuario.nombreCompletoDisplay}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final usuarioProvider = context.read<UsuarioProvider>();
              final success = await usuarioProvider.activarUsuario(usuario.id);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Usuario activado correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al activar: ${usuarioProvider.error}'),
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
