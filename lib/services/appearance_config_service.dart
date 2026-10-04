import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:nafahat/config/api_config.dart';

/// Stockage distant générique des configurations d'apparence.
/// Route backend: /api/bulls/appearance-config/:key
class AppearanceConfigService {
  static const Duration _timeout = Duration(seconds: 5);

  static String get _base => '${ApiConfig.apiUrl}/bulls/appearance-config';

  static Uri _uri(String key) =>
      Uri.parse('$_base/${Uri.encodeComponent(key)}');

  static Future<Map<String, dynamic>?> load(String key) async {
    try {
      final response = await http
          .get(
            _uri(key),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        debugPrint(
          'AppearanceConfigService.load($key): HTTP ${response.statusCode}',
        );
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return null;
      if (decoded['success'] != true) return null;

      final data = decoded['data'];
      if (data == null) return null;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return null;
    } on TimeoutException {
      debugPrint('AppearanceConfigService.load($key): timeout');
      return null;
    } catch (e) {
      debugPrint('AppearanceConfigService.load($key): $e');
      return null;
    }
  }

  static Future<bool> save(
    String key,
    Map<String, dynamic> config,
  ) async {
    try {
      final response = await http
          .put(
            _uri(key),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'config': config}),
          )
          .timeout(_timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          'AppearanceConfigService.save($key): HTTP ${response.statusCode}',
        );
        return false;
      }

      final decoded = jsonDecode(response.body);
      return decoded is Map && decoded['success'] == true;
    } on TimeoutException {
      debugPrint('AppearanceConfigService.save($key): timeout');
      return false;
    } catch (e) {
      debugPrint('AppearanceConfigService.save($key): $e');
      return false;
    }
  }

  static Future<bool> delete(String key) async {
    try {
      final response = await http
          .delete(
            _uri(key),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(_timeout);

      return response.statusCode >= 200 && response.statusCode < 300;
    } on TimeoutException {
      debugPrint('AppearanceConfigService.delete($key): timeout');
      return false;
    } catch (e) {
      debugPrint('AppearanceConfigService.delete($key): $e');
      return false;
    }
  }
}
