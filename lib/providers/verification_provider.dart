// lib/providers/verification_provider.dart
import 'package:flutter/material.dart';

class VerificationProvider extends ChangeNotifier {
  String? _email;
  String? _whatsapp;
  String? _nomPrenom;
  bool _isVerified = false;

  String? get email => _email;
  String? get whatsapp => _whatsapp;
  String? get nomPrenom => _nomPrenom;
  bool get isVerified => _isVerified;

  void setVerificationData({
    required String email,
    required String whatsapp,
    required String nomPrenom,
  }) {
    _email = email;
    _whatsapp = whatsapp;
    _nomPrenom = nomPrenom;
    _isVerified = false;
    notifyListeners();
  }

  void setVerified(bool verified) {
    _isVerified = verified;
    notifyListeners();
  }

  void clear() {
    _email = null;
    _whatsapp = null;
    _nomPrenom = null;
    _isVerified = false;
    notifyListeners();
  }
}
