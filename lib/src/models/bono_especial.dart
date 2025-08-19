import 'dart:convert';
import 'package:flutter/material.dart';

class BonoEspecial {
  final String id;
  final String idColaborador;
  final DateTime fecha;
  final double cantidad;
  final String nombreColaborador;

  BonoEspecial({
    required this.id,
    required this.idColaborador,
    required this.fecha,
    required this.cantidad,
    required this.nombreColaborador,
  });

  factory BonoEspecial.fromJson(Map<String, dynamic> json) {
    return BonoEspecial(
      id: json['id'] ?? '',
      idColaborador: json['id_colaborador'] ?? '',
      fecha: _parseFecha(json['fecha']),
      cantidad: _toDouble(json['cantidad']),
      nombreColaborador: json['nombre_colaborador'] ?? '',
    );
  }

  static DateTime _parseFecha(dynamic fecha) {
    if (fecha == null) return DateTime.now();
    if (fecha is DateTime) return fecha;
    if (fecha is String) {
      try {
        // Intentar parsear formato ISO
        return DateTime.parse(fecha);
      } catch (e) {
        try {
          // Intentar parsear formato GMT
          if (fecha.contains('GMT')) {
            final cleanFecha = fecha.replaceAll('GMT', '').trim();
            return DateTime.parse(cleanFecha);
          }
          // Intentar parsear formato DD/MM/YYYY
          final parts = fecha.split('/');
          if (parts.length == 3) {
            return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
          }
        } catch (e) {
          return DateTime.now();
        }
      }
    }
    return DateTime.now();
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_colaborador': idColaborador,
      'fecha': fecha.toIso8601String().split('T')[0],
      'cantidad': cantidad,
    };
  }

  // Getters para formato de fecha
  String get fechaFormateadaEspanol {
    final meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${fecha.day} de ${meses[fecha.month - 1]} de ${fecha.year}';
  }

  String get fechaFormateadaEspanolCompleta {
    final dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    final meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    final diaSemana = dias[(fecha.weekday - 1) % 7];
    return '$diaSemana, ${fecha.day} de ${meses[fecha.month - 1]} de ${fecha.year}';
  }

  String get fechaFormateadaCorta {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  // Getters para formato de cantidad
  String get cantidadFormateada {
    return '${cantidad.toStringAsFixed(1)}h';
  }

  // Getters para estado y validaciones
  bool get esFuturo => fecha.isAfter(DateTime.now());
  bool get esHoy => fecha.year == DateTime.now().year &&
                    fecha.month == DateTime.now().month &&
                    fecha.day == DateTime.now().day;
  bool get esPasado => fecha.isBefore(DateTime.now()) && !esHoy;

  // Getters para colores y estados
  String get estado {
    if (esFuturo) return 'FUTURO';
    if (esHoy) return 'HOY';
    return 'PASADO';
  }

  Color get estadoColor {
    switch (estado) {
      case 'FUTURO':
        return Colors.blue;
      case 'HOY':
        return Colors.green;
      case 'PASADO':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData get estadoIcono {
    switch (estado) {
      case 'FUTURO':
        return Icons.schedule;
      case 'HOY':
        return Icons.today;
      case 'PASADO':
        return Icons.history;
      default:
        return Icons.help;
    }
  }

  String get estadoTexto {
    switch (estado) {
      case 'FUTURO':
        return 'Futuro';
      case 'HOY':
        return 'Hoy';
      case 'PASADO':
        return 'Pasado';
      default:
        return 'Desconocido';
    }
  }
}

// Modelo para resumen por colaborador
class ResumenBonoEspecial {
  final String idColaborador;
  final String nombreColaborador;
  final int cantidadBonos;
  final double totalHorasSobrantes;
  final DateTime fechaInicio;
  final DateTime fechaFin;

  ResumenBonoEspecial({
    required this.idColaborador,
    required this.nombreColaborador,
    required this.cantidadBonos,
    required this.totalHorasSobrantes,
    required this.fechaInicio,
    required this.fechaFin,
  });

  factory ResumenBonoEspecial.fromJson(Map<String, dynamic> json) {
    return ResumenBonoEspecial(
      idColaborador: json['id_colaborador'] ?? '',
      nombreColaborador: json['nombre_colaborador'] ?? '',
      cantidadBonos: json['cantidad_bonos'] ?? 0,
      totalHorasSobrantes: _toDouble(json['total_horas_sobrantes']),
      fechaInicio: _parseFecha(json['fecha_inicio']),
      fechaFin: _parseFecha(json['fecha_fin']),
    );
  }

  static DateTime _parseFecha(dynamic fecha) {
    if (fecha == null) return DateTime.now();
    if (fecha is DateTime) return fecha;
    if (fecha is String) {
      try {
        return DateTime.parse(fecha);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  String get totalHorasSobrantesFormateada {
    return '${totalHorasSobrantes.toStringAsFixed(1)}h';
  }

  String get periodoFormateado {
    return '${fechaInicio.day.toString().padLeft(2, '0')}/${fechaInicio.month.toString().padLeft(2, '0')} - ${fechaFin.day.toString().padLeft(2, '0')}/${fechaFin.month.toString().padLeft(2, '0')}';
  }
}
