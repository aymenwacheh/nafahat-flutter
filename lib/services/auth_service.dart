// lib/services/auth_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nafahat/services/adherent_service.dart';
import 'package:nafahat/services/AdminUserService.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _userIdKey = 'user_id';

  // ============================================================
  // GESTION DU TOKEN ET DE L'UTILISATEUR
  // ============================================================

  // Vérifier si l'utilisateur est connecté
  static Future<bool> isAuthenticated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final userId = prefs.getInt(_userIdKey);
      return token != null && token.isNotEmpty && userId != null;
    } catch (e) {
      return false;
    }
  }

  // Récupérer l'ID de l'utilisateur connecté
  static Future<int?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_userIdKey);
    } catch (e) {
      return null;
    }
  }

  // Récupérer les données de l'utilisateur
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_userKey);
      if (userData != null && userData.isNotEmpty) {
        return json.decode(userData) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Sauvegarder les données de l'utilisateur après connexion
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, json.encode(userData));
      if (userData['id'] != null) {
        await prefs.setInt(_userIdKey, userData['id']);
      }
      if (userData['token'] != null) {
        await prefs.setString(_tokenKey, userData['token']);
      }
    } catch (e) {
      print('❌ Erreur sauvegarde user data: $e');
    }
  }

  // Sauvegarder le token
  static Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (e) {
      print('❌ Erreur sauvegarde token: $e');
    }
  }

  // Sauvegarder l'ID utilisateur
  static Future<void> saveUserId(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_userIdKey, userId);
    } catch (e) {
      print('❌ Erreur sauvegarde user ID: $e');
    }
  }

  // Déconnexion
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
      await prefs.remove(_userIdKey);
    } catch (e) {
      print('❌ Erreur déconnexion: $e');
    }
  }

  // ============================================================
  // AUTHENTIFICATION - UTILISE ADHERENT_SERVICE
  // ============================================================

  // Connexion avec WhatsApp et mot de passe
  static Future<Map<String, dynamic>> login(
    String whatsapp,
    String motDePasse,
  ) async {
    try {
      // Utiliser le service existant
      final result = await AdherentService.login(whatsapp, motDePasse);

      if (result.isNotEmpty) {
        // Sauvegarder les données
        await saveUserData(result);
        if (result['id'] != null) {
          await saveUserId(result['id']);
        }
        return result;
      }
      throw Exception('Erreur de connexion');
    } catch (e) {
      print('❌ Erreur login: $e');
      rethrow;
    }
  }

  // ============================================================
  // VÉRIFICATION WHATSAPP - UTILISE ADMIN_USER_SERVICE
  // ============================================================

  // Vérifier si un numéro WhatsApp existe
  static Future<bool> checkWhatsappExists(String whatsapp) async {
    try {
      // Utiliser AdminUserService (qui utilise le bon endpoint)
      return await AdminUserService.checkWhatsapp(whatsapp);
    } catch (e) {
      print('❌ Erreur vérification WhatsApp: $e');
      return false;
    }
  }

  // ============================================================
  // RÉCUPÉRATION UTILISATEUR PAR WHATSAPP - UTILISE ADHERENT_SERVICE
  // ============================================================

  // Récupérer l'utilisateur par WhatsApp pour le paiement
  static Future<Map<String, dynamic>?> getUserByWhatsapp(
    String whatsapp,
  ) async {
    try {
      // Récupérer tous les adhérents et filtrer
      final adherents = await AdherentService.getAdherents();

      // Chercher l'adhérent avec le WhatsApp correspondant
      final found = adherents.firstWhere(
        (adherent) => adherent.whatsapp == whatsapp,
        orElse: () => throw Exception('Adhérent non trouvé'),
      );

      // Retourner les données au format Map
      return {
        'id': found.id,
        'whatsapp': found.whatsapp,
        'nomPrenom': found.nomPrenom,
        'email': found.email,
        'pays': found.pays,
        'ville': found.ville,
        'dateNaissance': found.dateNaissance.toIso8601String(),
        'genre': found.genre,
        'sourceConnaissance': found.sourceConnaissance,
        'sourceAutreDetail': found.sourceAutreDetail,
        'objectif': found.objectif,
        'suggestions': found.suggestions,
        'accordPublication': found.accordPublication,
      };
    } catch (e) {
      print('❌ Erreur récupération utilisateur par WhatsApp: $e');
      return null;
    }
  }

  // Récupérer un adhérent par son ID
  static Future<Map<String, dynamic>?> getAdherentById(int id) async {
    try {
      final adherent = await AdherentService.getAdherentById(id);
      return {
        'id': adherent.id,
        'whatsapp': adherent.whatsapp,
        'nomPrenom': adherent.nomPrenom,
        'email': adherent.email,
        'pays': adherent.pays,
        'ville': adherent.ville,
        'dateNaissance': adherent.dateNaissance.toIso8601String(),
        'genre': adherent.genre,
        'sourceConnaissance': adherent.sourceConnaissance,
        'sourceAutreDetail': adherent.sourceAutreDetail,
        'objectif': adherent.objectif,
        'suggestions': adherent.suggestions,
        'accordPublication': adherent.accordPublication,
      };
    } catch (e) {
      print('❌ Erreur récupération adhérent par ID: $e');
      return null;
    }
  }

  // ============================================================
  // AIDE POUR LE PAIEMENT
  // ============================================================

  // Obtenir l'ID de l'utilisateur connecté pour le paiement
  static Future<String?> getUserIdForPayment() async {
    try {
      final userId = await getUserId();
      if (userId != null) {
        return userId.toString();
      }

      // Si pas d'ID, essayer de récupérer depuis les données utilisateur
      final userData = await getUserData();
      if (userData != null) {
        return userData['id']?.toString() ??
            userData['adherent_id']?.toString();
      }
      return null;
    } catch (e) {
      print('❌ Erreur récupération ID pour paiement: $e');
      return null;
    }
  }

  // Vérifier si l'utilisateur connecté peut payer
  static Future<bool> canUserPay() async {
    try {
      final isAuth = await isAuthenticated();
      if (!isAuth) return false;

      final userId = await getUserId();
      return userId != null;
    } catch (e) {
      return false;
    }
  }
}
