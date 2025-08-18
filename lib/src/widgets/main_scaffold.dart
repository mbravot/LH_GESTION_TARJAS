import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/tarja_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/permisos_provider.dart';
import '../providers/permiso_provider.dart';
import '../providers/trabajador_provider.dart';
import '../providers/colaborador_provider.dart';
import '../providers/vacacion_provider.dart';
import '../providers/licencia_provider.dart';
import '../theme/app_theme.dart';
import 'sucursal_selector.dart';
import 'user_info.dart';

class MainScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final PreferredSizeWidget? bottom;
  final List<Widget>? actions;
  final Widget? drawer;
  final VoidCallback? onRefresh;

  const MainScaffold({
    Key? key,
    required this.body,
    this.title,
    this.bottom,
    this.actions,
    this.drawer,
    this.onRefresh,
  }) : super(key: key);

  void _handleRefresh(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final tarjaProvider = Provider.of<TarjaProvider>(context, listen: false);
    final permisosProvider = Provider.of<PermisosProvider>(context, listen: false);
    final permisoProvider = Provider.of<PermisoProvider>(context, listen: false);
    final trabajadorProvider = Provider.of<TrabajadorProvider>(context, listen: false);
    final colaboradorProvider = Provider.of<ColaboradorProvider>(context, listen: false);
    final vacacionProvider = Provider.of<VacacionProvider>(context, listen: false);
    final licenciaProvider = Provider.of<LicenciaProvider>(context, listen: false);
    
    // Mostrar indicador de carga
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
            Text('Actualizando...'),
          ],
        ),
        duration: Duration(seconds: 1),
        backgroundColor: AppTheme.primaryColor,
      ),
    );

    try {
      // Ejecutar callback personalizado si existe
      if (onRefresh != null) {
        await Future.delayed(const Duration(milliseconds: 500));
        onRefresh!();
      } else {
        // Actualización por defecto
        await authProvider.checkAuthStatus();
        
        // Recargar permisos si no están cargados
        if (!permisosProvider.permisosCargados) {
          await permisosProvider.recargarPermisos();
        }
        
        // Si hay TarjaProvider disponible, recargar tarjas
        if (tarjaProvider != null) {
          await tarjaProvider.cargarTarjas();
        }
        
        // Si hay TrabajadorProvider disponible, recargar trabajadores
        if (trabajadorProvider != null) {
          await trabajadorProvider.cargarTrabajadores();
        }
        
        // Si hay ColaboradorProvider disponible, recargar colaboradores
        if (colaboradorProvider != null) {
          await colaboradorProvider.cargarColaboradores();
        }
        if (vacacionProvider != null) {
          await vacacionProvider.cargarVacaciones();
        }
        if (licenciaProvider != null) {
          await licenciaProvider.cargarLicencias();
        }
        if (permisoProvider != null) {
          await permisoProvider.cargarPermisos();
        }
      }

      // Mostrar mensaje de éxito
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Página actualizada'),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? 'LH Gestión Tarjas'),
        bottom: bottom,
        actions: [
          const UserInfo(),
          const SucursalSelector(),
          if (actions != null) ...actions!,
          // Botón de actualizar
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _handleRefresh(context),
          ),
          IconButton(
            icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              // Aquí puedes poner tu lógica de logout global
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
        ],
      ),
      drawer: drawer,
      body: body,
    );
  }
} 