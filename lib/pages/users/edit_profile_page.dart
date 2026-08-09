// lib/pages/users/edit_profile_page.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../landing/landing_page.dart' show AppColors;
import 'package:nafahat/models/adherent.dart';
import 'package:nafahat/services/adherent_service.dart';
import 'package:nafahat/providers/language_provider.dart';
import 'package:nafahat/providers/user_provider.dart';
import '../landing/widgets/navbar.dart';

class EditProfilePage extends StatefulWidget {
  final String? adherentId;
  final Adherent? adherentData;

  const EditProfilePage({super.key, this.adherentId, this.adherentData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = false;
  bool _isDataLoading = true;

  // Contrôleurs
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _paysController;
  late TextEditingController _villeController;
  late TextEditingController _dateNaissanceController;
  late TextEditingController _sourceConnaissanceController;
  late TextEditingController _objectifController;
  late TextEditingController _suggestionsController;
  final TextEditingController _passwordController = TextEditingController();

  // Variables pour les champs de sélection
  String _selectedGenre = 'homme';
  String _selectedSourceConnaissance = 'instagram';
  bool _accordPublication = false;

  // Données originales pour comparer les modifications
  Adherent? _originalData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isDataLoading = true);

    try {
      Adherent? data = widget.adherentData;

      if (data == null) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        if (userProvider.isLoggedIn) {
          try {
            final userId = int.parse(userProvider.userId!);
            final adherent = await AdherentService.getAdherentById(userId);
            data = adherent;
          } catch (e) {
            debugPrint('❌ Erreur récupération données: $e');
            data = Adherent(
              id: int.parse(userProvider.userId!),
              whatsapp: userProvider.userWhatsapp ?? '',
              nomPrenom: userProvider.displayName,
              email: userProvider.userEmail ?? '',
              pays: '',
              ville: '',
              dateNaissance: DateTime.now(),
              genre: 'homme',
              sourceConnaissance: 'instagram',
              accordPublication: false,
            );
          }
        }
      }

      if (data != null) {
        _originalData = data;
        _populateFields(data);
      }

      setState(() => _isDataLoading = false);
    } catch (e) {
      setState(() => _isDataLoading = false);
      final isArabic =
          Provider.of<LanguageProvider>(context, listen: false).isArabic;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? "❌ Erreur de chargement des données"
                : "❌ Erreur de chargement des données",
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _populateFields(Adherent data) {
    _nameController = TextEditingController(text: data.nomPrenom);
    _phoneController = TextEditingController(text: data.whatsapp);
    _emailController = TextEditingController(text: data.email ?? '');
    _paysController = TextEditingController(text: data.pays ?? '');
    _villeController = TextEditingController(text: data.ville ?? '');
    _dateNaissanceController = TextEditingController(
      text:
          '${data.dateNaissance.day}/${data.dateNaissance.month}/${data.dateNaissance.year}',
    );
    _sourceConnaissanceController = TextEditingController(
      text: data.sourceAutreDetail ?? '',
    );
    _objectifController = TextEditingController(text: data.objectif ?? '');
    _suggestionsController = TextEditingController(
      text: data.suggestions ?? '',
    );

    _selectedGenre = data.genre ?? 'homme';
    _selectedSourceConnaissance = data.sourceConnaissance ?? 'instagram';
    _accordPublication = data.accordPublication ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _paysController.dispose();
    _villeController.dispose();
    _dateNaissanceController.dispose();
    _sourceConnaissanceController.dispose();
    _objectifController.dispose();
    _suggestionsController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _hasChanges() {
    if (_originalData == null) return true;

    final original = _originalData!;
    return original.nomPrenom != _nameController.text.trim() ||
        original.whatsapp != _phoneController.text.trim() ||
        original.email != _emailController.text.trim() ||
        original.pays != _paysController.text.trim() ||
        original.ville != _villeController.text.trim() ||
        original.genre != _selectedGenre ||
        original.sourceConnaissance != _selectedSourceConnaissance ||
        original.sourceAutreDetail !=
            _sourceConnaissanceController.text.trim() ||
        original.objectif != _objectifController.text.trim() ||
        original.suggestions != _suggestionsController.text.trim() ||
        original.accordPublication != _accordPublication ||
        _passwordController.text.trim().isNotEmpty;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_hasChanges()) {
      final isArabic =
          Provider.of<LanguageProvider>(context, listen: false).isArabic;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? "⚠️ Aucune modification détectée"
                : "⚠️ Aucune modification détectée",
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      DateTime dateNaissance;
      try {
        final dateParts = _dateNaissanceController.text.split('/');
        if (dateParts.length == 3) {
          dateNaissance = DateTime(
            int.parse(dateParts[2]),
            int.parse(dateParts[1]),
            int.parse(dateParts[0]),
          );
        } else {
          dateNaissance = DateTime.now();
        }
      } catch (e) {
        dateNaissance = DateTime.now();
      }

      final updatedAdherent = Adherent(
        id: widget.adherentId != null ? int.parse(widget.adherentId!) : null,
        whatsapp: _phoneController.text.trim(),
        nomPrenom: _nameController.text.trim(),
        pays: _paysController.text.trim(),
        ville: _villeController.text.trim(),
        email: _emailController.text.trim(),
        dateNaissance: dateNaissance,
        genre: _selectedGenre,
        sourceConnaissance: _selectedSourceConnaissance,
        sourceAutreDetail:
            _sourceConnaissanceController.text.trim().isNotEmpty
                ? _sourceConnaissanceController.text.trim()
                : null,
        objectif:
            _objectifController.text.trim().isNotEmpty
                ? _objectifController.text.trim()
                : null,
        suggestions:
            _suggestionsController.text.trim().isNotEmpty
                ? _suggestionsController.text.trim()
                : null,
        accordPublication: _accordPublication,
      );

      String? idToUpdate = widget.adherentId;
      if (idToUpdate == null) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        if (userProvider.isLoggedIn) {
          idToUpdate = userProvider.userId;
        }
      }

      if (idToUpdate != null) {
        await AdherentService.updateAdherent(
          int.parse(idToUpdate),
          updatedAdherent,
        );
      }

      final isArabic =
          Provider.of<LanguageProvider>(context, listen: false).isArabic;

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.isLoggedIn && userProvider.userRole != null) {
        userProvider.setUser(
          id: userProvider.userId!,
          name: _nameController.text.trim(),
          whatsapp: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          role: userProvider.userRole!,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? "✅ تم تحديث الحساب بنجاح"
                : "✅ Profil mis à jour avec succès !",
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: const Color(0xff0D443E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      final isArabic =
          Provider.of<LanguageProvider>(context, listen: false).isArabic;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? "❌ Erreur: ${e.toString().replaceFirst('Exception: ', '')}"
                : "❌ Erreur: ${e.toString().replaceFirst('Exception: ', '')}",
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;
    final userProvider = Provider.of<UserProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    final double topMargin = isMobile ? 100 : 90;

    final bool hasData =
        _originalData != null ||
        (userProvider.isLoggedIn && userProvider.userName != null);

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.surface,
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
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(top: topMargin),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 600),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.08),
                        ),
                      ),
                      child:
                          _isDataLoading
                              ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(40.0),
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                  ),
                                ),
                              )
                              : !hasData
                              ? Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      size: 80,
                                      color: Colors.grey[300],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      isArabic
                                          ? "⚠️ Aucune donnée disponible"
                                          : "⚠️ Aucune donnée disponible",
                                      style: GoogleFonts.cairo(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: Text(
                                        isArabic ? "العودة" : "Retour",
                                        style: GoogleFonts.cairo(),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // ---- Avatar ----
                                    Center(
                                      child: Stack(
                                        children: [
                                          CircleAvatar(
                                            radius: 50,
                                            backgroundColor: AppColors.primary
                                                .withOpacity(0.1),
                                            child:
                                                userProvider.isLoggedIn
                                                    ? Text(
                                                      userProvider.initials,
                                                      style: GoogleFonts.cairo(
                                                        fontSize: 32,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            AppColors.primary,
                                                      ),
                                                    )
                                                    : const Icon(
                                                      Icons.person_rounded,
                                                      size: 55,
                                                      color: AppColors.primary,
                                                    ),
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            right: isArabic ? null : 0,
                                            left: isArabic ? 0 : null,
                                            child: CircleAvatar(
                                              radius: 16,
                                              backgroundColor:
                                                  AppColors.primary,
                                              child: const Icon(
                                                Icons.camera_alt_rounded,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (userProvider.isLoggedIn &&
                                        userProvider.userRole != null)
                                      Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            userProvider.userRole!.libelle,
                                            style: GoogleFonts.cairo(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 35),

                                    // ---- Champs du formulaire ----
                                    _buildEditField(
                                      controller: _nameController,
                                      labelFr: "Nom et Prénom",
                                      labelAr: "الاسم واللقب",
                                      icon: Icons.person_outline_rounded,
                                      validator:
                                          (v) =>
                                              v!.isEmpty
                                                  ? "Champ requis"
                                                  : null,
                                    ),
                                    const SizedBox(height: 16),

                                    _buildEditField(
                                      controller: _phoneController,
                                      labelFr: "WhatsApp (avec indicatif)",
                                      labelAr: "رقم الواتساب (مع رمز البلد)",
                                      icon: Icons.phone_android_rounded,
                                      keyboardType: TextInputType.phone,
                                      validator:
                                          (v) =>
                                              v!.isEmpty
                                                  ? "Champ requis"
                                                  : null,
                                    ),
                                    const SizedBox(height: 16),

                                    _buildEditField(
                                      controller: _emailController,
                                      labelFr: "Adresse E-mail",
                                      labelAr: "البريد الإلكتروني",
                                      icon: Icons.alternate_email_rounded,
                                      keyboardType: TextInputType.emailAddress,
                                      validator:
                                          (v) =>
                                              !v!.contains('@')
                                                  ? "E-mail invalide"
                                                  : null,
                                    ),
                                    const SizedBox(height: 16),

                                    _buildEditField(
                                      controller: _paysController,
                                      labelFr: "Pays",
                                      labelAr: "بلد الإقامة",
                                      icon: Icons.location_on_outlined,
                                      validator:
                                          (v) =>
                                              v!.isEmpty
                                                  ? "Champ requis"
                                                  : null,
                                    ),
                                    const SizedBox(height: 16),

                                    _buildEditField(
                                      controller: _villeController,
                                      labelFr: "Ville",
                                      labelAr: "المدينة",
                                      icon: Icons.location_city_outlined,
                                      validator:
                                          (v) =>
                                              v!.isEmpty
                                                  ? "Champ requis"
                                                  : null,
                                    ),
                                    const SizedBox(height: 16),

                                    _buildEditField(
                                      controller: _dateNaissanceController,
                                      labelFr: "Date de naissance",
                                      labelAr: "تاريخ الولادة",
                                      icon: Icons.calendar_today_outlined,
                                      readOnly: true,
                                      onTap: () async {
                                        final DateTime? picked =
                                            await showDatePicker(
                                              context: context,
                                              initialDate: DateTime.now(),
                                              firstDate: DateTime(1900),
                                              lastDate: DateTime.now(),
                                            );
                                        if (picked != null) {
                                          setState(() {
                                            _dateNaissanceController.text =
                                                '${picked.day}/${picked.month}/${picked.year}';
                                          });
                                        }
                                      },
                                      validator:
                                          (v) =>
                                              v!.isEmpty
                                                  ? "Champ requis"
                                                  : null,
                                    ),
                                    const SizedBox(height: 16),

                                    // ---- Genre (Dropdown corrigé) ----
                                    _buildDropdown(
                                      labelFr: "Genre",
                                      labelAr: "الجنس",
                                      value: _selectedGenre,
                                      items: const [
                                        DropdownMenuItem<String>(
                                          key: ValueKey('genre_homme'),
                                          value: 'homme',
                                          child: Text('Homme'),
                                        ),
                                        DropdownMenuItem<String>(
                                          key: ValueKey('genre_femme'),
                                          value: 'femme',
                                          child: Text('Femme'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(
                                            () => _selectedGenre = value,
                                          );
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // ---- Source (Dropdown corrigé) ----
                                    _buildDropdown(
                                      labelFr: "Source de connaissance",
                                      labelAr: "كيف تعرفت على الأكاديمية؟",
                                      value: _selectedSourceConnaissance,
                                      items: const [
                                        DropdownMenuItem<String>(
                                          key: ValueKey('source_instagram'),
                                          value: 'instagram',
                                          child: Text('Instagram'),
                                        ),
                                        DropdownMenuItem<String>(
                                          key: ValueKey('source_facebook'),
                                          value: 'facebook',
                                          child: Text('Facebook'),
                                        ),
                                        DropdownMenuItem<String>(
                                          key: ValueKey('source_ami'),
                                          value: 'ami',
                                          child: Text('Ami(e)'),
                                        ),
                                        DropdownMenuItem<String>(
                                          key: ValueKey('source_annonce'),
                                          value: 'annonce',
                                          child: Text('Annonce'),
                                        ),
                                        DropdownMenuItem<String>(
                                          key: ValueKey('source_autre'),
                                          value: 'autre',
                                          child: Text('Autre'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(
                                            () =>
                                                _selectedSourceConnaissance =
                                                    value,
                                          );
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    _buildEditField(
                                      controller: _objectifController,
                                      labelFr: "Objectif",
                                      labelAr:
                                          "ما هو هدفك من الالتحاق بهذه الدورات ؟",
                                      icon: Icons.flag_outlined,
                                      maxLines: 3,
                                    ),
                                    const SizedBox(height: 16),

                                    _buildEditField(
                                      controller: _suggestionsController,
                                      labelFr: "Suggestions",
                                      labelAr: "اقتراحات دورات و مواضيع دروس",
                                      icon: Icons.lightbulb_outline,
                                      maxLines: 2,
                                    ),
                                    const SizedBox(height: 16),

                                    _buildCheckbox(
                                      labelFr:
                                          "J'accepte la publication du contenu",
                                      labelAr: "أوافق على نشر محتوى الدورات",
                                      value: _accordPublication,
                                      onChanged: (value) {
                                        setState(
                                          () => _accordPublication = value!,
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    _buildEditField(
                                      controller: _passwordController,
                                      labelFr:
                                          "Nouveau mot de passe (optionnel)",
                                      labelAr: "كلمة مرور جديدة (اختياري)",
                                      icon: Icons.lock_outline_rounded,
                                      isPassword: true,
                                      validator:
                                          (v) =>
                                              (v!.isNotEmpty && v.length < 6)
                                                  ? "6 caractères minimum"
                                                  : null,
                                    ),
                                    const SizedBox(height: 30),

                                    // ---- Boutons ----
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed:
                                                _isLoading
                                                    ? null
                                                    : () {
                                                      Navigator.pop(context);
                                                    },
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.grey[700],
                                              side: BorderSide(
                                                color: Colors.grey[300]!,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 16,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                            ),
                                            child: Text(
                                              isArabic ? "إلغاء" : "Annuler",
                                              style: GoogleFonts.cairo(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed:
                                                _isLoading
                                                    ? null
                                                    : _saveProfile,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.primary,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 16,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              elevation: 0,
                                            ),
                                            child:
                                                _isLoading
                                                    ? const SizedBox(
                                                      height: 20,
                                                      width: 20,
                                                      child:
                                                          CircularProgressIndicator(
                                                            color: Colors.white,
                                                            strokeWidth: 2,
                                                          ),
                                                    )
                                                    : Text(
                                                      isArabic
                                                          ? "حفظ التغييرات"
                                                          : "Enregistrer",
                                                      style: GoogleFonts.cairo(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
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

              // ---- Overlay chargement ----
              if (_isLoading)
                const Opacity(
                  opacity: 0.5,
                  child: ModalBarrier(dismissible: false, color: Colors.black),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- WIDGETS PRIVÉS ----
  Widget _buildEditField({
    required TextEditingController controller,
    required String labelFr,
    required String labelAr,
    required IconData icon,
    bool isPassword = false,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final isArabic =
        Provider.of<LanguageProvider>(context, listen: false).isArabic;

    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.cairo(color: AppColors.textDark, fontSize: 15),
      decoration: InputDecoration(
        labelText: isArabic ? labelAr : labelFr,
        labelStyle: GoogleFonts.cairo(color: AppColors.textMuted),
        prefixIcon: Icon(
          icon,
          color: AppColors.primary.withOpacity(0.6),
          size: 20,
        ),
        filled: true,
        fillColor: AppColors.primary.withOpacity(0.01),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }

  // ---- DROPDOWN CORRIGÉ AVEC VÉRIFICATION ----
  Widget _buildDropdown({
    required String labelFr,
    required String labelAr,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    final isArabic =
        Provider.of<LanguageProvider>(context, listen: false).isArabic;

    // ✅ Vérifier que la valeur existe dans les items
    final bool hasValidValue = items.any((item) => item.value == value);
    final String? effectiveValue = hasValidValue ? value : null;

    return DropdownButtonFormField<String>(
      key: ValueKey('dropdown_${labelFr}_${effectiveValue ?? 'none'}'),
      initialValue: effectiveValue,
      decoration: InputDecoration(
        labelText: isArabic ? labelAr : labelFr,
        labelStyle: GoogleFonts.cairo(color: AppColors.textMuted),
        prefixIcon: Icon(
          Icons.arrow_drop_down,
          color: AppColors.primary.withOpacity(0.6),
        ),
        filled: true,
        fillColor: AppColors.primary.withOpacity(0.01),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
      items: items,
      onChanged: onChanged,
      style: GoogleFonts.cairo(color: AppColors.textDark, fontSize: 15),
      isExpanded: true,
      hint: Text(
        isArabic ? 'اختر...' : 'Sélectionnez...',
        style: GoogleFonts.cairo(color: Colors.grey.shade500, fontSize: 15),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return isArabic ? 'الرجاء الاختيار' : 'Veuillez sélectionner';
        }
        return null;
      },
    );
  }

  Widget _buildCheckbox({
    required String labelFr,
    required String labelAr,
    required bool value,
    required Function(bool?) onChanged,
  }) {
    final isArabic =
        Provider.of<LanguageProvider>(context, listen: false).isArabic;

    return CheckboxListTile(
      title: Text(
        isArabic ? labelAr : labelFr,
        style: GoogleFonts.cairo(color: AppColors.textDark),
      ),
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: AppColors.primary,
    );
  }
}
