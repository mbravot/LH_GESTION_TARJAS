class Trabajador {
  final String id;
  final String? rut;
  final String? codigoVerificador;
  final String nombre;
  final String apellidoPaterno;
  final String? apellidoMaterno;
  final String idContratista;
  final String idPorcentaje;
  final String idEstado;
  final String idSucursalActiva;
  final String? nombreContratista;
  final double? porcentaje;

  Trabajador({
    required this.id,
    this.rut,
    this.codigoVerificador,
    required this.nombre,
    required this.apellidoPaterno,
    this.apellidoMaterno,
    required this.idContratista,
    required this.idPorcentaje,
    required this.idEstado,
    required this.idSucursalActiva,
    this.nombreContratista,
    this.porcentaje,
  });

  factory Trabajador.fromJson(Map<String, dynamic> json) {
    return Trabajador(
      id: json['id']?.toString() ?? '',
      rut: json['rut']?.toString(),
      codigoVerificador: json['codigo_verificador']?.toString(),
      nombre: json['nombre']?.toString() ?? '',
      apellidoPaterno: json['apellido_paterno']?.toString() ?? '',
      apellidoMaterno: json['apellido_materno']?.toString(),
      idContratista: json['id_contratista']?.toString() ?? '',
      idPorcentaje: json['id_porcentaje']?.toString() ?? '',
      idEstado: json['id_estado']?.toString() ?? '',
      idSucursalActiva: json['id_sucursal_activa']?.toString() ?? '',
      nombreContratista: json['nombre_contratista']?.toString(),
      porcentaje: json['porcentaje'] != null 
          ? (json['porcentaje'] is num 
              ? json['porcentaje'].toDouble() 
              : double.tryParse(json['porcentaje'].toString()) ?? 0.0)
          : null,
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
      'id_contratista': idContratista,
      'id_porcentaje': idPorcentaje,
      'id_estado': idEstado,
      'id_sucursal_activa': idSucursalActiva,
      'nombre_contratista': nombreContratista,
      'porcentaje': porcentaje,
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

  // Método para obtener el estado como texto
  String get estadoText {
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
    switch (idEstado) {
      case '1':
        return 'green';
      case '2':
        return 'red';
      default:
        return 'grey';
    }
  }

  // Método para obtener el porcentaje formateado
  String get porcentajeFormateado {
    if (porcentaje != null) {
      return '${(porcentaje! * 100).round()}%';
    }
    return 'N/A';
  }

  // Método para clonar el trabajador con cambios
  Trabajador copyWith({
    String? id,
    String? rut,
    String? codigoVerificador,
    String? nombre,
    String? apellidoPaterno,
    String? apellidoMaterno,
    String? idContratista,
    String? idPorcentaje,
    String? idEstado,
    String? idSucursalActiva,
    String? nombreContratista,
    double? porcentaje,
  }) {
    return Trabajador(
      id: id ?? this.id,
      rut: rut ?? this.rut,
      codigoVerificador: codigoVerificador ?? this.codigoVerificador,
      nombre: nombre ?? this.nombre,
      apellidoPaterno: apellidoPaterno ?? this.apellidoPaterno,
      apellidoMaterno: apellidoMaterno ?? this.apellidoMaterno,
      idContratista: idContratista ?? this.idContratista,
      idPorcentaje: idPorcentaje ?? this.idPorcentaje,
      idEstado: idEstado ?? this.idEstado,
      idSucursalActiva: idSucursalActiva ?? this.idSucursalActiva,
      nombreContratista: nombreContratista ?? this.nombreContratista,
      porcentaje: porcentaje ?? this.porcentaje,
    );
  }
}
