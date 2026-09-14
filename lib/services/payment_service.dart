// lib/services/payment_service.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:nafahat/config/api_config.dart';
import 'upload_service.dart';

class PaymentService {
  static String get baseUrl => ApiConfig.apiUrl;

  // ============================================================
  // INITIATION DU PAIEMENT
  // ============================================================

  static Future<Map<String, dynamic>> initiatePayment({
    required String formationId,
    required String userId,
    required String currency,
  }) async {
    try {
      print('🔵 [PaymentService] Initiation paiement...');
      print('   📋 formationId: $formationId');
      print('   📋 userId: $userId');
      print('   📋 currency: $currency');

      final url = '$baseUrl/payments/initiate';
      print('   📋 URL: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'formation_id': formationId,
          'user_id': userId,
          'currency': currency,
        }),
      );

      print('🔵 [PaymentService] Response status: ${response.statusCode}');
      print('🔵 [PaymentService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
          error['message'] ?? 'Erreur lors de l\'initiation du paiement',
        );
      }
    } catch (e) {
      print('❌ [PaymentService] Erreur initiatePayment: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================
  // CONFIRMATION DU PAIEMENT (avec type de paiement)
  // ============================================================

  static Future<Map<String, dynamic>> confirmPayment({
    required String paymentId,
    required String modalite,
    String? typePaiement,
    double? montantAPayer,
    int? nombreMois,
    double? montantMensuel,
  }) async {
    try {
      print('🔵 [PaymentService] Confirmation paiement...');
      print('   📋 paymentId: $paymentId');
      print('   📋 modalite: $modalite');
      print('   📋 typePaiement: $typePaiement');
      print('   📋 montantAPayer: $montantAPayer');
      print('   📋 nombreMois: $nombreMois');
      print('   📋 montantMensuel: $montantMensuel');

      final url = '$baseUrl/payments/confirm';
      print('   📋 URL: $url');

      final Map<String, dynamic> body = {
        'paymentId': paymentId,
        'modalite': modalite,
      };

      if (typePaiement != null) body['type_paiement'] = typePaiement;
      if (montantAPayer != null) body['montant_a_payer'] = montantAPayer;
      if (nombreMois != null) body['nombre_mois'] = nombreMois;
      if (montantMensuel != null) body['montant_mensuel'] = montantMensuel;

      print('   📋 Body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('🔵 [PaymentService] confirmPayment response: ${response.statusCode}');
      print('🔵 [PaymentService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur de confirmation');
      }
    } catch (e) {
      print('❌ [PaymentService] Erreur confirmPayment: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================
  // UPLOAD DE LA QUITTANCE (initiale)
  // ============================================================

  static Future<Map<String, dynamic>> uploadQuittance({
    required String paymentId,
    required dynamic fileData,
    required String fileName,
  }) async {
    try {
      print('🔵 [PaymentService] Upload quittance...');
      print('   📋 paymentId: $paymentId');
      print('   📋 fileName: $fileName');
      print('   📋 Platform: ${kIsWeb ? "Web" : "Mobile/Desktop"}');

      return await UploadService.uploadQuittance(
        fileData: fileData,
        fileName: fileName,
        paymentId: paymentId,
      );
    } catch (e) {
      print('❌ [PaymentService] Erreur uploadQuittance: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================
  // RÉCUPÉRATION DES PAIEMENTS D'UN UTILISATEUR
  // ============================================================

  static Future<List<Map<String, dynamic>>> getUserPayments(
    String userId,
  ) async {
    try {
      print('🔵 [PaymentService] Récupération paiements utilisateur: $userId');

      final url = '$baseUrl/payments/user/$userId';
      print('   📋 URL: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> payments = data['data'] ?? [];
        return payments.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        print('❌ Erreur: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ [PaymentService] Erreur getUserPayments: $e');
      return [];
    }
  }

  // ============================================================
  // RÉCUPÉRATION DES PAIEMENTS D'UNE FORMATION
  // ============================================================

  static Future<Map<String, dynamic>> getFormationPayments(
    String formationId,
  ) async {
    try {
      print('🔵 [PaymentService] Récupération paiements formation: $formationId');

      final url = '$baseUrl/payments/formation/$formationId';
      print('   📋 URL: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [PaymentService] Erreur getFormationPayments: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================
  // STATISTIQUES
  // ============================================================

  static Future<Map<String, dynamic>> getStats() async {
    try {
      print('🔵 [PaymentService] Récupération statistiques');

      final url = '$baseUrl/payments/stats';
      print('   📋 URL: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [PaymentService] Erreur getStats: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================
  // MISE À JOUR DU STATUT
  // ============================================================

  static Future<Map<String, dynamic>> updateStatus({
    required String paymentId,
    required String statut,
    String? commentaire,
  }) async {
    try {
      print('🔵 [PaymentService] Mise à jour statut: $paymentId -> $statut');

      final url = '$baseUrl/payments/status/$paymentId';
      print('   📋 URL: $url');

      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'statut': statut, 'commentaire': commentaire}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur de mise à jour');
      }
    } catch (e) {
      print('❌ [PaymentService] Erreur updateStatus: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================
  // RÉCUPÉRATION D'UN PAIEMENT PAR ID
  // ============================================================

  static Future<Map<String, dynamic>?> getPaymentById(String paymentId) async {
    try {
      print('🔵 [PaymentService] Récupération paiement: $paymentId');

      final url = '$baseUrl/payments/$paymentId';
      print('   📋 URL: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      print('❌ [PaymentService] Erreur getPaymentById: $e');
      return null;
    }
  }

  // ============================================================
  // ✅ NOUVELLE MÉTHODE : Soumettre une tranche mensuelle
  // POST /api/payments/:paymentId/tranche
  // ============================================================

  static Future<Map<String, dynamic>> soumettreTranche({
    required String paymentId,
    required double montantTranche,
    String? quittanceUrl,
  }) async {
    try {
      print('🔵 [PaymentService] Soumission tranche...');
      print('   📋 paymentId: $paymentId');
      print('   📋 montantTranche: $montantTranche');
      print('   📋 quittanceUrl: $quittanceUrl');

      final url = '$baseUrl/payments/$paymentId/tranche';
      print('   📋 URL: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'montant_tranche': montantTranche,
          if (quittanceUrl != null && quittanceUrl.isNotEmpty)
            'quittance_url': quittanceUrl,
        }),
      );

      print('🔵 [PaymentService] Response: ${response.statusCode}');
      print('🔵 [PaymentService] Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur soumission tranche');
      }
    } catch (e) {
      print('❌ [PaymentService] Erreur soumettreTranche: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================
  // ✅ NOUVELLE MÉTHODE : Upload de la quittance de tranche
  // POST /api/payments/:paymentId/upload-tranche
  // ============================================================

  static Future<Map<String, dynamic>> uploadTrancheQuittance({
    required String paymentId,
    required dynamic fileData,
    required String fileName,
  }) async {
    try {
      print('🔵 [PaymentService] Upload quittance tranche...');
      print('   📋 paymentId: $paymentId');
      print('   📋 fileName: $fileName');
      print('   📋 Platform: ${kIsWeb ? "Web" : "Mobile"}');

      final url = '$baseUrl/payments/$paymentId/upload-tranche';
      print('   📋 URL: $url');

      var request = http.MultipartRequest('POST', Uri.parse(url));

      if (kIsWeb) {
        final bytes = fileData as Uint8List;
        request.files.add(
          http.MultipartFile.fromBytes(
            'quittance',
            bytes,
            filename: fileName,
          ),
        );
      } else {
        final file = fileData as File;
        request.files.add(
          await http.MultipartFile.fromPath('quittance', file.path),
        );
      }

      request.fields['paymentId'] = paymentId;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('🔵 [PaymentService] Response: ${response.statusCode}');
      print('🔵 [PaymentService] Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur upload quittance');
      }
    } catch (e) {
      print('❌ [PaymentService] Erreur uploadTrancheQuittance: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================
  // ✅ NOUVELLE MÉTHODE : Valider une tranche (admin)
  // POST /api/payments/:paymentId/valider-tranche
  // ============================================================

  static Future<Map<String, dynamic>> validerTranche({
    required String paymentId,
  }) async {
    try {
      print('🔵 [PaymentService] Validation tranche: $paymentId');

      final url = '$baseUrl/payments/$paymentId/valider-tranche';
      print('   📋 URL: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      print('🔵 [PaymentService] Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur validation tranche');
      }
    } catch (e) {
      print('❌ [PaymentService] Erreur validerTranche: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}