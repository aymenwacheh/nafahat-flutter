// slide_item.dart
//
// Modèle de données PARTAGÉ pour un slide du Hero.
// Utilisé à la fois par :
//   - apparence_hero.dart  (page d'administration : upload, édition, ordre)
//   - hero_section.dart    (widget affiché sur le site)
//
// Avant, chaque fichier avait sa propre classe SlideItem, ce qui pouvait les
// faire diverger silencieusement (ex: HeroSection ne savait pas lire les
// images uploadées en base64 sur le web). Maintenant il n'y a plus qu'une
// seule source de vérité.

import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';

class SlideItem {
  final String id;
  final String titleFr;
  final String titleAr;
  final String subtitleFr;
  final String subtitleAr;
  final String imagePath;
  final bool isAsset;
  final bool isVideo;
  final Uint8List? imageBytes;

  SlideItem({
    required this.id,
    required this.titleFr,
    required this.titleAr,
    required this.subtitleFr,
    required this.subtitleAr,
    required this.imagePath,
    this.isAsset = true,
    this.isVideo = false,
    this.imageBytes,
  });

  SlideItem copyWith({
    String? id,
    String? titleFr,
    String? titleAr,
    String? subtitleFr,
    String? subtitleAr,
    String? imagePath,
    bool? isAsset,
    bool? isVideo,
    Uint8List? imageBytes,
  }) {
    return SlideItem(
      id: id ?? this.id,
      titleFr: titleFr ?? this.titleFr,
      titleAr: titleAr ?? this.titleAr,
      subtitleFr: subtitleFr ?? this.subtitleFr,
      subtitleAr: subtitleAr ?? this.subtitleAr,
      imagePath: imagePath ?? this.imagePath,
      isAsset: isAsset ?? this.isAsset,
      isVideo: isVideo ?? this.isVideo,
      imageBytes: imageBytes ?? this.imageBytes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titleFr': titleFr,
      'titleAr': titleAr,
      'subtitleFr': subtitleFr,
      'subtitleAr': subtitleAr,
      'imagePath': imagePath,
      'isAsset': isAsset,
      'isVideo': isVideo,
    };
  }

  factory SlideItem.fromJson(Map<String, dynamic> json) {
    return SlideItem(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      titleFr: json['titleFr'] ?? '',
      titleAr: json['titleAr'] ?? '',
      subtitleFr: json['subtitleFr'] ?? '',
      subtitleAr: json['subtitleAr'] ?? '',
      imagePath: json['imagePath'] ?? '',
      isAsset: json['isAsset'] ?? true,
      isVideo: json['isVideo'] ?? false,
    );
  }

  /// Si ce slide référence une image stockée en base64 (upload web, clé
  /// préfixée par "hero_image_") ou une data URL ("data:image..."), tente de
  /// récupérer/décoder les bytes et retourne un NOUVEAU SlideItem avec
  /// `imageBytes` rempli.
  ///
  /// Si le slide est un asset, a déjà des bytes, ou que le décodage échoue,
  /// retourne le slide tel quel (inchangé).
  ///
  /// Cette logique était avant dupliquée (et absente dans HeroSection) —
  /// elle est maintenant centralisée ici pour que les deux widgets se
  /// comportent exactement pareil.
  static Future<SlideItem> resolveImageBytes(
    SlideItem slide,
    SharedPreferences prefs,
  ) async {
    if (slide.isAsset || slide.imageBytes != null) {
      return slide;
    }

    if (slide.imagePath.startsWith('hero_image_')) {
      final String? base64Image = prefs.getString(slide.imagePath);
      if (base64Image != null && base64Image.isNotEmpty) {
        try {
          return slide.copyWith(imageBytes: base64Decode(base64Image));
        } catch (e) {
          return slide;
        }
      }
      return slide;
    }

    if (slide.imagePath.startsWith('data:image')) {
      final parts = slide.imagePath.split(',');
      if (parts.length > 1) {
        try {
          return slide.copyWith(imageBytes: base64Decode(parts[1]));
        } catch (e) {
          return slide;
        }
      }
    }

    return slide;
  }
}
