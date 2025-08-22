class Colaborador {
  final String id;
  final String? rut;
  final String? codigoVerificador;
  final String nombre;
  final String apellidoPaterno;
  final String? apellidoMaterno;
  final String idSucursal;
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
  final String? nombreEstado;
  final String? fechaFiniquito;

  Colaborador({
    required this.id,
    this.rut,
    this.codigoVerificador,
    required this.nombre,
    required this.apellidoPaterno,
    this.apellidoMaterno,
    required this.idSucursal,
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
    this.nombreEstado,
    this.fechaFiniquito,
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
      nombreEstado: json['nombre_estado']?.toString(),
      fechaFiniquito: json['fecha_finiquito']?.toString(),
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
      'nombre_estado': nombreEstado,
      'fecha_finiquito': fechaFiniquito,
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
    return idSucursal.isNotEmpty ? 'Sucursal $idSucursal' : 'Sin sucursal';
  }

  // Método para parsear fechas en formato "Mon, 18 Aug 2025 00:00:00 GMT"
  DateTime? _parseFecha(String? fechaStr) {
    if (fechaStr == null || fechaStr.isEmpty) return null;
    
    try {
      // Intentar parsear como ISO primero
      return DateTime.parse(fechaStr);
    } catch (e) {
      try {
        // Si falla, intentar con el formato específico del backend
        // "Mon, 18 Aug 2025 00:00:00 GMT"
        final regex = RegExp(r'(\w{3}), (\d{1,2}) (\w{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2}) GMT');
        final match = regex.firstMatch(fechaStr);
        
        if (match != null) {
          final day = int.parse(match.group(2)!);
          final monthStr = match.group(3)!;
          final year = int.parse(match.group(4)!);
          final hour = int.parse(match.group(5)!);
          final minute = int.parse(match.group(6)!);
          final second = int.parse(match.group(7)!);
          
          // Mapear nombres de meses a números
          final monthMap = {
            'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
            'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
          };
          
          final month = monthMap[monthStr];
          if (month != null) {
            return DateTime(year, month, day, hour, minute, second);
          }
        }
        return null;
      } catch (e) {
        return null;
      }
    }
  }

  // Método para formatear fecha de nacimiento en formato chileno
  String get fechaNacimientoFormateada {
    final fecha = _parseFecha(fechaNacimiento);
    if (fecha != null) {
      return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
    }
    return fechaNacimiento ?? 'Sin fecha';
  }

  // Método para formatear fecha de incorporación en formato chileno
  String get fechaIncorporacionFormateada {
    final fecha = _parseFecha(fechaIncorporacion);
    if (fecha != null) {
      return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
    }
    return fechaIncorporacion ?? 'Sin fecha';
  }

  // Método para formatear fecha de nacimiento en español con día de la semana
  String get fechaNacimientoFormateadaEspanol {
    final fecha = _parseFecha(fechaNacimiento);
    if (fecha != null) {
      final diasSemana = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      final meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
      
      final diaSemana = diasSemana[fecha.weekday - 1];
      final dia = fecha.day.toString().padLeft(2, '0');
      final mes = meses[fecha.month - 1];
      final anio = fecha.year;
      
      return '$diaSemana, $dia $mes $anio';
    }
    return fechaNacimiento ?? 'Sin fecha';
  }

  // Método para formatear fecha de incorporación en español con día de la semana
  String get fechaIncorporacionFormateadaEspanol {
    final fecha = _parseFecha(fechaIncorporacion);
    if (fecha != null) {
      final diasSemana = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      final meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
      
      final diaSemana = diasSemana[fecha.weekday - 1];
      final dia = fecha.day.toString().padLeft(2, '0');
      final mes = meses[fecha.month - 1];
      final anio = fecha.year;
      
      return '$diaSemana, $dia $mes $anio';
    }
    return fechaIncorporacion ?? 'Sin fecha';
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
    String? nombreEstado,
    String? fechaFiniquito,
  }) {
    return Colaborador(
      id: id ?? this.id,
      rut: rut ?? this.rut,
      codigoVerificador: codigoVerificador ?? this.codigoVerificador,
      nombre: nombre ?? this.nombre,
      apellidoPaterno: apellidoPaterno ?? this.apellidoPaterno,
      apellidoMaterno: apellidoMaterno ?? this.apellidoMaterno,
      idSucursal: idSucursal ?? this.idSucursal,
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
      nombreEstado: nombreEstado ?? this.nombreEstado,
      fechaFiniquito: fechaFiniquito ?? this.fechaFiniquito,
    );
  }
}
