import 'dart:convert';

class HorasTrabajadas {
  final String idColaborador;
  final String colaborador;
  final String fecha;
  final String nombreDia;
  final double totalHorasTrabajadas;
  final double totalHorasExtras;
  final double horasEsperadas;
  final double diferenciaHoras;
  final String estadoTrabajo;
  final int cantidadActividades;
  final List<ActividadDetalle> actividadesDetalle;

  HorasTrabajadas({
    required this.idColaborador,
    required this.colaborador,
    required this.fecha,
    required this.nombreDia,
    required this.totalHorasTrabajadas,
    required this.totalHorasExtras,
    required this.horasEsperadas,
    required this.diferenciaHoras,
    required this.estadoTrabajo,
    required this.cantidadActividades,
    required this.actividadesDetalle,
  });

  factory HorasTrabajadas.fromJson(Map<String, dynamic> json) {
    List<ActividadDetalle> actividades = [];
    
    // Manejar actividades_detalle que puede venir como string JSON o como array
    if (json['actividades_detalle'] != null) {
      if (json['actividades_detalle'] is String) {
        // Si es string, intentar parsearlo como JSON
        try {
          final actividadesJson = jsonDecode(json['actividades_detalle'] as String);
          if (actividadesJson is List) {
            actividades = actividadesJson
                .map((actividad) => ActividadDetalle.fromJson(actividad))
                .toList();
          }
        } catch (e) {
          // Error silencioso al parsear actividades
        }
      } else if (json['actividades_detalle'] is List) {
        // Si ya es una lista
        actividades = (json['actividades_detalle'] as List<dynamic>)
            .map((actividad) => ActividadDetalle.fromJson(actividad))
            .toList();
      }
    }
    
    return HorasTrabajadas(
      idColaborador: json['id_colaborador']?.toString() ?? '',
      colaborador: json['colaborador']?.toString() ?? '',
      fecha: json['fecha']?.toString() ?? '',
      nombreDia: json['nombre_dia']?.toString() ?? '',
      totalHorasTrabajadas: _toDouble(json['total_horas_trabajadas']),
      totalHorasExtras: _toDouble(json['total_horas_extras']),
      horasEsperadas: _toDouble(json['horas_esperadas']),
      diferenciaHoras: _toDouble(json['diferencia_horas']),
      estadoTrabajo: json['estado_trabajo']?.toString() ?? '',
      cantidadActividades: json['cantidad_actividades'] ?? 0,
      actividadesDetalle: actividades,
    );
  }

  // Conversión segura a double para valores que pueden venir como num o String
  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) {
      final normalized = value.replaceAll(',', '.');
      return double.tryParse(normalized) ?? 0;
    }
    return 0;
  }

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

  // Getters para formateo
  String get fechaFormateadaEspanol {
    final fechaParsed = _parseFecha(fecha);
    if (fechaParsed != null) {
      return '${fechaParsed.day.toString().padLeft(2, '0')}/${fechaParsed.month.toString().padLeft(2, '0')}/${fechaParsed.year}';
    }
    return fecha;
  }

  // Método para formatear fecha en español con día de la semana
  String get fechaFormateadaEspanolCompleta {
    final fechaParsed = _parseFecha(fecha);
    if (fechaParsed != null) {
      final diasSemana = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      final meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
      
      final diaSemana = diasSemana[fechaParsed.weekday - 1];
      final dia = fechaParsed.day.toString().padLeft(2, '0');
      final mes = meses[fechaParsed.month - 1];
      final anio = fechaParsed.year;
      
      return '$diaSemana, $dia $mes $anio';
    }
    return fecha;
  }

  String get totalHorasTrabajadasFormateadas {
    return totalHorasTrabajadas.toStringAsFixed(1);
  }

  String get totalHorasExtrasFormateadas {
    return totalHorasExtras.toStringAsFixed(1);
  }

  String get horasEsperadasFormateadas {
    return horasEsperadas.toStringAsFixed(1);
  }

  String get diferenciaHorasFormateadas {
    return diferenciaHoras.toStringAsFixed(1);
  }

  // Total de horas (trabajadas + extras)
  double get totalHoras {
    return totalHorasTrabajadas + totalHorasExtras;
  }

  String get totalHorasFormateadas {
    return totalHoras.toStringAsFixed(1);
  }

  // Color del estado
  String get estadoColor {
    switch (estadoTrabajo.toUpperCase()) {
      case 'MÁS':
        return '#F44336'; // Rojo
      case 'MENOS':
        return '#F44336'; // Rojo
      case 'EXACTO':
        return '#4CAF50'; // Verde
      default:
        return '#757575'; // Gris
    }
  }

  // Icono del estado
  String get estadoIcono {
    switch (estadoTrabajo.toUpperCase()) {
      case 'MÁS':
        return 'arrow_upward';
      case 'MENOS':
        return 'arrow_downward';
      case 'EXACTO':
        return 'check_circle';
      default:
        return 'help';
    }
  }

  // Texto del estado
  String get estadoTexto {
    switch (estadoTrabajo.toUpperCase()) {
      case 'MÁS':
        return 'Más horas';
      case 'MENOS':
        return 'Menos horas';
      case 'EXACTO':
        return 'Horas exactas';
      default:
        return 'Sin estado';
    }
  }
}

// Modelo para el detalle de actividades
class ActividadDetalle {
  final String idActividad;
  final String rendimientoId;
  final String labor;
  final String ceco;
  final double horasTrabajadas;
  final double horasExtras;
  final double rendimiento;
  final String horaInicio;
  final String horaFin;

  ActividadDetalle({
    required this.idActividad,
    required this.rendimientoId,
    required this.labor,
    required this.ceco,
    required this.horasTrabajadas,
    required this.horasExtras,
    required this.rendimiento,
    required this.horaInicio,
    required this.horaFin,
  });

  factory ActividadDetalle.fromJson(Map<String, dynamic> json) {
    // Debug: imprimir el JSON completo para ver qué campos vienen
    print('🔧 Debug - ActividadDetalle JSON: ${json.toString()}');
    
    // Obtener el rendimiento_id directamente del backend
    String rendimientoId = json['rendimiento_id']?.toString() ?? '';
    
    print('🔧 Debug - Rendimiento ID encontrado: $rendimientoId');
    
    return ActividadDetalle(
      idActividad: json['id_actividad']?.toString() ?? '',
      rendimientoId: rendimientoId,
      labor: json['labor']?.toString() ?? '',
      ceco: json['ceco']?.toString() ?? '',
      horasTrabajadas: HorasTrabajadas._toDouble(json['horas_trabajadas']),
      horasExtras: HorasTrabajadas._toDouble(json['horas_extras']),
      rendimiento: HorasTrabajadas._toDouble(json['rendimiento']),
      horaInicio: json['hora_inicio']?.toString() ?? '',
      horaFin: json['hora_fin']?.toString() ?? '',
    );
  }

  String get horasTrabajadasFormateadas {
    return horasTrabajadas.toStringAsFixed(1);
  }

  String get horasExtrasFormateadas {
    return horasExtras.toStringAsFixed(1);
  }

  String get rendimientoFormateado {
    return rendimiento.toStringAsFixed(1);
  }

  // Total de horas de la actividad
  double get totalHoras {
    return horasTrabajadas + horasExtras;
  }

  String get totalHorasFormateadas {
    return totalHoras.toStringAsFixed(1);
  }

  // Formatear hora (quitar segundos si es necesario)
  String get horaInicioFormateada {
    if (horaInicio.length > 5) {
      return horaInicio.substring(0, 5); // Solo HH:MM
    }
    return horaInicio;
  }

  String get horaFinFormateada {
    if (horaFin.length > 5) {
      return horaFin.substring(0, 5); // Solo HH:MM
    }
    return horaFin;
  }
}
