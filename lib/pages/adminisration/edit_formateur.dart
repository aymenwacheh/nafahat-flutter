// lib/screens/admin/edit_formateur.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/formateur.dart';
import '../../services/training_service.dart';

class EditFormateurScreen extends StatefulWidget {
  final Formateur formateur;

  const EditFormateurScreen({Key? key, required this.formateur})
    : super(key: key);

  @override
  State<EditFormateurScreen> createState() => _EditFormateurScreenState();
}

class _EditFormateurScreenState extends State<EditFormateurScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomPrenomFrController;
  late TextEditingController _nomPrenomArController;
  late TextEditingController _emailController;
  late TextEditingController _telephoneController;
  late TextEditingController _bioFrController;
  late TextEditingController _bioArController;
  late TextEditingController _photoController;

  int? _selectedCategorieId;
  List<dynamic> _categories = [];
  bool _isLoading = false;
  bool _isSaving = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _nomPrenomFrController = TextEditingController(
      text: widget.formateur.nomPrenomFr,
    );
    _nomPrenomArController = TextEditingController(
      text: widget.formateur.nomPrenomAr,
    );
    _emailController = TextEditingController(
      text: widget.formateur.email ?? '',
    );
    _telephoneController = TextEditingController(
      text: widget.formateur.telephone ?? '',
    );
    _bioFrController = TextEditingController(
      text: widget.formateur.bioFr ?? '',
    );
    _bioArController = TextEditingController(
      text: widget.formateur.bioAr ?? '',
    );
    _photoController = TextEditingController(
      text: widget.formateur.photo ?? '',
    );
    _selectedCategorieId = widget.formateur.idCategorie;
    _fetchCategories();
  }

  @override
  void dispose() {
    _nomPrenomFrController.dispose();
    _nomPrenomArController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _bioFrController.dispose();
    _bioArController.dispose();
    _photoController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('${TrainingService.apiBaseUrl}/categories'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _categories = data['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Erreur lors du chargement des catégories');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Erreur de connexion');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${TrainingService.apiBaseUrl}/upload'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath('image', _selectedImage!.path),
      );

      var response = await request.send();
      var responseData = await response.stream.toBytes();
      var responseString = String.fromCharCodes(responseData);

      if (response.statusCode == 200) {
        final data = json.decode(responseString);
        setState(() {
          _photoController.text = data['data']['url'];
        });
        _showSuccessSnackBar('Image téléchargée avec succès');
      } else {
        _showErrorSnackBar('Erreur lors du téléchargement de l\'image');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur de téléchargement');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _updateFormateur() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final data = {
        'nom_prenom_fr': _nomPrenomFrController.text.trim(),
        'nom_prenom_ar': _nomPrenomArController.text.trim(),
        'email': _emailController.text.trim(),
        'telephone': _telephoneController.text.trim(),
        'bio_fr': _bioFrController.text.trim(),
        'bio_ar': _bioArController.text.trim(),
        'id_categorie': _selectedCategorieId,
        'photo': _photoController.text.trim(),
      };

      final response = await http.put(
        Uri.parse(
          '${TrainingService.apiBaseUrl}/formateurs/${widget.formateur.id}',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      );

      setState(() => _isSaving = false);

      if (response.statusCode == 200) {
        _showSuccessSnackBar('Formateur mis à jour avec succès');
        Navigator.pop(context, true);
      } else {
        final errorData = json.decode(response.body);
        _showErrorSnackBar(
          errorData['message'] ?? 'Erreur lors de la mise à jour',
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showErrorSnackBar('Erreur de connexion');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le formateur'),
        backgroundColor: const Color(0xff0D443E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xff0D443E),
                                  width: 3,
                                ),
                                image:
                                    _selectedImage != null
                                        ? DecorationImage(
                                          image: FileImage(_selectedImage!),
                                          fit: BoxFit.cover,
                                        )
                                        : (_photoController.text.isNotEmpty
                                            ? DecorationImage(
                                              image: NetworkImage(
                                                '${TrainingService.apiBaseUrl}/${_photoController.text}',
                                              ),
                                              fit: BoxFit.cover,
                                              onError:
                                                  (_, __) => const Icon(
                                                    Icons.person,
                                                    size: 60,
                                                    color: Colors.grey,
                                                  ),
                                            )
                                            : null),
                              ),
                              child:
                                  _selectedImage == null &&
                                          _photoController.text.isEmpty
                                      ? const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.grey,
                                      )
                                      : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xff0D443E),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: _pickImage,
                                  padding: const EdgeInsets.all(8),
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (_photoController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'URL: ${_photoController.text}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Nom Prénom FR
                      TextFormField(
                        controller: _nomPrenomFrController,
                        decoration: InputDecoration(
                          labelText: 'Nom et prénom (Français) *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ce champ est requis';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Nom Prénom AR
                      TextFormField(
                        controller: _nomPrenomArController,
                        decoration: InputDecoration(
                          labelText: 'الإسم واللقب (العربية) *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        textDirection: TextDirection.rtl,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'هذا الحقل مطلوب';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value)) {
                              return 'Email invalide';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Téléphone
                      TextFormField(
                        controller: _telephoneController,
                        decoration: InputDecoration(
                          labelText: 'Téléphone',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      // Catégorie
                      DropdownButtonFormField<int>(
                        value: _selectedCategorieId,
                        decoration: InputDecoration(
                          labelText: 'Catégorie',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.category),
                        ),
                        items:
                            _categories.map((categorie) {
                              return DropdownMenuItem<int>(
                                value: categorie['id'],
                                child: Text(
                                  categorie['categorie_fr'] ??
                                      categorie['categorie_ar'] ??
                                      'Sans catégorie',
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategorieId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Bio FR
                      TextFormField(
                        controller: _bioFrController,
                        decoration: InputDecoration(
                          labelText: 'Biographie (Français)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.description),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Bio AR
                      TextFormField(
                        controller: _bioArController,
                        decoration: InputDecoration(
                          labelText: 'السيرة الذاتية (العربية)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.description_outlined),
                        ),
                        maxLines: 3,
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 24),

                      // Boutons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed:
                                  _isSaving
                                      ? null
                                      : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Annuler'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _updateFormateur,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff0D443E),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child:
                                  _isSaving
                                      ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                      : const Text('Enregistrer'),
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
