class Usuario {
  final String id;
  final String usuario;
  final String correo;
  final int idSucursalActiva;
  final String nombre;
  final String apellidoPaterno;
  final String apellidoMaterno;
  final int? idEstado;
  final int? idRol;
  final int? idPerfil;
  final String? fechaCreacion;
  final String? nombreSucursal;
  final String? nombreCompleto;
  final List<String>? permisos;
  final List<int>? sucursalesAdicionales;

  Usuario({
    required this.id,
    required this.usuario,
    required this.correo,
    required this.idSucursalActiva,
    required this.nombre,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    this.idEstado,
    this.idRol,
    this.idPerfil,
    this.fechaCreacion,
    this.nombreSucursal,
    this.nombreCompleto,
    this.permisos,
    this.sucursalesAdicionales,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    // Extraer campos individuales del nombre_completo si no existen
    String nombre = json['nombre']?.toString() ?? '';
    String apellidoPaterno = json['apellido_paterno']?.toString() ?? '';
    String apellidoMaterno = json['apellido_materno']?.toString() ?? '';
    
    // Si los campos individuales no existen, intentar extraer del nombre_completo
    if (nombre.isEmpty && apellidoPaterno.isEmpty && apellidoMaterno.isEmpty) {
      final nombreCompleto = json['nombre_completo']?.toString() ?? '';
      if (nombreCompleto.isNotEmpty) {
        final partes = nombreCompleto.split(' ');
        if (partes.isNotEmpty) {
          nombre = partes[0];
          if (partes.length > 1) {
            apellidoPaterno = partes[1];
            if (partes.length > 2) {
              apellidoMaterno = partes.sublist(2).join(' ');
            }
          }
        }
      }
    }
    
    return Usuario(
      id: json['id']?.toString() ?? '',
      usuario: json['usuario']?.toString() ?? '',
      correo: json['correo']?.toString() ?? '',
      idSucursalActiva: _parseInt(json['id_sucursalactiva']),
      nombre: nombre,
      apellidoPaterno: apellidoPaterno,
      apellidoMaterno: apellidoMaterno,
      idEstado: _parseInt(json['id_estado']),
      idRol: _parseInt(json['id_rol']),
      idPerfil: _parseInt(json['id_perfil']),
      fechaCreacion: json['fecha_creacion']?.toString(),
      nombreSucursal: json['nombre_sucursal']?.toString(),
      nombreCompleto: json['nombre_completo']?.toString(),
      permisos: json['permisos'] != null 
          ? List<String>.from(json['permisos'].map((p) => p.toString()))
          : null,
      sucursalesAdicionales: json['sucursales_adicionales'] != null
          ? List<int>.from(json['sucursales_adicionales'].map((s) => s is int ? s : int.tryParse(s.toString()) ?? 0))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario': usuario,
      'correo': correo,
      'id_sucursalactiva': idSucursalActiva,
      'nombre': nombre,
      'apellido_paterno': apellidoPaterno,
      'apellido_materno': apellidoMaterno,
      'id_estado': idEstado,
      'permisos': permisos,
    };
  }

  Map<String, dynamic> toCreateJson({String? clave}) {
    final Map<String, dynamic> data = {
      'usuario': usuario,
      'correo': correo,
      'nombre': nombre,
      'apellido_paterno': apellidoPaterno,
      'id_estado': idEstado ?? 1, // Valor por defecto si es null
      'id_rol': idRol ?? 3, // Valor por defecto si es null
      'id_perfil': idPerfil ?? 1, // Valor por defecto si es null
    };
    
    // Solo incluir id_sucursalactiva si tiene un valor válido
    if (idSucursalActiva != null && idSucursalActiva! > 0) {
      data['id_sucursalactiva'] = idSucursalActiva;
    }
    
    // Solo incluir clave si se proporciona
    if (clave != null && clave.isNotEmpty) {
      data['clave'] = clave;
    }
    
    // Solo incluir apellido_materno si no está vacío
    if (apellidoMaterno.isNotEmpty) {
      data['apellido_materno'] = apellidoMaterno;
    }
    
    // Solo incluir permisos si no es null
    if (permisos != null) {
      data['permisos'] = permisos;
    }
    
    // Solo incluir sucursales_adicionales si no es null
    if (sucursalesAdicionales != null) {
      data['sucursales_adicionales'] = sucursalesAdicionales;
    }
    
    return data;
  }

  Map<String, dynamic> toUpdateJson() {
    print('Usuario.toUpdateJson: idSucursalActiva = $idSucursalActiva');
    
    final Map<String, dynamic> data = {
      'usuario': usuario,
      'correo': correo,
      'nombre': nombre,
      'apellido_paterno': apellidoPaterno,
      'id_estado': idEstado ?? 1, // Valor por defecto si es null
      'id_rol': idRol ?? 3, // Valor por defecto si es null
      'id_perfil': idPerfil ?? 1, // Valor por defecto si es null
    };
    
    // Solo incluir id_sucursalactiva si tiene un valor válido
    if (idSucursalActiva != null && idSucursalActiva! > 0) {
      data['id_sucursalactiva'] = idSucursalActiva;
      print('Usuario.toUpdateJson: Incluyendo id_sucursalactiva = ${idSucursalActiva}');
    } else {
      print('Usuario.toUpdateJson: NO incluyendo id_sucursalactiva (valor: $idSucursalActiva)');
    }
    
    // Solo incluir apellido_materno si no está vacío
    if (apellidoMaterno.isNotEmpty) {
      data['apellido_materno'] = apellidoMaterno;
    }
    
    // Solo incluir permisos si no es null
    if (permisos != null) {
      data['permisos'] = permisos;
    }
    
    // Solo incluir sucursales_adicionales si no es null
    if (sucursalesAdicionales != null) {
      data['sucursales_adicionales'] = sucursalesAdicionales;
    }
    
    return data;
  }

  String get nombreCompletoDisplay => nombreCompleto ?? '$nombre $apellidoPaterno $apellidoMaterno'.trim();
  
  String get estadoText => idEstado == 1 ? 'Activo' : 'Inactivo';

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class Permiso {
  final String id;
  final String nombre;
  final int idApp;
  final int idEstado;

  Permiso({
    required this.id,
    required this.nombre,
    required this.idApp,
    required this.idEstado,
  });

  factory Permiso.fromJson(Map<String, dynamic> json) {
    return Permiso(
      id: (json['id'] ?? json['id_permiso'])?.toString() ?? '',
      nombre: (json['nombre'] ?? json['nombre_permiso'])?.toString() ?? '',
      idApp: _parseInt(json['id_app']),
      idEstado: _parseInt(json['id_estado']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'id_app': idApp,
      'id_estado': idEstado,
    };
  }

  bool get isActivo => idEstado == 1;

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class UsuarioPermisos {
  final String usuarioId;
  final List<Permiso> permisos;
  final int total;

  UsuarioPermisos({
    required this.usuarioId,
    required this.permisos,
    required this.total,
  });

  factory UsuarioPermisos.fromJson(Map<String, dynamic> json) {
    return UsuarioPermisos(
      usuarioId: json['usuario_id']?.toString() ?? '',
      permisos: json['permisos'] != null
          ? (json['permisos'] as List).map((p) => Permiso.fromJson(p)).toList()
          : [],
      total: _parseInt(json['total']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
