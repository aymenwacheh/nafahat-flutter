// lib/pages/users/reset_password_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _resetSuccess = false;
  
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  static const Color nafahatGreen = Color(0xff0D443E);

  // ✅ Méthode utilitaire pour les traductions
  String _t(String ar, String fr) {
    final isArabic = Provider.of<LanguageProvider>(context, listen: false).isArabic;
    return isArabic ? ar : fr;
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

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
                          _t('🔑 إعادة تعيين كلمة المرور', '🔑 Réinitialiser le mot de passe'),
                          style: GoogleFonts.cairo(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff2c221e),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _t(
                            'أدخل بريدك الإلكتروني وكلمة المرور الجديدة',
                            'Entrez votre email et votre nouveau mot de passe'
                          ),
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // ✅ Email
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: _t('📧 البريد الإلكتروني', '📧 Email'),
                            hintText: _t('مثال@البريد.كوم', 'exemple@email.com'),
                            prefixIcon: Icon(Icons.email_outlined, color: nafahatGreen),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: nafahatGreen, width: 2),
                            ),
                            errorText: _errorMessage != null && 
                                (_errorMessage!.contains('Email') || 
                                 _errorMessage!.contains('البريد') ||
                                 _errorMessage!.contains('invalide') ||
                                 _errorMessage!.contains('غير صالح')) ? _errorMessage : null,
                            errorStyle: GoogleFonts.cairo(color: Colors.red.shade700),
                          ),
                          style: GoogleFonts.cairo(fontSize: 16),
                          onChanged: (_) {
                            if (_errorMessage != null && 
                                (_errorMessage!.contains('Email') || 
                                 _errorMessage!.contains('البريد') ||
                                 _errorMessage!.contains('invalide') ||
                                 _errorMessage!.contains('غير صالح'))) {
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
                            labelText: _t('🔒 كلمة المرور الجديدة', '🔒 Nouveau mot de passe'),
                            hintText: _t('6 أحرف على الأقل', 'Au moins 6 caractères'),
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
                            errorText: _errorMessage != null && 
                                (_errorMessage!.contains('mot de passe') || 
                                 _errorMessage!.contains('كلمة المرور') ||
                                 _errorMessage!.contains('6 caractères') ||
                                 _errorMessage!.contains('6 أحرف')) ? _errorMessage : null,
                            errorStyle: GoogleFonts.cairo(color: Colors.red.shade700),
                          ),
                          style: GoogleFonts.cairo(fontSize: 16),
                          onChanged: (_) {
                            if (_errorMessage != null && 
                                (_errorMessage!.contains('mot de passe') || 
                                 _errorMessage!.contains('كلمة المرور') ||
                                 _errorMessage!.contains('6 caractères') ||
                                 _errorMessage!.contains('6 أحرف'))) {
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
                            labelText: _t('🔒 تأكيد كلمة المرور', '🔒 Confirmer le mot de passe'),
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
                            errorText: _errorMessage != null && 
                                (_errorMessage!.contains('correspondent') || 
                                 _errorMessage!.contains('متطابقتين')) ? _errorMessage : null,
                            errorStyle: GoogleFonts.cairo(color: Colors.red.shade700),
                          ),
                          style: GoogleFonts.cairo(fontSize: 16),
                          onChanged: (_) {
                            if (_errorMessage != null && 
                                (_errorMessage!.contains('correspondent') || 
                                 _errorMessage!.contains('متطابقتين'))) {
                              setState(() => _errorMessage = null);
                            }
                          },
                        ),

                        // ✅ Message d'erreur général
                        if (_errorMessage != null && 
                            !_errorMessage!.contains('Email') && 
                            !_errorMessage!.contains('البريد') &&
                            !_errorMessage!.contains('mot de passe') &&
                            !_errorMessage!.contains('كلمة المرور') &&
                            !_errorMessage!.contains('6 caractères') &&
                            !_errorMessage!.contains('6 أحرف') &&
                            !_errorMessage!.contains('correspondent') &&
                            !_errorMessage!.contains('متطابقتين'))
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
                                  _t('✅ إعادة تعيين', '✅ Réinitialiser'),
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
                            _t('← العودة إلى تسجيل الدخول', '← Retour à la connexion'),
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

  Future<void> _resetPassword() async {
    final isArabic = Provider.of<LanguageProvider>(context, listen: false).isArabic;
    final email = _emailController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // ✅ Traductions pour les messages d'erreur
    String t(String ar, String fr) => isArabic ? ar : fr;

    // Validation
    if (email.isEmpty) {
      setState(() {
        _errorMessage = t('الرجاء إدخال بريدك الإلكتروني', 'Veuillez entrer votre email');
      });
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      setState(() {
        _errorMessage = t('البريد الإلكتروني غير صالح', 'Email invalide');
      });
      return;
    }

    if (newPassword.isEmpty) {
      setState(() {
        _errorMessage = t('الرجاء إدخال كلمة مرور', 'Veuillez entrer un mot de passe');
      });
      return;
    }

    if (newPassword.length < 6) {
      setState(() {
        _errorMessage = t(
          'يجب أن تحتوي كلمة المرور على 6 أحرف على الأقل',
          'Le mot de passe doit contenir au moins 6 caractères'
        );
      });
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() {
        _errorMessage = t('كلمتا المرور غير متطابقتين', 'Les mots de passe ne correspondent pas');
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // ✅ Appel à l'API
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/adherents/reset-password-direct'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
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
              t('✅ تم إعادة تعيين كلمة المرور بنجاح', '✅ Mot de passe réinitialisé avec succès'),
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
          // 1. Récupérer les données de l'utilisateur par email
          final userResponse = await http.get(
            Uri.parse('${ApiConfig.baseUrl}/adherents/by-email?email=${Uri.encodeComponent(email)}'),
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
          _errorMessage = data['error'] ?? t('حدث خطأ ما', 'Une erreur est survenue');
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = t(
          'خطأ في الاتصال بالخادم',
          'Erreur de connexion au serveur'
        );
        _isLoading = false;
      });
    }
  }
}