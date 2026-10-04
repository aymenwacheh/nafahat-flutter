// lib/pages/adminisration/apparence_card.dart
import 'package:flutter/material.dart';
import 'package:nafahat/pages/widgets/painter_color_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafahat/models/training_model.dart';
import 'package:nafahat/services/training_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nafahat/services/card_config_manager.dart';
import 'package:nafahat/models/card_config_model.dart';
import 'package:nafahat/pages/adminisration/admin_page_wrapper.dart';
import 'dart:convert';

class ApparenceCardPage extends StatefulWidget {
  const ApparenceCardPage({super.key});

  @override
  State<ApparenceCardPage> createState() => _ApparenceCardPageState();
}

class _ApparenceCardPageState extends State<ApparenceCardPage> {
  bool _isArabic = false;
  bool _isLoading = true;

  // Configuration de la carte
  CardConfig _config = CardConfig.defaultConfig();

  // Liste des formations disponibles pour la sélection
  List<TrainingModel> _availableTrainings = [];
  bool _isLoadingTrainings = false;

  // Options disponibles
  final List<CardFieldOption> _availableFields = [
    CardFieldOption(
      id: 'title',
      labelFr: 'Titre',
      labelAr: 'العنوان',
      icon: Icons.title,
      defaultVisible: true,
    ),
    CardFieldOption(
      id: 'trainer',
      labelFr: 'Formateur',
      labelAr: 'المكون',
      icon: Icons.person,
      defaultVisible: true,
    ),
    CardFieldOption(
      id: 'duration',
      labelFr: 'Durée',
      labelAr: 'المدة',
      icon: Icons.access_time,
      defaultVisible: true,
    ),
    CardFieldOption(
      id: 'period',
      labelFr: 'Période',
      labelAr: 'الفترة',
      icon: Icons.calendar_today,
      defaultVisible: true,
    ),
    CardFieldOption(
      id: 'target',
      labelFr: 'Public cible',
      labelAr: 'الجمهور المستهدف',
      icon: Icons.people,
      defaultVisible: false,
    ),
    CardFieldOption(
      id: 'price',
      labelFr: 'Prix',
      labelAr: 'السعر',
      icon: Icons.money,
      defaultVisible: true,
    ),
    CardFieldOption(
      id: 'discount',
      labelFr: 'Réduction',
      labelAr: 'الخصم',
      icon: Icons.local_offer,
      defaultVisible: true,
    ),
    CardFieldOption(
      id: 'type',
      labelFr: 'Type de formation',
      labelAr: 'نوع التكوين',
      icon: Icons.school,
      defaultVisible: false,
    ),
    CardFieldOption(
      id: 'category',
      labelFr: 'Catégorie',
      labelAr: 'التصنيف',
      icon: Icons.category,
      defaultVisible: false,
    ),
  ];

  // ✅ Prévisualisation - AJOUT des 3 prix
  final TrainingModel _previewTraining = TrainingModel(
    id: 'preview',
    titleFr: 'Formation Flutter Avancé',
    titleAr: 'دورة فلاتر المتقدمة',
    descriptionFr: 'Maîtrisez Flutter avec des projets concrets',
    descriptionAr: 'إتقان فلاتر من خلال مشاريع عملية',
    price: 15000,
    priceDt: 15000,
    priceEur: 450,
    priceUsd: 550,
    discountValue: 3000,
    hasDiscount: true,
    isPercentageDiscount: true,
    typeDuree: '3 mois',
    dateDebut: '2026-07-15',
    dateFin: '2026-10-15',
    target: 'Développeurs intermédiaires',
    typeFormation: 'Présentiel',
    categorieFr: 'Développement',
    categorieAr: 'تطوير',
    trainer: 'Mohamed Amine',
    imageUrl: 'https://picsum.photos/seed/preview/800/450',
    period: '15/07/2026 - 15/10/2026',
  );

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _loadTrainings();
  }

  Future<void> _loadTrainings() async {
    setState(() => _isLoadingTrainings = true);
    try {
      final trainings = await TrainingService.getTrainings();
      setState(() {
        _availableTrainings = trainings.reversed.toList();
        _isLoadingTrainings = false;
      });
    } catch (e) {
      setState(() => _isLoadingTrainings = false);
    }
  }

  Future<void> _loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString('card_config_apparence');
      if (configJson != null && configJson.isNotEmpty) {
        setState(() {
          _config = CardConfig.fromJson(json.decode(configJson));
          _isLoading = false;
        });
      } else {
        setState(() {
          _config = CardConfig.defaultConfig();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _config = CardConfig.defaultConfig();
        _isLoading = false;
      });
    }
  }

Future<void> _saveConfig() async {
  try {
    // Sauvegarder dans SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'card_config_apparence',
      json.encode(_config.toJson()),
    );
    
    // ✅ Mettre à jour le CardConfigManager (qui notifiera tous les widgets)
    final cardConfigManager = Provider.of<CardConfigManager>(context, listen: false);
    cardConfigManager.updateConfig(_config);

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
          _isArabic ? '❌ Erreur lors de la sauvegarde' : '❌ Erreur lors de la sauvegarde',
          style: GoogleFonts.cairo(),
        ),
        backgroundColor: Colors.red,
      ),
    );
  }
}


void _resetToDefault() {
  setState(() {
    _config = CardConfig.defaultConfig();
  });
  // ✅ Mettre à jour le provider
  final cardConfigManager = Provider.of<CardConfigManager>(context, listen: false);
  cardConfigManager.resetToDefault();
}

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return AdminPageWrapper(
      title: 'Apparence des cartes',
      titleAr: 'إعدادات مظهر البطاقة',
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
                    _buildPreviewSection(isMobile),
                    const SizedBox(height: 24),

                    // ✅ NOUVELLE SECTION : Paramètres d'affichage mobile
                    _buildMobileDisplaySettings(isMobile),

                    const SizedBox(height: 24),

                    _buildCardStyleSettings(isMobile),

                    const SizedBox(height: 24),

                    // Champs à afficher
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isMobile ? 16 : 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isArabic
                                  ? '📋 Champs à afficher'
                                  : '📋 Champs à afficher',
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
                              style: GoogleFonts.cairo(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  _availableFields.map((field) {
                                    final isVisible = _config.visibleFields
                                        .contains(field.id);
                                    return FilterChip(
                                      selected: isVisible,
                                      label: Text(
                                        _isArabic
                                            ? field.labelAr
                                            : field.labelFr,
                                        style: GoogleFonts.cairo(
                                          fontSize: 12,
                                          fontWeight:
                                              isVisible
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                        ),
                                      ),
                                      avatar: Icon(
                                        field.icon,
                                        size: 16,
                                        color:
                                            isVisible
                                                ? Colors.white
                                                : Colors.grey[600],
                                      ),
                                      selectedColor: const Color(0xff0D443E),
                                      backgroundColor: Colors.grey[100],
                                      checkmarkColor: Colors.white,
                                      onSelected: (selected) {
                                        setState(() {
                                          if (selected) {
                                            _config.visibleFields.add(field.id);
                                          } else {
                                            _config.visibleFields.remove(
                                              field.id,
                                            );
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Style du titre
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isMobile ? 16 : 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isArabic
                                  ? '📌 Style du titre'
                                  : '📌 Style du titre',
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xff0D443E),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildFontSelector(
                              label: _isArabic ? 'Police' : 'Police',
                              currentValue: _config.titleFontFamily,
                              onChanged: (value) {
                                setState(() {
                                  _config.titleFontFamily = value!;
                                });
                              },
                              isArabic: _isArabic,
                            ),
                            const SizedBox(height: 16),
                            _buildSizeSelector(
                              label: _isArabic ? 'Taille' : 'Taille',
                              currentValue: _config.titleFontSize,
                              onChanged: (value) {
                                setState(() {
                                  _config.titleFontSize = value!;
                                });
                              },
                              isArabic: _isArabic,
                              minValue: 8,
                              maxValue: 28,
                            ),
                            const SizedBox(height: 16),
                            _buildColorPicker(
                              label: _isArabic ? 'Couleur' : 'Couleur',
                              currentColor: _config.titleColor,
                              onChanged: (color) {
                                setState(() {
                                  _config.titleColor = color;
                                });
                              },
                              isArabic: _isArabic,
                            ),
                            const SizedBox(height: 8),
                            _buildWeightSelector(
                              label: _isArabic ? 'Épaisseur' : 'Épaisseur',
                              currentValue: _config.titleFontWeight,
                              onChanged: (value) {
                                setState(() {
                                  _config.titleFontWeight = value;
                                });
                              },
                              isArabic: _isArabic,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Style des libellés
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isMobile ? 16 : 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isArabic
                                  ? '🎨 Style des libellés'
                                  : '🎨 Style des libellés',
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xff0D443E),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildFontSelector(
                              label: _isArabic ? 'Police' : 'Police',
                              currentValue: _config.labelFontFamily,
                              onChanged: (value) {
                                setState(() {
                                  _config.labelFontFamily = value!;
                                });
                              },
                              isArabic: _isArabic,
                            ),
                            const SizedBox(height: 16),
                            _buildSizeSelector(
                              label: _isArabic ? 'Taille' : 'Taille',
                              currentValue: _config.labelFontSize,
                              onChanged: (value) {
                                setState(() {
                                  _config.labelFontSize = value!;
                                });
                              },
                              isArabic: _isArabic,
                              minValue: 6,
                              maxValue: 18,
                            ),
                            const SizedBox(height: 16),
                            _buildColorPicker(
                              label: _isArabic ? 'Couleur' : 'Couleur',
                              currentColor: _config.labelColor,
                              onChanged: (color) {
                                setState(() {
                                  _config.labelColor = color;
                                });
                              },
                              isArabic: _isArabic,
                            ),
                            const SizedBox(height: 8),
                            _buildWeightSelector(
                              label: _isArabic ? 'Épaisseur' : 'Épaisseur',
                              currentValue: _config.labelFontWeight,
                              onChanged: (value) {
                                setState(() {
                                  _config.labelFontWeight = value;
                                });
                              },
                              isArabic: _isArabic,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Style des valeurs
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isMobile ? 16 : 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isArabic
                                  ? '📝 Style des valeurs'
                                  : '📝 Style des valeurs',
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xff0D443E),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildFontSelector(
                              label: _isArabic ? 'Police' : 'Police',
                              currentValue: _config.valueFontFamily,
                              onChanged: (value) {
                                setState(() {
                                  _config.valueFontFamily = value!;
                                });
                              },
                              isArabic: _isArabic,
                            ),
                            const SizedBox(height: 16),
                            _buildSizeSelector(
                              label: _isArabic ? 'Taille' : 'Taille',
                              currentValue: _config.valueFontSize,
                              onChanged: (value) {
                                setState(() {
                                  _config.valueFontSize = value!;
                                });
                              },
                              isArabic: _isArabic,
                              minValue: 6,
                              maxValue: 18,
                            ),
                            const SizedBox(height: 16),
                            _buildColorPicker(
                              label: _isArabic ? 'Couleur' : 'Couleur',
                              currentColor: _config.valueColor,
                              onChanged: (color) {
                                setState(() {
                                  _config.valueColor = color;
                                });
                              },
                              isArabic: _isArabic,
                            ),
                            const SizedBox(height: 8),
                            _buildWeightSelector(
                              label: _isArabic ? 'Épaisseur' : 'Épaisseur',
                              currentValue: _config.valueFontWeight,
                              onChanged: (value) {
                                setState(() {
                                  _config.valueFontWeight = value;
                                });
                              },
                              isArabic: _isArabic,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Boutons
                    Row(
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
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
    );
  }

  // ✅ NOUVELLE SECTION : Paramètres d'affichage mobile
  Widget _buildCardStyleSettings(bool isMobile) {
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
            const SizedBox(height: 6),
            Text(
              _isArabic
                  ? 'ألوان، حدود، زوايا وظل البطاقة'
                  : 'Couleurs, bordure, arrondi et profondeur.',
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 18),
            _buildColorPicker(
              label: _isArabic ? 'لون الخلفية' : 'Fond de carte',
              currentColor: _config.cardBackgroundColor,
              onChanged: (color) {
                setState(() => _config.cardBackgroundColor = color);
              },
              isArabic: _isArabic,
            ),
            const SizedBox(height: 14),
            _buildColorPicker(
              label: _isArabic ? 'لون الحدود' : 'Couleur de bordure',
              currentColor: _config.cardBorderColor,
              onChanged: (color) {
                setState(() => _config.cardBorderColor = color);
              },
              isArabic: _isArabic,
            ),
            const SizedBox(height: 14),
            _buildColorPicker(
              label: _isArabic ? 'لون التمييز' : 'Couleur d’accent',
              currentColor: _config.accentColor,
              onChanged: (color) {
                setState(() => _config.accentColor = color);
              },
              isArabic: _isArabic,
            ),
            const SizedBox(height: 16),
            _buildNumberSlider(
              label: _isArabic ? 'تقويس الزوايا' : 'Arrondi',
              value: _config.cardBorderRadius,
              minValue: 0,
              maxValue: 36,
              onChanged: (value) {
                setState(() => _config.cardBorderRadius = value);
              },
            ),
            const SizedBox(height: 12),
            _buildNumberSlider(
              label: _isArabic ? 'قوة الظل' : 'Intensité de l’ombre',
              value: _config.cardShadowStrength * 100,
              minValue: 0,
              maxValue: 25,
              onChanged: (value) {
                setState(() => _config.cardShadowStrength = value / 100);
              },
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _stylePresetChip(
                  'Minimal',
                  Colors.white,
                  const Color(0xffE5E7EB),
                  const Color(0xff0D443E),
                  12,
                  0.03,
                ),
                _stylePresetChip(
                  'Nafahat',
                  Colors.white,
                  const Color(0xffE7E1DD),
                  const Color(0xffD57653),
                  16,
                  0.08,
                ),
                _stylePresetChip(
                  'Soft',
                  const Color(0xffFFF8F5),
                  const Color(0xffF0D6CB),
                  const Color(0xff994A2B),
                  22,
                  0.10,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stylePresetChip(
    String label,
    Color background,
    Color border,
    Color accent,
    double radius,
    double shadow,
  ) {
    return ActionChip(
      avatar: CircleAvatar(backgroundColor: accent, radius: 7),
      label: Text(label, style: GoogleFonts.cairo(fontSize: 12)),
      onPressed: () {
        setState(() {
          _config.cardBackgroundColor = background;
          _config.cardBorderColor = border;
          _config.accentColor = accent;
          _config.cardBorderRadius = radius;
          _config.cardShadowStrength = shadow;
        });
      },
    );
  }

  Widget _buildNumberSlider({
    required String label,
    required double value,
    required double minValue,
    required double maxValue,
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
          width: 230,
          child: Slider(
            value: value.clamp(minValue, maxValue).toDouble(),
            min: minValue,
            max: maxValue,
            divisions: (maxValue - minValue).round(),
            label: value.toStringAsFixed(value < 1 ? 2 : 0),
            activeColor: const Color(0xff0D443E),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            value.toStringAsFixed(value < 1 ? 2 : 0),
            textAlign: TextAlign.end,
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

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
                  ? 'Configurez l\'affichage des formations sur la page d\'accueil (version mobile)'
                  : 'Configurez l\'affichage des formations sur la page d\'accueil (version mobile)',
              style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Nombre de cartes à afficher
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
                                if (_config.mobileSelectedTrainings.length >
                                    value) {
                                  _config.mobileSelectedTrainings = _config
                                      .mobileSelectedTrainings
                                      .sublist(0, value);
                                }
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

            const SizedBox(height: 20),

            // Sélection des cartes à afficher
            if (_config.mobileDisplayCount > 0) ...[
              Text(
                _isArabic
                    ? 'Sélectionnez les cartes à afficher (${_config.mobileSelectedTrainings.length}/${_config.mobileDisplayCount})'
                    : 'Sélectionnez les cartes à afficher (${_config.mobileSelectedTrainings.length}/${_config.mobileDisplayCount})',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isArabic
                    ? 'Choisissez les formations à afficher sur la page d\'accueil en version mobile'
                    : 'Choisissez les formations à afficher sur la page d\'accueil en version mobile',
                style: GoogleFonts.cairo(color: Colors.grey[500], fontSize: 12),
              ),
              const SizedBox(height: 12),

              if (_isLoadingTrainings)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_availableTrainings.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      _isArabic
                          ? 'Aucune formation disponible'
                          : 'Aucune formation disponible',
                      style: GoogleFonts.cairo(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  constraints: BoxConstraints(maxHeight: isMobile ? 300 : 400),
                  child: _buildTrainingSelectionList(isMobile),
                ),

              const SizedBox(height: 12),

              // Boutons d'action pour la sélection
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _config.mobileSelectedTrainings = [];
                        });
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.red[300]!),
                        ),
                      ),
                      child: Text(
                        _isArabic
                            ? 'Effacer la sélection'
                            : 'Effacer la sélection',
                        style: GoogleFonts.cairo(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          final limit = _config.mobileDisplayCount;
                          _config.mobileSelectedTrainings =
                              _availableTrainings
                                  .take(limit)
                                  .map((t) => t.id)
                                  .toList();
                        });
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xff0D443E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: const Color(0xff0D443E)),
                        ),
                      ),
                      child: Text(
                        _isArabic
                            ? 'Sélectionner les ${_config.mobileDisplayCount} premières'
                            : 'Sélectionner les ${_config.mobileDisplayCount} premières',
                        style: GoogleFonts.cairo(),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Aperçu de la sélection
            if (_config.mobileSelectedTrainings.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xff0D443E).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xff0D443E).withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xff0D443E),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isArabic
                            ? '${_config.mobileSelectedTrainings.length} formation(s) sélectionnée(s) sur ${_availableTrainings.length} disponible(s)'
                            : '${_config.mobileSelectedTrainings.length} formation(s) sélectionnée(s) sur ${_availableTrainings.length} disponible(s)',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: const Color(0xff0D443E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ✅ Widget pour la liste de sélection des formations
  Widget _buildTrainingSelectionList(bool isMobile) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      itemCount: _availableTrainings.length,
      itemBuilder: (context, index) {
        final training = _availableTrainings[index];
        final isSelected = _config.mobileSelectedTrainings.contains(
          training.id,
        );
        final isDisabled =
            !isSelected &&
            _config.mobileSelectedTrainings.length >=
                _config.mobileDisplayCount;

        return CheckboxListTile(
          value: isSelected,
          onChanged:
              isDisabled && !isSelected
                  ? null
                  : (value) {
                    setState(() {
                      if (value == true) {
                        if (_config.mobileSelectedTrainings.length <
                            _config.mobileDisplayCount) {
                          _config.mobileSelectedTrainings.add(training.id);
                        }
                      } else {
                        _config.mobileSelectedTrainings.remove(training.id);
                      }
                    });
                  },
          title: Text(
            _isArabic ? training.titleAr : training.titleFr,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: isDisabled && !isSelected ? Colors.grey[400] : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            _isArabic ? training.categorieAr : training.categorieFr,
            style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[500]),
          ),
          secondary: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(training.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          selected: isSelected,
          selectedTileColor: const Color(0xff0D443E).withOpacity(0.08),
          activeColor: const Color(0xff0D443E),
          checkboxShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }

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
                        _config.cardShadowStrength.clamp(0.0, 0.30).toDouble(),
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
                        'https://picsum.photos/seed/preview/400/200',
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
                          if (_config.visibleFields.contains('title'))
                            Text(
                              _isArabic
                                  ? _previewTraining.titleAr
                                  : _previewTraining.titleFr,
                              style: _getFontWithFamily(
                                _config.titleFontFamily,
                                _config.titleFontSize,
                                _config.titleFontWeight,
                                _config.titleColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 6),
                          if (_config.visibleFields.contains('trainer'))
                            _buildPreviewInfoRow(
                              Icons.person,
                              _isArabic ? 'المكون : ' : 'Formateur : ',
                              _previewTraining.trainer,
                            ),
                          if (_config.visibleFields.contains('duration'))
                            _buildPreviewInfoRow(
                              Icons.access_time,
                              _isArabic ? 'المدة : ' : 'Durée : ',
                              _previewTraining.typeDuree,
                            ),
                          if (_config.visibleFields.contains('period'))
                            _buildPreviewInfoRow(
                              Icons.calendar_today,
                              _isArabic ? 'الفترة : ' : 'Période : ',
                              _previewTraining.period,
                            ),
                          if (_config.visibleFields.contains('target'))
                            _buildPreviewInfoRow(
                              Icons.people,
                              _isArabic ? 'الجمهور : ' : 'Cible : ',
                              _previewTraining.target,
                            ),
                          if (_config.visibleFields.contains('type'))
                            _buildPreviewInfoRow(
                              Icons.school,
                              _isArabic ? 'النوع : ' : 'Type : ',
                              _previewTraining.typeFormation,
                            ),
                          if (_config.visibleFields.contains('category'))
                            _buildPreviewInfoRow(
                              Icons.category,
                              _isArabic ? 'التصنيف : ' : 'Catégorie : ',
                              _isArabic
                                  ? _previewTraining.categorieAr
                                  : _previewTraining.categorieFr,
                            ),
                          if (_config.visibleFields.contains('price') ||
                              _config.visibleFields.contains('discount'))
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (_config.visibleFields.contains(
                                      'discount',
                                    ) &&
                                    _previewTraining.hasDiscount)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _isArabic
                                          ? '-${_previewTraining.discountValue?.toInt() ?? 0}%'
                                          : '-${_previewTraining.discountValue?.toInt() ?? 0}%',
                                      style: GoogleFonts.cairo(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                if (_config.visibleFields.contains('price'))
                                  Row(
                                    children: [
                                      if (_previewTraining.hasDiscount)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            right: 4,
                                          ),
                                          child: Text(
                                            '${_previewTraining.price.toInt()} DH',
                                            style: GoogleFonts.cairo(
                                              fontSize: 10,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ),
                                      Text(
                                        '${_previewTraining.finalPrice.toInt()} DH',
                                        style: GoogleFonts.cairo(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: _config.accentColor,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
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

  Widget _buildPreviewInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Icon(icon, size: 12, color: _config.labelColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: _getFontWithFamily(
              _config.labelFontFamily,
              _config.labelFontSize,
              _config.labelFontWeight,
              _config.labelColor,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: _getFontWithFamily(
                _config.valueFontFamily,
                _config.valueFontSize,
                _config.valueFontWeight,
                _config.valueColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

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
