// lib/pages/adminisration/add_training_card.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:nafahat/services/training_service.dart';

class AddTrainingCardPage extends StatefulWidget {
  const AddTrainingCardPage({super.key});

  @override
  State<AddTrainingCardPage> createState() => _AddTrainingCardPageState();
}

class _AddTrainingCardPageState extends State<AddTrainingCardPage> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs principaux
  final _titleFrController = TextEditingController();
  final _titleArController = TextEditingController();
  final _descriptionFrController = TextEditingController();
  final _descriptionArController = TextEditingController();
  final _targetController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountValueController = TextEditingController();
  final TextEditingController _dateDebutController = TextEditingController();
  final TextEditingController _dateFinController = TextEditingController();
  final TextEditingController _nbrHeurController = TextEditingController();
  final TextEditingController _nbrSeanceController = TextEditingController();
  final TextEditingController _nbrJourController = TextEditingController();

  bool _isLoading = false;
  bool _hasDiscount = false;
  bool _isPercentageDiscount = true;
  bool _isArabic = false;
  bool _isRepetitive = false;

  // Sélections
  int? _selectedTypeFormationId;
  int? _selectedDureeId;
  int? _selectedCategorieId;
  int? _selectedSousCategorieId;
  int? _selectedFormateurId;

  // Jours de la semaine
  final Map<String, bool> _joursSemaine = {
    'lundi': false,
    'mardi': false,
    'mercredi': false,
    'jeudi': false,
    'vendredi': false,
    'samedi': false,
    'dimanche': false,
  };

  // Listes
  List<Map<String, dynamic>> _typesFormation = [];
  List<Map<String, dynamic>> _durees = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _allSousCategories = [];
  List<Map<String, dynamic>> _filteredSousCategories = [];
  List<Map<String, dynamic>> _formateurs = [];

  static const Color nafahatGreen = Color(0xff0D443E);
  static const Color nafahatOrange = Color(0xffd57653);
  static const Color nafahatGold = Color(0xffC4A46C);

  // Couleurs constantes pour éviter les erreurs
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);

  final Map<String, String> _joursFr = {
    'lundi': 'Lundi',
    'mardi': 'Mardi',
    'mercredi': 'Mercredi',
    'jeudi': 'Jeudi',
    'vendredi': 'Vendredi',
    'samedi': 'Samedi',
    'dimanche': 'Dimanche',
  };

  final Map<String, String> _joursAr = {
    'lundi': 'الإثنين',
    'mardi': 'الثلاثاء',
    'mercredi': 'الأربعاء',
    'jeudi': 'الخميس',
    'vendredi': 'الجمعة',
    'samedi': 'السبت',
    'dimanche': 'الأحد',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final types = await TrainingService.getTypesFormation();
      final durees = await TrainingService.getDurees();
      final categories = await TrainingService.getCategories();
      final formateurs = await TrainingService.getFormateurs();
      final sousCategories = await _loadSousCategories();

      setState(() {
        _typesFormation = types;
        _durees = durees;
        _categories = categories;
        _formateurs = formateurs;
        _allSousCategories = sousCategories;
        _filteredSousCategories = [];
      });
    } catch (e) {
      print('❌ Erreur chargement données: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _loadSousCategories() async {
    try {
      final response = await http.get(
        Uri.parse('${TrainingService.apiBaseUrl}/categories/sous-categories'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      print('Erreur chargement sous-catégories: $e');
      return [];
    }
  }

  void _onCategorieChanged(dynamic value) {
    setState(() {
      _selectedCategorieId = value as int?;
      _selectedSousCategorieId = null;
      if (_selectedCategorieId != null) {
        _filteredSousCategories =
            _allSousCategories
                .where((sc) => sc['id_categorie'] == _selectedCategorieId)
                .toList();
      } else {
        _filteredSousCategories = [];
      }
    });
  }

  @override
  void dispose() {
    _titleFrController.dispose();
    _titleArController.dispose();
    _descriptionFrController.dispose();
    _descriptionArController.dispose();
    _targetController.dispose();
    _imageUrlController.dispose();
    _priceController.dispose();
    _discountValueController.dispose();
    _dateDebutController.dispose();
    _dateFinController.dispose();
    _nbrHeurController.dispose();
    _nbrSeanceController.dispose();
    _nbrJourController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final locale =
        _isArabic ? const Locale('ar', 'AR') : const Locale('fr', 'FR');

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: locale,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: nafahatGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.toLocal().toString().split(' ')[0];
      });
    }
  }

  String _getSelectedJours() {
    final selected =
        _joursSemaine.entries.where((e) => e.value).map((e) => e.key).toList();
    return jsonEncode(selected);
  }

  Future<void> _saveTraining() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final requestBody = {
        'titre_fr': _titleFrController.text,
        'titre_ar': _titleArController.text,
        'id_type_formation': _selectedTypeFormationId,
        'cible_fr': _targetController.text,
        'cible_ar': _targetController.text,
        'id_duree': _selectedDureeId,
        'date_debut':
            _dateDebutController.text.isNotEmpty
                ? _dateDebutController.text
                : null,
        'date_fin':
            _dateFinController.text.isNotEmpty ? _dateFinController.text : null,
        'prix': double.parse(_priceController.text),
        'discount': _hasDiscount ? 'oui' : 'non',
        'valeur_disc':
            _hasDiscount ? double.parse(_discountValueController.text) : null,
        'descri_fr': _descriptionFrController.text,
        'descri_ar': _descriptionArController.text,
        'id_categorie': _selectedCategorieId,
        'sous_categorie_id': _selectedSousCategorieId,
        'id_formateur': _selectedFormateurId,
        'photo':
            _imageUrlController.text.isNotEmpty
                ? _imageUrlController.text
                : null,
        'nbr_heur':
            _nbrHeurController.text.isNotEmpty
                ? int.parse(_nbrHeurController.text)
                : null,
        'nbr_seance':
            _nbrSeanceController.text.isNotEmpty
                ? int.parse(_nbrSeanceController.text)
                : null,
        'nbr_jour':
            _nbrJourController.text.isNotEmpty
                ? int.parse(_nbrJourController.text)
                : null,
        'repetitive': _isRepetitive ? 'oui' : 'non',
        'jour_semaine': _isRepetitive ? _getSelectedJours() : null,
      };

      try {
        final success = await TrainingService.createTraining(requestBody);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isArabic
                    ? '✅ تمت إضافة التكوين "${_titleArController.text}" بنجاح!'
                    : '✅ Formation "${_titleFrController.text}" ajoutée avec succès!',
              ),
              backgroundColor: nafahatGreen,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isArabic
                    ? '❌ خطأ في إضافة التكوين'
                    : '❌ Erreur lors de l\'ajout',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isArabic ? '❌ خطأ في الاتصال' : '❌ Erreur de connexion',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _selectedTypeFormationId = null;
      _selectedDureeId = null;
      _selectedCategorieId = null;
      _selectedSousCategorieId = null;
      _selectedFormateurId = null;
      _dateDebutController.clear();
      _dateFinController.clear();
      _hasDiscount = false;
      _isPercentageDiscount = true;
      _isRepetitive = false;
      _filteredSousCategories = [];
      _nbrHeurController.clear();
      _nbrSeanceController.clear();
      _nbrJourController.clear();
      _joursSemaine.updateAll((key, value) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: grey50,
      appBar: AppBar(
        title: Text(
          _isArabic ? 'إضافة تكوين' : 'Ajouter une formation',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: nafahatGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.language),
              onPressed: () => setState(() => _isArabic = !_isArabic),
              tooltip: _isArabic ? 'Français' : 'العربية',
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 24,
          vertical: 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ========== HEADER ==========
              _buildHeader(),
              const SizedBox(height: 24),

              // ========== CARD PRINCIPAL ==========
              Card(
                elevation: 4,
                shadowColor: nafahatGreen.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  child: Column(
                    children: [
                      // --- SECTION 1: Informations de base ---
                      _buildSection(
                        icon: Icons.info_outline,
                        title:
                            _isArabic
                                ? 'معلومات أساسية'
                                : 'Informations de base',
                        children: [
                          _buildField(
                            label:
                                _isArabic
                                    ? 'العنوان (بالفرنسية) *'
                                    : 'Titre (Français) *',
                            controller: _titleFrController,
                            hint:
                                _isArabic
                                    ? 'مثال: Formation Flutter avancé'
                                    : 'Ex: Formation Flutter avancé',
                            required: true,
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            label:
                                _isArabic
                                    ? 'العنوان (بالعربية) *'
                                    : 'Titre (Arabe) *',
                            controller: _titleArController,
                            hint:
                                _isArabic
                                    ? 'مثال: دورة فلاتر المتقدمة'
                                    : 'Ex: دورة فلاتر المتقدمة',
                            required: true,
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdownField(
                                  label:
                                      _isArabic
                                          ? 'نوع التكوين *'
                                          : 'Type de formation *',
                                  value: _selectedTypeFormationId,
                                  items:
                                      _typesFormation.map((t) {
                                        return DropdownMenuItem<int>(
                                          value: t['id'],
                                          child: Text(
                                            t['type_formation'] ?? '',
                                          ),
                                        );
                                      }).toList(),
                                  onChanged:
                                      (value) => setState(
                                        () =>
                                            _selectedTypeFormationId =
                                                value as int?,
                                      ),
                                  required: true,
                                  isArabic: _isArabic,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildDropdownField(
                                  label: _isArabic ? 'المدة *' : 'Durée *',
                                  value: _selectedDureeId,
                                  items:
                                      _durees.map((d) {
                                        return DropdownMenuItem<int>(
                                          value: d['id'],
                                          child: Text(d['type_duree'] ?? ''),
                                        );
                                      }).toList(),
                                  onChanged:
                                      (value) => setState(
                                        () => _selectedDureeId = value as int?,
                                      ),
                                  required: true,
                                  isArabic: _isArabic,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const Divider(height: 32, color: grey200),

                      // --- SECTION 2: Catégories ---
                      _buildSection(
                        icon: Icons.category_outlined,
                        title: _isArabic ? 'التصنيفات' : 'Catégories',
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdownField(
                                  label: _isArabic ? 'التصنيف' : 'Catégorie',
                                  value: _selectedCategorieId,
                                  items: [
                                    const DropdownMenuItem<int>(
                                      value: null,
                                      child: Text('---'),
                                    ),
                                    ..._categories.map((c) {
                                      final label =
                                          _isArabic
                                              ? c['categorie_ar']
                                              : c['categorie_fr'];
                                      return DropdownMenuItem<int>(
                                        value: c['id'],
                                        child: Text(label ?? ''),
                                      );
                                    }),
                                  ],
                                  onChanged: _onCategorieChanged,
                                  required: false,
                                  isArabic: _isArabic,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildDropdownField(
                                  label:
                                      _isArabic
                                          ? 'التصنيف الفرعي'
                                          : 'Sous-catégorie',
                                  value: _selectedSousCategorieId,
                                  items: [
                                    const DropdownMenuItem<int>(
                                      value: null,
                                      child: Text('---'),
                                    ),
                                    ..._filteredSousCategories.map((sc) {
                                      final label =
                                          _isArabic
                                              ? sc['nom_ar']
                                              : sc['nom_fr'];
                                      return DropdownMenuItem<int>(
                                        value: sc['id'],
                                        child: Text(label ?? ''),
                                      );
                                    }),
                                  ],
                                  onChanged:
                                      (value) => setState(
                                        () =>
                                            _selectedSousCategorieId =
                                                value as int?,
                                      ),
                                  required: false,
                                  isArabic: _isArabic,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildDropdownField(
                            label: _isArabic ? 'المكون' : 'Formateur',
                            value: _selectedFormateurId,
                            items: [
                              const DropdownMenuItem<int>(
                                value: null,
                                child: Text('---'),
                              ),
                              ..._formateurs.map((f) {
                                final label =
                                    _isArabic
                                        ? f['nom_prenom_ar']
                                        : f['nom_prenom_fr'];
                                return DropdownMenuItem<int>(
                                  value: f['id'],
                                  child: Text(label ?? ''),
                                );
                              }),
                            ],
                            onChanged:
                                (value) => setState(
                                  () => _selectedFormateurId = value as int?,
                                ),
                            required: false,
                            isArabic: _isArabic,
                          ),
                        ],
                      ),

                      const Divider(height: 32, color: grey200),

                      // --- SECTION 3: Détails de la durée ---
                      _buildSection(
                        icon: Icons.timer_outlined,
                        title:
                            _isArabic ? 'تفاصيل المدة' : 'Détails de la durée',
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildField(
                                  label: _isArabic ? 'Heures' : 'Heures',
                                  controller: _nbrHeurController,
                                  hint: _isArabic ? 'مثال: 20' : 'Ex: 20',
                                  keyboardType: TextInputType.number,
                                  prefixIcon: Icons.access_time_rounded,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildField(
                                  label: _isArabic ? 'Séances' : 'Séances',
                                  controller: _nbrSeanceController,
                                  hint: _isArabic ? 'مثال: 10' : 'Ex: 10',
                                  keyboardType: TextInputType.number,
                                  prefixIcon: Icons.people_outline_rounded,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildField(
                                  label: _isArabic ? 'Jours' : 'Jours',
                                  controller: _nbrJourController,
                                  hint: _isArabic ? 'مثال: 5' : 'Ex: 5',
                                  keyboardType: TextInputType.number,
                                  prefixIcon: Icons.calendar_today_rounded,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const Divider(height: 32, color: grey200),

                      // --- SECTION 4: Répétition ---
                      _buildSection(
                        icon: Icons.repeat_rounded,
                        title: _isArabic ? 'التكرار' : 'Répétition',
                        children: [_buildRepetitiveSection()],
                      ),

                      const Divider(height: 32, color: grey200),

                      // --- SECTION 5: Période ---
                      _buildSection(
                        icon: Icons.calendar_month_rounded,
                        title: _isArabic ? 'الفترة' : 'Période',
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildDateField(
                                  label:
                                      _isArabic
                                          ? 'تاريخ البداية *'
                                          : 'Date de début *',
                                  controller: _dateDebutController,
                                  onTap:
                                      () => _selectDate(_dateDebutController),
                                  required: true,
                                  isArabic: _isArabic,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildDateField(
                                  label:
                                      _isArabic
                                          ? 'تاريخ النهاية *'
                                          : 'Date de fin *',
                                  controller: _dateFinController,
                                  onTap: () => _selectDate(_dateFinController),
                                  required: true,
                                  isArabic: _isArabic,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const Divider(height: 32, color: grey200),

                      // --- SECTION 6: Description ---
                      _buildSection(
                        icon: Icons.description_outlined,
                        title: _isArabic ? 'الوصف' : 'Description',
                        children: [
                          _buildField(
                            label:
                                _isArabic
                                    ? 'الوصف (بالفرنسية) *'
                                    : 'Description (Français) *',
                            controller: _descriptionFrController,
                            hint:
                                _isArabic
                                    ? 'وصف تفصيلي'
                                    : 'Description détaillée',
                            required: true,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            label:
                                _isArabic
                                    ? 'الوصف (بالعربية) *'
                                    : 'Description (Arabe) *',
                            controller: _descriptionArController,
                            hint:
                                _isArabic
                                    ? 'وصف تفصيلي'
                                    : 'Description détaillée',
                            required: true,
                            maxLines: 3,
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),

                      const Divider(height: 32, color: grey200),

                      // --- SECTION 7: Prix et Cible ---
                      _buildSection(
                        icon: Icons.payments_outlined,
                        title: _isArabic ? 'السعر والجمهور' : 'Prix et Cible',
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildField(
                                  label:
                                      _isArabic
                                          ? 'الجمهور المستهدف *'
                                          : 'Cible *',
                                  controller: _targetController,
                                  hint:
                                      _isArabic
                                          ? 'مثال: Débutants'
                                          : 'Ex: Débutants',
                                  required: true,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildField(
                                  label:
                                      _isArabic
                                          ? 'السعر (درهم) *'
                                          : 'Prix (DH) *',
                                  controller: _priceController,
                                  hint: _isArabic ? 'مثال: 15000' : 'Ex: 15000',
                                  required: true,
                                  keyboardType: TextInputType.number,
                                  prefixIcon: Icons.money_rounded,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildDiscountSection(),
                        ],
                      ),

                      const Divider(height: 32, color: grey200),

                      // --- SECTION 8: Image ---
                      _buildSection(
                        icon: Icons.image_outlined,
                        title: _isArabic ? 'الصورة' : 'Image',
                        children: [
                          _buildField(
                            label:
                                _isArabic ? 'رابط الصورة' : 'URL de l\'image',
                            controller: _imageUrlController,
                            hint:
                                'https://... (${_isArabic ? 'اختياري' : 'optionnel'})',
                            prefixIcon: Icons.link_rounded,
                          ),
                          if (_imageUrlController.text.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _imageUrlController.text,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 150,
                                    color: grey200,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.broken_image,
                                            color: grey400,
                                            size: 40,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _isArabic
                                                ? '❌ صورة غير صالحة'
                                                : '❌ Image invalide',
                                            style: GoogleFonts.cairo(
                                              color: grey600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ========== BOUTONS ==========
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _resetForm,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: nafahatGreen,
                        side: BorderSide(color: nafahatGreen),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            size: 18,
                            color: nafahatGreen,
                          ),
                          const SizedBox(width: 8),
                          Text(_isArabic ? 'إعادة تعيين' : 'Réinitialiser'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveTraining,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: nafahatGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                        shadowColor: nafahatGreen.withOpacity(0.3),
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_rounded, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isArabic
                                        ? 'إضافة التكوين'
                                        : 'Ajouter la formation',
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
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
  }

  // ============================================================
  // WIDGETS
  // ============================================================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [nafahatGreen, nafahatGreen],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: nafahatGreen.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.add_business_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isArabic ? 'تكوين جديد' : 'Nouvelle formation',
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _isArabic
                      ? 'املأ جميع الحقول لإنشاء تكوين جديد'
                      : 'Remplissez tous les champs pour créer une nouvelle formation',
                  style: GoogleFonts.cairo(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: nafahatGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: nafahatGreen, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: nafahatGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildRepetitiveSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isRepetitive ? nafahatGreen.withOpacity(0.05) : grey50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isRepetitive ? nafahatGreen : grey300,
          width: _isRepetitive ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.repeat_rounded,
                    color: _isRepetitive ? nafahatGreen : grey600,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isArabic ? 'تكوين متكرر' : 'Formation répétitive',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _isRepetitive ? nafahatGreen : grey600,
                    ),
                  ),
                ],
              ),
              Switch(
                value: _isRepetitive,
                onChanged: (value) => setState(() => _isRepetitive = value),
                activeColor: nafahatGreen,
                activeTrackColor: nafahatGreen.withOpacity(0.3),
              ),
            ],
          ),
          if (_isRepetitive) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: grey200),
              ),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children:
                    _joursSemaine.keys.map((key) {
                      final label = _isArabic ? _joursAr[key] : _joursFr[key];
                      final isSelected = _joursSemaine[key]!;
                      return ChoiceChip(
                        label: Text(
                          label ?? key,
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? Colors.white : nafahatGreen,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _joursSemaine[key] = selected;
                          });
                        },
                        selectedColor: nafahatGreen,
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: isSelected ? nafahatGreen : grey300,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        labelStyle: GoogleFonts.cairo(),
                        avatar:
                            isSelected
                                ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.white,
                                  size: 16,
                                )
                                : null,
                      );
                    }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDiscountSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: nafahatOrange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _hasDiscount ? nafahatOrange : grey200,
          width: _hasDiscount ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.local_offer_rounded,
                    color: _hasDiscount ? nafahatOrange : grey600,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isArabic ? 'تفعيل الخصم' : 'Activer la réduction',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _hasDiscount ? nafahatOrange : grey600,
                    ),
                  ),
                ],
              ),
              Switch(
                value: _hasDiscount,
                onChanged: (value) => setState(() => _hasDiscount = value),
                activeColor: nafahatOrange,
                activeTrackColor: nafahatOrange.withOpacity(0.3),
              ),
            ],
          ),
          if (_hasDiscount) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isArabic ? 'نوع الخصم' : 'Type de réduction',
                        style: GoogleFonts.cairo(fontSize: 12, color: grey600),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<bool>(
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.resolveWith((
                            states,
                          ) {
                            if (states.contains(WidgetState.selected)) {
                              return nafahatOrange.withOpacity(0.15);
                            }
                            return grey100;
                          }),
                          foregroundColor: WidgetStateProperty.resolveWith((
                            states,
                          ) {
                            if (states.contains(WidgetState.selected)) {
                              return nafahatOrange;
                            }
                            return grey600;
                          }),
                        ),
                        segments: [
                          ButtonSegment(
                            value: true,
                            icon: const Icon(Icons.percent_rounded, size: 16),
                            label: Text(
                              _isArabic ? 'نسبة' : 'Pourcentage',
                              style: GoogleFonts.cairo(),
                            ),
                          ),
                          ButtonSegment(
                            value: false,
                            icon: const Icon(Icons.money_rounded, size: 16),
                            label: Text(
                              _isArabic ? 'مبلغ' : 'Montant',
                              style: GoogleFonts.cairo(),
                            ),
                          ),
                        ],
                        selected: {_isPercentageDiscount},
                        onSelectionChanged: (Set<bool> newSelection) {
                          setState(
                            () => _isPercentageDiscount = newSelection.first,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildField(
                    label:
                        _isPercentageDiscount
                            ? (_isArabic ? 'نسبة الخصم (%)' : 'Valeur (%)')
                            : (_isArabic ? 'قيمة الخصم (درهم)' : 'Valeur (DH)'),
                    controller: _discountValueController,
                    hint: _isPercentageDiscount ? '15' : '2000',
                    required: _hasDiscount,
                    keyboardType: TextInputType.number,
                    prefixIcon:
                        _isPercentageDiscount
                            ? Icons.percent_rounded
                            : Icons.money_rounded,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool required = false,
    int maxLines = 1,
    TextDirection textDirection = TextDirection.ltr,
    TextInputType keyboardType = TextInputType.text,
    IconData? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w600,
                color: nafahatGreen,
                fontSize: 13,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: GoogleFonts.cairo(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          textDirection: textDirection,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: GoogleFonts.cairo(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.cairo(color: grey400),
            filled: true,
            fillColor: Colors.white,
            prefixIcon:
                prefixIcon != null
                    ? Icon(
                      prefixIcon,
                      color: nafahatGreen.withOpacity(0.6),
                      size: 20,
                    )
                    : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: grey300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: grey300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: nafahatGreen, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade400),
            ),
          ),
          validator: (value) {
            if (required && (value == null || value.isEmpty)) {
              return _isArabic ? '⚠️ حقل مطلوب' : '⚠️ Champ requis';
            }
            if (keyboardType == TextInputType.number &&
                value != null &&
                value.isNotEmpty &&
                double.tryParse(value) == null) {
              return _isArabic ? '⚠️ رقم غير صالح' : '⚠️ Nombre invalide';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onTap,
    bool required = false,
    bool isArabic = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w600,
                color: nafahatGreen,
                fontSize: 13,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: GoogleFonts.cairo(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: AbsorbPointer(
            child: TextFormField(
              controller: controller,
              style: GoogleFonts.cairo(fontSize: 14),
              decoration: InputDecoration(
                hintText: isArabic ? 'اختر تاريخ' : 'Choisir une date',
                hintStyle: GoogleFonts.cairo(color: grey400),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(
                  Icons.calendar_today_rounded,
                  color: nafahatGreen.withOpacity(0.6),
                  size: 20,
                ),
                suffixIcon: Icon(
                  Icons.arrow_drop_down_rounded,
                  color: nafahatGreen.withOpacity(0.6),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: grey300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: grey300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: nafahatGreen, width: 2),
                ),
              ),
              validator: (value) {
                if (required && (value == null || value.isEmpty)) {
                  return isArabic ? '⚠️ حقل مطلوب' : '⚠️ Champ requis';
                }
                return null;
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required dynamic value,
    required List<DropdownMenuItem> items,
    required ValueChanged<dynamic> onChanged,
    bool required = false,
    bool isArabic = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w600,
                color: nafahatGreen,
                fontSize: 13,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: GoogleFonts.cairo(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: grey300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<dynamic>(
              value: value,
              isExpanded: true,
              hint: Text(
                required
                    ? (isArabic ? 'اختر' : 'Sélectionner')
                    : (isArabic ? 'اختياري' : 'Optionnel'),
                style: GoogleFonts.cairo(color: grey400),
              ),
              items: items,
              onChanged: onChanged,
              icon: Icon(Icons.arrow_drop_down_rounded, color: nafahatGreen),
              style: GoogleFonts.cairo(color: nafahatGreen, fontSize: 14),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
