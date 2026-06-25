// lib/services/adherent_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/adherent.dart';
import '../models/enfant.dart';
import '../models/acces_adherent.dart';

class AdherentService {
  static const String apiBaseUrl = 'http://localhost:3000/api';

  // ============================================================
  // AUTHENTIFICATION
  // ============================================================

  /// Authentifie un adhérent avec son numéro WhatsApp et son mot de passe
  static Future<Map<String, dynamic>> login(
    String whatsapp,
    String motDePasse,
  ) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/adherents/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'whatsapp': whatsapp, 'motDePasse': motDePasse}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data['data'];
      }
    }
    throw Exception('Identifiants invalides');
  }

  /// Récupère les identifiants d'un adhérent par son ID
  static Future<AccesAdherent> getAdherentCredentials(int adherentId) async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/adherents/$adherentId/credentials'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return AccesAdherent.fromJson(data['data']);
      }
    }
    throw Exception('Identifiants non trouvés');
  }

  /// Réinitialise le mot de passe d'un adhérent
  static Future<Map<String, dynamic>> resetPassword(int adherentId) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/adherents/$adherentId/reset-password'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return {
          'newMotDePasse': data['newMotDePasse'],
          'whatsappUrl': data['whatsappUrl'],
        };
      }
    }
    throw Exception('Erreur réinitialisation du mot de passe');
  }

  // ============================================================
  // GESTION DES ADHÉRENTS
  // ============================================================

  /// Récupère la liste de tous les adhérents
  static Future<List<Adherent>> getAdherents() async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/adherents'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        final List<dynamic> list = data['data'];
        return list.map((json) => Adherent.fromJson(json)).toList();
      }
    }
    throw Exception('Erreur chargement adhérents');
  }

  /// Récupère un adhérent par son ID
  static Future<Adherent> getAdherentById(int id) async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/adherents/$id'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return Adherent.fromJson(data['data']);
      }
    }
    throw Exception('Adhérent non trouvé');
  }

  /// Met à jour un adhérent
  static Future<void> updateAdherent(int id, Adherent adherent) async {
    final response = await http.put(
      Uri.parse('$apiBaseUrl/adherents/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(adherent.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur mise à jour');
    }
  }

  /// Supprime un adhérent
  static Future<void> deleteAdherent(int id) async {
    final response = await http.delete(
      Uri.parse('$apiBaseUrl/adherents/$id'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur suppression');
    }
  }

  // ============================================================
  // INSCRIPTION (avec création automatique des accès)
  // ============================================================

  /// Inscrit un nouvel adhérent avec ses enfants
  /// Retourne les identifiants générés (whatsapp, motDePasse)
  static Future<Map<String, dynamic>> inscrireAdherent(
    Adherent adherent,
    List<Enfant> enfants,
  ) async {
    final url = Uri.parse('$apiBaseUrl/adherents/inscrire');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'adherent': adherent.toJson(),
        'enfants': enfants.map((e) => e.toJson()).toList(),
      }),
    );

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
    }
    throw Exception('Erreur lors de l\'inscription: ${response.body}');
  }
}
