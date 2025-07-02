class Tarja {
  final String id;
  final String actividad;
  final String trabajador;
  final String lugar;
  final String tipo;
  final String estado;
  final String supervisor;
  final String fecha;
  final String horaInicio;
  final String horaFin;
  final String horasTrab;
  final String tarifa;
  final String oc;
  final bool tieneRendimiento;

  Tarja({
    required this.id,
    required this.actividad,
    required this.trabajador,
    required this.lugar,
    required this.tipo,
    required this.estado,
    required this.supervisor,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.horasTrab,
    required this.tarifa,
    required this.oc,
    required this.tieneRendimiento,
  });

  factory Tarja.fromJson(Map<String, dynamic> json) {
    return Tarja(
      id: json['_id'] ?? '',
      actividad: json['actividad'] ?? '',
      trabajador: json['trabajador'] ?? '',
      lugar: json['lugar'] ?? '',
      tipo: json['tipo'] ?? '',
      estado: json['estado'] ?? '',
      supervisor: json['supervisor'] ?? '',
      fecha: json['fecha'] ?? '',
      horaInicio: json['hora_inicio'] ?? '',
      horaFin: json['hora_fin'] ?? '',
      horasTrab: json['horas_trab'] ?? '',
      tarifa: json['tarifa'] ?? '0',
      oc: json['oc'] ?? '0',
      tieneRendimiento: json['tiene_rendimiento'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'actividad': actividad,
      'trabajador': trabajador,
      'lugar': lugar,
      'tipo': tipo,
      'estado': estado,
      'supervisor': supervisor,
      'fecha': fecha,
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
      'horas_trab': horasTrab,
      'tarifa': tarifa,
      'oc': oc,
      'tiene_rendimiento': tieneRendimiento,
    };
  }
} 