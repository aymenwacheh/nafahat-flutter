// lib/providers/about_provider.dart
import 'package:flutter/material.dart';
import 'package:nafahat/models/about_model.dart';
import 'package:nafahat/services/about_service.dart';

class AboutProvider extends ChangeNotifier {
  AboutModel? _about;
  bool _isLoading = false;
  String? _error;

  AboutModel? get about => _about;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _about != null;

  // Charger les données
  Future<void> loadAbout() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _about = await AboutService.getAbout();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sauvegarder les données
  Future<bool> saveAbout(AboutModel about) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final saved = await AboutService.saveAbout(about);
      _about = saved;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Mettre à jour les données
  Future<bool> updateAbout(AboutModel about) async {
    if (about.id == null) {
      return await saveAbout(about);
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await AboutService.updateAbout(about.id!, about);
      _about = updated;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Réinitialiser aux valeurs par défaut
  void resetToDefaults() {
    _about = AboutModel.defaultValues();
    notifyListeners();
  }

  // Vider les données
  void clear() {
    _about = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
