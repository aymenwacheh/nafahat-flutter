// lib/services/video_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nafahat/models/video_model.dart';
import '../config/api_config.dart'; // <-- Importer la config

class VideoService {
  // Utiliser ApiConfig.baseUrl
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<List<VideoModel>> getVideos() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/videos'),
        headers: {'Content-Type': 'application/json'},
      );

      print('📡 getVideos - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('✅ ${data.length} vidéos chargées');

        // ✅ Convertir chaque élément en VideoModel
        final List<VideoModel> videos = [];
        for (var item in data) {
          try {
            videos.add(VideoModel.fromMap(item));
          } catch (e) {
            print('❌ Erreur conversion vidéo: $e');
            print('📄 Donnée: $item');
          }
        }
        return videos;
      } else {
        print('❌ Erreur getVideos: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Erreur getVideos: $e');
      return [];
    }
  }

  static Future<VideoModel?> getVideoById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/videos/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return VideoModel.fromMap(data);
      } else {
        return null;
      }
    } catch (e) {
      print('❌ Erreur getVideoById: $e');
      return null;
    }
  }

  static Future<bool> createVideo(VideoModel video) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/videos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(video.toMap()),
      );

      print('📡 createVideo - Status: ${response.statusCode}');
      print('📡 createVideo - Body: ${response.body}');

      if (response.statusCode == 201) {
        print('✅ Vidéo créée avec succès');
        return true;
      } else {
        print('❌ Erreur création vidéo: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Erreur createVideo: $e');
      return false;
    }
  }

  static Future<bool> updateVideo(String id, VideoModel video) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/videos/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(video.toMap()),
      );

      if (response.statusCode == 200) {
        print('✅ Vidéo mise à jour avec succès');
        return true;
      } else {
        print('❌ Erreur mise à jour vidéo: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Erreur updateVideo: $e');
      return false;
    }
  }

  static Future<bool> deleteVideo(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/videos/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        print('✅ Vidéo supprimée avec succès');
        return true;
      } else {
        print('❌ Erreur suppression vidéo: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Erreur deleteVideo: $e');
      return false;
    }
  }

  static Future<bool> incrementViews(String id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/videos/$id/views'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Erreur incrementViews: $e');
      return false;
    }
  }
}
