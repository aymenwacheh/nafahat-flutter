// lib/config/api_config.dart
class ApiConfig {
  // Configuration automatique selon l'environnement
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  // Pour le web, on utilise la même URL mais avec des vérifications
  static String get apiUrl {
    // En production, on peut utiliser l'URL relative
    if (const String.fromEnvironment('IS_PRODUCTION') == 'true') {
      return '/api';
    }
    return baseUrl;
  }
}
