// lib/pages/administration/add_categorie.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:nafahat/services/training_service.dart';
import 'package:google_fonts/google_fonts.dart';

class AddCategoriePage extends StatefulWidget {
  const AddCategoriePage({super.key});

  @override
  State<AddCategoriePage> createState() => _AddCategoriePageState();
}

class _AddCategoriePageState extends State<AddCategoriePage> {
  final _formKey = GlobalKey<FormState>();

  // Champs communs
  final _nomFrController = TextEditingController();
  final _nomArController = TextEditingController();

  // Type : 'categorie' ou 'sous_categorie'
  String _selectedType = 'categorie';

  // Pour la catégorie parente (si type = sous_categorie)
  String? _selectedCategorieId;
  List<Map<String, dynamic>> _categories = [];
  bool _isLoadingCategories = true;

  // Champs supplémentaires optionnels (ch1 à ch5)
  final _ch1Controller = TextEditingController();
  final _ch2Controller = TextEditingController();
  final _ch3Controller = TextEditingController();
  final _ch4Controller = TextEditingController();
  final _ch5Controller = TextEditingController();

  bool _isLoading = false;
  bool _isArabic = false;

  static const Color nafahatGreen = Color(0xff0D443E);
  static const Color nafahatOrange = Color(0xffd57653);

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nomFrController.dispose();
    _nomArController.dispose();
    _ch1Controller.dispose();
    _ch2Controller.dispose();
    _ch3Controller.dispose();
    _ch4Controller.dispose();
    _ch5Controller.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final response = await http.get(
        Uri.parse('${TrainingService.apiBaseUrl}/categories'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _categories = List<Map<String, dynamic>>.from(data['data']);
          });
        }
      }
    } catch (e) {
      print('Erreur chargement catégories: $e');
    } finally {
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _saveItem() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final String url;
        final Map<String, dynamic> body;

        if (_selectedType == 'categorie') {
          // ---------- AJOUT D'UNE CATÉGORIE ----------
          url = '${TrainingService.apiBaseUrl}/categories';
          body = {
            'categorie_fr': _nomFrController.text,
            'categorie_ar': _nomArController.text,
            'parent_id':
                null, // On ne gère pas le parent pour les catégories ici
            'ch1': _ch1Controller.text.isNotEmpty ? _ch1Controller.text : null,
            'ch2': _ch2Controller.text.isNotEmpty ? _ch2Controller.text : null,
            'ch3': _ch3Controller.text.isNotEmpty ? _ch3Controller.text : null,
          };
        } else {
          // ---------- AJOUT D'UNE SOUS-CATÉGORIE ----------
          if (_selectedCategorieId == null || _selectedCategorieId!.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _isArabic
                      ? 'يرجى اختيار تصنيف أولاً'
                      : 'Veuillez sélectionner une catégorie',
                ),
                backgroundColor: Colors.red,
              ),
            );
            setState(() => _isLoading = false);
            return;
          }

          url = '${TrainingService.apiBaseUrl}/categories/sous-categories';
          body = {
            'nom_fr': _nomFrController.text,
            'nom_ar': _nomArController.text,
            'id_categorie': int.parse(_selectedCategorieId!),
            'ch1': _ch1Controller.text.isNotEmpty ? _ch1Controller.text : null,
            'ch2': _ch2Controller.text.isNotEmpty ? _ch2Controller.text : null,
            'ch3': _ch3Controller.text.isNotEmpty ? _ch3Controller.text : null,
            'ch4': _ch4Controller.text.isNotEmpty ? _ch4Controller.text : null,
            'ch5': _ch5Controller.text.isNotEmpty ? _ch5Controller.text : null,
          };
        }

        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(body),
        );

        final data = json.decode(response.body);

        if (response.statusCode == 201 && data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isArabic
                    ? _selectedType == 'categorie'
                        ? 'تمت إضافة التصنيف بنجاح'
                        : 'تمت إضافة التصنيف الفرعي بنجاح'
                    : _selectedType == 'categorie'
                    ? 'Catégorie ajoutée avec succès'
                    : 'Sous-catégorie ajoutée avec succès',
              ),
              backgroundColor: nafahatGreen,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isArabic ? 'خطأ في الإضافة' : 'Erreur lors de l\'ajout',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print('Erreur: $e');
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
        title: Text(_isArabic ? 'إضافة تصنيف' : 'Ajouter une catégorie'),
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
              const SizedBox(height: 24),
              // ✅ Sélecteur : Catégorie ou Sous-catégorie
              _buildTypeSelector(),
              const SizedBox(height: 24),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Nom (commun)
                      _buildField(
                        label:
                            _isArabic
                                ? 'الاسم (بالفرنسية) *'
                                : 'Nom (Français) *',
                        controller: _nomFrController,
                        hint:
                            _isArabic
                                ? 'مثال: Développement Web'
                                : 'Ex: Développement Web',
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        label:
                            _isArabic ? 'الاسم (بالعربية) *' : 'Nom (Arabe) *',
                        controller: _nomArController,
                        hint:
                            _isArabic ? 'مثال: تطوير الويب' : 'Ex: تطوير الويب',
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 16),

                      // Si sous-catégorie, afficher la sélection de catégorie parente
                      if (_selectedType == 'sous_categorie')
                        _buildCategorieParentDropdown(),

                      // Champs supplémentaires ch1 à ch5 (optionnels)
                      const SizedBox(height: 16),
                      _buildOptionalFields(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _buildButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: RadioListTile<String>(
              title: Text(
                _isArabic ? 'تصنيف رئيسي' : 'Catégorie',
                style: GoogleFonts.cairo(),
              ),
              value: 'categorie',
              groupValue: _selectedType,
              onChanged: (value) {
                setState(() => _selectedType = value!);
              },
              activeColor: nafahatGreen,
            ),
          ),
          Expanded(
            child: RadioListTile<String>(
              title: Text(
                _isArabic ? 'تصنيف فرعي' : 'Sous-catégorie',
                style: GoogleFonts.cairo(),
              ),
              value: 'sous_categorie',
              groupValue: _selectedType,
              onChanged: (value) {
                setState(() => _selectedType = value!);
              },
              activeColor: nafahatGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorieParentDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isArabic ? 'التصنيف الأب *' : 'Catégorie parente *',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w600,
            color: nafahatGreen,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        _isLoadingCategories
            ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: CircularProgressIndicator()),
            )
            : DropdownButtonFormField<String>(
              value: _selectedCategorieId,
              hint: Text(
                _isArabic
                    ? '-- اختر تصنيفًا --'
                    : '-- Sélectionner une catégorie --',
                style: GoogleFonts.cairo(color: Colors.grey[500]),
              ),
              isExpanded: true,
              decoration: InputDecoration(
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              items:
                  _categories.map((cat) {
                    final label =
                        _isArabic
                            ? cat['categorie_ar'] ?? cat['categorie_fr']
                            : cat['categorie_fr'] ?? cat['categorie_ar'];
                    return DropdownMenuItem<String>(
                      value: cat['id'].toString(),
                      child: Text(
                        label ?? 'Sans nom',
                        style: GoogleFonts.cairo(),
                      ),
                    );
                  }).toList(),
              onChanged:
                  (value) => setState(() => _selectedCategorieId = value),
              validator: (value) {
                if (_selectedType == 'sous_categorie' &&
                    (value == null || value.isEmpty)) {
                  return _isArabic ? 'حقل مطلوب' : 'Champ requis';
                }
                return null;
              },
            ),
      ],
    );
  }

  Widget _buildOptionalFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isArabic
              ? 'Champs supplémentaires (optionnels)'
              : 'Champs supplémentaires (optionnels)',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w600,
            color: nafahatGreen,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildSmallField('ch1', _ch1Controller)),
            const SizedBox(width: 12),
            Expanded(child: _buildSmallField('ch2', _ch2Controller)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildSmallField('ch3', _ch3Controller)),
            const SizedBox(width: 12),
            Expanded(child: _buildSmallField('ch4', _ch4Controller)),
          ],
        ),
        const SizedBox(height: 12),
        _buildSmallField('ch5', _ch5Controller),
      ],
    );
  }

  Widget _buildSmallField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[600]),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            child: Icon(Icons.category, color: nafahatGreen, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isArabic
                      ? 'إضافة تصنيف أو تصنيف فرعي'
                      : 'Ajouter une catégorie ou sous-catégorie',
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: nafahatGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isArabic
                      ? 'Choisissez le type puis remplissez les champs'
                      : 'Choisissez le type puis remplissez les champs',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: Colors.grey[600],
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
    TextDirection textDirection = TextDirection.ltr,
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
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.cairo(color: Colors.grey[400]),
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
            if (value == null || value.isEmpty) {
              return _isArabic ? 'حقل مطلوب' : 'Champ requis';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => _formKey.currentState?.reset(),
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
            onPressed: _isLoading ? null : _saveItem,
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
                          ? _selectedType == 'categorie'
                              ? 'إضافة تصنيف'
                              : 'إضافة تصنيف فرعي'
                          : _selectedType == 'categorie'
                          ? 'Ajouter une catégorie'
                          : 'Ajouter une sous-catégorie',
                      style: GoogleFonts.cairo(),
                    ),
          ),
        ),
      ],
    );
  }
}
