// lib/models/video_model.dart
class VideoModel {
  final String id;
  final String titleFr;
  final String titleAr;
  final String descriptionFr;
  final String descriptionAr;
  final String videoId;
  final String thumbnailUrl;
  final int views;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  VideoModel({
    required this.id,
    required this.titleFr,
    required this.titleAr,
    required this.descriptionFr,
    required this.descriptionAr,
    required this.videoId,
    required this.thumbnailUrl,
    this.views = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory VideoModel.fromMap(Map<String, dynamic> map) {
    return VideoModel(
      id: map['id'].toString(),
      titleFr: map['title_fr'] ?? '',
      titleAr: map['title_ar'] ?? '',
      descriptionFr: map['description_fr'] ?? '',
      descriptionAr: map['description_ar'] ?? '',
      videoId: map['video_id'] ?? '',
      thumbnailUrl: map['thumbnail_url'] ?? '',
      views: map['views'] ?? 0,
      createdAt: DateTime.parse(
        map['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        map['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
      // ✅ CORRECTION : Convertir l'int en bool
      isActive: map['is_active'] == 1 || map['is_active'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title_fr': titleFr,
      'title_ar': titleAr,
      'description_fr': descriptionFr,
      'description_ar': descriptionAr,
      'video_id': videoId,
      'thumbnail_url': thumbnailUrl,
      'views': views,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      // ✅ Convertir bool en int pour MySQL
      'is_active': isActive ? 1 : 0,
    };
  }

  // ✅ Récupérer le titre selon la langue
  String getTitle(bool isArabic) => isArabic ? titleAr : titleFr;

  // ✅ Récupérer la description selon la langue
  String getDescription(bool isArabic) =>
      isArabic ? descriptionAr : descriptionFr;

  // ✅ URL de la vidéo YouTube
  String get youtubeUrl => 'https://www.youtube.com/watch?v=$videoId';

  // ✅ URL embed pour l'iframe
  String get embedUrl => 'https://www.youtube.com/embed/$videoId';

  // ✅ URL miniature YouTube
  String get youtubeThumbnail =>
      'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
}
