// lib/config/api_config.dart
import 'package:flutter/foundation.dart';

class ApiConfig {
  // ✅ Garder une constante pour les widgets existants
  static const String baseUrlConst = 'https://api.nafahat-academy.com';

  // ✅ Getter pour la détection automatique (vos services l'utilisent)
  static String get baseUrl {
    // Si une variable d'environnement est définie
    const String envUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: '',
    );

    if (envUrl.isNotEmpty) {
      return envUrl;
    }

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
