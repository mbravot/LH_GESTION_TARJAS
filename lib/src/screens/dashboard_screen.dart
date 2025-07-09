import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/main_scaffold.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Map<String, dynamic>> _sucursales = [];
  bool _isLoadingSucursales = false;

  @override
  void initState() {
    super.initState();
    _cargarSucursales();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarSucursales() async {
    setState(() => _isLoadingSucursales = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final sucursales = await authProvider.getSucursalesDisponibles();
      setState(() {
        _sucursales = sucursales;
        _isLoadingSucursales = false;
      });
    } catch (e) {
      setState(() => _isLoadingSucursales = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar sucursales: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cambiarSucursal(String idSucursal) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.cambiarSucursal(idSucursal);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Sucursal actualizada'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar sucursal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: const InputDecoration(
        hintText: 'Buscar en dashboard...',
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
              backgroundColor: Colors.green,
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
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: () => setState(() => _isSearching = true),
      ),
      FutureBuilder<Map<String, dynamic>?> (
        future: authProvider.getCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            final idSucursalActual = snapshot.data!['id_sucursal']?.toString();
            // Intentar obtener el nombre de la sucursal actual
            String? nombreSucursalActual;
            if (_sucursales.isNotEmpty && idSucursalActual != null) {
              final sucursalActual = _sucursales.firstWhere(
                (s) => s['id'].toString() == idSucursalActual,
                orElse: () => {},
              );
              nombreSucursalActual = sucursalActual['nombre'] ?? sucursalActual['nombre_sucursal'] ?? 'Sin nombre';
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 16),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: _isLoadingSucursales
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                              ),
                            )
                          : (_sucursales.isEmpty || idSucursalActual == null)
                              ? const Text('Sin sucursales')
                              : DropdownButton<String>(
                                  value: idSucursalActual,
                                  underline: const SizedBox.shrink(),
                                  icon: Icon(
                                    Icons.arrow_drop_down,
                                    size: 16,
                                    color: AppTheme.primaryColor,
                                  ),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  items: _sucursales.map((sucursal) {
                                    final nombre = sucursal['nombre'] ?? sucursal['nombre_sucursal'] ?? 'Sin nombre';
                                    return DropdownMenuItem<String>(
                                      value: sucursal['id'].toString(),
                                      child: Text(
                                        nombre,
                      style: const TextStyle(fontSize: 14),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null && newValue != idSucursalActual) {
                                      _cambiarSucursal(newValue);
                                    }
                                  },
                                ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.person, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      snapshot.data!['nombre'] ?? 'Usuario',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Dashboard Administrativas',
      onRefresh: () async {
        await _cargarSucursales();
      },
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(title: 'Gestión de Tarjas'),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _DashboardCard(
                    icon: Icons.factory,
                    title: 'Avance por Plantas',
                    subtitle: 'Ver progreso por planta',
                    onTap: () {
                      // TODO: Implementar navegación
                    },
                  ),
                  _DashboardCard(
                    icon: Icons.fact_check,
                    title: 'Revisión Tarjas',
                    subtitle: 'Revisar tarjas pendientes',
                    onTap: () {
                      // TODO: Implementar navegación
                    },
                  ),
                ],
              ),
              const _SectionTitle(title: 'Control de Personal'),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _DashboardCard(
                    icon: Icons.person_outline,
                    title: 'Ficha Personal',
                    subtitle: 'Gestión de personal',
                    onTap: () {
                      // TODO: Implementar navegación
                    },
                  ),
                  _DashboardCard(
                    icon: Icons.medical_services,
                    title: 'Licencias',
                    subtitle: 'Control de licencias',
                    onTap: () {
                      // TODO: Implementar navegación
                    },
                  ),
                ],
              ),
              const _SectionTitle(title: 'Control de Horas'),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _DashboardCard(
                    icon: Icons.access_time,
                    title: 'Horas Trabajadas',
                    subtitle: 'Registro de horas',
                    onTap: () {
                      // TODO: Implementar navegación
                    },
                  ),
                  _DashboardCard(
                    icon: Icons.more_time,
                    title: 'Horas Extras',
                    subtitle: 'Control de horas extras',
                    onTap: () {
                      // TODO: Implementar navegación
                    },
                  ),
                ],
              ),
              const _SectionTitle(title: 'Reportes'),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _DashboardCard(
                    icon: Icons.analytics,
                    title: 'Mano de Obra',
                    subtitle: 'Detalle de mano de obra',
                    onTap: () {
                      // TODO: Implementar navegación
                    },
                  ),
                  _DashboardCard(
                    icon: Icons.upload_file,
                    title: 'Carga Agriprime',
                    subtitle: 'Gestión de datos',
                    onTap: () {
                      // TODO: Implementar navegación
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 