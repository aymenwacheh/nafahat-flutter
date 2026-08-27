// lib/services/paiement_validation_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/paiement_validation.dart';
import '../config/api_config.dart';

class PaiementValidationService {
  // ✅ Méthode pour construire l'URL correctement
  String _buildUrl(String path) {
    if (!path.startsWith('/')) {
      path = '/$path';
    }
    final String cleanPath = path.replaceFirst('/api/', '/');
    return '${ApiConfig.baseUrl}$cleanPath';
  }

  // ✅ Récupérer la liste paginée des paiements
  Future<Map<String, dynamic>> getPaginated({
    int page = 1,
    int perPage = 15,
    String? status,
    String? search,
    String sortBy = 'paiement_created_at', // ✅ Changé de 'pv.created_at'
    bool sortDesc = true,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'per_page': perPage.toString(),
      'sort_by': sortBy,
      'sort_desc': sortDesc.toString(),
      if (status != null && status != 'tous') 'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final uri = Uri.parse(
      _buildUrl('/api/admin/paiement-validation/list'),
    ).replace(queryParameters: queryParams);

    print('📡 [GET] ${uri.toString()}');

    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> items = data['data'] ?? [];
      return {
        'data': items.map((e) => PaiementValidation.fromJson(e)).toList(),
        'pagination':
            data['pagination'] ??
            {
              'total': 0,
              'totalPages': 1,
              'currentPage': page,
              'perPage': perPage,
            },
      };
    }

    print('❌ Erreur: ${response.statusCode} - ${response.body}');
    throw Exception('Erreur: ${response.statusCode}');
  }

  // ✅ Récupérer les statistiques
  Future<Map<String, dynamic>> getStats() async {
    final uri = Uri.parse(_buildUrl('/api/admin/paiement-validation/stats'));
    print('📡 [GET] ${uri.toString()}');

    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }

    print('❌ Erreur stats: ${response.statusCode} - ${response.body}');
    throw Exception('Erreur stats: ${response.statusCode}');
  }

  // ✅ Mettre à jour le statut d'un paiement
  Future<void> updateStatus(
    int id,
    String statut, {
    String? commentaire,
  }) async {
    final uri = Uri.parse(_buildUrl('/api/admin/paiement-validation/$id'));
    print('📡 [PUT] ${uri.toString()}');
    print('📦 Body: {"statut":"$statut","commentaire":"$commentaire"}');

    final response = await http.put(
      uri,
      headers: await _getHeaders(),
      body: json.encode({
        'statut': statut,
        if (commentaire != null && commentaire.isNotEmpty)
          'commentaire': commentaire,
      }),
    );

    print('📡 [PUT] Response: ${response.statusCode}');

    if (response.statusCode != 200) {
      print('❌ Erreur update: ${response.statusCode} - ${response.body}');
      throw Exception('Erreur: ${response.statusCode}');
    }
  }

  // ✅ Récupérer les validations d'un paiement
  Future<List<PaiementValidation>> getByPaiement(int paiementId) async {
    final uri = Uri.parse(
      _buildUrl('/api/admin/paiement-validation/paiement/$paiementId'),
    );
    print('📡 [GET] ${uri.toString()}');

    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> items = data['data'] ?? [];
      return items.map((e) => PaiementValidation.fromJson(e)).toList();
    }

    throw Exception('Erreur: ${response.statusCode}');
  }

  // ✅ Récupérer la dernière validation d'un paiement
  Future<PaiementValidation?> getLastByPaiement(int paiementId) async {
    final uri = Uri.parse(
      _buildUrl('/api/admin/paiement-validation/paiement/$paiementId/last'),
    );
    print('📡 [GET] ${uri.toString()}');

    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['data'] != null) {
        return PaiementValidation.fromJson(data['data']);
      }
      return null;
    }

    throw Exception('Erreur: ${response.statusCode}');
  }

  // ✅ Créer une validation
  Future<int> create({
    required int paiementId,
    String statut = 'en_attente',
    String? commentaire,
  }) async {
    final uri = Uri.parse(_buildUrl('/api/admin/paiement-validation'));
    print('📡 [POST] ${uri.toString()}');

    final response = await http.post(
      uri,
      headers: await _getHeaders(),
      body: json.encode({
        'paiement_id': paiementId,
        'statut': statut,
        if (commentaire != null) 'commentaire': commentaire,
      }),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return data['data']['id'];
    }

    throw Exception('Erreur: ${response.statusCode}');
  }

  // ✅ Supprimer une validation
  Future<void> delete(int id) async {
    final uri = Uri.parse(_buildUrl('/api/admin/paiement-validation/$id'));
    print('📡 [DELETE] ${uri.toString()}');

    final response = await http.delete(uri, headers: await _getHeaders());

    if (response.statusCode != 200) {
      throw Exception('Erreur: ${response.statusCode}');
    }
  }

  // ✅ Headers pour les requêtes
  Future<Map<String, String>> _getHeaders() async {
    return {'Content-Type': 'application/json', 'Accept': 'application/json'};
  }
}
