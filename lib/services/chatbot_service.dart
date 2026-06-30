// lib/services/chatbot_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chatbot_models.dart';

class ChatbotService {
  final String baseUrl;

  ChatbotService({required this.baseUrl});

  Future<Map<String, dynamic>> askQuestion(
    String message, {
    String langue = 'fr',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/chatbot/ask'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'message': message, 'langue': langue}),
      );

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
        return {'success': false, 'message': 'Erreur de connexion au serveur'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur: ${e.toString()}'};
    }
  }

  Future<List<ChatCategory>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/chatbot/categories'),
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
