import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:nafahat/src/features/landing/presentation/landing_page.dart'
    show AppColors;
import 'package:nafahat/models/adherent.dart';
import 'package:nafahat/services/adherent_service.dart';
import 'package:nafahat/providers/language_provider.dart';
import '../../../src/features/landing/presentation/widgets/navbar.dart';

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

  @override
  void initState() {
    super.initState();

    final data = widget.adherentData;

    _nameController = TextEditingController(text: data?.nomPrenom ?? '');
    _phoneController = TextEditingController(text: data?.whatsapp ?? '');
    _emailController = TextEditingController(text: data?.email ?? '');
    _paysController = TextEditingController(text: data?.pays ?? '');
    _villeController = TextEditingController(text: data?.ville ?? '');
    _dateNaissanceController = TextEditingController(
      text:
          data?.dateNaissance != null
              ? '${data!.dateNaissance.day}/${data.dateNaissance.month}/${data.dateNaissance.year}'
              : '',
    );
    _sourceConnaissanceController = TextEditingController(
      text: data?.sourceConnaissance ?? '',
    );
    _objectifController = TextEditingController(text: data?.objectif ?? '');
    _suggestionsController = TextEditingController(
      text: data?.suggestions ?? '',
    );

    _selectedGenre = data?.genre ?? 'homme';
    _selectedSourceConnaissance = data?.sourceConnaissance ?? 'instagram';
    _accordPublication = data?.accordPublication ?? false;
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

  // ---- Méthode pour changer la langue ----
  void toggleLanguage() {
    final provider = Provider.of<LanguageProvider>(context, listen: false);
    provider.toggleLanguage();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final updatedAdherent = Adherent(
          id: widget.adherentId != null ? int.parse(widget.adherentId!) : null,
          whatsapp: _phoneController.text,
          nomPrenom: _nameController.text,
          pays: _paysController.text,
          ville: _villeController.text,
          email: _emailController.text,
          dateNaissance: DateTime.now(),
          genre: _selectedGenre,
          sourceConnaissance: _selectedSourceConnaissance,
          sourceAutreDetail: _sourceConnaissanceController.text,
          objectif: _objectifController.text,
          suggestions: _suggestionsController.text,
          accordPublication: _accordPublication,
        );

        if (widget.adherentId != null) {
          await AdherentService.updateAdherent(
            int.parse(widget.adherentId!),
            updatedAdherent,
          );
        }

        final isArabic =
            Provider.of<LanguageProvider>(context, listen: false).isArabic;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic
                  ? "✅ تم تحديث الحساب بنجاح"
                  : "✅ Profil mis à jour avec succès !",
            ),
            backgroundColor: const Color(0xff0D443E),
          ),
        );
        Navigator.pop(context, true);
      } catch (e) {
        final isArabic =
            Provider.of<LanguageProvider>(context, listen: false).isArabic;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic ? "❌ خطأ: $e" : "❌ Erreur: $e"),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    final double topMargin = isMobile ? 100 : 90;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.surface,
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ---- Avatar ----
                            Center(
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundColor: AppColors.primary
                                        .withOpacity(0.1),
                                    child: const Icon(
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
                                      backgroundColor: AppColors.primary,
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
                            const SizedBox(height: 35),

                            // ---- Nom ----
                            _buildEditField(
                              controller: _nameController,
                              labelFr: "Nom et Prénom",
                              labelAr: "الاسم واللقب",
                              icon: Icons.person_outline_rounded,
                              validator:
                                  (v) => v!.isEmpty ? "Champ requis" : null,
                            ),
                            const SizedBox(height: 16),

                            // ---- WhatsApp ----
                            _buildEditField(
                              controller: _phoneController,
                              labelFr: "WhatsApp (avec indicatif)",
                              labelAr: "رقم الواتساب (مع رمز البلد)",
                              icon: Icons.phone_android_rounded,
                              keyboardType: TextInputType.phone,
                              validator:
                                  (v) => v!.isEmpty ? "Champ requis" : null,
                            ),
                            const SizedBox(height: 16),

                            // ---- Email ----
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

                            // ---- Pays ----
                            _buildEditField(
                              controller: _paysController,
                              labelFr: "Pays",
                              labelAr: "بلد الإقامة",
                              icon: Icons.location_on_outlined,
                              validator:
                                  (v) => v!.isEmpty ? "Champ requis" : null,
                            ),
                            const SizedBox(height: 16),

                            // ---- Ville ----
                            _buildEditField(
                              controller: _villeController,
                              labelFr: "Ville",
                              labelAr: "المدينة",
                              icon: Icons.location_city_outlined,
                              validator:
                                  (v) => v!.isEmpty ? "Champ requis" : null,
                            ),
                            const SizedBox(height: 16),

                            // ---- Date de naissance ----
                            _buildEditField(
                              controller: _dateNaissanceController,
                              labelFr: "Date de naissance",
                              labelAr: "تاريخ الولادة",
                              icon: Icons.calendar_today_outlined,
                              readOnly: true,
                              onTap: () async {
                                final DateTime? picked = await showDatePicker(
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
                                  (v) => v!.isEmpty ? "Champ requis" : null,
                            ),
                            const SizedBox(height: 16),

                            // ---- Genre ----
                            _buildDropdown(
                              labelFr: "Genre",
                              labelAr: "الجنس",
                              value: _selectedGenre,
                              items: const [
                                DropdownMenuItem<String>(
                                  value: 'homme',
                                  child: Text('Homme'),
                                ),
                                DropdownMenuItem<String>(
                                  value: 'femme',
                                  child: Text('Femme'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() => _selectedGenre = value!);
                              },
                            ),
                            const SizedBox(height: 16),

                            // ---- Source ----
                            _buildDropdown(
                              labelFr: "Source de connaissance",
                              labelAr: "كيف تعرفت على الأكاديمية؟",
                              value: _selectedSourceConnaissance,
                              items: const [
                                DropdownMenuItem<String>(
                                  value: 'instagram',
                                  child: Text('Instagram'),
                                ),
                                DropdownMenuItem<String>(
                                  value: 'facebook',
                                  child: Text('Facebook'),
                                ),
                                DropdownMenuItem<String>(
                                  value: 'ami',
                                  child: Text('Ami(e)'),
                                ),
                                DropdownMenuItem<String>(
                                  value: 'annonce',
                                  child: Text('Annonce'),
                                ),
                                DropdownMenuItem<String>(
                                  value: 'autre',
                                  child: Text('Autre'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(
                                  () => _selectedSourceConnaissance = value!,
                                );
                              },
                            ),
                            const SizedBox(height: 16),

                            // ---- Objectif ----
                            _buildEditField(
                              controller: _objectifController,
                              labelFr: "Objectif",
                              labelAr: "ما هو هدفك من الالتحاق بهذه الدورات ؟",
                              icon: Icons.flag_outlined,
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),

                            // ---- Suggestions ----
                            _buildEditField(
                              controller: _suggestionsController,
                              labelFr: "Suggestions",
                              labelAr: "اقتراحات دورات و مواضيع دروس",
                              icon: Icons.lightbulb_outline,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),

                            // ---- Accord publication ----
                            _buildCheckbox(
                              labelFr: "J'accepte la publication du contenu",
                              labelAr: "أوافق على نشر محتوى الدورات",
                              value: _accordPublication,
                              onChanged: (value) {
                                setState(() => _accordPublication = value!);
                              },
                            ),
                            const SizedBox(height: 16),

                            // ---- Mot de passe ----
                            _buildEditField(
                              controller: _passwordController,
                              labelFr: "Nouveau mot de passe (optionnel)",
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

                            // ---- Bouton ----
                            ElevatedButton(
                              onPressed: _isLoading ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
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
                                      ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                      : Text(
                                        isArabic
                                            ? "حفظ التغييرات"
                                            : "Enregistrer les modifications",
                                        style: GoogleFonts.cairo(
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

              // ---- NAVBAR ----
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

  Widget _buildDropdown({
    required String labelFr,
    required String labelAr,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    final isArabic =
        Provider.of<LanguageProvider>(context, listen: false).isArabic;

    return DropdownButtonFormField<String>(
      value: value,
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
      ),
      items: items,
      onChanged: onChanged,
      style: GoogleFonts.cairo(color: AppColors.textDark, fontSize: 15),
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
