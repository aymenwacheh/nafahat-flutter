// lib/services/formateur_card_config_manager.dart
import 'dart:ui' show FontWeight, Color;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:nafahat/pages/adminisration/apparence_card_formateur.dart';
import 'dart:convert';

class FormateurCardConfigManager {
  static FormateurCardConfigManager? _instance;
  FormateurCardConfig? _config;

  FormateurCardConfigManager._internal();

  factory FormateurCardConfigManager() {
    _instance ??= FormateurCardConfigManager._internal();
    return _instance!;
  }

  Future<void> loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString('formateur_card_config');
      if (configJson != null && configJson.isNotEmpty) {
        _config = FormateurCardConfig.fromJson(json.decode(configJson));
      } else {
        _config = FormateurCardConfig.defaultConfig();
      }
    } catch (e) {
      _config = FormateurCardConfig.defaultConfig();
    }
  }

  FormateurCardConfig get config {
    return _config ?? FormateurCardConfig.defaultConfig();
  }

  void updateConfig(FormateurCardConfig config) {
    _config = config;
  }

  // Méthodes d'accès direct
  List<String> get visibleFields => config.visibleFields;

  String getNameFontFamily() => config.nameFontFamily;
  double getNameFontSize() => config.nameFontSize;
  FontWeight getNameFontWeight() => config.nameFontWeight;
  Color getNameColor() => config.nameColor;

  String getFieldsFontFamily() => config.fieldsFontFamily;
  double getFieldsFontSize() => config.fieldsFontSize;
  FontWeight getFieldsFontWeight() => config.fieldsFontWeight;
  Color getFieldsColor() => config.fieldsColor;

  int getMobileDisplayCount() => config.mobileDisplayCount;
  bool getShowSeeMoreButton() => config.showSeeMoreButton;
}
