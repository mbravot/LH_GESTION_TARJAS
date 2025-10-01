import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class WeatherService {
  // API gratuita de OpenWeatherMap (necesitarás una API key)
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String _apiKey = '513f47cfab3502ca14d9f1f28cc1c623'; // Reemplaza con tu API key
  
  // Coordenadas por defecto (Santiago)
  static const double _defaultLatitude = -33.4489;
  static const double _defaultLongitude = -70.6693;

  // Obtener ubicación de la sucursal activa
  static Future<Map<String, double>?> getUbicacionSucursal() async {
    try {
      final response = await ApiService.obtenerUbicacionSucursalActiva();
      final ubicacion = response['ubicacion'] as String;
      
      // Parsear coordenadas (formato: "lat, lng")
      final coords = ubicacion.split(',');
      if (coords.length == 2) {
        final lat = double.parse(coords[0].trim());
        final lng = double.parse(coords[1].trim());
        return {
          'latitude': lat,
          'longitude': lng,
        };
      }
    } catch (e) {
      // Si falla, usar coordenadas por defecto
    }
    return null;
  }

  // Método principal que usa la ubicación de la sucursal activa
  static Future<Map<String, dynamic>?> getWeatherForSucursal() async {
    try {
      // Obtener ubicación de la sucursal activa
      final ubicacion = await getUbicacionSucursal();
      
      if (ubicacion != null) {
        return await getCurrentWeather(
          latitude: ubicacion['latitude'],
          longitude: ubicacion['longitude'],
        );
      } else {
        // Fallback a coordenadas por defecto
        return await getCurrentWeather();
      }
    } catch (e) {
      // Fallback a coordenadas por defecto
      return await getCurrentWeather();
    }
  }

  static Future<Map<String, dynamic>?> getCurrentWeather({
    double? latitude,
    double? longitude,
    String? cityName,
  }) async {
    try {
      // Usar coordenadas proporcionadas o las por defecto
      final lat = latitude ?? _defaultLatitude;
      final lon = longitude ?? _defaultLongitude;
      
      final url = '$_baseUrl/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=es';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'temperature': data['main']['temp'].round(),
          'description': _translateToSpanish(data['weather'][0]['description']),
          'icon': data['weather'][0]['icon'],
          'humidity': data['main']['humidity'],
          'wind_speed': data['wind']['speed'],
          'city': cityName ?? data['name'],
        };
      }
    } catch (e) {
      // print('Error obteniendo clima: $e');
    }
    return null;
  }

  // Método alternativo usando una API más simple (sin API key)
  static Future<Map<String, dynamic>?> getCurrentWeatherSimple({
    String? cityName,
  }) async {
    try {
      // Usando wttr.in (servicio gratuito sin API key) con idioma español
      final city = cityName ?? 'Santiago';
      final url = 'https://wttr.in/$city?format=j1&lang=es';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current_condition'][0];
        
        return {
          'temperature': int.parse(current['temp_C']),
          'description': _translateToSpanish(current['weatherDesc'][0]['value']),
          'icon': _getWeatherIcon(current['weatherCode']),
          'humidity': int.parse(current['humidity']),
          'wind_speed': double.parse(current['windspeedKmph']),
          'city': city,
        };
      }
    } catch (e) {
      // print('Error obteniendo clima simple: $e');
    }
    return null;
  }

  static String _translateToSpanish(String description) {
    // Debug: imprimir la descripción original
    // print('🌤️ Descripción original del clima: "$description"');
    
    // Traducción de descripciones de clima al español
    final translations = {
      // Condiciones básicas
      'clear sky': 'Cielo despejado',
      'sunny': 'Soleado',
      'partly cloudy': 'Parcialmente nublado',
      'cloudy': 'Nublado',
      'overcast': 'Cielo cubierto',
      'few clouds': 'Pocas nubes',
      'scattered clouds': 'Nubes dispersas',
      'broken clouds': 'Nubes rotas',
      'overcast clouds': 'Nubes cubiertas',
      
      // Lluvia
      'rain': 'Lluvia',
      'light rain': 'Lluvia ligera',
      'moderate rain': 'Lluvia moderada',
      'heavy rain': 'Lluvia intensa',
      'very heavy rain': 'Lluvia muy intensa',
      'extreme rain': 'Lluvia extrema',
      'freezing rain': 'Lluvia helada',
      'shower rain': 'Lluvia de chubascos',
      'light shower rain': 'Lluvia de chubascos ligera',
      'heavy shower rain': 'Lluvia de chubascos intensa',
      'ragged shower rain': 'Lluvia de chubascos irregular',
      'drizzle': 'Llovizna',
      'light drizzle': 'Llovizna ligera',
      'heavy drizzle': 'Llovizna intensa',
      
      // Nieve
      'snow': 'Nieve',
      'light snow': 'Nieve ligera',
      'heavy snow': 'Nieve intensa',
      'sleet': 'Aguanieve',
      'light shower sleet': 'Aguanieve ligera',
      'shower sleet': 'Aguanieve',
      'light rain and snow': 'Lluvia y nieve ligera',
      'rain and snow': 'Lluvia y nieve',
      'light shower snow': 'Nieve de chubascos ligera',
      'shower snow': 'Nieve de chubascos',
      'heavy shower snow': 'Nieve de chubascos intensa',
      
      // Tormentas
      'thunderstorm': 'Tormenta',
      'light thunderstorm': 'Tormenta ligera',
      'heavy thunderstorm': 'Tormenta intensa',
      'ragged thunderstorm': 'Tormenta irregular',
      'thunderstorm with light rain': 'Tormenta con lluvia ligera',
      'thunderstorm with rain': 'Tormenta con lluvia',
      'thunderstorm with heavy rain': 'Tormenta con lluvia intensa',
      'thunderstorm with light drizzle': 'Tormenta con llovizna ligera',
      'thunderstorm with drizzle': 'Tormenta con llovizna',
      'thunderstorm with heavy drizzle': 'Tormenta con llovizna intensa',
      
      // Condiciones atmosféricas
      'mist': 'Niebla',
      'fog': 'Niebla',
      'haze': 'Bruma',
      'smoke': 'Humo',
      'dust': 'Polvo',
      'sand': 'Arena',
      'ash': 'Ceniza',
      'squall': 'Ráfaga',
      'tornado': 'Tornado',
      'volcanic ash': 'Ceniza volcánica',
      
      // Términos adicionales comunes
      'hot': 'Caluroso',
      'cold': 'Frío',
      'windy': 'Ventoso',
      'humid': 'Húmedo',
      'dry': 'Seco',
      'storm': 'Tormenta',
      'blizzard': 'Ventisca',
      'ice': 'Hielo',
      'frost': 'Escarcha',
    };

    // Buscar traducción exacta
    final lowerDescription = description.toLowerCase().trim();
    if (translations.containsKey(lowerDescription)) {
      final translated = translations[lowerDescription]!;
      // print('🌤️ Traducción exacta: "$description" -> "$translated"');
      return translated;
    }

    // Buscar traducción parcial (palabras clave)
    for (final entry in translations.entries) {
      if (lowerDescription.contains(entry.key)) {
        // print('🌤️ Traducción parcial: "$description" -> "${entry.value}" (clave: "${entry.key}")');
        return entry.value;
      }
    }

    // Buscar por palabras individuales comunes
    final commonWords = {
      'clear': 'Despejado',
      'cloud': 'Nublado',
      'clouds': 'Nubes',
      'rain': 'Lluvia',
      'snow': 'Nieve',
      'storm': 'Tormenta',
      'thunder': 'Trueno',
      'light': 'Ligero',
      'heavy': 'Intenso',
      'moderate': 'Moderado',
      'shower': 'Chubasco',
      'drizzle': 'Llovizna',
      'mist': 'Niebla',
      'fog': 'Niebla',
      'haze': 'Bruma',
      'overcast': 'Cubierto',
      'partly': 'Parcialmente',
      'scattered': 'Disperso',
      'broken': 'Roto',
      'few': 'Pocas',
    };

    for (final word in commonWords.entries) {
      if (lowerDescription.contains(word.key)) {
        // print('🌤️ Traducción por palabra: "$description" -> "${word.value}" (palabra: "${word.key}")');
        return word.value;
      }
    }

    // Si no se encuentra traducción, devolver el original
    // print('🌤️ No se encontró traducción para: "$description"');
    return description;
  }

  static String _getWeatherIcon(String weatherCode) {
    // Mapeo básico de códigos de clima a iconos
    switch (weatherCode) {
      case '113': return '☀️'; // Soleado
      case '116': return '⛅'; // Parcialmente nublado
      case '119': case '122': return '☁️'; // Nublado
      case '143': case '248': case '260': return '🌫️'; // Niebla
      case '176': case '263': case '266': case '281': case '284': case '293': case '296': case '299': case '302': case '305': case '308': case '311': case '314': case '317': case '320': case '323': case '326': case '329': case '332': case '335': case '338': case '350': case '353': case '356': case '359': case '362': case '365': case '368': case '371': case '374': case '377': case '386': case '389': case '392': case '395': return '🌧️'; // Lluvia
      default: return '🌤️';
    }
  }
}
