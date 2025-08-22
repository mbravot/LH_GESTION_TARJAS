import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import '../models/tarja.dart';
import 'auth_service.dart';

class ApiService {
  static const String baseUrl = 'https://api-lh-gestion-tarjas-927498545444.us-central1.run.app/api';
  //static const String baseUrl = 'http://192.168.1.52:5000/api';
  
  // Método para verificar conectividad
  static Future<bool> verificarConectividad() async {
    try {
      // Intentar con el endpoint de licencias primero
      final response = await http.get(
        Uri.parse('$baseUrl/licencias'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200 || response.statusCode == 401; // 401 significa que el servidor responde pero necesita autenticación
    } catch (e) {
      // Intentar con una URL más simple
      try {
        final baseResponse = await http.get(
          Uri.parse('https://api-lh-gestion-tarjas-927498545444.us-central1.run.app/'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 5));
        return true;
      } catch (e2) {
        return false;
      }
    }
  }

  // Método para probar el endpoint de crear licencias
  static Future<bool> probarEndpointCrearLicencia() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return false;
      }

      final url = '$baseUrl/licencias';
      
      // Hacer una petición GET para verificar si el endpoint existe
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200 || response.statusCode == 401; // 401 significa que el servidor responde pero necesita autenticación
    } catch (e) {
      return false;
    }
  }
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

  // ===== MÉTODOS DE TRABAJADORES =====

  // Obtener trabajadores
  static Future<List<Map<String, dynamic>>> obtenerTrabajadores({
    String? idContratista,
    String? idSucursal,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final uri = Uri.parse('$baseUrl/trabajadores');
      final queryParams = <String, String>{};
      
      if (idContratista != null) {
        queryParams['id_contratista'] = idContratista;
      }
      if (idSucursal != null) {
        queryParams['id_sucursal'] = idSucursal;
      }

      final response = await http.get(
        uri.replace(queryParameters: queryParams.isNotEmpty ? queryParams : null),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al obtener trabajadores');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener un trabajador por ID
  static Future<Map<String, dynamic>> obtenerTrabajadorPorId(String trabajadorId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/trabajadores/$trabajadorId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body));
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al obtener trabajador');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Crear trabajador
  static Future<Map<String, dynamic>> crearTrabajador(Map<String, dynamic> trabajadorData) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/trabajadores/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(trabajadorData),
      );

      if (response.statusCode == 201) {
        return Map<String, dynamic>.from(json.decode(response.body));
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al crear trabajador');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Editar trabajador
  static Future<Map<String, dynamic>> editarTrabajador(
    String trabajadorId, 
    Map<String, dynamic> trabajadorData
  ) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/trabajadores/$trabajadorId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(trabajadorData),
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body));
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al editar trabajador');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }



  // ===== MÉTODOS DE COLABORADORES =====
  static Future<List<Map<String, dynamic>>> obtenerColaboradores() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/colaboradores'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al obtener colaboradores');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Crear colaborador
  static Future<Map<String, dynamic>> crearColaborador(Map<String, dynamic> colaboradorData) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/colaboradores/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(colaboradorData),
      );

      if (response.statusCode == 201) {
        return Map<String, dynamic>.from(json.decode(response.body));
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al crear colaborador');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener un colaborador por ID
  static Future<Map<String, dynamic>> obtenerColaboradorPorId(String colaboradorId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/colaboradores/$colaboradorId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body));
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al obtener colaborador');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Editar colaborador
  static Future<Map<String, dynamic>> editarColaborador(
    String colaboradorId, 
    Map<String, dynamic> colaboradorData
  ) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/colaboradores/$colaboradorId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(colaboradorData),
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body));
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al editar colaborador');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ===== MÉTODOS DE VACACIONES =====
  
  // Obtener todas las vacaciones
  static Future<List<Map<String, dynamic>>> obtenerVacaciones({String? idColaborador}) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      String url = '$baseUrl/vacaciones';
      if (idColaborador != null) {
        url += '?id_colaborador=$idColaborador';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al obtener vacaciones');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener una vacación por ID
  static Future<Map<String, dynamic>> obtenerVacacionPorId(String vacacionId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/vacaciones/$vacacionId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body));
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al obtener vacación');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Crear nueva vacación
  static Future<Map<String, dynamic>> crearVacacion(Map<String, dynamic> vacacionData) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/vacaciones/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(vacacionData),
      );

      if (response.statusCode == 201) {
        return Map<String, dynamic>.from(json.decode(response.body));
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al crear vacación');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Editar vacación
  static Future<Map<String, dynamic>> editarVacacion(
    String vacacionId, 
    Map<String, dynamic> vacacionData
  ) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/vacaciones/$vacacionId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(vacacionData),
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body));
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al editar vacación');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Eliminar vacación
  static Future<Map<String, dynamic>> eliminarVacacion(String vacacionId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/vacaciones/$vacacionId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body));
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al eliminar vacación');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener vacaciones de un colaborador específico
  static Future<List<Map<String, dynamic>>> obtenerVacacionesColaborador(String colaboradorId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/vacaciones/colaborador/$colaboradorId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al obtener vacaciones del colaborador');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ===== MÉTODOS DE LICENCIAS MÉDICAS =====
  
  // Obtener todas las licencias médicas
  static Future<List<Map<String, dynamic>>> obtenerLicencias({String? idColaborador}) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      String url = '$baseUrl/licencias';
      if (idColaborador != null) {
        url += '?id_colaborador=$idColaborador';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al obtener licencias médicas');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener una licencia médica por ID
  static Future<Map<String, dynamic>> obtenerLicenciaPorId(String licenciaId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/licencias/$licenciaId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body));
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al obtener licencia médica');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Crear nueva licencia médica
  static Future<Map<String, dynamic>> crearLicencia(Map<String, dynamic> licenciaData) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/licencias/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(licenciaData),
      );

      if (response.statusCode == 201) {
        return Map<String, dynamic>.from(json.decode(response.body));
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al crear licencia médica');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Editar licencia médica
  static Future<Map<String, dynamic>> editarLicencia(
    String licenciaId, 
    Map<String, dynamic> licenciaData
  ) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/licencias/$licenciaId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(licenciaData),
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body));
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al editar licencia médica');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Eliminar licencia médica
  static Future<Map<String, dynamic>> eliminarLicencia(String licenciaId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/licencias/$licenciaId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body));
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al eliminar licencia médica');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener licencias médicas de un colaborador específico
  static Future<List<Map<String, dynamic>>> obtenerLicenciasColaborador(String colaboradorId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/licencias/colaborador/$colaboradorId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al obtener licencias médicas del colaborador');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ===== MÉTODOS PARA FORMULARIOS =====
  
  // Obtener opciones para crear trabajador
  static Future<Map<String, dynamic>> obtenerOpcionesCrearTrabajador() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/trabajadores/opciones-crear'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body));
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al obtener opciones');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener opciones para editar trabajador
  static Future<Map<String, dynamic>> obtenerOpcionesEditarTrabajador(String trabajadorId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/trabajadores/opciones-editar/$trabajadorId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body));
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al obtener opciones');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener opciones para crear colaborador
  static Future<Map<String, dynamic>> obtenerOpcionesCrearColaborador() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/colaboradores/opciones-crear'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body));
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al obtener opciones');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener opciones para editar colaborador
  static Future<Map<String, dynamic>> obtenerOpcionesEditarColaborador(String colaboradorId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/colaboradores/opciones-editar/$colaboradorId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body));
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al obtener opciones');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }



  // Calcular dígito verificador usando la función existente
  static Future<String> calcularDigitoVerificador(String rut) async {
    try {
      // Usar la función local como fallback ya que el backend ya tiene validar_rut.py
      return _calcularDVLocal(rut);
    } catch (e) {
      throw Exception('Error al calcular DV: $e');
    }
  }

  // Calcular DV localmente usando el mismo algoritmo que validar_rut.py
  static String _calcularDVLocal(String rut) {
    if (rut.isEmpty || rut.length < 7 || rut.length > 8) {
      return '';
    }

    int suma = 0;
    int multiplicador = 2;

    // Calcular suma ponderada
    for (int i = rut.length - 1; i >= 0; i--) {
      suma += int.parse(rut[i]) * multiplicador;
      multiplicador++;
      if (multiplicador > 7) {
        multiplicador = 2;
      }
    }

    // Calcular dígito verificador
    int resto = suma % 11;
    int dv = 11 - resto;

    if (dv == 11) {
      return '0';
    } else if (dv == 10) {
      return 'K';
    } else {
      return dv.toString();
    }
  }

  // ===== MÉTODOS DE PERMISOS =====

  // Obtener permisos
  Future<List<Map<String, dynamic>>> obtenerPermisos() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/permisos-ausencia'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Map<String, dynamic>.from(json)).toList();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al obtener permisos');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Crear permiso
  Future<void> crearPermiso(Map<String, dynamic> datos) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/permisos-ausencia/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(datos),
      );

      if (response.statusCode != 201) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al crear permiso');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Editar permiso
  Future<void> editarPermiso(String permisoId, Map<String, dynamic> datos) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/permisos-ausencia/$permisoId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(datos),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al editar permiso');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Eliminar permiso
  Future<void> eliminarPermiso(String permisoId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/permisos-ausencia/$permisoId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al eliminar permiso');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener permiso por ID
  Future<Map<String, dynamic>> obtenerPermisoPorId(String permisoId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/permisos-ausencia/$permisoId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body));
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al obtener permiso');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener tipos de permiso
  Future<List<Map<String, dynamic>>> obtenerTiposPermiso() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/permisos-ausencia/tipos'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Map<String, dynamic>.from(json)).toList();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al obtener tipos de permiso');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener estados de permiso
  Future<List<Map<String, dynamic>>> obtenerEstadosPermiso() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/permisos-ausencia/estados'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Map<String, dynamic>.from(json)).toList();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al obtener estados de permiso');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ===== MÉTODOS DE HORAS TRABAJADAS =====

  // Obtener resumen de horas diarias por colaborador
  Future<List<Map<String, dynamic>>> obtenerResumenHorasDiarias({
    String? fechaInicio,
    String? fechaFin,
    String? idColaborador,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final uri = Uri.parse('$baseUrl/horas-trabajadas/resumen-diario-colaborador');
      final queryParams = <String, String>{};
      
      if (fechaInicio != null) {
        queryParams['fecha_inicio'] = fechaInicio;
      }
      if (fechaFin != null) {
        queryParams['fecha_fin'] = fechaFin;
      }
      if (idColaborador != null) {
        queryParams['id_colaborador'] = idColaborador;
      }

      final response = await http.get(
        uri.replace(queryParameters: queryParams.isNotEmpty ? queryParams : null),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Map<String, dynamic>.from(json)).toList();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al obtener resumen de horas');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ===== HORAS EXTRAS =====
  
  // Obtener rendimientos de horas extras
  Future<List<Map<String, dynamic>>> obtenerRendimientosHorasExtras({
    String? idColaborador,
    String? idActividad,
    String? fechaInicio,
    String? fechaFin,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/horas-extras/rendimientos');
      final queryParams = <String, String>{};
      
      if (idColaborador != null && idColaborador.isNotEmpty) {
        queryParams['id_colaborador'] = idColaborador;
      }
      if (idActividad != null && idActividad.isNotEmpty) {
        queryParams['id_actividad'] = idActividad;
      }
      if (fechaInicio != null && fechaInicio.isNotEmpty) {
        queryParams['fecha_inicio'] = fechaInicio;
      }
      if (fechaFin != null && fechaFin.isNotEmpty) {
        queryParams['fecha_fin'] = fechaFin;
      }

      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No se pudo obtener el token de autenticación');
      }

      final finalUri = queryParams.isNotEmpty 
          ? uri.replace(queryParameters: queryParams)
          : uri;

      final response = await http.get(
        finalUri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Error al obtener rendimientos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener rendimientos: $e');
    }
  }

  // Obtener rendimiento específico
  Future<Map<String, dynamic>> obtenerRendimientoHorasExtras(String rendimientoId) async {
    try {
      final uri = Uri.parse('$baseUrl/horas-extras/rendimientos/$rendimientoId');
      
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No se pudo obtener el token de autenticación');
      }

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener rendimiento: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener rendimiento: $e');
    }
  }

  // Asignar horas extras
  Future<Map<String, dynamic>> asignarHorasExtras(String rendimientoId, double horasExtras) async {
    try {
      final uri = Uri.parse('$baseUrl/horas-extras/rendimientos/$rendimientoId/horas-extras');
      
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No se pudo obtener el token de autenticación');
      }

      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'horas_extras': horasExtras}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al asignar horas extras: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al asignar horas extras: $e');
    }
  }

  // Obtener actividades por colaborador
  Future<List<Map<String, dynamic>>> obtenerActividadesColaborador(String idColaborador) async {
    try {
      final uri = Uri.parse('$baseUrl/horas-extras/actividades-colaborador/$idColaborador');
      
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No se pudo obtener el token de autenticación');
      }

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Error al obtener actividades: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener actividades: $e');
    }
  }

  // Crear nuevo rendimiento
  Future<Map<String, dynamic>> crearRendimientoHorasExtras({
    required String idActividad,
    required String idColaborador,
    required double rendimiento,
    required double horasTrabajadas,
    required double horasExtras,
    required int idBono,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/horas-extras/rendimientos');
      
      final body = {
        'id_actividad': idActividad,
        'id_colaborador': idColaborador,
        'rendimiento': rendimiento,
        'horas_trabajadas': horasTrabajadas,
        'horas_extras': horasExtras,
        'id_bono': idBono,
      };

      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No se pudo obtener el token de autenticación');
      }

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al crear rendimiento: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al crear rendimiento: $e');
    }
  }

  // Obtener bonos disponibles
  Future<List<Map<String, dynamic>>> obtenerBonos() async {
    try {
      final uri = Uri.parse('$baseUrl/horas-extras/bonos');
      
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No se pudo obtener el token de autenticación');
      }

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Error al obtener bonos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener bonos: $e');
    }
  }

  // ===== MÉTODOS PARA HORAS EXTRAS OTROS CECOs =====

  // Obtener horas extras otros CECOs
  static Future<List<Map<String, dynamic>>> obtenerHorasExtrasOtrosCecos({
    String? idColaborador,
    String? fechaInicio,
    String? fechaFin,
    int? idCecoTipo,
    int? idCeco,
  }) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No hay token de autenticación');

    final queryParams = <String, String>{};
    if (idColaborador != null) queryParams['id_colaborador'] = idColaborador;
    if (fechaInicio != null) queryParams['fecha_inicio'] = fechaInicio;
    if (fechaFin != null) queryParams['fecha_fin'] = fechaFin;
    if (idCecoTipo != null) queryParams['id_cecotipo'] = idCecoTipo.toString();
    if (idCeco != null) queryParams['id_ceco'] = idCeco.toString();

    final uri = Uri.parse('${ApiService.baseUrl}/horas-extras-otroscecos')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Error al obtener horas extras otros CECOs: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> obtenerHorasExtrasOtrosCecosPorId(String id) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No hay token de autenticación');

    final uri = Uri.parse('${ApiService.baseUrl}/horas-extras-otroscecos/$id');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener horas extras otros CECOs: ${response.statusCode}');
    }
  }

  static Future<void> crearHorasExtrasOtrosCecos(Map<String, dynamic> datos) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No hay token de autenticación');

    final uri = Uri.parse('${ApiService.baseUrl}/horas-extras-otroscecos/');

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(datos),
    );

    if (response.statusCode != 201) {
      throw Exception('Error al crear horas extras otros CECOs: ${response.statusCode}');
    }
  }

  static Future<void> editarHorasExtrasOtrosCecos(String id, Map<String, dynamic> datos) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No hay token de autenticación');

    final uri = Uri.parse('${ApiService.baseUrl}/horas-extras-otroscecos/$id');

    final response = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(datos),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al editar horas extras otros CECOs: ${response.statusCode}');
    }
  }

  static Future<void> eliminarHorasExtrasOtrosCecos(String id) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No hay token de autenticación');

    final uri = Uri.parse('${ApiService.baseUrl}/horas-extras-otroscecos/$id');

    final response = await http.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar horas extras otros CECOs: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> obtenerOpcionesHorasExtrasOtrosCecos() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No hay token de autenticación');

    final uri = Uri.parse('${ApiService.baseUrl}/horas-extras-otroscecos/opciones');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener opciones horas extras otros CECOs: ${response.statusCode}');
    }
  }

  // Métodos para Bono Especial
  static Future<List<Map<String, dynamic>>> obtenerBonosEspeciales({
    String? idColaborador,
    String? fechaInicio,
    String? fechaFin,
  }) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No hay token de autenticación');

    final queryParams = <String, String>{};
    if (idColaborador != null) queryParams['id_colaborador'] = idColaborador;
    if (fechaInicio != null) queryParams['fecha_inicio'] = fechaInicio;
    if (fechaFin != null) queryParams['fecha_fin'] = fechaFin;

    final uri = Uri.parse('${ApiService.baseUrl}/bono-especial').replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Error al obtener bonos especiales: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> obtenerBonoEspecialPorId(String id) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No hay token de autenticación');

    final uri = Uri.parse('${ApiService.baseUrl}/bono-especial/$id');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener bono especial: ${response.statusCode}');
    }
  }

  static Future<void> crearBonoEspecial(Map<String, dynamic> datos) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No hay token de autenticación');

    final uri = Uri.parse('${ApiService.baseUrl}/bono-especial/');

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(datos),
    );

    if (response.statusCode != 201) {
      throw Exception('Error al crear bono especial: ${response.statusCode}');
    }
  }

  static Future<void> editarBonoEspecial(String id, Map<String, dynamic> datos) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No hay token de autenticación');

    final uri = Uri.parse('${ApiService.baseUrl}/bono-especial/$id');

    final response = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(datos),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al editar bono especial: ${response.statusCode}');
    }
  }

  static Future<void> eliminarBonoEspecial(String id) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No hay token de autenticación');

    final uri = Uri.parse('${ApiService.baseUrl}/bono-especial/$id');

    final response = await http.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar bono especial: ${response.statusCode}');
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerResumenBonosEspeciales({
    String? fechaInicio,
    String? fechaFin,
  }) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No hay token de autenticación');

    final queryParams = <String, String>{};
    if (fechaInicio != null) queryParams['fecha_inicio'] = fechaInicio;
    if (fechaFin != null) queryParams['fecha_fin'] = fechaFin;

    final uri = Uri.parse('${ApiService.baseUrl}/bono-especial/resumen-colaborador').replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Error al obtener resumen de bonos especiales: ${response.statusCode}');
    }
  }

  // Métodos para Contratistas
  static Future<List<Map<String, dynamic>>> obtenerContratistas() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No hay token de autenticación');

    final uri = Uri.parse('${ApiService.baseUrl}/contratistas');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Error al obtener contratistas: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> obtenerContratistaPorId(String id) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No hay token de autenticación');

    final uri = Uri.parse('${ApiService.baseUrl}/contratistas/$id');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener contratista: ${response.statusCode}');
    }
  }

  static Future<void> crearContratista(Map<String, dynamic> datos) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No hay token de autenticación');

    final uri = Uri.parse('${ApiService.baseUrl}/contratistas/');

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(datos),
    );

    if (response.statusCode != 201) {
      throw Exception('Error al crear contratista: ${response.statusCode}');
    }
  }

  static Future<void> editarContratista(String id, Map<String, dynamic> datos) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No hay token de autenticación');

    final uri = Uri.parse('${ApiService.baseUrl}/contratistas/$id');

    final response = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(datos),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al editar contratista: ${response.statusCode}');
    }
  }



  static Future<Map<String, dynamic>> obtenerOpcionesContratistas() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No hay token de autenticación');

    final uri = Uri.parse('${ApiService.baseUrl}/contratistas/opciones');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener opciones de contratistas: ${response.statusCode}');
    }
  }



  // Desactivar colaborador (cambiar estado a inactivo)
  static Future<void> desactivarColaborador(String colaboradorId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/colaboradores/$colaboradorId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'id_estado': '2', // Estado inactivo
        }),
      );

      if (response.statusCode == 200) {
        return;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al desactivar colaborador');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Activar colaborador (cambiar estado a activo)
  static Future<void> activarColaborador(String colaboradorId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/colaboradores/$colaboradorId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'id_estado': '1', // Estado activo
        }),
      );

      if (response.statusCode == 200) {
        return;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al activar colaborador');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ===== MÉTODOS DE CONTRATISTAS =====

  // Desactivar contratista (cambiar estado a inactivo)
  static Future<void> desactivarContratista(String contratistaId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/contratistas/$contratistaId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'id_estado': '2', // Estado inactivo
        }),
      );

      if (response.statusCode == 200) {
        return;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al desactivar contratista');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Activar contratista (cambiar estado a activo)
  static Future<void> activarContratista(String contratistaId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/contratistas/$contratistaId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'id_estado': '1', // Estado activo
        }),
      );

      if (response.statusCode == 200) {
        return;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al activar contratista');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ===== MÉTODOS ADICIONALES DE TRABAJADORES =====

  // Desactivar trabajador (cambiar estado a inactivo)
  static Future<void> desactivarTrabajador(String trabajadorId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/trabajadores/$trabajadorId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'id_estado': '2', // Estado inactivo
        }),
      );

      if (response.statusCode == 200) {
        return;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al desactivar trabajador');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Activar trabajador (cambiar estado a activo)
  static Future<void> activarTrabajador(String trabajadorId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/trabajadores/$trabajadorId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'id_estado': '1', // Estado activo
        }),
      );

      if (response.statusCode == 200) {
        return;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al activar trabajador');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
} 