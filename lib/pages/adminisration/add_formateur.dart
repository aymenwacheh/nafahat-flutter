// lib/pages/administration/add_formateur.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:nafahat/services/training_service.dart';

class AddFormateurPage extends StatefulWidget {
  const AddFormateurPage({super.key});

  @override
  State<AddFormateurPage> createState() => _AddFormateurPageState();
}

class _AddFormateurPageState extends State<AddFormateurPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomFrController = TextEditingController();
  final _nomArController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _bioFrController = TextEditingController();
  final _bioArController = TextEditingController();

  String? _selectedCategorieId;
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;
  bool _isArabic = false;

  static const Color nafahatGreen = Color(0xff0D443E);
  static const Color nafahatOrange = Color(0xffd57653);

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await http.get(
        Uri.parse('${TrainingService.apiBaseUrl}/categories'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _categories = List<Map<String, dynamic>>.from(data['data']);
        });
      }
    } catch (e) {
      print('Erreur chargement catégories: $e');
    }
  }

  @override
  void dispose() {
    _nomFrController.dispose();
    _nomArController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _bioFrController.dispose();
    _bioArController.dispose();
    super.dispose();
  }

  Future<void> _saveFormateur() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final response = await http.post(
          Uri.parse('${TrainingService.apiBaseUrl}/formateurs'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'nom_prenom_fr': _nomFrController.text,
            'nom_prenom_ar': _nomArController.text,
            'email': _emailController.text,
            'telephone': _telephoneController.text,
            'bio_fr': _bioFrController.text,
            'bio_ar': _bioArController.text,
            'id_categorie': _selectedCategorieId,
          }),
        );

        final data = json.decode(response.body);

        if (response.statusCode == 201 && data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isArabic
                    ? 'تمت إضافة المكون بنجاح'
                    : 'Formateur ajouté avec succès',
              ),
              backgroundColor: nafahatGreen,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isArabic
                    ? 'خطأ في إضافة المكون'
                    : 'Erreur lors de l\'ajout du formateur',
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
        title: Text(_isArabic ? 'إضافة مكون' : 'Ajouter un formateur'),
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
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: nafahatGreen.withOpacity(0.05),
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
                      child: Icon(
                        Icons.person_add,
                        color: nafahatGreen,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _isArabic ? 'إضافة مكون جديد' : 'Nouveau formateur',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: nafahatGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
                      // Nom Français
                      _buildField(
                        label:
                            _isArabic
                                ? 'الاسم واللقب (بالفرنسية) *'
                                : 'Nom et prénom (Français) *',
                        controller: _nomFrController,
                        hint:
                            _isArabic ? 'مثال: Jean Dupont' : 'Ex: Jean Dupont',
                      ),
                      const SizedBox(height: 16),

                      // Nom Arabe
                      _buildField(
                        label:
                            _isArabic
                                ? 'الاسم واللقب (بالعربية) *'
                                : 'Nom et prénom (Arabe) *',
                        controller: _nomArController,
                        hint: _isArabic ? 'مثال: جان دوبون' : 'Ex: جان دوبون',
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 16),

                      // Email
                      _buildField(
                        label: _isArabic ? 'البريد الإلكتروني' : 'Email',
                        controller: _emailController,
                        hint:
                            _isArabic
                                ? 'مثال: nom@exemple.com'
                                : 'Ex: nom@exemple.com',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      // Téléphone
                      _buildField(
                        label: _isArabic ? 'رقم الهاتف' : 'Téléphone',
                        controller: _telephoneController,
                        hint: _isArabic ? 'مثال: 0612345678' : 'Ex: 0612345678',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      // Catégorie
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isArabic ? 'التصنيف' : 'Catégorie',
                            style: TextStyle(
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
                              child: DropdownButton<String>(
                                value: _selectedCategorieId,
                                hint: Text(
                                  _isArabic
                                      ? 'اختر تصنيف'
                                      : 'Choisir une catégorie',
                                ),
                                isExpanded: true,
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('---'),
                                  ),
                                  ..._categories.map((c) {
                                    final label =
                                        _isArabic
                                            ? c['categorie_ar']
                                            : c['categorie_fr'];
                                    return DropdownMenuItem(
                                      value: c['id'].toString(),
                                      child: Text(label ?? ''),
                                    );
                                  }),
                                ],
                                onChanged: (value) {
                                  setState(() => _selectedCategorieId = value);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Bio Français
                      _buildField(
                        label:
                            _isArabic
                                ? 'السيرة الذاتية (بالفرنسية)'
                                : 'Bio (Français)',
                        controller: _bioFrController,
                        hint: _isArabic ? 'السيرة الذاتية' : 'Bio en français',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Bio Arabe
                      _buildField(
                        label:
                            _isArabic
                                ? 'السيرة الذاتية (بالعربية)'
                                : 'Bio (Arabe)',
                        controller: _bioArController,
                        hint: _isArabic ? 'السيرة الذاتية' : 'Bio en arabe',
                        textDirection: TextDirection.rtl,
                        maxLines: 3,
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
                              : () => _formKey.currentState?.reset(),
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
                      onPressed: _isLoading ? null : _saveFormateur,
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
                                    ? 'إضافة المكون'
                                    : 'Ajouter le formateur',
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

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextDirection textDirection = TextDirection.ltr,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
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
            if (label.contains('*') && (value == null || value.isEmpty)) {
              return _isArabic ? 'حقل مطلوب' : 'Champ requis';
            }
            return null;
          },
        ),
      ],
    );
  }
}
