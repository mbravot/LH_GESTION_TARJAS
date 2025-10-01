import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'src/providers/auth_provider.dart';
import 'src/providers/theme_provider.dart';
import 'src/providers/tarja_provider.dart';
import 'src/providers/permisos_provider.dart';
import 'src/providers/permiso_provider.dart';
import 'src/providers/trabajador_provider.dart';
import 'src/providers/colaborador_provider.dart';
import 'src/providers/vacacion_provider.dart';
import 'src/providers/licencia_provider.dart';
import 'src/providers/horas_trabajadas_provider.dart';
import 'src/providers/horas_extras_provider.dart';
import 'src/providers/horas_extras_otroscecos_provider.dart';
import 'src/providers/bono_especial_provider.dart';
import 'src/providers/contratista_provider.dart';
import 'src/providers/sueldo_base_provider.dart';
import 'src/providers/notification_provider.dart';
import 'src/providers/sidebar_provider.dart';
import 'src/screens/splash_screen.dart';
import 'src/theme/app_theme.dart';
import 'src/widgets/session_handler_wrapper.dart';
import 'src/widgets/global_notification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TarjaProvider()),
        ChangeNotifierProvider(create: (_) => PermisosProvider()),
        ChangeNotifierProvider(create: (_) => PermisoProvider()),
        ChangeNotifierProvider(create: (_) => TrabajadorProvider()),
        ChangeNotifierProvider(create: (_) => ColaboradorProvider.instance),
        ChangeNotifierProvider(create: (_) => VacacionProvider()),
        ChangeNotifierProvider(create: (_) => LicenciaProvider()),
        ChangeNotifierProvider(create: (_) => HorasTrabajadasProvider()),
        ChangeNotifierProvider(create: (_) => HorasExtrasProvider()),
        ChangeNotifierProvider(create: (_) => HorasExtrasOtrosCecosProvider()),
        ChangeNotifierProvider(create: (_) => BonoEspecialProvider()),
        ChangeNotifierProvider(create: (_) => ContratistaProvider()),
        ChangeNotifierProvider(create: (_) => SueldoBaseProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => SidebarProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'LH Gestión Tarjas',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const GlobalNotification(
            child: SessionHandlerWrapper(
              child: SplashScreen(),
            ),
          ),
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('es', 'ES'),
            Locale('en', 'US'),
          ],
          locale: const Locale('es', 'ES'),
        );
      },
    );
  }
} 