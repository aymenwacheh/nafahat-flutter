// lib/services/card_config_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nafahat/models/card_config_model.dart';

export 'package:nafahat/models/card_config_model.dart';

class CardConfigService {
  static const String _configKey = 'card_config_apparence';

  // Singleton
  static final CardConfigService _instance = CardConfigService._internal();
  factory CardConfigService() => _instance;
  CardConfigService._internal();

  CardConfig? _cachedConfig;

  /// Charge la configuration depuis SharedPreferences
  Future<CardConfig> loadConfig() async {
    try {
      // Retourner le cache si disponible
      if (_cachedConfig != null) {
        return _cachedConfig!;
      }

      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(_configKey);

      if (configJson != null && configJson.isNotEmpty) {
        final Map<String, dynamic> data = json.decode(configJson);
        _cachedConfig = CardConfig.fromJson(data);
        return _cachedConfig!;
      }
    } catch (e) {
      print('❌ Erreur chargement config: $e');
    }

    // Configuration par défaut
    _cachedConfig = CardConfig.defaultConfig();
    return _cachedConfig!;
  }

  /// Sauvegarde la configuration
  Future<bool> saveConfig(CardConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(config.toJson());
      final result = await prefs.setString(_configKey, jsonString);

      if (result) {
        _cachedConfig = config;
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Erreur sauvegarde config: $e');
      return false;
    }
  }

  /// Réinitialise la configuration par défaut
  Future<CardConfig> resetConfig() async {
    final defaultConfig = CardConfig.defaultConfig();
    await saveConfig(defaultConfig);
    return defaultConfig;
  }

  /// Vérifie si un champ est visible
  Future<bool> isFieldVisible(String fieldId) async {
    final config = await loadConfig();
    return config.visibleFields.contains(fieldId);
  }

  /// Récupère les champs visibles
  Future<List<String>> getVisibleFields() async {
    final config = await loadConfig();
    return config.visibleFields;
  }
}
