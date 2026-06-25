// lib/pages/administration/edit_categorie.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:nafahat/services/training_service.dart';
import 'package:google_fonts/google_fonts.dart';

class EditCategoriePage extends StatefulWidget {
  final String itemId; // ID de la catégorie OU de la sous-catégorie
  final String type; // 'categorie' ou 'sous_categorie'

  const EditCategoriePage({
    super.key,
    required this.itemId,
    required this.type,
  });

  @override
  State<EditCategoriePage> createState() => _EditCategoriePageState();
}

class _EditCategoriePageState extends State<EditCategoriePage> {
  final _formKey = GlobalKey<FormState>();
  final _nomFrController = TextEditingController();
  final _nomArController = TextEditingController();

  // Pour les sous-catégories
  String? _selectedCategorieId;
  List<Map<String, dynamic>> _categories = [];

  // Champs optionnels
  final _ch1Controller = TextEditingController();
  final _ch2Controller = TextEditingController();
  final _ch3Controller = TextEditingController();
  final _ch4Controller = TextEditingController();
  final _ch5Controller = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingData = true;
  bool _isArabic = false;

  static const Color nafahatGreen = Color(0xff0D443E);
  static const Color nafahatOrange = Color(0xffd57653);

  @override
  void initState() {
    super.initState();
    _loadData();
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

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);
    try {
      // Charger les catégories pour le dropdown (si sous-catégorie)
      final catResponse = await http.get(
        Uri.parse('${TrainingService.apiBaseUrl}/categories'),
      );
      if (catResponse.statusCode == 200) {
        final catData = json.decode(catResponse.body);
        if (catData['success'] == true) {
          setState(() {
            _categories = List<Map<String, dynamic>>.from(catData['data']);
          });
        }
      }

      // Charger l'élément à éditer
      String url;
      if (widget.type == 'categorie') {
        url = '${TrainingService.apiBaseUrl}/categories/${widget.itemId}';
      } else {
        url =
            '${TrainingService.apiBaseUrl}/categories/sous-categories/${widget.itemId}';
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final item = data['data'];
          setState(() {
            _nomFrController.text =
                item['categorie_fr'] ?? item['nom_fr'] ?? '';
            _nomArController.text =
                item['categorie_ar'] ?? item['nom_ar'] ?? '';
            _ch1Controller.text = item['ch1'] ?? '';
            _ch2Controller.text = item['ch2'] ?? '';
            _ch3Controller.text = item['ch3'] ?? '';
            if (widget.type == 'sous_categorie') {
              _selectedCategorieId = item['id_categorie']?.toString();
            }
          });
        }
      }
    } catch (e) {
      print('Erreur chargement: $e');
    } finally {
      setState(() => _isLoadingData = false);
    }
  }

  Future<void> _updateItem() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        String url;
        Map<String, dynamic> body;

        if (widget.type == 'categorie') {
          url = '${TrainingService.apiBaseUrl}/categories/${widget.itemId}';
          body = {
            'categorie_fr': _nomFrController.text,
            'categorie_ar': _nomArController.text,
            'ch1': _ch1Controller.text.isNotEmpty ? _ch1Controller.text : null,
            'ch2': _ch2Controller.text.isNotEmpty ? _ch2Controller.text : null,
            'ch3': _ch3Controller.text.isNotEmpty ? _ch3Controller.text : null,
          };
        } else {
          url =
              '${TrainingService.apiBaseUrl}/categories/sous-categories/${widget.itemId}';
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

        final response = await http.put(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(body),
        );

        final data = json.decode(response.body);
        if (response.statusCode == 200 && data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isArabic ? 'Mis à jour avec succès' : 'Mise à jour réussie',
              ),
              backgroundColor: nafahatGreen,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isArabic ? 'Erreur de mise à jour' : 'Erreur de mise à jour',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print('Erreur: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isArabic ? 'Erreur de connexion' : 'Erreur de connexion',
            ),
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
        title: Text(
          _isArabic
              ? widget.type == 'categorie'
                  ? 'تعديل التصنيف'
                  : 'تعديل التصنيف الفرعي'
              : widget.type == 'categorie'
              ? 'Modifier la catégorie'
              : 'Modifier la sous-catégorie',
        ),
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
          _isLoadingData
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildHeader(),
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
                                    _isArabic
                                        ? 'الاسم (بالعربية) *'
                                        : 'Nom (Arabe) *',
                                controller: _nomArController,
                                hint:
                                    _isArabic
                                        ? 'مثال: تطوير الويب'
                                        : 'Ex: تطوير الويب',
                                textDirection: TextDirection.rtl,
                              ),
                              const SizedBox(height: 16),

                              // Pour sous-catégorie : dropdown de catégorie parente
                              if (widget.type == 'sous_categorie')
                                _buildCategorieParentDropdown(),

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
        DropdownButtonFormField<String>(
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
                  child: Text(label ?? 'Sans nom', style: GoogleFonts.cairo()),
                );
              }).toList(),
          onChanged: (value) => setState(() => _selectedCategorieId = value),
          validator: (value) {
            if (widget.type == 'sous_categorie' &&
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
            child: Icon(Icons.edit, color: nafahatGreen, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isArabic
                      ? widget.type == 'categorie'
                          ? 'تعديل التصنيف'
                          : 'تعديل التصنيف الفرعي'
                      : widget.type == 'categorie'
                      ? 'Modifier la catégorie'
                      : 'Modifier la sous-catégorie',
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: nafahatGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isArabic
                      ? 'Modifiez les informations et enregistrez'
                      : 'Modifiez les informations et enregistrez',
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
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: nafahatGreen,
              side: BorderSide(color: nafahatGreen),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(_isArabic ? 'إلغاء' : 'Annuler'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _updateItem,
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
                      _isArabic ? 'تحديث' : 'Mettre à jour',
                      style: GoogleFonts.cairo(),
                    ),
          ),
        ),
      ],
    );
  }
}
