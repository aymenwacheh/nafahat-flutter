// lib/services/cmpl_user_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/cmpl_user_model.dart';

class CmplUserService {
  static String get baseUrl => ApiConfig.baseUrl;

  // ============================================================
  // VÉRIFIER SI L'UTILISATEUR A DÉJÀ COMPLÉTÉ SES INFOS
  // ============================================================
  static Future<bool> checkCmplExists({
    required int adherentId,
    required int formationId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/adherents/$adherentId/formations/$formationId/check-cmpl',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['exists'] == true;
      }
      return false;
    } catch (e) {
      print('❌ [CmplUserService] checkCmplExists erreur: $e');
      return false;
    }
  }

  // ============================================================
  // RÉCUPÉRER LES INFOS COMPLÉMENTAIRES
  // ============================================================
  static Future<CmplUser?> getCmplInfo({
    required int adherentId,
    required int formationId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/adherents/$adherentId/formations/$formationId/cmpl',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return CmplUser.fromJson(data['data']);
        }
        return null;
      }

      if (response.statusCode == 404) {
        return null;
      }

      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    } catch (e) {
      print('❌ [CmplUserService] getCmplInfo erreur: $e');
      return null;
    }
  }

  // ============================================================
  // SAUVEGARDER LES INFOS COMPLÉMENTAIRES
  // ============================================================
  static Future<Map<String, dynamic>> saveCmplInfo({
    required int adherentId,
    required int formationId,
    required CmplUser cmplUser,
  }) async {
    try {
      final body = jsonEncode(cmplUser.toJsonForApi());

      print('═' * 50);
      print('📤 [CmplUserService] Sauvegarde des infos');
      print('📤 AdherentId: $adherentId');
      print('📤 FormationId: $formationId');
      print('📤 Body: $body');
      print('═' * 50);

      final response = await http.post(
        Uri.parse(
          '$baseUrl/adherents/$adherentId/formations/$formationId/cmpl',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      );

      print('📥 [CmplUserService] Status: ${response.statusCode}');
      print('📥 [CmplUserService] Response: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'Informations sauvegardées',
            'cmplId': data['cmplId'],
          };
        }
        throw Exception(data['error'] ?? 'Erreur lors de la sauvegarde');
      }

      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    } catch (e) {
      print('❌ [CmplUserService] saveCmplInfo erreur: $e');
      rethrow;
    }
  }

  // ============================================================
  // METTRE À JOUR LES INFOS COMPLÉMENTAIRES
  // ============================================================
  static Future<Map<String, dynamic>> updateCmplInfo({
    required int adherentId,
    required int formationId,
    required CmplUser cmplUser,
  }) async {
    try {
      final body = jsonEncode(cmplUser.toJsonForApi());

      final response = await http.put(
        Uri.parse(
          '$baseUrl/adherents/$adherentId/formations/$formationId/cmpl',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'Informations mises à jour',
            'cmplId': data['cmplId'],
          };
        }
        throw Exception(data['error'] ?? 'Erreur lors de la mise à jour');
      }

      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    } catch (e) {
      print('❌ [CmplUserService] updateCmplInfo erreur: $e');
      rethrow;
    }
  }

  // ============================================================
  // MÉTHODE UNIFIÉE : SAUVEGARDE OU MISE À JOUR
  // ============================================================
  static Future<Map<String, dynamic>> saveOrUpdateCmplInfo({
    required int adherentId,
    required int formationId,
    required CmplUser cmplUser,
  }) async {
    // Vérifier si les infos existent déjà
    final exists = await checkCmplExists(
      adherentId: adherentId,
      formationId: formationId,
    );

    if (exists) {
      return await updateCmplInfo(
        adherentId: adherentId,
        formationId: formationId,
        cmplUser: cmplUser,
      );
    } else {
      return await saveCmplInfo(
        adherentId: adherentId,
        formationId: formationId,
        cmplUser: cmplUser,
      );
    }
  }

  // ============================================================
  // VÉRIFIER SI LA FORMATION EST RELIGIEUSE (CATÉGORIE ID = 1)
  // ============================================================
  static bool isFormationReligieuse(int? categorieId) {
    return categorieId == 1;
  }

  // ============================================================
  // OPTIONS POUR LES DROPDOWNS
  // ============================================================

  /// Options pour le niveau de mémorisation
  static List<Map<String, dynamic>> getNiveauMemorisationOptions(
    bool isArabic,
  ) {
    return [
      {'value': 'debutant', 'label': isArabic ? 'مبتدئ' : 'Débutant'},
      {'value': 'moyen', 'label': isArabic ? 'متوسط' : 'Moyen'},
      {'value': 'avance', 'label': isArabic ? 'متقدم' : 'Avancé'},
      {'value': 'expert', 'label': isArabic ? 'خبير' : 'Expert'},
      {'value': 'autre', 'label': isArabic ? 'أخرى' : 'Autre'},
    ];
  }

  /// Options pour le rythme de mémorisation hebdomadaire
  static List<Map<String, dynamic>> getRythmeMemorisationOptions(
    bool isArabic,
  ) {
    return [
      {'value': '1_sourate', 'label': isArabic ? 'سورة واحدة' : '1 sourate'},
      {'value': '2_sourates', 'label': isArabic ? 'سورتين' : '2 sourates'},
      {'value': '3_sourates', 'label': isArabic ? '3 سور' : '3 sourates'},
      {'value': '5_sourates', 'label': isArabic ? '5 سور' : '5 sourates'},
      {'value': '10_sourates', 'label': isArabic ? '10 سور' : '10 sourates'},
      {
        'value': 'juz_par_semaine',
        'label': isArabic ? 'جزء في الأسبوع' : 'Juz par semaine',
      },
      {'value': 'autre', 'label': isArabic ? 'أخرى' : 'Autre'},
    ];
  }

  /// Options pour la riwaya souhaitée
  static List<Map<String, dynamic>> getRiwayaOptions(bool isArabic) {
    return [
      {'value': 'hafs', 'label': isArabic ? 'حفص عن عاصم' : 'Hafs'},
      {'value': 'warch', 'label': isArabic ? 'ورش عن نافع' : 'Warch'},
      {'value': 'qaloun', 'label': isArabic ? 'قالون عن نافع' : 'Qaloun'},
      {'value': 'autre', 'label': isArabic ? 'أخرى' : 'Autre'},
    ];
  }

  /// Options pour le type de lecture du Mushaf
  static List<Map<String, dynamic>> getLectureMushafOptions(bool isArabic) {
    return [
      {
        'value': 'madinah',
        'label': isArabic ? 'مصحف المدينة' : 'Mushaf de Médine',
      },
      {'value': 'tajwid', 'label': isArabic ? 'مصحف التجويد' : 'Mushaf Tajwid'},
      {
        'value': 'ecriture_othmani',
        'label': isArabic ? 'الرسم العثماني' : 'Écriture Othmani',
      },
      {'value': 'autre', 'label': isArabic ? 'أخرى' : 'Autre'},
    ];
  }

  /// Options pour le créneau horaire
  static List<Map<String, dynamic>> getCreneauOptions(bool isArabic) {
    return [
      {'value': 'matin_8_10', 'label': isArabic ? '8h - 10h' : '8h - 10h'},
      {'value': 'matin_10_12', 'label': isArabic ? '10h - 12h' : '10h - 12h'},
      {
        'value': 'apres_midi_14_16',
        'label': isArabic ? '14h - 16h' : '14h - 16h',
      },
      {
        'value': 'apres_midi_16_18',
        'label': isArabic ? '16h - 18h' : '16h - 18h',
      },
      {'value': 'soir_18_20', 'label': isArabic ? '18h - 20h' : '18h - 20h'},
      {'value': 'soir_20_22', 'label': isArabic ? '20h - 22h' : '20h - 22h'},
      {'value': 'flexible', 'label': isArabic ? 'مرن' : 'Flexible'},
      {'value': 'autre', 'label': isArabic ? 'أخرى' : 'Autre'},
    ];
  }

  /// Options pour le parcours préféré
  static List<Map<String, dynamic>> getParcoursOptions(bool isArabic) {
    return [
      {'value': 'academique', 'label': isArabic ? 'أكاديمي' : 'Académique'},
      {'value': 'intensif', 'label': isArabic ? 'مكثف' : 'Intensif'},
      {'value': 'dynamique', 'label': isArabic ? 'ديناميكي' : 'Dynamique'},
      {'value': 'tranquille', 'label': isArabic ? 'هادئ' : 'Tranquille'},
      {'value': 'concentre', 'label': isArabic ? 'مركز' : 'Concentré'},
    ];
  }
}
