class SueldoBase {
  final int id;
  final int sueldobase;
  final String idColaborador;
  final DateTime fecha;
  final int baseDia;
  final int horaDia;
  
  // Campos adicionales del colaborador
  final String? nombreColaborador;
  final String? apellidoPaternoColaborador;
  final String? apellidoMaternoColaborador;

  SueldoBase({
    required this.id,
    required this.sueldobase,
    required this.idColaborador,
    required this.fecha,
    required this.baseDia,
    required this.horaDia,
    this.nombreColaborador,
    this.apellidoPaternoColaborador,
    this.apellidoMaternoColaborador,
  });

  factory SueldoBase.fromJson(Map<String, dynamic> json) {
    return SueldoBase(
      id: json['id'] ?? 0,
      sueldobase: json['sueldobase'] ?? 0,
      idColaborador: json['id_colaborador']?.toString() ?? '',
      fecha: DateTime.parse(json['fecha']),
      baseDia: json['base_dia'] ?? 0,
      horaDia: json['hora_dia'] ?? 0,
      nombreColaborador: json['nombre_colaborador']?.toString(),
      apellidoPaternoColaborador: json['apellido_paterno_colaborador']?.toString(),
      apellidoMaternoColaborador: json['apellido_materno_colaborador']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sueldobase': sueldobase,
      'id_colaborador': idColaborador,
      'fecha': fecha.toIso8601String().split('T')[0],
      'base_dia': baseDia,
      'hora_dia': horaDia,
      'nombre_colaborador': nombreColaborador,
      'apellido_paterno_colaborador': apellidoPaternoColaborador,
      'apellido_materno_colaborador': apellidoMaternoColaborador,
    };
  }

  // Método para obtener el nombre completo del colaborador
  String get nombreCompletoColaborador {
    final apellidoMaternoStr = apellidoMaternoColaborador?.isNotEmpty == true ? ' $apellidoMaternoColaborador' : '';
    return '${nombreColaborador ?? ''} ${apellidoPaternoColaborador ?? ''}$apellidoMaternoStr'.trim();
  }

  // Método para obtener el sueldo base formateado
  String get sueldobaseFormateado {
    return '\$${sueldobase.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  // Método para obtener la base diaria formateada
  String get baseDiaFormateada {
    return '\$${baseDia.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  // Método para obtener la hora por día formateada
  String get horaDiaFormateada {
    return '\$${horaDia.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  // Método para obtener la fecha formateada
  String get fechaFormateada {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  // Método para clonar el sueldo base con cambios
  SueldoBase copyWith({
    int? id,
    int? sueldobase,
    String? idColaborador,
    DateTime? fecha,
    int? baseDia,
    int? horaDia,
    String? nombreColaborador,
    String? apellidoPaternoColaborador,
    String? apellidoMaternoColaborador,
  }) {
    return SueldoBase(
      id: id ?? this.id,
      sueldobase: sueldobase ?? this.sueldobase,
      idColaborador: idColaborador ?? this.idColaborador,
      fecha: fecha ?? this.fecha,
      baseDia: baseDia ?? this.baseDia,
      horaDia: horaDia ?? this.horaDia,
      nombreColaborador: nombreColaborador ?? this.nombreColaborador,
      apellidoPaternoColaborador: apellidoPaternoColaborador ?? this.apellidoPaternoColaborador,
      apellidoMaternoColaborador: apellidoMaternoColaborador ?? this.apellidoMaternoColaborador,
    );
  }
}
