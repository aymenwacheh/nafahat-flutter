// lib/providers/language_provider.dart
import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  bool _isArabic = false;

  bool get isArabic => _isArabic;

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
}
