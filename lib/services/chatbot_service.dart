// lib/services/chatbot_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chatbot_models.dart';
import 'training_service.dart'; // 👈 AJOUT

class ChatbotService {
  // ✅ Utiliser la même baseUrl que TrainingService
  final String baseUrl = TrainingService.apiBaseUrl;

  Future<Map<String, dynamic>> askQuestion(
    String message, {
    String langue = 'fr',
  }) async {
    try {
      final url = '$baseUrl/chatbot/ask';

      print('═══════════════════════════════════════════════════');
      print('📍 CHATBOT REQUEST');
      print('📌 BaseUrl: $baseUrl');
      print('📌 URL Complète: $url');
      print('📌 Message: $message');
      print('📌 Langue: $langue');
      print('═══════════════════════════════════════════════════');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'message': message, 'langue': langue}),
      );

      print('📌 Réponse Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {'success': true, 'data': data['data']};
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Erreur inconnue',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Erreur ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Erreur Chatbot: $e');
      return {'success': false, 'message': 'Erreur: ${e.toString()}'};
    }
  }

  Future<List<ChatCategory>> getCategories() async {
    try {
      final url = '$baseUrl/chatbot/categories';
      print('📍 Chatbot categories URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List)
              .map((item) => ChatCategory.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
