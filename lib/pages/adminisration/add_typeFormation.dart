// lib/pages/adminisration/add_typeFormation.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:nafahat/services/training_service.dart';

class AddTypeFormationPage extends StatefulWidget {
  final Map<String, dynamic>? typeToEdit;

  const AddTypeFormationPage({super.key, this.typeToEdit});

  @override
  State<AddTypeFormationPage> createState() => _AddTypeFormationPageState();
}

class _AddTypeFormationPageState extends State<AddTypeFormationPage> {
  final _formKey = GlobalKey<FormState>();
  final _typeFormationController = TextEditingController();
  final _ch1Controller = TextEditingController();
  final _ch2Controller = TextEditingController();
  final _ch3Controller = TextEditingController();
  final _ch4Controller = TextEditingController();
  final _ch5Controller = TextEditingController();
  final _ch6Controller = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.typeToEdit != null;
    if (_isEditing) {
      final data = widget.typeToEdit!;
      _typeFormationController.text = data['type_formation'] ?? '';
      _ch1Controller.text = data['ch1'] ?? '';
      _ch2Controller.text = data['ch2'] ?? '';
      _ch3Controller.text = data['ch3'] ?? '';
      _ch4Controller.text = data['ch4'] ?? '';
      _ch5Controller.text = data['ch5'] ?? '';
      _ch6Controller.text = data['ch6'] ?? '';
    }
  }

  @override
  void dispose() {
    _typeFormationController.dispose();
    _ch1Controller.dispose();
    _ch2Controller.dispose();
    _ch3Controller.dispose();
    _ch4Controller.dispose();
    _ch5Controller.dispose();
    _ch6Controller.dispose();
    super.dispose();
  }

  Future<void> _saveTypeFormation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final Map<String, dynamic> data = {
      'type_formation': _typeFormationController.text.trim(),
      'ch1':
          _ch1Controller.text.trim().isEmpty
              ? null
              : _ch1Controller.text.trim(),
      'ch2':
          _ch2Controller.text.trim().isEmpty
              ? null
              : _ch2Controller.text.trim(),
      'ch3':
          _ch3Controller.text.trim().isEmpty
              ? null
              : _ch3Controller.text.trim(),
      'ch4':
          _ch4Controller.text.trim().isEmpty
              ? null
              : _ch4Controller.text.trim(),
      'ch5':
          _ch5Controller.text.trim().isEmpty
              ? null
              : _ch5Controller.text.trim(),
      'ch6':
          _ch6Controller.text.trim().isEmpty
              ? null
              : _ch6Controller.text.trim(),
    };

    try {
      // ✅ CORRECTION : Ajouter le "s" à "types"
      final url =
          _isEditing
              ? Uri.parse(
                '${TrainingService.apiBaseUrl}/types-formation/${widget.typeToEdit!['id']}',
              )
              : Uri.parse('${TrainingService.apiBaseUrl}/types-formation');

      final response =
          _isEditing
              ? await http.put(
                url,
                headers: {'Content-Type': 'application/json'},
                body: json.encode(data),
              )
              : await http.post(
                url,
                headers: {'Content-Type': 'application/json'},
                body: json.encode(data),
              );

      final result = json.decode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Type de formation mis à jour avec succès'
                  : 'Type de formation créé avec succès',
            ),
            backgroundColor: const Color(0xff0D443E),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Erreur lors de l\'enregistrement',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? 'Modifier le type de formation'
              : 'Ajouter un type de formation',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xff0D443E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type formation
              _buildTextField(
                controller: _typeFormationController,
                label: 'Type de formation *',
                hint: 'Ex: En ligne, Présentiel, Hybride...',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le type de formation est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Champs CH1 à CH6
              Text(
                'Chapitres (optionnels)',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff2c221e),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Entrez les noms des chapitres associés à ce type de formation',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _ch1Controller,
                label: 'Chapitre 1',
                hint: 'Nom du chapitre 1 (optionnel)',
                validator: null,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _ch2Controller,
                label: 'Chapitre 2',
                hint: 'Nom du chapitre 2 (optionnel)',
                validator: null,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _ch3Controller,
                label: 'Chapitre 3',
                hint: 'Nom du chapitre 3 (optionnel)',
                validator: null,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _ch4Controller,
                label: 'Chapitre 4',
                hint: 'Nom du chapitre 4 (optionnel)',
                validator: null,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _ch5Controller,
                label: 'Chapitre 5',
                hint: 'Nom du chapitre 5 (optionnel)',
                validator: null,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _ch6Controller,
                label: 'Chapitre 6',
                hint: 'Nom du chapitre 6 (optionnel)',
                validator: null,
              ),
              const SizedBox(height: 32),

              // Boutons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveTypeFormation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff0D443E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                              : Text(
                                _isEditing ? 'Mettre à jour' : 'Ajouter',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xff0D443E),
                        side: const BorderSide(color: Color(0xff0D443E)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Annuler',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
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
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xff2c221e),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xff0D443E), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          style: GoogleFonts.poppins(fontSize: 14),
          validator: validator,
          onFieldSubmitted: (_) => _saveTypeFormation(),
        ),
      ],
    );
  }
}
