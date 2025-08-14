class Colaborador {
  final String id;
  final String? rut;
  final String? codigoVerificador;
  final String nombre;
  final String apellidoPaterno;
  final String? apellidoMaterno;
  final String idSucursal;
  final String? idSucursalContrato;
  final String? idCargo;
  final String? fechaNacimiento;
  final String? fechaIncorporacion;
  final String? idPrevision;
  final String? idAfp;
  final String idEstado;
  
  // Nuevos campos con nombres descriptivos
  final String? nombreCargo;
  final String? nombreAfp;
  final String? nombrePrevision;
  final String? nombreSucursal;
  final String? nombreSucursalContrato;
  final String? nombreEstado;

  Colaborador({
    required this.id,
    this.rut,
    this.codigoVerificador,
    required this.nombre,
    required this.apellidoPaterno,
    this.apellidoMaterno,
    required this.idSucursal,
    this.idSucursalContrato,
    this.idCargo,
    this.fechaNacimiento,
    this.fechaIncorporacion,
    this.idPrevision,
    this.idAfp,
    required this.idEstado,
    this.nombreCargo,
    this.nombreAfp,
    this.nombrePrevision,
    this.nombreSucursal,
    this.nombreSucursalContrato,
    this.nombreEstado,
  });

  factory Colaborador.fromJson(Map<String, dynamic> json) {
    return Colaborador(
      id: json['id']?.toString() ?? '',
      rut: json['rut']?.toString(),
      codigoVerificador: json['codigo_verificador']?.toString(),
      nombre: json['nombre']?.toString() ?? '',
      apellidoPaterno: json['apellido_paterno']?.toString() ?? '',
      apellidoMaterno: json['apellido_materno']?.toString(),
      idSucursal: json['id_sucursal']?.toString() ?? '',
      idSucursalContrato: json['id_sucursalcontrato']?.toString(),
      idCargo: json['id_cargo']?.toString(),
      fechaNacimiento: json['fecha_nacimiento']?.toString(),
      fechaIncorporacion: json['fecha_incorporacion']?.toString(),
      idPrevision: json['id_prevision']?.toString(),
      idAfp: json['id_afp']?.toString(),
      idEstado: json['id_estado']?.toString() ?? '1',
      nombreCargo: json['nombre_cargo']?.toString(),
      nombreAfp: json['nombre_afp']?.toString(),
      nombrePrevision: json['nombre_prevision']?.toString(),
      nombreSucursal: json['nombre_sucursal']?.toString(),
      nombreSucursalContrato: json['nombre_sucursal_contrato']?.toString(),
      nombreEstado: json['nombre_estado']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rut': rut,
      'codigo_verificador': codigoVerificador,
      'nombre': nombre,
      'apellido_paterno': apellidoPaterno,
      'apellido_materno': apellidoMaterno,
      'id_sucursal': idSucursal,
      'id_sucursalcontrato': idSucursalContrato,
      'id_cargo': idCargo,
      'fecha_nacimiento': fechaNacimiento,
      'fecha_incorporacion': fechaIncorporacion,
      'id_prevision': idPrevision,
      'id_afp': idAfp,
      'id_estado': idEstado,
      'nombre_cargo': nombreCargo,
      'nombre_afp': nombreAfp,
      'nombre_prevision': nombrePrevision,
      'nombre_sucursal': nombreSucursal,
      'nombre_sucursal_contrato': nombreSucursalContrato,
      'nombre_estado': nombreEstado,
    };
  }

  // Método para obtener el nombre completo
  String get nombreCompleto {
    final apellidoMaternoStr = apellidoMaterno?.isNotEmpty == true ? ' $apellidoMaterno' : '';
    return '$nombre $apellidoPaterno$apellidoMaternoStr';
  }

  // Método para obtener el RUT completo
  String get rutCompleto {
    if (rut != null && codigoVerificador != null) {
      return '$rut-$codigoVerificador';
    }
    return 'Sin RUT';
  }

  // Método para obtener el estado como texto (usar nombre descriptivo si está disponible)
  String get estadoText {
    if (nombreEstado != null && nombreEstado!.isNotEmpty) {
      return nombreEstado!;
    }
    switch (idEstado) {
      case '1':
        return 'Activo';
      case '2':
        return 'Inactivo';
      default:
        return 'Desconocido';
    }
  }

  // Método para obtener el color del estado
  String get estadoColor {
    final estado = estadoText.toLowerCase();
    if (estado.contains('activo')) {
      return 'green';
    } else if (estado.contains('inactivo')) {
      return 'red';
    }
    return 'grey';
  }

  // Método para obtener el cargo (usar nombre descriptivo si está disponible)
  String get cargoText {
    if (nombreCargo != null && nombreCargo!.isNotEmpty) {
      return nombreCargo!;
    }
    return idCargo ?? 'Sin cargo';
  }

  // Método para obtener la AFP (usar nombre descriptivo si está disponible)
  String get afpText {
    if (nombreAfp != null && nombreAfp!.isNotEmpty) {
      return nombreAfp!;
    }
    return idAfp ?? 'Sin AFP';
  }

  // Método para obtener la previsión (usar nombre descriptivo si está disponible)
  String get previsionText {
    if (nombrePrevision != null && nombrePrevision!.isNotEmpty) {
      return nombrePrevision!;
    }
    return idPrevision ?? 'Sin previsión';
  }

  // Método para obtener la sucursal (usar nombre descriptivo si está disponible)
  String get sucursalText {
    if (nombreSucursal != null && nombreSucursal!.isNotEmpty) {
      return nombreSucursal!;
    }
    return 'Sucursal $idSucursal';
  }

  // Método para obtener la sucursal del contrato (usar nombre descriptivo si está disponible)
  String get sucursalContratoText {
    if (nombreSucursalContrato != null && nombreSucursalContrato!.isNotEmpty) {
      return nombreSucursalContrato!;
    }
    return idSucursalContrato ?? 'Sin sucursal de contrato';
  }

  // Método para clonar el colaborador con cambios
  Colaborador copyWith({
    String? id,
    String? rut,
    String? codigoVerificador,
    String? nombre,
    String? apellidoPaterno,
    String? apellidoMaterno,
    String? idSucursal,
    String? idSucursalContrato,
    String? idCargo,
    String? fechaNacimiento,
    String? fechaIncorporacion,
    String? idPrevision,
    String? idAfp,
    String? idEstado,
    String? nombreCargo,
    String? nombreAfp,
    String? nombrePrevision,
    String? nombreSucursal,
    String? nombreSucursalContrato,
    String? nombreEstado,
  }) {
    return Colaborador(
      id: id ?? this.id,
      rut: rut ?? this.rut,
      codigoVerificador: codigoVerificador ?? this.codigoVerificador,
      nombre: nombre ?? this.nombre,
      apellidoPaterno: apellidoPaterno ?? this.apellidoPaterno,
      apellidoMaterno: apellidoMaterno ?? this.apellidoMaterno,
      idSucursal: idSucursal ?? this.idSucursal,
      idSucursalContrato: idSucursalContrato ?? this.idSucursalContrato,
      idCargo: idCargo ?? this.idCargo,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      fechaIncorporacion: fechaIncorporacion ?? this.fechaIncorporacion,
      idPrevision: idPrevision ?? this.idPrevision,
      idAfp: idAfp ?? this.idAfp,
      idEstado: idEstado ?? this.idEstado,
      nombreCargo: nombreCargo ?? this.nombreCargo,
      nombreAfp: nombreAfp ?? this.nombreAfp,
      nombrePrevision: nombrePrevision ?? this.nombrePrevision,
      nombreSucursal: nombreSucursal ?? this.nombreSucursal,
      nombreSucursalContrato: nombreSucursalContrato ?? this.nombreSucursalContrato,
      nombreEstado: nombreEstado ?? this.nombreEstado,
    );
  }
}
