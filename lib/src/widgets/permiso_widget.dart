import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/permisos_provider.dart';

class PermisoWidget extends StatelessWidget {
  final int idPermiso;
  final Widget child;
  final Widget? fallback;
  final bool mostrarFallback;

  const PermisoWidget({
    Key? key,
    required this.idPermiso,
    required this.child,
    this.fallback,
    this.mostrarFallback = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PermisosProvider>(
      builder: (context, permisosProvider, _) {
        // Si está cargando, mostrar un indicador de carga
        if (permisosProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final tienePermiso = permisosProvider.tienePermisoPorId(idPermiso);
    
        
        if (tienePermiso) {
          return child;
        } else if (mostrarFallback && fallback != null) {
          return fallback!;
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}

class PermisoWidgetAsync extends StatelessWidget {
  final String nombrePermiso;
  final Widget child;
  final Widget? fallback;
  final bool mostrarFallback;

  const PermisoWidgetAsync({
    Key? key,
    required this.nombrePermiso,
    required this.child,
    this.fallback,
    this.mostrarFallback = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PermisosProvider>(
      builder: (context, permisosProvider, _) {
        return FutureBuilder<bool>(
          future: permisosProvider.tienePermiso(nombrePermiso),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final tienePermiso = snapshot.data ?? false;
            
            if (tienePermiso) {
              return child;
            } else if (mostrarFallback && fallback != null) {
              return fallback!;
            } else {
              return const SizedBox.shrink();
            }
          },
        );
      },
    );
  }
}

class MultiPermisoWidget extends StatelessWidget {
  final List<int> idsPermisos;
  final Widget child;
  final Widget? fallback;
  final bool mostrarFallback;
  final bool requiereTodos; // true = todos los permisos, false = al menos uno

  const MultiPermisoWidget({
    Key? key,
    required this.idsPermisos,
    required this.child,
    this.fallback,
    this.mostrarFallback = true,
    this.requiereTodos = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PermisosProvider>(
      builder: (context, permisosProvider, _) {
        final tienePermiso = requiereTodos 
            ? permisosProvider.tieneTodosLosPermisos(idsPermisos)
            : permisosProvider.tieneAlgunoDeLosPermisos(idsPermisos);
        
        if (tienePermiso) {
          return child;
        } else if (mostrarFallback && fallback != null) {
          return fallback!;
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
} 