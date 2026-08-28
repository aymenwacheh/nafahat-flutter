// lib/pages/adminisration/creer_user_page.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/language_provider.dart';
import '../../services/AdminUserService.dart';
import '../../models/adherent.dart';
import '../../models/role.dart';
import 'admin_page_wrapper.dart';

class CreerUserPage extends StatefulWidget {
  const CreerUserPage({super.key});

  @override
  State<CreerUserPage> createState() => _CreerUserPageState();
}

class _CreerUserPageState extends State<CreerUserPage> {
  bool _isLoading = false;
  bool _isLoadingRoles = true;

  // ---- Listes ----
  List<Role> _roles = [];
  Role? _selectedRole;

  // ---- Champs essentiels ----
  String _whatsapp = '';
  String _selectedCountryCode = '+216';
  String _nomPrenom = '';
  String _email = '';

  // ---- Mot de passe personnalisé (optionnel) ----
  String _motDePassePersonnalise = '';
  bool _utiliserMotDePassePersonnalise = false;

  // ---- Contrôleurs ----
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _motDePasseController = TextEditingController();

  final FocusNode _whatsappFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _nomFocusNode = FocusNode();

  // ---- États de validation ----
  String? _whatsappError;
  String? _emailError;
  bool _isWhatsappValid = false;
  bool _isEmailValid = false;
  bool _isWhatsappChecking = false;
  bool _isEmailChecking = false;
  bool _whatsappExists = false;
  bool _emailExists = false;

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

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  @override
  void dispose() {
    _whatsappController.dispose();
    _emailController.dispose();
    _nomController.dispose();
    _motDePasseController.dispose();
    _whatsappFocusNode.dispose();
    _emailFocusNode.dispose();
    _nomFocusNode.dispose();
    super.dispose();
  }

  bool get _isArabic =>
      Provider.of<LanguageProvider>(context, listen: false).isArabic;

  // ============================================================
  // CHARGEMENT DES RÔLES
  // ============================================================
  Future<void> _loadRoles() async {
    setState(() => _isLoadingRoles = true);
    try {
      final roles = await AdminUserService.getRoles();
      if (mounted) {
        setState(() {
          _roles = roles;
          _isLoadingRoles = false;
          if (roles.isNotEmpty) {
            _selectedRole = roles.first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRoles = false);
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
  // VALIDATION WHATSAPP
  // ============================================================
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

  // ============================================================
  // VALIDATION EMAIL
  // ============================================================
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
  // SOUMISSION
  // ============================================================
  Future<void> _soumettre() async {
    final isArabic = _isArabic;

    // Vérifications
    if (_nomPrenom.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'Veuillez saisir le nom et prénom'
                : 'Veuillez saisir le nom et prénom',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_whatsapp.isEmpty || _whatsapp.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'Veuillez saisir un numéro WhatsApp valide'
                : 'Veuillez saisir un numéro WhatsApp valide',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_email.isEmpty || !_email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'Veuillez saisir un email valide'
                : 'Veuillez saisir un email valide',
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

    // Vérifier les doublons
    if (_whatsapp.isNotEmpty) {
      await _validateWhatsapp(_whatsapp);
    }
    if (_email.isNotEmpty) {
      await _checkEmail(_email);
    }

    if (_whatsappExists || _emailExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'Le numéro WhatsApp ou l\'email est déjà utilisé'
                : 'Le numéro WhatsApp ou l\'email est déjà utilisé',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Adhérent avec seulement les champs essentiels
      final adherent = Adherent(
        whatsapp: '$_selectedCountryCode$_whatsapp',
        nomPrenom: _nomPrenom,
        email: _email,
        pays: '', // Vide par défaut
        ville: '', // Vide par défaut
        dateNaissance: DateTime.now(), // Valeur par défaut
        genre: 'homme', // Valeur par défaut
        sourceConnaissance: 'instagram', // Valeur par défaut
        sourceAutreDetail: null,
        objectif: null,
        suggestions: null,
        accordPublication: false,
      );

      final result = await AdminUserService.creerUtilisateur(
        adherent: adherent,
        enfants: [], // Aucun enfant
        roleId: _selectedRole!.id,
        motDePassePersonnalise:
            _utiliserMotDePassePersonnalise
                ? (_motDePassePersonnalise.isNotEmpty
                    ? _motDePassePersonnalise
                    : null)
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
        final errorMsg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $errorMsg', style: GoogleFonts.cairo()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.all(28),
            constraints: const BoxConstraints(maxWidth: 440),
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
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff0D443E),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xff0D443E).withOpacity(0.05),
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
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff0D443E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isDesktop = screenWidth >= 1200;

    final double horizontalPadding = isMobile ? 16 : 40;
    final double cardPadding = isMobile ? 16 : 24;
    final double fontSize = isMobile ? 14 : 16;

    return AdminPageWrapper(
      title: 'Créer un utilisateur',
      titleAr: 'إنشاء مستخدم',
      backgroundColor: Colors.grey.shade50,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 20,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- En-tête ----
                Text(
                  isArabic
                      ? 'Créer un nouvel utilisateur'
                      : 'Créer un nouvel utilisateur',
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 24 : 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff0D443E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isArabic
                      ? 'Remplissez les informations pour créer un compte utilisateur (admin, formateur, etc.)'
                      : 'Remplissez les informations pour créer un compte utilisateur (admin, formateur, etc.)',
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 14 : 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),

                // ---- Formulaire ----
                Card(
                  elevation: isDesktop ? 4 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      children: [
                        // ---- Rôle ----
                        if (_isLoadingRoles)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_roles.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
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

                        // ---- WhatsApp ----
                        _buildWhatsAppField(isArabic, isMobile, fontSize),
                        const SizedBox(height: 16),

                        // ---- Email ----
                        _buildEmailField(isArabic, fontSize),
                        const SizedBox(height: 16),

                        // ---- Nom/Prénom ----
                        _buildTextField(
                          label:
                              isArabic ? 'الاسم واللقب *' : 'Nom et Prénom *',
                          controller: _nomController,
                          onChanged: (v) => _nomPrenom = v,
                          focusNode: _nomFocusNode,
                          fontSize: fontSize,
                        ),

                        const Divider(height: 32),

                        // ---- Mot de passe personnalisé ----
                        _buildMotDePassePersonnalise(isArabic, fontSize),

                        const SizedBox(height: 24),

                        // ---- Bouton de soumission ----
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _soumettre,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: isMobile ? 14 : 18,
                              ),
                              backgroundColor: const Color(0xff0D443E),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SÉLECTEUR DE RÔLE
  // ============================================================
  Widget _buildRoleSelector(bool isArabic, double fontSize) {
    final uniqueRoles = _roles.toSet().toList();
    final bool hasValidRole = uniqueRoles.any(
      (role) => role.id == _selectedRole?.id,
    );
    final Role? effectiveRole = hasValidRole ? _selectedRole : null;

    return DropdownButtonFormField<Role>(
      key: ValueKey('role_dropdown_${effectiveRole?.id ?? 'none'}'),
      initialValue: effectiveRole,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: isArabic ? 'الدور *' : 'Rôle *',
        border: const OutlineInputBorder(),
        labelStyle: GoogleFonts.cairo(fontSize: fontSize),
        prefixIcon: Icon(
          Icons.admin_panel_settings_rounded,
          color: const Color(0xff0D443E),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      style: GoogleFonts.cairo(fontSize: fontSize, color: Colors.black87),
      menuMaxHeight: 200,
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
                  labelText: isArabic ? 'رقم الواتساب *' : 'Numéro WhatsApp *',
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
                onChanged: (v) => _whatsapp = v,
                onFieldSubmitted: (v) async {
                  await _validateWhatsapp(v);
                  if (!_whatsappExists) {
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
            labelText: isArabic ? 'البريد الإلكتروني *' : 'E-mail *',
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
          onChanged: (v) => _email = v,
          onFieldSubmitted: (v) async {
            if (v.isNotEmpty && v.contains('@')) {
              await _checkEmail(v);
            }
            if (!_emailExists) {
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
  // CHAMP TEXTE GÉNÉRIQUE
  // ============================================================
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required Function(String) onChanged,
    FocusNode? focusNode,
    double fontSize = 14,
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          labelStyle: GoogleFonts.cairo(fontSize: fontSize),
        ),
        style: GoogleFonts.cairo(fontSize: fontSize),
        onChanged: onChanged,
        validator: (value) {
          if (required && (value == null || value.isEmpty)) {
            return 'Champ requis';
          }
          return null;
        },
      ),
    );
  }

  // ============================================================
  // MOT DE PASSE PERSONNALISÉ
  // ============================================================
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
                    isArabic ? 'Minimum 6 caractères' : 'Minimum 6 caractères',
                border: const OutlineInputBorder(),
                labelStyle: GoogleFonts.cairo(fontSize: fontSize),
                hintStyle: GoogleFonts.cairo(fontSize: fontSize),
                prefixIcon: const Icon(Icons.lock_outline_rounded),
              ),
              style: GoogleFonts.cairo(fontSize: fontSize),
              obscureText: true,
              onChanged: (v) => _motDePassePersonnalise = v,
              validator: (value) {
                if (_utiliserMotDePassePersonnalise &&
                    (value == null || value.length < 6)) {
                  return 'Le mot de passe doit contenir au moins 6 caractères';
                }
                return null;
              },
            ),
          ),
      ],
    );
  }
}
