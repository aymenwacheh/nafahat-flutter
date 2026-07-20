// lib/providers/chatbot_provider.dart
import 'package:flutter/material.dart';

class ChatbotProvider extends ChangeNotifier {
  bool _isVisible = true;

  bool get isVisible => _isVisible;

  void show() {
    if (!_isVisible) {
      _isVisible = true;
      notifyListeners();
      print('🤖 Chatbot: Affiché');
    }
  }

  void hide() {
    if (_isVisible) {
      _isVisible = false;
      notifyListeners();
      print('🤖 Chatbot: Caché');
    }
  }

  void toggle() {
    _isVisible = !_isVisible;
    notifyListeners();
    print('🤖 Chatbot: ${_isVisible ? 'Affiché' : 'Caché'}');
  }

  void setVisibility(bool visible) {
    if (_isVisible != visible) {
      _isVisible = visible;
      notifyListeners();
      print('🤖 Chatbot: ${_isVisible ? 'Affiché' : 'Caché'}');
    }
  }
}
