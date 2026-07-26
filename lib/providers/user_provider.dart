// lib/providers/user_provider.dart
import 'package:flutter/material.dart';
import '../models/role.dart';

class UserProvider extends ChangeNotifier {
  String? _userId;
  String? _userName;
  String? _userWhatsapp;
  String? _userEmail;
  Role? _userRole;
  bool _isLoggedIn = false;

  String? get userId => _userId;
  String? get userName => _userName;
  String? get userWhatsapp => _userWhatsapp;
  String? get userEmail => _userEmail;
  Role? get userRole => _userRole;
  bool get isLoggedIn => _isLoggedIn;

  // Vérifications de rôle
  bool get isSuperAdmin => _userRole?.nom == 'super_admin';
  bool get isAdmin => _userRole?.nom == 'admin' || isSuperAdmin;
  bool get isModerator => _userRole?.nom == 'moderator' || isAdmin;
  bool get isFormateur => _userRole?.nom == 'formateur';
  bool get isAdherent => _userRole?.nom == 'adherent';

  // Permission pour voir la page de création d'utilisateur
  bool get canCreateUser => isSuperAdmin;

  // Permission pour voir l'administration complète
  bool get canViewAdmin => isSuperAdmin || isAdmin || isModerator;

  // Permission pour voir les pages d'administration (sauf création user)
  bool get canViewAdminPages => isSuperAdmin || isAdmin || isModerator;

  // Nom complet pour l'affichage
  String get displayName => _userName ?? 'Utilisateur';

  // Initiales pour l'avatar
  String get initials {
    if (_userName == null || _userName!.isEmpty) return 'U';
    final parts = _userName!.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return _userName![0].toUpperCase();
  }

  void setUser({
    required String id,
    required String name,
    required String whatsapp,
    String? email,
    required Role role,
  }) {
    _userId = id;
    _userName = name;
    _userWhatsapp = whatsapp;
    _userEmail = email;
    _userRole = role;
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _userId = null;
    _userName = null;
    _userWhatsapp = null;
    _userEmail = null;
    _userRole = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  // Pour le développement / test
  void setTestUser(Role role) {
    setUser(
      id: '1',
      name: 'Test User',
      whatsapp: '+21612345678',
      email: 'test@nafahat.com',
      role: role,
    );
  }
}
