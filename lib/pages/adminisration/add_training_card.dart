// lib/pages/adminisration/add_training_card.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:nafahat/models/training_model.dart';
import 'package:nafahat/services/training_service.dart';
import '../../src/features/landing/presentation/landing_page.dart'
    show AppColors;

class AddTrainingCardPage extends StatefulWidget {
  const AddTrainingCardPage({super.key});

  @override
  State<AddTrainingCardPage> createState() => _AddTrainingCardPageState();
}

class _AddTrainingCardPageState extends State<AddTrainingCardPage> {
  final _formKey = GlobalKey<FormState>();

  final _titleFrController = TextEditingController();
  final _titleArController = TextEditingController();
  final _descriptionFrController = TextEditingController();
  final _descriptionArController = TextEditingController();
  final _trainerController = TextEditingController();
  final _targetController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountValueController = TextEditingController();
  final TextEditingController _dateDebutController = TextEditingController();
  final TextEditingController _dateFinController = TextEditingController();

  bool _isLoading = false;
  bool _hasDiscount = false;
  bool _isPercentageDiscount = true;
  bool _isArabic = false;

  int? _selectedTypeFormationId;
  int? _selectedDureeId;
  int? _selectedCategorieId;
  int? _selectedSousCategorieId;
  int? _selectedFormateurId;

  List<Map<String, dynamic>> _typesFormation = [];
  List<Map<String, dynamic>> _durees = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _allSousCategories = [];
  List<Map<String, dynamic>> _filteredSousCategories = [];
  List<Map<String, dynamic>> _formateurs = [];

  static const Color nafahatGreen = Color(0xff0D443E);
  static const Color nafahatOrange = Color(0xffd57653);

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

      print('📦 Catégories: ${categories.length}');
      print('📦 Sous-catégories chargées: ${sousCategories.length}');
      print('📦 Sous-catégories: $sousCategories');

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
    _trainerController.dispose();
    _targetController.dispose();
    _imageUrlController.dispose();
    _priceController.dispose();
    _discountValueController.dispose();
    _dateDebutController.dispose();
    _dateFinController.dispose();
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
            colorScheme: ColorScheme.light(
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
      };

      try {
        final success = await TrainingService.createTraining(requestBody);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isArabic
                    ? 'تمت إضافة التكوين "${_titleArController.text}" بنجاح!'
                    : 'Formation "${_titleFrController.text}" ajoutée avec succès!',
              ),
              backgroundColor: nafahatGreen,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isArabic ? 'خطأ في إضافة التكوين' : 'Erreur lors de l\'ajout',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isArabic ? 'خطأ في الاتصال' : 'Erreur de connexion'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_isArabic ? 'إضافة تكوين' : 'Ajouter une formation'),
        backgroundColor: nafahatGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => setState(() => _isArabic = !_isArabic),
            tooltip: _isArabic ? 'Français' : 'العربية',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
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
                      const SizedBox(height: 20),
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
                      const SizedBox(height: 20),
                      _buildDropdownField(
                        label:
                            _isArabic ? 'نوع التكوين *' : 'Type de formation *',
                        value: _selectedTypeFormationId,
                        items:
                            _typesFormation.map((t) {
                              return DropdownMenuItem<int>(
                                value: t['id'],
                                child: Text(t['type_formation'] ?? ''),
                              );
                            }).toList(),
                        onChanged:
                            (value) => setState(
                              () => _selectedTypeFormationId = value as int?,
                            ),
                        required: true,
                        isArabic: _isArabic,
                      ),
                      const SizedBox(height: 20),
                      _buildDropdownField(
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
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateField(
                              label:
                                  _isArabic
                                      ? 'تاريخ البداية *'
                                      : 'Date de début *',
                              controller: _dateDebutController,
                              onTap: () => _selectDate(_dateDebutController),
                              required: true,
                              isArabic: _isArabic,
                            ),
                          ),
                          const SizedBox(width: 16),
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
                      const SizedBox(height: 20),
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
                          const SizedBox(width: 16),
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
                                      _isArabic ? sc['nom_ar'] : sc['nom_fr'];
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
                      const SizedBox(height: 20),
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
                      const SizedBox(height: 20),
                      _buildField(
                        label:
                            _isArabic
                                ? 'الوصف (بالفرنسية) *'
                                : 'Description (Français) *',
                        controller: _descriptionFrController,
                        hint:
                            _isArabic ? 'وصف تفصيلي' : 'Description détaillée',
                        required: true,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 20),
                      _buildField(
                        label:
                            _isArabic
                                ? 'الوصف (بالعربية) *'
                                : 'Description (Arabe) *',
                        controller: _descriptionArController,
                        hint:
                            _isArabic ? 'وصف تفصيلي' : 'Description détaillée',
                        required: true,
                        maxLines: 3,
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              label:
                                  _isArabic ? 'الجمهور المستهدف *' : 'Cible *',
                              controller: _targetController,
                              hint:
                                  _isArabic
                                      ? 'مثال: Débutants'
                                      : 'Ex: Débutants',
                              required: true,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildField(
                              label:
                                  _isArabic ? 'السعر (درهم) *' : 'Prix (DH) *',
                              controller: _priceController,
                              hint: _isArabic ? 'مثال: 15000' : 'Ex: 15000',
                              required: true,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ✅ Section Discount avec Switch moderne
                      Card(
                        color: nafahatOrange.withOpacity(0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.local_offer_outlined,
                                        color:
                                            _hasDiscount
                                                ? nafahatGreen
                                                : Colors.grey,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _isArabic
                                            ? 'تفعيل الخصم'
                                            : 'Activer la réduction',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color:
                                              _hasDiscount
                                                  ? nafahatGreen
                                                  : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Switch(
                                    value: _hasDiscount,
                                    onChanged:
                                        (value) => setState(
                                          () => _hasDiscount = value,
                                        ),
                                    activeColor: nafahatGreen,
                                  ),
                                ],
                              ),
                              if (_hasDiscount) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _isArabic
                                                ? 'نوع الخصم'
                                                : 'Type de réduction',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          SegmentedButton<bool>(
                                            segments: [
                                              ButtonSegment(
                                                value: true,
                                                icon: const Icon(
                                                  Icons.percent,
                                                  size: 16,
                                                ),
                                                label: Text(
                                                  _isArabic
                                                      ? 'نسبة مئوية'
                                                      : 'Pourcentage',
                                                ),
                                              ),
                                              ButtonSegment(
                                                value: false,
                                                icon: const Icon(
                                                  Icons.attach_money,
                                                  size: 16,
                                                ),
                                                label: Text(
                                                  _isArabic
                                                      ? 'مبلغ ثابت'
                                                      : 'Montant fixe',
                                                ),
                                              ),
                                            ],
                                            selected: {_isPercentageDiscount},
                                            onSelectionChanged: (
                                              Set<bool> newSelection,
                                            ) {
                                              setState(
                                                () =>
                                                    _isPercentageDiscount =
                                                        newSelection.first,
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
                                                ? (_isArabic
                                                    ? 'نسبة الخصم (%)'
                                                    : 'Valeur (%)')
                                                : (_isArabic
                                                    ? 'قيمة الخصم (درهم)'
                                                    : 'Valeur (DH)'),
                                        controller: _discountValueController,
                                        hint:
                                            _isPercentageDiscount
                                                ? '15'
                                                : '2000',
                                        required: _hasDiscount,
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildField(
                        label: _isArabic ? 'رابط الصورة' : 'URL de l\'image',
                        controller: _imageUrlController,
                        hint:
                            'https://... (${_isArabic ? 'اختياري' : 'optionnel'})',
                      ),
                      const SizedBox(height: 8),
                      if (_imageUrlController.text.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          height: 100,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: NetworkImage(_imageUrlController.text),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isLoading
                              ? null
                              : () {
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
                                  _filteredSousCategories = [];
                                });
                              },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: nafahatGreen,
                        side: BorderSide(color: nafahatGreen),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(_isArabic ? 'إعادة تعيين' : 'Réinitialiser'),
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : Text(
                                _isArabic
                                    ? 'إضافة التكوين'
                                    : 'Ajouter la formation',
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            nafahatGreen.withOpacity(0.05),
            nafahatOrange.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: nafahatGreen.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: nafahatGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.add_business, color: nafahatGreen, size: 28),
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
                    color: nafahatGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isArabic
                      ? 'املأ جميع الحقول لإنشاء تكوين جديد'
                      : 'Remplissez tous les champs pour créer une nouvelle formation',
                  style: GoogleFonts.cairo(
                    color: Colors.grey[600],
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

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool required = false,
    int maxLines = 1,
    TextDirection textDirection = TextDirection.ltr,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w600,
            color: nafahatGreen,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          textDirection: textDirection,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: nafahatGreen, width: 2),
            ),
          ),
          validator: (value) {
            if (required && (value == null || value.isEmpty))
              return _isArabic ? 'حقل مطلوب' : 'Champ requis';
            if (keyboardType == TextInputType.number &&
                value != null &&
                value.isNotEmpty &&
                double.tryParse(value) == null) {
              return _isArabic ? 'رقم غير صالح' : 'Nombre invalide';
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
        Text(
          label,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w600,
            color: nafahatGreen,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: AbsorbPointer(
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                hintText: isArabic ? 'اختر تاريخ' : 'Choisir une date',
                filled: true,
                fillColor: Colors.grey[50],
                suffixIcon: const Icon(
                  Icons.calendar_today,
                  color: nafahatGreen,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: nafahatGreen, width: 2),
                ),
              ),
              validator: (value) {
                if (required && (value == null || value.isEmpty))
                  return isArabic ? 'حقل مطلوب' : 'Champ requis';
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
        Text(
          label,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w600,
            color: nafahatGreen,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<dynamic>(
              value: value,
              isExpanded: true,
              hint: Text(
                required
                    ? (isArabic ? 'اختر' : 'Sélectionner')
                    : (isArabic ? 'اختياري' : 'Optionnel'),
              ),
              items: items,
              onChanged: onChanged,
              icon: Icon(Icons.arrow_drop_down, color: nafahatGreen),
              style: GoogleFonts.cairo(color: nafahatGreen, fontSize: 14),
            ),
          ),
        ),
        if (required && value == null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              isArabic ? 'حقل مطلوب' : 'Champ requis',
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: Colors.red.shade400,
              ),
            ),
          ),
      ],
    );
  }
}
