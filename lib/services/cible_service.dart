// lib/services/cible_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nafahat/config/api_config.dart';
import 'package:nafahat/models/cible_model.dart';

class CibleService {
  static String get apiBaseUrl => ApiConfig.baseUrl;

  // =============================================
  // ✅ GET - Récupérer toutes les cibles
  // =============================================
  static Future<List<CibleModel>> getCibles() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/cibles'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> ciblesJson = data['data'];
          return ciblesJson.map((json) => CibleModel.fromJson(json)).toList();
        }
        return [];
      } else {
        print('❌ Erreur getCibles: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Erreur getCibles: $e');
      return [];
    }
  }

  // =============================================
  // ✅ GET - Récupérer une cible par ID
  // =============================================
  static Future<CibleModel?> getCibleById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/cibles/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          return CibleModel.fromJson(data['data']);
        }
        return null;
      } else {
        print('❌ Erreur getCibleById: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Erreur getCibleById: $e');
      return null;
    }
  }

  // =============================================
  // ✅ POST - Créer une nouvelle cible
  // =============================================
  static Future<CibleModel?> createCible(CibleModel cible) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/cibles'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(cible.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ Cible créée avec succès');
          return CibleModel.fromJson(data['data']);
        }
        return null;
      } else {
        print('❌ Erreur createCible: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Erreur createCible: $e');
      return null;
    }
  }

  // =============================================
  // ✅ PUT - Mettre à jour une cible
  // =============================================
  static Future<CibleModel?> updateCible(CibleModel cible) async {
    try {
      if (cible.id == null) {
        throw Exception('ID requis pour la mise à jour');
      }

      final response = await http.put(
        Uri.parse('$apiBaseUrl/cibles/${cible.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(cible.toJson()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ Cible mise à jour avec succès');
          return CibleModel.fromJson(data['data']);
        }
        return null;
      } else {
        print('❌ Erreur updateCible: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Erreur updateCible: $e');
      return null;
    }
  }

  // =============================================
  // ❌ DELETE - Supprimer une cible
  // =============================================
  static Future<bool> deleteCible(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$apiBaseUrl/cibles/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ Cible supprimée avec succès');
          return true;
        }
        return false;
      } else {
        print('❌ Erreur deleteCible: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Erreur deleteCible: $e');
      return false;
    }
  }
}
