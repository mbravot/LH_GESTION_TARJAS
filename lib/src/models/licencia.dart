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

  // Getters para fechas parseadas
  DateTime? get fechaInicioDateTime => _parseFecha(fechaInicio);
  DateTime? get fechaFinDateTime => _parseFecha(fechaFin);

  // Método para parsear fechas en formato "Mon, 18 Aug 2025 00:00:00 GMT"
  DateTime? _parseFecha(String fechaStr) {
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

  // Método para obtener la duración en días
  int get duracionDias {
    final inicio = _parseFecha(fechaInicio);
    final fin = _parseFecha(fechaFin);
    
    if (inicio != null && fin != null) {
      return fin.difference(inicio).inDays + 1; // +1 para incluir el día de inicio
    }
    return 0;
  }

  // Método para verificar si la licencia está en el futuro
  bool get esFutura {
    final inicio = _parseFecha(fechaInicio);
    if (inicio == null) return false;
    final ahora = DateTime.now();
    return inicio.isAfter(ahora);
  }

  // Método para verificar si la licencia está en el presente
  bool get esPresente {
    final inicio = _parseFecha(fechaInicio);
    final fin = _parseFecha(fechaFin);
    if (inicio == null || fin == null) return false;
    final ahora = DateTime.now();
    return inicio.isBefore(ahora) && fin.isAfter(ahora);
  }

  // Método para verificar si la licencia está en el pasado
  bool get esPasada {
    final fin = _parseFecha(fechaFin);
    if (fin == null) return false;
    final ahora = DateTime.now();
    return fin.isBefore(ahora);
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

  // Método para formatear las fechas en formato chileno
  String get fechaInicioFormateada {
    final fecha = _parseFecha(fechaInicio);
    if (fecha != null) {
      return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
    }
    return fechaInicio;
  }

  String get fechaFinFormateada {
    final fecha = _parseFecha(fechaFin);
    if (fecha != null) {
      return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
    }
    return fechaFin;
  }

  // Método para formatear las fechas en español con día de la semana
  String get fechaInicioFormateadaEspanol {
    final fecha = _parseFecha(fechaInicio);
    if (fecha != null) {
      final diasSemana = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      final meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
      
      final diaSemana = diasSemana[fecha.weekday - 1];
      final dia = fecha.day.toString().padLeft(2, '0');
      final mes = meses[fecha.month - 1];
      final anio = fecha.year;
      
      return '$diaSemana, $dia $mes $anio';
    }
    return fechaInicio;
  }

  String get fechaFinFormateadaEspanol {
    final fecha = _parseFecha(fechaFin);
    if (fecha != null) {
      final diasSemana = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      final meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
      
      final diaSemana = diasSemana[fecha.weekday - 1];
      final dia = fecha.day.toString().padLeft(2, '0');
      final mes = meses[fecha.month - 1];
      final anio = fecha.year;
      
      return '$diaSemana, $dia $mes $anio';
    }
    return fechaFin;
  }

  // Método para obtener el período formateado en español
  String get periodoFormateadoEspanol {
    return '$fechaInicioFormateadaEspanol - $fechaFinFormateadaEspanol';
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
