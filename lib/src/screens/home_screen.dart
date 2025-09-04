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
    // Cargar permisos automáticamente si no están cargados
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final permisosProvider = context.read<PermisosProvider>();
      // Siempre intentar cargar permisos para asegurar que estén disponibles
      // especialmente después de un hot reload
      permisosProvider.cargarPermisos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const MasterLayout();
  }
} 