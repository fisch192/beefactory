import 'dart:convert';

import 'package:http/http.dart' as http;

enum VarroaWeatherRisk { low, medium, high }

class WeatherData {
  final double temperature;
  final int humidity;
  final double precipitation;
  final double windSpeed;
  final int weatherCode;

  const WeatherData({
    required this.temperature,
    required this.humidity,
    required this.precipitation,
    required this.windSpeed,
    required this.weatherCode,
  });

  String get conditionEmoji {
    if (weatherCode == 0) return '☀️';
    if (weatherCode <= 3) return '⛅';
    if (weatherCode <= 48) return '🌫️';
    if (weatherCode <= 55) return '🌦️';
    if (weatherCode <= 65) return '🌧️';
    if (weatherCode <= 75) return '❄️';
    if (weatherCode <= 82) return '🌦️';
    return '⛈️';
  }

  String get conditionText {
    if (weatherCode == 0) return 'Sonnig';
    if (weatherCode <= 3) return 'Leicht bewölkt';
    if (weatherCode <= 48) return 'Nebelig';
    if (weatherCode <= 55) return 'Nieselregen';
    if (weatherCode <= 65) return 'Regen';
    if (weatherCode <= 75) return 'Schnee';
    if (weatherCode <= 82) return 'Schauer';
    return 'Gewitter';
  }

  bool get goodForBeesFlight =>
      temperature >= 10 &&
      precipitation < 0.5 &&
      windSpeed < 25 &&
      weatherCode < 51;

  VarroaWeatherRisk get varroaRisk {
    // Varroa reproduces optimally at 15–35 °C + high humidity
    if (temperature < 5 || temperature > 38) return VarroaWeatherRisk.low;
    if (temperature >= 15 && temperature <= 35 && humidity >= 70) {
      return VarroaWeatherRisk.high;
    }
    if (temperature >= 10 && humidity >= 55) return VarroaWeatherRisk.medium;
    return VarroaWeatherRisk.low;
  }

  String get varroaRiskLabel {
    switch (varroaRisk) {
      case VarroaWeatherRisk.low:
        return 'Gering';
      case VarroaWeatherRisk.medium:
        return 'Mittel';
      case VarroaWeatherRisk.high:
        return 'Erhöht';
    }
  }
}

class WeatherApi {
  static Future<WeatherData?> fetch(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lng'
        '&current=temperature_2m,relative_humidity_2m,'
        'precipitation,wind_speed_10m,weather_code'
        '&timezone=auto',
      );
      final response =
          await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final c = body['current'] as Map<String, dynamic>;
      return WeatherData(
        temperature: (c['temperature_2m'] as num).toDouble(),
        humidity: (c['relative_humidity_2m'] as num).toInt(),
        precipitation: (c['precipitation'] as num).toDouble(),
        windSpeed: (c['wind_speed_10m'] as num).toDouble(),
        weatherCode: (c['weather_code'] as num).toInt(),
      );
    } catch (_) {
      return null;
    }
  }
}
