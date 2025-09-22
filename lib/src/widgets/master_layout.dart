import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/permisos_provider.dart';
import '../providers/sidebar_provider.dart';
import '../providers/tarja_provider.dart';
import '../providers/horas_trabajadas_provider.dart';
import '../providers/horas_extras_provider.dart';
import '../providers/horas_extras_otroscecos_provider.dart';
import '../providers/colaborador_provider.dart';
import '../providers/licencia_provider.dart';
import '../providers/vacacion_provider.dart';
import '../providers/permiso_provider.dart';
import '../providers/bono_especial_provider.dart';
import '../providers/trabajador_provider.dart';
import '../providers/contratista_provider.dart';
import '../providers/sueldo_base_provider.dart';
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
import '../screens/sueldo_base_screen.dart';
import '../screens/indicadores_screen.dart';
import '../screens/ejemplo_permisos_screen.dart';
import '../screens/info_screen.dart';
import '../screens/cambiar_clave_screen.dart';
import '../screens/login_screen.dart';
import 'sucursal_selector.dart';
import 'user_info.dart';
import 'user_name_widget.dart';
import 'weather_widget.dart';

class MasterLayout extends StatefulWidget {
  const MasterLayout({super.key});

  @override
  State<MasterLayout> createState() => _MasterLayoutState();
}

class _MasterLayoutState extends State<MasterLayout>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _currentScreenIndex = 0;

  // Lista de todas las pantallas disponibles
  final List<Map<String, dynamic>> _screens = [
    {'key': 'home', 'screen': _HomeContent(), 'title': 'Inicio'},
    {'key': 'indicadores', 'screen': IndicadoresScreen(), 'title': 'Indicadores'},
    {'key': 'revision_tarjas', 'screen': RevisionTarjasScreen(), 'title': 'Revisión de Tarjas'},
    {'key': 'aprobacion_tarjas', 'screen': AprobacionTarjasScreen(), 'title': 'Aprobación de Tarjas'},
    {'key': 'colaboradores', 'screen': ColaboradorScreen(), 'title': 'Colaboradores'},
    {'key': 'licencias', 'screen': LicenciasScreen(), 'title': 'Licencias'},
    {'key': 'vacaciones', 'screen': VacacionesScreen(), 'title': 'Vacaciones'},
    {'key': 'permisos', 'screen': PermisoScreen(), 'title': 'Permisos'},
    {'key': 'horas_trabajadas', 'screen': HorasTrabajadasScreen(), 'title': 'Horas Trabajadas'},
    {'key': 'horas_extras', 'screen': HorasExtrasScreen(), 'title': 'Horas Extras'},
    {'key': 'horas_extras_otroscecos', 'screen': HorasExtrasOtrosCecosScreen(), 'title': 'Horas Extras Otros Cecos'},
    {'key': 'bono_especial', 'screen': BonoEspecialScreen(), 'title': 'Bono Especial'},
    {'key': 'trabajadores', 'screen': TrabajadorScreen(), 'title': 'Trabajadores'},
    {'key': 'contratistas', 'screen': ContratistaScreen(), 'title': 'Contratistas'},
    {'key': 'sueldos_base', 'screen': SueldoBaseScreen(), 'title': 'Sueldos Base'},
    {'key': 'ejemplo_permisos', 'screen': EjemploPermisosScreen(), 'title': 'Ejemplo de Permisos'},
    {'key': 'info', 'screen': const InfoScreen(), 'title': 'Acerca de'},
    {'key': 'cambiar_clave', 'screen': const CambiarClaveScreen(), 'title': 'Cambiar Contraseña'},
  ];

  @override
  void initState() {
    super.initState();
    print('🏗️ [MASTER_LAYOUT] MasterLayout inicializado');
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

  void _navigateToScreen(String screenKey) {
    final index = _screens.indexWhere((screen) => screen['key'] == screenKey);
    if (index != -1) {
      setState(() {
        _currentScreenIndex = index;
      });
    }
  }

  // Método para determinar si se debe ocultar el título
  bool _shouldHideTitle() {
    final currentKey = _screens[_currentScreenIndex]['key'];
    
    // No ocultar el título en ninguna pantalla ya que todas usan MainScaffold
    return false;
  }

  void _refreshCurrentScreen() async {
    // Mostrar un mensaje de confirmación
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 8),
            Text('Actualizando todas las pantallas...'),
          ],
        ),
        duration: Duration(seconds: 2),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
    
    try {
      // Obtener todos los providers
      final tarjaProvider = Provider.of<TarjaProvider>(context, listen: false);
      final colaboradorProvider = Provider.of<ColaboradorProvider>(context, listen: false);
      final vacacionProvider = Provider.of<VacacionProvider>(context, listen: false);
      final licenciaProvider = Provider.of<LicenciaProvider>(context, listen: false);
      final permisoProvider = Provider.of<PermisoProvider>(context, listen: false);
      final horasTrabajadasProvider = Provider.of<HorasTrabajadasProvider>(context, listen: false);
      final horasExtrasProvider = Provider.of<HorasExtrasProvider>(context, listen: false);
      final horasExtrasOtrosCecosProvider = Provider.of<HorasExtrasOtrosCecosProvider>(context, listen: false);
      final bonoEspecialProvider = Provider.of<BonoEspecialProvider>(context, listen: false);
      final trabajadorProvider = Provider.of<TrabajadorProvider>(context, listen: false);
      final contratistaProvider = Provider.of<ContratistaProvider>(context, listen: false);
      final sueldoBaseProvider = Provider.of<SueldoBaseProvider>(context, listen: false);
      
      // Limpiar cache de tarjas primero
      tarjaProvider.limpiarCacheRendimientos();
      
      // Ejecutar todas las cargas en paralelo
      await Future.wait([
        tarjaProvider.cargarTarjas(),
        colaboradorProvider.cargarColaboradores(),
        vacacionProvider.cargarVacaciones(),
        licenciaProvider.cargarLicencias(),
        permisoProvider.cargarPermisos(),
        horasTrabajadasProvider.cargarHorasTrabajadas(),
        horasExtrasProvider.cargarRendimientos(),
        horasExtrasOtrosCecosProvider.cargarHorasExtras(),
        bonoEspecialProvider.cargarBonosEspeciales(),
        trabajadorProvider.cargarTrabajadores(),
        contratistaProvider.cargarContratistas(),
        sueldoBaseProvider.cargarSueldosBase(),
      ]);
      
      // Mostrar mensaje de éxito
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Todas las pantallas actualizadas correctamente'),
              ],
            ),
            duration: Duration(seconds: 2),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      // Mostrar mensaje de error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Error al actualizar: $e'),
              ],
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final sidebarProvider = Provider.of<SidebarProvider>(context);
    
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
                    width: sidebarProvider.isExpanded ? 280 : 70,
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
                              if (sidebarProvider.isExpanded) ...[
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
                              if (sidebarProvider.isExpanded)
                                IconButton(
                                  icon: const Icon(
                                    Icons.chevron_left,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    sidebarProvider.toggleSidebar();
                                    if (sidebarProvider.isExpanded) {
                                      _animationController.forward();
                                    } else {
                                      _animationController.reverse();
                                    }
                                  },
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
                                      onTap: () => _navigateToScreen('home'),
                                      screenKey: 'home',
                                    ),
                                    _buildMenuItem(
                                      icon: Icons.insights,
                                      title: 'Indicadores',
                                      onTap: () => _navigateToScreen('indicadores'),
                                      screenKey: 'indicadores',
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
                                      onTap: () => _navigateToScreen('revision_tarjas'),
                                      permissionId: 2,
                                      screenKey: 'revision_tarjas',
                                    ),
                                    _buildMenuItem(
                                      icon: Icons.fact_check,
                                      title: 'Aprobación de Tarjas',
                                      onTap: () => _navigateToScreen('aprobacion_tarjas'),
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
                                      onTap: () => _navigateToScreen('colaboradores'),
                                      screenKey: 'colaboradores',
                                    ),
                                    _buildMenuItem(
                                      icon: Icons.attach_money,
                                      title: 'Sueldos Base',
                                      onTap: () => _navigateToScreen('sueldos_base'),
                                      screenKey: 'sueldos_base',
                                    ),
                                    _buildMenuItem(
                                      icon: Icons.medical_services,
                                      title: 'Licencias',
                                      onTap: () => _navigateToScreen('licencias'),
                                      screenKey: 'licencias',
                                    ),
                                    _buildMenuItem(
                                      icon: Icons.beach_access,
                                      title: 'Vacaciones',
                                      onTap: () => _navigateToScreen('vacaciones'),
                                      screenKey: 'vacaciones',
                                    ),
                                    _buildMenuItem(
                                      icon: Icons.assignment_turned_in,
                                      title: 'Permisos',
                                      onTap: () => _navigateToScreen('permisos'),
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
                                      onTap: () => _navigateToScreen('horas_trabajadas'),
                                      screenKey: 'horas_trabajadas',
                                    ),
                                    _buildMenuItem(
                                      icon: Icons.add_circle_outline,
                                      title: 'Horas Extras',
                                      onTap: () => _navigateToScreen('horas_extras'),
                                      screenKey: 'horas_extras',
                                    ),
                                    _buildMenuItem(
                                      icon: Icons.more_time,
                                      title: 'Horas Extras Otros Cecos',
                                      onTap: () => _navigateToScreen('horas_extras_otroscecos'),
                                      screenKey: 'horas_extras_otroscecos',
                                    ),
                                    _buildMenuItem(
                                      icon: Icons.card_giftcard,
                                      title: 'Bono Especial',
                                      onTap: () => _navigateToScreen('bono_especial'),
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
                                      onTap: () => _navigateToScreen('trabajadores'),
                                      screenKey: 'trabajadores',
                                    ),
                                    _buildMenuItem(
                                      icon: Icons.groups,
                                      title: 'Contratistas',
                                      onTap: () => _navigateToScreen('contratistas'),
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
                                      onTap: () => _navigateToScreen('ejemplo_permisos'),
                                      screenKey: 'ejemplo_permisos',
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 20),
                                
                                // Opciones del sistema
                                _buildMenuItem(
                                  icon: Icons.info,
                                  title: 'Acerca de',
                                  onTap: () => _navigateToScreen('info'),
                                  iconColor: Colors.blue,
                                  screenKey: 'info',
                                ),
                                _buildMenuItem(
                                  icon: Icons.lock,
                                  title: 'Cambiar Contraseña',
                                  onTap: () => _navigateToScreen('cambiar_clave'),
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
                          onPressed: () {
                            sidebarProvider.toggleSidebar();
                            if (sidebarProvider.isExpanded) {
                              _animationController.forward();
                            } else {
                              _animationController.reverse();
                            }
                          },
                        ),
                        
                        // Título (solo si la pantalla no usa showAppBarElements: false)
                        if (!_shouldHideTitle())
                          const SizedBox(width: 16),
                        if (!_shouldHideTitle())
                          Expanded(
                            child: Text(
                              _screens[_currentScreenIndex]['title'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        
                        // Espacio para centrar elementos
                        const Spacer(),
                        
                        // Elementos centrados: Nombre de Usuario, Selector de Sucursal, Clima
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Nombre de Usuario
                            const UserNameWidget(),
                            const SizedBox(width: 16),
                            
                            // Selector de Sucursal
                            const SucursalSelector(),
                            const SizedBox(width: 16),
                            
                            // Widget de clima
                            WeatherWidget(key: WeatherWidget.globalKey),
                          ],
                        ),
                        
                        // Espacio para centrar elementos
                        const Spacer(),
                        
                        // Botón de actualizar para pantallas específicas
                        if (_screens[_currentScreenIndex]['key'] == 'indicadores' ||
                            _screens[_currentScreenIndex]['key'] == 'horas_trabajadas' ||
                            _screens[_currentScreenIndex]['key'] == 'revision_tarjas' ||
                            _screens[_currentScreenIndex]['key'] == 'aprobacion_tarjas' ||
                            _screens[_currentScreenIndex]['key'] == 'horas_extras' ||
                            _screens[_currentScreenIndex]['key'] == 'horas_extras_otroscecos' ||
                            _screens[_currentScreenIndex]['key'] == 'colaboradores' ||
                            _screens[_currentScreenIndex]['key'] == 'licencias' ||
                            _screens[_currentScreenIndex]['key'] == 'vacaciones' ||
                            _screens[_currentScreenIndex]['key'] == 'permisos' ||
                            _screens[_currentScreenIndex]['key'] == 'bono_especial' ||
                            _screens[_currentScreenIndex]['key'] == 'trabajadores' ||
                            _screens[_currentScreenIndex]['key'] == 'contratistas' ||
                            _screens[_currentScreenIndex]['key'] == 'sueldos_base')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Tooltip(
                              message: 'Actualizar todas las pantallas',
                              child: IconButton(
                                icon: const Icon(Icons.refresh, color: Colors.white),
                                onPressed: () {
                                  _refreshCurrentScreen();
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 24,
                                  minHeight: 24,
                                ),
                              ),
                            ),
                          ),
                        
                        // Espaciado consistente antes de las acciones del usuario
                        const SizedBox(width: 16),
                        
                        // Acciones del usuario (derecha)
                        const UserInfo(),
                        
                      ],
                    ),
                  ),
                   
                  // Contenido del body usando IndexedStack para mantener el estado
                  Expanded(
                    child: IndexedStack(
                      index: _currentScreenIndex,
                      children: _screens.map((screen) => screen['screen'] as Widget).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(String title, List<Widget> children) {
    final sidebarProvider = Provider.of<SidebarProvider>(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sidebarProvider.isExpanded) ...[
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
    final sidebarProvider = Provider.of<SidebarProvider>(context);
    
    // Verificar permisos si se especifica
    if (permissionId != null) {
      final permisosProvider = Provider.of<PermisosProvider>(context, listen: false);
      if (!permisosProvider.tienePermisoPorId(permissionId)) {
        return const SizedBox.shrink();
      }
    }

    // Determinar si este elemento está activo
    final isActive = _screens[_currentScreenIndex]['key'] == screenKey;

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
                    horizontal: sidebarProvider.isExpanded ? 16 : 8,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        color: isActive ? Colors.yellow : (iconColor ?? Colors.white),
                        size: 24,
                      ),
                      if (sidebarProvider.isExpanded) ...[
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

// Widget para el contenido de la pantalla de inicio
class _HomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bienvenido a LH Gestión Tarjas',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Selecciona una opción del menú lateral para comenzar.',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
