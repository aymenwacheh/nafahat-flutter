// lib/config/api_config.dart
import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    // ✅ Si une variable d'environnement est définie, l'utiliser en priorité
    const String envUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: '',
    );
    
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    
    // ✅ Détection automatique
    if (kIsWeb) {
      final host = Uri.base.host;
      final scheme = Uri.base.scheme;
      final port = Uri.base.port;
      
      // Localhost
      if (host == 'localhost' || host == '127.0.0.1') {
        return 'http://localhost:3000/api';
      }
      
      // Serveur
      return (port == 80 || port == 443) 
          ? '$scheme://$host/api' 
          : '$scheme://$host:3000/api';
    }
    
    // Mobile
    return 'http://192.168.1.100:3000/api';
  }
}