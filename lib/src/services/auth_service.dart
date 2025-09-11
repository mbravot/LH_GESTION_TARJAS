import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final String baseUrl = 'https://api-lh-gestion-tarjas-927498545444.us-central1.run.app/api';
  //final String baseUrl = 'http://192.168.1.52:5000/api';
  final storage = const FlutterSecureStorage();

  //Login
  Future<Map<String, dynamic>> login(String usuario, String password) async {
    final startTime = DateTime.now();
    print('🔐 [LOGIN] Iniciando login para usuario: $usuario');
    print('🔐 [LOGIN] URL: $baseUrl/auth/login');
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'usuario': usuario,
          'clave': password,
        }),
      );

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      print('🔐 [LOGIN] Respuesta recibida en ${duration.inMilliseconds}ms - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🔐 [LOGIN] Login exitoso - Datos del usuario obtenidos');
        
        print('🔐 [LOGIN] Guardando datos en storage...');
        final storageStartTime = DateTime.now();
        
        // Guardar el token
        await storage.write(key: 'token', value: data['access_token']);
        
        // Guardar los datos del usuario individualmente
        await storage.write(key: 'nombre', value: data['nombre_usuario'] ?? data['usuario']);
        await storage.write(key: 'id_sucursal', value: data['id_sucursal']?.toString());
        await storage.write(key: 'nombre_sucursal', value: data['sucursal_nombre']);
        await storage.write(key: 'id_rol', value: data['id_rol']?.toString());
        
        // Guardar los datos completos del usuario
        await storage.write(key: 'user_data', value: json.encode({
          'nombre': data['nombre_usuario'] ?? data['usuario'],
          'id_sucursal': data['id_sucursal'],
          'nombre_sucursal': data['sucursal_nombre'],
          'id_rol': data['id_rol'],
        }));

        final storageEndTime = DateTime.now();
        final storageDuration = storageEndTime.difference(storageStartTime);
        print('🔐 [LOGIN] Storage completado en ${storageDuration.inMilliseconds}ms');
        
        final totalDuration = storageEndTime.difference(startTime);
        print('🔐 [LOGIN] Login total completado en ${totalDuration.inMilliseconds}ms');

        return data;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error de autenticación');
      }
    } catch (e) {
      developer.log('Error durante el login: $e');
      rethrow;
    }
  }

  //Cerrar sesión
  Future<void> logout() async {
    await storage.deleteAll();
  }

  Future<String?> getToken() async {
    return await storage.read(key: 'token');
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final startTime = DateTime.now();
    print('👤 [GET_USER] Obteniendo datos del usuario desde storage...');
    
    try {
      final userDataStr = await storage.read(key: 'user_data');
      if (userDataStr != null) {
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);
        print('👤 [GET_USER] Datos obtenidos en ${duration.inMilliseconds}ms');
        return json.decode(userDataStr);
      }
      print('👤 [GET_USER] No hay datos de usuario en storage');
      return null;
    } catch (e) {
      print('👤 [GET_USER] Error al obtener datos del usuario: $e');
      return null;
    }
  }

  // Validar si el token actual es válido
  Future<bool> validateToken() async {
    try {
      final token = await getToken();
      if (token == null) return false;

      // Usar un endpoint que sabemos que existe para validar el token
      // Si el token es válido, debería devolver 200 o 401 (pero no 403)
      // Si es inválido, devolverá 401 o 403
      final response = await http.get(
        Uri.parse('$baseUrl/colaboradores'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      // Si el token es válido, debería devolver 200
      // Si es inválido, devolverá 401 o 403
      return response.statusCode == 200;
    } catch (e) {
      developer.log('Error al validar token: $e');
      return false;
    }
  }

//Cambiar contraseña
  Future<void> cambiarClave(String claveActual, String nuevaClave) async {
    developer.log('Intentando cambiar contraseña');
    
    try {
      final token = await getToken();
      if (token == null) throw Exception('No autorizado');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/cambiar-clave'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'clave_actual': claveActual,
          'nueva_clave': nuevaClave,
        }),
      );

      developer.log('Código de respuesta: ${response.statusCode}');
      developer.log('Cuerpo de respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        developer.log('Contraseña cambiada exitosamente');
        return;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al cambiar la contraseña');
      }
    } catch (e) {
      developer.log('Error durante el cambio de contraseña: $e');
      rethrow;
    }
  }

  // Obtener las sucursales disponibles del usuario
  Future<List<Map<String, dynamic>>> getSucursalesDisponibles() async {
    final startTime = DateTime.now();
    developer.log('Obteniendo sucursales disponibles');
    
    try {
      final token = await getToken();
      if (token == null) throw Exception('No autorizado');

      final response = await http.get(
        Uri.parse('$baseUrl/auth/sucursales'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      
      developer.log('Código de respuesta: ${response.statusCode}');
      developer.log('Cuerpo de respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al obtener las sucursales');
      }
    } catch (e) {
      developer.log('Error al obtener sucursales: $e');
      rethrow;
    }
  }

  // Cambiar la sucursal activa del usuario
  Future<Map<String, dynamic>> cambiarSucursal(String idSucursal) async {
    final startTime = DateTime.now();
    developer.log('Cambiando sucursal activa a: $idSucursal');
    
    try {
      final token = await getToken();
      if (token == null) throw Exception('No autorizado');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/cambiar-sucursal'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'id_sucursal': idSucursal,
        }),
      );

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      
      developer.log('Código de respuesta: ${response.statusCode}');
      developer.log('Cuerpo de respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Actualizar los datos del usuario en el storage
        final currentUserData = await getCurrentUser();
        if (currentUserData != null) {
          currentUserData['id_sucursal'] = int.tryParse(idSucursal);
          currentUserData['nombre_sucursal'] = data['sucursal_nombre'];
          
          await storage.write(key: 'user_data', value: json.encode(currentUserData));
          await storage.write(key: 'id_sucursal', value: idSucursal);
          await storage.write(key: 'nombre_sucursal', value: data['sucursal_nombre']);
        }
        
        return data;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al cambiar la sucursal');
      }
    } catch (e) {
      developer.log('Error al cambiar sucursal: $e');
      rethrow;
    }
  }
} 