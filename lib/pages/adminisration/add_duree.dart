// lib/pages/adminisration/add_duree.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nafahat/pages/landing/widgets/back_to_admin_button.dart';
import 'dart:convert';
import 'package:nafahat/services/training_service.dart';

class AddDureePage extends StatefulWidget {
  final Map<String, dynamic>? dureeToEdit;

  const AddDureePage({super.key, this.dureeToEdit});

  @override
  State<AddDureePage> createState() => _AddDureePageState();
}

class _AddDureePageState extends State<AddDureePage> {
  final _formKey = GlobalKey<FormState>();
  final _typeDureeController = TextEditingController();
  final _ch1Controller = TextEditingController();
  final _ch2Controller = TextEditingController();
  final _ch3Controller = TextEditingController();
  final _ch4Controller = TextEditingController();
  final _ch5Controller = TextEditingController();
  final _ch6Controller = TextEditingController();

  bool _isLoading = false;
  bool _isArabic = false;
  bool _isEditing = false;

  static const Color nafahatGreen = Color(0xff0D443E);
  static const Color nafahatOrange = Color(0xffd57653);

  @override
  void initState() {
    super.initState();
    _isEditing = widget.dureeToEdit != null;
    if (_isEditing) {
      _loadDureeData();
    }
  }

  void _loadDureeData() {
    final data = widget.dureeToEdit!;
    _typeDureeController.text = data['type_duree'] ?? '';
    _ch1Controller.text = data['ch1']?.toString() ?? '';
    _ch2Controller.text = data['ch2']?.toString() ?? '';
    _ch3Controller.text = data['ch3']?.toString() ?? '';
    _ch4Controller.text = data['ch4']?.toString() ?? '';
    _ch5Controller.text = data['ch5']?.toString() ?? '';
    _ch6Controller.text = data['ch6']?.toString() ?? '';
  }

  @override
  void dispose() {
    _typeDureeController.dispose();
    _ch1Controller.dispose();
    _ch2Controller.dispose();
    _ch3Controller.dispose();
    _ch4Controller.dispose();
    _ch5Controller.dispose();
    _ch6Controller.dispose();
    super.dispose();
  }

  Future<void> _saveDuree() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final body = {
          'type_duree': _typeDureeController.text,
          'ch1':
              _ch1Controller.text.isNotEmpty
                  ? int.parse(_ch1Controller.text)
                  : null,
          'ch2':
              _ch2Controller.text.isNotEmpty
                  ? int.parse(_ch2Controller.text)
                  : null,
          'ch3':
              _ch3Controller.text.isNotEmpty
                  ? int.parse(_ch3Controller.text)
                  : null,
          'ch4':
              _ch4Controller.text.isNotEmpty
                  ? int.parse(_ch4Controller.text)
                  : null,
          'ch5':
              _ch5Controller.text.isNotEmpty
                  ? int.parse(_ch5Controller.text)
                  : null,
          'ch6':
              _ch6Controller.text.isNotEmpty
                  ? int.parse(_ch6Controller.text)
                  : null,
        };

        final url =
            _isEditing
                ? Uri.parse(
                  '${TrainingService.apiBaseUrl}/duree/${widget.dureeToEdit!['id']}',
                )
                : Uri.parse('${TrainingService.apiBaseUrl}/duree');

        http.Response response;

        if (_isEditing) {
          response = await http.put(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          );
        } else {
          response = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          );
        }

        final data = json.decode(response.body);

        if (response.statusCode == 201 || response.statusCode == 200) {
          if (data['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _isArabic
                      ? _isEditing
                          ? 'تم تحديث المدة بنجاح'
                          : 'تمت إضافة المدة بنجاح'
                      : _isEditing
                      ? 'Durée mise à jour avec succès'
                      : 'Durée ajoutée avec succès',
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
                      ? 'خطأ في حفظ المدة'
                      : 'Erreur lors de l\'enregistrement de la durée',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isArabic
                    ? 'خطأ في حفظ المدة'
                    : 'Erreur lors de l\'enregistrement de la durée',
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

  Future<void> _deleteDuree() async {
    if (!_isEditing) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(_isArabic ? 'تأكيد الحذف' : 'Confirmer la suppression'),
            content: Text(
              _isArabic
                  ? 'هل أنت متأكد من حذف هذه المدة؟'
                  : 'Êtes-vous sûr de vouloir supprimer cette durée ?',
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
      setState(() => _isLoading = true);

      try {
        final response = await http.delete(
          Uri.parse(
            '${TrainingService.apiBaseUrl}/duree/${widget.dureeToEdit!['id']}',
          ),
          headers: {'Content-Type': 'application/json'},
        );

        final data = json.decode(response.body);

        if (response.statusCode == 200 && data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isArabic
                    ? 'تم حذف المدة بنجاح'
                    : 'Durée supprimée avec succès',
              ),
              backgroundColor: nafahatGreen,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                data['message'] ??
                    (_isArabic
                        ? 'خطأ في حذف المدة'
                        : 'Erreur lors de la suppression'),
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

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
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
            if (keyboardType == TextInputType.number &&
                value != null &&
                value.isNotEmpty &&
                int.tryParse(value) == null) {
              return _isArabic
                  ? 'يرجى إدخال رقم صحيح'
                  : 'Veuillez entrer un nombre entier';
            }
            return null;
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _isEditing
              ? (_isArabic ? 'تعديل المدة' : 'Modifier la durée')
              : (_isArabic ? 'إضافة مدة' : 'Ajouter une durée'),
        ),
        backgroundColor: nafahatGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          const BackToAdminButton(),
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => setState(() => _isArabic = !_isArabic),
            tooltip: _isArabic ? 'Français' : 'العربية',
          ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: _isLoading ? null : _deleteDuree,
              tooltip: _isArabic ? 'حذف' : 'Supprimer',
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
                        _isEditing ? Icons.edit : Icons.access_time,
                        color: nafahatGreen,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _isEditing
                            ? (_isArabic ? 'تعديل المدة' : 'Modifier la durée')
                            : (_isArabic
                                ? 'إضافة مدة جديدة'
                                : 'Nouvelle durée'),
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
                      _buildField(
                        label: _isArabic ? 'نوع المدة *' : 'Type de durée *',
                        controller: _typeDureeController,
                        hint:
                            _isArabic
                                ? 'مثال: Jour, Mois, Année...'
                                : 'Ex: Jour, Mois, Année...',
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
                        child: Text(
                          _isArabic
                              ? '--- المدة لكل فصل ---'
                              : '--- Durée par chapitre ---',
                          style: TextStyle(
                            color: nafahatGreen.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildField(
                        label: 'Ch1',
                        controller: _ch1Controller,
                        hint: _isArabic ? 'عدد الأيام' : 'Nombre de jours',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        label: 'Ch2',
                        controller: _ch2Controller,
                        hint: _isArabic ? 'عدد الأيام' : 'Nombre de jours',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        label: 'Ch3',
                        controller: _ch3Controller,
                        hint: _isArabic ? 'عدد الأيام' : 'Nombre de jours',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        label: 'Ch4',
                        controller: _ch4Controller,
                        hint: _isArabic ? 'عدد الأيام' : 'Nombre de jours',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        label: 'Ch5',
                        controller: _ch5Controller,
                        hint: _isArabic ? 'عدد الأيام' : 'Nombre de jours',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        label: 'Ch6',
                        controller: _ch6Controller,
                        hint: _isArabic ? 'عدد الأيام' : 'Nombre de jours',
                        keyboardType: TextInputType.number,
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
                                if (_isEditing) {
                                  _loadDureeData();
                                }
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
                      onPressed: _isLoading ? null : _saveDuree,
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
                                _isEditing
                                    ? (_isArabic
                                        ? 'تحديث المدة'
                                        : 'Mettre à jour')
                                    : (_isArabic
                                        ? 'إضافة المدة'
                                        : 'Ajouter la durée'),
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
}
