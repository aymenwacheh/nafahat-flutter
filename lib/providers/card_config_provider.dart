// lib/providers/card_config_provider.dart
import 'package:flutter/material.dart';
import 'package:nafahat/services/card_config_service.dart';

class CardConfigProvider extends ChangeNotifier {
  final CardConfigService _service = CardConfigService();

  CardConfig? _config;
  bool _isLoading = true;

  CardConfig? get config => _config;
  bool get isLoading => _isLoading;

  CardConfigProvider() {
    _loadConfig();
  }

  /// Charge la configuration depuis le service
  Future<void> _loadConfig() async {
    try {
      _isLoading = true;
      _config = await _service.loadConfig();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Erreur chargement provider: $e');
      _isLoading = false;
    }
  }

  /// Met à jour la configuration
  Future<bool> updateConfig(CardConfig newConfig) async {
    try {
      final success = await _service.saveConfig(newConfig);
      if (success) {
        _config = newConfig;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Erreur mise à jour config: $e');
      return false;
    }
  }

  /// Réinitialise la configuration
  Future<CardConfig> resetConfig() async {
    final defaultConfig = await _service.resetConfig();
    _config = defaultConfig;
    notifyListeners();
    return defaultConfig;
  }

  /// Vérifie si un champ est visible
  bool isFieldVisible(String fieldId) {
    return _config?.visibleFields.contains(fieldId) ?? false;
  }

  /// Récupère les champs visibles
  List<String> getVisibleFields() {
    return _config?.visibleFields ?? [];
  }

  /// Récupère le style du titre
  TextStyle getTitleStyle() {
    return _config?.getTitleStyle() ?? const TextStyle();
  }

  /// Récupère le style des libellés
  TextStyle getLabelStyle() {
    return _config?.getLabelStyle() ?? const TextStyle();
  }

  /// Récupère le style des valeurs
  TextStyle getValueStyle() {
    return _config?.getValueStyle() ?? const TextStyle();
  }

  /// Recharge la configuration depuis le stockage
  Future<void> refreshConfig() async {
    await _loadConfig();
  }
}
