// lib/services/training_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
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
      print('Erreur de décodage local: $e');
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
    print('Cache local vidé');
  }

  // =============================================
  // MÉTHODES API
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
        print('Erreur API: ${response.statusCode}');
        return await getTrainingsLocally();
      }
    } catch (e) {
      print('Erreur réseau: $e');
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
      print('Erreur récupération promotions: $e');
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
      print('Erreur récupération par catégorie: $e');
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
      print('Erreur création formation: $e');
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
      print('Erreur mise à jour formation: $e');
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
      print('Erreur suppression formation: $e');
      return false;
    }
  }

  // =============================================
  // MÉTHODE POUR UPLOADER UNE IMAGE (CORRIGÉE)
  // =============================================
  static Future<Map<String, dynamic>> uploadImage(File imageFile) async {
    try {
      print('📤 [Upload] Début de l\'upload...');

      // Lire les bytes du fichier
      final bytes = await imageFile.readAsBytes();

      // Créer une requête multipart
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiBaseUrl/upload/image'),
      );

      // Ajouter le fichier image avec les bytes
      var multipartFile = http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: imageFile.path.split('/').last,
      );

      request.files.add(multipartFile);

      // Ajouter les headers
      request.headers['Accept'] = 'application/json';

      // Envoyer la requête
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      print('📤 [Upload] Status: ${response.statusCode}');
      print('📤 [Upload] Response: $responseBody');

      if (response.statusCode == 200) {
        return json.decode(responseBody);
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [Upload] Erreur: $e');
      rethrow;
    }
  }

  // =============================================
  // MÉTHODE POUR UPLOADER UNE IMAGE (VIA XFile)
  // =============================================
  static Future<Map<String, dynamic>> uploadXFileImage(dynamic xFile) async {
    try {
      print('📤 [Upload] Début de l\'upload XFile...');

      // Lire les bytes du XFile
      final bytes = await xFile.readAsBytes();
      final String fileName = xFile.name;

      // Créer une requête multipart
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiBaseUrl/upload/image'),
      );

      // Ajouter le fichier image avec les bytes
      var multipartFile = http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: fileName,
      );

      request.files.add(multipartFile);

      // Ajouter les headers
      request.headers['Accept'] = 'application/json';

      // Envoyer la requête
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      print('📤 [Upload] Status: ${response.statusCode}');
      print('📤 [Upload] Response: $responseBody');

      if (response.statusCode == 200) {
        return json.decode(responseBody);
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [Upload] Erreur: $e');
      rethrow;
    }
  }

  // =============================================
  // MÉTHODE POUR SUPPRIMER UNE IMAGE
  // =============================================
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
      print('❌ [Delete] Erreur: $e');
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
      print('Erreur upload image: $e');
      return null;
    }
  }

  // =============================================
  // DONNÉES DE RÉFÉRENCE
  // =============================================

  static Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/categories'),
        headers: {'Content-Type': 'application/json'},
      );
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

  static Future<List<Map<String, dynamic>>> getFormateurs() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/formateurs'),
        headers: {'Content-Type': 'application/json'},
      );
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

  static Future<List<Map<String, dynamic>>> getDurees() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/duree'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      }
      return [];
    } catch (e) {
      print('Erreur chargement durées: $e');
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
        return List<Map<String, dynamic>>.from(data['data']);
      }
      return [];
    } catch (e) {
      print('Erreur chargement types de formation: $e');
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
      print('Erreur récupération formation: $e');
      return null;
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
      print('Erreur comptage formations: $e');
      return 0;
    }
  }
}
