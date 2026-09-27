import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class PaymentNotification {
  final String id;
  final String type;
  final int? paymentId;
  final int? validationId;
  final int? formationId;
  final String? formationTitreFr;
  final String? formationTitreAr;
  final String? prochainPaiementDate;
  final String? dateValidation;
  final int? daysRemaining;
  final String messageFr;
  final String messageAr;

  const PaymentNotification({
    required this.id,
    required this.type,
    required this.messageFr,
    required this.messageAr,
    this.paymentId,
    this.validationId,
    this.formationId,
    this.formationTitreFr,
    this.formationTitreAr,
    this.prochainPaiementDate,
    this.dateValidation,
    this.daysRemaining,
  });

  factory PaymentNotification.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    return PaymentNotification(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      paymentId: toInt(json['payment_id']),
      validationId: toInt(json['validation_id']),
      formationId: toInt(json['formation_id']),
      formationTitreFr: json['formation_titre_fr']?.toString(),
      formationTitreAr: json['formation_titre_ar']?.toString(),
      prochainPaiementDate: json['prochain_paiement_date']?.toString(),
      dateValidation: json['date_validation']?.toString(),
      daysRemaining: toInt(json['days_remaining']),
      messageFr: json['message_fr']?.toString() ??
          'Nouvelle notification de paiement.',
      messageAr: json['message_ar']?.toString() ??
          'إشعار جديد بخصوص الدفع.',
    );
  }

  String title(bool isArabic) {
    if (type == 'payment_validated') {
      return isArabic ? 'تم تأكيد الدفع' : 'Paiement validé';
    }
    return isArabic ? 'موعد دفع قريب' : 'Échéance de paiement';
  }

  String message(bool isArabic) => isArabic ? messageAr : messageFr;

  String? formationTitle(bool isArabic) {
    final primary = isArabic ? formationTitreAr : formationTitreFr;
    final fallback = isArabic ? formationTitreFr : formationTitreAr;
    final value = (primary?.trim().isNotEmpty ?? false) ? primary : fallback;
    return (value?.trim().isNotEmpty ?? false) ? value!.trim() : null;
  }
}

class PaymentNotificationService {
  static const String _seenPrefix = 'payment_notifications_seen_';

  static Future<List<PaymentNotification>> getUnreadNotifications(
    String userId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.apiUrl}/payments/user/$userId/notifications'),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        debugPrint(
          '⚠️ Notifications paiement HTTP ${response.statusCode}: ${response.body}',
        );
        return [];
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
        return [];
      }

      final raw = decoded['data'];
      if (raw is! List) return [];

      final notifications = raw
          .whereType<Map>()
          .map(
            (item) => PaymentNotification.fromJson(
              item.cast<String, dynamic>(),
            ),
          )
          .where((item) => item.id.isNotEmpty)
          .toList();

      final prefs = await SharedPreferences.getInstance();
      final seen = (prefs.getStringList('$_seenPrefix$userId') ?? const <String>[])
          .toSet();

      return notifications.where((item) => !seen.contains(item.id)).toList();
    } catch (e) {
      debugPrint('⚠️ Erreur notifications paiement: $e');
      return [];
    }
  }

  static Future<void> markAsRead(
    String userId,
    Iterable<PaymentNotification> notifications,
  ) async {
    final ids = notifications.map((item) => item.id).where((id) => id.isNotEmpty);
    if (ids.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final key = '$_seenPrefix$userId';
    final seen = (prefs.getStringList(key) ?? const <String>[]).toSet();
    seen.addAll(ids);

    // On garde une taille raisonnable tout en conservant les notifications récentes.
    final values = seen.toList();
    final trimmed = values.length > 250
        ? values.sublist(values.length - 250)
        : values;
    await prefs.setStringList(key, trimmed);
  }
}
