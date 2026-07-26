// lib/services/admin_user_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/adherent.dart';
import '../models/enfant.dart';
import '../models/role.dart';

class AdminUserService {
  static const String baseUrl = ApiConfig.baseUrl;

  // ============================================================
  // RÉCUPÉRER LA LISTE DES RÔLES ✅ CORRIGÉ
  // ============================================================
  static Future<List<Role>> getRoles() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/adherents/roles'), // ✅ AJOUTÉ 'adherents/'
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> rolesJson = data['data'];
          return rolesJson.map((json) => Role.fromJson(json)).toList();
        }
        throw Exception(data['error'] ?? 'Erreur lors du chargement des rôles');
      }
      throw Exception('Erreur serveur: ${response.statusCode}');
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  // ============================================================
  // VÉRIFICATION WHATSAPP ✅ CORRIGÉ
  // ============================================================
  static Future<bool> checkWhatsapp(String whatsapp) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/adherents/check-whatsapp?whatsapp=${Uri.encodeComponent(whatsapp)}', // ✅ AJOUTÉ 'adherents/'
        ),
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

  // ============================================================
  // VÉRIFICATION EMAIL ✅ CORRIGÉ
  // ============================================================
  static Future<bool> checkEmail(String email) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/adherents/check-email?email=${Uri.encodeComponent(email)}', // ✅ AJOUTÉ 'adherents/'
        ),
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

  // ============================================================
  // CRÉATION D'UN UTILISATEUR PAR LE SUPER ADMIN ✅ CORRIGÉ
  // ============================================================
  static Future<Map<String, dynamic>> creerUtilisateur({
    required Adherent adherent,
    required List<Enfant> enfants,
    required int roleId,
    String? motDePassePersonnalise,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'adherent': adherent.toJson(),
        'enfants': enfants.map((e) => e.toJson()).toList(),
        'roleId': roleId,
        'motDePassePersonnalise': motDePassePersonnalise,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/adherents/users'), // ✅ AJOUTÉ 'adherents/'
        headers: {
          'Content-Type': 'application/json',
          // TODO: Ajouter le token d'authentification du super admin
          // 'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'Utilisateur créé avec succès',
            'userId': data['userId'],
            'motDePasse': data['motDePasse'],
            'identifiant': data['identifiant'],
            'credentials': data['credentials'],
          };
        }
        throw Exception(data['error'] ?? 'Erreur lors de la création');
      }

      if (response.statusCode == 409) {
        final fieldErrors = data['fieldErrors'] ?? {};
        throw Exception(
          json.encode({
            'statusCode': 409,
            'fieldErrors': fieldErrors,
            'error': data['error'] ?? 'Informations déjà utilisées',
          }),
        );
      }

      throw Exception(
        data['error'] ?? 'Erreur serveur: ${response.statusCode}',
      );
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================
  // CRÉATION D'UN UTILISATEUR AVEC RÔLE SPÉCIFIQUE (version simplifiée)
  // ============================================================
  static Future<Map<String, dynamic>> creerUtilisateurAvecRole({
    required String whatsapp,
    required String nomPrenom,
    required String pays,
    required String ville,
    String? email,
    DateTime? dateNaissance,
    String genre = 'homme',
    String sourceConnaissance = 'instagram',
    String? sourceAutreDetail,
    String? objectif,
    String? suggestions,
    bool accordPublication = false,
    required int roleId,
    List<Map<String, dynamic>> enfants = const [],
    String? motDePassePersonnalise,
  }) async {
    final adherent = Adherent(
      whatsapp: whatsapp,
      nomPrenom: nomPrenom,
      pays: pays,
      ville: ville,
      email: email ?? '',
      dateNaissance: dateNaissance ?? DateTime.now(),
      genre: genre,
      sourceConnaissance: sourceConnaissance,
      sourceAutreDetail: sourceAutreDetail,
      objectif: objectif,
      suggestions: suggestions,
      accordPublication: accordPublication,
    );

    final enfantsList =
        enfants
            .map(
              (e) => Enfant(
                nomPrenom: e['nomPrenom'] ?? '',
                dateNaissance: e['dateNaissance'] ?? DateTime.now(),
                genre: e['genre'] ?? 'homme',
                niveauTilawa: e['niveauTilawa'] ?? 'debutant',
                memorisation: e['memorisation'],
                memorisationAutreDetail: e['memorisationAutreDetail'],
                objectif: e['objectif'],
                accordInscription: e['accordInscription'] ?? false,
              ),
            )
            .toList();

    return await creerUtilisateur(
      adherent: adherent,
      enfants: enfantsList,
      roleId: roleId,
      motDePassePersonnalise: motDePassePersonnalise,
    );
  }
}
