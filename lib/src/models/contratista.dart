import 'package:flutter/material.dart';

class Contratista {
  final String id;
  final String rut;
  final String nombre;
  final String apellidoPaterno;
  final String apellidoMaterno;
  final String? email;
  final String? telefono;
  final String? direccion;
  final DateTime? fechaNacimiento;
  final DateTime? fechaIncorporacion;
  final String estado;
  final String? observaciones;
  final DateTime timestamp;

  Contratista({
    required this.id,
    required this.rut,
    required this.nombre,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    this.email,
    this.telefono,
    this.direccion,
    this.fechaNacimiento,
    this.fechaIncorporacion,
    required this.estado,
    this.observaciones,
    required this.timestamp,
  });

  factory Contratista.fromJson(Map<String, dynamic> json) {
    try {
      return Contratista(
        id: json['id']?.toString() ?? '',
        rut: json['rut']?.toString() ?? '',
        nombre: json['nombre']?.toString() ?? '',
        apellidoPaterno: json['apellido_paterno']?.toString() ?? '',
        apellidoMaterno: json['apellido_materno']?.toString() ?? '',
        email: json['email']?.toString(),
        telefono: json['telefono']?.toString(),
        direccion: json['direccion']?.toString(),
        fechaNacimiento: _parseFecha(json['fecha_nacimiento']),
        fechaIncorporacion: _parseFecha(json['fecha_incorporacion']),
        estado: _getEstadoFromId(json['id_estado']),
        observaciones: json['observaciones']?.toString(),
        timestamp: _parseFecha(json['timestamp']) ?? DateTime.now(),
      );
    } catch (e) {
      print('❌ Error al parsear contratista: $e');
      print('📄 JSON problemático: $json');
      rethrow;
    }
  }

  static String _getEstadoFromId(dynamic idEstado) {
    if (idEstado == null) return 'ACTIVO';
    switch (idEstado.toString()) {
      case '1':
        return 'ACTIVO';
      case '2':
        return 'INACTIVO';
      case '3':
        return 'SUSPENDIDO';
      default:
        return 'ACTIVO';
    }
  }

  static DateTime? _parseFecha(dynamic fecha) {
    if (fecha == null) return null;
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
          return null;
        }
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rut': rut,
      'nombre': nombre,
      'apellido_paterno': apellidoPaterno,
      'apellido_materno': apellidoMaterno,
      'email': email,
      'telefono': telefono,
      'direccion': direccion,
      'fecha_nacimiento': fechaNacimiento?.toIso8601String().split('T')[0],
      'fecha_incorporacion': fechaIncorporacion?.toIso8601String().split('T')[0],
      'id_estado': _getEstadoId(estado),
      'observaciones': observaciones,
    };
  }

  static int _getEstadoId(String estado) {
    switch (estado.toUpperCase()) {
      case 'ACTIVO':
        return 1;
      case 'INACTIVO':
        return 2;
      case 'SUSPENDIDO':
        return 3;
      default:
        return 1;
    }
  }

  // Getters para nombre completo
  String get nombreCompleto {
    return '$nombre $apellidoPaterno $apellidoMaterno'.trim();
  }

  String get nombreCorto {
    return '$nombre $apellidoPaterno'.trim();
  }

  // Getters para formato de fecha
  String get fechaNacimientoFormateada {
    if (fechaNacimiento == null) return 'No especificada';
    final meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${fechaNacimiento!.day} de ${meses[fechaNacimiento!.month - 1]} de ${fechaNacimiento!.year}';
  }

  String get fechaNacimientoFormateadaEspanol {
    if (fechaNacimiento == null) return 'No especificada';
    final meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${fechaNacimiento!.day} de ${meses[fechaNacimiento!.month - 1]} de ${fechaNacimiento!.year}';
  }

  String get fechaIncorporacionFormateada {
    if (fechaIncorporacion == null) return 'No especificada';
    final meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${fechaIncorporacion!.day} de ${meses[fechaIncorporacion!.month - 1]} de ${fechaIncorporacion!.year}';
  }

  String get fechaIncorporacionFormateadaEspanol {
    if (fechaIncorporacion == null) return 'No especificada';
    final meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${fechaIncorporacion!.day} de ${meses[fechaIncorporacion!.month - 1]} de ${fechaIncorporacion!.year}';
  }

  String get timestampFormateadoEspanol {
    final meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${timestamp.day} de ${meses[timestamp.month - 1]} de ${timestamp.year}';
  }

  // Getters para estado y validaciones
  bool get esActivo => estado.toUpperCase() == 'ACTIVO';
  bool get esInactivo => estado.toUpperCase() == 'INACTIVO';

  // Getters para colores y estados
  Color get estadoColor {
    switch (estado.toUpperCase()) {
      case 'ACTIVO':
        return Colors.green;
      case 'INACTIVO':
        return Colors.red;
      case 'SUSPENDIDO':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData get estadoIcono {
    switch (estado.toUpperCase()) {
      case 'ACTIVO':
        return Icons.check_circle;
      case 'INACTIVO':
        return Icons.cancel;
      case 'SUSPENDIDO':
        return Icons.pause_circle;
      default:
        return Icons.help;
    }
  }

  String get estadoTexto {
    switch (estado.toUpperCase()) {
      case 'ACTIVO':
        return 'Activo';
      case 'INACTIVO':
        return 'Inactivo';
      case 'SUSPENDIDO':
        return 'Suspendido';
      default:
        return 'Desconocido';
    }
  }

  // Getters para información de contacto
  String get informacionContacto {
    final contactos = <String>[];
    if (email != null && email!.isNotEmpty) contactos.add(email!);
    if (telefono != null && telefono!.isNotEmpty) contactos.add(telefono!);
    return contactos.isEmpty ? 'Sin información de contacto' : contactos.join(' • ');
  }

  // Getters para validaciones
  bool get tieneEmail => email != null && email!.isNotEmpty;
  bool get tieneTelefono => telefono != null && telefono!.isNotEmpty;
  bool get tieneDireccion => direccion != null && direccion!.isNotEmpty;
  bool get tieneFechaNacimiento => fechaNacimiento != null;
  bool get tieneFechaIncorporacion => fechaIncorporacion != null;
}
