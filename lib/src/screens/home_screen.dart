import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/permisos_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/master_layout.dart';
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
    // print('🏠 [HOME_SCREEN] HomeScreen inicializado');
    // No cargar permisos automáticamente ya que se cargan en LoginScreen
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   // print('🏠 [HOME_SCREEN] Cargando permisos automáticamente...');
    //   final permisosProvider = context.read<PermisosProvider>();
    //   permisosProvider.cargarPermisos();
    // });
  }

  @override
  Widget build(BuildContext context) {
    return const MasterLayout();
  }
} 