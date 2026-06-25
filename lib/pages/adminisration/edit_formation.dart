// lib/pages/adminisration/edit_formation.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:nafahat/models/training_model.dart';
import 'package:nafahat/services/training_service.dart';

class EditFormationPage extends StatefulWidget {
  final String formationId;

  const EditFormationPage({super.key, required this.formationId});

  @override
  State<EditFormationPage> createState() => _EditFormationPageState();
}

class _EditFormationPageState extends State<EditFormationPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isArabic = false;

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

  bool _hasDiscount = false;
  bool _isPercentageDiscount = true;
  String? _currentActif;

  int? _selectedTypeFormationId;
  int? _selectedDureeId;
  int? _selectedCategorieId;
  int? _selectedFormateurId;

  List<Map<String, dynamic>> _typesFormation = [];
  List<Map<String, dynamic>> _durees = [];
  List<Map<String, dynamic>> _categories = [];
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

      final response = await http.get(
        Uri.parse(
          '${TrainingService.apiBaseUrl}/formations/${widget.formationId}',
        ),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final formation = data['data'];
          _populateForm(formation);
        }
      }

      setState(() {
        _typesFormation = types;
        _durees = durees;
        _categories = categories;
        _formateurs = formateurs;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur chargement données: $e');
      setState(() => _isLoading = false);
    }
  }

  void _populateForm(Map<String, dynamic> formation) {
    _titleFrController.text = formation['titre_fr'] ?? '';
    _titleArController.text = formation['titre_ar'] ?? '';
    _selectedTypeFormationId = formation['id_type_formation'];
    _selectedDureeId = formation['id_duree'];
    _descriptionFrController.text = formation['descri_fr'] ?? '';
    _descriptionArController.text = formation['descri_ar'] ?? '';
    _trainerController.text = formation['formateur_nom_fr'] ?? '';
    _targetController.text = formation['cible_fr'] ?? '';
    _priceController.text = formation['prix']?.toString() ?? '0';
    _selectedCategorieId = formation['id_categorie'];
    _selectedFormateurId = formation['id_formateur'];
    _hasDiscount = formation['discount'] == 'oui';
    if (_hasDiscount && formation['valeur_disc'] != null) {
      _discountValueController.text = formation['valeur_disc'].toString();
    }
    _imageUrlController.text = formation['photo'] ?? '';
    _currentActif = formation['actif'] ?? 'oui';

    final periode = formation['periode'] ?? '';
    if (periode.isNotEmpty) {
      final parts = periode.split(' - ');
      if (parts.length == 2) {
        _dateDebutController.text = parts[0].trim();
        _dateFinController.text = parts[1].trim();
      }
    }
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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: Locale(_isArabic ? 'ar' : 'fr'),
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.toLocal().toString().split(' ')[0];
      });
    }
  }

  Future<void> _saveFormation() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

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
        'id_formateur': _selectedFormateurId,
        'photo':
            _imageUrlController.text.isNotEmpty
                ? _imageUrlController.text
                : null,
        'actif': _currentActif,
      };

      try {
        final response = await http.put(
          Uri.parse(
            '${TrainingService.apiBaseUrl}/formations/${widget.formationId}',
          ),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(requestBody),
        );
        final data = json.decode(response.body);
        if (response.statusCode == 200 && data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isArabic
                    ? 'تم تحديث التكوين بنجاح'
                    : 'Formation mise à jour avec succès',
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
                    ? 'خطأ في تحديث التكوين'
                    : 'Erreur lors de la mise à jour',
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
      setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteFormation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(_isArabic ? 'تأكيد الحذف' : 'Confirmer la suppression'),
            content: Text(
              _isArabic
                  ? 'Voulez-vous vraiment désactiver cette formation ?'
                  : 'Voulez-vous vraiment désactiver cette formation ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(_isArabic ? 'إلغاء' : 'Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(_isArabic ? 'حذف' : 'Supprimer'),
              ),
            ],
          ),
    );
    if (confirm == true) {
      setState(() => _isSaving = true);
      try {
        final response = await http.delete(
          Uri.parse(
            '${TrainingService.apiBaseUrl}/formations/${widget.formationId}',
          ),
          headers: {'Content-Type': 'application/json'},
        );
        final data = json.decode(response.body);
        if (response.statusCode == 200 && data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isArabic
                    ? 'تم حذف التكوين بنجاح'
                    : 'Formation supprimée avec succès',
              ),
              backgroundColor: nafahatGreen,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        print('❌ Erreur suppression: $e');
      }
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_isArabic ? 'تعديل تكوين' : 'Modifier la formation'),
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
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
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
                                        ? 'مثال: Flutter avancé'
                                        : 'Ex: Flutter avancé',
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
                                        ? 'مثال: فلاتر متقدم'
                                        : 'Ex: فلاتر متقدم',
                                required: true,
                                textDirection: TextDirection.rtl,
                              ),
                              const SizedBox(height: 20),
                              _buildDropdownField(
                                label:
                                    _isArabic
                                        ? 'نوع التكوين *'
                                        : 'Type de formation *',
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
                                      () => _selectedTypeFormationId = value,
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
                                      () => _selectedDureeId = value,
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
                                      onTap:
                                          () =>
                                              _selectDate(_dateDebutController),
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
                                      onTap:
                                          () => _selectDate(_dateFinController),
                                      required: true,
                                      isArabic: _isArabic,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _buildDropdownField(
                                label: _isArabic ? 'التصنيف' : 'Catégorie',
                                value: _selectedCategorieId,
                                items:
                                    _categories.map((c) {
                                      final label =
                                          _isArabic
                                              ? c['categorie_ar']
                                              : c['categorie_fr'];
                                      return DropdownMenuItem<int>(
                                        value: c['id'],
                                        child: Text(label ?? ''),
                                      );
                                    }).toList(),
                                onChanged:
                                    (value) => setState(
                                      () => _selectedCategorieId = value,
                                    ),
                                required: false,
                                isArabic: _isArabic,
                              ),
                              const SizedBox(height: 20),
                              _buildDropdownField(
                                label: _isArabic ? 'المكون' : 'Formateur',
                                value: _selectedFormateurId,
                                items:
                                    _formateurs.map((f) {
                                      final label =
                                          _isArabic
                                              ? f['nom_prenom_ar']
                                              : f['nom_prenom_fr'];
                                      return DropdownMenuItem<int>(
                                        value: f['id'],
                                        child: Text(label ?? ''),
                                      );
                                    }).toList(),
                                onChanged:
                                    (value) => setState(
                                      () => _selectedFormateurId = value,
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
                                    _isArabic
                                        ? 'وصف تفصيلي'
                                        : 'Description détaillée',
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
                                    _isArabic
                                        ? 'وصف تفصيلي'
                                        : 'Description détaillée',
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
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildField(
                                      label:
                                          _isArabic
                                              ? 'السعر (درهم) *'
                                              : 'Prix (DH) *',
                                      controller: _priceController,
                                      hint:
                                          _isArabic
                                              ? 'مثال: 15000'
                                              : 'Ex: 15000',
                                      required: true,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Card(
                                color: nafahatOrange.withOpacity(0.05),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Checkbox(
                                            value: _hasDiscount,
                                            onChanged:
                                                (value) => setState(
                                                  () =>
                                                      _hasDiscount =
                                                          value ?? false,
                                                ),
                                            activeColor: nafahatGreen,
                                          ),
                                          Text(
                                            _isArabic
                                                ? 'تفعيل الخصم'
                                                : 'Activer la réduction',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
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
                                                    selected: {
                                                      _isPercentageDiscount,
                                                    },
                                                    onSelectionChanged: (
                                                      Set<bool> newSelection,
                                                    ) {
                                                      setState(
                                                        () =>
                                                            _isPercentageDiscount =
                                                                newSelection
                                                                    .first,
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
                                                controller:
                                                    _discountValueController,
                                                hint:
                                                    _isPercentageDiscount
                                                        ? '15'
                                                        : '2000',
                                                required: _hasDiscount,
                                                keyboardType:
                                                    TextInputType.number,
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
                                label:
                                    _isArabic
                                        ? 'رابط الصورة'
                                        : 'URL de l\'image',
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
                                      image: NetworkImage(
                                        _imageUrlController.text,
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 20),
                              _buildDropdownField(
                                label: _isArabic ? 'الحالة' : 'Statut',
                                value: _currentActif,
                                items: [
                                  const DropdownMenuItem(
                                    value: 'oui',
                                    child: Text('Actif'),
                                  ),
                                  const DropdownMenuItem(
                                    value: 'non',
                                    child: Text('Inactif'),
                                  ),
                                ],
                                onChanged:
                                    (value) =>
                                        setState(() => _currentActif = value),
                                required: false,
                                isArabic: _isArabic,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed:
                                  _isSaving
                                      ? null
                                      : () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                              label: Text(_isArabic ? 'إلغاء' : 'Annuler'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey[700],
                                side: BorderSide(color: Colors.grey[300]!),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isSaving ? null : _saveFormation,
                              icon:
                                  _isSaving
                                      ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                      : const Icon(Icons.save),
                              label: Text(
                                _isArabic ? 'حفظ التغييرات' : 'Enregistrer',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: nafahatGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isSaving ? null : _deleteFormation,
                          icon: const Icon(Icons.delete_outline),
                          label: Text(
                            _isArabic
                                ? 'حذف هذه التكوين'
                                : 'Supprimer cette formation',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: BorderSide(color: Colors.red.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
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
            child: Icon(Icons.edit_note, color: nafahatGreen, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isArabic ? 'تعديل التكوين' : 'Modifier la formation',
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: nafahatGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isArabic
                      ? 'تعديل معلومات التكوين'
                      : 'Modifier les informations de la formation',
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
