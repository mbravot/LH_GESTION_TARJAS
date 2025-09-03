import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/permisos_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_layout.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar permisos automáticamente si no están cargados
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final permisosProvider = context.read<PermisosProvider>();
      if (!permisosProvider.permisosCargados) {
        permisosProvider.cargarPermisos();
      }
    });
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

  Widget _buildDashboardPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dashboard,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Dashboard Administrativas',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'En desarrollo',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dashboard Administrativas - En desarrollo'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            icon: const Icon(Icons.info_outline),
            label: const Text('Más información'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return AppLayout(
      title: 'LH Gestión Tarjas',
      onRefresh: () async {
        await authProvider.checkAuthStatus();
      },
      currentScreen: 'home',
      child: _buildDashboardPlaceholder(),
    );
  }
} 