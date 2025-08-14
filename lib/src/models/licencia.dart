class Licencia {
  final String id;
  final String idColaborador;
  final String fechaInicio;
  final String fechaFin;
  final String? nombreColaborador;
  final String? apellidoPaterno;
  final String? apellidoMaterno;
  final String? idSucursal;

  Licencia({
    required this.id,
    required this.idColaborador,
    required this.fechaInicio,
    required this.fechaFin,
    this.nombreColaborador,
    this.apellidoPaterno,
    this.apellidoMaterno,
    this.idSucursal,
  });

  factory Licencia.fromJson(Map<String, dynamic> json) {
    return Licencia(
      id: json['id']?.toString() ?? '',
      idColaborador: json['id_colaborador']?.toString() ?? '',
      fechaInicio: json['fecha_inicio']?.toString() ?? '',
      fechaFin: json['fecha_fin']?.toString() ?? '',
      nombreColaborador: json['nombre_colaborador']?.toString(),
      apellidoPaterno: json['apellido_paterno']?.toString(),
      apellidoMaterno: json['apellido_materno']?.toString(),
      idSucursal: json['id_sucursal']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_colaborador': idColaborador,
      'fecha_inicio': fechaInicio,
      'fecha_fin': fechaFin,
      'nombre_colaborador': nombreColaborador,
      'apellido_paterno': apellidoPaterno,
      'apellido_materno': apellidoMaterno,
      'id_sucursal': idSucursal,
    };
  }

  // Método para obtener el nombre completo del colaborador
  String get nombreCompletoColaborador {
    final apellidoMaternoStr = apellidoMaterno?.isNotEmpty == true ? ' $apellidoMaterno' : '';
    return '${nombreColaborador ?? 'Sin nombre'} ${apellidoPaterno ?? ''}$apellidoMaternoStr';
  }

  // Método para obtener la duración en días
  int get duracionDias {
    try {
      final inicio = DateTime.parse(fechaInicio);
      final fin = DateTime.parse(fechaFin);
      return fin.difference(inicio).inDays + 1; // +1 para incluir el día de inicio
    } catch (e) {
      return 0;
    }
  }

  // Método para verificar si la licencia está en el futuro
  bool get esFutura {
    try {
      final inicio = DateTime.parse(fechaInicio);
      final ahora = DateTime.now();
      return inicio.isAfter(ahora);
    } catch (e) {
      return false;
    }
  }

  // Método para verificar si la licencia está en el presente
  bool get esPresente {
    try {
      final inicio = DateTime.parse(fechaInicio);
      final fin = DateTime.parse(fechaFin);
      final ahora = DateTime.now();
      return inicio.isBefore(ahora) && fin.isAfter(ahora);
    } catch (e) {
      return false;
    }
  }

  // Método para verificar si la licencia está en el pasado
  bool get esPasada {
    try {
      final fin = DateTime.parse(fechaFin);
      final ahora = DateTime.now();
      return fin.isBefore(ahora);
    } catch (e) {
      return false;
    }
  }

  // Método para obtener el estado de la licencia
  String get estado {
    if (esPresente) return 'En curso';
    if (esFutura) return 'Programada';
    if (esPasada) return 'Completada';
    return 'Desconocido';
  }

  // Método para obtener el color del estado
  String get estadoColor {
    switch (estado) {
      case 'En curso':
        return 'orange';
      case 'Programada':
        return 'blue';
      case 'Completada':
        return 'green';
      default:
        return 'grey';
    }
  }

  // Método para formatear las fechas
  String get fechaInicioFormateada {
    try {
      final fecha = DateTime.parse(fechaInicio);
      return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
    } catch (e) {
      return fechaInicio;
    }
  }

  String get fechaFinFormateada {
    try {
      final fecha = DateTime.parse(fechaFin);
      return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
    } catch (e) {
      return fechaFin;
    }
  }

  // Método para obtener el período formateado
  String get periodoFormateado {
    return '$fechaInicioFormateada - $fechaFinFormateada';
  }

  // Método para clonar la licencia con cambios
  Licencia copyWith({
    String? id,
    String? idColaborador,
    String? fechaInicio,
    String? fechaFin,
    String? nombreColaborador,
    String? apellidoPaterno,
    String? apellidoMaterno,
    String? idSucursal,
  }) {
    return Licencia(
      id: id ?? this.id,
      idColaborador: idColaborador ?? this.idColaborador,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      nombreColaborador: nombreColaborador ?? this.nombreColaborador,
      apellidoPaterno: apellidoPaterno ?? this.apellidoPaterno,
      apellidoMaterno: apellidoMaterno ?? this.apellidoMaterno,
      idSucursal: idSucursal ?? this.idSucursal,
    );
  }
}
