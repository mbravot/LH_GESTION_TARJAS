import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/permisos_provider.dart';
import '../widgets/permiso_widget.dart';
import '../widgets/main_scaffold.dart';
import '../theme/app_theme.dart';

class EjemploPermisosScreen extends StatelessWidget {
  const EjemploPermisosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Ejemplo de Permisos',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ejemplo 1: Verificar permiso por ID
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Permiso por ID (ID: 2)',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    PermisoWidget(
                      idPermiso: 2,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Tienes permiso para ver esta sección'),
                          ],
                        ),
                      ),
                      fallback: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.cancel, color: Colors.red),
                            SizedBox(width: 8),
                            Text('No tienes permiso para ver esta sección'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Ejemplo 2: Verificar múltiples permisos (al menos uno)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Múltiples Permisos (al menos uno)',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    MultiPermisoWidget(
                      idsPermisos: [1, 2, 3],
                      requiereTodos: false,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Tienes al menos uno de los permisos requeridos'),
                          ],
                        ),
                      ),
                      fallback: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('No tienes ninguno de los permisos requeridos'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Ejemplo 3: Verificar múltiples permisos (todos)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Múltiples Permisos (todos)',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    MultiPermisoWidget(
                      idsPermisos: [1, 2],
                      requiereTodos: true,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.purple),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.purple),
                            SizedBox(width: 8),
                            Text('Tienes todos los permisos requeridos'),
                          ],
                        ),
                      ),
                      fallback: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.cancel, color: Colors.red),
                            SizedBox(width: 8),
                            Text('No tienes todos los permisos requeridos'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Ejemplo 4: Verificar permiso por nombre (async)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Permiso por Nombre (Async)',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    PermisoWidgetAsync(
                      nombrePermiso: 'revisador',
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.teal),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.teal),
                            SizedBox(width: 8),
                            Text('Tienes el permiso "revisador"'),
                          ],
                        ),
                      ),
                      fallback: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.cancel, color: Colors.grey),
                            SizedBox(width: 8),
                            Text('No tienes el permiso "revisador"'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Ejemplo 5: Información de permisos del usuario
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información de Permisos',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Consumer<PermisosProvider>(
                      builder: (context, permisosProvider, child) {
                        if (permisosProvider.isLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        if (permisosProvider.error != null) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red),
                            ),
                            child: Text('Error: ${permisosProvider.error}'),
                          );
                        }
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total de permisos: ${permisosProvider.permisos.length}'),
                            const SizedBox(height: 8),
                            ...permisosProvider.permisos.map((permiso) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.security,
                                    color: AppTheme.primaryColor,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text('ID: ${permiso['id']} - ${permiso['nombre']}'),
                                ],
                              ),
                            )),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 