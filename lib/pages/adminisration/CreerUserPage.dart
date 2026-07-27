// lib/pages/administration/creer_user_page.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/language_provider.dart';
import '../landing/widgets/navbar.dart';
import '../../services/AdminUserService.dart';
import '../../models/adherent.dart';
import '../../models/enfant.dart';
import '../../models/role.dart';

// ============================================================
// PAGE PRINCIPALE - CRÉATION UTILISATEUR (SUPER ADMIN)
// ============================================================
class CreerUserPage extends StatefulWidget {
  const CreerUserPage({super.key});

  @override
  State<CreerUserPage> createState() => _CreerUserPageState();
}

class _CreerUserPageState extends State<CreerUserPage> {
  bool isLoading = false;
  bool isLoadingRoles = true;

  // ---- Listes ----
  List<Role> _roles = [];
  Role? _selectedRole;

  // ---- Données utilisateur ----
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

  // ---- Mot de passe personnalisé (optionnel) ----
  String _motDePassePersonnalise = '';
  bool _utiliserMotDePassePersonnalise = false;

  // ---- Enfants ----
  List<Enfant> _enfants = [];
  bool _ajouterEnfants = false;

  // ---- Contrôleurs ----
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _paysController = TextEditingController();
  final TextEditingController _villeController = TextEditingController();
  final TextEditingController _motDePasseController = TextEditingController();

  final FocusNode _whatsappFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _nomFocusNode = FocusNode();
  final FocusNode _paysFocusNode = FocusNode();
  final FocusNode _villeFocusNode = FocusNode();

  // ---- États de validation ----
  String? _whatsappError;
  String? _emailError;
  bool _isWhatsappValid = false;
  bool _isEmailValid = false;
  bool _isWhatsappChecking = false;
  bool _isEmailChecking = false;
  bool _whatsappExists = false;
  bool _emailExists = false;

  bool _popupVisible = false;
  Timer? _debounceTimer;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ---- Codes pays ----
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

  // ============================================================
  // INIT & DISPOSE
  // ============================================================
  @override
  void initState() {
    super.initState();
    _whatsappController.addListener(_onWhatsappChanged);
    _emailController.addListener(_onEmailChanged);
    _loadRoles();

    _whatsappFocusNode.addListener(() {
      if (!_whatsappFocusNode.hasFocus && _whatsappController.text.isNotEmpty) {
        _checkWhatsappOnExit(_whatsappController.text);
      }
    });

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
    _nomController.dispose();
    _paysController.dispose();
    _villeController.dispose();
    _motDePasseController.dispose();
    _whatsappFocusNode.dispose();
    _emailFocusNode.dispose();
    _nomFocusNode.dispose();
    _paysFocusNode.dispose();
    _villeFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  bool get _isArabic =>
      Provider.of<LanguageProvider>(context, listen: false).isArabic;

  // ============================================================
  // CHARGEMENT DES RÔLES
  // ============================================================
  Future<void> _loadRoles() async {
    setState(() => isLoadingRoles = true);
    try {
      final roles = await AdminUserService.getRoles();
      if (mounted) {
        setState(() {
          _roles = roles;
          isLoadingRoles = false;
          if (roles.isNotEmpty) {
            _selectedRole = roles.first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoadingRoles = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Erreur de chargement des rôles: $e',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ============================================================
  // VALIDATION WHATSAPP (temps réel)
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
      final exists = await AdminUserService.checkWhatsapp(fullWhatsapp);

      if (!mounted) return;

      if (exists) {
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

  Future<void> _checkWhatsappOnExit(String value) async {
    if (value.isEmpty || value.length < 8) return;
    _debounceTimer?.cancel();
    await _validateWhatsapp(value);
    _showDuplicatePopupIfNeeded();
  }

  // ============================================================
  // VALIDATION EMAIL (temps réel)
  // ============================================================
  void _onEmailChanged() {
    _email = _emailController.text;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _checkEmail(_emailController.text);
    });
  }

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
      final exists = await AdminUserService.checkEmail(value);

      if (!mounted) return;
      setState(() => _isEmailChecking = false);

      if (exists) {
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
  // POPUP UNIQUE - DOUBLONS
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
                  '🔹 Vérifiez les informations saisies.\n'
                  '🔹 Un utilisateur existe déjà avec ces identifiants.'
              : 'Le numéro WhatsApp et l\'email que vous avez saisis sont déjà '
                  'enregistrés.\n\n'
                  '🔹 Vérifiez les informations saisies.\n'
                  '🔹 Un utilisateur existe déjà avec ces identifiants.';
      icon = Icons.report_problem_rounded;
    } else if (whatsappDup) {
      title =
          isArabic
              ? '⚠️ رقم الواتساب مسجل بالفعل'
              : '⚠️ Numéro WhatsApp déjà enregistré';
      message =
          isArabic
              ? 'رقم الواتساب هذا مسجل بالفعل.\n\n'
                  '🔹 Vérifiez le numéro saisi.\n'
                  '🔹 Un autre utilisateur utilise déjà ce numéro.'
              : 'Ce numéro WhatsApp est déjà enregistré.\n\n'
                  '🔹 Vérifiez le numéro saisi.\n'
                  '🔹 Un autre utilisateur utilise déjà ce numéro.';
      icon = Icons.phone_android_rounded;
    } else {
      title =
          isArabic ? '⚠️ البريد الإلكتروني مستخدم' : '⚠️ Email déjà utilisé';
      message =
          isArabic
              ? 'هذا البريد الإلكتروني مسجل بالفعل.\n\n'
                  '🔹 Vérifiez l\'email saisi.\n'
                  '🔹 Un autre utilisateur utilise déjà cet email.'
              : 'Cet email est déjà enregistré.\n\n'
                  '🔹 Vérifiez l\'email saisi.\n'
                  '🔹 Un autre utilisateur utilise déjà cet email.';
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
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
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
                            // Fermer le popup, l'admin corrige les champs
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
                            isArabic ? 'موافق' : 'OK',
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
  // POPUP SUCCÈS
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
                  Text(
                    isArabic
                        ? '✅ تم إنشاء المستخدم بنجاح'
                        : '✅ Utilisateur créé avec succès',
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
                        ? 'المستخدم مسجل الآن dans l\'académie'
                        : 'L\'utilisateur est maintenant enregistré',
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Retour à la liste des utilisateurs ou au dashboard
                        Navigator.pop(context);
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
                        isArabic ? 'العودة' : 'Retour',
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
  // GESTION DES ENFANTS
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
  // SOUMISSION
  // ============================================================
  Future<void> _soumettre(bool isArabic) async {
    // Vérifications obligatoires
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

    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'Veuillez sélectionner un rôle'
                : 'Veuillez sélectionner un rôle',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Revérifier les doublons avant soumission
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

      final result = await AdminUserService.creerUtilisateur(
        adherent: adherent,
        enfants: _enfants,
        roleId: _selectedRole!.id,
        motDePassePersonnalise:
            _utiliserMotDePassePersonnalise
                ? _motDePassePersonnalise.isNotEmpty
                    ? _motDePassePersonnalise
                    : null
                : null,
      );

      if (mounted) {
        _showSuccessPopup(
          context,
          isArabic,
          result['identifiant'] ?? result['credentials']['identifiant'],
          result['motDePasse'] ?? result['credentials']['motDePasse'],
        );
      }
    } catch (e) {
      if (mounted) {
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
  // BUILD - VERSION CORRIGÉE
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

    // ---- Titre de la page ----
    final String pageTitle =
        isArabic ? 'إنشاء مستخدم جديد' : 'Créer un nouvel utilisateur';
    final String pageSubtitle =
        isArabic
            ? 'Remplissez les informations pour créer un compte utilisateur'
            : 'Remplissez les informations pour créer un compte utilisateur';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey.shade50,
      // ✅ Ajout du drawer pour la version mobile
      drawer: Navbar(
        isMobile: isMobile,
        scaffoldKey: _scaffoldKey,
      ).buildDrawer(context),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ---- En-tête ----
                      Text(
                        pageTitle,
                        style: GoogleFonts.cairo(
                          fontSize: isMobile ? 24 : 32,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff0D443E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pageSubtitle,
                        style: GoogleFonts.cairo(
                          fontSize: isMobile ? 14 : 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ---- Formulaire ----
                      Card(
                        elevation: isDesktop ? 4 : 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(cardPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ---- Sélecteur de rôle ----
                              if (isLoadingRoles)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else if (_roles.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                  ),
                                  child: Center(
                                    child: Text(
                                      isArabic
                                          ? '⚠️ Aucun rôle disponible'
                                          : '⚠️ Aucun rôle disponible',
                                      style: GoogleFonts.cairo(
                                        color: Colors.orange.shade700,
                                        fontSize: fontSize,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                _buildRoleSelector(isArabic, fontSize),

                              const SizedBox(height: 16),

                              // ---- Champs de l'utilisateur ----
                              _buildWhatsAppField(isArabic, isMobile, fontSize),
                              const SizedBox(height: 12),
                              _buildEmailField(isArabic, fontSize),
                              const SizedBox(height: 12),
                              _buildTextField(
                                label:
                                    isArabic
                                        ? 'الاسم واللقب *'
                                        : 'Nom et Prénom *',
                                controller: _nomController,
                                onChanged:
                                    (v) => _updateAdherentField('nomPrenom', v),
                                required: true,
                                fontSize: fontSize,
                                focusNode: _nomFocusNode,
                              ),
                              _buildTextField(
                                label: isArabic ? 'بلد الإقامة *' : 'Pays *',
                                controller: _paysController,
                                onChanged:
                                    (v) => _updateAdherentField('pays', v),
                                required: true,
                                fontSize: fontSize,
                                focusNode: _paysFocusNode,
                              ),
                              _buildTextField(
                                label: isArabic ? 'المدينة *' : 'Ville *',
                                controller: _villeController,
                                onChanged:
                                    (v) => _updateAdherentField('ville', v),
                                required: true,
                                fontSize: fontSize,
                                focusNode: _villeFocusNode,
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
                                      isArabic ? 'الرجاء التوضيح' : 'Précisez',
                                  controller: null,
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
                                        ? 'ما هو هدف المستخدم من الالتحاق بهذه الدورات ؟'
                                        : 'Quel est l\'objectif de l\'utilisateur en rejoignant ces cycles ?',
                                controller: null,
                                initialValue: _objectif,
                                onChanged:
                                    (v) => _updateAdherentField('objectif', v),
                                maxLines: 3,
                                fontSize: fontSize,
                              ),
                              _buildTextField(
                                label:
                                    isArabic
                                        ? 'اقتراحات دورات و مواضيع دروس'
                                        : 'Suggestions de cours et sujets',
                                controller: null,
                                initialValue: _suggestions,
                                onChanged:
                                    (v) =>
                                        _updateAdherentField('suggestions', v),
                                maxLines: 2,
                                fontSize: fontSize,
                              ),
                              _buildCheckbox(
                                label:
                                    isArabic
                                        ? 'أوافق على نشر محتوى الدورات sur les pages de l\'académie'
                                        : 'J\'accepte la publication du contenu des cycles',
                                value: _accordPublication,
                                onChanged:
                                    (v) => _updateAdherentField(
                                      'accordPublication',
                                      v,
                                    ),
                                fontSize: fontSize,
                              ),

                              // ---- Mot de passe personnalisé ----
                              const Divider(height: 24),
                              _buildMotDePassePersonnalise(isArabic, fontSize),

                              // ---- Enfants ----
                              const Divider(height: 24),
                              _buildToggleEnfants(isArabic, fontSize),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ---- Section enfants (si activée) ----
                      if (_ajouterEnfants)
                        _buildEnfantsSection(isArabic, fontSize, isMobile),

                      const SizedBox(height: 30),

                      // ---- Bouton de soumission ----
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
                                    isArabic
                                        ? 'إنشاء المستخدم'
                                        : 'Créer l\'utilisateur',
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
              child: Container(
                height: 85,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Navbar(isMobile: isMobile, scaffoldKey: _scaffoldKey),
              ),
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
    );
  }

  // ============================================================
  // SÉLECTEUR DE RÔLE
  // ============================================================
  // ============================================================
  // SÉLECTEUR DE RÔLE - VERSION SIMPLIFIÉE
  // ============================================================
  Widget _buildRoleSelector(bool isArabic, double fontSize) {
    // ✅ S'assurer que les rôles ont des IDs uniques
    final uniqueRoles = _roles.toSet().toList();

    // ✅ Vérifier que la valeur sélectionnée existe
    final bool hasValidRole = uniqueRoles.any(
      (role) => role.id == _selectedRole?.id,
    );
    final Role? effectiveRole = hasValidRole ? _selectedRole : null;

    return DropdownButtonFormField<Role>(
      key: ValueKey('role_dropdown_${effectiveRole?.id ?? 'none'}'),
      value: effectiveRole,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: isArabic ? 'الدور *' : 'Rôle *',
        border: const OutlineInputBorder(),
        labelStyle: GoogleFonts.cairo(fontSize: fontSize),
        prefixIcon: Icon(
          Icons.admin_panel_settings_rounded,
          color: const Color(0xff0D443E),
        ),
        // ✅ Réduire le padding vertical
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      style: GoogleFonts.cairo(fontSize: fontSize, color: Colors.black87),
      // ✅ Limiter la hauteur du menu déroulant
      menuMaxHeight: 200,
      // ✅ UNIQUEMENT le libellé du rôle, pas de description
      items:
          uniqueRoles.map((role) {
            return DropdownMenuItem<Role>(
              key: ValueKey('role_${role.id}'),
              value: role,
              child: Text(
                role.libelle,
                style: GoogleFonts.cairo(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedRole = value);
        }
      },
      hint: Text(
        isArabic ? 'اختر دوراً' : 'Sélectionnez un rôle',
        style: GoogleFonts.cairo(fontSize: fontSize),
      ),
      validator: (value) {
        if (value == null) {
          return isArabic
              ? 'الرجاء اختيار دور'
              : 'Veuillez sélectionner un rôle';
        }
        return null;
      },
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
    TextEditingController? controller,
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
        controller: controller,
        initialValue: controller == null ? initialValue : null,
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
                ? 'كيف تعرف على الأكاديمية؟'
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
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildMotDePassePersonnalise(bool isArabic, double fontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: _utiliserMotDePassePersonnalise,
              onChanged: (value) {
                setState(() {
                  _utiliserMotDePassePersonnalise = value ?? false;
                  if (!_utiliserMotDePassePersonnalise) {
                    _motDePassePersonnalise = '';
                    _motDePasseController.clear();
                  }
                });
              },
              activeColor: const Color(0xff0D443E),
            ),
            Expanded(
              child: Text(
                isArabic
                    ? 'Définir un mot de passe personnalisé'
                    : 'Définir un mot de passe personnalisé',
                style: GoogleFonts.cairo(fontSize: fontSize),
              ),
            ),
          ],
        ),
        if (_utiliserMotDePassePersonnalise)
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: TextFormField(
              controller: _motDePasseController,
              decoration: InputDecoration(
                labelText: isArabic ? 'Mot de passe' : 'Mot de passe',
                hintText:
                    isArabic
                        ? 'Entrez un mot de passe (minimum 6 caractères)'
                        : 'Entrez un mot de passe (minimum 6 caractères)',
                border: const OutlineInputBorder(),
                labelStyle: GoogleFonts.cairo(fontSize: fontSize),
                hintStyle: GoogleFonts.cairo(fontSize: fontSize),
                prefixIcon: const Icon(Icons.lock_outline_rounded),
              ),
              style: GoogleFonts.cairo(fontSize: fontSize),
              obscureText: true,
              onChanged: (v) {
                _motDePassePersonnalise = v;
              },
            ),
          ),
      ],
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
                ? 'هل تريد تسجيل أطفال أيضا ؟'
                : 'Voulez-vous aussi inscrire des enfants ?',
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
          groupValue: _ajouterEnfants,
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _ajouterEnfants = val;
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
                              controller: null,
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
                                      ? 'ما هو مستوى تلاوة الطفل'
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
                                  controller: null,
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
                                      ? 'ما هو هدف التحاق الطفل بهذه الدورات ؟'
                                      : 'Objectif pour l\'enfant',
                              controller: null,
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
}
