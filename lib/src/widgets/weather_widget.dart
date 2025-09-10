import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/weather_service.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key});

  static final GlobalKey<_WeatherWidgetState> globalKey = GlobalKey<_WeatherWidgetState>();

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();

  static void refreshWeather() {
    globalKey.currentState?._loadWeather();
  }
}

class _WeatherWidgetState extends State<WeatherWidget> {
  Map<String, dynamic>? _weatherData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Obtener información de la sucursal activa
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userData = authProvider.userData;
      
      String? cityName;
      double? latitude;
      double? longitude;
      
      if (userData != null) {
        cityName = userData['nombre_sucursal'];
        
        // Intentar obtener coordenadas de la sucursal
        try {
          final sucursales = await authProvider.getSucursalesDisponibles();
          final sucursalActual = sucursales.firstWhere(
            (s) => s['id'].toString() == userData['id_sucursal'].toString(),
            orElse: () => {},
          );
          
          if (sucursalActual['ubicacion'] != null) {
            final ubicacion = sucursalActual['ubicacion'].toString();
            final coords = ubicacion.split(',');
            if (coords.length == 2) {
              latitude = double.tryParse(coords[0].trim());
              longitude = double.tryParse(coords[1].trim());
            }
          }
        } catch (e) {
          print('Error obteniendo coordenadas de sucursal: $e');
        }
      }

      // Intentar primero con la API simple (sin API key)
      var weatherData = await WeatherService.getCurrentWeatherSimple(
        cityName: cityName,
      );
      
      // Si falla, intentar con OpenWeatherMap (necesita API key)
      if (weatherData == null) {
        weatherData = await WeatherService.getCurrentWeather(
          latitude: latitude,
          longitude: longitude,
          cityName: cityName,
        );
      }

      if (mounted) {
        setState(() {
          _weatherData = weatherData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: _buildWeatherContent(),
    );
  }

  Widget _buildWeatherContent() {
    if (_isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Cargando...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    if (_error != null || _weatherData == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'Sin datos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icono del clima
          Icon(
            _getWeatherIcon(_weatherData!['icon']),
            color: Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 8),
          
          // Temperatura
          Text(
            '${_weatherData!['temperature']}°C',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          
          // Descripción (solo en pantallas grandes)
          if (MediaQuery.of(context).size.width > 1200)
            Text(
              _weatherData!['description'],
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
              ),
            ),
        ],
      );
  }

  IconData _getWeatherIcon(dynamic icon) {
    if (icon is String) {
      // Mapeo de códigos de OpenWeatherMap a iconos de Material Design
      switch (icon) {
        case '01d': return Icons.wb_sunny; // Sol
        case '01n': return Icons.nightlight_round; // Luna
        case '02d': case '02n': return Icons.wb_cloudy; // Parcialmente nublado
        case '03d': case '03n': return Icons.cloud; // Nublado
        case '04d': case '04n': return Icons.cloud_queue; // Muy nublado
        case '09d': case '09n': return Icons.grain; // Lluvia ligera
        case '10d': case '10n': return Icons.beach_access; // Lluvia
        case '11d': case '11n': return Icons.flash_on; // Tormenta
        case '13d': case '13n': return Icons.ac_unit; // Nieve
        case '50d': case '50n': return Icons.blur_on; // Niebla
        default: return Icons.wb_sunny;
      }
    }
    return Icons.wb_sunny;
  }
}
