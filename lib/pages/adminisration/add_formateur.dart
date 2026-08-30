// lib/pages/adminisration/add_formateur.dart
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:nafahat/pages/adminisration/admin_page_wrapper.dart';
import 'package:nafahat/services/training_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:http_parser/http_parser.dart' show MediaType;

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

  // ✅ Nouveaux champs pour la photo (compatibles Web)
  Uint8List? _imageBytes;
  String? _imageName;
  String? _photoUrl;
  bool _isUploadingPhoto = false;
  bool _isImageLoading = false;

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

  // ✅ Méthode pour choisir une photo (Web/Mobile)
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageName = image.name;
        });
        await _uploadPhoto(bytes, image.name);
      }
    } catch (e) {
      print('❌ Erreur sélection image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isArabic
                  ? 'Erreur lors de la sélection de l\'image'
                  : 'Erreur lors de la sélection de l\'image',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ Méthode pour prendre une photo avec la caméra (Web/Mobile)
  Future<void> _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageName = image.name;
        });
        await _uploadPhoto(bytes, image.name);
      }
    } catch (e) {
      print('❌ Erreur capture photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isArabic
                  ? 'Erreur lors de la capture de la photo'
                  : 'Erreur lors de la capture de la photo',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ Upload de la photo (universel)
  Future<void> _uploadPhoto(Uint8List bytes, String fileName) async {
    setState(() => _isUploadingPhoto = true);

    try {
      final uri = Uri.parse('${TrainingService.apiBaseUrl}/formateurs/upload');
      final request = http.MultipartRequest('POST', uri);

      // ✅ Déterminer le Content-Type réel à partir de l'extension,
      // sinon express-fileupload reçoit "application/octet-stream"
      // et rejette le fichier même si c'est un PNG/JPEG valide.
      final ext = fileName.split('.').last.toLowerCase();
      const mimeMap = {
        'jpg': 'jpeg',
        'jpeg': 'jpeg',
        'png': 'png',
        'webp': 'webp',
        'gif': 'gif',
      };
      final subtype = mimeMap[ext] ?? 'jpeg';

      final multipartFile = http.MultipartFile.fromBytes(
        'photo',
        bytes,
        filename: fileName,
        contentType: MediaType('image', subtype),
      );
      request.files.add(multipartFile);

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final data = json.decode(responseData);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _photoUrl = data['fileName'];
          _isImageLoading = true;
        });

        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          setState(() => _isImageLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isArabic
                    ? '✅ Photo uploadée avec succès'
                    : '✅ Photo uploadée avec succès',
              ),
              backgroundColor: nafahatGreen,
            ),
          );
        }
      } else {
        throw Exception(data['message'] ?? 'Erreur upload');
      }
    } catch (e) {
      print('❌ Erreur upload photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isArabic
                  ? 'Erreur lors de l\'upload de la photo'
                  : 'Erreur lors de l\'upload de la photo',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  // ✅ Supprimer la photo
  void _removePhoto() {
    setState(() {
      _imageBytes = null;
      _imageName = null;
      _photoUrl = null;
      _isImageLoading = false;
    });
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
            'photo': _photoUrl,
          }),
        );

        final data = json.decode(response.body);

        if (response.statusCode == 201 && data['success'] == true) {
          if (mounted) {
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
            Navigator.pop(context, true);
          }
        } else {
          if (mounted) {
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
        }
      } catch (e) {
        print('Erreur: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isArabic ? 'خطأ في الاتصال' : 'Erreur de connexion',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPageWrapper(
      title: 'Ajouter un formateur',
      titleAr: 'إضافة مكون',
      backgroundColor: Colors.grey[50]!,
      actions: [
        IconButton(
          icon: const Icon(Icons.language),
          onPressed: () => setState(() => _isArabic = !_isArabic),
          tooltip: _isArabic ? 'Français' : 'العربية',
        ),
      ],
      child: SingleChildScrollView(
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
                      _buildPhotoSection(),
                      const SizedBox(height: 16),
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
                      _buildField(
                        label: _isArabic ? 'رقم الهاتف' : 'Téléphone',
                        controller: _telephoneController,
                        hint: _isArabic ? 'مثال: 0612345678' : 'Ex: 0612345678',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      _buildCategorieDropdown(),
                      const SizedBox(height: 16),
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
                      onPressed:
                          _isLoading || _isUploadingPhoto
                              ? null
                              : _saveFormateur,
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

  Widget _buildHeader() {
    return Container(
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
            child: Icon(Icons.person_add, color: nafahatGreen, size: 28),
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
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isArabic ? 'صورة المكون' : 'Photo du formateur',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: nafahatGreen,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              _buildPhotoPreview(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isUploadingPhoto)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: LinearProgressIndicator(color: nafahatGreen),
                      ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (_imageBytes == null && _photoUrl == null) ...[
                          ElevatedButton.icon(
                            onPressed: _isUploadingPhoto ? null : _pickImage,
                            icon: const Icon(Icons.photo_library, size: 16),
                            label: Text(
                              _isArabic ? 'اختر صورة' : 'Choisir',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: nafahatGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              textStyle: TextStyle(fontSize: 12),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isUploadingPhoto ? null : _takePhoto,
                            icon: const Icon(Icons.camera_alt, size: 16),
                            label: Text(
                              _isArabic ? 'تصوير' : 'Appareil photo',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: nafahatOrange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              textStyle: TextStyle(fontSize: 12),
                            ),
                          ),
                        ] else ...[
                          OutlinedButton.icon(
                            onPressed: _isUploadingPhoto ? null : _pickImage,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: Text(
                              _isArabic ? 'تغيير' : 'Changer',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: nafahatGreen,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              textStyle: TextStyle(fontSize: 12),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _isUploadingPhoto ? null : _removePhoto,
                            icon: const Icon(Icons.delete, size: 16),
                            label: Text(
                              _isArabic ? 'حذف' : 'Supprimer',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              textStyle: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoPreview() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child:
          _isImageLoading
              ? const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: nafahatGreen,
                  ),
                ),
              )
              : _imageBytes != null
              ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _imageBytes!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.grey[400],
                    );
                  },
                ),
              )
              : _photoUrl != null
              ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  '${TrainingService.apiBaseUrl.replaceAll('/api', '')}/uploads/formateurs/$_photoUrl',
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: nafahatGreen,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.grey[400],
                    );
                  },
                ),
              )
              : Icon(Icons.person, size: 40, color: Colors.grey[400]),
    );
  }

  Widget _buildCategorieDropdown() {
    return Column(
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
              hint: Text(_isArabic ? 'اختر تصنيف' : 'Choisir une catégorie'),
              isExpanded: true,
              items: [
                const DropdownMenuItem(value: null, child: Text('---')),
                ..._categories.map((c) {
                  final label =
                      _isArabic ? c['categorie_ar'] : c['categorie_fr'];
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
