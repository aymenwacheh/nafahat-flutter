// lib/services/bull_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nafahat/models/bull_model.dart';
import 'package:nafahat/config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BullService {
  // ✅ Utilisation de ApiConfig au lieu de l'URL codée en dur
  static String get apiBaseUrl => ApiConfig.apiUrl;
  static const String _storageKey = 'bulls_data';

  // ============================================================
  // RÉCUPÉRER TOUS LES BULLS
  // ============================================================
  static Future<List<BullModel>> getBulls() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/bulls'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> bullsData = data['data'] ?? [];
          final bulls = bullsData.map((json) => BullModel.fromJson(json)).toList();
          await _saveToCache(bulls);
          return bulls;
        }
      }
      return await _loadFromCache();
    } catch (e) {
      print('❌ [BULLS] Erreur chargement: $e');
      return await _loadFromCache();
    }
  }

  // ============================================================
  // AJOUTER UN BULL
  // ============================================================
  static Future<bool> addBull(BullModel bull) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/bulls'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(bull.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('❌ [BULLS] Erreur ajout: $e');
      return false;
    }
  }

  // ============================================================
  // SUPPRIMER UN BULL
  // ============================================================
  static Future<bool> deleteBull(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$apiBaseUrl/bulls/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('❌ [BULLS] Erreur suppression: $e');
      return false;
    }
  }

  // ============================================================
  // METTRE À JOUR UN BULL
  // ============================================================
  static Future<bool> updateBull(BullModel bull) async {
    try {
      final response = await http.put(
        Uri.parse('$apiBaseUrl/bulls/${bull.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(bull.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('❌ [BULLS] Erreur mise à jour: $e');
      return false;
    }
  }

  // ============================================================
  // RÉORGANISER L'ORDRE DES BULLS
  // ✅ NOUVELLE MÉTHODE AJOUTÉE
  // ============================================================
  static Future<bool> reorderBulls(List<String> orderedIds) async {
    try {
      print('🔄 [BULLS] Réorganisation des bulls...');
      print('   📋 Ordre: $orderedIds');
      
      final response = await http.post(
        Uri.parse('$apiBaseUrl/bulls/reorder'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'orderedIds': orderedIds}),
      );

      print('📥 [BULLS] Response status: ${response.statusCode}');
      print('📥 [BULLS] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('❌ [BULLS] Erreur réorganisation: $e');
      return false;
    }
  }

  // ============================================================
  // CACHE LOCAL
  // ============================================================
  static Future<void> _saveToCache(List<BullModel> bulls) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = bulls.map((b) => b.toJson()).toList();
      await prefs.setString(_storageKey, json.encode(jsonList));
    } catch (e) {
      print('❌ [BULLS] Erreur cache: $e');
    }
  }

  static Future<List<BullModel>> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(_storageKey);
      if (data != null && data.isNotEmpty) {
        final List<dynamic> jsonList = json.decode(data);
        return jsonList.map((json) => BullModel.fromJson(json)).toList();
      }
    } catch (e) {
      print('❌ [BULLS] Erreur chargement cache: $e');
    }
    return getDefaultBulls();
  }

  // ============================================================
  // DONNÉES PAR DÉFAUT
  // ============================================================
  static List<BullModel> getDefaultBulls() {
    return [
      BullModel(
        id: '1',
        title: 'Formations',
        titleAr: 'الدورات',
        titleFr: 'Formations',
        link: '/formations',
        backgroundColor: const Color(0xff0D443E),
        textColor: Colors.white,
        borderColor: const Color(0xffC4A46C),
        fontSize: 14,
        order: 0,
      ),
      BullModel(
        id: '2',
        title: 'Vidéos',
        titleAr: 'الفيديوهات',
        titleFr: 'Vidéos',
        link: '/videos',
        backgroundColor: const Color(0xffd57653),
        textColor: Colors.white,
        borderColor: const Color(0xffC4A46C),
        fontSize: 14,
        order: 1,
      ),
      BullModel(
        id: '3',
        title: 'À propos',
        titleAr: 'عن المنصة',
        titleFr: 'À propos',
        link: '/about',
        backgroundColor: const Color(0xff2c221e),
        textColor: Colors.white,
        borderColor: const Color(0xffC4A46C),
        fontSize: 14,
        order: 2,
      ),
    ];
  }
}