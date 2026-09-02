// lib/models/SectionOrderModel.dart
import 'package:flutter/material.dart';

class SectionOrderModel {
  final String id;
  final String sectionKey;
  final String title;
  final String titleAr;
  final IconData icon;
  final int order;
  final bool isActive;
  final bool isDuplicate;

  SectionOrderModel({
    required this.id,
    required this.sectionKey,
    required this.title,
    required this.titleAr,
    required this.icon,
    this.order = 0,
    this.isActive = true,
    this.isDuplicate = false,
  });

  // ✅ Convertir IconData en String pour le JSON
  String _iconToString(IconData icon) {
    // Utiliser le code point pour identifier l'icône
    return icon.codePoint.toString();
  }

  // ✅ Convertir String en IconData
  IconData _stringToIcon(String iconString) {
    // Mapper les icônes connues
    final iconMap = {
      'Icons.home_outlined': Icons.home_outlined,
      'Icons.school_outlined': Icons.school_outlined,
      'Icons.person_outline': Icons.person_outline,
      'Icons.video_library_outlined': Icons.video_library_outlined,
      'Icons.link_rounded': Icons.link_rounded,
      'Icons.assignment_outlined': Icons.assignment_outlined,
      'Icons.home_work_outlined': Icons.home_work_outlined,
      'Icons.palette_outlined': Icons.palette_outlined,
      'Icons.people_outline': Icons.people_outline,
      'Icons.info_outline': Icons.info_outline,
    };
    
    return iconMap[iconString] ?? Icons.circle_outlined;
  }

  factory SectionOrderModel.fromJson(Map<String, dynamic> json) {
    // ✅ Récupérer l'icône comme String et la convertir
    final iconString = json['icon'] as String? ?? 'Icons.circle_outlined';
    final icon = _stringToIconStatic(iconString);
    
    return SectionOrderModel(
      id: json['id']?.toString() ?? '',
      sectionKey: json['sectionKey'] ?? '',
      title: json['title'] ?? '',
      titleAr: json['titleAr'] ?? '',
      icon: icon,
      order: json['order'] as int? ?? 0,
      isActive: json['isActive'] ?? true,
      isDuplicate: json['isDuplicate'] ?? false,
    );
  }

  // ✅ Méthode statique pour la conversion
  static IconData _stringToIconStatic(String iconString) {
    final iconMap = {
      'Icons.home_outlined': Icons.home_outlined,
      'Icons.school_outlined': Icons.school_outlined,
      'Icons.person_outline': Icons.person_outline,
      'Icons.video_library_outlined': Icons.video_library_outlined,
      'Icons.link_rounded': Icons.link_rounded,
      'Icons.assignment_outlined': Icons.assignment_outlined,
      'Icons.home_work_outlined': Icons.home_work_outlined,
      'Icons.palette_outlined': Icons.palette_outlined,
      'Icons.people_outline': Icons.people_outline,
      'Icons.info_outline': Icons.info_outline,
      // Ajouter d'autres icônes si nécessaire
    };
    return iconMap[iconString] ?? Icons.circle_outlined;
  }

  // ✅ Convertir en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sectionKey': sectionKey,
      'title': title,
      'titleAr': titleAr,
      'icon': _iconToString(icon), // Convertir IconData en String
      'order': order,
      'isActive': isActive,
      'isDuplicate': isDuplicate,
    };
  }

  SectionOrderModel copyWith({
    String? id,
    String? sectionKey,
    String? title,
    String? titleAr,
    IconData? icon,
    int? order,
    bool? isActive,
    bool? isDuplicate,
  }) {
    return SectionOrderModel(
      id: id ?? this.id,
      sectionKey: sectionKey ?? this.sectionKey,
      title: title ?? this.title,
      titleAr: titleAr ?? this.titleAr,
      icon: icon ?? this.icon,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      isDuplicate: isDuplicate ?? this.isDuplicate,
    );
  }
}

// ============================================================
// SECTIONS PRÉDÉFINIES
// ============================================================
class PredefinedSections {
  static const String hero = 'hero';
  static const String bulls = 'bulls';
  static const String trainings = 'trainings';
  static const String inscription = 'inscription';
  static const String videos = 'videos';
  static const String formateurs = 'formateurs';

  static List<Map<String, dynamic>> getDefaultSectionsData() {
    return [
      {
        'id': '1',
        'sectionKey': hero,
        'title': 'Hero Section',
        'titleAr': 'قسم الهيرو',
        'icon': 'Icons.home_outlined', // ✅ String, pas IconData
        'order': 0,
        'isActive': true,
        'isDuplicate': false,
      },
      {
        'id': '2',
        'sectionKey': bulls,
        'title': 'Bulls Liens',
        'titleAr': 'وحدات الروابط',
        'icon': 'Icons.link_rounded',
        'order': 1,
        'isActive': true,
        'isDuplicate': false,
      },
      {
        'id': '3',
        'sectionKey': trainings,
        'title': 'Formations',
        'titleAr': 'التكوينات',
        'icon': 'Icons.school_outlined',
        'order': 2,
        'isActive': true,
        'isDuplicate': false,
      },
      {
        'id': '4',
        'sectionKey': inscription,
        'title': 'Inscription',
        'titleAr': 'التسجيل',
        'icon': 'Icons.assignment_outlined',
        'order': 3,
        'isActive': true,
        'isDuplicate': false,
      },
      {
        'id': '5',
        'sectionKey': videos,
        'title': 'Vidéos Favorites',
        'titleAr': 'الفيديوهات المفضلة',
        'icon': 'Icons.video_library_outlined',
        'order': 4,
        'isActive': true,
        'isDuplicate': false,
      },
      {
        'id': '6',
        'sectionKey': formateurs,
        'title': 'Formateurs',
        'titleAr': 'المكونين',
        'icon': 'Icons.person_outline',
        'order': 5,
        'isActive': true,
        'isDuplicate': false,
      },
    ];
  }
}