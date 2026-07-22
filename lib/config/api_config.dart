// lib/config/api_config.dart
class ApiConfig {
  // En développement local, par défaut : http://localhost:3000/api
  // En production, on passe --dart-define=API_BASE_URL=/api lors du build
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );
}
