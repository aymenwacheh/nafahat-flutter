// lib/pages/adminisration/apparence_card.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafahat/models/training_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nafahat/services/card_config_manager.dart';
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

  // Prévisualisation
  TrainingModel _previewTraining = TrainingModel(
    id: 'preview',
    titleFr: 'Formation Flutter Avancé',
    titleAr: 'دورة فلاتر المتقدمة',
    descriptionFr: 'Maîtrisez Flutter avec des projets concrets',
    descriptionAr: 'إتقان فلاتر من خلال مشاريع عملية',
    price: 15000,
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'card_config_apparence',
        json.encode(_config.toJson()),
      );
      CardConfigManager().updateConfig(_config);

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
      _config = CardConfig.defaultConfig();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text(
          _isArabic ? 'إعدادات مظهر البطاقة' : 'Apparence des cartes',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xff0D443E),
        foregroundColor: Colors.white,
        elevation: 0,
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
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 12 : 24),
                child: Column(
                  children: [
                    _buildPreviewSection(isMobile),
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
                              minValue: 10,
                              maxValue: 22,
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
                              minValue: 8,
                              maxValue: 16,
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
                              minValue: 8,
                              maxValue: 16,
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
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
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
                          // Titre avec style titre
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

                          // Champs avec style libellé/valeur
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

                          // Prix et réduction
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
                                          color: const Color(0xffd57653),
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

  // ✅ Fonction utilitaire pour extraire le nom de la famille
  String _extractFontFamily(String fontWithVariant) {
    if (fontWithVariant.contains('-')) {
      return fontWithVariant.split('-').first;
    }
    return fontWithVariant;
  }

  // ✅ Fonction utilitaire pour obtenir le style avec GoogleFonts
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
    final colors = [
      Colors.black,
      Colors.grey[800]!,
      Colors.grey[600]!,
      const Color(0xff0D443E),
      const Color(0xffd57653),
      Colors.blue[700]!,
      Colors.red[700]!,
      Colors.green[700]!,
      Colors.purple[700]!,
      Colors.orange[700]!,
    ];

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
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              colors.map((color) {
                final isSelected = currentColor == color;
                return GestureDetector(
                  onTap: () => onChanged(color),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isSelected
                                ? const Color(0xff0D443E)
                                : Colors.grey[300]!,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child:
                        isSelected
                            ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            )
                            : null,
                  ),
                );
              }).toList(),
        ),
      ],
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

// ============================================
// MODÈLE DE CONFIGURATION
// ============================================

class CardConfig {
  List<String> visibleFields;

  // Style des libellés
  String labelFontFamily;
  double labelFontSize;
  FontWeight labelFontWeight;
  Color labelColor;

  // Style des valeurs
  String valueFontFamily;
  double valueFontSize;
  FontWeight valueFontWeight;
  Color valueColor;

  // Style du titre
  String titleFontFamily;
  double titleFontSize;
  FontWeight titleFontWeight;
  Color titleColor;

  CardConfig({
    required this.visibleFields,
    required this.labelFontFamily,
    required this.labelFontSize,
    required this.labelFontWeight,
    required this.labelColor,
    required this.valueFontFamily,
    required this.valueFontSize,
    required this.valueFontWeight,
    required this.valueColor,
    required this.titleFontFamily,
    required this.titleFontSize,
    required this.titleFontWeight,
    required this.titleColor,
  });

  factory CardConfig.defaultConfig() {
    return CardConfig(
      visibleFields: [
        'title',
        'trainer',
        'duration',
        'period',
        'price',
        'discount',
      ],
      labelFontFamily: 'Cairo-Regular', // ✅ Variante Regular
      labelFontSize: 10,
      labelFontWeight: FontWeight.w600,
      labelColor: Colors.grey[600]!,
      valueFontFamily: 'Cairo-Regular', // ✅ Variante Regular
      valueFontSize: 10,
      valueFontWeight: FontWeight.w500,
      valueColor: Colors.black,
      titleFontFamily: 'Cairo-Bold', // ✅ Variante Bold
      titleFontSize: 14,
      titleFontWeight: FontWeight.bold,
      titleColor: const Color(0xff2c221e),
    );
  }

  factory CardConfig.fromJson(Map<String, dynamic> json) {
    return CardConfig(
      visibleFields: List<String>.from(json['visibleFields'] ?? []),
      labelFontFamily: json['labelFontFamily'] ?? 'Cairo-Regular',
      labelFontSize: (json['labelFontSize'] ?? 10).toDouble(),
      labelFontWeight: _getFontWeight(json['labelFontWeight'] ?? 600),
      labelColor: _getColor(json['labelColor'] ?? '#616161'),
      valueFontFamily: json['valueFontFamily'] ?? 'Cairo-Regular',
      valueFontSize: (json['valueFontSize'] ?? 10).toDouble(),
      valueFontWeight: _getFontWeight(json['valueFontWeight'] ?? 500),
      valueColor: _getColor(json['valueColor'] ?? '#000000'),
      titleFontFamily: json['titleFontFamily'] ?? 'Cairo-Bold',
      titleFontSize: (json['titleFontSize'] ?? 14).toDouble(),
      titleFontWeight: _getFontWeight(json['titleFontWeight'] ?? 700),
      titleColor: _getColor(json['titleColor'] ?? '#2c221e'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'visibleFields': visibleFields,
      'labelFontFamily': labelFontFamily,
      'labelFontSize': labelFontSize,
      'labelFontWeight': labelFontWeight.index,
      'labelColor': _colorToString(labelColor),
      'valueFontFamily': valueFontFamily,
      'valueFontSize': valueFontSize,
      'valueFontWeight': valueFontWeight.index,
      'valueColor': _colorToString(valueColor),
      'titleFontFamily': titleFontFamily,
      'titleFontSize': titleFontSize,
      'titleFontWeight': titleFontWeight.index,
      'titleColor': _colorToString(titleColor),
    };
  }

  static FontWeight _getFontWeight(int value) {
    return FontWeight.values.firstWhere(
      (w) => w.index == value,
      orElse: () => FontWeight.w400,
    );
  }

  static Color _getColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xff')));
    } catch (e) {
      return Colors.black;
    }
  }

  static String _colorToString(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  // Méthodes utilitaires
  TextStyle getTitleStyle() {
    final family = _extractFontFamily(titleFontFamily);
    return GoogleFonts.getFont(
      family,
      fontSize: titleFontSize,
      fontWeight: titleFontWeight,
      color: titleColor,
    );
  }

  TextStyle getLabelStyle() {
    final family = _extractFontFamily(labelFontFamily);
    return GoogleFonts.getFont(
      family,
      fontSize: labelFontSize,
      fontWeight: labelFontWeight,
      color: labelColor,
    );
  }

  TextStyle getValueStyle() {
    final family = _extractFontFamily(valueFontFamily);
    return GoogleFonts.getFont(
      family,
      fontSize: valueFontSize,
      fontWeight: valueFontWeight,
      color: valueColor,
    );
  }

  static String _extractFontFamily(String fontWithVariant) {
    if (fontWithVariant.contains('-')) {
      return fontWithVariant.split('-').first;
    }
    return fontWithVariant;
  }
}

class CardFieldOption {
  final String id;
  final String labelFr;
  final String labelAr;
  final IconData icon;
  final bool defaultVisible;

  CardFieldOption({
    required this.id,
    required this.labelFr,
    required this.labelAr,
    required this.icon,
    this.defaultVisible = false,
  });
}
