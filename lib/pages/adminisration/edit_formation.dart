// lib/pages/adminisration/edit_formation.dart
import 'dart:typed_data';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:nafahat/models/cible_model.dart';
import 'package:nafahat/services/cible_service.dart';
import 'package:nafahat/services/training_service.dart';
import 'package:nafahat/services/upload_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;

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

  // Contrôleurs principaux
  final _titleFrController = TextEditingController();
  final _titleArController = TextEditingController();
  final _descriptionFrController = TextEditingController();
  final _descriptionArController = TextEditingController();
  final _targetController = TextEditingController();
  final _imageUrlController = TextEditingController();

  // Prix multi-devises
  final _priceDtController = TextEditingController();
  final _priceEurController = TextEditingController();
  final _priceUsdController = TextEditingController();

  // Autres contrôleurs
  final _discountValueController = TextEditingController();
  final TextEditingController _dateDebutController = TextEditingController();
  final TextEditingController _dateFinController = TextEditingController();
  final TextEditingController _nbrHeurController = TextEditingController();
  final TextEditingController _nbrSeanceController = TextEditingController();
  final TextEditingController _nbrJourController = TextEditingController();

  // États
  bool _hasDiscount = false;
  bool _isPercentageDiscount = true;
  bool _isRepetitive = false;

  // États pour l'image
  dynamic _selectedImageFile;
  bool _isUploadingImage = false;
  String? _uploadedImageUrl;
  Uint8List? _imageBytes;
  String? _imageName;

  // Sélections
  int? _selectedTypeFormationId;
  int? _selectedDureeId;
  int? _selectedCategorieId;
  int? _selectedSousCategorieId;
  int? _selectedFormateurId;
  int? _selectedCibleId;
  String? _currentActif;

  // Jours de la semaine
  final Map<String, bool> _joursSemaine = {
    'lundi': false,
    'mardi': false,
    'mercredi': false,
    'jeudi': false,
    'vendredi': false,
    'samedi': false,
    'dimanche': false,
  };

  // Listes
  List<Map<String, dynamic>> _typesFormation = [];
  List<Map<String, dynamic>> _durees = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _allSousCategories = [];
  List<Map<String, dynamic>> _filteredSousCategories = [];
  List<Map<String, dynamic>> _formateurs = [];
  List<CibleModel> _cibles = [];

  // Couleurs
  static const Color nafahatGreen = Color(0xff0D443E);
  static const Color nafahatOrange = Color(0xffd57653);
  static const Color nafahatGold = Color(0xffC4A46C);

  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);

  final Map<String, String> _joursFr = {
    'lundi': 'Lundi',
    'mardi': 'Mardi',
    'mercredi': 'Mercredi',
    'jeudi': 'Jeudi',
    'vendredi': 'Vendredi',
    'samedi': 'Samedi',
    'dimanche': 'Dimanche',
  };

  final Map<String, String> _joursAr = {
    'lundi': 'الإثنين',
    'mardi': 'الثلاثاء',
    'mercredi': 'الأربعاء',
    'jeudi': 'الخميس',
    'vendredi': 'الجمعة',
    'samedi': 'السبت',
    'dimanche': 'الأحد',
  };

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
      final sousCategories = await _loadSousCategories();
      final cibles = await CibleService.getCibles();

      // Récupérer la formation
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
        _allSousCategories = sousCategories;
        _filteredSousCategories = _filterSousCategories(_selectedCategorieId);
        _cibles = cibles;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Erreur chargement données: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _loadSousCategories() async {
    try {
      final response = await http.get(
        Uri.parse('${TrainingService.apiBaseUrl}/categories/sous-categories'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Erreur chargement sous-catégories: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _filterSousCategories(int? categorieId) {
    if (categorieId == null) return [];
    return _allSousCategories
        .where((sc) => sc['id_categorie'] == categorieId)
        .toList();
  }

  void _onCategorieChanged(dynamic value) {
    setState(() {
      _selectedCategorieId = value as int?;
      _selectedSousCategorieId = null;
      _filteredSousCategories = _filterSousCategories(_selectedCategorieId);
    });
  }

  void _populateForm(Map<String, dynamic> formation) {
    _titleFrController.text = formation['titre_fr'] ?? '';
    _titleArController.text = formation['titre_ar'] ?? '';
    _selectedTypeFormationId = formation['id_type_formation'];
    _selectedDureeId = formation['id_duree'];
    _selectedCibleId = formation['id_cible'];
    _selectedCategorieId = formation['id_categorie'];
    _selectedSousCategorieId = formation['id_sous_categorie'];
    _selectedFormateurId = formation['id_formateur'];

    _descriptionFrController.text = formation['descri_fr'] ?? '';
    _descriptionArController.text = formation['descri_ar'] ?? '';

    // Prix multi-devises
    _priceDtController.text = formation['prix_dt']?.toString() ?? '0';
    _priceEurController.text = formation['prix_eur']?.toString() ?? '0';
    _priceUsdController.text = formation['prix_usd']?.toString() ?? '0';

    // Image
    if (formation['photo'] != null && formation['photo'].isNotEmpty) {
      _uploadedImageUrl = formation['photo'];
      _imageUrlController.text = formation['photo'];
    }

    // Discount
    _hasDiscount = formation['discount'] == 'oui';
    if (_hasDiscount && formation['valeur_disc'] != null) {
      _discountValueController.text = formation['valeur_disc'].toString();
    }

    // Dates
    final periode = formation['periode'] ?? '';
    if (periode.isNotEmpty) {
      final parts = periode.split(' - ');
      if (parts.length == 2) {
        _dateDebutController.text = parts[0].trim();
        _dateFinController.text = parts[1].trim();
      }
    }

    // Nombre d'heures, séances, jours
    _nbrHeurController.text = formation['nbr_heur']?.toString() ?? '';
    _nbrSeanceController.text = formation['nbr_seance']?.toString() ?? '';
    _nbrJourController.text = formation['nbr_jour']?.toString() ?? '';

    // Répétitive
    _isRepetitive = formation['repetitive'] == 'oui';
    if (_isRepetitive && formation['jour_semaine'] != null) {
      try {
        final jours = json.decode(formation['jour_semaine']);
        if (jours is List) {
          for (var jour in jours) {
            if (_joursSemaine.containsKey(jour)) {
              _joursSemaine[jour] = true;
            }
          }
        }
      } catch (e) {
        debugPrint('Erreur parsing jours: $e');
      }
    }

    _currentActif = formation['actif'] ?? 'oui';
  }

  @override
  void dispose() {
    _titleFrController.dispose();
    _titleArController.dispose();
    _descriptionFrController.dispose();
    _descriptionArController.dispose();
    _targetController.dispose();
    _imageUrlController.dispose();
    _priceDtController.dispose();
    _priceEurController.dispose();
    _priceUsdController.dispose();
    _discountValueController.dispose();
    _dateDebutController.dispose();
    _dateFinController.dispose();
    _nbrHeurController.dispose();
    _nbrSeanceController.dispose();
    _nbrJourController.dispose();
    super.dispose();
  }

  // ==================== MÉTHODES DE SÉLECTION D'IMAGE ====================
  Future<void> _pickImageWeb() async {
    try {
      setState(() => _isUploadingImage = true);
      final input = html.FileUploadInputElement();
      input.accept = 'image/*';
      input.multiple = false;
      input.click();
      await input.onChange.first;

      if (input.files != null && input.files!.isNotEmpty) {
        final file = input.files!.first;
        final reader = html.FileReader();
        reader.readAsDataUrl(file);
        await reader.onLoad.first;

        setState(() {
          _imageName = file.name;
        });

        await _uploadImageWeb(file);
      } else {
        setState(() => _isUploadingImage = false);
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      _showErrorSnackBar(
        _isArabic ? '❌ Erreur sélection image' : '❌ Erreur sélection image',
      );
      debugPrint('❌ Erreur sélection image: $e');
    }
  }

  Future<void> _pickImageMobile() async {
    try {
      setState(() => _isUploadingImage = true);
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        await _uploadImageMobile(imageFile);
      } else {
        setState(() => _isUploadingImage = false);
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      _showErrorSnackBar(
        _isArabic ? '❌ Erreur sélection image' : '❌ Erreur sélection image',
      );
      debugPrint('❌ Erreur sélection image: $e');
    }
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      await _pickImageWeb();
    } else {
      await _pickImageMobile();
    }
  }

  Future<void> _uploadImageWeb(html.File file) async {
    try {
      setState(() {
        _selectedImageFile = file;
        _isUploadingImage = true;
      });

      final result = await UploadService.uploadImageSmart(file);

      if (result['success'] == true) {
        setState(() {
          _uploadedImageUrl = result['image_url'];
          _imageUrlController.text = result['image_url'];
          _isUploadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isArabic ? '✅ Image téléchargée' : '✅ Image téléchargée',
            ),
            backgroundColor: nafahatGreen,
          ),
        );
      } else {
        setState(() => _isUploadingImage = false);
        throw Exception(result['message'] ?? 'Upload failed');
      }
    } catch (e) {
      setState(() {
        _selectedImageFile = null;
        _isUploadingImage = false;
      });
      _showErrorSnackBar(_isArabic ? '❌ Erreur upload' : '❌ Erreur upload');
      debugPrint('❌ Erreur upload image: $e');
    }
  }

  Future<void> _uploadImageMobile(File imageFile) async {
    try {
      setState(() {
        _selectedImageFile = imageFile;
        _isUploadingImage = true;
      });

      final result = await TrainingService.uploadImage(imageFile);

      if (result['success'] == true) {
        setState(() {
          _uploadedImageUrl = result['image_url'];
          _imageUrlController.text = result['image_url'];
          _isUploadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isArabic ? '✅ Image téléchargée' : '✅ Image téléchargée',
            ),
            backgroundColor: nafahatGreen,
          ),
        );
      } else {
        setState(() => _isUploadingImage = false);
        throw Exception(result['message'] ?? 'Upload failed');
      }
    } catch (e) {
      setState(() {
        _selectedImageFile = null;
        _isUploadingImage = false;
      });
      _showErrorSnackBar(_isArabic ? '❌ Erreur upload' : '❌ Erreur upload');
      debugPrint('❌ Erreur upload image: $e');
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImageFile = null;
      _uploadedImageUrl = null;
      _imageUrlController.clear();
      _imageBytes = null;
      _imageName = null;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final locale =
        _isArabic ? const Locale('ar', 'AR') : const Locale('fr', 'FR');

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: locale,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: nafahatGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.toLocal().toString().split(' ')[0];
      });
    }
  }

  String _getSelectedJours() {
    final selected =
        _joursSemaine.entries.where((e) => e.value).map((e) => e.key).toList();
    return jsonEncode(selected);
  }

  Future<void> _saveTraining() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      final requestBody = {
        'titre_fr': _titleFrController.text,
        'titre_ar': _titleArController.text,
        'id_type_formation': _selectedTypeFormationId,
        'id_cible': _selectedCibleId,
        'cible_fr': null,
        'cible_ar': null,
        'id_duree': _selectedDureeId,
        'date_debut':
            _dateDebutController.text.isNotEmpty
                ? _dateDebutController.text
                : null,
        'date_fin':
            _dateFinController.text.isNotEmpty ? _dateFinController.text : null,
        'prix': double.parse(_priceDtController.text),
        'prix_dt': double.parse(_priceDtController.text),
        'prix_eur': double.parse(_priceEurController.text),
        'prix_usd': double.parse(_priceUsdController.text),
        'discount': _hasDiscount ? 'oui' : 'non',
        'valeur_disc':
            _hasDiscount ? double.parse(_discountValueController.text) : null,
        'descri_fr': _descriptionFrController.text,
        'descri_ar': _descriptionArController.text,
        'id_categorie': _selectedCategorieId,
        'sous_categorie_id': _selectedSousCategorieId,
        'id_formateur': _selectedFormateurId,
        'photo':
            _imageUrlController.text.isNotEmpty
                ? _imageUrlController.text
                : null,
        'nbr_heur':
            _nbrHeurController.text.isNotEmpty
                ? int.parse(_nbrHeurController.text)
                : null,
        'nbr_seance':
            _nbrSeanceController.text.isNotEmpty
                ? int.parse(_nbrSeanceController.text)
                : null,
        'nbr_jour':
            _nbrJourController.text.isNotEmpty
                ? int.parse(_nbrJourController.text)
                : null,
        'repetitive': _isRepetitive ? 'oui' : 'non',
        'jour_semaine': _isRepetitive ? _getSelectedJours() : null,
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
                    ? '✅ تم تحديث التكوين "${_titleArController.text}" بنجاح!'
                    : '✅ Formation "${_titleFrController.text}" mise à jour avec succès!',
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
                    ? '❌ خطأ في تحديث التكوين'
                    : '❌ Erreur lors de la mise à jour',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isArabic ? '❌ خطأ في الاتصال' : '❌ Erreur de connexion',
            ),
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
                    ? '✅ تم حذف التكوين بنجاح'
                    : '✅ Formation supprimée avec succès',
              ),
              backgroundColor: nafahatGreen,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        debugPrint('❌ Erreur suppression: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isArabic ? '❌ Erreur suppression' : '❌ Erreur suppression',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: grey50,
      appBar: AppBar(
        title: Text(
          _isArabic ? 'تعديل تكوين' : 'Modifier une formation',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: nafahatGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.language),
              onPressed: () => setState(() => _isArabic = !_isArabic),
              tooltip: _isArabic ? 'Français' : 'العربية',
            ),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 24,
                  vertical: 16,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),

                      Card(
                        elevation: 4,
                        shadowColor: nafahatGreen.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(isMobile ? 16 : 24),
                          child: Column(
                            children: [
                              // SECTION 1: Informations de base
                              _buildSection(
                                icon: Icons.info_outline,
                                title:
                                    _isArabic
                                        ? 'معلومات أساسية'
                                        : 'Informations de base',
                                children: [
                                  _buildField(
                                    label:
                                        _isArabic
                                            ? 'العنوان (بالفرنسية) *'
                                            : 'Titre (Français) *',
                                    controller: _titleFrController,
                                    hint:
                                        _isArabic
                                            ? 'مثال: Formation Flutter avancé'
                                            : 'Ex: Formation Flutter avancé',
                                    required: true,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildField(
                                    label:
                                        _isArabic
                                            ? 'العنوان (بالعربية) *'
                                            : 'Titre (Arabe) *',
                                    controller: _titleArController,
                                    hint:
                                        _isArabic
                                            ? 'مثال: دورة فلاتر المتقدمة'
                                            : 'Ex: دورة فلاتر المتقدمة',
                                    required: true,
                                    textDirection: TextDirection.rtl,
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildDropdownField(
                                          label:
                                              _isArabic
                                                  ? 'نوع التكوين *'
                                                  : 'Type de formation *',
                                          value: _selectedTypeFormationId,
                                          items:
                                              _typesFormation.map((t) {
                                                return DropdownMenuItem<int>(
                                                  value: t['id'],
                                                  child: Text(
                                                    t['type_formation'] ?? '',
                                                  ),
                                                );
                                              }).toList(),
                                          onChanged:
                                              (value) => setState(
                                                () =>
                                                    _selectedTypeFormationId =
                                                        value as int?,
                                              ),
                                          required: true,
                                          isArabic: _isArabic,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildDropdownField(
                                          label:
                                              _isArabic ? 'المدة *' : 'Durée *',
                                          value: _selectedDureeId,
                                          items:
                                              _durees.map((d) {
                                                return DropdownMenuItem<int>(
                                                  value: d['id'],
                                                  child: Text(
                                                    d['type_duree'] ?? '',
                                                  ),
                                                );
                                              }).toList(),
                                          onChanged:
                                              (value) => setState(
                                                () =>
                                                    _selectedDureeId =
                                                        value as int?,
                                              ),
                                          required: true,
                                          isArabic: _isArabic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const Divider(height: 32, color: grey200),

                              // SECTION 2: Catégories
                              _buildSection(
                                icon: Icons.category_outlined,
                                title: _isArabic ? 'التصنيفات' : 'Catégories',
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildDropdownField(
                                          label:
                                              _isArabic
                                                  ? 'التصنيف'
                                                  : 'Catégorie',
                                          value: _selectedCategorieId,
                                          items: [
                                            const DropdownMenuItem<int>(
                                              value: null,
                                              child: Text('---'),
                                            ),
                                            ..._categories.map((c) {
                                              final label =
                                                  _isArabic
                                                      ? c['categorie_ar']
                                                      : c['categorie_fr'];
                                              return DropdownMenuItem<int>(
                                                value: c['id'],
                                                child: Text(label ?? ''),
                                              );
                                            }),
                                          ],
                                          onChanged: _onCategorieChanged,
                                          required: false,
                                          isArabic: _isArabic,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildDropdownField(
                                          label:
                                              _isArabic
                                                  ? 'التصنيف الفرعي'
                                                  : 'Sous-catégorie',
                                          value: _selectedSousCategorieId,
                                          items: [
                                            const DropdownMenuItem<int>(
                                              value: null,
                                              child: Text('---'),
                                            ),
                                            ..._filteredSousCategories.map((
                                              sc,
                                            ) {
                                              final label =
                                                  _isArabic
                                                      ? sc['nom_ar']
                                                      : sc['nom_fr'];
                                              return DropdownMenuItem<int>(
                                                value: sc['id'],
                                                child: Text(label ?? ''),
                                              );
                                            }),
                                          ],
                                          onChanged:
                                              (value) => setState(
                                                () =>
                                                    _selectedSousCategorieId =
                                                        value as int?,
                                              ),
                                          required: false,
                                          isArabic: _isArabic,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildDropdownField(
                                    label: _isArabic ? 'المكون' : 'Formateur',
                                    value: _selectedFormateurId,
                                    items: [
                                      const DropdownMenuItem<int>(
                                        value: null,
                                        child: Text('---'),
                                      ),
                                      ..._formateurs.map((f) {
                                        final label =
                                            _isArabic
                                                ? f['nom_prenom_ar']
                                                : f['nom_prenom_fr'];
                                        return DropdownMenuItem<int>(
                                          value: f['id'],
                                          child: Text(label ?? ''),
                                        );
                                      }),
                                    ],
                                    onChanged:
                                        (value) => setState(
                                          () =>
                                              _selectedFormateurId =
                                                  value as int?,
                                        ),
                                    required: false,
                                    isArabic: _isArabic,
                                  ),
                                ],
                              ),

                              const Divider(height: 32, color: grey200),

                              // SECTION 3: Détails de la durée
                              _buildSection(
                                icon: Icons.timer_outlined,
                                title:
                                    _isArabic
                                        ? 'تفاصيل المدة'
                                        : 'Détails de la durée',
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildField(
                                          label:
                                              _isArabic ? 'Heures' : 'Heures',
                                          controller: _nbrHeurController,
                                          hint:
                                              _isArabic ? 'مثال: 20' : 'Ex: 20',
                                          keyboardType: TextInputType.number,
                                          prefixIcon: Icons.access_time_rounded,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildField(
                                          label:
                                              _isArabic ? 'Séances' : 'Séances',
                                          controller: _nbrSeanceController,
                                          hint:
                                              _isArabic ? 'مثال: 10' : 'Ex: 10',
                                          keyboardType: TextInputType.number,
                                          prefixIcon:
                                              Icons.people_outline_rounded,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildField(
                                          label: _isArabic ? 'Jours' : 'Jours',
                                          controller: _nbrJourController,
                                          hint: _isArabic ? 'مثال: 5' : 'Ex: 5',
                                          keyboardType: TextInputType.number,
                                          prefixIcon:
                                              Icons.calendar_today_rounded,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const Divider(height: 32, color: grey200),

                              // SECTION 4: Répétition
                              _buildSection(
                                icon: Icons.repeat_rounded,
                                title: _isArabic ? 'التكرار' : 'Répétition',
                                children: [_buildRepetitiveSection()],
                              ),

                              const Divider(height: 32, color: grey200),

                              // SECTION 5: Période
                              _buildSection(
                                icon: Icons.calendar_month_rounded,
                                title: _isArabic ? 'الفترة' : 'Période',
                                children: [
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
                                              () => _selectDate(
                                                _dateDebutController,
                                              ),
                                          required: true,
                                          isArabic: _isArabic,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildDateField(
                                          label:
                                              _isArabic
                                                  ? 'تاريخ النهاية *'
                                                  : 'Date de fin *',
                                          controller: _dateFinController,
                                          onTap:
                                              () => _selectDate(
                                                _dateFinController,
                                              ),
                                          required: true,
                                          isArabic: _isArabic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const Divider(height: 32, color: grey200),

                              // SECTION 6: Description
                              _buildSection(
                                icon: Icons.description_outlined,
                                title: _isArabic ? 'الوصف' : 'Description',
                                children: [
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
                                  const SizedBox(height: 16),
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
                                ],
                              ),

                              const Divider(height: 32, color: grey200),

                              // SECTION 7: PRIX ET CIBLE
                              _buildSection(
                                icon: Icons.payments_outlined,
                                title:
                                    _isArabic
                                        ? 'السعر والجمهور'
                                        : 'Prix et Cible',
                                children: [
                                  _buildDropdownField(
                                    label:
                                        _isArabic
                                            ? 'الجمهور المستهدف *'
                                            : 'Cible *',
                                    value: _selectedCibleId,
                                    items: [
                                      const DropdownMenuItem<int>(
                                        value: null,
                                        child: Text('---'),
                                      ),
                                      ..._cibles.map((cible) {
                                        return DropdownMenuItem<int>(
                                          value: cible.id,
                                          child: Text(
                                            cible.nomCible,
                                            style: GoogleFonts.cairo(),
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                    onChanged:
                                        (value) => setState(
                                          () =>
                                              _selectedCibleId = value as int?,
                                        ),
                                    required: true,
                                    isArabic: _isArabic,
                                  ),
                                  const SizedBox(height: 16),

                                  // PRIX DT
                                  _buildField(
                                    label:
                                        _isArabic
                                            ? 'السعر (DT) *'
                                            : 'Prix (DT) *',
                                    controller: _priceDtController,
                                    hint:
                                        _isArabic ? 'مثال: 15000' : 'Ex: 15000',
                                    required: true,
                                    keyboardType: TextInputType.number,
                                    prefixIcon: Icons.money_rounded,
                                  ),
                                  const SizedBox(height: 12),

                                  // PRIX EURO
                                  _buildField(
                                    label:
                                        _isArabic
                                            ? 'السعر (€) *'
                                            : 'Prix (€) *',
                                    controller: _priceEurController,
                                    hint: _isArabic ? 'مثال: 450' : 'Ex: 450',
                                    required: true,
                                    keyboardType: TextInputType.number,
                                    prefixIcon: Icons.euro_rounded,
                                  ),
                                  const SizedBox(height: 12),

                                  // PRIX USD
                                  _buildField(
                                    label:
                                        _isArabic
                                            ? 'السعر (\$) *'
                                            : 'Prix (\$) *',
                                    controller: _priceUsdController,
                                    hint: _isArabic ? 'مثال: 550' : 'Ex: 550',
                                    required: true,
                                    keyboardType: TextInputType.number,
                                    prefixIcon: Icons.attach_money_rounded,
                                  ),
                                  const SizedBox(height: 16),

                                  _buildDiscountSection(),
                                ],
                              ),

                              const Divider(height: 32, color: grey200),

                              // SECTION 8: IMAGE
                              _buildImageSection(),

                              const Divider(height: 32, color: grey200),

                              // SECTION 9: STATUT
                              _buildSection(
                                icon: Icons.toggle_on_outlined,
                                title: _isArabic ? 'الحالة' : 'Statut',
                                children: [
                                  _buildDropdownField(
                                    label: _isArabic ? 'الحالة' : 'Statut',
                                    value: _currentActif,
                                    items: [
                                      const DropdownMenuItem<String>(
                                        value: 'oui',
                                        child: Text('Actif'),
                                      ),
                                      const DropdownMenuItem<String>(
                                        value: 'non',
                                        child: Text('Inactif'),
                                      ),
                                    ],
                                    onChanged:
                                        (value) => setState(
                                          () =>
                                              _currentActif = value as String?,
                                        ),
                                    required: false,
                                    isArabic: _isArabic,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // BOUTONS
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed:
                                  _isSaving
                                      ? null
                                      : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: nafahatGreen,
                                side: BorderSide(color: nafahatGreen),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: nafahatGreen,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(_isArabic ? 'إلغاء' : 'Annuler'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveTraining,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: nafahatGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 4,
                                shadowColor: nafahatGreen.withOpacity(0.3),
                              ),
                              child:
                                  _isSaving
                                      ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                      : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.check_circle_rounded,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _isArabic
                                                ? 'حفظ التغييرات'
                                                : 'Enregistrer',
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
                      const SizedBox(height: 16),

                      // BOUTON SUPPRIMER
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isSaving ? null : _deleteFormation,
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: Text(
                            _isArabic
                                ? 'حذف هذا التكوين'
                                : 'Supprimer cette formation',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: BorderSide(color: Colors.red.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
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

  // ==================== SECTION IMAGE ====================
  Widget _buildImageSection() {
    final bool hasImage =
        _selectedImageFile != null ||
        (_imageUrlController.text.isNotEmpty && _uploadedImageUrl != null);

    return _buildSection(
      icon: Icons.image_outlined,
      title: _isArabic ? 'الصورة' : 'Image',
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              flex: 3,
              child: _buildField(
                label: _isArabic ? 'رابط الصورة' : 'URL de l\'image',
                controller: _imageUrlController,
                hint:
                    _isArabic
                        ? 'URL ou sélectionnez une image'
                        : 'URL ou sélectionnez une image',
                prefixIcon: Icons.link_rounded,
                readOnly: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _isUploadingImage ? null : _pickImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: nafahatGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: const Size(double.infinity, 40),
                      textStyle: GoogleFonts.cairo(fontSize: 12),
                    ),
                    icon:
                        _isUploadingImage
                            ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(Icons.folder_open_rounded, size: 16),
                    label: Text(
                      _isUploadingImage
                          ? (_isArabic ? 'جاري...' : 'Chargement...')
                          : (_isArabic ? 'تصفح' : 'Parcourir'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        if (hasImage) ...[
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: nafahatGreen.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _getImagePreview(),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _removeImage,
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 18,
              ),
              label: Text(
                _isArabic ? 'إزالة الصورة' : 'Supprimer l\'image',
                style: GoogleFonts.cairo(color: Colors.red),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ==================== APERÇU DE L'IMAGE ====================
  Widget _getImagePreview() {
    if (_selectedImageFile is File && _selectedImageFile != null) {
      return Image.file(
        _selectedImageFile as File,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }

    if (_selectedImageFile is html.File && _selectedImageFile != null) {
      final file = _selectedImageFile as html.File;
      final url = html.Url.createObjectUrl(file);
      return Image.network(
        url,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 180,
            color: grey100,
            child: Center(
              child: CircularProgressIndicator(
                value:
                    loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                color: nafahatGreen,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 180,
            color: grey200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, color: grey400, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    _isArabic ? '❌ صورة غير صالحة' : '❌ Image invalide',
                    style: GoogleFonts.cairo(color: grey600),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    if (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty) {
      return Image.network(
        _uploadedImageUrl!,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 180,
            color: grey100,
            child: Center(
              child: CircularProgressIndicator(
                value:
                    loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                color: nafahatGreen,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 180,
            color: grey200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, color: grey400, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    _isArabic ? '❌ صورة غير صالحة' : '❌ Image invalide',
                    style: GoogleFonts.cairo(color: grey600),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  // ==================== WIDGETS ====================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [nafahatGreen, nafahatGreen],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: nafahatGreen.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isArabic ? 'تعديل تكوين' : 'Modifier la formation',
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _isArabic
                      ? 'قم بتعديل معلومات التكوين'
                      : 'Modifiez les informations de la formation',
                  style: GoogleFonts.cairo(
                    color: Colors.white.withOpacity(0.8),
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

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: nafahatGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: nafahatGreen, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: nafahatGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildRepetitiveSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isRepetitive ? nafahatGreen.withOpacity(0.05) : grey50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isRepetitive ? nafahatGreen : grey300,
          width: _isRepetitive ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.repeat_rounded,
                    color: _isRepetitive ? nafahatGreen : grey600,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isArabic ? 'تكوين متكرر' : 'Formation répétitive',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _isRepetitive ? nafahatGreen : grey600,
                    ),
                  ),
                ],
              ),
              Switch(
                value: _isRepetitive,
                onChanged: (value) => setState(() => _isRepetitive = value),
                activeColor: nafahatGreen,
                activeTrackColor: nafahatGreen.withOpacity(0.3),
              ),
            ],
          ),
          if (_isRepetitive) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: grey200),
              ),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children:
                    _joursSemaine.keys.map((key) {
                      final label = _isArabic ? _joursAr[key] : _joursFr[key];
                      final isSelected = _joursSemaine[key]!;
                      return ChoiceChip(
                        label: Text(
                          label ?? key,
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? Colors.white : nafahatGreen,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _joursSemaine[key] = selected;
                          });
                        },
                        selectedColor: nafahatGreen,
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: isSelected ? nafahatGreen : grey300,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        labelStyle: GoogleFonts.cairo(),
                        avatar:
                            isSelected
                                ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.white,
                                  size: 16,
                                )
                                : null,
                      );
                    }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDiscountSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: nafahatOrange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _hasDiscount ? nafahatOrange : grey200,
          width: _hasDiscount ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.local_offer_rounded,
                    color: _hasDiscount ? nafahatOrange : grey600,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isArabic ? 'تفعيل الخصم' : 'Activer la réduction',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _hasDiscount ? nafahatOrange : grey600,
                    ),
                  ),
                ],
              ),
              Switch(
                value: _hasDiscount,
                onChanged: (value) => setState(() => _hasDiscount = value),
                activeColor: nafahatOrange,
                activeTrackColor: nafahatOrange.withOpacity(0.3),
              ),
            ],
          ),
          if (_hasDiscount) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isArabic ? 'نوع الخصم' : 'Type de réduction',
                        style: GoogleFonts.cairo(fontSize: 12, color: grey600),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<bool>(
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.resolveWith((
                            states,
                          ) {
                            if (states.contains(WidgetState.selected)) {
                              return nafahatOrange.withOpacity(0.15);
                            }
                            return grey100;
                          }),
                          foregroundColor: WidgetStateProperty.resolveWith((
                            states,
                          ) {
                            if (states.contains(WidgetState.selected)) {
                              return nafahatOrange;
                            }
                            return grey600;
                          }),
                        ),
                        segments: [
                          ButtonSegment(
                            value: true,
                            icon: const Icon(Icons.percent_rounded, size: 16),
                            label: Text(
                              _isArabic ? 'نسبة' : 'Pourcentage',
                              style: GoogleFonts.cairo(),
                            ),
                          ),
                          ButtonSegment(
                            value: false,
                            icon: const Icon(Icons.money_rounded, size: 16),
                            label: Text(
                              _isArabic ? 'مبلغ' : 'Montant',
                              style: GoogleFonts.cairo(),
                            ),
                          ),
                        ],
                        selected: {_isPercentageDiscount},
                        onSelectionChanged: (Set<bool> newSelection) {
                          setState(
                            () => _isPercentageDiscount = newSelection.first,
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
                            ? (_isArabic ? 'نسبة الخصم (%)' : 'Valeur (%)')
                            : (_isArabic ? 'قيمة الخصم (درهم)' : 'Valeur (DH)'),
                    controller: _discountValueController,
                    hint: _isPercentageDiscount ? '15' : '2000',
                    required: _hasDiscount,
                    keyboardType: TextInputType.number,
                    prefixIcon:
                        _isPercentageDiscount
                            ? Icons.percent_rounded
                            : Icons.money_rounded,
                  ),
                ),
              ],
            ),
          ],
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
    IconData? prefixIcon,
    bool readOnly = false,
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
          textDirection: textDirection,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          style: GoogleFonts.cairo(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.cairo(color: grey400),
            filled: true,
            fillColor: readOnly ? grey100 : Colors.white,
            prefixIcon:
                prefixIcon != null
                    ? Icon(
                      prefixIcon,
                      color: nafahatGreen.withOpacity(0.6),
                      size: 20,
                    )
                    : null,
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
              return _isArabic ? '⚠️ حقل مطلوب' : '⚠️ Champ requis';
            }
            if (keyboardType == TextInputType.number &&
                value != null &&
                value.isNotEmpty &&
                double.tryParse(value) == null) {
              return _isArabic ? '⚠️ رقم غير صالح' : '⚠️ Nombre invalide';
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
        GestureDetector(
          onTap: onTap,
          child: AbsorbPointer(
            child: TextFormField(
              controller: controller,
              style: GoogleFonts.cairo(fontSize: 14),
              decoration: InputDecoration(
                hintText: isArabic ? 'اختر تاريخ' : 'Choisir une date',
                hintStyle: GoogleFonts.cairo(color: grey400),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(
                  Icons.calendar_today_rounded,
                  color: nafahatGreen.withOpacity(0.6),
                  size: 20,
                ),
                suffixIcon: Icon(
                  Icons.arrow_drop_down_rounded,
                  color: nafahatGreen.withOpacity(0.6),
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
              ),
              validator: (value) {
                if (required && (value == null || value.isEmpty)) {
                  return isArabic ? '⚠️ حقل مطلوب' : '⚠️ Champ requis';
                }
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
    final bool hasValidValue = items.any((item) => item.value == value);
    final dynamic effectiveValue = hasValidValue ? value : null;

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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: grey300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<dynamic>(
              key: ValueKey(
                'dropdown_${label.replaceAll(' ', '_')}_${effectiveValue ?? 'none'}',
              ),
              value: effectiveValue,
              isExpanded: true,
              hint: Text(
                required
                    ? (isArabic ? 'اختر' : 'Sélectionner')
                    : (isArabic ? 'اختياري' : 'Optionnel'),
                style: GoogleFonts.cairo(color: grey400),
              ),
              items: items,
              onChanged: onChanged,
              icon: Icon(Icons.arrow_drop_down_rounded, color: nafahatGreen),
              style: GoogleFonts.cairo(color: nafahatGreen, fontSize: 14),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
