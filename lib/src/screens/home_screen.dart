import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/permisos_provider.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'revision_tarjas_screen.dart';
import 'aprobacion_tarjas_screen.dart';
import 'cambiar_clave_screen.dart';
import 'ejemplo_permisos_screen.dart';
import '../widgets/sucursal_selector.dart';
import '../widgets/main_scaffold.dart';
import '../widgets/permiso_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Cargar permisos automáticamente si no están cargados
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final permisosProvider = context.read<PermisosProvider>();
      if (!permisosProvider.permisosCargados) {
        print('🔍 Cargando permisos automáticamente en HomeScreen...');
        permisosProvider.cargarPermisos();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Future<void> _confirmarCerrarSesion(BuildContext context, AuthProvider authProvider) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(
                Icons.logout,
                color: AppTheme.errorColor,
                size: 28,
              ),
              const SizedBox(width: 8),
              const Text('Cerrar Sesión'),
            ],
          ),
          content: const Text(
            '¿Estás seguro de que quieres cerrar sesión?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Cerrar Sesión',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        );
      },
    );

    if (result == true && context.mounted) {
      await authProvider.logout();
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: const InputDecoration(
        hintText: 'Buscar en el menú...',
        hintStyle: TextStyle(color: Colors.white70),
        border: InputBorder.none,
        prefixIcon: Icon(Icons.search, color: Colors.black54),
      ),
      style: const TextStyle(color: Colors.black),
      onChanged: (value) {
        // No hacer nada aquí para evitar SnackBars molestos
      },
      onSubmitted: (value) {
        if (value.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Búsqueda completada: $value'),
              duration: const Duration(seconds: 2),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
        setState(() => _isSearching = false);
      },
    );
  }

  List<Widget> _buildAppBarActions(ThemeProvider themeProvider, AuthProvider authProvider) {
    if (_isSearching) {
      return [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            if (_searchController.text.isEmpty) {
              setState(() => _isSearching = false);
            } else {
              _searchController.clear();
            }
          },
        ),
      ];
    }

    return [
      // Botón de búsqueda
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: () => setState(() => _isSearching = true),
      ),
      // Selector de sucursal global
      const SucursalSelector(),
      // Botón de tema
      IconButton(
        icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
        onPressed: () => themeProvider.toggleTheme(),
      ),
      // Botón de cerrar sesión
      IconButton(
        icon: const Icon(Icons.logout, color: Colors.white),
        onPressed: () => _confirmarCerrarSesion(context, authProvider),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return MainScaffold(
      title: 'LH Gestión Tarjas',
      onRefresh: () async {
        await authProvider.checkAuthStatus();
      },
      body: Column(
        children: [
          Expanded(
            child: _isSearching
            ? _buildSearchField()
                : _selectedIndex == 0
                    ? DashboardScreen()
                    : RevisionTarjasScreen(),
          ),
        ],
      ),
      drawer: _isSearching ? null : Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 35,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                          color: Colors.white,
                        ),
                        onPressed: () => themeProvider.toggleTheme(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (authProvider.userData != null) ...[
                    Text(
                      authProvider.userData!['nombre'] ?? 'Usuario',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sucursal: ${authProvider.userData!['nombre_sucursal'] ?? 'No especificada'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Dashboards
            const _MenuHeader(title: 'Dashboards'),
            _MenuItem(
              icon: Icons.dashboard,
              title: 'Dashboard Administrativas',
              onTap: () => _navigateTo(context, const DashboardScreen()),
            ),
            _MenuItem(
              icon: Icons.assignment,
              title: 'Dashboard Tarjas',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar navegación
              },
            ),

            // Gestión de Tarjas
            const _MenuHeader(title: 'Gestión de Tarjas'),
            _MenuItem(
              icon: Icons.factory,
              title: 'Avance por Plantas',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar navegación
              },
            ),
            PermisoWidget(
              idPermiso: 2,
              child: _MenuItem(
                icon: Icons.search,
              title: 'Revisión de Tarjas',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RevisionTarjasScreen()),
                );
              },
              ),
            ),
            PermisoWidget(
              idPermiso: 3,
              child: _MenuItem(
                icon: Icons.fact_check,
                title: 'Aprobación de Tarjas',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AprobacionTarjasScreen()),
                  );
                },
              ),
            ),
            _MenuItem(
              icon: Icons.business,
              title: 'Tarja Propios',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar navegación
              },
            ),
            _MenuItem(
              icon: Icons.engineering,
              title: 'Tarja Contratista',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar navegación
              },
            ),

            // Gestión de Personal
            const _MenuHeader(title: 'Gestión de Personal'),
            _MenuItem(
              icon: Icons.person_outline,
              title: 'Ficha Personal',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar navegación
              },
            ),
            _MenuItem(
              icon: Icons.medical_services,
              title: 'Licencias',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar navegación
              },
            ),
            _MenuItem(
              icon: Icons.beach_access,
              title: 'Vacaciones',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar navegación
              },
            ),
            _MenuItem(
              icon: Icons.time_to_leave,
              title: 'Permisos',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar navegación
              },
            ),
            _MenuItem(
              icon: Icons.person_off,
              title: 'Inasistencias',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar navegación
              },
            ),

            // Gestión de Trabajadores
            const _MenuHeader(title: 'Gestión de Trabajadores'),
            _MenuItem(
              icon: Icons.groups,
              title: 'Trabajadores',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar navegación
              },
            ),
            _MenuItem(
              icon: Icons.person_add,
              title: 'Pre-enrolados',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar navegación
              },
            ),
            _MenuItem(
              icon: Icons.person_off_outlined,
              title: 'Desactivar Usuarios',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar navegación
              },
            ),

            // Control de Horas y Bonos
            const _MenuHeader(title: 'Control de Horas y Bonos'),
            _MenuItem(
              icon: Icons.access_time,
              title: 'Horas Trabajadas',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar navegación
              },
            ),
            _MenuItem(
              icon: Icons.more_time,
              title: 'Horas Extras',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar navegación
              },
            ),
            _MenuItem(
              icon: Icons.card_giftcard,
              title: 'Bono Especial',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar navegación
              },
            ),

            // Reportes y Edición
            const _MenuHeader(title: 'Reportes y Edición'),
            _MenuItem(
              icon: Icons.analytics,
              title: 'Detalle Mano de Obra',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar navegación
              },
            ),

            // Sistema de Permisos
            const _MenuHeader(title: 'Sistema de Permisos'),
            _MenuItem(
              icon: Icons.security,
              title: 'Ejemplo de Permisos',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EjemploPermisosScreen()),
                );
              },
            ),
            _MenuItem(
              icon: Icons.bug_report,
              title: 'Debug Permisos',
              onTap: () {
                Navigator.pop(context);
                final permisosProvider = Provider.of<PermisosProvider>(context, listen: false);
                print('🔍 Debug - Permisos actuales:');
                print('   - Total: ${permisosProvider.permisos.length}');
                for (var permiso in permisosProvider.permisos) {
                  print('   - ID: ${permiso['id']} (${permiso['id'].runtimeType}), Nombre: ${permiso['nombre']}');
                }
                print('🔍 Debug - Verificando permiso ID 2: ${permisosProvider.tienePermisoPorId(2)}');
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Permisos: ${permisosProvider.permisos.length}, ID 2: ${permisosProvider.tienePermisoPorId(2)}'),
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
            ),
            _MenuItem(
              icon: Icons.upload_file,
              title: 'Carga Agriprime',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar navegación
              },
            ),
            _MenuItem(
              icon: Icons.edit,
              title: 'Edición de Datos',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar navegación
              },
            ),

            const Divider(),
            _MenuItem(
              icon: Icons.lock,
              title: 'Cambiar Contraseña',
              iconColor: Colors.amber,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CambiarClaveScreen()),
                );
              },
            ),
            _MenuItem(
              icon: Icons.exit_to_app,
              title: 'Cerrar Sesión',
              iconColor: AppTheme.errorColor,
              onTap: () {
                Navigator.pop(context);
                _confirmarCerrarSesion(context, authProvider);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuHeader extends StatelessWidget {
  final String title;

  const _MenuHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? Theme.of(context).primaryColor,
      ),
      title: Text(title),
      onTap: onTap,
      dense: true,
    );
  }
} 