import 'dart:convert';
import 'package:flutter/material.dart';

class HorasExtrasOtrosCecos {
  final String id;
  final String idColaborador;
  final DateTime fecha;
  final int idCecoTipo;
  final int idCeco;
  final double cantidad;
  final String nombreColaborador;
  final String nombreCecoTipo;
  final String nombreCeco;

  HorasExtrasOtrosCecos({
    required this.id,
    required this.idColaborador,
    required this.fecha,
    required this.idCecoTipo,
    required this.idCeco,
    required this.cantidad,
    required this.nombreColaborador,
    required this.nombreCecoTipo,
    required this.nombreCeco,
  });

  factory HorasExtrasOtrosCecos.fromJson(Map<String, dynamic> json) {
    print('🔍 DEBUG: Parseando JSON: $json');
    return HorasExtrasOtrosCecos(
      id: json['id'] ?? '',
      idColaborador: json['id_colaborador'] ?? '',
      fecha: _parseFecha(json['fecha']),
      idCecoTipo: json['id_cecotipo'] ?? 0,
      idCeco: json['id_ceco'] ?? 0,
      cantidad: _toDouble(json['cantidad']),
      nombreColaborador: json['nombre_colaborador'] ?? '',
      nombreCecoTipo: json['nombre_cecotipo'] ?? '',
      nombreCeco: json['nombre_ceco'] ?? '',
    );
  }

  static DateTime _parseFecha(dynamic fecha) {
    print('🔍 DEBUG: Parseando fecha: $fecha (tipo: ${fecha.runtimeType})');
    if (fecha == null) return DateTime.now();
    if (fecha is DateTime) return fecha;
    if (fecha is String) {
      try {
        // Intentar parsear formato ISO
        final parsed = DateTime.parse(fecha);
        print('🔍 DEBUG: Fecha parseada exitosamente: $parsed');
        return parsed;
      } catch (e) {
        print('🔍 DEBUG: Error parseando fecha ISO: $e');
        try {
          // Intentar parsear formato GMT específico: "Mon, 08 Sep 2025 00:00:00 GMT"
          if (fecha.contains('GMT')) {
            // Formato: "Mon, 08 Sep 2025 00:00:00 GMT"
            // Extraer solo la parte de fecha y hora: "08 Sep 2025 00:00:00"
            final parts = fecha.split(', ');
            if (parts.length >= 2) {
              final dateTimePart = parts[1].replaceAll('GMT', '').trim();
              // Convertir formato "08 Sep 2025 00:00:00" a formato parseable
              final dateTimeParts = dateTimePart.split(' ');
              if (dateTimeParts.length >= 4) {
                final day = dateTimeParts[0];
                final month = _convertMonthName(dateTimeParts[1]);
                final year = dateTimeParts[2];
                final time = dateTimeParts[3];
                
                // Crear fecha en formato ISO
                final isoString = '$year-$month-$day $time';
                final parsed = DateTime.parse(isoString);
                print('🔍 DEBUG: Fecha GMT parseada exitosamente: $parsed');
                return parsed;
              }
            }
          }
          // Intentar parsear formato DD/MM/YYYY
          final parts = fecha.split('/');
          if (parts.length == 3) {
            final parsed = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
            print('🔍 DEBUG: Fecha DD/MM/YYYY parseada exitosamente: $parsed');
            return parsed;
          }
        } catch (e) {
          print('🔍 DEBUG: Error parsing fecha: $fecha, error: $e');
          return DateTime.now();
        }
      }
    }
    return DateTime.now();
  }

  static String _convertMonthName(String monthName) {
    const monthMap = {
      'Jan': '01', 'Feb': '02', 'Mar': '03', 'Apr': '04',
      'May': '05', 'Jun': '06', 'Jul': '07', 'Aug': '08',
      'Sep': '09', 'Oct': '10', 'Nov': '11', 'Dec': '12'
    };
    final result = monthMap[monthName] ?? '01';
    print('🔍 DEBUG: Convirtiendo mes: $monthName -> $result');
    return result;
  }

  static double _toDouble(dynamic value) {
    print('🔍 DEBUG: Parseando cantidad: $value (tipo: ${value.runtimeType})');
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value) ?? 0.0;
      print('🔍 DEBUG: Cantidad parseada: $parsed');
      return parsed;
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_colaborador': idColaborador,
      'fecha': fecha.toIso8601String().split('T')[0],
      'id_cecotipo': idCecoTipo,
      'id_ceco': idCeco,
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
    final meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${fecha.day} de ${meses[fecha.month - 1]} de ${fecha.year}';
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

// Modelo para opciones de formularios
class CecoTipo {
  final int id;
  final String nombre;

  CecoTipo({
    required this.id,
    required this.nombre,
  });

  factory CecoTipo.fromJson(Map<String, dynamic> json) {
    return CecoTipo(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
    );
  }
}

class Ceco {
  final int id;
  final String nombre;
  final int idCecoTipo;
  final int idSucursal;
  final int idEstado;

  Ceco({
    required this.id,
    required this.nombre,
    required this.idCecoTipo,
    required this.idSucursal,
    required this.idEstado,
  });

  factory Ceco.fromJson(Map<String, dynamic> json) {
    return Ceco(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      idCecoTipo: json['id_cecotipo'] ?? 0,
      idSucursal: json['id_sucursal'] ?? 0,
      idEstado: json['id_estado'] ?? 0,
    );
  }
}
