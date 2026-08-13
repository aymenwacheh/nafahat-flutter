// lib/pages/adminisration/add_about.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:nafahat/providers/language_provider.dart';
import 'package:nafahat/providers/about_provider.dart';
import 'package:nafahat/models/about_model.dart';

class AddAboutPage extends StatefulWidget {
  const AddAboutPage({super.key});

  @override
  State<AddAboutPage> createState() => _AddAboutPageState();
}

class _AddAboutPageState extends State<AddAboutPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers pour les champs texte
  final _titleFrController = TextEditingController();
  final _titleArController = TextEditingController();
  final _sloganFrController = TextEditingController();
  final _sloganArController = TextEditingController();
  final _subtitleFrController = TextEditingController();
  final _subtitleArController = TextEditingController();
  final _descriptionFrController = TextEditingController();
  final _descriptionArController = TextEditingController();
  final _callToActionFrController = TextEditingController();
  final _callToActionArController = TextEditingController();
  final _visionFrController = TextEditingController();
  final _visionArController = TextEditingController();
  final _missionFrController = TextEditingController();
  final _missionArController = TextEditingController();

  // Controllers pour les statistiques
  final _stat1ValueController = TextEditingController();
  final _stat1LabelFrController = TextEditingController();
  final _stat1LabelArController = TextEditingController();
  final _stat2ValueController = TextEditingController();
  final _stat2LabelFrController = TextEditingController();
  final _stat2LabelArController = TextEditingController();
  final _stat3ValueController = TextEditingController();
  final _stat3LabelFrController = TextEditingController();
  final _stat3LabelArController = TextEditingController();
  final _stat4ValueController = TextEditingController();
  final _stat4LabelFrController = TextEditingController();
  final _stat4LabelArController = TextEditingController();

  // Controllers pour les contacts
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressFrController = TextEditingController();
  final _addressArController = TextEditingController();

  // Controllers pour les réseaux sociaux
  final _facebookUrlController = TextEditingController();
  final _youtubeUrlController = TextEditingController();
  final _telegramUrlController = TextEditingController();
  final _instagramUrlController = TextEditingController();

  // Liste des valeurs (chips)
  List<String> _values = [];
  final _valueController = TextEditingController();

  // Liste des membres de l'équipe
  List<TeamMember> _teamMembers = [];
  final _teamNameController = TextEditingController();
  final _teamRoleFrController = TextEditingController();
  final _teamRoleArController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  int? _aboutId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    // Libérer les contrôleurs
    _titleFrController.dispose();
    _titleArController.dispose();
    _sloganFrController.dispose();
    _sloganArController.dispose();
    _subtitleFrController.dispose();
    _subtitleArController.dispose();
    _descriptionFrController.dispose();
    _descriptionArController.dispose();
    _callToActionFrController.dispose();
    _callToActionArController.dispose();
    _visionFrController.dispose();
    _visionArController.dispose();
    _missionFrController.dispose();
    _missionArController.dispose();
    _stat1ValueController.dispose();
    _stat1LabelFrController.dispose();
    _stat1LabelArController.dispose();
    _stat2ValueController.dispose();
    _stat2LabelFrController.dispose();
    _stat2LabelArController.dispose();
    _stat3ValueController.dispose();
    _stat3LabelFrController.dispose();
    _stat3LabelArController.dispose();
    _stat4ValueController.dispose();
    _stat4LabelFrController.dispose();
    _stat4LabelArController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressFrController.dispose();
    _addressArController.dispose();
    _facebookUrlController.dispose();
    _youtubeUrlController.dispose();
    _telegramUrlController.dispose();
    _instagramUrlController.dispose();
    _valueController.dispose();
    _teamNameController.dispose();
    _teamRoleFrController.dispose();
    _teamRoleArController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final aboutProvider = Provider.of<AboutProvider>(context, listen: false);

    setState(() => _isLoading = true);

    await aboutProvider.loadAbout();

    final about = aboutProvider.about;

    if (about != null) {
      _aboutId = about.id;
      _titleFrController.text = about.titleFr;
      _titleArController.text = about.titleAr;
      _sloganFrController.text = about.sloganFr;
      _sloganArController.text = about.sloganAr;
      _subtitleFrController.text = about.subtitleFr;
      _subtitleArController.text = about.subtitleAr;
      _descriptionFrController.text = about.descriptionFr;
      _descriptionArController.text = about.descriptionAr;
      _callToActionFrController.text = about.ctaFr;
      _callToActionArController.text = about.ctaAr;
      _visionFrController.text = about.visionFr ?? '';
      _visionArController.text = about.visionAr ?? '';
      _missionFrController.text = about.missionFr ?? '';
      _missionArController.text = about.missionAr ?? '';

      _values = List.from(about.values);

      _stat1ValueController.text = about.stat1Value;
      _stat1LabelFrController.text = about.stat1LabelFr;
      _stat1LabelArController.text = about.stat1LabelAr;
      _stat2ValueController.text = about.stat2Value;
      _stat2LabelFrController.text = about.stat2LabelFr;
      _stat2LabelArController.text = about.stat2LabelAr;
      _stat3ValueController.text = about.stat3Value;
      _stat3LabelFrController.text = about.stat3LabelFr;
      _stat3LabelArController.text = about.stat3LabelAr;
      _stat4ValueController.text = about.stat4Value;
      _stat4LabelFrController.text = about.stat4LabelFr;
      _stat4LabelArController.text = about.stat4LabelAr;

      _emailController.text = about.email;
      _phoneController.text = about.phone;
      _addressFrController.text = about.addressFr;
      _addressArController.text = about.addressAr;

      _facebookUrlController.text = about.facebookUrl ?? '';
      _youtubeUrlController.text = about.youtubeUrl ?? '';
      _telegramUrlController.text = about.telegramUrl ?? '';
      _instagramUrlController.text = about.instagramUrl ?? '';

      _teamMembers = List.from(about.teamMembers);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final about = AboutModel(
      id: _aboutId,
      titleFr: _titleFrController.text,
      titleAr: _titleArController.text,
      sloganFr: _sloganFrController.text,
      sloganAr: _sloganArController.text,
      subtitleFr: _subtitleFrController.text,
      subtitleAr: _subtitleArController.text,
      descriptionFr: _descriptionFrController.text,
      descriptionAr: _descriptionArController.text,
      ctaFr: _callToActionFrController.text,
      ctaAr: _callToActionArController.text,
      visionFr:
          _visionFrController.text.isNotEmpty ? _visionFrController.text : null,
      visionAr:
          _visionArController.text.isNotEmpty ? _visionArController.text : null,
      missionFr:
          _missionFrController.text.isNotEmpty
              ? _missionFrController.text
              : null,
      missionAr:
          _missionArController.text.isNotEmpty
              ? _missionArController.text
              : null,
      values: _values,
      stat1Value: _stat1ValueController.text,
      stat1LabelFr: _stat1LabelFrController.text,
      stat1LabelAr: _stat1LabelArController.text,
      stat2Value: _stat2ValueController.text,
      stat2LabelFr: _stat2LabelFrController.text,
      stat2LabelAr: _stat2LabelArController.text,
      stat3Value: _stat3ValueController.text,
      stat3LabelFr: _stat3LabelFrController.text,
      stat3LabelAr: _stat3LabelArController.text,
      stat4Value: _stat4ValueController.text,
      stat4LabelFr: _stat4LabelFrController.text,
      stat4LabelAr: _stat4LabelArController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      addressFr: _addressFrController.text,
      addressAr: _addressArController.text,
      facebookUrl:
          _facebookUrlController.text.isNotEmpty
              ? _facebookUrlController.text
              : null,
      youtubeUrl:
          _youtubeUrlController.text.isNotEmpty
              ? _youtubeUrlController.text
              : null,
      telegramUrl:
          _telegramUrlController.text.isNotEmpty
              ? _telegramUrlController.text
              : null,
      instagramUrl:
          _instagramUrlController.text.isNotEmpty
              ? _instagramUrlController.text
              : null,
      teamMembers: _teamMembers,
    );

    final aboutProvider = Provider.of<AboutProvider>(context, listen: false);

    bool success;
    if (_aboutId != null) {
      success = await aboutProvider.updateAbout(about);
    } else {
      success = await aboutProvider.saveAbout(about);
    }

    setState(() => _isSaving = false);

    final isArabic =
        Provider.of<LanguageProvider>(context, listen: false).isArabic;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? '✅ تم حفظ البيانات بنجاح'
                : '✅ Données sauvegardées avec succès',
          ),
          backgroundColor: const Color(0xff0D443E),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? '❌ Erreur lors de la sauvegarde: ${aboutProvider.error}'
                : '❌ Erreur lors de la sauvegarde: ${aboutProvider.error}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addValue() {
    if (_valueController.text.isNotEmpty) {
      setState(() {
        _values.add(_valueController.text);
        _valueController.clear();
      });
    }
  }

  void _removeValue(int index) {
    setState(() {
      _values.removeAt(index);
    });
  }

  void _addTeamMember() {
    if (_teamNameController.text.isNotEmpty &&
        _teamRoleFrController.text.isNotEmpty &&
        _teamRoleArController.text.isNotEmpty) {
      setState(() {
        _teamMembers.add(
          TeamMember(
            name: _teamNameController.text,
            roleFr: _teamRoleFrController.text,
            roleAr: _teamRoleArController.text,
          ),
        );
        _teamNameController.clear();
        _teamRoleFrController.clear();
        _teamRoleArController.clear();
      });
    }
  }

  void _removeTeamMember(int index) {
    setState(() {
      _teamMembers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isArabic ? 'إدارة صفحة "عن المنصة"' : 'Gestion de la page "À propos"',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 16 : 20,
          ),
        ),
        backgroundColor: const Color(0xff0D443E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save_rounded),
              onPressed: _saveData,
              tooltip: isArabic ? 'حفظ' : 'Sauvegarder',
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Container(
                color: Colors.grey.shade50,
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ID affiché si existant
                          if (_aboutId != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xff0D443E,
                                ).withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(
                                    0xff0D443E,
                                  ).withOpacity(0.1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    color: Color(0xff0D443E),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isArabic
                                        ? 'ID: $_aboutId (en cours de modification)'
                                        : 'ID: $_aboutId (en cours de modification)',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: const Color(0xff0D443E),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          _buildSection(
                            title:
                                isArabic
                                    ? '🏷️ العنوان الرئيسي'
                                    : '🏷️ Titre principal',
                            child: Column(
                              children: [
                                _buildTextField(
                                  label:
                                      isArabic
                                          ? 'Titre (Français)'
                                          : 'Titre (Français)',
                                  controller: _titleFrController,
                                  isArabic: false,
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  label:
                                      isArabic
                                          ? 'Titre (Arabe)'
                                          : 'Titre (Arabe)',
                                  controller: _titleArController,
                                  isArabic: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildSection(
                            title: isArabic ? '✨ الشعار' : '✨ Slogan',
                            child: Column(
                              children: [
                                _buildTextField(
                                  label:
                                      isArabic
                                          ? 'Slogan (Français)'
                                          : 'Slogan (Français)',
                                  controller: _sloganFrController,
                                  isArabic: false,
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  label:
                                      isArabic
                                          ? 'Slogan (Arabe)'
                                          : 'Slogan (Arabe)',
                                  controller: _sloganArController,
                                  isArabic: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildSection(
                            title: isArabic ? '📖 Sous-titre' : '📖 Sous-titre',
                            child: Column(
                              children: [
                                _buildTextField(
                                  label:
                                      isArabic
                                          ? 'Sous-titre (Français)'
                                          : 'Sous-titre (Français)',
                                  controller: _subtitleFrController,
                                  isArabic: false,
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  label:
                                      isArabic
                                          ? 'Sous-titre (Arabe)'
                                          : 'Sous-titre (Arabe)',
                                  controller: _subtitleArController,
                                  isArabic: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildSection(
                            title:
                                isArabic ? '📝 Description' : '📝 Description',
                            child: Column(
                              children: [
                                _buildTextField(
                                  label:
                                      isArabic
                                          ? 'Description (Français)'
                                          : 'Description (Français)',
                                  controller: _descriptionFrController,
                                  isArabic: false,
                                  maxLines: 5,
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  label:
                                      isArabic
                                          ? 'Description (Arabe)'
                                          : 'Description (Arabe)',
                                  controller: _descriptionArController,
                                  isArabic: true,
                                  maxLines: 5,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildSection(
                            title:
                                isArabic
                                    ? '💚 Appel à l\'action'
                                    : '💚 Appel à l\'action',
                            child: Column(
                              children: [
                                _buildTextField(
                                  label:
                                      isArabic
                                          ? 'CTA (Français)'
                                          : 'CTA (Français)',
                                  controller: _callToActionFrController,
                                  isArabic: false,
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  label:
                                      isArabic ? 'CTA (Arabe)' : 'CTA (Arabe)',
                                  controller: _callToActionArController,
                                  isArabic: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildSection(
                            title: isArabic ? '👁️ Vision' : '👁️ Vision',
                            child: Column(
                              children: [
                                _buildTextField(
                                  label:
                                      isArabic
                                          ? 'Vision (Français)'
                                          : 'Vision (Français)',
                                  controller: _visionFrController,
                                  isArabic: false,
                                  maxLines: 3,
                                  required: false,
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  label:
                                      isArabic
                                          ? 'Vision (Arabe)'
                                          : 'Vision (Arabe)',
                                  controller: _visionArController,
                                  isArabic: true,
                                  maxLines: 3,
                                  required: false,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildSection(
                            title: isArabic ? '🎯 Mission' : '🎯 Mission',
                            child: Column(
                              children: [
                                _buildTextField(
                                  label:
                                      isArabic
                                          ? 'Mission (Français)'
                                          : 'Mission (Français)',
                                  controller: _missionFrController,
                                  isArabic: false,
                                  maxLines: 3,
                                  required: false,
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  label:
                                      isArabic
                                          ? 'Mission (Arabe)'
                                          : 'Mission (Arabe)',
                                  controller: _missionArController,
                                  isArabic: true,
                                  maxLines: 3,
                                  required: false,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildSection(
                            title:
                                isArabic
                                    ? '🏷️ Valeurs / Thèmes'
                                    : '🏷️ Valeurs / Thèmes',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children:
                                      _values.asMap().entries.map((entry) {
                                        final index = entry.key;
                                        final value = entry.value;
                                        return Chip(
                                          label: Text(value),
                                          onDeleted: () => _removeValue(index),
                                          deleteIcon: const Icon(
                                            Icons.close,
                                            size: 16,
                                          ),
                                          backgroundColor: const Color(
                                            0xff0D443E,
                                          ).withOpacity(0.08),
                                          labelStyle: GoogleFonts.poppins(
                                            fontSize: 13,
                                          ),
                                        );
                                      }).toList(),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _valueController,
                                        decoration: InputDecoration(
                                          hintText:
                                              isArabic
                                                  ? 'Ajouter une valeur...'
                                                  : 'Ajouter une valeur...',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                        ),
                                        onSubmitted: (_) => _addValue(),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.add_circle,
                                        color: Color(0xff0D443E),
                                      ),
                                      onPressed: _addValue,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildSection(
                            title:
                                isArabic
                                    ? '📊 Statistiques'
                                    : '📊 Statistiques',
                            child: Column(
                              children: [
                                _buildStatRow(
                                  statLabel:
                                      isArabic
                                          ? 'Statistique 1'
                                          : 'Statistique 1',
                                  valueController: _stat1ValueController,
                                  labelFrController: _stat1LabelFrController,
                                  labelArController: _stat1LabelArController,
                                  isArabic: isArabic,
                                ),
                                const SizedBox(height: 12),
                                _buildStatRow(
                                  statLabel:
                                      isArabic
                                          ? 'Statistique 2'
                                          : 'Statistique 2',
                                  valueController: _stat2ValueController,
                                  labelFrController: _stat2LabelFrController,
                                  labelArController: _stat2LabelArController,
                                  isArabic: isArabic,
                                ),
                                const SizedBox(height: 12),
                                _buildStatRow(
                                  statLabel:
                                      isArabic
                                          ? 'Statistique 3'
                                          : 'Statistique 3',
                                  valueController: _stat3ValueController,
                                  labelFrController: _stat3LabelFrController,
                                  labelArController: _stat3LabelArController,
                                  isArabic: isArabic,
                                ),
                                const SizedBox(height: 12),
                                _buildStatRow(
                                  statLabel:
                                      isArabic
                                          ? 'Statistique 4'
                                          : 'Statistique 4',
                                  valueController: _stat4ValueController,
                                  labelFrController: _stat4LabelFrController,
                                  labelArController: _stat4LabelArController,
                                  isArabic: isArabic,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildSection(
                            title: isArabic ? '📬 Contact' : '📬 Contact',
                            child: Column(
                              children: [
                                _buildTextField(
                                  label: isArabic ? 'Email' : 'Email',
                                  controller: _emailController,
                                  isArabic: false,
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  label: isArabic ? 'Téléphone' : 'Téléphone',
                                  controller: _phoneController,
                                  isArabic: false,
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  label:
                                      isArabic
                                          ? 'Adresse (Français)'
                                          : 'Adresse (Français)',
                                  controller: _addressFrController,
                                  isArabic: false,
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  label:
                                      isArabic
                                          ? 'Adresse (Arabe)'
                                          : 'Adresse (Arabe)',
                                  controller: _addressArController,
                                  isArabic: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildSection(
                            title:
                                isArabic
                                    ? '🌐 Réseaux sociaux'
                                    : '🌐 Réseaux sociaux',
                            child: Column(
                              children: [
                                _buildTextField(
                                  label:
                                      isArabic
                                          ? 'Facebook URL'
                                          : 'Facebook URL',
                                  controller: _facebookUrlController,
                                  isArabic: false,
                                  required: false,
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  label:
                                      isArabic ? 'YouTube URL' : 'YouTube URL',
                                  controller: _youtubeUrlController,
                                  isArabic: false,
                                  required: false,
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  label:
                                      isArabic
                                          ? 'Telegram URL'
                                          : 'Telegram URL',
                                  controller: _telegramUrlController,
                                  isArabic: false,
                                  required: false,
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  label:
                                      isArabic
                                          ? 'Instagram URL'
                                          : 'Instagram URL',
                                  controller: _instagramUrlController,
                                  isArabic: false,
                                  required: false,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildSection(
                            title: isArabic ? '👥 Équipe' : '👥 Équipe',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ..._teamMembers.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final member = entry.value;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                member.name,
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                '${member.roleFr} / ${member.roleAr}',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.close,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          onPressed:
                                              () => _removeTeamMember(index),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: TextField(
                                        controller: _teamNameController,
                                        decoration: InputDecoration(
                                          hintText: isArabic ? 'Nom' : 'Nom',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: _teamRoleFrController,
                                        decoration: InputDecoration(
                                          hintText:
                                              isArabic
                                                  ? 'Rôle (FR)'
                                                  : 'Rôle (FR)',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: _teamRoleArController,
                                        textDirection: TextDirection.rtl,
                                        decoration: InputDecoration(
                                          hintText:
                                              isArabic
                                                  ? 'Rôle (AR)'
                                                  : 'Rôle (AR)',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.add_circle,
                                        color: Color(0xff0D443E),
                                      ),
                                      onPressed: _addTeamMember,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Bouton de sauvegarde
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff0D443E),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child:
                                  _isSaving
                                      ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                      : Text(
                                        isArabic
                                            ? '💾 حفظ جميع التغييرات'
                                            : '💾 Sauvegarder toutes les modifications',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
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
              ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xff0D443E),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool isArabic,
    int maxLines = 1,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xff0D443E), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: (value) {
        if (required && (value == null || value.isEmpty)) {
          return 'Ce champ est requis';
        }
        return null;
      },
    );
  }

  Widget _buildStatRow({
    required String statLabel,
    required TextEditingController valueController,
    required TextEditingController labelFrController,
    required TextEditingController labelArController,
    required bool isArabic,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: TextField(
              controller: valueController,
              decoration: InputDecoration(
                hintText: isArabic ? 'Valeur' : 'Valeur',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              controller: labelFrController,
              decoration: InputDecoration(
                hintText: isArabic ? 'Label FR' : 'Label FR',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              controller: labelArController,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: isArabic ? 'Label AR' : 'Label AR',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
