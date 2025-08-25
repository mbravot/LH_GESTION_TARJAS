class Permiso {
  final String id;
  final String idUsuario;
  final String timestamp;
  final String fecha;
  final String idTipopermiso;
  final String idColaborador;
  final String horas;
  final String idEstadopermiso;
  final String? tipoPermiso;
  final String? nombreColaborador;
  final String? apellidoPaterno;
  final String? apellidoMaterno;
  final String? estadoPermiso;

  Permiso({
    required this.id,
    required this.idUsuario,
    required this.timestamp,
    required this.fecha,
    required this.idTipopermiso,
    required this.idColaborador,
    required this.horas,
    required this.idEstadopermiso,
    this.tipoPermiso,
    this.nombreColaborador,
    this.apellidoPaterno,
    this.apellidoMaterno,
    this.estadoPermiso,
  });

  factory Permiso.fromJson(Map<String, dynamic> json) {
    return Permiso(
      id: json['id']?.toString() ?? '',
      idUsuario: json['id_usuario']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? '',
      fecha: json['fecha']?.toString() ?? '',
      idTipopermiso: json['id_tipopermiso']?.toString() ?? '',
      idColaborador: json['id_colaborador']?.toString() ?? '',
      horas: json['horas']?.toString() ?? '',
      idEstadopermiso: json['id_estadopermiso']?.toString() ?? '',
      tipoPermiso: json['tipo_permiso']?.toString(),
      nombreColaborador: json['nombre_colaborador']?.toString(),
      apellidoPaterno: json['apellido_paterno']?.toString(),
      apellidoMaterno: json['apellido_materno']?.toString(),
      estadoPermiso: json['estado_permiso']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_usuario': idUsuario,
      'timestamp': timestamp,
      'fecha': fecha,
      'id_tipopermiso': idTipopermiso,
      'id_colaborador': idColaborador,
      'horas': horas,
      'id_estadopermiso': idEstadopermiso,
      'tipo_permiso': tipoPermiso,
      'nombre_colaborador': nombreColaborador,
      'apellido_paterno': apellidoPaterno,
      'apellido_materno': apellidoMaterno,
      'estado_permiso': estadoPermiso,
    };
  }

  // Método para obtener el nombre completo del colaborador
  String get nombreCompletoColaborador {
    final nombre = nombreColaborador ?? '';
    final apellidoP = apellidoPaterno ?? '';
    final apellidoM = apellidoMaterno ?? '';
    
    if (apellidoM.isNotEmpty) {
      return '$nombre $apellidoP $apellidoM'.trim();
    } else {
      return '$nombre $apellidoP'.trim();
    }
  }

  // Método para formatear la fecha en formato español
  String get fechaFormateadaEspanol {
    final fecha = _parseFecha(this.fecha);
    if (fecha != null) {
      final diasSemana = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
      final meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
      
      final diaSemana = diasSemana[fecha.weekday % 7];
      final dia = fecha.day.toString().padLeft(2, '0');
      final mes = meses[fecha.month - 1];
      final anio = fecha.year;
      
      return '$diaSemana, $dia $mes $anio';
    }
    return this.fecha;
  }

  // Método para formatear el timestamp en formato español
  String get timestampFormateadoEspanol {
    final fecha = _parseFecha(this.timestamp);
    if (fecha != null) {
      final diasSemana = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
      final meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
      
      final diaSemana = diasSemana[fecha.weekday % 7];
      final dia = fecha.day.toString().padLeft(2, '0');
      final mes = meses[fecha.month - 1];
      final anio = fecha.year;
      final hora = fecha.hour.toString().padLeft(2, '0');
      final minuto = fecha.minute.toString().padLeft(2, '0');
      
      return '$diaSemana, $dia $mes $anio $hora:$minuto';
    }
    return this.timestamp;
  }

  // Método para verificar si el permiso está en el futuro
  bool get esFuturo {
    final fecha = _parseFecha(this.fecha);
    if (fecha == null) return false;
    final ahora = DateTime.now();
    return fecha.isAfter(ahora);
  }

  // Método para verificar si el permiso es hoy
  bool get esHoy {
    final fecha = _parseFecha(this.fecha);
    if (fecha == null) return false;
    final ahora = DateTime.now();
    return fecha.year == ahora.year && 
           fecha.month == ahora.month && 
           fecha.day == ahora.day;
  }

  // Método para verificar si el permiso está en el pasado
  bool get esPasado {
    final fecha = _parseFecha(this.fecha);
    if (fecha == null) return false;
    final ahora = DateTime.now();
    return fecha.isBefore(ahora) && !esHoy;
  }

  // Método para obtener el estado del permiso basado en idEstadopermiso
  String get estado {
    // Mapear idEstadopermiso a estados legibles
    switch (idEstadopermiso) {
      case '1':
        return 'Creado';
      case '2':
        return 'Aprobado';
      case '3':
        return 'Por Aprobar'; // Este es el mismo que Creado pero para aprobación
      default:
        return estadoPermiso ?? 'Desconocido';
    }
  }

  // Método para obtener el color del estado
  String get estadoColor {
    switch (estado) {
      case 'Creado':
        return 'blue';
      case 'Aprobado':
        return 'green';
      case 'Por Aprobar':
        return 'orange';
      default:
        return 'grey';
    }
  }

  // Método para verificar si se puede editar
  bool get sePuedeEditar {
    return estado == 'Creado' || estado == 'Aprobado';
  }

  // Método para verificar si se puede eliminar
  bool get sePuedeEliminar {
    return estado == 'Creado' || estado == 'Aprobado';
  }

  // Método para verificar si se puede aprobar
  bool get sePuedeAprobar {
    return estado == 'Por Aprobar'; // Los permisos "Por Aprobar" son los que se pueden aprobar
  }

  // Método para parsear fechas del backend
  DateTime? _parseFecha(String fechaStr) {
    try {
      // Intentar parsear formato ISO
      if (fechaStr.contains('T') || fechaStr.contains('Z')) {
        return DateTime.parse(fechaStr);
      }
      
      // Intentar parsear formato específico del backend
      if (fechaStr.contains(',')) {
        final regex = RegExp(r'(\w{3}), (\d{1,2}) (\w{3}) (\d{4})');
        final match = regex.firstMatch(fechaStr);
        if (match != null) {
          final diaSemana = match.group(1);
          final dia = int.parse(match.group(2)!);
          final mesStr = match.group(3)!;
          final anio = int.parse(match.group(4)!);
          
          final monthMap = {
            'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
            'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
          };
          
          final month = monthMap[mesStr];
          if (month != null) {
            return DateTime(anio, month, dia);
          }
        }
      }
      
      // Intentar parsear formato YYYY-MM-DD
      if (fechaStr.contains('-')) {
        final parts = fechaStr.split('-');
        if (parts.length == 3) {
          final anio = int.parse(parts[0]);
          final mes = int.parse(parts[1]);
          final dia = int.parse(parts[2]);
          return DateTime(anio, mes, dia);
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
}
