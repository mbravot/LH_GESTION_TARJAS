import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import '../models/tarja.dart';
import 'auth_service.dart';

class TarjaService {
  final String baseUrl = 'http://192.168.1.60:5000/api';
  final AuthService _authService = AuthService();

//Obtener las actividades de una fecha y una sucursal
  Future<List<Tarja>> getTarjasByDate(DateTime fecha, String idSucursal) async {
    try {
      developer.log('Iniciando obtención de actividades');
      developer.log('ID Sucursal: $idSucursal');
      
      final token = await _authService.getToken();
      developer.log('Token obtenido: [32m${token?.substring(0, 20)}...[0m');
      
      if (token == null) throw Exception('No autorizado');

      final url = '$baseUrl/actividades/sucursal/$idSucursal';
      developer.log('URL completa: $url');
      developer.log('Intentando conectar a: $url');

      try {
        developer.log('Realizando petición HTTP...');
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            developer.log('⚠️ Tiempo de espera agotado al intentar conectar a $url');
            throw Exception('Tiempo de espera agotado');
          },
        );

        developer.log('Respuesta recibida');
        developer.log('Código de estado: ${response.statusCode}');
        developer.log('Headers de respuesta: ${response.headers}');
        developer.log('Cuerpo de la respuesta: ${response.body}');

        if (response.statusCode == 200) {
          final List<dynamic> jsonList = json.decode(response.body);
          developer.log('Número de actividades recibidas: ${jsonList.length}');

          // Ya que el backend filtra por estado, no es necesario filtrar aquí
          // Pero si quieres filtrar por seguridad, usa el campo correcto:
          // final filteredList = jsonList.where((json) =>
          //   json['id_estadoactividad'] == 1 || json['id_estadoactividad'] == 2
          // ).toList();

          // Mapeo directo
          return jsonList.map((json) => Tarja.fromJson({
            '_id': json['id'],
            'actividad': json['labor'] ?? '',
            'trabajador': json['contratista'] ?? '',
            'lugar': '', // No hay campo ceco en el JSON
            'tipo': json['tipo_rend'] ?? '',
            'estado': json['id_estadoactividad']?.toString() ?? '',
            'supervisor': '',
            'fecha': json['fecha'],
            'hora_inicio': json['hora_inicio'],
            'hora_fin': json['hora_fin'],
            'horas_trab': '', // No hay campo horas_trab en el JSON
            'tarifa': json['tarifa']?.toString() ?? '0',
            'oc': '0', // No hay campo OC en el JSON
            'tiene_rendimiento': json['tiene_rendimiento'] == 1 || json['tiene_rendimiento'] == true,
          })).toList();
        } else {
          developer.log('❌ Error HTTP: ${response.statusCode}');
          developer.log('❌ Cuerpo del error: ${response.body}');
          throw Exception('Error al cargar las actividades: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        developer.log('❌ Error en la petición HTTP: $e');
        rethrow;
      }
    } catch (e) {
      developer.log('Error en getTarjasByDate: $e', error: e);
      throw Exception('Error al cargar las actividades: $e');
    }
  }

  //Aprobar una tarja
  Future<void> aprobarTarja(String id) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No autorizado');

      final response = await http.put(
        Uri.parse('$baseUrl/tarjas/$id/aprobar'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Error al aprobar la tarja: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al aprobar la tarja: $e');
    }
  }

  //Rechazar una tarja
  Future<void> rechazarTarja(String id, String motivo) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No autorizado');

      final response = await http.put(
        Uri.parse('$baseUrl/tarjas/$id/rechazar'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'motivo': motivo}),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al rechazar la tarja: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al rechazar la tarja: $e');
    }
  }

  //Actualizar una tarja
  Future<void> actualizarTarja(String id, Map<String, dynamic> datos) async {
    try {
      developer.log('Iniciando actualización de actividad: $id');
      developer.log('Datos a actualizar: $datos');
      
      final token = await _authService.getToken();
      if (token == null) throw Exception('No autorizado');

      final url = '$baseUrl/actividades/$id';
      developer.log('URL de actualización: $url');

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(datos),
      );

      developer.log('Respuesta de actualización - Status: ${response.statusCode}');
      developer.log('Respuesta de actualización - Body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Error al actualizar la actividad: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log('Error al actualizar actividad: $e', error: e);
      throw Exception('Error al actualizar la actividad: $e');
    }
  }
} 