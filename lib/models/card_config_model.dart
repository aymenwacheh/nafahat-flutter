// lib/models/card_config_model.dart
// Modèle unique de configuration des cartes (fusion des anciennes
// définitions dupliquées dans apparence_card.dart et card_config_service.dart)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafahat/models/training_model.dart';

// ============================================
// MODÈLE DE CONFIGURATION MIS À JOUR
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

  // ✅ NOUVEAUX CHAMPS : Paramètres d'affichage mobile
  int mobileDisplayCount;
  List<String> mobileSelectedTrainings;
  bool showSeeMoreButton;

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
    this.mobileDisplayCount = 3,
    this.mobileSelectedTrainings = const [],
    this.showSeeMoreButton = true,
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
      labelFontFamily: 'Cairo-Regular',
      labelFontSize: 10,
      labelFontWeight: FontWeight.w600,
      labelColor: Colors.grey[600]!,
      valueFontFamily: 'Cairo-Regular',
      valueFontSize: 10,
      valueFontWeight: FontWeight.w500,
      valueColor: Colors.black,
      titleFontFamily: 'Cairo-Bold',
      titleFontSize: 14,
      titleFontWeight: FontWeight.bold,
      titleColor: const Color(0xff2c221e),
      mobileDisplayCount: 3,
      mobileSelectedTrainings: [],
      showSeeMoreButton: true,
    );
  }

  factory CardConfig.fromJson(Map<String, dynamic> json) {
    return CardConfig(
      visibleFields: List<String>.from(json['visibleFields'] ?? []),
      labelFontFamily: json['labelFontFamily'] ?? 'Cairo-Regular',
      labelFontSize: (json['labelFontSize'] ?? 10).toDouble(),
      labelFontWeight: _getFontWeight(json['labelFontWeight'] ?? 600),
      labelColor: _getColor(json['labelColor'] ?? '#616161'),
      valueFontFamily: json['valueFontFamily'] ?? 'Cairo-Regular',
      valueFontSize: (json['valueFontSize'] ?? 10).toDouble(),
      valueFontWeight: _getFontWeight(json['valueFontWeight'] ?? 500),
      valueColor: _getColor(json['valueColor'] ?? '#000000'),
      titleFontFamily: json['titleFontFamily'] ?? 'Cairo-Bold',
      titleFontSize: (json['titleFontSize'] ?? 14).toDouble(),
      titleFontWeight: _getFontWeight(json['titleFontWeight'] ?? 700),
      titleColor: _getColor(json['titleColor'] ?? '#2c221e'),
      mobileDisplayCount: json['mobileDisplayCount'] ?? 3,
      mobileSelectedTrainings: List<String>.from(
        json['mobileSelectedTrainings'] ?? [],
      ),
      showSeeMoreButton: json['showSeeMoreButton'] ?? true,
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
      'mobileDisplayCount': mobileDisplayCount,
      'mobileSelectedTrainings': mobileSelectedTrainings,
      'showSeeMoreButton': showSeeMoreButton,
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
    final family = _extractFontFamily(titleFontFamily);
    return GoogleFonts.getFont(
      family,
      fontSize: titleFontSize,
      fontWeight: titleFontWeight,
      color: titleColor,
    );
  }

  TextStyle getLabelStyle() {
    final family = _extractFontFamily(labelFontFamily);
    return GoogleFonts.getFont(
      family,
      fontSize: labelFontSize,
      fontWeight: labelFontWeight,
      color: labelColor,
    );
  }

  TextStyle getValueStyle() {
    final family = _extractFontFamily(valueFontFamily);
    return GoogleFonts.getFont(
      family,
      fontSize: valueFontSize,
      fontWeight: valueFontWeight,
      color: valueColor,
    );
  }

  static String _extractFontFamily(String fontWithVariant) {
    if (fontWithVariant.contains('-')) {
      return fontWithVariant.split('-').first;
    }
    return fontWithVariant;
  }

  // ✅ Méthode pour obtenir les formations sélectionnées
  List<TrainingModel> getSelectedTrainings(List<TrainingModel> allTrainings) {
    final selected = <TrainingModel>[];
    for (final id in mobileSelectedTrainings) {
      final training = allTrainings.firstWhere(
        (t) => t.id == id,
        orElse: () => throw Exception('Training not found'),
      );
      selected.add(training);
    }
    return selected;
  }
}

class CardFieldOption {
  final String id;
  final String labelFr;
  final String labelAr;
  final IconData icon;
  final bool defaultVisible;

  CardFieldOption({
    required this.id,
    required this.labelFr,
    required this.labelAr,
    required this.icon,
    this.defaultVisible = false,
  });
}

// ✅ Import du service de formation (à ajouter en haut du fichier)
// import 'package:nafahat/services/training_service.dart';
