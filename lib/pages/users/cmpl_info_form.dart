// lib/pages/users/cmpl_info_form.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/language_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/cmpl_user_model.dart';
import '../../services/cmpl_user_service.dart';
import '../widgets/navbar.dart';
import '../widgets/chatbot/chatbot_wrapper.dart';
import '../../models/training_model.dart';

class CmplInfoForm extends StatefulWidget {
  final int adherentId;
  final int formationId;
  final TrainingModel? formation;
  final VoidCallback? onComplete;

  const CmplInfoForm({
    super.key,
    required this.adherentId,
    required this.formationId,
    this.formation,
    this.onComplete,
  });

  @override
  State<CmplInfoForm> createState() => _CmplInfoFormState();
}

class _CmplInfoFormState extends State<CmplInfoForm> {
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isEditMode = false;

  // ============================================================
  // CHAMPS DU FORMULAIRE
  // ============================================================
  String _niveauMemorisation = 'debutant';
  String? _niveauMemorisationAutre;
  String? _souratesOuDjouzMaitrises;
  String? _rythmeMemorisationHebdo;
  String? _rythmeMemorisationHebdoAutre;
  bool _etudeTajwidTheorique = false;
  String _riwayaSouhaitee = 'hafs';
  String? _riwayaSouhaiteeAutre;
  String _lectureMushaf = 'madinah';
  bool _aIjaza = false;
  String? _detailsIjaza;
  String? _objectifPrincipal;
  String? _creneauHoraire = 'flexible';
  String? _parcoursPrefere = 'dynamique';

  // ============================================================
  // CONTROLEURS
  // ============================================================
  final TextEditingController _niveauMemorisationAutreController =
      TextEditingController();
  final TextEditingController _souratesController = TextEditingController();
  final TextEditingController _rythmeAutreController = TextEditingController();
  final TextEditingController _riwayaAutreController = TextEditingController();
  final TextEditingController _detailsIjazaController = TextEditingController();
  final TextEditingController _objectifController = TextEditingController();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool get _isArabic =>
      Provider.of<LanguageProvider>(context, listen: false).isArabic;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  @override
  void dispose() {
    _niveauMemorisationAutreController.dispose();
    _souratesController.dispose();
    _rythmeAutreController.dispose();
    _riwayaAutreController.dispose();
    _detailsIjazaController.dispose();
    _objectifController.dispose();
    super.dispose();
  }

  // ============================================================
  // CHARGEMENT DES DONNÉES EXISTANTES
  // ============================================================
  Future<void> _loadExistingData() async {
    setState(() => _isLoading = true);

    try {
      final cmpl = await CmplUserService.getCmplInfo(
        adherentId: widget.adherentId,
        formationId: widget.formationId,
      );

      if (cmpl != null) {
        setState(() {
          _isEditMode = true;
          _niveauMemorisation = cmpl.niveauMemorisation;
          _niveauMemorisationAutre = cmpl.niveauMemorisationAutre;
          _souratesOuDjouzMaitrises = cmpl.souratesOuDjouzMaitrises;
          _rythmeMemorisationHebdo = cmpl.rythmeMemorisationHebdo;
          _rythmeMemorisationHebdoAutre = cmpl.rythmeMemorisationHebdoAutre;
          _etudeTajwidTheorique = cmpl.etudeTajwidTheorique;
          _riwayaSouhaitee = cmpl.riwayaSouhaitee;
          _riwayaSouhaiteeAutre = cmpl.riwayaSouhaiteeAutre;
          _lectureMushaf = cmpl.lectureMushaf;
          _aIjaza = cmpl.aIjaza;
          _detailsIjaza = cmpl.detailsIjaza;
          _objectifPrincipal = cmpl.objectifPrincipal;
          _creneauHoraire = cmpl.creneauHoraire;
          _parcoursPrefere = cmpl.parcoursPrefere;

          // Remplir les contrôleurs
          _niveauMemorisationAutreController.text =
              cmpl.niveauMemorisationAutre ?? '';
          _souratesController.text = cmpl.souratesOuDjouzMaitrises ?? '';
          _rythmeAutreController.text = cmpl.rythmeMemorisationHebdoAutre ?? '';
          _riwayaAutreController.text = cmpl.riwayaSouhaiteeAutre ?? '';
          _detailsIjazaController.text = cmpl.detailsIjaza ?? '';
          _objectifController.text = cmpl.objectifPrincipal ?? '';
        });
      }
    } catch (e) {
      print('❌ [CmplInfoForm] Erreur chargement: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ============================================================
  // SAUVEGARDE
  // ============================================================
  Future<void> _saveInfo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    setState(() => _isSaving = true);

    try {
      // Construire l'objet CmplUser
      final cmplUser = CmplUser(
        adherentId: widget.adherentId,
        formationId: widget.formationId,
        niveauMemorisation: _niveauMemorisation,
        niveauMemorisationAutre:
            _niveauMemorisation == 'autre'
                ? _niveauMemorisationAutreController.text.trim()
                : null,
        souratesOuDjouzMaitrises:
            _souratesController.text.trim().isEmpty
                ? null
                : _souratesController.text.trim(),
        rythmeMemorisationHebdo: _rythmeMemorisationHebdo,
        rythmeMemorisationHebdoAutre:
            _rythmeMemorisationHebdo == 'autre'
                ? _rythmeAutreController.text.trim()
                : null,
        etudeTajwidTheorique: _etudeTajwidTheorique,
        riwayaSouhaitee: _riwayaSouhaitee,
        riwayaSouhaiteeAutre:
            _riwayaSouhaitee == 'autre'
                ? _riwayaAutreController.text.trim()
                : null,
        lectureMushaf: _lectureMushaf,
        aIjaza: _aIjaza,
        detailsIjaza: _aIjaza ? _detailsIjazaController.text.trim() : null,
        objectifPrincipal:
            _objectifController.text.trim().isEmpty
                ? null
                : _objectifController.text.trim(),
        creneauHoraire: _creneauHoraire,
        parcoursPrefere: _parcoursPrefere,
      );

      // Sauvegarder
      final result = await CmplUserService.saveOrUpdateCmplInfo(
        adherentId: widget.adherentId,
        formationId: widget.formationId,
        cmplUser: cmplUser,
      );

      if (result['success'] == true) {
        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isArabic
                  ? '✅ تم حفظ المعلومات بنجاح'
                  : '✅ Informations sauvegardées avec succès',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: const Color(0xff0D443E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        // Appeler le callback si fourni
        if (widget.onComplete != null) {
          widget.onComplete!();
        }

        // Fermer la page
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        throw Exception(result['message'] ?? 'Erreur lors de la sauvegarde');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ ${e.toString().replaceFirst('Exception: ', '')}',
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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;
    final bool isTablet = screenWidth >= 600 && screenWidth < 1200;
    final bool isDesktop = screenWidth >= 1200;

    final double horizontalPadding = isMobile ? 16 : (isTablet ? 32 : 64);
    final double verticalPadding = isMobile ? 16 : (isTablet ? 24 : 40);
    final double cardPadding = isMobile ? 16 : 24;
    final double maxWidth = isDesktop ? 800 : double.infinity;
    final double fontSize = isMobile ? 14 : 16;
    final double topMargin = isMobile ? 100 : 90;

    return ChatbotWrapper(
      apiBaseUrl: 'http://localhost:3000',
      langue: _isArabic ? 'ar' : 'fr',
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
                        // ---- En-tête ----
                        _buildHeader(),
                        const SizedBox(height: 20),

                        // ---- Formulaire ----
                        Card(
                          elevation: isDesktop ? 4 : 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(cardPadding),
                            child:
                                _isLoading
                                    ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(40.0),
                                        child: CircularProgressIndicator(
                                          color: Color(0xff0D443E),
                                        ),
                                      ),
                                    )
                                    : Form(
                                      key: _formKey,
                                      child: Column(
                                        children: [
                                          _buildSectionTitle(
                                            _isArabic
                                                ? '📚 معلومات التلاوة والحفظ'
                                                : '📚 Informations de récitation et mémorisation',
                                          ),
                                          const SizedBox(height: 16),

                                          // Niveau de mémorisation
                                          _buildNiveauMemorisation(fontSize),
                                          const SizedBox(height: 12),

                                          // Sourates / Djouz maîtrisés
                                          _buildSouratesField(fontSize),
                                          const SizedBox(height: 12),

                                          // Rythme de mémorisation
                                          _buildRythmeMemorisation(fontSize),
                                          const SizedBox(height: 12),

                                          // Étude Tajwid théorique
                                          _buildTajwidCheckbox(fontSize),
                                          const SizedBox(height: 16),

                                          _buildDivider(),
                                          const SizedBox(height: 16),

                                          _buildSectionTitle(
                                            _isArabic
                                                ? '📖 Préférences de lecture'
                                                : '📖 Préférences de lecture',
                                          ),
                                          const SizedBox(height: 16),

                                          // Riwaya souhaitée
                                          _buildRiwayaSouhaitee(fontSize),
                                          const SizedBox(height: 12),

                                          // Lecture Mushaf
                                          _buildLectureMushaf(fontSize),
                                          const SizedBox(height: 12),

                                          // Ijaza
                                          _buildIjaza(fontSize),
                                          const SizedBox(height: 16),

                                          _buildDivider(),
                                          const SizedBox(height: 16),

                                          _buildSectionTitle(
                                            _isArabic
                                                ? '🎯 Objectifs et préférences'
                                                : '🎯 Objectifs et préférences',
                                          ),
                                          const SizedBox(height: 16),

                                          // Objectif principal
                                          _buildObjectifPrincipal(fontSize),
                                          const SizedBox(height: 12),

                                          // Créneau horaire
                                          _buildCreneauHoraire(fontSize),
                                          const SizedBox(height: 12),

                                          // Parcours préféré
                                          _buildParcoursPrefere(fontSize),
                                          const SizedBox(height: 24),

                                          // ---- Bouton sauvegarder ----
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed:
                                                  _isSaving ? null : _saveInfo,
                                              style: ElevatedButton.styleFrom(
                                                padding: EdgeInsets.symmetric(
                                                  vertical: isMobile ? 14 : 18,
                                                  horizontal: 20,
                                                ),
                                                backgroundColor: const Color(
                                                  0xff0D443E,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              child:
                                                  _isSaving
                                                      ? const SizedBox(
                                                        height: 20,
                                                        width: 20,
                                                        child:
                                                            CircularProgressIndicator(
                                                              color:
                                                                  Colors.white,
                                                              strokeWidth: 2,
                                                            ),
                                                      )
                                                      : Text(
                                                        _isEditMode
                                                            ? (_isArabic
                                                                ? 'تحديث المعلومات'
                                                                : 'Mettre à jour')
                                                            : (_isArabic
                                                                ? 'حفظ المعلومات'
                                                                : 'Enregistrer'),
                                                        style:
                                                            GoogleFonts.cairo(
                                                              fontSize:
                                                                  fontSize + 2,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                      ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),

                                          // ---- Message info ----
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.blue.shade200,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.info_outline,
                                                  color: Colors.blue.shade700,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    _isArabic
                                                        ? 'هذه المعلومات ضرورية لتخصيص مسار التعلم الخاص بك'
                                                        : 'Ces informations sont nécessaires pour personnaliser votre parcours d\'apprentissage',
                                                    style: GoogleFonts.cairo(
                                                      fontSize: fontSize - 2,
                                                      color:
                                                          Colors.blue.shade700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                          ),
                        ),
                        const SizedBox(height: 30),
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
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // WIDGETS DU FORMULAIRE
  // ============================================================

  Widget _buildHeader() {
    // Récupérer le titre de la formation (FR ou AR selon la langue)
    String formationTitle = widget.formation?.titleFr ?? '';
    if (_isArabic &&
        widget.formation?.titleAr != null &&
        widget.formation!.titleAr.isNotEmpty) {
      formationTitle = widget.formation!.titleAr;
    }

    return Column(
      children: [
        Text(
          _isArabic ? '📝 استكمال الملف الشخصي' : '📝 Compléter le profil',
          style: GoogleFonts.cairo(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xff0D443E),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isArabic
              ? 'يرجى إكمال المعلومات التالية للمتابعة'
              : 'Veuillez compléter les informations suivantes pour continuer',
          style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey.shade600),
        ),
        if (widget.formation != null && formationTitle.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xff0D443E).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_isArabic ? 'الدورة' : 'Formation'}: $formationTitle',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xff0D443E),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: const Color(0xff0D443E),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(color: Colors.grey.shade300, thickness: 1);
  }

  // ---- Niveau de mémorisation ----
  Widget _buildNiveauMemorisation(double fontSize) {
    final options = CmplUserService.getNiveauMemorisationOptions(_isArabic);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isArabic ? 'مستوى الحفظ' : 'Niveau de mémorisation',
          style: GoogleFonts.cairo(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _niveauMemorisation,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
          ),
          items:
              options.map<DropdownMenuItem<String>>((option) {
                return DropdownMenuItem<String>(
                  value: option['value'] as String,
                  child: Text(
                    option['label'] as String,
                    style: GoogleFonts.cairo(fontSize: fontSize),
                  ),
                );
              }).toList(),
          onChanged: (value) {
            setState(() {
              _niveauMemorisation = value!;
              if (value != 'autre') {
                _niveauMemorisationAutreController.clear();
              }
            });
          },
        ),
        if (_niveauMemorisation == 'autre')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextFormField(
              controller: _niveauMemorisationAutreController,
              decoration: InputDecoration(
                labelText: _isArabic ? 'الرجاء التوضيح' : 'Précisez',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                labelStyle: GoogleFonts.cairo(fontSize: fontSize),
              ),
              style: GoogleFonts.cairo(fontSize: fontSize),
              validator: (value) {
                if (_niveauMemorisation == 'autre' &&
                    (value == null || value.isEmpty)) {
                  return _isArabic ? 'الرجاء التوضيح' : 'Veuillez préciser';
                }
                return null;
              },
            ),
          ),
      ],
    );
  }

  // ---- Sourates / Djouz maîtrisés ----
  Widget _buildSouratesField(double fontSize) {
    return TextFormField(
      controller: _souratesController,
      maxLines: 2,
      decoration: InputDecoration(
        labelText:
            _isArabic
                ? 'السور أو الأجزاء التي تتقنها (اختياري)'
                : 'Sourates ou Djouz maîtrisés (optionnel)',
        hintText:
            _isArabic
                ? 'مثال: سورة البقرة، جزء عم، ...'
                : 'Ex: Sourate Al-Baqara, Juz Amma, ...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: GoogleFonts.cairo(fontSize: fontSize),
        hintStyle: GoogleFonts.cairo(fontSize: fontSize),
      ),
      style: GoogleFonts.cairo(fontSize: fontSize),
    );
  }

  // ---- Rythme de mémorisation ----
  Widget _buildRythmeMemorisation(double fontSize) {
    final options = CmplUserService.getRythmeMemorisationOptions(_isArabic);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isArabic
              ? 'الوتيرة الأسبوعية للحفظ'
              : 'Rythme de mémorisation hebdomadaire',
          style: GoogleFonts.cairo(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String?>(
          value: _rythmeMemorisationHebdo,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
          ),
          hint: Text(
            _isArabic ? 'اختر الوتيرة' : 'Choisissez le rythme',
            style: GoogleFonts.cairo(
              fontSize: fontSize,
              color: Colors.grey.shade500,
            ),
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: SizedBox.shrink(),
            ),
            ...options.map<DropdownMenuItem<String?>>((option) {
              return DropdownMenuItem<String?>(
                value: option['value'] as String?,
                child: Text(
                  option['label'] as String,
                  style: GoogleFonts.cairo(fontSize: fontSize),
                ),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _rythmeMemorisationHebdo = value;
              if (value != 'autre') {
                _rythmeAutreController.clear();
              }
            });
          },
        ),
        if (_rythmeMemorisationHebdo == 'autre')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextFormField(
              controller: _rythmeAutreController,
              decoration: InputDecoration(
                labelText: _isArabic ? 'الرجاء التوضيح' : 'Précisez',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                labelStyle: GoogleFonts.cairo(fontSize: fontSize),
              ),
              style: GoogleFonts.cairo(fontSize: fontSize),
              validator: (value) {
                if (_rythmeMemorisationHebdo == 'autre' &&
                    (value == null || value.isEmpty)) {
                  return _isArabic ? 'الرجاء التوضيح' : 'Veuillez préciser';
                }
                return null;
              },
            ),
          ),
      ],
    );
  }

  // ---- Étude Tajwid théorique ----
  Widget _buildTajwidCheckbox(double fontSize) {
    return CheckboxListTile(
      title: Text(
        _isArabic
            ? 'هل درست أحكام التجويد نظرياً؟'
            : 'Avez-vous étudié le Tajwid théoriquement ?',
        style: GoogleFonts.cairo(fontSize: fontSize),
      ),
      value: _etudeTajwidTheorique,
      onChanged: (value) {
        setState(() {
          _etudeTajwidTheorique = value ?? false;
        });
      },
      activeColor: const Color(0xff0D443E),
      contentPadding: EdgeInsets.zero,
    );
  }

  // ---- Riwaya souhaitée ----
  Widget _buildRiwayaSouhaitee(double fontSize) {
    final options = CmplUserService.getRiwayaOptions(_isArabic);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isArabic ? 'الرواية المرغوبة' : 'Riwaya souhaitée',
          style: GoogleFonts.cairo(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _riwayaSouhaitee,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
          ),
          items:
              options.map<DropdownMenuItem<String>>((option) {
                return DropdownMenuItem<String>(
                  value: option['value'] as String,
                  child: Text(
                    option['label'] as String,
                    style: GoogleFonts.cairo(fontSize: fontSize),
                  ),
                );
              }).toList(),
          onChanged: (value) {
            setState(() {
              _riwayaSouhaitee = value!;
              if (value != 'autre') {
                _riwayaAutreController.clear();
              }
            });
          },
        ),
        if (_riwayaSouhaitee == 'autre')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextFormField(
              controller: _riwayaAutreController,
              decoration: InputDecoration(
                labelText: _isArabic ? 'الرجاء التوضيح' : 'Précisez',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                labelStyle: GoogleFonts.cairo(fontSize: fontSize),
              ),
              style: GoogleFonts.cairo(fontSize: fontSize),
              validator: (value) {
                if (_riwayaSouhaitee == 'autre' &&
                    (value == null || value.isEmpty)) {
                  return _isArabic ? 'الرجاء التوضيح' : 'Veuillez préciser';
                }
                return null;
              },
            ),
          ),
      ],
    );
  }

  // ---- Lecture Mushaf ----
  Widget _buildLectureMushaf(double fontSize) {
    final options = CmplUserService.getLectureMushafOptions(_isArabic);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isArabic ? 'نوع المصحف المستخدم' : 'Type de Mushaf utilisé',
          style: GoogleFonts.cairo(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _lectureMushaf,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
          ),
          items:
              options.map<DropdownMenuItem<String>>((option) {
                return DropdownMenuItem<String>(
                  value: option['value'] as String,
                  child: Text(
                    option['label'] as String,
                    style: GoogleFonts.cairo(fontSize: fontSize),
                  ),
                );
              }).toList(),
          onChanged: (value) {
            setState(() {
              _lectureMushaf = value!;
            });
          },
        ),
      ],
    );
  }

  // ---- Ijaza ----
  Widget _buildIjaza(double fontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          title: Text(
            _isArabic
                ? 'هل لديك إجازة في القرآن الكريم؟'
                : 'Avez-vous une Ijaza dans le Saint Coran ?',
            style: GoogleFonts.cairo(fontSize: fontSize),
          ),
          value: _aIjaza,
          onChanged: (value) {
            setState(() {
              _aIjaza = value ?? false;
              if (!_aIjaza) {
                _detailsIjazaController.clear();
              }
            });
          },
          activeColor: const Color(0xff0D443E),
          contentPadding: EdgeInsets.zero,
        ),
        if (_aIjaza)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 8),
            child: TextFormField(
              controller: _detailsIjazaController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText:
                    _isArabic
                        ? 'تفاصيل الإجازة (المسند، السند، ...)'
                        : 'Détails de l\'Ijaza (Sanad, ...)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                labelStyle: GoogleFonts.cairo(fontSize: fontSize),
              ),
              style: GoogleFonts.cairo(fontSize: fontSize),
              validator: (value) {
                if (_aIjaza && (value == null || value.isEmpty)) {
                  return _isArabic
                      ? 'الرجاء إدخال تفاصيل الإجازة'
                      : 'Veuillez entrer les détails de l\'Ijaza';
                }
                return null;
              },
            ),
          ),
      ],
    );
  }

  // ---- Objectif principal ----
  Widget _buildObjectifPrincipal(double fontSize) {
    return TextFormField(
      controller: _objectifController,
      maxLines: 2,
      decoration: InputDecoration(
        labelText:
            _isArabic
                ? 'ما هو هدفك الرئيسي من هذه الدورة؟'
                : 'Quel est votre objectif principal ?',
        hintText:
            _isArabic
                ? 'مثال: إتقان التلاوة، حفظ القرآن، ...'
                : 'Ex: Maîtriser la récitation, Mémoriser le Coran, ...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: GoogleFonts.cairo(fontSize: fontSize),
        hintStyle: GoogleFonts.cairo(fontSize: fontSize),
      ),
      style: GoogleFonts.cairo(fontSize: fontSize),
    );
  }

  // ---- Créneau horaire ----
  Widget _buildCreneauHoraire(double fontSize) {
    final options = CmplUserService.getCreneauOptions(_isArabic);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isArabic ? 'الفترة الزمنية المفضلة' : 'Créneau horaire préféré',
          style: GoogleFonts.cairo(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String?>(
          value: _creneauHoraire,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
          ),
          items:
              options.map<DropdownMenuItem<String?>>((option) {
                return DropdownMenuItem<String?>(
                  value: option['value'] as String?,
                  child: Text(
                    option['label'] as String,
                    style: GoogleFonts.cairo(fontSize: fontSize),
                  ),
                );
              }).toList(),
          onChanged: (value) {
            setState(() {
              _creneauHoraire = value;
            });
          },
        ),
      ],
    );
  }

  // ---- Parcours préféré ----
  Widget _buildParcoursPrefere(double fontSize) {
    final options = CmplUserService.getParcoursOptions(_isArabic);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isArabic ? 'المسار المفضل' : 'Parcours préféré',
          style: GoogleFonts.cairo(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String?>(
          value: _parcoursPrefere,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
          ),
          items:
              options.map<DropdownMenuItem<String?>>((option) {
                return DropdownMenuItem<String?>(
                  value: option['value'] as String?,
                  child: Text(
                    option['label'] as String,
                    style: GoogleFonts.cairo(fontSize: fontSize),
                  ),
                );
              }).toList(),
          onChanged: (value) {
            setState(() {
              _parcoursPrefere = value;
            });
          },
        ),
      ],
    );
  }
}
