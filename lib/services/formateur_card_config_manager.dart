// lib/services/formateur_card_config_manager.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nafahat/pages/adminisration/apparence_card_formateur.dart';
import 'package:nafahat/services/appearance_config_service.dart';
import 'dart:convert';

class FormateurCardConfigManager extends ChangeNotifier {
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
      final remote = await AppearanceConfigService.load('formateur_card');
      if (remote != null && remote.isNotEmpty) {
        _config = FormateurCardConfig.fromJson(remote);
        await prefs.setString(
          'formateur_card_config',
          json.encode(remote),
        );
      } else {
        final configJson = prefs.getString('formateur_card_config');
        if (configJson != null && configJson.isNotEmpty) {
          _config = FormateurCardConfig.fromJson(json.decode(configJson));
        } else {
          _config = FormateurCardConfig.defaultConfig();
        }
      }
    } catch (e) {
      _config = FormateurCardConfig.defaultConfig();
    }
    notifyListeners();
  }

  FormateurCardConfig get config {
    return _config ?? FormateurCardConfig.defaultConfig();
  }

  void updateConfig(FormateurCardConfig config) {
    _config = config;
    notifyListeners();
  }

  Future<void> saveConfig(FormateurCardConfig config) async {
    _config = config;
    final prefs = await SharedPreferences.getInstance();
    final jsonMap = config.toJson();
    await prefs.setString('formateur_card_config', json.encode(jsonMap));
    await AppearanceConfigService.save('formateur_card', jsonMap);
    notifyListeners();
  }

  Future<void> reset() async {
    _config = FormateurCardConfig.defaultConfig();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('formateur_card_config');
    await AppearanceConfigService.delete('formateur_card');
    notifyListeners();
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
