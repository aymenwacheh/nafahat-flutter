// lib/pages/adminisration/add_cible_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafahat/models/cible_model.dart';
import 'package:nafahat/services/cible_service.dart';
import 'package:nafahat/providers/language_provider.dart';

class AddCiblePage extends StatefulWidget {
  final CibleModel? cible;

  const AddCiblePage({super.key, this.cible});

  @override
  State<AddCiblePage> createState() => _AddCiblePageState();
}

class _AddCiblePageState extends State<AddCiblePage> {
  final _formKey = GlobalKey<FormState>();
  final _nomCibleController = TextEditingController();
  final _ch1Controller = TextEditingController();
  final _ch2Controller = TextEditingController();
  final _ch3Controller = TextEditingController();

  bool _isLoading = false;
  bool _isEditMode = false;

  static const Color nafahatGreen = Color(0xff0D443E);
  static const Color nafahatOrange = Color(0xffd57653);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.cible != null;
    if (widget.cible != null) {
      _nomCibleController.text = widget.cible!.nomCible;
      _ch1Controller.text = widget.cible!.ch1 ?? '';
      _ch2Controller.text = widget.cible!.ch2 ?? '';
      _ch3Controller.text = widget.cible!.ch3 ?? '';
    }
  }

  @override
  void dispose() {
    _nomCibleController.dispose();
    _ch1Controller.dispose();
    _ch2Controller.dispose();
    _ch3Controller.dispose();
    super.dispose();
  }

  Future<void> _saveCible() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final isArabic = context.read<LanguageProvider>().isArabic;

    final cible = CibleModel(
      id: _isEditMode ? widget.cible!.id : null,
      nomCible: _nomCibleController.text.trim(),
      ch1:
          _ch1Controller.text.trim().isNotEmpty
              ? _ch1Controller.text.trim()
              : null,
      ch2:
          _ch2Controller.text.trim().isNotEmpty
              ? _ch2Controller.text.trim()
              : null,
      ch3:
          _ch3Controller.text.trim().isNotEmpty
              ? _ch3Controller.text.trim()
              : null,
    );

    try {
      bool success;
      if (_isEditMode) {
        final updated = await CibleService.updateCible(cible);
        success = updated != null;
      } else {
        final created = await CibleService.createCible(cible);
        success = created != null;
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? (isArabic ? '✅ تم التحديث بنجاح' : '✅ Mise à jour réussie')
                  : (isArabic ? '✅ تمت الإضافة بنجاح' : '✅ Ajout réussi'),
            ),
            backgroundColor: nafahatGreen,
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Erreur lors de l\'opération');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? '❌ Erreur lors de l\'opération'
                : '❌ Erreur lors de l\'opération',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LanguageProvider>().isArabic;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text(
          _isEditMode
              ? (isArabic ? 'تعديل الجمهور' : 'Modifier la cible')
              : (isArabic ? 'إضافة جمهور' : 'Ajouter une cible'),
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: nafahatGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // ✅ Bouton de changement de langue
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                isArabic ? Icons.translate : Icons.translate,
                color: Colors.white,
              ),
              onPressed: () {
                context.read<LanguageProvider>().toggleLanguage();
              },
              tooltip: isArabic ? 'Français' : 'العربية',
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: nafahatGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.people_rounded,
                          color: nafahatGreen,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isEditMode
                            ? (isArabic ? 'تعديل الجمهور' : 'Modifier la cible')
                            : (isArabic
                                ? 'إضافة جمهور جديد'
                                : 'Nouvelle cible'),
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: nafahatGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Nom de la cible
                  _buildField(
                    label: isArabic ? 'Nom de la cible *' : 'Nom de la cible *',
                    controller: _nomCibleController,
                    hint: isArabic ? 'مثال: Développeurs' : 'Ex: Développeurs',
                    required: true,
                    icon: Icons.label_rounded,
                    isArabic: isArabic,
                  ),
                  const SizedBox(height: 16),

                  // Séparateur
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(child: Container(height: 1, color: grey200)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            isArabic
                                ? 'champs supplémentaires'
                                : 'Champs supplémentaires',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: grey600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(child: Container(height: 1, color: grey200)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Champ 1
                  _buildField(
                    label: isArabic ? 'ch1' : 'ch1',
                    controller: _ch1Controller,
                    hint: isArabic ? 'مثال: Junior' : 'Ex: Junior',
                    required: false,
                    icon: Icons.filter_1_rounded,
                    isArabic: isArabic,
                  ),
                  const SizedBox(height: 16),

                  // Champ 2
                  _buildField(
                    label: isArabic ? 'ch2' : 'ch2',
                    controller: _ch2Controller,
                    hint: isArabic ? 'مثال: Senior' : 'Ex: Senior',
                    required: false,
                    icon: Icons.filter_2_rounded,
                    isArabic: isArabic,
                  ),
                  const SizedBox(height: 16),

                  // Champ 3
                  _buildField(
                    label: isArabic ? 'ch3' : 'ch3',
                    controller: _ch3Controller,
                    hint: isArabic ? 'مثال: Expert' : 'Ex: Expert',
                    required: false,
                    icon: Icons.filter_3_rounded,
                    isArabic: isArabic,
                  ),
                  const SizedBox(height: 24),

                  // Boutons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              _isLoading ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            side: BorderSide(color: Colors.grey[300]!),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            isArabic ? 'إلغاء' : 'Annuler',
                            style: GoogleFonts.cairo(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveCible,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: nafahatGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
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
                                  : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _isEditMode
                                            ? Icons.save_rounded
                                            : Icons.add_rounded,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _isEditMode
                                            ? (isArabic
                                                ? 'تحديث'
                                                : 'Mettre à jour')
                                            : (isArabic ? 'إضافة' : 'Ajouter'),
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
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool required,
    required IconData icon,
    required bool isArabic,
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
          style: GoogleFonts.cairo(fontSize: 14),
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.cairo(color: grey400),
            hintTextDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            filled: true,
            fillColor: Colors.white,
            prefixIcon: Icon(
              icon,
              color: nafahatGreen.withOpacity(0.6),
              size: 20,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade400),
            ),
          ),
          validator: (value) {
            if (required && (value == null || value.isEmpty)) {
              return isArabic ? '⚠️ حقل مطلوب' : '⚠️ Champ requis';
            }
            return null;
          },
        ),
      ],
    );
  }
}
