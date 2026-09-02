// lib/models/bull_model.dart
import 'dart:ui';

class BullModel {
  final String id;
  final String title;
  final String? titleAr;
  final String? titleFr;
  final String link;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final double fontSize;
  final int order;
  final bool isActive;

  BullModel({
    required this.id,
    required this.title,
    this.titleAr,
    this.titleFr,
    required this.link,
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
    this.fontSize = 14,
    this.order = 0,
    this.isActive = true,
  });

  // ============================================================
  // PARSE COULEUR ROBUSTE
  // Gère tous les formats possibles renvoyés par l'API ou stockés
  // en cache local :
  //   - "#0D443E"        (hex web, 6 chiffres)
  //   - "#FF0D443E"      (hex web avec alpha, 8 chiffres)
  //   - "0xFF0D443E"     (littéral Dart)
  //   - "4280098622"     (entier décimal, ex: Color.value.toString())
  //   - déjà un int
  // ============================================================
  static Color _parseColor(dynamic value, Color fallback) {
    if (value == null) return fallback;

    if (value is int) {
      return Color(value);
    }

    if (value is String) {
      String s = value.trim();
      if (s.isEmpty) return fallback;

      // Format "#RRGGBB" ou "#AARRGGBB"
      if (s.startsWith('#')) {
        s = s.substring(1);
        if (s.length == 6) s = 'FF$s'; // ajoute l'alpha si absent
        final parsed = int.tryParse(s, radix: 16);
        return parsed != null ? Color(parsed) : fallback;
      }

      // Format "0xFF0D443E" ou "0XFF0D443E"
      if (s.toLowerCase().startsWith('0x')) {
        final parsed = int.tryParse(s.substring(2), radix: 16);
        return parsed != null ? Color(parsed) : fallback;
      }

      // Entier décimal pur (ex: "4280098622")
      final decimal = int.tryParse(s);
      if (decimal != null) return Color(decimal);

      // Dernier recours: essayer directement en hexadécimal (ex: "FF0D443E")
      final hexOnly = int.tryParse(s, radix: 16);
      if (hexOnly != null) {
        return Color(s.length <= 6 ? (0xFF000000 | hexOnly) : hexOnly);
      }
    }

    return fallback;
  }

  factory BullModel.fromJson(Map<String, dynamic> json) {
    return BullModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      titleAr: json['titleAr'],
      titleFr: json['titleFr'],
      link: json['link'] ?? '#',
      backgroundColor: _parseColor(json['backgroundColor'], const Color(0xff0D443E)),
      textColor: _parseColor(json['textColor'], const Color(0xffFFFFFF)),
      borderColor: _parseColor(json['borderColor'], const Color(0xffC4A46C)),
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 14,
      order: json['order'] as int? ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'titleAr': titleAr,
      'titleFr': titleFr,
      'link': link,
      'backgroundColor': backgroundColor.value.toString(),
      'textColor': textColor.value.toString(),
      'borderColor': borderColor.value.toString(),
      'fontSize': fontSize,
      'order': order,
      'isActive': isActive,
    };
  }

  BullModel copyWith({
    String? id,
    String? title,
    String? titleAr,
    String? titleFr,
    String? link,
    Color? backgroundColor,
    Color? textColor,
    Color? borderColor,
    double? fontSize,
    int? order,
    bool? isActive,
  }) {
    return BullModel(
      id: id ?? this.id,
      title: title ?? this.title,
      titleAr: titleAr ?? this.titleAr,
      titleFr: titleFr ?? this.titleFr,
      link: link ?? this.link,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      borderColor: borderColor ?? this.borderColor,
      fontSize: fontSize ?? this.fontSize,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
    );
  }
}