// lib/services/geo_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class GeoService {
  static const String _ipApiUrl = 'http://ip-api.com/json/';

  // ✅ Récupérer le code pays depuis l'IP
  static Future<String> getUserCountryCode() async {
    try {
      final response = await http.get(Uri.parse(_ipApiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['countryCode'] ?? 'TN';
      }
      return 'TN';
    } catch (e) {
      print('❌ Erreur détection IP: $e');
      return 'TN';
    }
  }

  // ✅ Récupérer toutes les informations de localisation
  static Future<Map<String, dynamic>> getUserLocation() async {
    try {
      final response = await http.get(Uri.parse(_ipApiUrl));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'countryCode': 'TN', 'country': 'Tunisie'};
    } catch (e) {
      print('❌ Erreur détection IP: $e');
      return {'countryCode': 'TN', 'country': 'Tunisie'};
    }
  }

  // ✅ Vérifier si le pays utilise l'Euro
  static bool isEuroZone(String countryCode) {
    const euroCountries = [
      'FR',
      'DE',
      'IT',
      'ES',
      'PT',
      'BE',
      'NL',
      'LU',
      'IE',
      'AT',
      'FI',
      'GR',
      'SK',
      'SI',
      'LT',
      'LV',
      'EE',
      'MT',
      'CY',
      'HR',
    ];
    return euroCountries.contains(countryCode.toUpperCase());
  }

  // ✅ Vérifier si le pays utilise le Dollar US
  static bool isUsdZone(String countryCode) {
    const usdCountries = ['US', 'CA', 'MX', 'EC', 'SV', 'PA', 'ZW'];
    return usdCountries.contains(countryCode.toUpperCase());
  }
}
