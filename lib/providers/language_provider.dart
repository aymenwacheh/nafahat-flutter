// lib/providers/language_provider.dart
import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  bool _isArabic = true;

  // 👈 CONSTRUCTEUR : Initialiser avec la valeur par défaut
  LanguageProvider() {
    // Sauvegarder la préférence si nécessaire
    _isArabic = true;
  }

  bool get isArabic => _isArabic;

  Locale get locale => _isArabic ? const Locale('ar') : const Locale('fr');

  void toggleLanguage() {
    _isArabic = !_isArabic;
    notifyListeners();
  }

  void setLanguage(bool arabic) {
    if (_isArabic != arabic) {
      _isArabic = arabic;
      notifyListeners();
    }
  }

  String get languageCode => _isArabic ? 'ar' : 'fr';
}
