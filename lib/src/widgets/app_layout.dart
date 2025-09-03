import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/permisos_provider.dart';
import '../theme/app_theme.dart';
import '../screens/revision_tarjas_screen.dart';
import '../screens/aprobacion_tarjas_screen.dart';
import '../screens/colaborador_screen.dart';
import '../screens/licencias_screen.dart';
import '../screens/vacaciones_screen.dart';
import '../screens/permiso_screen.dart';
import '../screens/horas_trabajadas_screen.dart';
import '../screens/horas_extras_screen.dart';
import '../screens/horas_extras_otroscecos_screen.dart';
import '../screens/bono_especial_screen.dart';
import '../screens/trabajador_screen.dart';
import '../screens/contratista_screen.dart';
import '../screens/ejemplo_permisos_screen.dart';
import '../screens/home_screen.dart';
import '../screens/info_screen.dart';
import '../screens/cambiar_clave_screen.dart';
import '../screens/login_screen.dart';
import 'sucursal_selector.dart';
import 'user_info.dart';

class AppLayout extends StatefulWidget {
  final Widget child;
  final String? title;
  final VoidCallback? onRefresh;
  final String? currentScreen;

  const AppLayout({
    Key? key,
    required this.child,
    this.title,
    this.onRefresh,
    this.currentScreen,
  }) : super(key: key);

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // Sidebar colapsable
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return ClipRect(
                  child: Container(
                    width: _isExpanded ? 280 : 70,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(2, 0),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Header del sidebar
                        Container(
                          height: 80,
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              if (_isExpanded) ...[
                                // Logo y título cuando está expandido
                                ClipOval(
                                  child: Image.asset(
                                    'assets/images/lh.jpg',
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'LH GESTIÓN',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ] else ...[
                                // Solo logo cuando está colapsado
                                Expanded(
                                  child: Center(
                                    child: ClipOval(
                                      child: Image.asset(
                                        'assets/images/lh.jpg',
                                        width: 32,
                                        height: 32,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              // Botón de toggle solo cuando está expandido
                              if (_isExpanded)
                                IconButton(
                                  icon: const Icon(
                                    Icons.chevron_left,
                                    color: Colors.white,
                                  ),
                                  onPressed: _toggleSidebar,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        // Menú principal
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                // Dashboards
                                _buildMenuSection(
                                  'Dashboards',
                                  [
                                    _buildMenuItem(
                                      icon: Icons.dashboard,
                                      title: 'Inicio',
                                      onTap: () => _navigateToScreen(context, HomeScreen()),
                                      screenKey: 'home',
                                    ),
                                  ],
                                ),
                                
                                // Gestión de Tarjas
                                _buildMenuSection(
                                  'Gestión de Tarjas',
                                  [
                                    _buildMenuItem(
                                      icon: Icons.search,
                                      title: 'Revisión de Tarjas',
                                      onTap: () => _navigateToScreen(context, RevisionTarjasScreen()),
                                      permissionId: 2,
                                      screenKey: 'revision_tarjas',
                                    ),
                                    _buildMenuItem(
                                      icon: Icons.fact_check,
                                      title: 'Aprobación de Tarjas',
                                      onTap: () => _navigateToScreen(context, AprobacionTarjasScreen()),
                                      permissionId: 3,
                                      screenKey: 'aprobacion_tarjas',
                                    ),
                                  ],
                                ),
                                
                                // Gestión de Personal
                                _buildMenuSection(
                                  'Gestión de Personal',
                                  [
                                    _buildMenuItem(
                                      icon: Icons.people,
                                      title: 'Colaboradores',
                                      onTap: () => _navigateToScreen(context, ColaboradorScreen()),
                                      screenKey: 'colaboradores',
                                    ),
                                    _buildMenuItem(
                                      icon: Icons.medical_services,
                                      title: 'Licencias',
                                      onTap: () => _navigateToScreen(context, LicenciasScreen()),
                                      screenKey: 'licencias',
                                    ),
                                    _buildMenuItem(
                                      icon: Icons.beach_access,
                                      title: 'Vacaciones',
                                      onTap: () => _navigateToScreen(context, VacacionesScreen()),
                                      screenKey: 'vacaciones',
                                    ),
                                    _buildMenuItem(
                                      icon: Icons.assignment_turned_in,
                                      title: 'Permisos',
                                      onTap: () => _navigateToScreen(context, PermisoScreen()),
                                      screenKey: 'permisos',
                                    ),
                                  ],
                                ),
                                
                                // Control de Horas y Bonos
                                _buildMenuSection(
                                  'Control de Horas y Bonos',
                                  [
                                    _buildMenuItem(
                                      icon: Icons.access_time,
                                      title: 'Horas Trabajadas',
                                      onTap: () => _navigateToScreen(context, HorasTrabajadasScreen()),
                                      screenKey: 'horas_trabajadas',
                                    ),
                                    _buildMenuItem(
                                      icon: Icons.more_time,
                                      title: 'Horas Extras',
                                      onTap: () => _navigateToScreen(context, HorasExtrasScreen()),
                                      screenKey: 'horas_extras',
                                    ),
                                    _buildMenuItem(
                                      icon: Icons.add_circle_outline,
                                      title: 'Horas Extras Otros Cecos',
                                      onTap: () => _navigateToScreen(context, HorasExtrasOtrosCecosScreen()),
                                      screenKey: 'horas_extras_otroscecos',
                                    ),
                                    _buildMenuItem(
                                      icon: Icons.card_giftcard,
                                      title: 'Bono Especial',
                                      onTap: () => _navigateToScreen(context, BonoEspecialScreen()),
                                      screenKey: 'bono_especial',
                                    ),
                                  ],
                                ),
                                
                                // Gestión de Trabajadores
                                _buildMenuSection(
                                  'Gestión de Trabajadores',
                                  [
                                    _buildMenuItem(
                                      icon: Icons.people,
                                      title: 'Trabajadores',
                                      onTap: () => _navigateToScreen(context, TrabajadorScreen()),
                                      screenKey: 'trabajadores',
                                    ),
                                    _buildMenuItem(
                                      icon: Icons.groups,
                                      title: 'Contratistas',
                                      onTap: () => _navigateToScreen(context, ContratistaScreen()),
                                      screenKey: 'contratistas',
                                    ),
                                  ],
                                ),
                                
                                // Sistema de Permisos
                                _buildMenuSection(
                                  'Sistema de Permisos',
                                  [
                                    _buildMenuItem(
                                      icon: Icons.security,
                                      title: 'Ejemplo de Permisos',
                                      onTap: () => _navigateToScreen(context, EjemploPermisosScreen()),
                                      screenKey: 'ejemplo_permisos',
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 20),
                                
                                // Opciones del sistema
                                _buildMenuItem(
                                  icon: Icons.info,
                                  title: 'Acerca de',
                                  onTap: () => _navigateToScreen(context, InfoScreen()),
                                  iconColor: Colors.blue,
                                  screenKey: 'info',
                                ),
                                _buildMenuItem(
                                  icon: Icons.lock,
                                  title: 'Cambiar Contraseña',
                                  onTap: () => _navigateToScreen(context, CambiarClaveScreen()),
                                  iconColor: Colors.amber,
                                  screenKey: 'cambiar_clave',
                                ),
                                _buildMenuItem(
                                  icon: Icons.exit_to_app,
                                  title: 'Cerrar Sesión',
                                  onTap: () => _confirmarCerrarSesion(context, authProvider),
                                  iconColor: AppTheme.errorColor,
                                  screenKey: 'logout',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            // Contenido principal
            Expanded(
              child: Column(
                children: [
                  // AppBar personalizado
                  Container(
                    height: 80,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Botón de menú
                        IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white),
                          onPressed: _toggleSidebar,
                        ),
                        
                        // Título
                        if (widget.title != null) ...[
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              widget.title!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        
                        // Acciones del usuario
                        const UserInfo(),
                        const SucursalSelector(),
                        
                        // Botón de actualizar
                        if (widget.onRefresh != null)
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            onPressed: widget.onRefresh,
                          ),
                        
                        // Botón de tema
                        IconButton(
                          icon: Icon(
                            themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                            color: Colors.white,
                          ),
                          onPressed: () => themeProvider.toggleTheme(),
                        ),
                        
                        // Botón de cerrar sesión
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          onPressed: () => _confirmarCerrarSesion(context, authProvider),
                        ),
                      ],
                    ),
                  ),
                  
                  // Contenido del body
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isExpanded) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
        ...children,
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    int? permissionId,
    String? screenKey,
  }) {
    // Verificar permisos si se especifica
    if (permissionId != null) {
      final permisosProvider = Provider.of<PermisosProvider>(context, listen: false);
      if (!permisosProvider.tienePermisoPorId(permissionId)) {
        return const SizedBox.shrink();
      }
    }

    // Determinar si este elemento está activo
    final isActive = widget.currentScreen != null && 
                     screenKey != null && 
                     widget.currentScreen == screenKey;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isActive ? Border.all(color: Colors.white.withOpacity(0.3), width: 1) : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: Tooltip(
                message: title,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: _isExpanded ? 16 : 8,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        color: isActive ? Colors.yellow : (iconColor ?? Colors.white),
                        size: 24,
                      ),
                      if (_isExpanded) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: isActive ? Colors.yellow : Colors.white,
                              fontSize: 14,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateToScreen(BuildContext context, dynamic screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _confirmarCerrarSesion(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Cierre de Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Cerrar sesión en el AuthProvider
              await authProvider.logout();
              // Navegar a la pantalla de login y limpiar el stack de navegación
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                  (route) => false, // Remover todas las rutas del stack
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}
