// lib/services/card_config_manager.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:nafahat/models/card_config_model.dart';

class CardConfigManager extends ChangeNotifier {
  static final CardConfigManager _instance = CardConfigManager._internal();
  factory CardConfigManager() => _instance;
  CardConfigManager._internal();

  CardConfig _config = CardConfig.defaultConfig();
  bool _isInitialized = false;

  CardConfig get config => _config;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString('card_config_apparence');
      if (configJson != null && configJson.isNotEmpty) {
        _config = CardConfig.fromJson(json.decode(configJson));
      } else {
        _config = CardConfig.defaultConfig();
      }
      _isInitialized = true;
      notifyListeners();
      print('✅ CardConfigManager initialisé avec: ${_config.visibleFields}');
    } catch (e) {
      print('❌ Erreur init CardConfigManager: $e');
      _config = CardConfig.defaultConfig();
      _isInitialized = true;
      notifyListeners();
    }
  }

  void updateConfig(CardConfig newConfig) {
    print('📝 Mise à jour de la configuration...');
    _config = newConfig;
    _saveConfig();
    notifyListeners();
    print('✅ Configuration mise à jour et notifiée');
  }

  Future<void> _saveConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'card_config_apparence',
        json.encode(_config.toJson()),
      );
      print('✅ Configuration sauvegardée dans SharedPreferences');
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde: $e');
    }
  }

  void resetToDefault() {
    print('🔄 Réinitialisation à la configuration par défaut');
    _config = CardConfig.defaultConfig();
    _saveConfig();
    notifyListeners();
  }

  bool isFieldVisible(String fieldId) {
    return _config.visibleFields.contains(fieldId);
  }
}