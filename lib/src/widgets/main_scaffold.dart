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
import '../providers/horas_trabajadas_provider.dart';
import '../providers/horas_extras_provider.dart';
import '../providers/horas_extras_otroscecos_provider.dart';
import '../providers/bono_especial_provider.dart';
import '../providers/contratista_provider.dart';
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
        try {
          await tarjaProvider.cargarTarjas();
        } catch (e) {
          // Ignorar si el provider no está disponible
        }
        
        // Si hay TrabajadorProvider disponible, recargar trabajadores
        try {
          await trabajadorProvider.cargarTrabajadores();
        } catch (e) {
          // Ignorar si el provider no está disponible
        }
        
        // Si hay ColaboradorProvider disponible, recargar colaboradores
        try {
          await colaboradorProvider.cargarColaboradores();
        } catch (e) {
          // Ignorar si el provider no está disponible
        }
        try {
          await vacacionProvider.cargarVacaciones();
        } catch (e) {
          // Ignorar si el provider no está disponible
        }
        try {
          await licenciaProvider.cargarLicencias();
        } catch (e) {
          // Ignorar si el provider no está disponible
        }
        try {
          await permisoProvider.cargarPermisos();
        } catch (e) {
          // Ignorar si el provider no está disponible
        }
        
        // Si hay HorasTrabajadasProvider disponible, recargar horas trabajadas
        try {
          final horasTrabajadasProvider = context.read<HorasTrabajadasProvider>();
          await horasTrabajadasProvider.cargarHorasTrabajadas();
        } catch (e) {
          // Ignorar si el provider no está disponible
        }
        
        // Si hay HorasExtrasProvider disponible, recargar horas extras
        try {
          final horasExtrasProvider = context.read<HorasExtrasProvider>();
          await horasExtrasProvider.cargarRendimientos();
        } catch (e) {
          // Ignorar si el provider no está disponible
        }
        
        // Si hay HorasExtrasOtrosCecosProvider disponible, recargar horas extras otros CECOs
        try {
          final horasExtrasOtrosCecosProvider = context.read<HorasExtrasOtrosCecosProvider>();
          await horasExtrasOtrosCecosProvider.cargarHorasExtras();
        } catch (e) {
          // Ignorar si el provider no está disponible
        }
        
        // Si hay BonoEspecialProvider disponible, recargar bonos especiales
        try {
          final bonoEspecialProvider = context.read<BonoEspecialProvider>();
          await bonoEspecialProvider.cargarBonosEspeciales();
          await bonoEspecialProvider.cargarResumenes();
        } catch (e) {
          // Ignorar si el provider no está disponible
        }
        
        // Si hay ContratistaProvider disponible, recargar contratistas
        try {
          final contratistaProvider = context.read<ContratistaProvider>();
          await contratistaProvider.cargarContratistas();
          await contratistaProvider.cargarOpciones();
        } catch (e) {
          // Ignorar si el provider no está disponible
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