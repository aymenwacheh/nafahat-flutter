// lib/services/SectionOrderService.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nafahat/models/SectionOrderModel.dart';

class SectionOrderService {
  static const String _storageKey = 'sections_order';

  // ============================================================
  // CHARGER LES SECTIONS
  // ============================================================
  static Future<List<SectionOrderModel>> loadSections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(_storageKey);
      
      if (data != null && data.isNotEmpty) {
        final List<dynamic> jsonList = json.decode(data);
        // ✅ Les icônes sont déjà des Strings dans le JSON
        return jsonList.map((json) => SectionOrderModel.fromJson(json)).toList();
      }
    } catch (e) {
      print('❌ [SECTIONS] Erreur chargement: $e');
    }
    
    // Retourner les sections par défaut
    return getDefaultSections();
  }

  // ============================================================
  // SAUVEGARDER LES SECTIONS
  // ============================================================
  static Future<void> saveSections(List<SectionOrderModel> sections) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = sections.map((s) => s.toJson()).toList();
      await prefs.setString(_storageKey, json.encode(jsonList));
    } catch (e) {
      print('❌ [SECTIONS] Erreur sauvegarde: $e');
    }
  }

  // ============================================================
  // SECTIONS PAR DÉFAUT
  // ============================================================
  static List<SectionOrderModel> getDefaultSections() {
    final data = PredefinedSections.getDefaultSectionsData();
    return data.map((json) => SectionOrderModel.fromJson(json)).toList();
  }

  // ============================================================
  // RÉINITIALISER
  // ============================================================
  static Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}