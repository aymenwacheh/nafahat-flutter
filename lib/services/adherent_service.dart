// lib/services/adherent_service.dart
import 'dart:async' show TimeoutException;
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/adherent.dart';
import '../models/enfant.dart';
import '../models/acces_adherent.dart';
import '../config/api_config.dart';

class AdherentService {
  // ✅ Utilisation de ApiConfig
  static String get apiBaseUrl => ApiConfig.baseUrl;

  // ============================================================
  // AUTHENTIFICATION
  // ============================================================

  static Future<Map<String, dynamic>> login(
    String whatsapp,
    String motDePasse,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$apiBaseUrl/adherents/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'whatsapp': whatsapp, 'motDePasse': motDePasse}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
        throw Exception(data['error'] ?? 'Identifiants invalides');
      }

      if (response.statusCode == 401) {
        throw Exception('Identifiants invalides');
      }

      throw Exception('Erreur ${response.statusCode}');
    } catch (e) {
      print('❌ Erreur login: $e');
      rethrow;
    }
  }

  // ============================================================
  // INSCRIPTION - VERSION FINALE
  // ============================================================

  static Future<Map<String, dynamic>> inscrireAdherent(
    Adherent adherent,
    List<Enfant> enfants,
  ) async {
    try {
      final url = Uri.parse('$apiBaseUrl/adherents/inscrire');

      // 🐛 Debug complet
      print('═' * 50);
      print('📤 [Inscription] URL: $url');
      print('📤 [Inscription] Adherent:');
      print('   - Nom: ${adherent.nomPrenom}');
      print('   - WhatsApp: ${adherent.whatsapp}');
      print('   - Email: ${adherent.email}');
      print('   - Pays: ${adherent.pays}');
      print('   - Ville: ${adherent.ville}');
      print('📤 [Inscription] Enfants: ${enfants.length}');

      final body = jsonEncode({
        'adherent': adherent.toJson(),
        'enfants': enfants.map((e) => e.toJson()).toList(),
      });

      print('📤 [Inscription] Body: $body');
      print('═' * 50);

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      print('═' * 50);
      print('📥 [Inscription] Status: ${response.statusCode}');
      print('📥 [Inscription] Body: ${response.body}');
      print('═' * 50);

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'adherentId': data['adherentId'],
            'motDePasse': data['motDePasse'],
            'whatsappUrl': data['whatsappUrl'],
            'credentials': data['credentials'],
          };
        }
        throw Exception(data['error'] ?? 'Erreur lors de l\'inscription');
      }

      // Gestion des erreurs HTTP
      if (response.statusCode == 400) {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Données invalides');
      }

      if (response.statusCode == 500) {
        throw Exception('Erreur serveur (500). Vérifiez les logs du backend.');
      }

      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    } on http.ClientException catch (e) {
      print('❌ [Inscription] Erreur de connexion: $e');
      throw Exception(
        '⚠️ Impossible de contacter le serveur.\n\n'
        'Vérifiez que le serveur backend est démarré:\n'
        '1. cd nafahat_api\n'
        '2. npm start\n'
        '3. Le serveur doit être sur http://localhost:3000',
      );
    } on TimeoutException {
      throw Exception('⏱️ Le serveur ne répond pas. Vérifiez votre connexion.');
    } catch (e) {
      print('❌ [Inscription] Erreur: $e');
      rethrow;
    }
  }

  // ============================================================
  // RÉCUPÉRATION DES ADHÉRENTS
  // ============================================================

  static Future<List<Adherent>> getAdherents() async {
    try {
      final response = await http
          .get(
            Uri.parse('$apiBaseUrl/adherents'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> list = data['data'];
          return list.map((json) => Adherent.fromJson(json)).toList();
        }
        throw Exception(data['error'] ?? 'Erreur chargement');
      }
      throw Exception('Erreur ${response.statusCode}');
    } catch (e) {
      print('❌ Erreur getAdherents: $e');
      rethrow;
    }
  }

  // ============================================================
  // RÉCUPÉRATION D'UN ADHÉRENT PAR ID
  // ============================================================

  static Future<Adherent> getAdherentById(int id) async {
    try {
      final response = await http
          .get(
            Uri.parse('$apiBaseUrl/adherents/$id'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Adherent.fromJson(data['data']);
        }
        throw Exception(data['error'] ?? 'Adhérent non trouvé');
      }
      throw Exception('Erreur ${response.statusCode}');
    } catch (e) {
      print('❌ Erreur getAdherentById: $e');
      rethrow;
    }
  }

  // ============================================================
  // MISE À JOUR D'UN ADHÉRENT - CORRIGÉE
  // ============================================================

  static Future<void> updateAdherent(int id, Adherent adherent) async {
    try {
      final url = Uri.parse('$apiBaseUrl/adherents/$id');

      print('═' * 50);
      print('📤 [Update] URL: $url');
      print('📤 [Update] ID: $id');
      print('📤 [Update] Data: ${jsonEncode(adherent.toJson())}');
      print('═' * 50);

      final response = await http
          .put(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(adherent.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      print('📥 [Update] Status: ${response.statusCode}');
      print('📥 [Update] Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return;
        }
        throw Exception(data['error'] ?? 'Erreur mise à jour');
      }

      if (response.statusCode == 404) {
        throw Exception('Adhérent non trouvé');
      }

      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    } catch (e) {
      print('❌ Erreur updateAdherent: $e');
      rethrow;
    }
  }

  // ============================================================
  // SUPPRESSION D'UN ADHÉRENT
  // ============================================================

  static Future<void> deleteAdherent(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$apiBaseUrl/adherents/$id'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Erreur suppression');
      }
    } catch (e) {
      print('❌ Erreur deleteAdherent: $e');
      rethrow;
    }
  }

  // ============================================================
  // RÉINITIALISATION DU MOT DE PASSE
  // ============================================================

  static Future<Map<String, dynamic>> resetPassword(int adherentId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$apiBaseUrl/adherents/$adherentId/reset-password'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'newMotDePasse': data['newMotDePasse'],
            'whatsappUrl': data['whatsappUrl'],
          };
        }
        throw Exception(data['error'] ?? 'Erreur réinitialisation');
      }
      throw Exception('Erreur ${response.statusCode}');
    } catch (e) {
      print('❌ Erreur resetPassword: $e');
      rethrow;
    }
  }

  // ============================================================
  // RÉCUPÉRATION DES IDENTIFIANTS
  // ============================================================

  static Future<AccesAdherent> getAdherentCredentials(int adherentId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$apiBaseUrl/adherents/$adherentId/credentials'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return AccesAdherent.fromJson(data['data']);
        }
        throw Exception(data['error'] ?? 'Identifiants non trouvés');
      }
      throw Exception('Erreur ${response.statusCode}');
    } catch (e) {
      print('❌ Erreur getAdherentCredentials: $e');
      rethrow;
    }
  }
}
