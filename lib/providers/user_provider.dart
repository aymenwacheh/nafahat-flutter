// lib/providers/user_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/role.dart';
import 'dart:convert';

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

  // 📥 CONSTRUCTEUR - Charge la session au démarrage
  UserProvider() {
    _loadSession();
  }

  // 📥 Charger la session depuis SharedPreferences
  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final userId = prefs.getString('user_id');
      final userName = prefs.getString('user_name');
      final userWhatsapp = prefs.getString('user_whatsapp');
      final userEmail = prefs.getString('user_email');
      final roleJson = prefs.getString('user_role');
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

      if (userId != null && isLoggedIn) {
        _userId = userId;
        _userName = userName;
        _userWhatsapp = userWhatsapp;
        _userEmail = userEmail;
        _isLoggedIn = true;

        if (roleJson != null) {
          final Map<String, dynamic> roleMap = jsonDecode(roleJson);
          _userRole = Role.fromJson(roleMap);
        }

        notifyListeners();
        print('✅ Session chargée pour: $_userName');
      } else {
        print('ℹ️ Aucune session active trouvée');
      }
    } catch (e) {
      print('❌ Erreur lors du chargement de la session: $e');
    }
  }

  // 💾 Sauvegarder la session dans SharedPreferences
  Future<void> _saveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_userId != null && _isLoggedIn) {
        await prefs.setString('user_id', _userId!);
        await prefs.setString('user_name', _userName ?? '');
        await prefs.setString('user_whatsapp', _userWhatsapp ?? '');
        await prefs.setString('user_email', _userEmail ?? '');
        await prefs.setBool('is_logged_in', _isLoggedIn);

        if (_userRole != null) {
          await prefs.setString('user_role', jsonEncode(_userRole!.toJson()));
        }

        print('✅ Session sauvegardée pour: $_userName');
      }
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde de la session: $e');
    }
  }

  // 👤 Définir l'utilisateur (connexion)
  Future<void> setUser({
    required String id,
    required String name,
    required String whatsapp,
    String? email,
    required Role role,
  }) async {
    _userId = id;
    _userName = name;
    _userWhatsapp = whatsapp;
    _userEmail = email;
    _userRole = role;
    _isLoggedIn = true;

    await _saveSession(); // 💾 Sauvegarde persistante
    notifyListeners();
  }

  // 🚪 Déconnexion
  Future<void> logout() async {
    _userId = null;
    _userName = null;
    _userWhatsapp = null;
    _userEmail = null;
    _userRole = null;
    _isLoggedIn = false;

    // Efface toutes les données persistées
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_whatsapp');
    await prefs.remove('user_email');
    await prefs.remove('user_role');
    await prefs.remove('is_logged_in');

    notifyListeners();
    print('👋 Déconnexion effectuée');
  }

  // 🔄 Mettre à jour les données utilisateur
  Future<void> updateUser({
    String? name,
    String? email,
    String? whatsapp,
  }) async {
    if (name != null) _userName = name;
    if (email != null) _userEmail = email;
    if (whatsapp != null) _userWhatsapp = whatsapp;

    await _saveSession();
    notifyListeners();
  }

  // 🔍 Vérifier si l'utilisateur est connecté
  bool get isAuthenticated => _isLoggedIn && _userId != null;

  // Pour le développement / test
  Future<void> setTestUser(Role role) async {
    await setUser(
      id: '1',
      name: 'Test User',
      whatsapp: '+21612345678',
      email: 'test@nafahat.com',
      role: role,
    );
  }
}
