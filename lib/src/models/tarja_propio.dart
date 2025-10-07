class TarjaPropio {
  final int idSucursal;
  final String fecha;
  final String idUsuario;
  final String usuario;
  final String idColaborador;
  final String colaborador;
  final int idLabor;
  final String labor;
  final int idTipoRendimiento;
  final String tipoRendimiento;
  final int idCeco;
  final String centroDeCosto;
  final String detalleCeco;
  final String horasTrabajadas;
  final int idUnidad;
  final String unidad;
  final double rendimiento;
  final double tarifa;
  final double liquidoTratoDia;
  final double horasExtras;
  final double valorHe;
  final double totalHe;
  final int idEstadoActividad;
  final String estado;

  TarjaPropio({
    required this.idSucursal,
    required this.fecha,
    required this.idUsuario,
    required this.usuario,
    required this.idColaborador,
    required this.colaborador,
    required this.idLabor,
    required this.labor,
    required this.idTipoRendimiento,
    required this.tipoRendimiento,
    required this.idCeco,
    required this.centroDeCosto,
    required this.detalleCeco,
    required this.horasTrabajadas,
    required this.idUnidad,
    required this.unidad,
    required this.rendimiento,
    required this.tarifa,
    required this.liquidoTratoDia,
    required this.horasExtras,
    required this.valorHe,
    required this.totalHe,
    required this.idEstadoActividad,
    required this.estado,
  });

  factory TarjaPropio.fromJson(Map<String, dynamic> json) {
    return TarjaPropio(
      idSucursal: _parseInt(json['id_sucursal']),
      fecha: json['fecha']?.toString() ?? '',
      idUsuario: json['id_usuario']?.toString() ?? '',
      usuario: json['usuario']?.toString() ?? '',
      idColaborador: json['id_colaborador']?.toString() ?? '',
      colaborador: json['colaborador']?.toString() ?? '',
      idLabor: _parseInt(json['id_labor']),
      labor: json['labor']?.toString() ?? '',
      idTipoRendimiento: _parseInt(json['id_tiporendimiento']),
      tipoRendimiento: json['tipo_renimiento']?.toString() ?? '',
      idCeco: _parseInt(json['id_ceco']),
      centroDeCosto: json['centro_de_costo']?.toString() ?? '',
      detalleCeco: json['detalle_ceco']?.toString() ?? '',
      horasTrabajadas: json['horas_trabajadas']?.toString() ?? '',
      idUnidad: _parseInt(json['id_unidad']),
      unidad: json['unidad']?.toString() ?? '',
      rendimiento: _parseDouble(json['rendimiento']),
      tarifa: _parseDouble(json['tarifa']),
      liquidoTratoDia: _parseDouble(json['liquido_trato_dia']),
      horasExtras: _parseDouble(json['horas_extras']),
      valorHe: _parseDouble(json['valor_he']),
      totalHe: _parseDouble(json['total_HE']),
      idEstadoActividad: _parseInt(json['id_estadoactividad']),
      estado: json['estado']?.toString() ?? '',
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // Método para formatear fecha en formato chileno
  String get fechaFormateadaChilena {
    final fechaParseada = parseFecha(fecha);
    if (fechaParseada != null) {
      return '${fechaParseada.day.toString().padLeft(2, '0')}/${fechaParseada.month.toString().padLeft(2, '0')}/${fechaParseada.year}';
    }
    return fecha;
  }

  // Método para parsear fechas GMT
  static DateTime? parseFecha(String? fechaStr) {
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
      } catch (e2) {
        // Si también falla, devolver null
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id_sucursal': idSucursal,
      'fecha': fecha,
      'id_usuario': idUsuario,
      'usuario': usuario,
      'id_colaborador': idColaborador,
      'colaborador': colaborador,
      'id_labor': idLabor,
      'labor': labor,
      'id_tiporendimiento': idTipoRendimiento,
      'tipo_renimiento': tipoRendimiento,
      'id_ceco': idCeco,
      'centro_de_costo': centroDeCosto,
      'detalle_ceco': detalleCeco,
      'horas_trabajadas': horasTrabajadas,
      'id_unidad': idUnidad,
      'unidad': unidad,
      'rendimiento': rendimiento,
      'tarifa': tarifa,
      'liquido_trato_dia': liquidoTratoDia,
      'horas_extras': horasExtras,
      'valor_he': valorHe,
      'total_HE': totalHe,
      'id_estadoactividad': idEstadoActividad,
      'estado': estado,
    };
  }
}

class TarjaPropioResumen {
  final String idColaborador;
  final String colaborador;
  final int totalRegistros;
  final String totalHorasTrabajadas;
  final double totalRendimiento;
  final double totalHorasExtras;
  final double totalValorHe;
  final double totalLiquidoTratoDia;
  final double promedioRendimiento;

  TarjaPropioResumen({
    required this.idColaborador,
    required this.colaborador,
    required this.totalRegistros,
    required this.totalHorasTrabajadas,
    required this.totalRendimiento,
    required this.totalHorasExtras,
    required this.totalValorHe,
    required this.totalLiquidoTratoDia,
    required this.promedioRendimiento,
  });

  factory TarjaPropioResumen.fromJson(Map<String, dynamic> json) {
    return TarjaPropioResumen(
      idColaborador: json['id_colaborador']?.toString() ?? '',
      colaborador: json['colaborador']?.toString() ?? '',
      totalRegistros: TarjaPropio._parseInt(json['total_registros']),
      totalHorasTrabajadas: json['total_horas_trabajadas']?.toString() ?? '',
      totalRendimiento: TarjaPropio._parseDouble(json['total_rendimiento']),
      totalHorasExtras: TarjaPropio._parseDouble(json['total_horas_extras']),
      totalValorHe: TarjaPropio._parseDouble(json['total_valor_he']),
      totalLiquidoTratoDia: TarjaPropio._parseDouble(json['total_liquido_trato_dia']),
      promedioRendimiento: TarjaPropio._parseDouble(json['promedio_rendimiento']),
    );
  }
}
