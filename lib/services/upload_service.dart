// lib/services/upload_service.dart
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // ✅ AJOUTER CET IMPORT
import 'package:nafahat/config/api_config.dart';

class UploadService {
  static String get apiBaseUrl => ApiConfig.baseUrl;

  /// Upload une image depuis un fichier HTML (Web)
  static Future<Map<String, dynamic>> uploadImageWeb(html.File file) async {
    try {
      print('📤 [Upload Web] Début de l\'upload...');
      print('📄 [Upload Web] Nom du fichier: ${file.name}');
      print('📄 [Upload Web] Taille: ${file.size} bytes');
      print('📄 [Upload Web] Type MIME: ${file.type}');

      // Lire le fichier en bytes
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);

      await reader.onLoad.first;

      final bytes = reader.result as Uint8List;

      print('📄 [Upload Web] Bytes lus: ${bytes.length} bytes');

      // ✅ Déterminer l'extension du fichier
      String getExtension(String filename) {
        final parts = filename.split('.');
        return parts.length > 1 ? '.${parts.last}' : '.jpg';
      }

      // ✅ Obtenir le MediaType
      MediaType getMediaType(String filename, String mimeType) {
        // Si le type MIME est fourni et valide, l'utiliser
        if (mimeType.isNotEmpty && mimeType.contains('/')) {
          final parts = mimeType.split('/');
          if (parts.length == 2) {
            return MediaType(parts[0].trim(), parts[1].trim());
          }
        }

        // Sinon, déduire du nom de fichier
        final ext = getExtension(filename).toLowerCase();
        switch (ext) {
          case '.jpg':
          case '.jpeg':
            return MediaType('image', 'jpeg');
          case '.png':
            return MediaType('image', 'png');
          case '.gif':
            return MediaType('image', 'gif');
          case '.webp':
            return MediaType('image', 'webp');
          case '.svg':
            return MediaType('image', 'svg+xml');
          case '.bmp':
            return MediaType('image', 'bmp');
          default:
            return MediaType('image', 'jpeg'); // Valeur par défaut
        }
      }

      // ✅ Créer le MediaType
      final mediaType = getMediaType(file.name, file.type);
      print(
        '📄 [Upload Web] MediaType: ${mediaType.type}/${mediaType.subtype}',
      );

      // Créer une requête multipart
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiBaseUrl/upload/image'),
      );

      // ✅ Ajouter le fichier avec le bon MediaType
      final filename = file.name.isNotEmpty ? file.name : 'image.jpg';

      var multipartFile = http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: filename,
        contentType: mediaType, // ✅ Maintenant c'est un MediaType
      );

      request.files.add(multipartFile);

      // Ajouter les headers
      request.headers['Accept'] = 'application/json';

      // Envoyer la requête
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      print('📤 [Upload Web] Status: ${response.statusCode}');
      print('📤 [Upload Web] Response: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(responseBody);
      } else {
        // Meilleure gestion des erreurs
        try {
          final errorData = json.decode(responseBody);
          throw Exception(
            errorData['message'] ??
                errorData['error'] ??
                'Upload failed: ${response.statusCode}',
          );
        } catch (_) {
          throw Exception('Upload failed: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('❌ [Upload Web] Erreur: $e');
      rethrow;
    }
  }

  /// Upload avec fallback sur l'endpoint auto
  static Future<Map<String, dynamic>> uploadImageWebAuto(html.File file) async {
    try {
      print('📤 [Upload Web Auto] Début de l\'upload...');

      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);

      await reader.onLoad.first;

      final bytes = reader.result as Uint8List;

      // ✅ MediaType par défaut
      final mediaType = MediaType('image', 'jpeg');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiBaseUrl/upload/image-auto'),
      );

      var multipartFile = http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: file.name.isNotEmpty ? file.name : 'image.jpg',
        contentType: mediaType,
      );

      request.files.add(multipartFile);
      request.headers['Accept'] = 'application/json';

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      print('📤 [Upload Web Auto] Status: ${response.statusCode}');
      print('📤 [Upload Web Auto] Response: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(responseBody);
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [Upload Web Auto] Erreur: $e');
      rethrow;
    }
  }

  /// Upload avec détection automatique (essaye plusieurs endpoints)
  static Future<Map<String, dynamic>> uploadImageSmart(html.File file) async {
    try {
      // Essayer d'abord l'endpoint standard
      try {
        return await uploadImageWeb(file);
      } catch (e) {
        print('⚠️ [Upload] Endpoint standard échoué, tentative avec auto...');
        // Si ça échoue, essayer l'endpoint auto
        return await uploadImageWebAuto(file);
      }
    } catch (e) {
      print('❌ [Upload] Tous les endpoints ont échoué: $e');
      rethrow;
    }
  }

  /// Upload depuis des bytes (alternative)
  static Future<Map<String, dynamic>> uploadImageBytes(
    Uint8List bytes,
    String filename,
  ) async {
    try {
      print('📤 [Upload Bytes] Début de l\'upload...');

      // ✅ MediaType par défaut
      final mediaType = MediaType('image', 'jpeg');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiBaseUrl/upload/image'),
      );

      var multipartFile = http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: filename.isNotEmpty ? filename : 'image.jpg',
        contentType: mediaType,
      );

      request.files.add(multipartFile);
      request.headers['Accept'] = 'application/json';

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      print('📤 [Upload Bytes] Status: ${response.statusCode}');
      print('📤 [Upload Bytes] Response: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(responseBody);
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [Upload Bytes] Erreur: $e');
      rethrow;
    }
  }
}
