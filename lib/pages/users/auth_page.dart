import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafahat/src/features/landing/presentation/landing_page.dart';
import '../../../src/features/landing/presentation/widgets/navbar.dart';
import 'profile_dashboard_page.dart';
import 'inscription_adherent.dart';
import '../../providers/language_provider.dart';
import '../../services/adherent_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLoading = false;

  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // --- COULEURS ---
  static const Color nafahatGreenDark = Color(0xff092E2A);
  static const Color nafahatGreen = Color(0xff0D443E);
  static const Color nafahatGold = Color(0xffC4A46C);

  // Méthode toggle qui appelle le provider
  void toggleLanguage() {
    final provider = Provider.of<LanguageProvider>(context, listen: false);
    provider.toggleLanguage();
  }

  // ---- AUTHENTIFICATION ----
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final userData = await AdherentService.login(
          _whatsappController.text.trim(),
          _passwordController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                Provider.of<LanguageProvider>(context, listen: false).isArabic
                    ? "✅ تم تسجيل الدخول بنجاح"
                    : "✅ Connexion réussie !",
              ),
              backgroundColor: nafahatGreen,
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfileDashboardPage(),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          final isArabic =
              Provider.of<LanguageProvider>(context, listen: false).isArabic;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isArabic
                    ? "❌ ${e.toString().replaceFirst('Exception: ', '')}"
                    : "❌ ${e.toString().replaceFirst('Exception: ', '')}",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // ---- RÉINITIALISATION DU MOT DE PASSE ----
  Future<void> _resetPassword() async {
    final whatsapp = _whatsappController.text.trim();
    if (whatsapp.isEmpty) {
      final isArabic =
          Provider.of<LanguageProvider>(context, listen: false).isArabic;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? "يرجى إدخال رقم WhatsApp pour réinitialiser"
                : "Veuillez entrer votre numéro WhatsApp",
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // TODO: Implémenter la réinitialisation du mot de passe
    // Pour l'instant, on affiche un message
    final isArabic =
        Provider.of<LanguageProvider>(context, listen: false).isArabic;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabic
              ? "📧 Un lien de réinitialisation sera envoyé sur votre WhatsApp"
              : "📧 Un lien de réinitialisation vous sera envoyé sur WhatsApp",
        ),
        backgroundColor: nafahatGold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 950;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.surface,
        body: SafeArea(
          top: false,
          child: Stack(
            children: [
              Row(
                children: [
                  // --- PANNEAU VISUEL ---
                  if (!isMobile)
                    Expanded(
                      flex: 5,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [nafahatGreenDark, nafahatGreen],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: -80,
                              left: -80,
                              child: CircleAvatar(
                                radius: 180,
                                backgroundColor: Colors.white.withOpacity(0.02),
                              ),
                            ),
                            Positioned(
                              bottom: -50,
                              right: -50,
                              child: CircleAvatar(
                                radius: 130,
                                backgroundColor: nafahatGold.withOpacity(0.04),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(60.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: nafahatGold.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: nafahatGold.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      isArabic ? "مرحباً بكم" : "Bienvenue",
                                      style: GoogleFonts.cairo(
                                        color: nafahatGold,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    isArabic
                                        ? "منصة نفحات"
                                        : "Plateforme Nafahat",
                                    style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontSize: 42,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    isArabic
                                        ? "طريقك نحو التميز والتطوير المستمر من خلال دورات تدريبية متكاملة."
                                        : "Votre chemin vers l'excellence et le développement continu à travers des cycles de formation complets.",
                                    style: GoogleFonts.cairo(
                                      color: Colors.white.withOpacity(0.75),
                                      fontSize: 16,
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // --- ZONE FORMULAIRE DE CONNEXION ---
                  Expanded(
                    flex: 6,
                    child: Container(
                      color: AppColors.surface,
                      child: Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.only(
                            top: isMobile ? 140 : 100,
                            bottom: 40,
                            left: 24,
                            right: 24,
                          ),
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 460),
                            padding: const EdgeInsets.all(36),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.06),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: nafahatGreenDark.withOpacity(0.02),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // --- TITRE ---
                                  Text(
                                    isArabic
                                        ? "تسجيل الدخول"
                                        : "Bienvenue à nouveau",
                                    style: GoogleFonts.cairo(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    isArabic
                                        ? "أدخل بياناتك للدخول إلى حسابك"
                                        : "Entrez vos identifiants pour accéder à votre compte",
                                    style: GoogleFonts.cairo(
                                      color: AppColors.textMuted,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 30),

                                  // --- CHAMP WHATSAPP (identifiant) ---
                                  _buildTextField(
                                    controller: _whatsappController,
                                    labelFr: "Numéro WhatsApp",
                                    labelAr: "رقم الواتساب",
                                    icon: Icons.phone_android_rounded,
                                    isArabic: isArabic,
                                    keyboardType: TextInputType.phone,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return isArabic
                                            ? "يرجى إدخال رقم الواتساب"
                                            : "Veuillez entrer votre numéro WhatsApp";
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 18),

                                  // --- CHAMP MOT DE PASSE ---
                                  _buildTextField(
                                    controller: _passwordController,
                                    labelFr: "Mot de passe",
                                    labelAr: "كلمة المرور",
                                    icon: Icons.lock_outline_rounded,
                                    isArabic: isArabic,
                                    isPassword: true,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return isArabic
                                            ? "يرجى إدخال كلمة المرور"
                                            : "Veuillez entrer votre mot de passe";
                                      }
                                      if (value.length < 6) {
                                        return isArabic
                                            ? "كلمة المرور قصيرة جداً (6 أحرف على الأقل)"
                                            : "6 caractères minimum";
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),

                                  // --- LIEN "MOT DE PASSE OUBLIÉ" ---
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _resetPassword,
                                      style: TextButton.styleFrom(
                                        foregroundColor: nafahatGreen,
                                      ),
                                      child: Text(
                                        isArabic
                                            ? "نسيت كلمة المرور؟"
                                            : "Mot de passe oublié ?",
                                        style: GoogleFonts.cairo(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 30),

                                  // --- BOUTON SE CONNECTER ---
                                  ElevatedButton(
                                    onPressed: _isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: nafahatGreen,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 0,
                                    ),
                                    child:
                                        _isLoading
                                            ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                            : Text(
                                              isArabic
                                                  ? "تسجيل الدخول"
                                                  : "Se connecter",
                                              style: GoogleFonts.cairo(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                  ),
                                  const SizedBox(height: 20),

                                  // --- LIEN "CRÉER UN COMPTE" ---
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        isArabic
                                            ? "ليس لديك حساب؟"
                                            : "Vous n'avez pas de compte ?",
                                        style: GoogleFonts.cairo(
                                          color: AppColors.textMuted,
                                          fontSize: 14,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                      const InscriptionAdherentPage(),
                                            ),
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: nafahatGreen,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                        ),
                                        child: Text(
                                          isArabic
                                              ? "إنشاء حساب"
                                              : "Créer un compte",
                                          style: GoogleFonts.cairo(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // --- NAVBAR ---
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Navbar(
                  isArabic: isArabic,
                  isMobile: isMobile,
                  onLanguageToggle: toggleLanguage,
                  scaffoldKey: _scaffoldKey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET CHAMP DE TEXTE ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelFr,
    required String labelAr,
    required IconData icon,
    required bool isArabic,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    required String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.cairo(color: AppColors.textDark, fontSize: 14),
      decoration: InputDecoration(
        labelText: isArabic ? labelAr : labelFr,
        labelStyle: GoogleFonts.cairo(color: AppColors.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: nafahatGreen.withOpacity(0.6), size: 18),
        filled: true,
        fillColor: nafahatGreen.withOpacity(0.01),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: nafahatGreen.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: nafahatGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}
