// lib/pages/users/reset_password_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafahat/pages/users/request_reset_password.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_config.dart';
import '../../providers/language_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/role.dart';
import '../../services/auth_service.dart';
import '../widgets/navbar.dart';
import 'auth_page.dart';
import 'profile_dashboard_page.dart';

class ResetPasswordPage extends StatefulWidget {
  final String token;

  const ResetPasswordPage({super.key, required this.token});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isTokenValid = false;
  bool _isTokenChecked = false;
  String? _errorMessage;
  String? _email;
  String? _whatsapp;
  
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _resetSuccess = false;

  static const Color nafahatGreen = Color(0xff0D443E);

  @override
  void initState() {
    super.initState();
    _verifyToken();
  }

  Future<void> _verifyToken() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/adherents/verify-reset-token?token=${widget.token}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true && data['valid'] == true) {
        setState(() {
          _isTokenValid = true;
          _isTokenChecked = true;
          _whatsapp = data['whatsapp'];
          _email = data['email'];
          _whatsappController.text = data['whatsapp'] ?? '';
        });
      } else {
        setState(() {
          _isTokenValid = false;
          _isTokenChecked = true;
          _errorMessage = data['error'] ?? 'Token invalide ou expiré';
        });
      }
    } catch (e) {
      setState(() {
        _isTokenValid = false;
        _isTokenChecked = true;
        _errorMessage = 'Erreur de connexion au serveur';
      });
    }
  }

  Future<void> _resetPassword() async {
    final isArabic = Provider.of<LanguageProvider>(context, listen: false).isArabic;
    final whatsapp = _whatsappController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validation
    if (whatsapp.isEmpty) {
      setState(() {
        _errorMessage = isArabic ? 'Veuillez entrer votre numéro WhatsApp' : 'Veuillez entrer votre numéro WhatsApp';
      });
      return;
    }

    if (newPassword.isEmpty) {
      setState(() {
        _errorMessage = isArabic ? 'Veuillez entrer un mot de passe' : 'Veuillez entrer un mot de passe';
      });
      return;
    }

    if (newPassword.length < 6) {
      setState(() {
        _errorMessage = isArabic 
            ? 'Le mot de passe doit contenir au moins 6 caractères'
            : 'Le mot de passe doit contenir au moins 6 caractères';
      });
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() {
        _errorMessage = isArabic ? 'Les mots de passe ne correspondent pas' : 'Les mots de passe ne correspondent pas';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/adherents/reset-password-with-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': widget.token,
          'whatsapp': whatsapp,
          'newPassword': newPassword,
        }),
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // ✅ Réinitialisation réussie
        setState(() {
          _resetSuccess = true;
          _isLoading = false;
        });

        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic ? '✅ Mot de passe réinitialisé avec succès' : '✅ Mot de passe réinitialisé avec succès',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: nafahatGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        // ✅ Récupérer l'utilisateur et le connecter automatiquement
        try {
          // 1. Récupérer les données de l'utilisateur
          final userResponse = await http.get(
            Uri.parse('${ApiConfig.baseUrl}/adherents/${data['userId']}'),
            headers: {'Content-Type': 'application/json'},
          );

          if (userResponse.statusCode == 200) {
            final userData = json.decode(userResponse.body);
            if (userData['success'] == true) {
              final user = userData['data'];

              // 2. Créer le rôle
              Role? userRole;
              if (user['role_id'] != null) {
                userRole = Role(
                  id: user['role_id'],
                  nom: user['role_nom'] ?? 'adherent',
                  libelle: user['role_libelle'] ?? 'Adhérent',
                  description: 'Accès à l\'espace membre',
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
              } else {
                userRole = Role(
                  id: 4,
                  nom: 'adherent',
                  libelle: 'Adhérent',
                  description: 'Accès à l\'espace membre',
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
              }

              // 3. Connecter l'utilisateur
              final userProvider = Provider.of<UserProvider>(context, listen: false);

              await userProvider.setUser(
                id: user['id'].toString(),
                name: user['nom_prenom'],
                whatsapp: user['whatsapp'],
                email: user['email'] ?? '',
                role: userRole,
              );

              // 4. Sauvegarder dans AuthService
              await AuthService.saveUserData({
                'id': user['id'],
                'nomPrenom': user['nom_prenom'],
                'whatsapp': user['whatsapp'],
                'email': user['email'] ?? '',
                'token': 'session_${user['id']}',
              });
              await AuthService.saveUserId(user['id']);

              // 5. Rediriger vers le tableau de bord
              await Future.delayed(const Duration(milliseconds: 500));
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileDashboardPage()),
                  (route) => false,
                );
              }
            }
          }
        } catch (loginError) {
          // Si la connexion automatique échoue, rediriger vers la page de connexion
          print('❌ Erreur connexion automatique: $loginError');
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const AuthPage()),
              (route) => false,
            );
          }
        }
      } else {
        setState(() {
          _errorMessage = data['error'] ?? (isArabic ? 'Une erreur est survenue' : 'Une erreur est survenue');
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = isArabic 
            ? 'Erreur de connexion au serveur' 
            : 'Erreur de connexion au serveur';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // État : Vérification du token en cours
    if (!_isTokenChecked) {
      return Scaffold(
        key: _scaffoldKey,
        drawer: isMobile ? Navbar(isMobile: true, scaffoldKey: _scaffoldKey).buildDrawer(context) : null,
        backgroundColor: Colors.grey.shade50,
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Navbar(isMobile: isMobile, scaffoldKey: _scaffoldKey),
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: nafahatGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // État : Token invalide ou expiré
    if (!_isTokenValid) {
      return Scaffold(
        key: _scaffoldKey,
        drawer: isMobile ? Navbar(isMobile: true, scaffoldKey: _scaffoldKey).buildDrawer(context) : null,
        backgroundColor: Colors.grey.shade50,
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Navbar(isMobile: isMobile, scaffoldKey: _scaffoldKey),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                        const SizedBox(height: 16),
                        Text(
                          isArabic ? 'Lien invalide ou expiré' : 'Lien invalide ou expiré',
                          style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff2c221e),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage ?? (isArabic 
                              ? 'Le lien de réinitialisation est invalide ou a expiré. Veuillez faire une nouvelle demande.'
                              : 'Le lien de réinitialisation est invalide ou a expiré. Veuillez faire une nouvelle demande.'),
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const RequestResetPasswordPage()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: nafahatGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            isArabic ? 'Faire une nouvelle demande' : 'Faire une nouvelle demande',
                            style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ État : Token valide - Afficher le formulaire de réinitialisation
    return Scaffold(
      key: _scaffoldKey,
      drawer: isMobile ? Navbar(isMobile: true, scaffoldKey: _scaffoldKey).buildDrawer(context) : null,
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Navbar(isMobile: isMobile, scaffoldKey: _scaffoldKey),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 450),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Icône
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: nafahatGreen.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.password_rounded,
                            size: 40,
                            color: nafahatGreen,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          isArabic ? '🔑 Réinitialiser le mot de passe' : '🔑 Réinitialiser le mot de passe',
                          style: GoogleFonts.cairo(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff2c221e),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isArabic 
                              ? 'Entrez votre identifiant et votre nouveau mot de passe'
                              : 'Entrez votre identifiant et votre nouveau mot de passe',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // ✅ Email (non modifiable - pour information)
                        if (_email != null && _email!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.email_outlined, color: Colors.green.shade700, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _email!,
                                    style: GoogleFonts.cairo(
                                      fontSize: 14,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Icon(Icons.check_circle, color: Colors.green.shade400, size: 16),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),

                        // ✅ WhatsApp (login) - Champ modifiable
                        TextFormField(
                          controller: _whatsappController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: isArabic ? '📱 Identifiant (WhatsApp)' : '📱 Identifiant (WhatsApp)',
                            hintText: '+216 25357461',
                            prefixIcon: Icon(Icons.phone_android_rounded, color: nafahatGreen),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: nafahatGreen, width: 2),
                            ),
                            errorText: _errorMessage?.contains('WhatsApp') == true ? _errorMessage : null,
                            errorStyle: GoogleFonts.cairo(color: Colors.red.shade700),
                          ),
                          style: GoogleFonts.cairo(fontSize: 16),
                          onChanged: (_) {
                            if (_errorMessage != null && _errorMessage!.contains('WhatsApp')) {
                              setState(() => _errorMessage = null);
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // ✅ Nouveau mot de passe
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: isArabic ? '🔒 Nouveau mot de passe' : '🔒 Nouveau mot de passe',
                            hintText: isArabic ? 'Au moins 6 caractères' : 'Au moins 6 caractères',
                            prefixIcon: Icon(Icons.lock_outline_rounded, color: nafahatGreen),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword 
                                    ? Icons.visibility_outlined 
                                    : Icons.visibility_off_outlined,
                                color: Colors.grey.shade500,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: nafahatGreen, width: 2),
                            ),
                            errorText: _errorMessage?.contains('mot de passe') == true ? _errorMessage : null,
                            errorStyle: GoogleFonts.cairo(color: Colors.red.shade700),
                          ),
                          style: GoogleFonts.cairo(fontSize: 16),
                          onChanged: (_) {
                            if (_errorMessage != null && _errorMessage!.contains('mot de passe')) {
                              setState(() => _errorMessage = null);
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // ✅ Confirmation du mot de passe
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: isArabic ? '🔒 Confirmer le mot de passe' : '🔒 Confirmer le mot de passe',
                            prefixIcon: Icon(Icons.lock_outline_rounded, color: nafahatGreen),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword 
                                    ? Icons.visibility_outlined 
                                    : Icons.visibility_off_outlined,
                                color: Colors.grey.shade500,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: nafahatGreen, width: 2),
                            ),
                            errorText: _errorMessage?.contains('correspondent') == true ? _errorMessage : null,
                            errorStyle: GoogleFonts.cairo(color: Colors.red.shade700),
                          ),
                          style: GoogleFonts.cairo(fontSize: 16),
                          onChanged: (_) {
                            if (_errorMessage != null && _errorMessage!.contains('correspondent')) {
                              setState(() => _errorMessage = null);
                            }
                          },
                        ),

                        // ✅ Message d'erreur général
                        if (_errorMessage != null && 
                            !_errorMessage!.contains('WhatsApp') && 
                            !_errorMessage!.contains('mot de passe') &&
                            !_errorMessage!.contains('correspondent'))
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _errorMessage!,
                              style: GoogleFonts.cairo(
                                color: Colors.red.shade700,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        const SizedBox(height: 24),

                        // ✅ Bouton de réinitialisation
                        ElevatedButton(
                          onPressed: _isLoading ? null : _resetPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: nafahatGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  isArabic ? '✅ Réinitialiser' : '✅ Réinitialiser',
                                  style: GoogleFonts.cairo(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),

                        const SizedBox(height: 12),

                        // ✅ Lien retour vers la connexion
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const AuthPage()),
                            );
                          },
                          child: Text(
                            isArabic ? '← Retour à la connexion' : '← Retour à la connexion',
                            style: GoogleFonts.cairo(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}