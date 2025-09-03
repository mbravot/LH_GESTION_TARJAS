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
import '../screens/info_screen.dart';
import '../screens/cambiar_clave_screen.dart';

class CollapsibleDrawer extends StatefulWidget {
  const CollapsibleDrawer({Key? key}) : super(key: key);

  @override
  State<CollapsibleDrawer> createState() => _CollapsibleDrawerState();
}

class _CollapsibleDrawerState extends State<CollapsibleDrawer>
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

  void _toggleDrawer() {
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
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
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
              // Header del drawer
              Container(
                height: 80,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (_isExpanded) ...[
                      // Logo y título cuando está expandido
                      Icon(
                        Icons.agriculture,
                        color: Colors.white,
                        size: 32,
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
                      // Solo icono cuando está colapsado
                      Icon(
                        Icons.agriculture,
                        color: Colors.white,
                        size: 32,
                      ),
                    ],
                    // Botón de toggle
                    IconButton(
                      icon: Icon(
                        _isExpanded ? Icons.chevron_left : Icons.chevron_right,
                        color: Colors.white,
                      ),
                      onPressed: _toggleDrawer,
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
                            title: 'Dashboard General',
                            onTap: () => _navigateToScreen(context, '/'),
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
                          ),
                          _buildMenuItem(
                            icon: Icons.fact_check,
                            title: 'Aprobación de Tarjas',
                            onTap: () => _navigateToScreen(context, AprobacionTarjasScreen()),
                            permissionId: 3,
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
                          ),
                          _buildMenuItem(
                            icon: Icons.medical_services,
                            title: 'Licencias',
                            onTap: () => _navigateToScreen(context, LicenciasScreen()),
                          ),
                          _buildMenuItem(
                            icon: Icons.beach_access,
                            title: 'Vacaciones',
                            onTap: () => _navigateToScreen(context, VacacionesScreen()),
                          ),
                          _buildMenuItem(
                            icon: Icons.assignment_turned_in,
                            title: 'Permisos',
                            onTap: () => _navigateToScreen(context, PermisoScreen()),
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
                          ),
                          _buildMenuItem(
                            icon: Icons.more_time,
                            title: 'Horas Extras',
                            onTap: () => _navigateToScreen(context, HorasExtrasScreen()),
                          ),
                          _buildMenuItem(
                            icon: Icons.add_circle_outline,
                            title: 'Horas Extras Otros Cecos',
                            onTap: () => _navigateToScreen(context, HorasExtrasOtrosCecosScreen()),
                          ),
                          _buildMenuItem(
                            icon: Icons.card_giftcard,
                            title: 'Bono Especial',
                            onTap: () => _navigateToScreen(context, BonoEspecialScreen()),
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
                          ),
                          _buildMenuItem(
                            icon: Icons.groups,
                            title: 'Contratistas',
                            onTap: () => _navigateToScreen(context, ContratistaScreen()),
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
                      ),
                      _buildMenuItem(
                        icon: Icons.lock,
                        title: 'Cambiar Contraseña',
                        onTap: () => _navigateToScreen(context, CambiarClaveScreen()),
                        iconColor: Colors.amber,
                      ),
                      _buildMenuItem(
                        icon: Icons.exit_to_app,
                        title: 'Cerrar Sesión',
                        onTap: () => _confirmarCerrarSesion(context, authProvider),
                        iconColor: AppTheme.errorColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
  }) {
    // Verificar permisos si se especifica
    if (permissionId != null) {
      final permisosProvider = Provider.of<PermisosProvider>(context, listen: false);
      if (!permisosProvider.tienePermisoPorId(permissionId)) {
        return const SizedBox.shrink();
      }
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: _isExpanded ? 16 : 8,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: iconColor ?? Colors.white,
                      size: 24,
                    ),
                    if (_isExpanded) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
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
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}
