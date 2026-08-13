// lib/services/verification_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/adherent.dart';
import '../models/enfant.dart';

class VerificationService {
  static String get baseUrl => ApiConfig.baseUrl;

  // ============================================================
  // ENVOYER LE CODE DE VÉRIFICATION
  // ============================================================
  static Future<void> sendVerificationCode({
    required String email,
    required String whatsapp,
    required String nomPrenom,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/adherents/send-verification-code'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': email,
              'whatsapp': whatsapp,
              'nomPrenom': nomPrenom,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (data['success'] == true) {
          // En développement, on peut afficher le code
          if (data['code'] != null) {
            print('📧 Code de vérification: ${data['code']}');
          }
          return;
        }
        throw Exception(data['error'] ?? 'Erreur lors de l\'envoi du code');
      }

      throw Exception(
        'Erreur ${response.statusCode}: ${data['error'] ?? 'Inconnue'}',
      );
    } catch (e) {
      print('❌ [sendVerificationCode] Erreur: $e');
      rethrow;
    }
  }

  // ============================================================
  // VÉRIFIER LE CODE ET CRÉER L'UTILISATEUR
  // ============================================================
  static Future<Map<String, dynamic>> verifyCodeAndCreateUser({
    required String email,
    required String code,
    required Adherent adherent,
    required List<Enfant> enfants,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/adherents/verify-code-and-create'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': email,
              'code': code,
              'adherent': adherent.toJson(),
              'enfants': enfants.map((e) => e.toJson()).toList(),
            }),
          )
          .timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        if (data['success'] == true) {
          return {
            'success': true,
            'adherentId': data['adherentId'],
            'motDePasse': data['motDePasse'],
            'credentials': data['credentials'],
          };
        }
        throw Exception(
          data['error'] ?? 'Erreur lors de la création du compte',
        );
      }

      if (response.statusCode == 409) {
        final fieldErrors = data['fieldErrors'] ?? {};
        throw Exception(
          jsonEncode({
            'statusCode': 409,
            'fieldErrors': fieldErrors,
            'error': data['error'] ?? 'Informations déjà utilisées',
          }),
        );
      }

      throw Exception(data['error'] ?? 'Erreur ${response.statusCode}');
    } catch (e) {
      print('❌ [verifyCodeAndCreateUser] Erreur: $e');
      rethrow;
    }
  }
}
