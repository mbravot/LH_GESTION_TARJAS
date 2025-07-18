import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import '../models/tarja.dart';
import 'auth_service.dart';

class TarjaService {
  static const String baseUrl = 'http://192.168.1.60:5000/api';
  static final AuthService _authService = AuthService();

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
          
          // Log para verificar los datos de la primera actividad
          if (jsonList.isNotEmpty) {
            developer.log('Primera actividad - nombre_unidad: ${jsonList[0]['nombre_unidad']}');
            developer.log('Primera actividad - id_unidad: ${jsonList[0]['id_unidad']}');
            developer.log('Primera actividad - nombre_usuario: ${jsonList[0]['nombre_usuario']}');
            developer.log('Primera actividad - labor: ${jsonList[0]['labor']}');
          }

          // Mapeo directo usando el modelo actualizado
          return jsonList.map((json) => Tarja.fromJson(json)).toList();
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

  //Cambiar solo el estado de una actividad
  Future<void> cambiarEstadoActividad(String id, String nuevoEstado) async {
    try {
      developer.log('Iniciando cambio de estado de actividad: $id');
      developer.log('Nuevo estado: $nuevoEstado');
      
      final token = await _authService.getToken();
      if (token == null) throw Exception('No autorizado');

      final url = '$baseUrl/actividades/$id/estado';
      developer.log('URL de cambio de estado: $url');

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'id_estadoactividad': nuevoEstado}),
      );

      developer.log('Respuesta de cambio de estado - Status: ${response.statusCode}');
      developer.log('Respuesta de cambio de estado - Body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Error al cambiar el estado de la actividad: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log('Error al cambiar estado de actividad: $e', error: e);
      throw Exception('Error al cambiar el estado de la actividad: $e');
    }
  }

  static Future<Map<String, dynamic>> _getOpciones() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No hay token de autenticación');
    final response = await http.get(
      Uri.parse('$baseUrl/opciones/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    print('Respuesta opciones status:  {response.statusCode}');
    print('Respuesta opciones body:  {response.body}');
    print('Token enviado: Bearer $token');
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Error al obtener opciones: ${response.statusCode}');
    }
  }

  static Future<List<Map<String, dynamic>>> getLabores() async {
    final opciones = await _getOpciones();
    final labores = opciones['labores'] as List<dynamic>? ?? [];
    return labores.cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> getUnidades() async {
    final opciones = await _getOpciones();
    final unidades = opciones['unidades'] as List<dynamic>? ?? [];
    return unidades.cast<Map<String, dynamic>>();
  }

  // Determinar el tipo de actividad basado en los campos de la tarja
  static String _determinarTipoActividad({
    required String idTipotrabajador,
    required String idTiporendimiento,
    String? idContratista,
  }) {
    // Si es grupal
    if (idTiporendimiento == '2') {
      return 'grupal';
    }
    // Si es individual propio
    if (idTiporendimiento == '1' && idTipotrabajador == '1') {
      return 'propio';
    }
    // Si es individual contratista
    if (idTiporendimiento == '1' && idTipotrabajador == '2') {
      return 'contratista';
    }
    // Por defecto, propio
    return 'propio';
  }

  // Obtener rendimientos según el tipo de actividad
  static Future<List<Map<String, dynamic>>> obtenerRendimientos(String actividadId, {
    required String idTipotrabajador,
    required String idTiporendimiento,
    String? idContratista,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('No se pudo obtener el token de autenticación');
    }

    final tipoActividad = _determinarTipoActividad(
      idTipotrabajador: idTipotrabajador,
      idTiporendimiento: idTiporendimiento,
      idContratista: idContratista,
    );

    String endpoint;
    Map<String, String> headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    switch (tipoActividad) {
      case 'propio':
        endpoint = '$baseUrl/rendimientopropio/actividad/$actividadId';
        break;
      case 'contratista':
        endpoint = '$baseUrl/rendimientos/individual/contratista?id_actividad=$actividadId';
        break;
      case 'grupal':
        endpoint = '$baseUrl/rendimientos/$actividadId';
        break;
      default:
        throw Exception('Tipo de actividad no reconocido');
    }

    developer.log('🔍 Obteniendo rendimientos para actividad: $actividadId');
    developer.log('🔍 Tipo de actividad: $tipoActividad');
    developer.log('🔍 Endpoint: $endpoint');

    try {
      final response = await http.get(
        Uri.parse(endpoint),
        headers: headers,
      );

      developer.log('📡 Respuesta recibida - Status: ${response.statusCode}');
      developer.log('📡 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        developer.log('📊 Datos decodificados: $data');
        
        List<Map<String, dynamic>> result = [];
        
        // Manejar diferentes estructuras de respuesta según el tipo
        if (data is List) {
          // Para rendimientos individuales de contratista, la labor está en nombre_actividad
          result = data.map((item) {
            final rendimiento = Map<String, dynamic>.from(item);
            if (rendimiento['nombre_actividad'] != null && rendimiento['labor'] == null) {
              rendimiento['labor'] = rendimiento['nombre_actividad'];
            }
            return rendimiento;
          }).toList();
        } else if (data is Map && data.containsKey('rendimientos')) {
          final rendimientos = data['rendimientos'] as List;
          final actividad = data['actividad'] as Map<String, dynamic>?;
          
          // Para rendimientos individuales, extraer labor de actividad y agregarla a cada rendimiento
          result = rendimientos.map((item) {
            final rendimiento = Map<String, dynamic>.from(item);
            if (actividad != null && actividad['labor'] != null) {
              rendimiento['labor'] = actividad['labor'];
            }
            return rendimiento;
          }).toList();
        } else if (data is Map) {
          result = [Map<String, dynamic>.from(data)];
        } else {
          result = [];
        }

        developer.log('📋 Resultado final: $result');
        
        // Log detallado de cada rendimiento
        for (int i = 0; i < result.length; i++) {
          final r = result[i];
          developer.log('📋 Rendimiento $i:');
          developer.log('   - Keys disponibles: ${r.keys.toList()}');
          developer.log('   - Labor: ${r['labor']}');
          developer.log('   - Nombre colaborador: ${r['nombre_colaborador']}');
          developer.log('   - Nombre trabajador: ${r['nombre_trabajador']}');
          developer.log('   - Nombre actividad: ${r['nombre_actividad']}');
          developer.log('   - Horas trabajadas: ${r['horas_trabajadas']}');
          developer.log('   - Rendimiento: ${r['rendimiento']}');
          developer.log('   - Porcentaje: ${r['porcentaje']}');
        }

        return result;
      } else {
        throw Exception('Error al obtener rendimientos: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('❌ Error en obtenerRendimientos: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener información específica del tipo de rendimiento
  static Map<String, String> obtenerCamposRendimiento(String tipoActividad) {
    switch (tipoActividad) {
      case 'propio':
        return {
          'titulo': 'Rendimientos Individuales Propios',
          'campo1': 'Colaborador',
          'campo2': 'Cantidad',
          'campo3': 'Bonos',
          'campo4': 'Total',
        };
      case 'contratista':
        return {
          'titulo': 'Rendimientos Individuales de Contratistas',
          'campo1': 'Trabajador',
          'campo2': 'Cantidad',
          'campo3': 'Porcentaje',
          'campo4': 'Total',
        };
      case 'grupal':
        return {
          'titulo': 'Rendimientos Grupales',
          'campo1': 'Equipo',
          'campo2': 'Cantidad',
          'campo3': 'Participantes',
          'campo4': 'Total',
        };
      default:
        return {
          'titulo': 'Rendimientos',
          'campo1': 'Campo 1',
          'campo2': 'Campo 2',
          'campo3': 'Campo 3',
          'campo4': 'Total',
        };
    }
  }

  // Obtener todos los permisos del usuario actual
  static Future<List<Map<String, dynamic>>> obtenerPermisosUsuario() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('No hay token de autenticación');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/permisos/usuario/actual'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final permisos = data.map((item) => Map<String, dynamic>.from(item)).toList();
      print('🔍 Permisos recibidos del backend:');
      for (var permiso in permisos) {
        print('   - ID: ${permiso['id']} (${permiso['id'].runtimeType}), Nombre: ${permiso['nombre']}');
      }
      return permisos;
    } else {
      throw Exception('Error al obtener permisos: ${response.statusCode}');
    }
  }

  // Verificar si el usuario tiene un permiso específico
  static Future<bool> verificarPermiso(String nombrePermiso) async {
    final token = await _authService.getToken();
    if (token == null) {
      return false;
    }

    final response = await http.get(
      Uri.parse('$baseUrl/permisos/usuario/verificar/$nombrePermiso'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['tiene_permiso'] ?? false;
    } else {
      return false;
    }
  }

  // Verificar múltiples permisos de una vez
  static Future<Map<String, bool>> verificarMultiplesPermisos(List<String> permisos) async {
    final token = await _authService.getToken();
    if (token == null) {
      return {for (var permiso in permisos) permiso: false};
    }

    final response = await http.post(
      Uri.parse('$baseUrl/permisos/usuario/verificar-multiples'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'permisos': permisos}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      Map<String, bool> resultado = {};
      for (var permiso in permisos) {
        resultado[permiso] = data[permiso]?['tiene_permiso'] ?? false;
      }
      return resultado;
    } else {
      return {for (var permiso in permisos) permiso: false};
    }
  }

  // Verificar si el usuario tiene un permiso por ID
  static Future<bool> verificarPermisoPorId(int idPermiso) async {
    final permisos = await obtenerPermisosUsuario();
    return permisos.any((permiso) => permiso['id'] == idPermiso);
  }

  // Obtener roles del usuario
  static Future<Map<String, dynamic>> obtenerRolesUsuario() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('No hay token de autenticación');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/permisos/usuario/roles'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener roles: ${response.statusCode}');
    }
  }
} 