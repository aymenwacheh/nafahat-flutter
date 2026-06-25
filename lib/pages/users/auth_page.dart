import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nafahat/src/features/landing/presentation/landing_page.dart';
import '../../../src/features/landing/presentation/widgets/navbar.dart'; // Import exact selon ton arborescence
import 'profile_dashboard_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isArabic = false;
  bool isSignUp = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // --- NOUVELLE CHARTE GRAPHIQUE NAFAHAT ---
  static const Color nafahatGreenDark = Color(
    0xff092E2A,
  ); // Vert très sombre pour le contraste
  static const Color nafahatGreen = Color(0xff0D443E); // Vert émeraude du logo
  static const Color nafahatGold = Color(0xffC4A46C); // Doré textuel du logo

  void toggleLanguage() {
    setState(() {
      isArabic = !isArabic;
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfileDashboardPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 950;

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
                  // 1. PANNEAU VISUEL RECORRIGÉ AUX COULEURS DE NAFAHAT
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
                            // Motifs orientaux / cercles discrets rappelant l'univers de Nafahat
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
                                  // Petit badge élégant
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
                                      style: const TextStyle(
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
                                    style: const TextStyle(
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
                                    style: TextStyle(
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

                  // 2. ZONE FORMULAIRE CONTENU
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
                                  Text(
                                    isSignUp
                                        ? (isArabic
                                            ? "إنشاء حساب جديد"
                                            : "Rejoignez Nafahat")
                                        : (isArabic
                                            ? "تسجيل الدخول"
                                            : "Bienvenue à nouveau"),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 25),
                                  _buildAuthToggle(),
                                  const SizedBox(height: 30),
                                  if (isSignUp) ...[
                                    _buildTextField(
                                      controller: _nameController,
                                      labelFr: "Nom et Prénom",
                                      labelAr: "الاسم واللقب",
                                      icon: Icons.person_outline_rounded,
                                      validator:
                                          (value) =>
                                              value!.isEmpty
                                                  ? (isArabic
                                                      ? "يرجى إدخال الاسم"
                                                      : "Veuillez entrer votre nom")
                                                  : null,
                                    ),
                                    const SizedBox(height: 18),
                                  ],
                                  if (isSignUp) ...[
                                    _buildTextField(
                                      controller: _phoneController,
                                      labelFr: "Numéro de téléphone",
                                      labelAr: "رقم الهاتف",
                                      icon: Icons.phone_android_rounded,
                                      keyboardType: TextInputType.phone,
                                      validator:
                                          (value) =>
                                              value!.isEmpty
                                                  ? (isArabic
                                                      ? "يرجى إدخال رقم الهاتف"
                                                      : "Veuillez entrer votre numéro")
                                                  : null,
                                    ),
                                    const SizedBox(height: 18),
                                  ],
                                  _buildTextField(
                                    controller: _emailController,
                                    labelFr: "Adresse E-mail",
                                    labelAr: "البريد الإلكتروني",
                                    icon: Icons.alternate_email_rounded,
                                    keyboardType: TextInputType.emailAddress,
                                    validator:
                                        (value) =>
                                            !value!.contains('@')
                                                ? (isArabic
                                                    ? "بريد إلكتروني غير صالح"
                                                    : "E-mail invalide")
                                                : null,
                                  ),
                                  const SizedBox(height: 18),
                                  _buildTextField(
                                    controller: _passwordController,
                                    labelFr: "Mot de passe",
                                    labelAr: "كلمة المرور",
                                    icon: Icons.lock_outline_rounded,
                                    isPassword: true,
                                    validator:
                                        (value) =>
                                            value!.length < 6
                                                ? (isArabic
                                                    ? "كلمة المرور قصيرة جداً"
                                                    : "6 caractères minimum")
                                                : null,
                                  ),
                                  const SizedBox(height: 30),
                                  ElevatedButton(
                                    onPressed: _submitForm,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          nafahatGreen, // Application du bouton vert Nafahat
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      isSignUp
                                          ? (isArabic
                                              ? "إنشاء حساب"
                                              : "S'inscrire")
                                          : (isArabic
                                              ? "تسجيل الدخول"
                                              : "Se connecter"),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
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

  Widget _buildAuthToggle() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: nafahatGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isSignUp = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSignUp ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow:
                      isSignUp
                          ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                            ),
                          ]
                          : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  isArabic ? "تسجيل جديد" : "Inscription",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSignUp ? nafahatGreenDark : AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isSignUp = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: !isSignUp ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow:
                      !isSignUp
                          ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                            ),
                          ]
                          : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  isArabic ? "دخول" : "Connexion",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: !isSignUp ? nafahatGreenDark : AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelFr,
    required String labelAr,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    required String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: AppColors.textDark, fontSize: 14),
      decoration: InputDecoration(
        labelText: isArabic ? labelAr : labelFr,
        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
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
