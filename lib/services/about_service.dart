// lib/services/about_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nafahat/models/about_model.dart';
import 'package:nafahat/config/api_config.dart';

class AboutService {
  static const String baseUrl = ApiConfig.baseUrl;

  // Récupérer les données "À propos"
  static Future<AboutModel> getAbout() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/about'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return AboutModel.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Erreur lors du chargement');
        }
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      // En cas d'erreur, retourner les valeurs par défaut
      return AboutModel.defaultValues();
    }
  }

  // Créer ou mettre à jour les données "À propos"
  static Future<AboutModel> saveAbout(AboutModel about) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/about'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(about.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return AboutModel.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Erreur lors de la sauvegarde');
        }
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  // Mettre à jour les données "À propos"
  static Future<AboutModel> updateAbout(int id, AboutModel about) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/about/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(about.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return AboutModel.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Erreur lors de la mise à jour');
        }
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  // Supprimer les données "À propos" (soft delete ou hard delete selon besoin)
  static Future<bool> deleteAbout(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/about/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Vérifier si les données existent
  static Future<bool> exists() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/about/exists'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['exists'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
