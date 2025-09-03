import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/permisos_provider.dart';
import '../theme/app_theme.dart';

class EjemploPermisosScreen extends StatelessWidget {
  const EjemploPermisosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PermisosProvider>(
      builder: (context, permisosProvider, child) {
        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ejemplo de Permisos',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Esta es una pantalla de ejemplo para mostrar permisos.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: permisosProvider.permisos.isEmpty
                      ? const Center(
                          child: Text('No hay permisos disponibles'),
                        )
                      : ListView.builder(
                          itemCount: permisosProvider.permisos.length,
                          itemBuilder: (context, index) {
                            final permiso = permisosProvider.permisos[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(permiso['nombre'] ?? 'Sin nombre'),
                                subtitle: Text(permiso['descripcion'] ?? 'Sin descripción'),
                                leading: Icon(
                                  Icons.security,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 