// lib/services/training_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/training_model.dart';
import '../config/api_config.dart';

class TrainingService {
  static const String _storageKey = 'trainings';
  static String get apiBaseUrl => ApiConfig.baseUrl;

  // =============================================
  // MÉTHODES LOCALES (offline)
  // =============================================

  static Future<void> saveTrainingsLocally(
    List<TrainingModel> trainings,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonList =
        trainings.map((t) => t.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  static Future<List<TrainingModel>> getTrainingsLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_storageKey);
    if (data == null || data.isEmpty) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((json) => TrainingModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Erreur de décodage local: $e');
      return [];
    }
  }

  static Future<void> addTrainingLocally(TrainingModel training) async {
    final trainings = await getTrainingsLocally();
    trainings.add(training);
    await saveTrainingsLocally(trainings);
  }

  static Future<void> deleteTrainingLocally(String id) async {
    final trainings = await getTrainingsLocally();
    trainings.removeWhere((t) => t.id == id);
    await saveTrainingsLocally(trainings);
  }

  static Future<void> clearLocalCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    debugPrint('Cache local vidé');
  }

  // =============================================
  // MÉTHODES API - FORMATIONS
  // =============================================

  static Future<List<TrainingModel>> getTrainings() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/formations/active'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> formationsJson = data['data'];
        final trainings =
            formationsJson
                .map((json) => TrainingModel.fromApiJson(json))
                .toList();
        await saveTrainingsLocally(trainings);
        return trainings;
      } else {
        debugPrint('Erreur API: ${response.statusCode}');
        return await getTrainingsLocally();
      }
    } catch (e) {
      debugPrint('Erreur réseau: $e');
      return await getTrainingsLocally();
    }
  }

  static Future<List<TrainingModel>> getPromoFormations() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/formations/promos'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> formationsJson = data['data'];
        return formationsJson
            .map((json) => TrainingModel.fromApiJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Erreur récupération promotions: $e');
      return [];
    }
  }

  static Future<List<TrainingModel>> getFormationsByCategorie(
    int categorieId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/formations/categorie/$categorieId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> formationsJson = data['data'];
        return formationsJson
            .map((json) => TrainingModel.fromApiJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Erreur récupération par catégorie: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getFormationById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/formations/$id'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      debugPrint('Erreur récupération formation: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getAllFormationsAdmin() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/formations/admin/all'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('❌ Erreur getAllFormationsAdmin: $e');
      return [];
    }
  }

  static Future<bool> createTraining(Map<String, dynamic> requestBody) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/formations'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );
      final Map<String, dynamic> data = json.decode(response.body);
      return data['success'] == true;
    } catch (e) {
      debugPrint('Erreur création formation: $e');
      return false;
    }
  }

  static Future<bool> updateTraining(
    String id,
    Map<String, dynamic> requestBody,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$apiBaseUrl/formations/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );
      final Map<String, dynamic> data = json.decode(response.body);
      return data['success'] == true;
    } catch (e) {
      debugPrint('Erreur mise à jour formation: $e');
      return false;
    }
  }

  static Future<bool> deleteTraining(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$apiBaseUrl/formations/$id'),
        headers: {'Content-Type': 'application/json'},
      );
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['success'] == true) {
        await deleteTrainingLocally(id);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erreur suppression formation: $e');
      return false;
    }
  }

  static Future<int> getTrainingsCount() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/formations/active'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> formationsJson = data['data'];
        return formationsJson.length;
      }
      return 0;
    } catch (e) {
      debugPrint('Erreur comptage formations: $e');
      return 0;
    }
  }

  // =============================================
  // MÉTHODES API - CIBLES
  // =============================================

  static Future<List<Map<String, dynamic>>> getCibles() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/cibles'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      debugPrint('❌ Erreur getCibles - Status: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('❌ Erreur getCibles: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getCibleById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/cibles/$id'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Erreur getCibleById: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> createCible(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/cibles'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Erreur createCible: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> updateCible(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$apiBaseUrl/cibles/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Erreur updateCible: $e');
      return null;
    }
  }

  static Future<bool> deleteCible(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$apiBaseUrl/cibles/$id'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Erreur deleteCible: $e');
      return false;
    }
  }

  // =============================================
  // MÉTHODES API - SOUS-CATÉGORIES
  // =============================================

  static Future<List<Map<String, dynamic>>> getSousCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/sous-categories'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      debugPrint('❌ Erreur getSousCategories - Status: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('❌ Erreur getSousCategories: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getSousCategorieById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/sous-categories/$id'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Erreur getSousCategorieById: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> createSousCategorie(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/sous-categories'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Erreur createSousCategorie: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> updateSousCategorie(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$apiBaseUrl/sous-categories/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Erreur updateSousCategorie: $e');
      return null;
    }
  }

  static Future<bool> deleteSousCategorie(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$apiBaseUrl/sous-categories/$id'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Erreur deleteSousCategorie: $e');
      return false;
    }
  }

  // =============================================
  // MÉTHODES API - DONNÉES DE RÉFÉRENCE
  // =============================================

  static Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/categories'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Erreur chargement catégories: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getFormateurs() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/formateurs'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Erreur chargement formateurs: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getDurees() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/duree'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Erreur chargement durées: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getTypesFormation() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/types-formation'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Erreur chargement types de formation: $e');
      return [];
    }
  }

  // =============================================
  // MÉTHODES D'UPLOAD D'IMAGES
  // =============================================

  // ✅ Méthode unique Web + Mobile : à partir de bytes bruts (via
  // image_picker + XFile.readAsBytes(), qui fonctionne sur les deux
  // plateformes). Plus besoin de dart:io File ni de dart:html.
  static Future<Map<String, dynamic>> uploadImageBytes(
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      debugPrint('📤 [Upload] Début de l\'upload (bytes)...');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiBaseUrl/upload/image'),
      );

      final ext = fileName.split('.').last.toLowerCase();
      const mimeMap = {
        'jpg': 'jpeg',
        'jpeg': 'jpeg',
        'png': 'png',
        'webp': 'webp',
        'gif': 'gif',
      };
      final subtype = mimeMap[ext] ?? 'jpeg';

      var multipartFile = http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: fileName,
        contentType: MediaType('image', subtype),
      );

      request.files.add(multipartFile);
      request.headers['Accept'] = 'application/json';

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      debugPrint('📤 [Upload] Status: ${response.statusCode}');
      debugPrint('📤 [Upload] Response: $responseBody');

      if (response.statusCode == 200) {
        return json.decode(responseBody);
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Upload] Erreur: $e');
      rethrow;
    }
  }
  // lib/services/training_service.dart

  // Ajoutez cette méthode après uploadImageBytes
  static Future<Map<String, dynamic>> uploadImageBytesAlt(
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      debugPrint('📤 [Upload Alt] Début de l\'upload...');

      // Utiliser la route /upload au lieu de /upload/image
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiBaseUrl/upload'), // ← Changement ici
      );

      final ext = fileName.split('.').last.toLowerCase();
      const mimeMap = {
        'jpg': 'jpeg',
        'jpeg': 'jpeg',
        'png': 'png',
        'webp': 'webp',
        'gif': 'gif',
      };
      final subtype = mimeMap[ext] ?? 'jpeg';

      var multipartFile = http.MultipartFile.fromBytes(
        'image', // ← Vérifiez le nom du champ attendu par le serveur
        bytes,
        filename: fileName,
        contentType: MediaType('image', subtype),
      );

      request.files.add(multipartFile);
      request.headers['Accept'] = 'application/json';

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      debugPrint('📤 [Upload Alt] Status: ${response.statusCode}');
      debugPrint('📤 [Upload Alt] Response: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(responseBody);
        // Le format de réponse peut être différent
        return {
          'success': true,
          'image_url': data['imageUrl'] ?? data['data']?['url'] ?? data['url'],
        };
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Upload Alt] Erreur: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> uploadImage(File imageFile) async {
    try {
      debugPrint('📤 [Upload] Début de l\'upload...');

      final bytes = await imageFile.readAsBytes();
      final fileName = imageFile.path.split('/').last;

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiBaseUrl/upload/image'),
      );

      // ✅ Déterminer le Content-Type réel à partir de l'extension.
      // Sans ça, http.MultipartFile.fromBytes envoie
      // "application/octet-stream" par défaut et le serveur (mobile
      // uniquement, le web passe par un autre chemin) rejette le fichier.
      final ext = fileName.split('.').last.toLowerCase();
      const mimeMap = {
        'jpg': 'jpeg',
        'jpeg': 'jpeg',
        'png': 'png',
        'webp': 'webp',
        'gif': 'gif',
      };
      final subtype = mimeMap[ext] ?? 'jpeg';

      var multipartFile = http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: fileName,
        contentType: MediaType('image', subtype),
      );

      request.files.add(multipartFile);
      request.headers['Accept'] = 'application/json';

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      debugPrint('📤 [Upload] Status: ${response.statusCode}');
      debugPrint('📤 [Upload] Response: $responseBody');

      if (response.statusCode == 200) {
        return json.decode(responseBody);
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Upload] Erreur: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> uploadXFileImage(dynamic xFile) async {
    try {
      debugPrint('📤 [Upload] Début de l\'upload XFile...');

      final bytes = await xFile.readAsBytes();
      final String fileName = xFile.name;

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiBaseUrl/upload/image'),
      );

      final ext = fileName.split('.').last.toLowerCase();
      const mimeMap = {
        'jpg': 'jpeg',
        'jpeg': 'jpeg',
        'png': 'png',
        'webp': 'webp',
        'gif': 'gif',
      };
      final subtype = mimeMap[ext] ?? 'jpeg';

      var multipartFile = http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: fileName,
        contentType: MediaType('image', subtype),
      );

      request.files.add(multipartFile);
      request.headers['Accept'] = 'application/json';

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      debugPrint('📤 [Upload] Status: ${response.statusCode}');
      debugPrint('📤 [Upload] Response: $responseBody');

      if (response.statusCode == 200) {
        return json.decode(responseBody);
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Upload] Erreur: $e');
      rethrow;
    }
  }

  static Future<bool> deleteImage(String filename) async {
    try {
      final response = await http.delete(
        Uri.parse('$apiBaseUrl/upload/image/$filename'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ [Delete] Erreur: $e');
      return false;
    }
  }

  // =============================================
  // ANCIENNE MÉTHODE (conservée pour compatibilité)
  // =============================================
  static Future<String?> uploadImageOld(String imagePath) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiBaseUrl/upload'),
      );
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonData = json.decode(responseData);
      if (response.statusCode == 200 && jsonData['success'] == true) {
        return jsonData['imageUrl'];
      }
      return null;
    } catch (e) {
      debugPrint('Erreur upload image: $e');
      return null;
    }
  }
  // lib/services/training_service.dart

  static Future<TrainingModel?> getTraining(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/formations/$id'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return TrainingModel.fromApiJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Erreur getTraining: $e');
      return null;
    }
  }
}
