// lib/pages/adminisration/apparence_hero.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:nafahat/pages/adminisration/admin_page_wrapper.dart';
import '../landing/widgets/hero_section.dart';
import '../landing/widgets/slide_item.dart';

// ============================================================================
// CONSTANTES GLOBALES
// ============================================================================
const Color kHeroPrimary = Color(0xFFD57653);
const Color kHeroPrimaryLight = Color(0xFFE8987A);
const Color kHeroSecondary = Color(0xFF994A2B);
const Color kHeroDark = Color(0xFF2C221E);
const Color kHeroLight = Color(0xFF7C6E68);

const double kOpacityLight = 0.2;
const double kOpacityMedium = 0.5;
const double kOpacityHeavy = 0.75;
const bool kIsWeb = identical(0, 0.0);

// ============================================================================
// PAGE PRINCIPALE
// ============================================================================
class ApparenceHero extends StatefulWidget {
  final bool isArabic;
  const ApparenceHero({super.key, required this.isArabic});

  @override
  State<ApparenceHero> createState() => _ApparenceHeroState();
}

class _ApparenceHeroState extends State<ApparenceHero> {
  String _animationType = 'scroll';
  String _animationDirection = 'leftToRight';
  double _slideDuration = 5.0;
  double _transitionDuration = 0.8;
  List<SlideItem> _slides = [];
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _transitionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    print('=== INIT STATE ===');
    print('Plateforme: ${kIsWeb ? "Web" : "Mobile/Desktop"}');
    _loadAllData();
  }

  @override
  void dispose() {
    _durationController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    print('=== CHARGEMENT DES DONNÉES ===');
    await _loadConfig();
    await _loadSlides();
  }

  Future<void> _loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _animationType = prefs.getString('hero_animation_type') ?? 'scroll';
        _animationDirection =
            prefs.getString('hero_animation_direction') ?? 'leftToRight';
        _slideDuration = prefs.getDouble('hero_slide_duration') ?? 5.0;
        _transitionDuration =
            prefs.getDouble('hero_transition_duration') ?? 0.8;
        _durationController.text = _slideDuration.toString();
        _transitionController.text = _transitionDuration.toString();
      });
      print('Config chargée: $_animationType, $_animationDirection');
    } catch (e) {
      debugPrint('Erreur chargement config: $e');
    }
  }

  Future<void> _loadSlides() async {
    try {
      print('=== CHARGEMENT DES SLIDES ===');
      final prefs = await SharedPreferences.getInstance();
      final String? slidesJson = prefs.getString('hero_slides');

      print('slidesJson: ${slidesJson != null ? "Présent" : "Null"}');

      if (slidesJson != null && slidesJson.isNotEmpty) {
        print('JSON reçu: ${slidesJson.length} caractères');
        final List<dynamic> decoded = json.decode(slidesJson);
        print('Nombre de slides dans le JSON: ${decoded.length}');

        final List<SlideItem> loadedSlides = [];

        for (var i = 0; i < decoded.length; i++) {
          final item = decoded[i];
          SlideItem slide = SlideItem.fromJson(item);
          slide = await SlideItem.resolveImageBytes(slide, prefs);
          print(
            'Slide $i: ${slide.titleFr} - imageBytes: ${slide.imageBytes != null ? "OK" : "Null"}',
          );
          loadedSlides.add(slide);
        }

        print('=== FIN CHARGEMENT ===');
        print('Total slides chargés: ${loadedSlides.length}');

        if (mounted) {
          setState(() {
            _slides = loadedSlides;
          });
          print('État mis à jour avec ${_slides.length} slides');
        }
      } else {
        print('Aucun slide trouvé dans SharedPreferences');
        if (mounted) {
          setState(() {
            _slides = [];
          });
        }
      }
    } catch (e) {
      print('ERREUR chargement slides: $e');
      if (mounted) {
        setState(() {
          _slides = [];
        });
      }
    }
  }

  Future<void> _saveConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('hero_animation_type', _animationType);
      await prefs.setString('hero_animation_direction', _animationDirection);
      await prefs.setDouble('hero_slide_duration', _slideDuration);
      await prefs.setDouble('hero_transition_duration', _transitionDuration);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isArabic ? 'تم حفظ الإعدادات' : 'Paramètres sauvegardés',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveSlides() async {
    try {
      print('=== SAUVEGARDE DES SLIDES ===');
      final prefs = await SharedPreferences.getInstance();

      final List<Map<String, dynamic>> jsonList =
          _slides.map((slide) => slide.toJson()).toList();
      final String jsonString = json.encode(jsonList);
      await prefs.setString('hero_slides', jsonString);
      print('Métadonnées sauvegardées: ${_slides.length} slides');

      int imagesSauvegardees = 0;
      for (var slide in _slides) {
        if (!slide.isAsset &&
            slide.imageBytes != null &&
            slide.imagePath.startsWith('hero_image_')) {
          try {
            final String base64Image = base64Encode(slide.imageBytes!);
            await prefs.setString(slide.imagePath, base64Image);
            imagesSauvegardees++;
          } catch (e) {
            print('Erreur sauvegarde image: $e');
          }
        }
      }

      print('=== FIN SAUVEGARDE ===');
      print('$imagesSauvegardees images sauvegardées');
    } catch (e) {
      print('ERREUR sauvegarde slides: $e');
    }
  }

  Future<void> _uploadImage() async {
    try {
      print('=== UPLOAD IMAGE DEPUIS PC ===');

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        print('Nom du fichier: ${file.name}');
        print('Plateforme: ${kIsWeb ? "Web" : "Mobile/Desktop"}');

        if (kIsWeb) {
          if (file.bytes == null) {
            throw Exception('Impossible de récupérer les données de l\'image');
          }

          final bytes = file.bytes!;
          final String base64Image = base64Encode(bytes);
          final String imageKey =
              'hero_image_${DateTime.now().millisecondsSinceEpoch}';

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(imageKey, base64Image);
          print('Image stockée dans SharedPreferences avec clé: $imageKey');

          setState(() {
            _slides.add(
              SlideItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                titleFr: 'Nouveau Slide',
                titleAr: 'شريحة جديدة',
                subtitleFr: 'Description du slide',
                subtitleAr: 'وصف الشريحة',
                imagePath: imageKey,
                isAsset: false,
                imageBytes: bytes,
              ),
            );
          });
        } else {
          String? filePath = file.path;
          if (filePath == null) {
            throw Exception('Impossible de récupérer le chemin du fichier');
          }

          File sourceFile = File(filePath);
          final appDir = await getApplicationDocumentsDirectory();
          final String newPath =
              '${appDir.path}/hero_${DateTime.now().millisecondsSinceEpoch}_${file.name}';

          await sourceFile.copy(newPath);
          print('Fichier copié vers: $newPath');

          setState(() {
            _slides.add(
              SlideItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                titleFr: 'Nouveau Slide',
                titleAr: 'شريحة جديدة',
                subtitleFr: 'Description du slide',
                subtitleAr: 'وصف الشريحة',
                imagePath: newPath,
                isAsset: false,
              ),
            );
          });
        }

        await _saveSlides();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isArabic ? 'تم رفع الصورة' : 'Image uploadée',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        print('Aucun fichier sélectionné');
      }
    } catch (e) {
      print('ERREUR upload: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      print('=== UPLOAD IMAGE DEPUIS GALERIE ===');

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        print('Image sélectionnée: ${image.name}');
        print('Plateforme: ${kIsWeb ? "Web" : "Mobile/Desktop"}');

        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          final String base64Image = base64Encode(bytes);
          final String imageKey =
              'hero_image_${DateTime.now().millisecondsSinceEpoch}';

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(imageKey, base64Image);

          setState(() {
            _slides.add(
              SlideItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                titleFr: 'Nouveau Slide',
                titleAr: 'شريحة جديدة',
                subtitleFr: 'Description du slide',
                subtitleAr: 'وصف الشريحة',
                imagePath: imageKey,
                isAsset: false,
                imageBytes: bytes,
              ),
            );
          });
        } else {
          File file = File(image.path);
          String fileName = image.name;
          final appDir = await getApplicationDocumentsDirectory();
          final String newPath =
              '${appDir.path}/hero_${DateTime.now().millisecondsSinceEpoch}_$fileName';
          await file.copy(newPath);
          print('Fichier copié vers: $newPath');

          setState(() {
            _slides.add(
              SlideItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                titleFr: 'Nouveau Slide',
                titleAr: 'شريحة جديدة',
                subtitleFr: 'Description du slide',
                subtitleAr: 'وصف الشريحة',
                imagePath: newPath,
                isAsset: false,
              ),
            );
          });
        }

        await _saveSlides();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isArabic ? 'تم رفع الصورة' : 'Image importée',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        print('Aucune image sélectionnée');
      }
    } catch (e) {
      print('ERREUR galerie: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteSlide(int index) async {
    print('=== SUPPRESSION SLIDE ===');
    final slide = _slides[index];

    if (!slide.isAsset && slide.imagePath.startsWith('hero_image_')) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(slide.imagePath);
      print('Image supprimée de SharedPreferences: ${slide.imagePath}');
    }

    setState(() {
      _slides.removeAt(index);
    });
    await _saveSlides();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isArabic ? 'تم حذف الشريحة' : 'Slide supprimé'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _reorderSlides(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final SlideItem slide = _slides.removeAt(oldIndex);
      _slides.insert(newIndex, slide);
    });
    _saveSlides();
  }

  void _showEditDialog(int index) {
    final slide = _slides[index];
    final TextEditingController titleFrController = TextEditingController(
      text: slide.titleFr,
    );
    final TextEditingController titleArController = TextEditingController(
      text: slide.titleAr,
    );
    final TextEditingController subtitleFrController = TextEditingController(
      text: slide.subtitleFr,
    );
    final TextEditingController subtitleArController = TextEditingController(
      text: slide.subtitleAr,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              widget.isArabic ? 'تعديل الشريحة' : 'Modifier le slide',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleFrController,
                    decoration: const InputDecoration(
                      labelText: 'Titre FR',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: titleArController,
                    decoration: const InputDecoration(
                      labelText: 'Titre AR',
                      border: OutlineInputBorder(),
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: subtitleFrController,
                    decoration: const InputDecoration(
                      labelText: 'Sous-titre FR',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: subtitleArController,
                    decoration: const InputDecoration(
                      labelText: 'Sous-titre AR',
                      border: OutlineInputBorder(),
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(widget.isArabic ? 'إلغاء' : 'Annuler'),
              ),
              TextButton(
                onPressed: () async {
                  setState(() {
                    _slides[index] = slide.copyWith(
                      titleFr: titleFrController.text,
                      titleAr: titleArController.text,
                      subtitleFr: subtitleFrController.text,
                      subtitleAr: subtitleArController.text,
                    );
                  });
                  await _saveSlides();
                  if (mounted) Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          widget.isArabic ? 'تم التحديث' : 'Mis à jour',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: Text(widget.isArabic ? 'حفظ' : 'Enregistrer'),
              ),
            ],
          ),
    );
  }

  Future<void> _resetToDefault() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(widget.isArabic ? 'تأكيد' : 'Confirmation'),
            content: Text(
              widget.isArabic
                  ? 'Voulez-vous vraiment réinitialiser tous les paramètres ?'
                  : 'Voulez-vous vraiment réinitialiser tous les paramètres ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(widget.isArabic ? 'إلغاء' : 'Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  widget.isArabic ? 'تأكيد' : 'Confirmer',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        print('=== RÉINITIALISATION ===');
        final prefs = await SharedPreferences.getInstance();

        for (var slide in _slides) {
          if (!slide.isAsset && slide.imagePath.startsWith('hero_image_')) {
            await prefs.remove(slide.imagePath);
          }
        }

        await prefs.remove('hero_animation_type');
        await prefs.remove('hero_animation_direction');
        await prefs.remove('hero_slide_duration');
        await prefs.remove('hero_transition_duration');
        await prefs.remove('hero_slides');
        print('Toutes les données supprimées');

        await _loadAllData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isArabic ? 'تمت إعادة التعيين' : 'Réinitialisé',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        print('ERREUR réinitialisation: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showPreviewDialog() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.isArabic ? 'معاينة الهيرو' : 'Aperçu Hero',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: HeroSection(isArabic: widget.isArabic),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${widget.isArabic ? 'الانتقال' : 'Transition'}: $_animationType | ${widget.isArabic ? 'الاتجاه' : 'Direction'}: $_animationDirection',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('=== BUILD ===');
    print('Nombre de slides dans le build: ${_slides.length}');

    return AdminPageWrapper(
      title: 'Apparence Hero',
      titleAr: 'مظهر الهيرو',
      backgroundColor: Colors.grey[50]!,
      actions: [
        IconButton(
          icon: const Icon(Icons.save),
          onPressed: _saveConfig,
          tooltip: widget.isArabic ? 'حفظ' : 'Sauvegarder',
        ),
        IconButton(
          icon: const Icon(Icons.restore),
          onPressed: _resetToDefault,
          tooltip: widget.isArabic ? 'إعادة تعيين' : 'Réinitialiser',
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildUploadSection(),
            const SizedBox(height: 24),
            _buildAnimationSection(),
            const SizedBox(height: 24),
            _buildSlidesList(),
            const SizedBox(height: 24),
            _buildPreviewButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_upload, color: kHeroPrimary),
                const SizedBox(width: 8),
                Text(
                  widget.isArabic ? 'إضافة وسائط' : 'Ajouter des médias',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              kIsWeb
                  ? '🌐 Les images sont stockées dans SharedPreferences (base64)'
                  : '📱 Les images sont stockées dans le dossier documents',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildUploadButton(
                  icon: Icons.folder_open,
                  label: 'Parcourir PC',
                  color: Colors.blue,
                  onTap: _uploadImage,
                ),
                _buildUploadButton(
                  icon: Icons.photo_library,
                  label: 'Galerie',
                  color: Colors.green,
                  onTap: _pickImageFromGallery,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildAnimationSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.animation, color: kHeroPrimary),
                const SizedBox(width: 8),
                Text(
                  widget.isArabic
                      ? 'إعدادات الحركة'
                      : 'Paramètres d\'animation',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _animationType,
              decoration: InputDecoration(
                labelText: widget.isArabic ? 'نوع الحركة' : 'Type d\'animation',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.motion_photos_on),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'scroll',
                  child: Text('Scroll (Défilement)'),
                ),
                DropdownMenuItem(value: 'fade', child: Text('Fade (Fondu)')),
                DropdownMenuItem(
                  value: 'slide',
                  child: Text('Slide (Glissement)'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _animationType = value!;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _animationDirection,
              decoration: InputDecoration(
                labelText:
                    widget.isArabic ? 'اتجاه الحركة' : 'Direction d\'animation',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.arrow_forward),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'leftToRight',
                  child: Text('Gauche → Droite'),
                ),
                DropdownMenuItem(
                  value: 'rightToLeft',
                  child: Text('Droite → Gauche'),
                ),
                DropdownMenuItem(
                  value: 'topToBottom',
                  child: Text('Haut → Bas'),
                ),
                DropdownMenuItem(
                  value: 'bottomToTop',
                  child: Text('Bas → Haut'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _animationDirection = value!;
                });
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText:
                          widget.isArabic
                              ? 'مدة العرض (ثواني)'
                              : 'Durée du slide (sec)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.timer),
                      suffixText: 'sec',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _slideDuration = double.tryParse(value) ?? 5.0;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _transitionController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText:
                          widget.isArabic
                              ? 'مدة الانتقال (ثواني)'
                              : 'Durée transition (sec)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.swap_horiz),
                      suffixText: 'sec',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _transitionDuration = double.tryParse(value) ?? 0.8;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlidesList() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.list, color: kHeroPrimary),
                    const SizedBox(width: 8),
                    Text(
                      widget.isArabic ? 'قائمة الشرائح' : 'Liste des slides',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: kHeroPrimary.withOpacity(kOpacityLight),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_slides.length} slide${_slides.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: kHeroPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_slides.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.image_not_supported,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.isArabic ? 'لا توجد شرائح' : 'Aucun slide',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _uploadImage,
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter une image'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kHeroPrimary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _slides.length,
                onReorder: _reorderSlides,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return _buildSlideItem(index, slide);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlideItem(int index, SlideItem slide) {
    Widget imageWidget;

    try {
      if (slide.isAsset) {
        imageWidget = Image.asset(
          slide.imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            );
          },
        );
      } else if (slide.imageBytes != null) {
        imageWidget = Image.memory(
          slide.imageBytes!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            );
          },
        );
      } else if (slide.imagePath.startsWith('data:image')) {
        imageWidget = Image.network(
          slide.imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            );
          },
        );
      } else if (!kIsWeb) {
        final file = File(slide.imagePath);
        final exists = file.existsSync();

        if (exists) {
          imageWidget = Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              );
            },
          );
        } else {
          imageWidget = Container(
            color: Colors.grey[300],
            child: const Icon(Icons.image_not_supported, color: Colors.grey),
          );
        }
      } else {
        imageWidget = Container(
          color: Colors.grey[300],
          child: const Icon(Icons.image_not_supported, color: Colors.grey),
        );
      }
    } catch (e) {
      imageWidget = Container(
        color: Colors.grey[300],
        child: Icon(Icons.error_outline, color: Colors.grey[600]),
      );
    }

    return Container(
      key: Key(slide.id),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[200],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageWidget,
          ),
        ),
        title: Text(
          widget.isArabic ? slide.titleAr : slide.titleFr,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          widget.isArabic ? slide.subtitleAr : slide.subtitleFr,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showEditDialog(index),
              tooltip: widget.isArabic ? 'تعديل' : 'Modifier',
              iconSize: 20,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteSlide(index),
              tooltip: widget.isArabic ? 'حذف' : 'Supprimer',
              iconSize: 20,
            ),
            const Icon(Icons.drag_handle, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewButton() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isArabic ? 'معاينة الهيرو' : 'Aperçu Hero',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Aperçu avant sauvegarde',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                _saveConfig();
                _showPreviewDialog();
              },
              icon: const Icon(Icons.play_arrow),
              label: Text(widget.isArabic ? 'معاينة' : 'Aperçu'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kHeroPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
