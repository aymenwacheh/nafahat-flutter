// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/training_model.dart';
import '../config/api_config.dart'; // <-- Importer la config

class ApiService {
  // Utiliser ApiConfig.baseUrl au lieu de la constante en dur
  static String get baseUrl => ApiConfig.baseUrl;

  // Récupérer toutes les formations
  static Future<List<TrainingModel>> getFormations() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/formations/active'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> formationsJson = data['data'];
        return formationsJson
            .map((json) => TrainingModel.fromApiJson(json))
            .toList();
      } else {
        throw Exception('Erreur lors du chargement des formations');
      }
    } catch (e) {
      print('Erreur API: $e');
      return [];
    }
  }

  // Récupérer les formations en promotion
  static Future<List<TrainingModel>> getPromoFormations() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/formations/promos'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> formationsJson = data['data'];
        return formationsJson
            .map((json) => TrainingModel.fromApiJson(json))
            .toList();
      } else {
        throw Exception('Erreur lors du chargement des promotions');
      }
    } catch (e) {
      print('Erreur API: $e');
      return [];
    }
  }

  // Créer une formation
  static Future<bool> createFormation(
    Map<String, dynamic> formationData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/formations'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(formationData),
      );

      final Map<String, dynamic> data = json.decode(response.body);
      return data['success'] == true;
    } catch (e) {
      print('Erreur création formation: $e');
      return false;
    }
  }

  // Upload d'image
  static Future<String?> uploadImage(String imagePath) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonData = json.decode(responseData);

      if (response.statusCode == 200 && jsonData['success'] == true) {
        return jsonData['imageUrl'];
      }
      return null;
    } catch (e) {
      print('Erreur upload image: $e');
      return null;
    }
  }

  // Récupérer les catégories
  static Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categories'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      }
      return [];
    } catch (e) {
      print('Erreur chargement catégories: $e');
      return [];
    }
  }

  // Récupérer les formateurs
  static Future<List<Map<String, dynamic>>> getFormateurs() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/formateurs'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      }
      return [];
    } catch (e) {
      print('Erreur chargement formateurs: $e');
      return [];
    }
  }
}
