import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/language_provider.dart';
import '../landing/widgets/navbar.dart';
import '../../services/adherent_service.dart';
import '../../models/adherent.dart';
import '../../models/enfant.dart';
import '../landing/widgets/chatbot/chatbot_wrapper.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';

// ----- PAGE PRINCIPALE -----
class InscriptionAdherentPage extends StatefulWidget {
  const InscriptionAdherentPage({super.key});

  @override
  State<InscriptionAdherentPage> createState() =>
      _InscriptionAdherentPageState();
}

class _InscriptionAdherentPageState extends State<InscriptionAdherentPage> {
  bool isLoading = false;
  bool ajouterEnfants = false;

  // Données adhérent
  String _whatsapp = '';
  String _selectedCountryCode = '+216';
  String _nomPrenom = '';
  String _pays = '';
  String _ville = '';
  String _email = '';
  DateTime _dateNaissance = DateTime.now();
  String _genre = 'homme';
  String _sourceConnaissance = 'instagram';
  String? _sourceAutreDetail;
  String? _objectif;
  String? _suggestions;
  bool _accordPublication = false;

  // ✅ Contrôleurs
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _whatsappFocusNode = FocusNode();
  final FocusNode _nomFocusNode = FocusNode();

  // ✅ États de validation
  String? _whatsappError;
  String? _emailError;
  bool _isWhatsappValid = false;
  bool _isEmailValid = false;
  bool _isEmailChecking = false;
  bool _isWhatsappChecking = false;

  // ✅ "Déjà utilisé" — flags dédiés (distincts de la validité de format)
  bool _whatsappExists = false;
  bool _emailExists = false;

  // ✅ Empêche l'empilement de popups
  bool _popupVisible = false;

  // ✅ Debounce
  Timer? _debounceTimer;

  List<Enfant> _enfants = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Map<String, String>> _countryCodes = [
    {'flag': '🇹🇳', 'code': '+216'},
    {'flag': '🇫🇷', 'code': '+33'},
    {'flag': '🇩🇿', 'code': '+213'},
    {'flag': '🇲🇦', 'code': '+212'},
    {'flag': '🇪🇬', 'code': '+20'},
    {'flag': '🇸🇦', 'code': '+966'},
    {'flag': '🇦🇪', 'code': '+971'},
    {'flag': '🇶🇦', 'code': '+974'},
    {'flag': '🇰🇼', 'code': '+965'},
    {'flag': '🇱🇧', 'code': '+961'},
    {'flag': '🇯🇴', 'code': '+962'},
    {'flag': '🇺🇸', 'code': '+1'},
    {'flag': '🇬🇧', 'code': '+44'},
    {'flag': '🇩🇪', 'code': '+49'},
  ];

  @override
  void initState() {
    super.initState();
    _whatsappController.addListener(_onWhatsappChanged);
    _emailController.addListener(_onEmailChanged);

    // ✅ Détecter quand l'utilisateur quitte le champ WhatsApp
    // -> la vérification (et le popup éventuel) doit se faire AVANT
    //    de continuer vers le champ suivant.
    _whatsappFocusNode.addListener(() {
      if (!_whatsappFocusNode.hasFocus && _whatsappController.text.isNotEmpty) {
        _checkWhatsappOnExit(_whatsappController.text);
      }
    });

    // ✅ Détecter quand l'utilisateur quitte le champ email
    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus && _emailController.text.isNotEmpty) {
        _checkEmailOnExit(_emailController.text);
      }
    });
  }

  @override
  void dispose() {
    _whatsappController.dispose();
    _emailController.dispose();
    _emailFocusNode.dispose();
    _whatsappFocusNode.dispose();
    _nomFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  bool get _isArabic =>
      Provider.of<LanguageProvider>(context, listen: false).isArabic;

  // ============================================================
  // ✅ VALIDATION WHATSAPP (temps réel, pendant la frappe)
  // ============================================================
  void _onWhatsappChanged() {
    _whatsapp = _whatsappController.text;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _validateWhatsapp(_whatsappController.text);
    });
  }

  Future<void> _validateWhatsapp(String value) async {
    if (value.isEmpty || value.length < 8) {
      if (!mounted) return;
      setState(() {
        _whatsappError = null;
        _isWhatsappValid = false;
        _whatsappExists = false;
      });
      return;
    }

    final fullWhatsapp = '$_selectedCountryCode$value';
    final isArabic = _isArabic;

    if (mounted) setState(() => _isWhatsappChecking = true);

    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/adherents/check-whatsapp?whatsapp=${Uri.encodeComponent(fullWhatsapp)}',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['exists'] == true) {
          setState(() {
            _whatsappError =
                isArabic
                    ? '⚠️ رقم الواتساب هذا مستعمل بالفعل'
                    : '⚠️ Ce numéro WhatsApp est déjà utilisé';
            _isWhatsappValid = false;
            _whatsappExists = true;
          });
        } else {
          setState(() {
            _whatsappError = null;
            _isWhatsappValid = true;
            _whatsappExists = false;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _whatsappError = null;
        _isWhatsappValid = true;
        _whatsappExists = false;
      });
    } finally {
      if (mounted) setState(() => _isWhatsappChecking = false);
    }
  }

  // ✅ Vérification immédiate (annule le debounce) quand l'utilisateur
  //    quitte le champ WhatsApp -> déclenche le popup si besoin
  //    AVANT que l'utilisateur ne poursuive sa saisie.
  Future<void> _checkWhatsappOnExit(String value) async {
    if (value.isEmpty || value.length < 8) return;
    _debounceTimer?.cancel();
    await _validateWhatsapp(value);
    _showDuplicatePopupIfNeeded();
  }

  // ============================================================
  // ✅ VALIDATION EMAIL - EN TEMPS RÉEL
  // ============================================================
  void _onEmailChanged() {
    _email = _emailController.text;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _checkEmail(_emailController.text);
    });
  }

  // ✅ Vérification immédiate quand l'utilisateur quitte le champ
  //    -> déclenche le popup si besoin AVANT de passer au champ suivant.
  Future<void> _checkEmailOnExit(String value) async {
    if (value.isEmpty || !value.contains('@')) return;
    _debounceTimer?.cancel();
    await _checkEmail(value);
    _showDuplicatePopupIfNeeded();
  }

  Future<void> _checkEmail(String value) async {
    final isArabic = _isArabic;

    if (value.isEmpty || !value.contains('@') || value.length < 5) {
      if (!mounted) return;
      setState(() {
        _emailError = null;
        _isEmailValid = false;
        _isEmailChecking = false;
        _emailExists = false;
      });
      return;
    }

    if (mounted) setState(() => _isEmailChecking = true);

    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/adherents/check-email?email=${Uri.encodeComponent(value)}',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (!mounted) return;
      setState(() => _isEmailChecking = false);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['exists'] == true) {
          setState(() {
            _emailError =
                isArabic
                    ? '⚠️ هذا البريد الإلكتروني مستعمل بالفعل'
                    : '⚠️ Cet email est déjà utilisé';
            _isEmailValid = false;
            _emailExists = true;
          });
        } else {
          setState(() {
            _emailError = null;
            _isEmailValid = true;
            _emailExists = false;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _emailError = null;
        _isEmailValid = true;
        _isEmailChecking = false;
        _emailExists = false;
      });
    }
  }

  // ============================================================
  // ✅ POPUP UNIQUE — CENTRÉ, RESPONSIVE (WEB + MOBILE)
  //    Gère les 3 cas précis :
  //    - WhatsApp déjà enregistré
  //    - Email déjà enregistré
  //    - WhatsApp ET Email déjà enregistrés
  // ============================================================
  Future<void> _showDuplicatePopupIfNeeded() async {
    if (_popupVisible || !mounted) return;

    final whatsappDup = _whatsapp.trim().isNotEmpty && _whatsappExists;
    final emailDup = _email.trim().isNotEmpty && _emailExists;

    if (!whatsappDup && !emailDup) return;

    _popupVisible = true;
    await _showDuplicatePopup(whatsappDup: whatsappDup, emailDup: emailDup);
    _popupVisible = false;
  }

  Future<void> _showDuplicatePopup({
    required bool whatsappDup,
    required bool emailDup,
  }) async {
    final isArabic = _isArabic;

    // ---- Textes précis selon le(s) cas ----
    late final String title;
    late final String message;
    late final IconData icon;

    if (whatsappDup && emailDup) {
      title =
          isArabic
              ? '⚠️ رقم الواتساب والبريد الإلكتروني مسجلان بالفعل'
              : '⚠️ Numéro WhatsApp et email déjà enregistrés';
      message =
          isArabic
              ? 'رقم الواتساب والبريد الإلكتروني اللذان أدخلتهما مسجلان بالفعل.\n\n'
                  '🔹 إذا كان لديك حساب، الرجاء تسجيل الدخول.\n'
                  '🔹 وإلا، الرجاء استعمال بيانات أخرى.'
              : 'Le numéro WhatsApp et l\'email que vous avez saisis sont déjà '
                  'enregistrés.\n\n'
                  '🔹 Si vous avez déjà un compte, veuillez vous connecter.\n'
                  '🔹 Sinon, veuillez utiliser d\'autres coordonnées.';
      icon = Icons.report_problem_rounded;
    } else if (whatsappDup) {
      title =
          isArabic
              ? '⚠️ رقم الواتساب مسجل بالفعل'
              : '⚠️ Numéro WhatsApp déjà enregistré';
      message =
          isArabic
              ? 'رقم الواتساب هذا مسجل بالفعل.\n\n'
                  '🔹 إذا كان لديك حساب، الرجاء تسجيل الدخول.\n'
                  '🔹 وإلا، الرجاء استعمال رقم آخر.'
              : 'Ce numéro WhatsApp est déjà enregistré.\n\n'
                  '🔹 Si vous avez déjà un compte, veuillez vous connecter.\n'
                  '🔹 Sinon, veuillez utiliser un autre numéro.';
      icon = Icons.phone_android_rounded;
    } else {
      title =
          isArabic ? '⚠️ البريد الإلكتروني مستخدم' : '⚠️ Email déjà utilisé';
      message =
          isArabic
              ? 'هذا البريد الإلكتروني مسجل بالفعل.\n\n'
                  '🔹 إذا كان لديك حساب، الرجاء تسجيل الدخول.\n'
                  '🔹 وإلا، الرجاء استعمال بريد آخر.'
              : 'Cet email est déjà enregistré.\n\n'
                  '🔹 Si vous avez déjà un compte, veuillez vous connecter.\n'
                  '🔹 Sinon, veuillez utiliser un autre email.';
      icon = Icons.email_outlined;
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext dialogContext) {
        final screenSize = MediaQuery.of(dialogContext).size;
        final isWideScreen = screenSize.width > 500;

        return Dialog(
          // ✅ Toujours centré au milieu de l'écran (web + mobile)
          alignment: Alignment.center,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            width: isWideScreen ? 440 : double.infinity,
            constraints: BoxConstraints(maxHeight: screenSize.height * 0.85),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ✅ Icône avec cercle rouge
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade600, Colors.red.shade800],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(icon, size: 42, color: Colors.white),
                  ),
                  const SizedBox(height: 20),

                  // ✅ Titre
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // ✅ Message précis
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200, width: 1),
                    ),
                    child: Text(
                      message,
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ✅ Valeur(s) saisie(s) en surbrillance
                  if (whatsappDup)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildDuplicateValueChip(
                        icon: Icons.phone_android_rounded,
                        value: '$_selectedCountryCode$_whatsapp',
                      ),
                    ),
                  if (emailDup)
                    _buildDuplicateValueChip(
                      icon: Icons.email_rounded,
                      value: _email,
                    ),
                  const SizedBox(height: 24),

                  // ✅ Boutons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            // ✅ Effacer le(s) champ(s) en doublon et remettre
                            //    le focus dessus pour correction immédiate.
                            Future.delayed(
                              const Duration(milliseconds: 100),
                              () {
                                if (!mounted) return;
                                setState(() {
                                  if (whatsappDup) {
                                    _whatsappController.clear();
                                    _whatsapp = '';
                                    _whatsappError = null;
                                    _isWhatsappValid = false;
                                    _whatsappExists = false;
                                  }
                                  if (emailDup) {
                                    _emailController.clear();
                                    _email = '';
                                    _emailError = null;
                                    _isEmailValid = false;
                                    _emailExists = false;
                                  }
                                });
                                if (whatsappDup) {
                                  _whatsappFocusNode.requestFocus();
                                } else if (emailDup) {
                                  _emailFocusNode.requestFocus();
                                }
                              },
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                            side: BorderSide(color: Colors.grey.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            isArabic ? 'تعديل' : 'Modifier',
                            style: GoogleFonts.cairo(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            // ✅ Rediriger vers la page de connexion
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff0D443E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            isArabic ? 'تسجيل الدخول' : 'Se connecter',
                            style: GoogleFonts.cairo(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDuplicateValueChip({
    required IconData icon,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ POPUP SUCCÈS MODERNE
  // ============================================================
  void _showSuccessPopup(
    BuildContext context,
    bool isArabic,
    String identifiant,
    String motDePasse,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        final screenSize = MediaQuery.of(context).size;
        return Dialog(
          alignment: Alignment.center,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            width: screenSize.width > 500 ? 440 : double.infinity,
            constraints: BoxConstraints(maxHeight: screenSize.height * 0.85),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff0D443E).withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ✅ Cercle de succès
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xff0D443E), Color(0xff1a6b5e)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xff0D443E).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 42,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ✅ Titre
                  Text(
                    isArabic
                        ? '🎉 تم التسجيل بنجاح'
                        : '🎉 Inscription réussie !',
                    style: GoogleFonts.cairo(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff0D443E),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  Text(
                    isArabic
                        ? 'مرحباً بك في أكاديمية نفحات'
                        : 'Bienvenue à l\'Académie Nafahat',
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // ✅ Identifiants
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xff0D443E).withOpacity(0.05),
                          const Color(0xff0D443E).withOpacity(0.02),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xff0D443E).withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          isArabic ? '📱 Identifiant' : '📱 Identifiant',
                          identifiant,
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          isArabic ? '🔑 Mot de passe' : '🔑 Mot de passe',
                          motDePasse,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ✅ Avertissement
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          isArabic
                              ? '⚠️ Conservez ces informations précieusement'
                              : '⚠️ Conservez ces informations précieusement',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ✅ Bouton
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // ✅ Rediriger vers la page de connexion
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff0D443E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isArabic ? 'تسجيل الدخول' : 'Se connecter',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey.shade600),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xff0D443E).withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xff0D443E).withOpacity(0.15),
            ),
          ),
          child: Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xff0D443E),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FONCTIONS DE GESTION
  // ============================================================
  void _ajouterEnfant() {
    setState(() {
      _enfants.add(
        Enfant(
          nomPrenom: '',
          dateNaissance: DateTime.now(),
          genre: 'homme',
          niveauTilawa: 'debutant',
        ),
      );
    });
  }

  void _retirerEnfant(int index) {
    setState(() {
      _enfants.removeAt(index);
    });
  }

  void _updateAdherentField(String key, dynamic value) {
    setState(() {
      switch (key) {
        case 'whatsapp':
          _whatsapp = value;
          break;
        case 'nomPrenom':
          _nomPrenom = value;
          break;
        case 'pays':
          _pays = value;
          break;
        case 'ville':
          _ville = value;
          break;
        case 'email':
          _email = value;
          break;
        case 'dateNaissance':
          _dateNaissance = value;
          break;
        case 'genre':
          _genre = value;
          break;
        case 'sourceConnaissance':
          _sourceConnaissance = value;
          break;
        case 'sourceAutreDetail':
          _sourceAutreDetail = value;
          break;
        case 'objectif':
          _objectif = value;
          break;
        case 'suggestions':
          _suggestions = value;
          break;
        case 'accordPublication':
          _accordPublication = value;
          break;
      }
    });
  }

  void _updateEnfantField(int index, String key, dynamic value) {
    setState(() {
      final e = _enfants[index];
      switch (key) {
        case 'nomPrenom':
          e.nomPrenom = value;
          break;
        case 'dateNaissance':
          e.dateNaissance = value;
          break;
        case 'genre':
          e.genre = value;
          break;
        case 'niveauTilawa':
          e.niveauTilawa = value;
          break;
        case 'memorisation':
          e.memorisation = value;
          break;
        case 'memorisationAutreDetail':
          e.memorisationAutreDetail = value;
          break;
        case 'objectif':
          e.objectif = value;
          break;
        case 'accordInscription':
          e.accordInscription = value;
          break;
      }
      _enfants[index] = e;
    });
  }

  // ============================================================
  // SOUMISSION FINALE
  // ============================================================
  Future<void> _soumettre(bool isArabic) async {
    if (_nomPrenom.isEmpty || _pays.isEmpty || _ville.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'Veuillez remplir tous les champs obligatoires (*)'
                : 'Veuillez remplir tous les champs obligatoires (*)',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // ✅ Revérifier au moment de la soumission (sécurité) puis bloquer
    //    avec le popup unique si un doublon existe.
    _debounceTimer?.cancel();
    if (_whatsapp.isNotEmpty) {
      await _validateWhatsapp(_whatsapp);
    }
    if (_email.isNotEmpty) {
      await _checkEmail(_email);
    }

    if (_whatsappExists || _emailExists) {
      await _showDuplicatePopupIfNeeded();
      return;
    }

    setState(() => isLoading = true);

    try {
      final adherent = Adherent(
        whatsapp: '$_selectedCountryCode$_whatsapp',
        nomPrenom: _nomPrenom,
        pays: _pays,
        ville: _ville,
        email: _email,
        dateNaissance: _dateNaissance,
        genre: _genre,
        sourceConnaissance: _sourceConnaissance,
        sourceAutreDetail: _sourceAutreDetail,
        objectif: _objectif,
        suggestions: _suggestions,
        accordPublication: _accordPublication,
      );

      final result = await AdherentService.inscrireAdherent(adherent, _enfants);

      if (mounted) {
        _showSuccessPopup(
          context,
          isArabic,
          result['credentials']['identifiant'],
          result['motDePasse'],
        );
      }
    } catch (e) {
      if (mounted) {
        // ✅ Le serveur reste la source de vérité finale : si l'inscription
        //    échoue avec un 409 "déjà enregistré", on affiche le MÊME popup
        //    unique (au lieu d'un message d'erreur brut), même si les
        //    pré-vérifications côté champ ne l'avaient pas détecté.
        final handledAsDuplicate = await _handleDuplicateSubmitError(e);
        if (!handledAsDuplicate) {
          final errorMsg = e.toString().replaceFirst('Exception: ', '');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ $errorMsg', style: GoogleFonts.cairo()),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ✅ Analyse une erreur d'inscription (409 avec fieldErrors whatsapp/email)
  //    et affiche le popup de doublon unique et précis si applicable.
  //    Retourne true si l'erreur a été prise en charge par le popup.
  Future<bool> _handleDuplicateSubmitError(Object error) async {
    final raw = error.toString();
    if (!raw.contains('409')) return false;

    final jsonStart = raw.indexOf('{');
    if (jsonStart == -1) return false;

    Map<String, dynamic> data;
    try {
      data = json.decode(raw.substring(jsonStart)) as Map<String, dynamic>;
    } catch (_) {
      return false;
    }

    final fieldErrors = data['fieldErrors'];
    final whatsappDup =
        fieldErrors is Map && fieldErrors.containsKey('whatsapp');
    final emailDup = fieldErrors is Map && fieldErrors.containsKey('email');

    if (!whatsappDup && !emailDup) return false;
    if (!mounted) return true;

    setState(() {
      if (whatsappDup) {
        _whatsappExists = true;
        _isWhatsappValid = false;
        _whatsappError =
            _isArabic
                ? '⚠️ رقم الواتساب هذا مستعمل بالفعل'
                : '⚠️ Ce numéro WhatsApp est déjà utilisé';
      }
      if (emailDup) {
        _emailExists = true;
        _isEmailValid = false;
        _emailError =
            _isArabic
                ? '⚠️ هذا البريد الإلكتروني مستعمل بالفعل'
                : '⚠️ Cet email est déjà utilisé';
      }
    });

    if (_popupVisible) return true;
    _popupVisible = true;
    await _showDuplicatePopup(whatsappDup: whatsappDup, emailDup: emailDup);
    _popupVisible = false;
    return true;
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final isDesktop = screenWidth >= 1200;

    final double horizontalPadding = isMobile ? 16 : (isTablet ? 32 : 64);
    final double verticalPadding = isMobile ? 16 : (isTablet ? 24 : 40);
    final double cardPadding = isMobile ? 16 : 24;
    final double maxWidth = isDesktop ? 800 : double.infinity;
    final double fontSize = isMobile ? 14 : 16;
    final double topMargin = isMobile ? 100 : 90;

    return ChatbotWrapper(
      apiBaseUrl: 'http://localhost:3000',
      langue: isArabic ? 'ar' : 'fr',
      primaryColor: const Color(0xff0D443E),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.grey.shade50,
        body: SafeArea(
          top: false,
          child: Stack(
            children: [
              // ---- Contenu principal ----
              Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(top: topMargin),
                    child: Column(
                      children: [
                        Card(
                          elevation: isDesktop ? 4 : 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(cardPadding),
                            child: Column(
                              children: [
                                _buildWhatsAppField(
                                  isArabic,
                                  isMobile,
                                  fontSize,
                                ),
                                const SizedBox(height: 12),
                                _buildEmailField(isArabic, fontSize),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  label:
                                      isArabic
                                          ? 'الاسم واللقب *'
                                          : 'Nom et Prénom *',
                                  initialValue: _nomPrenom,
                                  onChanged:
                                      (v) =>
                                          _updateAdherentField('nomPrenom', v),
                                  required: true,
                                  fontSize: fontSize,
                                  focusNode: _nomFocusNode,
                                ),
                                _buildTextField(
                                  label: isArabic ? 'بلد الإقامة *' : 'Pays *',
                                  initialValue: _pays,
                                  onChanged:
                                      (v) => _updateAdherentField('pays', v),
                                  required: true,
                                  fontSize: fontSize,
                                ),
                                _buildTextField(
                                  label: isArabic ? 'المدينة *' : 'Ville *',
                                  initialValue: _ville,
                                  onChanged:
                                      (v) => _updateAdherentField('ville', v),
                                  required: true,
                                  fontSize: fontSize,
                                ),
                                _buildDatePicker(
                                  label:
                                      isArabic
                                          ? 'تاريخ الولادة'
                                          : 'Date de naissance',
                                  value: _dateNaissance,
                                  onChanged:
                                      (date) => _updateAdherentField(
                                        'dateNaissance',
                                        date,
                                      ),
                                  fontSize: fontSize,
                                ),
                                _buildGenderRadio(isArabic, fontSize),
                                _buildSourceRadio(isArabic, fontSize),
                                if (_sourceConnaissance == 'autre')
                                  _buildTextField(
                                    label:
                                        isArabic
                                            ? 'الرجاء التوضيح'
                                            : 'Précisez',
                                    initialValue: _sourceAutreDetail,
                                    onChanged:
                                        (v) => _updateAdherentField(
                                          'sourceAutreDetail',
                                          v,
                                        ),
                                    fontSize: fontSize,
                                  ),
                                _buildTextField(
                                  label:
                                      isArabic
                                          ? 'ما هو هدفك من الالتحاق بهذه الدورات ؟'
                                          : 'Quel est votre objectif en rejoignant ces cycles ?',
                                  initialValue: _objectif,
                                  onChanged:
                                      (v) =>
                                          _updateAdherentField('objectif', v),
                                  maxLines: 3,
                                  fontSize: fontSize,
                                ),
                                _buildTextField(
                                  label:
                                      isArabic
                                          ? 'اقتراحات دورات و مواضيع دروس تريد أن نبرمجها مستقبلا'
                                          : 'Suggestions de cours et sujets à programmer',
                                  initialValue: _suggestions,
                                  onChanged:
                                      (v) => _updateAdherentField(
                                        'suggestions',
                                        v,
                                      ),
                                  maxLines: 2,
                                  fontSize: fontSize,
                                ),
                                _buildCheckbox(
                                  label:
                                      isArabic
                                          ? 'أوافق على نشر محتوى الدورات على صفحات أكاديمية نفحات'
                                          : 'J\'accepte la publication du contenu des cycles sur les pages de Nafahat',
                                  value: _accordPublication,
                                  onChanged:
                                      (v) => _updateAdherentField(
                                        'accordPublication',
                                        v,
                                      ),
                                  fontSize: fontSize,
                                ),
                                _buildToggleEnfants(isArabic, fontSize),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (ajouterEnfants)
                          _buildEnfantsSection(isArabic, fontSize, isMobile),
                        const SizedBox(height: 30),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                isLoading ? null : () => _soumettre(isArabic),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: isMobile ? 14 : 18,
                                horizontal: 20,
                              ),
                              backgroundColor: const Color(0xff0D443E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child:
                                isLoading
                                    ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : Text(
                                      isArabic ? 'تسجيل' : 'S\'inscrire',
                                      style: GoogleFonts.cairo(
                                        fontSize: fontSize + 2,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),

              // ---- NAVBAR ----
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Navbar(isMobile: isMobile, scaffoldKey: _scaffoldKey),
              ),

              if (isLoading)
                const Opacity(
                  opacity: 0.5,
                  child: ModalBarrier(dismissible: false, color: Colors.black),
                ),
              if (isLoading) const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CHAMP WHATSAPP
  // ============================================================
  Widget _buildWhatsAppField(bool isArabic, bool isMobile, double fontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: isMobile ? 100 : 130,
              decoration: BoxDecoration(
                border: Border.all(
                  color:
                      _whatsappError != null
                          ? Colors.red.shade400
                          : Colors.grey.shade400,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCountryCode,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down),
                  items:
                      _countryCodes.map((country) {
                        return DropdownMenuItem<String>(
                          value: country['code'],
                          child: Text('${country['flag']} ${country['code']}'),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCountryCode = value);
                      if (_whatsappController.text.isNotEmpty) {
                        _debounceTimer?.cancel();
                        _validateWhatsapp(_whatsappController.text);
                      }
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _whatsappController,
                focusNode: _whatsappFocusNode,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText:
                      isArabic
                          ? 'رقم الواتساب (مع رمز البلد) *'
                          : 'Numéro WhatsApp *',
                  hintText: '25357461',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelStyle: GoogleFonts.cairo(
                    fontSize: fontSize,
                    color:
                        _whatsappError != null
                            ? Colors.red.shade700
                            : Colors.grey.shade700,
                  ),
                  hintStyle: GoogleFonts.cairo(fontSize: fontSize),
                  errorText: _whatsappError,
                  errorStyle: GoogleFonts.cairo(
                    fontSize: fontSize - 2,
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(
                    Icons.phone_android_rounded,
                    color:
                        _whatsappError != null
                            ? Colors.red.shade700
                            : const Color(0xff0D443E),
                  ),
                  suffixIcon:
                      _isWhatsappChecking
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: Padding(
                              padding: EdgeInsets.all(10.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xff0D443E),
                              ),
                            ),
                          )
                          : (_isWhatsappValid &&
                                  _whatsappController.text.length >= 8
                              ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              )
                              : null),
                ),
                style: GoogleFonts.cairo(fontSize: fontSize),
                keyboardType: TextInputType.phone,
                onChanged: (v) {
                  _whatsapp = v;
                  _updateAdherentField('whatsapp', v);
                },
                onFieldSubmitted: (v) async {
                  // ✅ Vérifier AVANT de passer au champ suivant
                  _debounceTimer?.cancel();
                  await _validateWhatsapp(v);
                  if (_whatsappExists) {
                    _showDuplicatePopupIfNeeded();
                  } else {
                    FocusScope.of(context).requestFocus(_emailFocusNode);
                  }
                },
              ),
            ),
          ],
        ),
        if (_whatsappError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 8),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: Colors.red.shade700,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _whatsappError!,
                    style: GoogleFonts.cairo(
                      fontSize: fontSize - 2,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ============================================================
  // CHAMP EMAIL
  // ============================================================
  Widget _buildEmailField(bool isArabic, double fontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _emailController,
          focusNode: _emailFocusNode,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: isArabic ? 'البريد الإلكتروني - EMAIL *' : 'E-mail *',
            hintText: 'exemple@email.com',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            labelStyle: GoogleFonts.cairo(
              fontSize: fontSize,
              color:
                  _emailError != null
                      ? Colors.red.shade700
                      : Colors.grey.shade700,
            ),
            hintStyle: GoogleFonts.cairo(fontSize: fontSize),
            errorText: _emailError,
            errorStyle: GoogleFonts.cairo(
              fontSize: fontSize - 2,
              color: Colors.red.shade700,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              Icons.alternate_email_rounded,
              color:
                  _emailError != null
                      ? Colors.red.shade700
                      : const Color(0xff0D443E),
            ),
            suffixIcon:
                _isEmailChecking
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: Padding(
                        padding: EdgeInsets.all(10.0),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xff0D443E),
                        ),
                      ),
                    )
                    : (_isEmailValid &&
                            _emailController.text.isNotEmpty &&
                            _emailController.text.contains('@')
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null),
          ),
          style: GoogleFonts.cairo(fontSize: fontSize),
          keyboardType: TextInputType.emailAddress,
          onChanged: (v) {
            _email = v;
            _updateAdherentField('email', v);
          },
          onFieldSubmitted: (v) async {
            // ✅ Vérifier AVANT de passer au champ suivant
            _debounceTimer?.cancel();
            if (v.isNotEmpty && v.contains('@')) {
              await _checkEmail(v);
            }
            if (_emailExists) {
              _showDuplicatePopupIfNeeded();
            } else {
              FocusScope.of(context).requestFocus(_nomFocusNode);
            }
          },
        ),
        if (_emailError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 8),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: Colors.red.shade700,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _emailError!,
                    style: GoogleFonts.cairo(
                      fontSize: fontSize - 2,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ============================================================
  // WIDGETS GÉNÉRIQUES
  // ============================================================
  Widget _buildTextField({
    required String label,
    String? initialValue,
    required Function(String) onChanged,
    bool required = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
    double fontSize = 14,
    FocusNode? focusNode,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        initialValue: initialValue,
        focusNode: focusNode,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          labelStyle: GoogleFonts.cairo(fontSize: fontSize),
          hintStyle: GoogleFonts.cairo(fontSize: fontSize),
        ),
        style: GoogleFonts.cairo(fontSize: fontSize),
        maxLines: maxLines,
        keyboardType: keyboardType,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime value,
    required Function(DateTime) onChanged,
    double fontSize = 14,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: InkWell(
        onTap: () async {
          DateTime? picked = await showDatePicker(
            context: context,
            initialDate: value,
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (picked != null) onChanged(picked);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            labelStyle: GoogleFonts.cairo(fontSize: fontSize),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd/MM/yyyy').format(value),
                style: GoogleFonts.cairo(fontSize: fontSize),
              ),
              Icon(Icons.calendar_today, size: fontSize + 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderRadio(bool isArabic, double fontSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'الجنس' : 'Genre',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w500,
              fontSize: fontSize,
            ),
          ),
          Row(
            children: [
              _buildRadioOption('homme', isArabic ? 'ذكر' : 'Homme', fontSize),
              _buildRadioOption('femme', isArabic ? 'أنثى' : 'Femme', fontSize),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption(String value, String label, double fontSize) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: _genre,
          onChanged: (v) => _updateAdherentField('genre', v),
          activeColor: const Color(0xff0D443E),
        ),
        Text(label, style: GoogleFonts.cairo(fontSize: fontSize)),
      ],
    );
  }

  Widget _buildSourceRadio(bool isArabic, double fontSize) {
    final List<Map<String, dynamic>> sources = [
      {
        'key': 'instagram',
        'icon': Icons.camera_alt,
        'labelFr': 'Instagram',
        'labelAr': 'إنستغرام',
      },
      {
        'key': 'facebook',
        'icon': Icons.facebook,
        'labelFr': 'Facebook',
        'labelAr': 'فيسبوك',
      },
      {
        'key': 'ami',
        'icon': Icons.people,
        'labelFr': 'Ami(e)',
        'labelAr': 'صديق/ة',
      },
      {
        'key': 'annonce',
        'icon': Icons.ads_click,
        'labelFr': 'Annonce',
        'labelAr': 'إعلان ممول',
      },
      {
        'key': 'autre',
        'icon': Icons.more_horiz,
        'labelFr': 'Autre',
        'labelAr': 'أخرى',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic
                ? 'كيف تعرفت على الأكاديمية؟'
                : 'Comment avez-vous connu l\'académie ?',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w500,
              fontSize: fontSize,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                sources.map((src) {
                  final isSelected = _sourceConnaissance == src['key'];
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          src['icon'],
                          size: 18,
                          color: isSelected ? Colors.white : Colors.black54,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isArabic ? src['labelAr'] : src['labelFr'],
                          style: GoogleFonts.cairo(fontSize: fontSize),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        _updateAdherentField('sourceConnaissance', src['key']);
                      }
                    },
                    selectedColor: const Color(0xff0D443E),
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: GoogleFonts.cairo(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: fontSize,
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleEnfants(bool isArabic, double fontSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic
                ? 'هل تريد تسجيل أطفالك أيضا ؟'
                : 'Voulez-vous aussi inscrire vos enfants ?',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w500,
              fontSize: fontSize,
            ),
          ),
          Row(
            children: [
              _buildToggleOption(true, isArabic ? 'نعم' : 'Oui', fontSize),
              _buildToggleOption(false, isArabic ? 'لا' : 'Non', fontSize),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(bool value, String label, double fontSize) {
    return Row(
      children: [
        Radio<bool>(
          value: value,
          groupValue: ajouterEnfants,
          onChanged: (val) {
            if (val != null) {
              setState(() {
                ajouterEnfants = val;
                if (!val) _enfants.clear();
              });
            }
          },
          activeColor: const Color(0xff0D443E),
        ),
        Text(label, style: GoogleFonts.cairo(fontSize: fontSize)),
      ],
    );
  }

  Widget _buildEnfantsSection(bool isArabic, double fontSize, bool isMobile) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isArabic
                      ? 'معلومات عن الأبناء'
                      : 'Informations sur les enfants',
                  style: GoogleFonts.cairo(
                    fontSize: fontSize + 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _ajouterEnfant,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_enfants.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Center(
                  child: Text(
                    isArabic
                        ? 'لا يوجد أطفال مسجلين. اضغط على + لإضافة طفل'
                        : 'Aucun enfant enregistré. Appuyez sur + pour en ajouter',
                    style: GoogleFonts.cairo(
                      color: Colors.grey.shade600,
                      fontSize: fontSize,
                    ),
                  ),
                ),
              )
            else
              SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  children:
                      _enfants.asMap().entries.map((entry) {
                        int idx = entry.key;
                        Enfant enfant = entry.value;
                        return Column(
                          children: [
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${isArabic ? 'الابن' : 'Enfant'} ${idx + 1}',
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold,
                                    fontSize: fontSize,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _retirerEnfant(idx),
                                ),
                              ],
                            ),
                            _buildTextField(
                              label:
                                  isArabic
                                      ? 'الاسم واللقب *'
                                      : 'Nom et Prénom *',
                              initialValue: enfant.nomPrenom,
                              onChanged:
                                  (v) =>
                                      _updateEnfantField(idx, 'nomPrenom', v),
                              required: true,
                              fontSize: fontSize,
                            ),
                            _buildDatePicker(
                              label:
                                  isArabic
                                      ? 'تاريخ الولادة'
                                      : 'Date de naissance',
                              value: enfant.dateNaissance,
                              onChanged:
                                  (date) => _updateEnfantField(
                                    idx,
                                    'dateNaissance',
                                    date,
                                  ),
                              fontSize: fontSize,
                            ),
                            _buildEnfantGenderRadio(idx, isArabic, fontSize),
                            _buildDropdown(
                              label:
                                  isArabic
                                      ? 'ما هو مستوى تلاوة طفلك'
                                      : 'Niveau de récitation',
                              value: enfant.niveauTilawa,
                              items:
                                  [
                                    'debutant',
                                    'quelques_sourates',
                                    'avance',
                                  ].map((n) {
                                    String label =
                                        isArabic
                                            ? {
                                              'debutant': 'مبتدئ من الصفر',
                                              'quelques_sourates':
                                                  'يحفظ بعض قصار السور',
                                              'avance':
                                                  'متقدم : حافظ و متقن لأحكام التلاوة',
                                            }[n]!
                                            : n;
                                    return DropdownMenuItem(
                                      value: n,
                                      child: Text(
                                        label,
                                        style: GoogleFonts.cairo(),
                                      ),
                                    );
                                  }).toList(),
                              onChanged:
                                  (v) => _updateEnfantField(
                                    idx,
                                    'niveauTilawa',
                                    v,
                                  ),
                              fontSize: fontSize,
                            ),
                            if (enfant.niveauTilawa == 'avance') ...[
                              _buildDropdown(
                                label:
                                    isArabic
                                        ? 'كم يحفظ من كتاب الله'
                                        : 'Mémorisation',
                                value: enfant.memorisation ?? 'juz_amma',
                                items:
                                    ['juz_amma', 'plus_5_hizbs', 'autre'].map((
                                      m,
                                    ) {
                                      String label =
                                          isArabic
                                              ? {
                                                'juz_amma': 'جزء عم',
                                                'plus_5_hizbs':
                                                    'أكثر من 5 أحزاب',
                                                'autre': 'Autre :',
                                              }[m]!
                                              : m;
                                      return DropdownMenuItem(
                                        value: m,
                                        child: Text(
                                          label,
                                          style: GoogleFonts.cairo(),
                                        ),
                                      );
                                    }).toList(),
                                onChanged:
                                    (v) => _updateEnfantField(
                                      idx,
                                      'memorisation',
                                      v,
                                    ),
                                fontSize: fontSize,
                              ),
                              if (enfant.memorisation == 'autre')
                                _buildTextField(
                                  label:
                                      isArabic ? 'الرجاء التوضيح' : 'Précisez',
                                  initialValue: enfant.memorisationAutreDetail,
                                  onChanged:
                                      (v) => _updateEnfantField(
                                        idx,
                                        'memorisationAutreDetail',
                                        v,
                                      ),
                                  fontSize: fontSize,
                                ),
                            ],
                            _buildTextField(
                              label:
                                  isArabic
                                      ? 'ما هو هدفك من التحاق طفلك بهذه الدورات ؟'
                                      : 'Objectif pour votre enfant',
                              initialValue: enfant.objectif,
                              onChanged:
                                  (v) => _updateEnfantField(idx, 'objectif', v),
                              maxLines: 2,
                              fontSize: fontSize,
                            ),
                            _buildCheckbox(
                              label: isArabic ? 'موافق' : 'J\'accepte',
                              value: enfant.accordInscription ?? false,
                              onChanged:
                                  (v) => _updateEnfantField(
                                    idx,
                                    'accordInscription',
                                    v,
                                  ),
                              fontSize: fontSize,
                            ),
                            const SizedBox(height: 8),
                          ],
                        );
                      }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnfantGenderRadio(int index, bool isArabic, double fontSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            isArabic ? 'الجنس' : 'Genre',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w500,
              fontSize: fontSize,
            ),
          ),
          const SizedBox(width: 20),
          _buildRadioEnfantOption(
            index,
            'homme',
            isArabic ? 'ذكر' : 'Homme',
            fontSize,
          ),
          _buildRadioEnfantOption(
            index,
            'femme',
            isArabic ? 'أنثى' : 'Femme',
            fontSize,
          ),
        ],
      ),
    );
  }

  Widget _buildRadioEnfantOption(
    int index,
    String value,
    String label,
    double fontSize,
  ) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: _enfants[index].genre,
          onChanged: (v) => _updateEnfantField(index, 'genre', v),
          activeColor: const Color(0xff0D443E),
        ),
        Text(label, style: GoogleFonts.cairo(fontSize: fontSize)),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    double fontSize = 14,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          labelStyle: GoogleFonts.cairo(fontSize: fontSize),
        ),
        style: GoogleFonts.cairo(fontSize: fontSize, color: Colors.black87),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildCheckbox({
    required String label,
    required bool value,
    required Function(bool?) onChanged,
    double fontSize = 14,
  }) {
    return CheckboxListTile(
      title: Text(label, style: GoogleFonts.cairo(fontSize: fontSize)),
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
