// lib/screens/admin/edit_formateur.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/formateur.dart';
import '../../services/training_service.dart';

class EditFormateurScreen extends StatefulWidget {
  final Formateur formateur;

  const EditFormateurScreen({super.key, required this.formateur});

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
  bool _isUploadingPhoto = false;
  // ✅ Compatible Web : bytes en mémoire au lieu de dart:io File
  Uint8List? _selectedImageBytes;

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
      // ✅ readAsBytes() fonctionne sur Web et Mobile (contrairement à dart:io File)
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
      });
      await _uploadPhoto(bytes, pickedFile.name);
    }
  }

  Future<void> _uploadPhoto(Uint8List bytes, String fileName) async {
    setState(() => _isUploadingPhoto = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // ✅ Même endpoint que add_formateur.dart : /formateurs/upload
      final uri = Uri.parse('${TrainingService.apiBaseUrl}/formateurs/upload');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      // ✅ Déterminer le Content-Type réel à partir de l'extension,
      // sinon express-fileupload reçoit "application/octet-stream" et rejette le fichier.
      final ext = fileName.split('.').last.toLowerCase();
      const mimeMap = {
        'jpg': 'jpeg',
        'jpeg': 'jpeg',
        'png': 'png',
        'webp': 'webp',
        'gif': 'gif',
      };
      final subtype = mimeMap[ext] ?? 'jpeg';

      request.files.add(
        http.MultipartFile.fromBytes(
          'photo',
          bytes,
          filename: fileName,
          contentType: MediaType('image', subtype),
        ),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final data = json.decode(responseData);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          // ✅ Le backend renvoie juste le nom de fichier (fileName), pas une URL
          _photoController.text = data['fileName'];
        });
        _showSuccessSnackBar('Photo téléchargée avec succès');
      } else {
        _showErrorSnackBar(data['message'] ?? 'Erreur lors du téléchargement');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur de téléchargement: $e');
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
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
                                color: Colors.grey[200],
                                image:
                                    _selectedImageBytes != null
                                        ? DecorationImage(
                                          image: MemoryImage(
                                            _selectedImageBytes!,
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                        : (_photoController.text.isNotEmpty
                                            ? DecorationImage(
                                              image: NetworkImage(
                                                // ✅ Reconstruit l'URL complète à partir
                                                // du nom de fichier stocké côté backend
                                                '${TrainingService.apiBaseUrl.replaceAll('/api', '')}/uploads/formateurs/${_photoController.text}',
                                              ),
                                              fit: BoxFit.cover,
                                              onError: (_, __) {},
                                            )
                                            : null),
                              ),
                              child:
                                  _isUploadingPhoto
                                      ? const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xff0D443E),
                                        ),
                                      )
                                      : (_selectedImageBytes == null &&
                                              _photoController.text.isEmpty
                                          ? const Icon(
                                            Icons.person,
                                            size: 60,
                                            color: Colors.grey,
                                          )
                                          : null),
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
                                  onPressed:
                                      _isUploadingPhoto ? null : _pickImage,
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
                            'Photo: ${_photoController.text}',
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
                        initialValue: _selectedCategorieId,
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
                                  (_isSaving || _isUploadingPhoto)
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
                              onPressed:
                                  (_isSaving || _isUploadingPhoto)
                                      ? null
                                      : _updateFormateur,
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
