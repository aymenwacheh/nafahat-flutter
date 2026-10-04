// lib/services/SectionOrderService.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nafahat/models/SectionOrderModel.dart';
import 'package:nafahat/services/appearance_config_service.dart';

class SectionOrderService {
  static const String _storageKey = 'sections_order';
  static const String _remoteKey = 'landing_sections';

  /// Permet à la LandingPage déjà ouverte de se rafraîchir immédiatement
  /// après un enregistrement depuis l'administration.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static void _notifyChanged() {
    revision.value = revision.value + 1;
  }

  static List<SectionOrderModel> _parseSections(dynamic raw) {
    if (raw is! List) return <SectionOrderModel>[];

    final sections = raw
        .whereType<Map>()
        .map((item) => SectionOrderModel.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .where((section) => section.sectionKey.trim().isNotEmpty)
        .toList();

    sections.sort((a, b) => a.order.compareTo(b.order));

    // Les anciennes sauvegardes pouvaient contenir des id vides/dupliqués,
    // ce qui casse ReorderableListView (clés identiques).
    final usedIds = <String>{};
    final normalized = <SectionOrderModel>[];
    for (var i = 0; i < sections.length; i++) {
      final section = sections[i];
      var id = section.id.trim();
      if (id.isEmpty || usedIds.contains(id)) {
        id = '${section.sectionKey}_${i}_${section.order}';
      }
      usedIds.add(id);
      normalized.add(section.copyWith(id: id, order: i));
    }
    return normalized;
  }

  // ============================================================
  // CHARGER LES SECTIONS
  // ============================================================
  static Future<List<SectionOrderModel>> loadSections() async {
    final prefs = await SharedPreferences.getInstance();

    // 1) Le serveur est la source de vérité. Ainsi l'ordre défini dans
    // l'administration est également visible après refresh / autre session.
    try {
      final remote = await AppearanceConfigService.load(_remoteKey);
      final remoteSections = _parseSections(remote?['sections']);

      if (remoteSections.isNotEmpty) {
        await prefs.setString(
          _storageKey,
          jsonEncode(remoteSections.map((s) => s.toJson()).toList()),
        );
        return remoteSections;
      }
    } catch (e) {
      debugPrint('❌ [SECTIONS] Erreur chargement serveur: $e');
    }

    // 2) Cache local si le serveur est temporairement indisponible.
    try {
      final data = prefs.getString(_storageKey);
      if (data != null && data.isNotEmpty) {
        final cached = _parseSections(jsonDecode(data));
        if (cached.isNotEmpty) return cached;
      }
    } catch (e) {
      debugPrint('❌ [SECTIONS] Erreur chargement cache: $e');
    }

    // 3) Valeurs par défaut au premier lancement.
    return getDefaultSections();
  }

  // ============================================================
  // SAUVEGARDER LES SECTIONS
  // ============================================================
  static Future<bool> saveSections(List<SectionOrderModel> sections) async {
    try {
      // On normalise ici aussi pour garantir un ordre cohérent, même si
      // l'appelant oublie de le faire.
      final normalized = <SectionOrderModel>[
        for (var i = 0; i < sections.length; i++)
          sections[i].copyWith(order: i),
      ];
      final jsonList = normalized.map((s) => s.toJson()).toList();

      // Toujours mettre à jour le cache local pour un rafraîchissement immédiat.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(jsonList));

      // Puis persister côté serveur pour que le landing conserve le même ordre
      // après rechargement et sur les autres appareils.
      final remoteSaved = await AppearanceConfigService.save(
        _remoteKey,
        {'sections': jsonList},
      );

      _notifyChanged();
      return remoteSaved;
    } catch (e) {
      debugPrint('❌ [SECTIONS] Erreur sauvegarde: $e');
      return false;
    }
  }

  // ============================================================
  // SECTIONS PAR DÉFAUT
  // ============================================================
  static List<SectionOrderModel> getDefaultSections() {
    final data = PredefinedSections.getDefaultSectionsData();
    return data.map((json) => SectionOrderModel.fromJson(json)).toList();
  }

  // ============================================================
  // RÉINITIALISER
  // ============================================================
  static Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await AppearanceConfigService.delete(_remoteKey);
    _notifyChanged();
  }
}
