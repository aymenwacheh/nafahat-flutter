// lib/services/card_config_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

// ============================================
// MODÈLE DE CONFIGURATION
// ============================================

class CardConfig {
  List<String> visibleFields;

  // Style des libellés
  String labelFontFamily;
  double labelFontSize;
  FontWeight labelFontWeight;
  Color labelColor;

  // Style des valeurs
  String valueFontFamily;
  double valueFontSize;
  FontWeight valueFontWeight;
  Color valueColor;

  // Style du titre
  String titleFontFamily;
  double titleFontSize;
  FontWeight titleFontWeight;
  Color titleColor;

  CardConfig({
    required this.visibleFields,
    required this.labelFontFamily,
    required this.labelFontSize,
    required this.labelFontWeight,
    required this.labelColor,
    required this.valueFontFamily,
    required this.valueFontSize,
    required this.valueFontWeight,
    required this.valueColor,
    required this.titleFontFamily,
    required this.titleFontSize,
    required this.titleFontWeight,
    required this.titleColor,
  });

  factory CardConfig.defaultConfig() {
    return CardConfig(
      visibleFields: [
        'title',
        'trainer',
        'duration',
        'period',
        'price',
        'discount',
      ],
      labelFontFamily: 'Cairo',
      labelFontSize: 10,
      labelFontWeight: FontWeight.w600,
      labelColor: Colors.grey[600]!,
      valueFontFamily: 'Cairo',
      valueFontSize: 10,
      valueFontWeight: FontWeight.w500,
      valueColor: Colors.black,
      titleFontFamily: 'Cairo',
      titleFontSize: 14,
      titleFontWeight: FontWeight.bold,
      titleColor: const Color(0xff2c221e),
    );
  }

  factory CardConfig.fromJson(Map<String, dynamic> json) {
    return CardConfig(
      visibleFields: List<String>.from(json['visibleFields'] ?? []),
      labelFontFamily: json['labelFontFamily'] ?? 'Cairo',
      labelFontSize: (json['labelFontSize'] ?? 10).toDouble(),
      labelFontWeight: _getFontWeight(json['labelFontWeight'] ?? 600),
      labelColor: _getColor(json['labelColor'] ?? '#616161'),
      valueFontFamily: json['valueFontFamily'] ?? 'Cairo',
      valueFontSize: (json['valueFontSize'] ?? 10).toDouble(),
      valueFontWeight: _getFontWeight(json['valueFontWeight'] ?? 500),
      valueColor: _getColor(json['valueColor'] ?? '#000000'),
      titleFontFamily: json['titleFontFamily'] ?? 'Cairo',
      titleFontSize: (json['titleFontSize'] ?? 14).toDouble(),
      titleFontWeight: _getFontWeight(json['titleFontWeight'] ?? 700),
      titleColor: _getColor(json['titleColor'] ?? '#2c221e'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'visibleFields': visibleFields,
      'labelFontFamily': labelFontFamily,
      'labelFontSize': labelFontSize,
      'labelFontWeight': labelFontWeight.index,
      'labelColor': _colorToString(labelColor),
      'valueFontFamily': valueFontFamily,
      'valueFontSize': valueFontSize,
      'valueFontWeight': valueFontWeight.index,
      'valueColor': _colorToString(valueColor),
      'titleFontFamily': titleFontFamily,
      'titleFontSize': titleFontSize,
      'titleFontWeight': titleFontWeight.index,
      'titleColor': _colorToString(titleColor),
    };
  }

  static FontWeight _getFontWeight(int value) {
    return FontWeight.values.firstWhere(
      (w) => w.index == value,
      orElse: () => FontWeight.w400,
    );
  }

  static Color _getColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xff')));
    } catch (e) {
      return Colors.black;
    }
  }

  static String _colorToString(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  // Méthodes utilitaires
  TextStyle getTitleStyle() {
    return GoogleFonts.getFont(
      titleFontFamily,
      fontSize: titleFontSize,
      fontWeight: titleFontWeight,
      color: titleColor,
    );
  }

  TextStyle getLabelStyle() {
    return GoogleFonts.getFont(
      labelFontFamily,
      fontSize: labelFontSize,
      fontWeight: labelFontWeight,
      color: labelColor,
    );
  }

  TextStyle getValueStyle() {
    return GoogleFonts.getFont(
      valueFontFamily,
      fontSize: valueFontSize,
      fontWeight: valueFontWeight,
      color: valueColor,
    );
  }
}
