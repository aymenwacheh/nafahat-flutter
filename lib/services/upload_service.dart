// lib/services/upload_service.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:nafahat/config/api_config.dart';

// ✅ Import pour Web uniquement
// Sur Mobile, ce fichier ne sera pas utilisé pour les méthodes Web
import 'dart:html' as html;

class UploadService {
  // ✅ Utiliser ApiConfig.apiUrl qui inclut déjà /api
  static String get apiBaseUrl => ApiConfig.apiUrl;

  // ============================================================
  // UPLOAD DE FICHIER (UNIFIÉ - WEB + MOBILE)
  // ============================================================

  static Future<Map<String, dynamic>> uploadFile({
    required dynamic fileData,
    required String fileName,
    required String fieldName,
    required String endpoint,
    Map<String, String>? additionalFields,
    String? mimeType,
  }) async {
    try {
      print('🔵 [UploadService] Upload de fichier...');
      print('   📋 fileName: $fileName');
      print('   📋 fieldName: $fieldName');
      print('   📋 endpoint: $endpoint');
      print('   📋 Platform: ${kIsWeb ? "Web" : "Mobile/Desktop"}');

      // ✅ URL complète : apiBaseUrl + endpoint
      // apiBaseUrl = http://localhost:3000/api
      // endpoint = /payments/upload-quittance
      // URL finale = http://localhost:3000/api/payments/upload-quittance
      final fullUrl = '$apiBaseUrl$endpoint';
      print('   📋 URL: $fullUrl');

      final String finalMimeType =
          mimeType ?? lookupMimeType(fileName) ?? 'application/octet-stream';
      print('   📋 MIME Type: $finalMimeType');

      var request = http.MultipartRequest('POST', Uri.parse(fullUrl));

      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      if (kIsWeb) {
        if (fileData is! Uint8List) {
          throw Exception('Format de fichier Web invalide. Attendu: Uint8List');
        }

        final multipartFile = http.MultipartFile.fromBytes(
          fieldName,
          fileData,
          filename: fileName,
          contentType: MediaType.parse(finalMimeType),
        );
        request.files.add(multipartFile);

        print('   📋 Upload Web: ${fileData.length} bytes');
      } else {
        if (fileData is! File) {
          throw Exception('Format de fichier Mobile invalide. Attendu: File');
        }

        if (!await fileData.exists()) {
          throw Exception('Le fichier n\'existe pas: ${fileData.path}');
        }

        final fileSize = await fileData.length();
        if (fileSize > 5 * 1024 * 1024) {
          throw Exception('Le fichier dépasse 5MB');
        }

        final multipartFile = await http.MultipartFile.fromPath(
          fieldName,
          fileData.path,
          contentType: MediaType.parse(finalMimeType),
        );
        request.files.add(multipartFile);

        print('   📋 Upload Mobile: $fileSize bytes');
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      print('🔵 [UploadService] Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(responseBody);
      } else {
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
      print('❌ [UploadService] Erreur: $e');
      rethrow;
    }
  }

  // ============================================================
  // UPLOAD D'IMAGE (SPÉCIFIQUE WEB)
  // ============================================================

  static Future<Map<String, dynamic>> uploadImageWeb(html.File file) async {
    try {
      print('📤 [Upload Web] Début de l\'upload...');
      print('📄 [Upload Web] Nom du fichier: ${file.name}');

      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;

      final bytes = reader.result as Uint8List;
      print('📄 [Upload Web] Bytes lus: ${bytes.length} bytes');

      return await uploadFile(
        fileData: bytes,
        fileName: file.name.isNotEmpty ? file.name : 'image.jpg',
        fieldName: 'image',
        endpoint: '/upload/image',
        mimeType: file.type.isNotEmpty ? file.type : null,
      );
    } catch (e) {
      print('❌ [Upload Web] Erreur: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> uploadImageWebAuto(html.File file) async {
    try {
      print('📤 [Upload Web Auto] Début de l\'upload...');

      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;

      final bytes = reader.result as Uint8List;

      return await uploadFile(
        fileData: bytes,
        fileName: file.name.isNotEmpty ? file.name : 'image.jpg',
        fieldName: 'image',
        endpoint: '/upload/image-auto',
        mimeType: file.type.isNotEmpty ? file.type : null,
      );
    } catch (e) {
      print('❌ [Upload Web Auto] Erreur: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> uploadImageSmart(html.File file) async {
    try {
      try {
        return await uploadImageWeb(file);
      } catch (e) {
        print('⚠️ [Upload] Endpoint standard échoué, tentative avec auto...');
        return await uploadImageWebAuto(file);
      }
    } catch (e) {
      print('❌ [Upload] Tous les endpoints ont échoué: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> uploadImageBytes(
    Uint8List bytes,
    String filename,
  ) async {
    return await uploadFile(
      fileData: bytes,
      fileName: filename.isNotEmpty ? filename : 'image.jpg',
      fieldName: 'image',
      endpoint: '/upload/image',
    );
  }

  // ============================================================
  // UPLOAD DE QUITTANCE
  // ============================================================

  static Future<Map<String, dynamic>> uploadQuittance({
    required dynamic fileData,
    required String fileName,
    required String paymentId,
  }) async {
    return await uploadFile(
      fileData: fileData,
      fileName: fileName,
      fieldName: 'quittance',
      endpoint: '/payments/upload-quittance', // ✅ Sans /api en trop
      additionalFields: {'paymentId': paymentId},
    );
  }
}
