// lib/services/card_config_manager.dart
import 'package:flutter/material.dart';
import 'package:nafahat/models/card_config_model.dart';

class CardConfigManager {
  static final CardConfigManager _instance = CardConfigManager._internal();
  factory CardConfigManager() => _instance;
  CardConfigManager._internal();

  // ValueNotifier pour notifier les changements
  final ValueNotifier<CardConfig?> configNotifier = ValueNotifier(null);

  CardConfig? _currentConfig;

  CardConfig? get currentConfig => _currentConfig;

  void updateConfig(CardConfig newConfig) {
    _currentConfig = newConfig;
    configNotifier.value = newConfig;
  }

  void reset() {
    _currentConfig = CardConfig.defaultConfig();
    configNotifier.value = _currentConfig;
  }
}
