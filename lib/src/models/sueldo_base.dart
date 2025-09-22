import 'dart:convert';

class SueldoBase {
  final int id;
  final int sueldobase;
  final String idColaborador;
  final DateTime fecha;
  final int baseDia;
  final int horaDia;
  final String? nombreColaborador;
  final String? rut;
  final String? nombreSucursal;

  SueldoBase({
    required this.id,
    required this.sueldobase,
    required this.idColaborador,
    required this.fecha,
    required this.baseDia,
    required this.horaDia,
    this.nombreColaborador,
    this.rut,
    this.nombreSucursal,
  });

  // Constructor para sueldos base dentro de la estructura agrupada
  SueldoBase.fromGroupedJson(Map<String, dynamic> json) 
    : id = json['id'] ?? 0,
      sueldobase = json['sueldobase'] ?? 0,
      idColaborador = '', // Se asignará desde el colaborador padre
      fecha = _parseDate(json['fecha']),
      baseDia = json['base_dia'] ?? 0,
      horaDia = json['hora_dia'] ?? 0,
      nombreColaborador = null, // Se asignará desde el colaborador padre
      rut = null, // Se asignará desde el colaborador padre
      nombreSucursal = null; // Se asignará desde el colaborador padre

  factory SueldoBase.fromJson(Map<String, dynamic> json) {
    return SueldoBase(
      id: json['id'] ?? 0,
      sueldobase: json['sueldobase'] ?? 0,
      idColaborador: json['id_colaborador']?.toString() ?? '',
      fecha: _parseDate(json['fecha']),
      baseDia: json['base_dia'] ?? 0,
      horaDia: json['hora_dia'] ?? 0,
      nombreColaborador: json['nombre_colaborador']?.toString(),
      rut: json['rut']?.toString(),
      nombreSucursal: json['nombre_sucursal']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sueldobase': sueldobase,
      'id_colaborador': idColaborador,
      'fecha': fecha.toIso8601String().split('T')[0], // Formato YYYY-MM-DD
      'base_dia': baseDia,
      'hora_dia': horaDia,
      'nombre_colaborador': nombreColaborador,
      'rut': rut,
      'nombre_sucursal': nombreSucursal,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'sueldobase': sueldobase,
      'id_colaborador': idColaborador,
      'fecha': fecha.toIso8601String().split('T')[0], // Formato YYYY-MM-DD
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'sueldobase': sueldobase,
      'id_colaborador': idColaborador,
      'fecha': fecha.toIso8601String().split('T')[0], // Formato YYYY-MM-DD
    };
  }

  // Getters para formateo
  String get sueldobaseFormateado {
    return '\$${sueldobase.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }

  String get baseDiaFormateado {
    return '\$${baseDia.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }

  String get horaDiaFormateado {
    return '\$${horaDia.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }

  String get fechaFormateada {
    final diasSemana = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    
    final diaSemana = diasSemana[fecha.weekday - 1];
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = meses[fecha.month - 1];
    final anio = fecha.year;
    
    return '$diaSemana, $dia $mes $anio';
  }

  String get fechaFormateadaEspanol {
    final diasSemana = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    
    final diaSemana = diasSemana[fecha.weekday - 1];
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = meses[fecha.month - 1];
    final anio = fecha.year;
    
    return '$diaSemana, $dia $mes $anio';
  }

  @override
  String toString() {
    return 'SueldoBase(id: $id, sueldobase: $sueldobase, idColaborador: $idColaborador, fecha: $fecha)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SueldoBase && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Método para parsear fechas en formato "Mon, 18 Aug 2025 00:00:00 GMT"
  static DateTime _parseDate(dynamic fecha) {
    if (fecha == null) return DateTime.now();
    
    try {
      // Si es un string, intentar parsearlo
      if (fecha is String) {
        try {
          // Intentar parsear como ISO primero
          return DateTime.parse(fecha);
        } catch (e) {
          try {
            // Si falla, intentar con el formato específico del backend
            // "Mon, 18 Aug 2025 00:00:00 GMT"
            final regex = RegExp(r'(\w{3}), (\d{1,2}) (\w{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2}) GMT');
            final match = regex.firstMatch(fecha);
            
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
            return DateTime.now();
          } catch (e) {
            return DateTime.now();
          }
        }
      }
      
      // Si es un número (timestamp)
      if (fecha is int) {
        return DateTime.fromMillisecondsSinceEpoch(fecha);
      }
      
      // Si es un double (timestamp)
      if (fecha is double) {
        return DateTime.fromMillisecondsSinceEpoch(fecha.toInt());
      }
      
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }
}

// Modelo para la estructura agrupada por colaborador
class SueldoBaseAgrupado {
  final String colaboradorId;
  final String nombreColaborador;
  final String rut;
  final String nombreSucursal;
  final List<SueldoBase> sueldosBase;

  SueldoBaseAgrupado({
    required this.colaboradorId,
    required this.nombreColaborador,
    required this.rut,
    required this.nombreSucursal,
    required this.sueldosBase,
  });

  factory SueldoBaseAgrupado.fromJson(Map<String, dynamic> json) {
    List<dynamic> sueldosBaseJson = [];
    
    // El backend ahora devuelve sueldos_base como array real (ya ordenado por fecha descendente)
    if (json['sueldos_base'] is List) {
      sueldosBaseJson = json['sueldos_base'] as List<dynamic>;
    } else if (json['sueldos_base'] is String) {
      // Fallback para compatibilidad con versiones anteriores (string JSON)
      try {
        sueldosBaseJson = jsonDecode(json['sueldos_base']) as List<dynamic>;
      } catch (e) {
        // print('❌ [SUELDO_BASE] Error al parsear sueldos_base string: $e');
        sueldosBaseJson = [];
      }
    }

    return SueldoBaseAgrupado(
      colaboradorId: json['colaborador_id']?.toString() ?? '',
      nombreColaborador: json['nombre_colaborador']?.toString() ?? '',
      rut: json['rut']?.toString() ?? '',
      nombreSucursal: json['nombre_sucursal']?.toString() ?? '',
      sueldosBase: sueldosBaseJson.map((sueldoJson) {
        final sueldo = SueldoBase.fromGroupedJson(sueldoJson);
        // Asignar datos del colaborador padre a cada sueldo
        return SueldoBase(
          id: sueldo.id,
          sueldobase: sueldo.sueldobase,
          idColaborador: json['colaborador_id']?.toString() ?? '',
          fecha: sueldo.fecha,
          baseDia: sueldo.baseDia,
          horaDia: sueldo.horaDia,
          nombreColaborador: json['nombre_colaborador']?.toString(),
          rut: json['rut']?.toString(),
          nombreSucursal: json['nombre_sucursal']?.toString(),
        );
      }).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'colaborador_id': colaboradorId,
      'nombre_colaborador': nombreColaborador,
      'rut': rut,
      'nombre_sucursal': nombreSucursal,
      'sueldos_base': sueldosBase.map((sueldo) => sueldo.toJson()).toList(),
    };
  }

  // Obtener el sueldo base más reciente
  SueldoBase? get sueldoMasReciente {
    if (sueldosBase.isEmpty) return null;
    return sueldosBase.first; // Ya están ordenados por fecha descendente
  }

  // Obtener el sueldo base más antiguo
  SueldoBase? get sueldoMasAntiguo {
    if (sueldosBase.isEmpty) return null;
    return sueldosBase.last; // El último es el más antiguo
  }

  // Obtener el promedio de sueldos base
  double get promedioSueldos {
    if (sueldosBase.isEmpty) return 0.0;
    final total = sueldosBase.fold<int>(0, (sum, sueldo) => sum + sueldo.sueldobase);
    return total / sueldosBase.length;
  }

  // Obtener el total de sueldos base
  int get totalSueldos {
    return sueldosBase.fold<int>(0, (sum, sueldo) => sum + sueldo.sueldobase);
  }

  @override
  String toString() {
    return 'SueldoBaseAgrupado(colaboradorId: $colaboradorId, nombreColaborador: $nombreColaborador, sueldosCount: ${sueldosBase.length})';
  }
}