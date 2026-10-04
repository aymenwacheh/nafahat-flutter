// lib/pages/adminisration/apparence_card_formateur.dart
import 'package:flutter/material.dart';
import 'package:nafahat/pages/widgets/painter_color_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nafahat/services/formateur_card_config_manager.dart';
import 'package:nafahat/pages/adminisration/admin_page_wrapper.dart';
import 'dart:convert';

class ApparenceCardFormateurPage extends StatefulWidget {
  const ApparenceCardFormateurPage({super.key});

  @override
  State<ApparenceCardFormateurPage> createState() =>
      _ApparenceCardFormateurPageState();
}

class _ApparenceCardFormateurPageState
    extends State<ApparenceCardFormateurPage> {
  bool _isArabic = false;
  bool _isLoading = true;

  // Configuration de la carte formateur
  FormateurCardConfig _config = FormateurCardConfig.defaultConfig();

  // Options disponibles pour les champs
  final List<FormateurCardFieldOption> _availableFields = [
    FormateurCardFieldOption(
      id: 'name',
      labelFr: 'Nom',
      labelAr: 'الاسم',
      icon: Icons.person,
      defaultVisible: true,
    ),
    FormateurCardFieldOption(
      id: 'speciality',
      labelFr: 'Spécialité',
      labelAr: 'التخصص',
      icon: Icons.psychology,
      defaultVisible: true,
    ),
    FormateurCardFieldOption(
      id: 'experience',
      labelFr: 'Expérience',
      labelAr: 'الخبرة',
      icon: Icons.work,
      defaultVisible: true,
    ),
    FormateurCardFieldOption(
      id: 'rating',
      labelFr: 'Note',
      labelAr: 'التقييم',
      icon: Icons.star,
      defaultVisible: true,
    ),
    FormateurCardFieldOption(
      id: 'formations_count',
      labelFr: 'Nombre de formations',
      labelAr: 'عدد التكوينات',
      icon: Icons.school,
      defaultVisible: false,
    ),
    FormateurCardFieldOption(
      id: 'email',
      labelFr: 'Email',
      labelAr: 'البريد الإلكتروني',
      icon: Icons.email,
      defaultVisible: false,
    ),
    FormateurCardFieldOption(
      id: 'phone',
      labelFr: 'Téléphone',
      labelAr: 'الهاتف',
      icon: Icons.phone,
      defaultVisible: false,
    ),
    FormateurCardFieldOption(
      id: 'location',
      labelFr: 'Localisation',
      labelAr: 'الموقع',
      icon: Icons.location_on,
      defaultVisible: false,
    ),
  ];

  // Formateur de prévisualisation
  final FormateurPreview _previewFormateur = FormateurPreview(
    name: 'Mohamed Amine',
    nameAr: 'محمد أمين',
    speciality: 'Développement Mobile',
    specialityAr: 'تطوير التطبيقات',
    experience: '8 ans d\'expérience',
    experienceAr: '8 سنوات من الخبرة',
    rating: 4.8,
    formationsCount: 15,
    email: 'amine@nafahat.com',
    phone: '+212 6 00 00 00 00',
    location: 'Casablanca',
    locationAr: 'الدار البيضاء',
    imageUrl: 'https://picsum.photos/seed/formateur/800/450',
  );

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString('formateur_card_config');
      if (configJson != null && configJson.isNotEmpty) {
        setState(() {
          _config = FormateurCardConfig.fromJson(json.decode(configJson));
          _isLoading = false;
        });
      } else {
        setState(() {
          _config = FormateurCardConfig.defaultConfig();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _config = FormateurCardConfig.defaultConfig();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'formateur_card_config',
        json.encode(_config.toJson()),
      );

      // Application immédiate sur les cartes déjà affichées.
      await FormateurCardConfigManager().saveConfig(_config);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isArabic ? '✅ تم حفظ الإعدادات' : '✅ Configuration sauvegardée',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: const Color(0xff0D443E),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isArabic
                ? '❌ Erreur lors de la sauvegarde'
                : '❌ Erreur lors de la sauvegarde',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resetToDefault() {
    setState(() {
      _config = FormateurCardConfig.defaultConfig();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return AdminPageWrapper(
      title: 'Apparence des cartes formateur',
      titleAr: 'إعدادات مظهر بطاقة المكون',
      backgroundColor: const Color(0xFFFAFAFA),
      actions: [
        IconButton(
          icon: const Icon(Icons.language),
          onPressed: () => setState(() => _isArabic = !_isArabic),
          tooltip: _isArabic ? 'Français' : 'العربية',
        ),
        TextButton(
          onPressed: _resetToDefault,
          child: Text(
            _isArabic ? 'إعادة تعيين' : 'Réinitialiser',
            style: GoogleFonts.cairo(color: Colors.white70),
          ),
        ),
      ],
      child:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 12 : 24),
                child: Column(
                  children: [
                    // Aperçu
                    _buildPreviewSection(isMobile),
                    const SizedBox(height: 24),

                    // Paramètres d'affichage mobile
                    _buildMobileDisplaySettings(isMobile),
                    const SizedBox(height: 24),

                    // Style avancé du conteneur
                    _buildCardContainerStyle(isMobile),
                    const SizedBox(height: 24),

                    // Champs à afficher
                    _buildFieldsSection(isMobile),
                    const SizedBox(height: 24),

                    // Style du nom
                    _buildNameStyleSection(isMobile),
                    const SizedBox(height: 24),

                    // Style des autres champs
                    _buildFieldsStyleSection(isMobile),
                    const SizedBox(height: 24),

                    // Boutons
                    _buildActionButtons(isMobile),
                  ],
                ),
              ),
    );
  }

  // ============================================================
  // SECTION : CHAMPS À AFFICHER
  // ============================================================
  Widget _buildCardContainerStyle(bool isMobile) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isArabic ? '🎨 Style de la carte' : '🎨 Style de la carte',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xff0D443E),
              ),
            ),
            const SizedBox(height: 14),
            _buildColorPicker(
              label: _isArabic ? 'الخلفية' : 'Fond',
              currentColor: _config.cardBackgroundColor,
              onChanged: (c) => setState(() => _config.cardBackgroundColor = c),
              isArabic: _isArabic,
            ),
            const SizedBox(height: 14),
            _buildColorPicker(
              label: _isArabic ? 'الحدود' : 'Bordure',
              currentColor: _config.cardBorderColor,
              onChanged: (c) => setState(() => _config.cardBorderColor = c),
              isArabic: _isArabic,
            ),
            const SizedBox(height: 14),
            _buildColorPicker(
              label: _isArabic ? 'اللون المميز' : 'Accent',
              currentColor: _config.accentColor,
              onChanged: (c) => setState(() => _config.accentColor = c),
              isArabic: _isArabic,
            ),
            const SizedBox(height: 16),
            _simpleSlider(
              label: _isArabic ? 'تقويس الزوايا' : 'Arrondi',
              value: _config.cardBorderRadius,
              min: 0,
              max: 36,
              onChanged: (v) => setState(() => _config.cardBorderRadius = v),
            ),
            _simpleSlider(
              label: _isArabic ? 'قوة الظل' : 'Intensité de l’ombre',
              value: _config.shadowStrength * 100,
              min: 0,
              max: 25,
              onChanged: (v) =>
                  setState(() => _config.shadowStrength = v / 100),
            ),
            _simpleSlider(
              label: _isArabic ? 'حجم الصورة' : 'Taille de la photo',
              value: _config.photoScale * 100,
              min: 70,
              max: 140,
              onChanged: (v) =>
                  setState(() => _config.photoScale = v / 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _simpleSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        SizedBox(
          width: 240,
          child: Slider(
            value: value.clamp(min, max).toDouble(),
            min: min,
            max: max,
            divisions: (max - min).round(),
            activeColor: const Color(0xff0D443E),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 46,
          child: Text(
            value.toStringAsFixed(0),
            textAlign: TextAlign.end,
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldsSection(bool isMobile) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isArabic ? '📋 Champs à afficher' : '📋 Champs à afficher',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xff0D443E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isArabic
                  ? 'Sélectionnez les informations à afficher sur la carte'
                  : 'Sélectionnez les informations à afficher sur la carte',
              style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _availableFields.map((field) {
                    final isVisible = _config.visibleFields.contains(field.id);
                    return FilterChip(
                      selected: isVisible,
                      label: Text(
                        _isArabic ? field.labelAr : field.labelFr,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight:
                              isVisible ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      avatar: Icon(
                        field.icon,
                        size: 16,
                        color: isVisible ? Colors.white : Colors.grey[600],
                      ),
                      selectedColor: const Color(0xff0D443E),
                      backgroundColor: Colors.grey[100],
                      checkmarkColor: Colors.white,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _config.visibleFields.add(field.id);
                          } else {
                            _config.visibleFields.remove(field.id);
                          }
                        });
                      },
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION : STYLE DU NOM (couleur, taille, police)
  // ============================================================
  Widget _buildNameStyleSection(bool isMobile) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isArabic ? '📌 Style du nom' : '📌 Style du nom',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xff0D443E),
              ),
            ),
            const SizedBox(height: 16),

            // Police du nom
            _buildFontSelector(
              label: _isArabic ? 'Police du nom' : 'Police du nom',
              currentValue: _config.nameFontFamily,
              onChanged: (value) {
                setState(() {
                  _config.nameFontFamily = value!;
                });
              },
              isArabic: _isArabic,
            ),
            const SizedBox(height: 16),

            // Taille du nom
            _buildSizeSelector(
              label: _isArabic ? 'Taille du nom' : 'Taille du nom',
              currentValue: _config.nameFontSize,
              onChanged: (value) {
                setState(() {
                  _config.nameFontSize = value!;
                });
              },
              isArabic: _isArabic,
              minValue: 8,
              maxValue: 28,
            ),
            const SizedBox(height: 16),

            // Couleur du nom
            _buildColorPicker(
              label: _isArabic ? 'Couleur du nom' : 'Couleur du nom',
              currentColor: _config.nameColor,
              onChanged: (color) {
                setState(() {
                  _config.nameColor = color;
                });
              },
              isArabic: _isArabic,
            ),
            const SizedBox(height: 8),

            // Épaisseur du nom
            _buildWeightSelector(
              label: _isArabic ? 'Épaisseur du nom' : 'Épaisseur du nom',
              currentValue: _config.nameFontWeight,
              onChanged: (value) {
                setState(() {
                  _config.nameFontWeight = value;
                });
              },
              isArabic: _isArabic,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION : STYLE DES AUTRES CHAMPS (couleur, taille, police)
  // ============================================================
  Widget _buildFieldsStyleSection(bool isMobile) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isArabic
                  ? '📝 Style des autres champs'
                  : '📝 Style des autres champs',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xff0D443E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isArabic
                  ? 'Couleur, taille et police des champs (spécialité, expérience, note...)'
                  : 'Couleur, taille et police des champs (spécialité, expérience, note...)',
              style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Police des champs
            _buildFontSelector(
              label: _isArabic ? 'Police des champs' : 'Police des champs',
              currentValue: _config.fieldsFontFamily,
              onChanged: (value) {
                setState(() {
                  _config.fieldsFontFamily = value!;
                });
              },
              isArabic: _isArabic,
            ),
            const SizedBox(height: 16),

            // Taille des champs
            _buildSizeSelector(
              label: _isArabic ? 'Taille des champs' : 'Taille des champs',
              currentValue: _config.fieldsFontSize,
              onChanged: (value) {
                setState(() {
                  _config.fieldsFontSize = value!;
                });
              },
              isArabic: _isArabic,
              minValue: 6,
              maxValue: 18,
            ),
            const SizedBox(height: 16),

            // Couleur des champs
            _buildColorPicker(
              label: _isArabic ? 'Couleur des champs' : 'Couleur des champs',
              currentColor: _config.fieldsColor,
              onChanged: (color) {
                setState(() {
                  _config.fieldsColor = color;
                });
              },
              isArabic: _isArabic,
            ),
            const SizedBox(height: 8),

            // Épaisseur des champs
            _buildWeightSelector(
              label:
                  _isArabic ? 'Épaisseur des champs' : 'Épaisseur des champs',
              currentValue: _config.fieldsFontWeight,
              onChanged: (value) {
                setState(() {
                  _config.fieldsFontWeight = value;
                });
              },
              isArabic: _isArabic,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION : PARAMÈTRES MOBILE
  // ============================================================
  Widget _buildMobileDisplaySettings(bool isMobile) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.phone_android, color: const Color(0xff0D443E)),
                const SizedBox(width: 8),
                Text(
                  _isArabic
                      ? '📱 Paramètres d\'affichage mobile'
                      : '📱 Paramètres d\'affichage mobile',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff0D443E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _isArabic
                  ? 'Configurez l\'affichage des formateurs sur la page d\'accueil (version mobile)'
                  : 'Configurez l\'affichage des formateurs sur la page d\'accueil (version mobile)',
              style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isArabic
                            ? 'Nombre de cartes à afficher'
                            : 'Nombre de cartes à afficher',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _config.mobileDisplayCount,
                            isExpanded: true,
                            items:
                                List.generate(10, (index) => index + 1).map((
                                  count,
                                ) {
                                  return DropdownMenuItem<int>(
                                    value: count,
                                    child: Text(
                                      '$count ${_isArabic ? 'بطاقة' : 'cartes'}',
                                      style: GoogleFonts.cairo(fontSize: 14),
                                    ),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _config.mobileDisplayCount = value!;
                              });
                            },
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: const Color(0xff0D443E),
                            ),
                            style: GoogleFonts.cairo(
                              color: const Color(0xff0D443E),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isArabic
                            ? 'Afficher le bouton "Voir plus"'
                            : 'Afficher le bouton "Voir plus"',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<bool>(
                            value: _config.showSeeMoreButton,
                            isExpanded: true,
                            items: [
                              DropdownMenuItem<bool>(
                                value: true,
                                child: Text(
                                  _isArabic ? 'نعم' : 'Oui',
                                  style: GoogleFonts.cairo(fontSize: 14),
                                ),
                              ),
                              DropdownMenuItem<bool>(
                                value: false,
                                child: Text(
                                  _isArabic ? 'لا' : 'Non',
                                  style: GoogleFonts.cairo(fontSize: 14),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _config.showSeeMoreButton = value!;
                              });
                            },
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: const Color(0xff0D443E),
                            ),
                            style: GoogleFonts.cairo(
                              color: const Color(0xff0D443E),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION : APERÇU
  // ============================================================
  Widget _buildPreviewSection(bool isMobile) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.preview, color: const Color(0xff0D443E)),
                const SizedBox(width: 8),
                Text(
                  _isArabic ? '👁️ Aperçu en direct' : '👁️ Aperçu en direct',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff0D443E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Container(
                decoration: BoxDecoration(
                  color: _config.cardBackgroundColor,
                  borderRadius: BorderRadius.circular(_config.cardBorderRadius),
                  border: Border.all(color: _config.cardBorderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(
                        _config.shadowStrength.clamp(0.0, 0.30).toDouble(),
                      ),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(_config.cardBorderRadius),
                      ),
                      child: Image.network(
                        'https://picsum.photos/seed/formateur/400/200',
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // NOM
                          if (_config.visibleFields.contains('name'))
                            Text(
                              _isArabic
                                  ? _previewFormateur.nameAr
                                  : _previewFormateur.name,
                              style: _getFontWithFamily(
                                _config.nameFontFamily,
                                _config.nameFontSize,
                                _config.nameFontWeight,
                                _config.nameColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 6),

                          // AUTRES CHAMPS
                          if (_config.visibleFields.contains('speciality'))
                            _buildPreviewFieldRow(
                              Icons.psychology,
                              _isArabic
                                  ? _previewFormateur.specialityAr
                                  : _previewFormateur.speciality,
                            ),
                          if (_config.visibleFields.contains('experience'))
                            _buildPreviewFieldRow(
                              Icons.work,
                              _isArabic
                                  ? _previewFormateur.experienceAr
                                  : _previewFormateur.experience,
                            ),
                          if (_config.visibleFields.contains('rating'))
                            _buildPreviewFieldRow(
                              Icons.star,
                              '${_previewFormateur.rating} / 5 ★',
                            ),
                          if (_config.visibleFields.contains(
                            'formations_count',
                          ))
                            _buildPreviewFieldRow(
                              Icons.school,
                              '${_previewFormateur.formationsCount}',
                            ),
                          if (_config.visibleFields.contains('email'))
                            _buildPreviewFieldRow(
                              Icons.email,
                              _previewFormateur.email,
                            ),
                          if (_config.visibleFields.contains('phone'))
                            _buildPreviewFieldRow(
                              Icons.phone,
                              _previewFormateur.phone,
                            ),
                          if (_config.visibleFields.contains('location'))
                            _buildPreviewFieldRow(
                              Icons.location_on,
                              _isArabic
                                  ? _previewFormateur.locationAr
                                  : _previewFormateur.location,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Ligne de prévisualisation pour les champs (sans libellé)
  Widget _buildPreviewFieldRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Icon(icon, size: 12, color: _config.fieldsColor),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: _getFontWithFamily(
                _config.fieldsFontFamily,
                _config.fieldsFontSize,
                _config.fieldsFontWeight,
                _config.fieldsColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOUTONS D'ACTION
  // ============================================================
  Widget _buildActionButtons(bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[700],
              side: BorderSide(color: Colors.grey[300]!),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              _isArabic ? 'إلغاء' : 'Annuler',
              style: GoogleFonts.cairo(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveConfig,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff0D443E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 4,
            ),
            child: Text(
              _isArabic ? '💾 Sauvegarder' : '💾 Sauvegarder',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MÉTHODES UTILITAIRES
  // ============================================================

  String _extractFontFamily(String fontWithVariant) {
    if (fontWithVariant.contains('-')) {
      return fontWithVariant.split('-').first;
    }
    return fontWithVariant;
  }

  TextStyle _getFontWithFamily(
    String fontWithVariant,
    double fontSize,
    FontWeight fontWeight,
    Color color,
  ) {
    final family = _extractFontFamily(fontWithVariant);
    return GoogleFonts.getFont(
      family,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  Widget _buildFontSelector({
    required String label,
    required String currentValue,
    required ValueChanged<String?> onChanged,
    required bool isArabic,
  }) {
    final fonts = ['Cairo-Regular', 'Cairo-Bold', 'Cairo-Light'];

    final displayNames = {
      'Cairo-Regular': 'Cairo (Regular)',
      'Cairo-Bold': 'Cairo (Bold)',
      'Cairo-Light': 'Cairo (Light)',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentValue,
              isExpanded: true,
              items:
                  fonts.map((font) {
                    return DropdownMenuItem<String>(
                      value: font,
                      child: Text(
                        displayNames[font] ?? font,
                        style: GoogleFonts.getFont(
                          _extractFontFamily(font),
                          fontSize: 14,
                        ),
                      ),
                    );
                  }).toList(),
              onChanged: onChanged,
              icon: Icon(Icons.arrow_drop_down, color: const Color(0xff0D443E)),
              style: GoogleFonts.cairo(color: const Color(0xff0D443E)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSizeSelector({
    required String label,
    required double currentValue,
    required ValueChanged<double?> onChanged,
    required bool isArabic,
    required double minValue,
    required double maxValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label : ${currentValue.toInt()}px',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        Slider(
          value: currentValue,
          min: minValue,
          max: maxValue,
          divisions: (maxValue - minValue).toInt(),
          activeColor: const Color(0xff0D443E),
          inactiveColor: Colors.grey[300],
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildColorPicker({
    required String label,
    required Color currentColor,
    required ValueChanged<Color> onChanged,
    required bool isArabic,
  }) {
    return PainterColorPickerField(
      label: label,
      color: currentColor,
      onChanged: onChanged,
      isArabic: isArabic,
    );
  }

  Widget _buildWeightSelector({
    required String label,
    required FontWeight currentValue,
    required ValueChanged<FontWeight> onChanged,
    required bool isArabic,
  }) {
    final weights = [
      FontWeight.w100,
      FontWeight.w200,
      FontWeight.w300,
      FontWeight.w400,
      FontWeight.w500,
      FontWeight.w600,
      FontWeight.w700,
      FontWeight.w800,
      FontWeight.w900,
    ];

    final weightLabels = {
      FontWeight.w100: '100 (Thin)',
      FontWeight.w200: '200 (ExtraLight)',
      FontWeight.w300: '300 (Light)',
      FontWeight.w400: '400 (Regular)',
      FontWeight.w500: '500 (Medium)',
      FontWeight.w600: '600 (SemiBold)',
      FontWeight.w700: '700 (Bold)',
      FontWeight.w800: '800 (ExtraBold)',
      FontWeight.w900: '900 (Black)',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<FontWeight>(
              value: currentValue,
              isExpanded: true,
              items:
                  weights.map((weight) {
                    return DropdownMenuItem<FontWeight>(
                      value: weight,
                      child: Text(
                        weightLabels[weight] ?? weight.toString(),
                        style: TextStyle(fontWeight: weight, fontSize: 14),
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) onChanged(value);
              },
              icon: Icon(Icons.arrow_drop_down, color: const Color(0xff0D443E)),
              style: GoogleFonts.cairo(color: const Color(0xff0D443E)),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// MODÈLES
// ============================================================

class FormateurCardConfig {
  // Champs visibles
  List<String> visibleFields;

  // Style du NOM
  String nameFontFamily;
  double nameFontSize;
  FontWeight nameFontWeight;
  Color nameColor;

  // Style des AUTRES CHAMPS
  String fieldsFontFamily;
  double fieldsFontSize;
  FontWeight fieldsFontWeight;
  Color fieldsColor;

  // Style du conteneur
  Color cardBackgroundColor;
  Color cardBorderColor;
  Color accentColor;
  double cardBorderRadius;
  double shadowStrength;
  double photoScale;

  // Paramètres d'affichage mobile
  int mobileDisplayCount;
  bool showSeeMoreButton;

  FormateurCardConfig({
    this.visibleFields = const ['name', 'speciality', 'experience', 'rating'],
    this.nameFontFamily = 'Cairo-Bold',
    this.nameFontSize = 16,
    this.nameFontWeight = FontWeight.bold,
    this.nameColor = const Color(0xff1A1A1A),
    this.fieldsFontFamily = 'Cairo-Regular',
    this.fieldsFontSize = 12,
    this.fieldsFontWeight = FontWeight.w500,
    this.fieldsColor = const Color(
      0xff616161,
    ),
    this.cardBackgroundColor = Colors.white,
    this.cardBorderColor = const Color(0xffE5E7EB),
    this.accentColor = const Color(0xffD57653),
    this.cardBorderRadius = 16,
    this.shadowStrength = 0.06,
    this.photoScale = 1.0,
    this.mobileDisplayCount = 4,
    this.showSeeMoreButton = true,
  });

  factory FormateurCardConfig.defaultConfig() {
    return FormateurCardConfig();
  }

  factory FormateurCardConfig.fromJson(Map<String, dynamic> json) {
    return FormateurCardConfig(
      visibleFields: List<String>.from(
        json['visibleFields'] ?? ['name', 'speciality', 'experience', 'rating'],
      ),
      nameFontFamily: json['nameFontFamily'] ?? 'Cairo-Bold',
      nameFontSize: (json['nameFontSize'] ?? 16).toDouble(),
      nameFontWeight: _fontWeightFromValue(json['nameFontWeight'] ?? 700),
      nameColor: _colorFromJson(json['nameColor']),
      fieldsFontFamily: json['fieldsFontFamily'] ?? 'Cairo-Regular',
      fieldsFontSize: (json['fieldsFontSize'] ?? 12).toDouble(),
      fieldsFontWeight: _fontWeightFromValue(json['fieldsFontWeight'] ?? 500),
      fieldsColor: _colorFromJson(json['fieldsColor']),
      cardBackgroundColor:
          _colorFromJson(json['cardBackgroundColor'] ?? '#FFFFFFFF'),
      cardBorderColor:
          _colorFromJson(json['cardBorderColor'] ?? '#FFE5E7EB'),
      accentColor: _colorFromJson(json['accentColor'] ?? '#FFD57653'),
      cardBorderRadius: (json['cardBorderRadius'] ?? 16).toDouble(),
      shadowStrength: (json['shadowStrength'] ?? 0.06).toDouble(),
      photoScale: (json['photoScale'] ?? 1.0).toDouble(),
      mobileDisplayCount: json['mobileDisplayCount'] ?? 4,
      showSeeMoreButton: json['showSeeMoreButton'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'visibleFields': visibleFields,
      'nameFontFamily': nameFontFamily,
      'nameFontSize': nameFontSize,
      'nameFontWeight': nameFontWeight.index,
      'nameColor': _colorToJson(nameColor),
      'fieldsFontFamily': fieldsFontFamily,
      'fieldsFontSize': fieldsFontSize,
      'fieldsFontWeight': fieldsFontWeight.index,
      'fieldsColor': _colorToJson(fieldsColor),
      'cardBackgroundColor': _colorToJson(cardBackgroundColor),
      'cardBorderColor': _colorToJson(cardBorderColor),
      'accentColor': _colorToJson(accentColor),
      'cardBorderRadius': cardBorderRadius,
      'shadowStrength': shadowStrength,
      'photoScale': photoScale,
      'mobileDisplayCount': mobileDisplayCount,
      'showSeeMoreButton': showSeeMoreButton,
    };
  }

  static FontWeight _fontWeightFromValue(int value) {
    switch (value) {
      case 100:
        return FontWeight.w100;
      case 200:
        return FontWeight.w200;
      case 300:
        return FontWeight.w300;
      case 400:
        return FontWeight.w400;
      case 500:
        return FontWeight.w500;
      case 600:
        return FontWeight.w600;
      case 700:
        return FontWeight.w700;
      case 800:
        return FontWeight.w800;
      case 900:
        return FontWeight.w900;
      default:
        return FontWeight.w400;
    }
  }

  static Color _colorFromJson(dynamic value) {
    if (value is int) return Color(value);
    if (value is String) {
      var hex = value.trim().replaceAll('#', '').replaceAll('0x', '');
      if (hex.length == 6) hex = 'FF$hex';
      final parsed = int.tryParse(hex, radix: 16);
      if (parsed != null) return Color(parsed);
    }
    return Colors.grey[700]!;
  }

  static String _colorToJson(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0')}';
  }
}

class FormateurCardFieldOption {
  final String id;
  final String labelFr;
  final String labelAr;
  final IconData icon;
  final bool defaultVisible;

  FormateurCardFieldOption({
    required this.id,
    required this.labelFr,
    required this.labelAr,
    required this.icon,
    this.defaultVisible = false,
  });
}

class FormateurPreview {
  final String name;
  final String nameAr;
  final String speciality;
  final String specialityAr;
  final String experience;
  final String experienceAr;
  final double rating;
  final int formationsCount;
  final String email;
  final String phone;
  final String location;
  final String locationAr;
  final String imageUrl;

  FormateurPreview({
    required this.name,
    required this.nameAr,
    required this.speciality,
    required this.specialityAr,
    required this.experience,
    required this.experienceAr,
    required this.rating,
    required this.formationsCount,
    required this.email,
    required this.phone,
    required this.location,
    required this.locationAr,
    required this.imageUrl,
  });
}
