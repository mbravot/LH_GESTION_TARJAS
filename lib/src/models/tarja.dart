class Tarja {
  final String id;
  final String fecha;
  final String idEstadoactividad;
  final String idLabor;
  final String idUnidad;
  final String? nombreUnidad;
  final String idTipotrabajador;
  final String idTiporendimiento;
  final String? idContratista;
  final String idSucursalactiva;
  final String idTipoceco;
  final String horaInicio;
  final String horaFin;
  final String tarifa;
  final String labor;
  final String? contratista;
  final String tipoRend;
  final String? nombreTipoceco;
  final String? nombreCeco;
  final String? nombreUsuario;
  final bool tieneRendimiento;
  
  // Campos adicionales para compatibilidad
  final String actividad; // Alias para labor
  final String trabajador; // Alias para contratista
  final String lugar; // Alias para idUnidad
  final String tipo; // Alias para tipoRend
  final String estado; // Alias para idEstadoactividad
  final String supervisor; // Campo para compatibilidad
  final String horasTrab; // Campo para compatibilidad
  final String oc; // Campo para compatibilidad

  Tarja({
    required this.id,
    required this.fecha,
    required this.idEstadoactividad,
    required this.idLabor,
    required this.idUnidad,
    this.nombreUnidad,
    required this.idTipotrabajador,
    required this.idTiporendimiento,
    this.idContratista,
    required this.idSucursalactiva,
    required this.idTipoceco,
    required this.horaInicio,
    required this.horaFin,
    required this.tarifa,
    required this.labor,
    this.contratista,
    required this.tipoRend,
    this.nombreTipoceco,
    this.nombreCeco,
    this.nombreUsuario,
    required this.tieneRendimiento,
    required this.actividad,
    required this.trabajador,
    required this.lugar,
    required this.tipo,
    required this.estado,
    required this.supervisor,
    required this.horasTrab,
    required this.oc,
  });

  factory Tarja.fromJson(Map<String, dynamic> json) {
    return Tarja(
      // Campos principales del backend
      id: json['id']?.toString() ?? '',
      fecha: json['fecha']?.toString() ?? '',
      idEstadoactividad: json['id_estadoactividad']?.toString() ?? '',
      idLabor: json['id_labor']?.toString() ?? '',
      idUnidad: json['id_unidad']?.toString() ?? '',
      nombreUnidad: json['nombre_unidad'],
      idTipotrabajador: json['id_tipotrabajador']?.toString() ?? '',
      idTiporendimiento: json['id_tiporendimiento']?.toString() ?? '',
      idContratista: json['id_contratista']?.toString(),
      idSucursalactiva: json['id_sucursalactiva']?.toString() ?? '',
      idTipoceco: json['id_tipoceco']?.toString() ?? '',
      horaInicio: json['hora_inicio']?.toString() ?? '',
      horaFin: json['hora_fin']?.toString() ?? '',
      tarifa: json['tarifa']?.toString() ?? '0',
      labor: json['labor'] ?? '',
      contratista: json['contratista'],
      tipoRend: json['tipo_rend'] ?? '',
      nombreTipoceco: json['nombre_tipoceco'],
      nombreCeco: json['nombre_ceco'],
      nombreUsuario: json['nombre_usuario'] ?? json['nombre_completo'],
      tieneRendimiento: json['tiene_rendimiento'] == 1 || json['tiene_rendimiento'] == true,
      
      // Campos de compatibilidad (aliases)
      actividad: json['labor'] ?? '',
      trabajador: json['contratista'] ?? '',
      lugar: json['id_unidad']?.toString() ?? '',
      tipo: json['tipo_rend'] ?? '',
      estado: json['id_estadoactividad']?.toString() ?? '',
      supervisor: '', // No viene en el endpoint actual
      horasTrab: '', // No viene en el endpoint actual
      oc: '0', // No viene en el endpoint actual
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fecha': fecha,
      'id_estadoactividad': idEstadoactividad,
      'id_labor': idLabor,
      'id_unidad': idUnidad,
      'nombre_unidad': nombreUnidad,
      'id_tipotrabajador': idTipotrabajador,
      'id_tiporendimiento': idTiporendimiento,
      'id_contratista': idContratista,
      'id_sucursalactiva': idSucursalactiva,
      'id_tipoceco': idTipoceco,
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
      'tarifa': tarifa,
      'labor': labor,
      'contratista': contratista,
      'tipo_rend': tipoRend,
      'nombre_tipoceco': nombreTipoceco,
      'nombre_ceco': nombreCeco,
      'nombre_usuario': nombreUsuario,
      'tiene_rendimiento': tieneRendimiento,
    };
  }
} 