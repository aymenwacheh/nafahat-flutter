// lib/pages/adminisration/apparence_bull.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafahat/models/bull_model.dart';
import 'package:nafahat/services/bull_service.dart';
import 'package:nafahat/services/training_service.dart';
import 'package:nafahat/services/video_service.dart';
import 'package:nafahat/providers/language_provider.dart';
import 'package:provider/provider.dart';

class ApparitionBullPage extends StatefulWidget {
  const ApparitionBullPage({super.key});

  @override
  State<ApparitionBullPage> createState() => _ApparitionBullPageState();
}

class _ApparitionBullPageState extends State<ApparitionBullPage> {
  List<BullModel> _bulls = [];
  bool _isLoading = true;

  // Couleurs par défaut
  Color _selectedBgColor = const Color(0xff0D443E);
  Color _selectedTextColor = Colors.white;
  Color _selectedBorderColor = const Color(0xffC4A46C);
  double _selectedFontSize = 14;

  // ✅ Types de bull disponibles avec leurs icônes
  final List<Map<String, dynamic>> _bullTypes = [
    {'key': 'formateur', 'label': 'Formateur', 'labelAr': 'مكون', 'icon': Icons.person_outline},
    {'key': 'categorie', 'label': 'Catégorie', 'labelAr': 'تصنيف', 'icon': Icons.category_outlined},
    {'key': 'formation', 'label': 'Formation', 'labelAr': 'تكوين', 'icon': Icons.school_outlined},
    {'key': 'video', 'label': 'Vidéo', 'labelAr': 'فيديو', 'icon': Icons.video_library_outlined},
    {'key': 'page', 'label': 'Page', 'labelAr': 'صفحة', 'icon': Icons.web_outlined},
    {'key': 'section', 'label': 'Section', 'labelAr': 'قسم', 'icon': Icons.dashboard_outlined},
  ];

  // ✅ Pages prédéfinies
  final List<Map<String, dynamic>> _pages = [
    {'id': 'page_home', 'path': '/', 'label': 'Accueil', 'labelAr': 'الرئيسية'},
    {'id': 'page_formations', 'path': '/formations', 'label': 'Formations', 'labelAr': 'الدورات'},
    {'id': 'page_videos', 'path': '/videos', 'label': 'Vidéos', 'labelAr': 'الفيديوهات'},
    {'id': 'page_formateurs', 'path': '/formateurs', 'label': 'Formateurs', 'labelAr': 'المكونين'},
    {'id': 'page_about', 'path': '/about', 'label': 'À propos', 'labelAr': 'عن المنصة'},
    {'id': 'page_contact', 'path': '/contact', 'label': 'Contact', 'labelAr': 'اتصل بنا'},
    {'id': 'page_profile', 'path': '/profile', 'label': 'Profil', 'labelAr': 'الملف الشخصي'},
    {'id': 'page_admin', 'path': '/admin', 'label': 'Administration', 'labelAr': 'لوحة التحكم'},
  ];

  // Données pour les listes déroulantes
  List<Map<String, dynamic>> _formateurs = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _formations = [];
  List<Map<String, dynamic>> _videos = [];
  bool _isLoadingData = false;

  // ✅ Logging
  void _log(String message) {
    print(message);
  }

  T _logAndReturn<T>(String message, T value) {
    print(message);
    return value;
  }

  @override
  void initState() {
    super.initState();
    _log('🔵 [INIT] ApparitionBullPage initialisée');
    _loadBulls();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await _loadDataForType('formateur');
    await _loadDataForType('categorie');
    await _loadDataForType('formation');
    await _loadDataForType('video');
  }

  Future<void> _loadBulls() async {
    _log('🔄 [LOAD] Chargement des bulls...');
    setState(() => _isLoading = true);
    _bulls = await BullService.getBulls();
    _log('✅ [LOAD] ${_bulls.length} bulls chargés');
    setState(() => _isLoading = false);
  }

  // ============================================================
  // CHARGER LES DONNÉES POUR LES LISTES
  // ============================================================
  Future<void> _loadDataForType(String type) async {
    _log('🔄 [LOAD_DATA] Chargement des données pour: $type');
    setState(() => _isLoadingData = true);
    
    try {
      if (type == 'formateur') {
        _log('📥 [LOAD_DATA] Appel TrainingService.getFormateurs()...');
        _formateurs = await TrainingService.getFormateurs();
        _log('📊 [LOAD_DATA] Formateurs reçus: ${_formateurs.length}');
      } else if (type == 'categorie') {
        _log('📥 [LOAD_DATA] Appel TrainingService.getCategories()...');
        _categories = await TrainingService.getCategories();
        _log('📊 [LOAD_DATA] Categories reçues: ${_categories.length}');
      } else if (type == 'formation') {
        _log('📥 [LOAD_DATA] Appel TrainingService.getTrainings()...');
        final trainings = await TrainingService.getTrainings();
        _formations = trainings.map((t) => ({
          'id': t.id,
          'title': t.titleFr,
          'titleFr': t.titleFr,
          'titleAr': t.titleAr,
        })).toList();
        _log('📊 [LOAD_DATA] Formations reçues: ${_formations.length}');
      } else if (type == 'video') {
        _log('📥 [LOAD_DATA] Appel VideoService.getVideos()...');
        final videos = await VideoService.getVideos();
        _videos = videos.map((v) => ({
          'id': v.id.toString(),
          'title': v.titleFr.isNotEmpty ? v.titleFr : v.titleAr,
          'titleAr': v.titleAr,
          'titleFr': v.titleFr,
        })).toList();
        _log('📊 [LOAD_DATA] Vidéos reçues: ${_videos.length}');
      } else if (type == 'page') {
        _log('📊 [LOAD_DATA] Pages disponibles: ${_pages.length}');
      }
    } catch (e) {
      _log('❌ [LOAD_DATA] Erreur: $e');
    }
    
    _log('🔚 [LOAD_DATA] Terminé pour: $type');
    setState(() => _isLoadingData = false);
  }

  // ============================================================
  // SÉLECTEUR DE COULEUR AVEC PALETTE
  // ============================================================
Widget _buildColorPicker({
  required String label,
  required Color selectedColor,
  required Function(Color) onColorSelected,
}) {
  // Couleurs de base pour l'aperçu rapide
  final List<Color> baseColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: GoogleFonts.cairo(fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 8),
      // Afficher la couleur sélectionnée avec un aperçu
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selectedColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _getColorName(selectedColor),
              style: GoogleFonts.cairo(
                color: _getContrastColor(selectedColor),
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getContrastColor(selectedColor).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '#${selectedColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: _getContrastColor(selectedColor),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      // Bouton pour ouvrir la palette
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showColorPalette(
            context,
            selectedColor,
            onColorSelected,
          ),
          icon: const Icon(Icons.palette_outlined, size: 20),
          label: Text(
            '🎨 Ouvrir la palette de couleurs',
            style: GoogleFonts.cairo(),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xffd57653),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      // Aperçu des couleurs rapides
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          ...baseColors.map((color) {
            return GestureDetector(
              onTap: () => onColorSelected(color),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selectedColor == color ? Colors.black : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: selectedColor == color
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
            );
          }),
        ],
      ),
    ],
  );
}

  // ============================================================
  // PALETTE DE COULEURS COMPLÈTE
  // ============================================================
  void _showColorPalette(
    BuildContext context,
    Color currentColor,
    Function(Color) onColorSelected,
  ) {
    final isArabic = Provider.of<LanguageProvider>(context, listen: false).isArabic;
    Color tempSelectedColor = currentColor;

    // Définition des couleurs Material avec leurs nuances
    final Map<String, Map<int, Color>> materialColors = {
      'Rouge': {
        50: Colors.red.shade50,
        100: Colors.red.shade100,
        200: Colors.red.shade200,
        300: Colors.red.shade300,
        400: Colors.red.shade400,
        500: Colors.red.shade500,
        600: Colors.red.shade600,
        700: Colors.red.shade700,
        800: Colors.red.shade800,
        900: Colors.red.shade900,
      },
      'Rose': {
        50: Colors.pink.shade50,
        100: Colors.pink.shade100,
        200: Colors.pink.shade200,
        300: Colors.pink.shade300,
        400: Colors.pink.shade400,
        500: Colors.pink.shade500,
        600: Colors.pink.shade600,
        700: Colors.pink.shade700,
        800: Colors.pink.shade800,
        900: Colors.pink.shade900,
      },
      'Violet': {
        50: Colors.purple.shade50,
        100: Colors.purple.shade100,
        200: Colors.purple.shade200,
        300: Colors.purple.shade300,
        400: Colors.purple.shade400,
        500: Colors.purple.shade500,
        600: Colors.purple.shade600,
        700: Colors.purple.shade700,
        800: Colors.purple.shade800,
        900: Colors.purple.shade900,
      },
      'Violet foncé': {
        50: Colors.deepPurple.shade50,
        100: Colors.deepPurple.shade100,
        200: Colors.deepPurple.shade200,
        300: Colors.deepPurple.shade300,
        400: Colors.deepPurple.shade400,
        500: Colors.deepPurple.shade500,
        600: Colors.deepPurple.shade600,
        700: Colors.deepPurple.shade700,
        800: Colors.deepPurple.shade800,
        900: Colors.deepPurple.shade900,
      },
      'Indigo': {
        50: Colors.indigo.shade50,
        100: Colors.indigo.shade100,
        200: Colors.indigo.shade200,
        300: Colors.indigo.shade300,
        400: Colors.indigo.shade400,
        500: Colors.indigo.shade500,
        600: Colors.indigo.shade600,
        700: Colors.indigo.shade700,
        800: Colors.indigo.shade800,
        900: Colors.indigo.shade900,
      },
      'Bleu': {
        50: Colors.blue.shade50,
        100: Colors.blue.shade100,
        200: Colors.blue.shade200,
        300: Colors.blue.shade300,
        400: Colors.blue.shade400,
        500: Colors.blue.shade500,
        600: Colors.blue.shade600,
        700: Colors.blue.shade700,
        800: Colors.blue.shade800,
        900: Colors.blue.shade900,
      },
      'Bleu clair': {
        50: Colors.lightBlue.shade50,
        100: Colors.lightBlue.shade100,
        200: Colors.lightBlue.shade200,
        300: Colors.lightBlue.shade300,
        400: Colors.lightBlue.shade400,
        500: Colors.lightBlue.shade500,
        600: Colors.lightBlue.shade600,
        700: Colors.lightBlue.shade700,
        800: Colors.lightBlue.shade800,
        900: Colors.lightBlue.shade900,
      },
      'Cyan': {
        50: Colors.cyan.shade50,
        100: Colors.cyan.shade100,
        200: Colors.cyan.shade200,
        300: Colors.cyan.shade300,
        400: Colors.cyan.shade400,
        500: Colors.cyan.shade500,
        600: Colors.cyan.shade600,
        700: Colors.cyan.shade700,
        800: Colors.cyan.shade800,
        900: Colors.cyan.shade900,
      },
      'Sarcelle': {
        50: Colors.teal.shade50,
        100: Colors.teal.shade100,
        200: Colors.teal.shade200,
        300: Colors.teal.shade300,
        400: Colors.teal.shade400,
        500: Colors.teal.shade500,
        600: Colors.teal.shade600,
        700: Colors.teal.shade700,
        800: Colors.teal.shade800,
        900: Colors.teal.shade900,
      },
      'Vert': {
        50: Colors.green.shade50,
        100: Colors.green.shade100,
        200: Colors.green.shade200,
        300: Colors.green.shade300,
        400: Colors.green.shade400,
        500: Colors.green.shade500,
        600: Colors.green.shade600,
        700: Colors.green.shade700,
        800: Colors.green.shade800,
        900: Colors.green.shade900,
      },
      'Vert clair': {
        50: Colors.lightGreen.shade50,
        100: Colors.lightGreen.shade100,
        200: Colors.lightGreen.shade200,
        300: Colors.lightGreen.shade300,
        400: Colors.lightGreen.shade400,
        500: Colors.lightGreen.shade500,
        600: Colors.lightGreen.shade600,
        700: Colors.lightGreen.shade700,
        800: Colors.lightGreen.shade800,
        900: Colors.lightGreen.shade900,
      },
      'Lime': {
        50: Colors.lime.shade50,
        100: Colors.lime.shade100,
        200: Colors.lime.shade200,
        300: Colors.lime.shade300,
        400: Colors.lime.shade400,
        500: Colors.lime.shade500,
        600: Colors.lime.shade600,
        700: Colors.lime.shade700,
        800: Colors.lime.shade800,
        900: Colors.lime.shade900,
      },
      'Jaune': {
        50: Colors.yellow.shade50,
        100: Colors.yellow.shade100,
        200: Colors.yellow.shade200,
        300: Colors.yellow.shade300,
        400: Colors.yellow.shade400,
        500: Colors.yellow.shade500,
        600: Colors.yellow.shade600,
        700: Colors.yellow.shade700,
        800: Colors.yellow.shade800,
        900: Colors.yellow.shade900,
      },
      'Ambre': {
        50: Colors.amber.shade50,
        100: Colors.amber.shade100,
        200: Colors.amber.shade200,
        300: Colors.amber.shade300,
        400: Colors.amber.shade400,
        500: Colors.amber.shade500,
        600: Colors.amber.shade600,
        700: Colors.amber.shade700,
        800: Colors.amber.shade800,
        900: Colors.amber.shade900,
      },
      'Orange': {
        50: Colors.orange.shade50,
        100: Colors.orange.shade100,
        200: Colors.orange.shade200,
        300: Colors.orange.shade300,
        400: Colors.orange.shade400,
        500: Colors.orange.shade500,
        600: Colors.orange.shade600,
        700: Colors.orange.shade700,
        800: Colors.orange.shade800,
        900: Colors.orange.shade900,
      },
      'Orange foncé': {
        50: Colors.deepOrange.shade50,
        100: Colors.deepOrange.shade100,
        200: Colors.deepOrange.shade200,
        300: Colors.deepOrange.shade300,
        400: Colors.deepOrange.shade400,
        500: Colors.deepOrange.shade500,
        600: Colors.deepOrange.shade600,
        700: Colors.deepOrange.shade700,
        800: Colors.deepOrange.shade800,
        900: Colors.deepOrange.shade900,
      },
      'Marron': {
        50: Colors.brown.shade50,
        100: Colors.brown.shade100,
        200: Colors.brown.shade200,
        300: Colors.brown.shade300,
        400: Colors.brown.shade400,
        500: Colors.brown.shade500,
        600: Colors.brown.shade600,
        700: Colors.brown.shade700,
        800: Colors.brown.shade800,
        900: Colors.brown.shade900,
      },
      'Gris': {
        50: Colors.grey.shade50,
        100: Colors.grey.shade100,
        200: Colors.grey.shade200,
        300: Colors.grey.shade300,
        400: Colors.grey.shade400,
        500: Colors.grey.shade500,
        600: Colors.grey.shade600,
        700: Colors.grey.shade700,
        800: Colors.grey.shade800,
        900: Colors.grey.shade900,
      },
      'Bleu gris': {
        50: Colors.blueGrey.shade50,
        100: Colors.blueGrey.shade100,
        200: Colors.blueGrey.shade200,
        300: Colors.blueGrey.shade300,
        400: Colors.blueGrey.shade400,
        500: Colors.blueGrey.shade500,
        600: Colors.blueGrey.shade600,
        700: Colors.blueGrey.shade700,
        800: Colors.blueGrey.shade800,
        900: Colors.blueGrey.shade900,
      },
    };

    // Noms en arabe
    final Map<String, String> colorNamesAr = {
      'Rouge': 'أحمر',
      'Rose': 'وردي',
      'Violet': 'بنفسجي',
      'Violet foncé': 'بنفسجي غامق',
      'Indigo': 'نيلي',
      'Bleu': 'أزرق',
      'Bleu clair': 'أزرق فاتح',
      'Cyan': 'سماوي',
      'Sarcelle': 'بطي',
      'Vert': 'أخضر',
      'Vert clair': 'أخضر فاتح',
      'Lime': 'ليموني',
      'Jaune': 'أصفر',
      'Ambre': 'عنبر',
      'Orange': 'برتقالي',
      'Orange foncé': 'برتقالي غامق',
      'Marron': 'بني',
      'Gris': 'رمادي',
      'Bleu gris': 'أزرق رمادي',
    };

    // Nuances disponibles
    final List<int> shades = [50, 100, 200, 300, 400, 500, 600, 700, 800, 900];

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.palette, color: const Color(0xffd57653)),
                const SizedBox(width: 12),
                Text(
                  isArabic ? '🎨 لوحة الألوان' : '🎨 Palette de couleurs',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Container(
              width: double.maxFinite,
              constraints: const BoxConstraints(maxHeight: 500),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Couleur actuelle avec aperçu
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: tempSelectedColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _getColorName(tempSelectedColor),
                            style: GoogleFonts.cairo(
                              color: _getContrastColor(tempSelectedColor),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getContrastColor(tempSelectedColor).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '#${tempSelectedColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    color: _getContrastColor(tempSelectedColor),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(
                                  Icons.check_circle,
                                  color: _getContrastColor(tempSelectedColor),
                                ),
                                onPressed: () {
                                  onColorSelected(tempSelectedColor);
                                  Navigator.pop(context);
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Palette complète avec nuances
                    Text(
                      isArabic ? '🌈 اختار لوناً' : '🌈 Choisissez une couleur',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...materialColors.entries.map((entry) {
                      final colorNameFr = entry.key;
                      final colorName = isArabic 
                          ? colorNamesAr[colorNameFr] ?? colorNameFr
                          : colorNameFr;
                      final shadesMap = entry.value;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            colorName,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: shades.map((shade) {
                              final color = shadesMap[shade]!;
                              return GestureDetector(
                                onTap: () {
                                  setStateDialog(() {
                                    tempSelectedColor = color;
                                  });
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: tempSelectedColor == color
                                          ? Colors.black
                                          : Colors.grey[300]!,
                                      width: tempSelectedColor == color ? 3 : 1,
                                    ),
                                  ),
                                  child: tempSelectedColor == color
                                      ? Icon(
                                          Icons.check,
                                          color: _getContrastColor(color),
                                          size: 14,
                                        )
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    }).toList(),

                    // Couleurs personnalisées
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic ? '🎨 ألوان مخصصة' : '🎨 Couleurs personnalisées',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: tempSelectedColor.value
                                      .toRadixString(16)
                                      .padLeft(8, '0')
                                      .substring(2),
                                  decoration: InputDecoration(
                                    labelText: isArabic ? 'رمز اللون' : 'Code couleur',
                                    hintText: '#FF5733',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    try {
                                      String hex = value.replaceAll('#', '');
                                      if (hex.length == 6) {
                                        hex = 'FF$hex';
                                      }
                                      if (hex.length == 8) {
                                        final color = Color(int.parse('0x$hex'));
                                        setStateDialog(() {
                                          tempSelectedColor = color;
                                        });
                                      }
                                    } catch (e) {
                                      // Ignorer les erreurs de parsing
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: tempSelectedColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  isArabic ? 'إلغاء' : 'Annuler',
                  style: GoogleFonts.cairo(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  onColorSelected(tempSelectedColor);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffd57653),
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  isArabic ? 'اختيار' : 'Choisir',
                  style: GoogleFonts.cairo(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // HELPER : Obtenir le nom d'une couleur spécifique
  // ============================================================
  String _getColorName(Color color) {
    // Vérifier si c'est une couleur Material avec ses nuances
    final Map<Color, String> colorNames = {
      Colors.red.shade50: 'Rouge 50',
      Colors.red.shade100: 'Rouge 100',
      Colors.red.shade200: 'Rouge 200',
      Colors.red.shade300: 'Rouge 300',
      Colors.red.shade400: 'Rouge 400',
      Colors.red.shade500: 'Rouge 500',
      Colors.red.shade600: 'Rouge 600',
      Colors.red.shade700: 'Rouge 700',
      Colors.red.shade800: 'Rouge 800',
      Colors.red.shade900: 'Rouge 900',
      Colors.pink.shade50: 'Rose 50',
      Colors.pink.shade100: 'Rose 100',
      Colors.pink.shade200: 'Rose 200',
      Colors.pink.shade300: 'Rose 300',
      Colors.pink.shade400: 'Rose 400',
      Colors.pink.shade500: 'Rose 500',
      Colors.pink.shade600: 'Rose 600',
      Colors.pink.shade700: 'Rose 700',
      Colors.pink.shade800: 'Rose 800',
      Colors.pink.shade900: 'Rose 900',
      Colors.purple.shade50: 'Violet 50',
      Colors.purple.shade100: 'Violet 100',
      Colors.purple.shade200: 'Violet 200',
      Colors.purple.shade300: 'Violet 300',
      Colors.purple.shade400: 'Violet 400',
      Colors.purple.shade500: 'Violet 500',
      Colors.purple.shade600: 'Violet 600',
      Colors.purple.shade700: 'Violet 700',
      Colors.purple.shade800: 'Violet 800',
      Colors.purple.shade900: 'Violet 900',
      Colors.deepPurple.shade50: 'Violet foncé 50',
      Colors.deepPurple.shade100: 'Violet foncé 100',
      Colors.deepPurple.shade200: 'Violet foncé 200',
      Colors.deepPurple.shade300: 'Violet foncé 300',
      Colors.deepPurple.shade400: 'Violet foncé 400',
      Colors.deepPurple.shade500: 'Violet foncé 500',
      Colors.deepPurple.shade600: 'Violet foncé 600',
      Colors.deepPurple.shade700: 'Violet foncé 700',
      Colors.deepPurple.shade800: 'Violet foncé 800',
      Colors.deepPurple.shade900: 'Violet foncé 900',
      Colors.indigo.shade50: 'Indigo 50',
      Colors.indigo.shade100: 'Indigo 100',
      Colors.indigo.shade200: 'Indigo 200',
      Colors.indigo.shade300: 'Indigo 300',
      Colors.indigo.shade400: 'Indigo 400',
      Colors.indigo.shade500: 'Indigo 500',
      Colors.indigo.shade600: 'Indigo 600',
      Colors.indigo.shade700: 'Indigo 700',
      Colors.indigo.shade800: 'Indigo 800',
      Colors.indigo.shade900: 'Indigo 900',
      Colors.blue.shade50: 'Bleu 50',
      Colors.blue.shade100: 'Bleu 100',
      Colors.blue.shade200: 'Bleu 200',
      Colors.blue.shade300: 'Bleu 300',
      Colors.blue.shade400: 'Bleu 400',
      Colors.blue.shade500: 'Bleu 500',
      Colors.blue.shade600: 'Bleu 600',
      Colors.blue.shade700: 'Bleu 700',
      Colors.blue.shade800: 'Bleu 800',
      Colors.blue.shade900: 'Bleu 900',
      Colors.lightBlue.shade50: 'Bleu clair 50',
      Colors.lightBlue.shade100: 'Bleu clair 100',
      Colors.lightBlue.shade200: 'Bleu clair 200',
      Colors.lightBlue.shade300: 'Bleu clair 300',
      Colors.lightBlue.shade400: 'Bleu clair 400',
      Colors.lightBlue.shade500: 'Bleu clair 500',
      Colors.lightBlue.shade600: 'Bleu clair 600',
      Colors.lightBlue.shade700: 'Bleu clair 700',
      Colors.lightBlue.shade800: 'Bleu clair 800',
      Colors.lightBlue.shade900: 'Bleu clair 900',
      Colors.cyan.shade50: 'Cyan 50',
      Colors.cyan.shade100: 'Cyan 100',
      Colors.cyan.shade200: 'Cyan 200',
      Colors.cyan.shade300: 'Cyan 300',
      Colors.cyan.shade400: 'Cyan 400',
      Colors.cyan.shade500: 'Cyan 500',
      Colors.cyan.shade600: 'Cyan 600',
      Colors.cyan.shade700: 'Cyan 700',
      Colors.cyan.shade800: 'Cyan 800',
      Colors.cyan.shade900: 'Cyan 900',
      Colors.teal.shade50: 'Sarcelle 50',
      Colors.teal.shade100: 'Sarcelle 100',
      Colors.teal.shade200: 'Sarcelle 200',
      Colors.teal.shade300: 'Sarcelle 300',
      Colors.teal.shade400: 'Sarcelle 400',
      Colors.teal.shade500: 'Sarcelle 500',
      Colors.teal.shade600: 'Sarcelle 600',
      Colors.teal.shade700: 'Sarcelle 700',
      Colors.teal.shade800: 'Sarcelle 800',
      Colors.teal.shade900: 'Sarcelle 900',
      Colors.green.shade50: 'Vert 50',
      Colors.green.shade100: 'Vert 100',
      Colors.green.shade200: 'Vert 200',
      Colors.green.shade300: 'Vert 300',
      Colors.green.shade400: 'Vert 400',
      Colors.green.shade500: 'Vert 500',
      Colors.green.shade600: 'Vert 600',
      Colors.green.shade700: 'Vert 700',
      Colors.green.shade800: 'Vert 800',
      Colors.green.shade900: 'Vert 900',
      Colors.lightGreen.shade50: 'Vert clair 50',
      Colors.lightGreen.shade100: 'Vert clair 100',
      Colors.lightGreen.shade200: 'Vert clair 200',
      Colors.lightGreen.shade300: 'Vert clair 300',
      Colors.lightGreen.shade400: 'Vert clair 400',
      Colors.lightGreen.shade500: 'Vert clair 500',
      Colors.lightGreen.shade600: 'Vert clair 600',
      Colors.lightGreen.shade700: 'Vert clair 700',
      Colors.lightGreen.shade800: 'Vert clair 800',
      Colors.lightGreen.shade900: 'Vert clair 900',
      Colors.lime.shade50: 'Lime 50',
      Colors.lime.shade100: 'Lime 100',
      Colors.lime.shade200: 'Lime 200',
      Colors.lime.shade300: 'Lime 300',
      Colors.lime.shade400: 'Lime 400',
      Colors.lime.shade500: 'Lime 500',
      Colors.lime.shade600: 'Lime 600',
      Colors.lime.shade700: 'Lime 700',
      Colors.lime.shade800: 'Lime 800',
      Colors.lime.shade900: 'Lime 900',
      Colors.yellow.shade50: 'Jaune 50',
      Colors.yellow.shade100: 'Jaune 100',
      Colors.yellow.shade200: 'Jaune 200',
      Colors.yellow.shade300: 'Jaune 300',
      Colors.yellow.shade400: 'Jaune 400',
      Colors.yellow.shade500: 'Jaune 500',
      Colors.yellow.shade600: 'Jaune 600',
      Colors.yellow.shade700: 'Jaune 700',
      Colors.yellow.shade800: 'Jaune 800',
      Colors.yellow.shade900: 'Jaune 900',
      Colors.amber.shade50: 'Ambre 50',
      Colors.amber.shade100: 'Ambre 100',
      Colors.amber.shade200: 'Ambre 200',
      Colors.amber.shade300: 'Ambre 300',
      Colors.amber.shade400: 'Ambre 400',
      Colors.amber.shade500: 'Ambre 500',
      Colors.amber.shade600: 'Ambre 600',
      Colors.amber.shade700: 'Ambre 700',
      Colors.amber.shade800: 'Ambre 800',
      Colors.amber.shade900: 'Ambre 900',
      Colors.orange.shade50: 'Orange 50',
      Colors.orange.shade100: 'Orange 100',
      Colors.orange.shade200: 'Orange 200',
      Colors.orange.shade300: 'Orange 300',
      Colors.orange.shade400: 'Orange 400',
      Colors.orange.shade500: 'Orange 500',
      Colors.orange.shade600: 'Orange 600',
      Colors.orange.shade700: 'Orange 700',
      Colors.orange.shade800: 'Orange 800',
      Colors.orange.shade900: 'Orange 900',
      Colors.deepOrange.shade50: 'Orange foncé 50',
      Colors.deepOrange.shade100: 'Orange foncé 100',
      Colors.deepOrange.shade200: 'Orange foncé 200',
      Colors.deepOrange.shade300: 'Orange foncé 300',
      Colors.deepOrange.shade400: 'Orange foncé 400',
      Colors.deepOrange.shade500: 'Orange foncé 500',
      Colors.deepOrange.shade600: 'Orange foncé 600',
      Colors.deepOrange.shade700: 'Orange foncé 700',
      Colors.deepOrange.shade800: 'Orange foncé 800',
      Colors.deepOrange.shade900: 'Orange foncé 900',
      Colors.brown.shade50: 'Marron 50',
      Colors.brown.shade100: 'Marron 100',
      Colors.brown.shade200: 'Marron 200',
      Colors.brown.shade300: 'Marron 300',
      Colors.brown.shade400: 'Marron 400',
      Colors.brown.shade500: 'Marron 500',
      Colors.brown.shade600: 'Marron 600',
      Colors.brown.shade700: 'Marron 700',
      Colors.brown.shade800: 'Marron 800',
      Colors.brown.shade900: 'Marron 900',
      Colors.grey.shade50: 'Gris 50',
      Colors.grey.shade100: 'Gris 100',
      Colors.grey.shade200: 'Gris 200',
      Colors.grey.shade300: 'Gris 300',
      Colors.grey.shade400: 'Gris 400',
      Colors.grey.shade500: 'Gris 500',
      Colors.grey.shade600: 'Gris 600',
      Colors.grey.shade700: 'Gris 700',
      Colors.grey.shade800: 'Gris 800',
      Colors.grey.shade900: 'Gris 900',
      Colors.blueGrey.shade50: 'Bleu gris 50',
      Colors.blueGrey.shade100: 'Bleu gris 100',
      Colors.blueGrey.shade200: 'Bleu gris 200',
      Colors.blueGrey.shade300: 'Bleu gris 300',
      Colors.blueGrey.shade400: 'Bleu gris 400',
      Colors.blueGrey.shade500: 'Bleu gris 500',
      Colors.blueGrey.shade600: 'Bleu gris 600',
      Colors.blueGrey.shade700: 'Bleu gris 700',
      Colors.blueGrey.shade800: 'Bleu gris 800',
      Colors.blueGrey.shade900: 'Bleu gris 900',
    };

    if (colorNames.containsKey(color)) {
      return colorNames[color]!;
    }

    // Couleurs personnalisées
    if (color == const Color(0xff0D443E)) return 'Vert forêt';
    if (color == const Color(0xffd57653)) return 'Terre cuite';
    if (color == const Color(0xff2c221e)) return 'Brun foncé';
    if (color == const Color(0xffC4A46C)) return 'Doré';
    if (color == Colors.white) return 'Blanc';
    if (color == Colors.black) return 'Noir';
    if (color == Colors.transparent) return 'Transparent';

    return 'Personnalisé';
  }

  // ============================================================
  // HELPER : Obtenir une couleur contrastante (noir ou blanc)
  // ============================================================
  Color _getContrastColor(Color color) {
    final brightness = color.computeLuminance();
    return brightness > 0.5 ? Colors.black : Colors.white;
  }

  // ============================================================
  // AJOUTER / MODIFIER UN BULL
  // ============================================================
  Future<void> _showBullDialog({BullModel? bullToEdit}) async {
    _log('🔵 [DIALOG] Ouverture du dialogue${bullToEdit != null ? ' (édition)' : ' (création)'}');
    
    final isArabic = Provider.of<LanguageProvider>(context, listen: false).isArabic;
    
    final TextEditingController titleController = TextEditingController(
      text: bullToEdit?.title ?? '',
    );
    final TextEditingController titleArController = TextEditingController(
      text: bullToEdit?.titleAr ?? '',
    );
    final TextEditingController titleFrController = TextEditingController(
      text: bullToEdit?.titleFr ?? '',
    );
    final TextEditingController linkController = TextEditingController(
      text: bullToEdit?.link ?? '',
    );

    String selectedType = 'page';
    String selectedItemId = '';

    // ✅ Déterminer le type à partir du lien si on édite
    if (bullToEdit != null) {
      final link = bullToEdit.link;
      _log('🔍 [DIALOG] Lien existant: $link');
      
      if (link.startsWith('/formateur/')) {
        selectedType = 'formateur';
        selectedItemId = link.replaceAll('/formateur/', '');
        _log('   ➜ Type: formateur, ID: $selectedItemId');
      } else if (link.startsWith('/categorie/')) {
        selectedType = 'categorie';
        selectedItemId = link.replaceAll('/categorie/', '');
        _log('   ➜ Type: categorie, ID: $selectedItemId');
      } else if (link.startsWith('/formation/')) {
        selectedType = 'formation';
        selectedItemId = link.replaceAll('/formation/', '');
        _log('   ➜ Type: formation, ID: $selectedItemId');
      } else if (link.startsWith('/video/')) {
        selectedType = 'video';
        selectedItemId = link.replaceAll('/video/', '');
        _log('   ➜ Type: video, ID: $selectedItemId');
      } else if (link.startsWith('/section/')) {
        selectedType = 'section';
        selectedItemId = link.replaceAll('/section/', '');
        _log('   ➜ Type: section, ID: $selectedItemId');
      } else {
        final foundPage = _pages.firstWhere(
          (p) => p['path'] == link,
          orElse: () => {},
        );
        if (foundPage.isNotEmpty) {
          selectedType = 'page';
          selectedItemId = foundPage['id'] ?? '';
          _log('   ➜ Type: page, ID: $selectedItemId, Path: $link');
        } else {
          selectedType = 'page';
          _log('   ➜ Type: page (personnalisé)');
        }
      }
    }

    Color bgColor = bullToEdit?.backgroundColor ?? _selectedBgColor;
    Color textColor = bullToEdit?.textColor ?? _selectedTextColor;
    Color borderColor = bullToEdit?.borderColor ?? _selectedBorderColor;
    double fontSize = bullToEdit?.fontSize ?? _selectedFontSize;

    _log('🔄 [DIALOG] Chargement initial pour type: $selectedType');
    await _loadDataForType(selectedType);

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(
              bullToEdit != null
                  ? (isArabic ? '✏️ تعديل رابط' : '✏️ Modifier un lien')
                  : (isArabic ? '➕ إضافة رابط جديد' : '➕ Ajouter un nouveau lien'),
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ============================================================
                  // TYPE DE BULL
                  // ============================================================
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: InputDecoration(
                      labelText: isArabic ? 'نوع الرابط' : 'Type de lien',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: Icon(Icons.type_specimen_rounded, color: const Color(0xffd57653)),
                    ),
                    items: _bullTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type['key'],
                        child: Row(
                          children: [
                            Icon(type['icon'], size: 20, color: const Color(0xffd57653)),
                            const SizedBox(width: 8),
                            Text(
                              isArabic ? type['labelAr'] : type['label'],
                              style: GoogleFonts.cairo(),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      if (value != null) {
                        _log('🔄 [DIALOG] Changement de type: $selectedType -> $value');
                        await _loadDataForType(value);
                        setStateDialog(() {
                          selectedType = value;
                          selectedItemId = '';
                          linkController.text = '';
                        });
                        _log('🔄 [DIALOG] Rechargement après changement de type');
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // ============================================================
                  // SÉLECTION DE L'ÉLÉMENT
                  // ============================================================
                  if (selectedType != 'section') ...[
                    _buildItemSelector(
                      type: selectedType,
                      isArabic: isArabic,
                      selectedItemId: selectedItemId,
                      onItemSelected: (id, name) {
                        _log('✅ [DIALOG] Item sélectionné: $name (ID: $id)');
                        setStateDialog(() {
                          selectedItemId = id;
                          if (id.isNotEmpty) {
                            if (selectedType == 'formateur') {
                              linkController.text = '/formateur/$id';
                            } else if (selectedType == 'categorie') {
                              linkController.text = '/categorie/$id';
                            } else if (selectedType == 'formation') {
                              linkController.text = '/formation/$id';
                            } else if (selectedType == 'video') {
                              linkController.text = '/video/$id';
                            } else if (selectedType == 'page') {
                              final selectedPage = _pages.firstWhere(
                                (p) => p['id'] == id,
                                orElse: () => {},
                              );
                              if (selectedPage.isNotEmpty) {
                                linkController.text = selectedPage['path'] ?? '/';
                              }
                            }
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ============================================================
                  // LIEN MANUEL
                  // ============================================================
                  if (selectedType == 'section') ...[
                    TextField(
                      controller: linkController,
                      decoration: InputDecoration(
                        labelText: isArabic ? 'الرابط' : 'Lien',
                        hintText: '/section/hero',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.link_rounded, color: const Color(0xffd57653)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ============================================================
                  // TITRES
                  // ============================================================
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: isArabic ? 'العنوان' : 'Titre',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: Icon(Icons.title_rounded, color: const Color(0xffd57653)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleArController,
                    decoration: InputDecoration(
                      labelText: isArabic ? 'العنوان بالعربية' : 'Titre en arabe',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: Icon(Icons.translate_rounded, color: const Color(0xffd57653)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleFrController,
                    decoration: InputDecoration(
                      labelText: isArabic ? 'العنوان بالفرنسية' : 'Titre en français',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: Icon(Icons.translate_rounded, color: const Color(0xffd57653)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),

                  // ============================================================
                  // COULEURS AVEC PALETTE
                  // ============================================================
                  _buildColorPicker(
                    label: isArabic ? 'لون الخلفية' : 'Couleur de fond',
                    selectedColor: bgColor,
                    onColorSelected: (color) {
                      setStateDialog(() {
                        bgColor = color;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildColorPicker(
                    label: isArabic ? 'لون النص' : 'Couleur du texte',
                    selectedColor: textColor,
                    onColorSelected: (color) {
                      setStateDialog(() {
                        textColor = color;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildColorPicker(
                    label: isArabic ? 'لون الحدود' : 'Couleur de bordure',
                    selectedColor: borderColor,
                    onColorSelected: (color) {
                      setStateDialog(() {
                        borderColor = color;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // ============================================================
                  // TAILLE DE POLICE
                  // ============================================================
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isArabic ? 'حجم الخط: ${fontSize.toStringAsFixed(0)}' : 'Taille de police: ${fontSize.toStringAsFixed(0)}',
                          style: GoogleFonts.cairo(),
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: fontSize,
                          min: 10,
                          max: 24,
                          divisions: 14,
                          label: fontSize.toStringAsFixed(0),
                          onChanged: (value) {
                            setStateDialog(() {
                              fontSize = value;
                            });
                          },
                          activeColor: const Color(0xffd57653),
                        ),
                      ),
                    ],
                  ),

                  // ============================================================
                  // APERÇU EN DIRECT
                  // ============================================================
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isArabic ? '👁️ معاينة' : '👁️ Aperçu',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: borderColor, width: 2),
                            ),
                            child: Text(
                              titleController.text.isNotEmpty
                                  ? titleController.text
                                  : (isArabic ? 'عنوان' : 'Titre'),
                              style: GoogleFonts.cairo(
                                fontSize: fontSize,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Center(
                          child: Text(
                            linkController.text.isNotEmpty
                                ? '🔗 ${linkController.text}'
                                : '',
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _log('🔚 [DIALOG] Annulation');
                  Navigator.pop(context);
                },
                child: Text(
                  isArabic ? 'إلغاء' : 'Annuler',
                  style: GoogleFonts.cairo(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  _log('💾 [DIALOG] Sauvegarde du bull...');
                  
                  if (titleController.text.isEmpty) {
                    _log('⚠️ [DIALOG] Titre vide');
                    _showSnackBar(
                      isArabic ? '⚠️ Veuillez saisir un titre' : '⚠️ Veuillez saisir un titre',
                      Colors.orange,
                    );
                    return;
                  }

                  if (linkController.text.isEmpty) {
                    _log('⚠️ [DIALOG] Lien vide');
                    _showSnackBar(
                      isArabic ? '⚠️ Veuillez saisir un lien' : '⚠️ Veuillez saisir un lien',
                      Colors.orange,
                    );
                    return;
                  }

                  final bull = BullModel(
                    id: bullToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text,
                    titleAr: titleArController.text.isNotEmpty ? titleArController.text : null,
                    titleFr: titleFrController.text.isNotEmpty ? titleFrController.text : null,
                    link: linkController.text,
                    backgroundColor: bgColor,
                    textColor: textColor,
                    borderColor: borderColor,
                    fontSize: fontSize,
                    order: bullToEdit?.order ?? _bulls.length,
                    isActive: bullToEdit?.isActive ?? true,
                  );

                  _log('📦 [DIALOG] Bull créé: ${bull.title} (${bull.link})');
                  
                  bool success;
                  if (bullToEdit != null) {
                    _log('🔄 [DIALOG] Mise à jour du bull existant');
                    success = await BullService.updateBull(bull);
                  } else {
                    _log('➕ [DIALOG] Ajout d\'un nouveau bull');
                    success = await BullService.addBull(bull);
                  }

                  if (success) {
                    _log('✅ [DIALOG] Opération réussie');
                    await _loadBulls();
                    if (mounted) Navigator.pop(context);
                    _showSnackBar(
                      bullToEdit != null
                          ? (isArabic ? '✅ تم تعديل الرابط بنجاح' : '✅ Lien modifié avec succès')
                          : (isArabic ? '✅ تم إضافة الرابط بنجاح' : '✅ Lien ajouté avec succès'),
                      Colors.green,
                    );
                  } else {
                    _log('❌ [DIALOG] Échec de l\'opération');
                    _showSnackBar(
                      isArabic ? '❌ Erreur lors de l\'opération' : '❌ Erreur lors de l\'opération',
                      Colors.red,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffd57653),
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  bullToEdit != null
                      ? (isArabic ? 'تعديل' : 'Modifier')
                      : (isArabic ? 'إضافة' : 'Ajouter'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // SÉLECTEUR D'ÉLÉMENT
  // ============================================================
  Widget _buildItemSelector({
    required String type,
    required bool isArabic,
    required String selectedItemId,
    required Function(String, String) onItemSelected,
  }) {
    return _logAndReturn<Widget>(
      '🔧 [SELECTOR] Construction du sélecteur pour: $type',
      _buildItemSelectorContent(
        type: type,
        isArabic: isArabic,
        selectedItemId: selectedItemId,
        onItemSelected: onItemSelected,
      ),
    );
  }

  Widget _buildItemSelectorContent({
    required String type,
    required bool isArabic,
    required String selectedItemId,
    required Function(String, String) onItemSelected,
  }) {
    _log('   📋 selectedItemId: "$selectedItemId"');
    
    List<Map<String, dynamic>> items = [];
    String label = '';
    String labelAr = '';
    IconData? icon;

    if (type == 'formateur') {
      items = _formateurs;
      label = 'Sélectionnez un formateur';
      labelAr = 'اختر مكوناً';
      icon = Icons.person_outline;
      _log('   👤 Type: FORMATEUR, items: ${items.length}');
    } else if (type == 'categorie') {
      items = _categories;
      label = 'Sélectionnez une catégorie';
      labelAr = 'اختر تصنيفاً';
      icon = Icons.category_outlined;
      _log('   📂 Type: CATEGORIE, items: ${items.length}');
    } else if (type == 'formation') {
      items = _formations;
      label = 'Sélectionnez une formation';
      labelAr = 'اختر تكويناً';
      icon = Icons.school_outlined;
      _log('   📚 Type: FORMATION, items: ${items.length}');
    } else if (type == 'video') {
      items = _videos;
      label = 'Sélectionnez une vidéo';
      labelAr = 'اختر فيديو';
      icon = Icons.video_library_outlined;
      _log('   🎬 Type: VIDEO, items: ${items.length}');
    } else if (type == 'page') {
      items = _pages;
      label = 'Sélectionnez une page';
      labelAr = 'اختر صفحة';
      icon = Icons.web_outlined;
      _log('   📄 Type: PAGE, items: ${items.length}');
    }

    if (items.isNotEmpty) {
      _log('   📋 Liste des items disponibles:');
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        final id = item['id'];
        String nameFR = 'N/A';
        String nameAR = 'N/A';
        
        if (type == 'formateur') {
          nameFR = item['nom_prenom_fr'] ?? 'N/A';
          nameAR = item['nom_prenom_ar'] ?? 'N/A';
        } else if (type == 'categorie') {
          nameFR = item['categorie_fr'] ?? 'N/A';
          nameAR = item['categorie_ar'] ?? 'N/A';
        } else if (type == 'formation') {
          nameFR = item['titleFr'] ?? item['title'] ?? 'N/A';
          nameAR = item['titleAr'] ?? item['title'] ?? 'N/A';
        } else if (type == 'video') {
          nameFR = item['titleFr'] ?? 'N/A';
          nameAR = item['titleAr'] ?? 'N/A';
        } else if (type == 'page') {
          nameFR = item['label'] ?? 'N/A';
          nameAR = item['labelAr'] ?? 'N/A';
        }
        _log('      [$i] ID: $id, FR: "$nameFR", AR: "$nameAR"');
      }
    } else {
      _log('   ⚠️ AUCUN ITEM DISPONIBLE');
    }

    bool hasSelected = items.any((item) => item['id'].toString() == selectedItemId);
    _log('   🔍 ID sélectionné "$selectedItemId" existe? $hasSelected');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? labelAr : label,
          style: GoogleFonts.cairo(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        _isLoadingData
            ? const Center(
                child: SizedBox(
                  height: 30,
                  width: 30,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xffd57653)),
                ),
              )
            : items.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey[50],
                    ),
                    child: Center(
                      child: Text(
                        isArabic ? 'لا توجد بيانات' : 'Aucune donnée disponible',
                        style: GoogleFonts.cairo(
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: hasSelected ? selectedItemId : null,
                        hint: Text(
                          isArabic ? '-- اختر --' : '-- Sélectionner --',
                          style: GoogleFonts.cairo(color: Colors.grey[500]),
                        ),
                        items: items.map((item) {
                          String name = _getItemDisplayName(type, item, isArabic);
                          final id = item['id'].toString();
                          
                          return DropdownMenuItem<String>(
                            value: id,
                            child: Row(
                              children: [
                                Icon(
                                  icon ?? Icons.circle,
                                  size: 16,
                                  color: const Color(0xffd57653),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: GoogleFonts.cairo(fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          _log('🔄 [SELECTOR] Changement de valeur: "$value"');
                          if (value != null && value.isNotEmpty) {
                            final selected = items.firstWhere(
                              (item) => item['id'].toString() == value,
                              orElse: () => {},
                            );
                            if (selected.isNotEmpty) {
                              String name = _getItemDisplayName(type, selected, isArabic);
                              _log('✅ [SELECTOR] Sélectionné: "$name" (ID: $value)');
                              onItemSelected(value, name);
                            } else {
                              _log('⚠️ [SELECTOR] Item non trouvé pour ID: $value');
                            }
                          }
                        },
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down_rounded, color: const Color(0xffd57653)),
                        dropdownColor: Colors.white,
                        style: GoogleFonts.cairo(color: const Color(0xff2c221e)),
                        elevation: 2,
                        borderRadius: BorderRadius.circular(10),
                        menuMaxHeight: 300,
                      ),
                    ),
                  ),
        if (selectedItemId.isNotEmpty && !_isLoadingData)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              isArabic ? '✅ تم الاختيار' : '✅ Sélectionné',
              style: GoogleFonts.cairo(
                fontSize: 11,
                color: Colors.green,
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // HELPER : Obtenir le nom d'affichage selon le type
  // ============================================================
  String _getItemDisplayName(String type, Map<String, dynamic> item, bool isArabic) {
    String name = 'Sans nom';
    final id = item['id']?.toString() ?? '?';
    
    try {
      if (type == 'formateur') {
        if (isArabic) {
          name = item['nom_prenom_ar']?.toString() ?? 
                 item['nomPrenomAr']?.toString() ?? 
                 item['nom_ar']?.toString() ??
                 item['nom']?.toString() ??
                 'Formateur $id';
        } else {
          name = item['nom_prenom_fr']?.toString() ?? 
                 item['nomPrenomFr']?.toString() ?? 
                 item['nom_fr']?.toString() ??
                 item['nom']?.toString() ??
                 'Formateur $id';
        }
      } else if (type == 'categorie') {
        if (isArabic) {
          name = item['categorie_ar']?.toString() ?? 
                 item['categorieAr']?.toString() ?? 
                 'Catégorie $id';
        } else {
          name = item['categorie_fr']?.toString() ?? 
                 item['categorieFr']?.toString() ?? 
                 'Catégorie $id';
        }
        if (item['parent_fr'] != null || item['parent_ar'] != null) {
          final parent = isArabic ? item['parent_ar'] : item['parent_fr'];
          if (parent != null) {
            name = '$name (${isArabic ? 'فرع' : 'sous'} : $parent)';
          }
        }
      } else if (type == 'formation') {
        if (isArabic) {
          name = item['titleAr']?.toString() ?? 
                 item['title']?.toString() ?? 
                 'Formation $id';
        } else {
          name = item['titleFr']?.toString() ?? 
                 item['title']?.toString() ?? 
                 'Formation $id';
        }
      } else if (type == 'video') {
        if (isArabic) {
          name = item['titleAr']?.toString() ?? 
                 item['title_ar']?.toString() ?? 
                 'Vidéo $id';
        } else {
          name = item['titleFr']?.toString() ?? 
                 item['title_fr']?.toString() ?? 
                 'Vidéo $id';
        }
      } else if (type == 'page') {
        if (isArabic) {
          name = item['labelAr']?.toString() ?? item['label']?.toString() ?? 'Page $id';
        } else {
          name = item['label']?.toString() ?? item['labelAr']?.toString() ?? 'Page $id';
        }
        if (item['path'] != null) {
          name = '$name (${item['path']})';
        }
      }
      
      if (name.trim().isEmpty || name == 'null' || name == 'Sans nom') {
        name = '${_capitalize(type)} $id';
      }
    } catch (e) {
      _log('❌ [GET_NAME] Erreur: $e');
      name = 'Erreur (ID: $id)';
    }
    
    _log('   🔤 [GET_NAME] Type: $type, ID: $id, Nom: "$name"');
    return name;
  }

  // ============================================================
  // HELPER : Capitalize
  // ============================================================
  String _capitalize(String str) {
    if (str.isEmpty) return str;
    return str[0].toUpperCase() + str.substring(1);
  }

  // ============================================================
  // SNACKBAR HELPER
  // ============================================================
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ============================================================
  // SUPPRIMER UN BULL
  // ============================================================
  Future<void> _deleteBull(BullModel bull) async {
    final isArabic = Provider.of<LanguageProvider>(context, listen: false).isArabic;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isArabic ? '⚠️ تأكيد الحذف' : '⚠️ Confirmation de suppression',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          isArabic
              ? 'هل أنت متأكد من حذف "${bull.title}"؟'
              : 'Êtes-vous sûr de vouloir supprimer "${bull.title}" ?',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              isArabic ? 'إلغاء' : 'Annuler',
              style: GoogleFonts.cairo(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              isArabic ? 'حذف' : 'Supprimer',
              style: GoogleFonts.cairo(),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await BullService.deleteBull(bull.id);
      if (success) {
        await _loadBulls();
        _showSnackBar(
          isArabic ? '✅ تم حذف الرابط بنجاح' : '✅ Lien supprimé avec succès',
          Colors.green,
        );
      }
    }
  }

  // ============================================================
  // TOGGLE ACTIF/INACTIF
  // ============================================================
  Future<void> _toggleBullStatus(BullModel bull) async {
    final updatedBull = bull.copyWith(isActive: !bull.isActive);
    final success = await BullService.updateBull(updatedBull);
    if (success) {
      await _loadBulls();
    }
  }

  // ============================================================
  // RÉORGANISATION DE L'ORDRE DES BULLS
  // ============================================================
  Future<void> _moveBullUp(int index) async {
    if (index <= 0) return;
    
    final updatedBulls = List<BullModel>.from(_bulls);
    final bullToMove = updatedBulls.removeAt(index);
    updatedBulls.insert(index - 1, bullToMove);
    
    for (var i = 0; i < updatedBulls.length; i++) {
      updatedBulls[i] = updatedBulls[i].copyWith(order: i);
    }
    
    setState(() {
      _bulls = updatedBulls;
    });
    
    await _saveOrderToServer(updatedBulls);
  }

  Future<void> _moveBullDown(int index) async {
    if (index >= _bulls.length - 1) return;
    
    final updatedBulls = List<BullModel>.from(_bulls);
    final bullToMove = updatedBulls.removeAt(index);
    updatedBulls.insert(index + 1, bullToMove);
    
    for (var i = 0; i < updatedBulls.length; i++) {
      updatedBulls[i] = updatedBulls[i].copyWith(order: i);
    }
    
    setState(() {
      _bulls = updatedBulls;
    });
    
    await _saveOrderToServer(updatedBulls);
  }

  Future<void> _saveOrderToServer(List<BullModel> orderedBulls) async {
    try {
      final orderedIds = orderedBulls.map((b) => b.id).toList();
      final response = await BullService.reorderBulls(orderedIds);
      
      if (response) {
        _log('✅ [REORDER] Ordre sauvegardé avec succès');
        _showSnackBar('✅ Ordre mis à jour avec succès', Colors.green);
      } else {
        _log('❌ [REORDER] Échec de la sauvegarde');
        _showSnackBar('❌ Erreur lors de la sauvegarde de l\'ordre', Colors.red);
        await _loadBulls();
      }
    } catch (e) {
      _log('❌ [REORDER] Erreur: $e');
      _showSnackBar('❌ Erreur: $e', Colors.red);
      await _loadBulls();
    }
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xfffcfbfa),
      appBar: AppBar(
        title: Text(
          isArabic ? '🎨 إدارة الروابط' : '🎨 Gestion des liens',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Color(0xffd57653)),
            onPressed: () => _showBullDialog(),
            tooltip: isArabic ? 'إضافة رابط' : 'Ajouter un lien',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xffd57653)))
          : _bulls.isEmpty
              ? _buildEmptyState(isArabic)
              : _buildBullsList(isArabic, isMobile),
    );
  }

  Widget _buildEmptyState(bool isArabic) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.link_off_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            isArabic ? 'لا توجد روابط' : 'Aucun lien disponible',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isArabic
                ? 'انقر على زر + لإضافة رابط جديد'
                : 'Cliquez sur le bouton + pour ajouter un lien',
            style: GoogleFonts.cairo(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showBullDialog(),
            icon: const Icon(Icons.add),
            label: Text(isArabic ? 'إضافة رابط' : 'Ajouter un lien'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffd57653),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBullsList(bool isArabic, bool isMobile) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bulls.length,
      itemBuilder: (context, index) {
        final bull = _bulls[index];
        final title = bull.title;
        final isFirst = index == 0;
        final isLast = index == _bulls.length - 1;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: bull.isActive ? const Color(0xffd57653).withOpacity(0.3) : Colors.grey[300]!,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xffd57653).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xffd57653),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: bull.backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: bull.borderColor, width: 2),
                ),
                child: Text(
                  bull.isActive ? title : '$title (inactif)',
                  style: GoogleFonts.cairo(
                    fontSize: bull.fontSize,
                    fontWeight: FontWeight.w600,
                    color: bull.textColor.withOpacity(bull.isActive ? 1 : 0.5),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔗 ${bull.link}',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildInfoChip(
                          isArabic ? 'العربية' : 'Arabe',
                          bull.titleAr ?? 'Non défini',
                        ),
                        _buildInfoChip(
                          isArabic ? 'الفرنسية' : 'Français',
                          bull.titleFr ?? 'Non défini',
                        ),
                        _buildInfoChip(
                          isArabic ? 'الحجم' : 'Taille',
                          '${bull.fontSize.toStringAsFixed(0)}px',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_upward,
                      color: isFirst ? Colors.grey[300] : const Color(0xffd57653),
                      size: 20,
                    ),
                    onPressed: isFirst ? null : () => _moveBullUp(index),
                    tooltip: isArabic ? 'رفع للأعلى' : 'Monter',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.arrow_downward,
                      color: isLast ? Colors.grey[300] : const Color(0xffd57653),
                      size: 20,
                    ),
                    onPressed: isLast ? null : () => _moveBullDown(index),
                    tooltip: isArabic ? 'خفض للأسفل' : 'Descendre',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Color(0xffd57653), size: 20),
                    onPressed: () => _showBullDialog(bullToEdit: bull),
                    tooltip: isArabic ? 'تعديل' : 'Modifier',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  IconButton(
                    icon: Icon(
                      bull.isActive ? Icons.visibility : Icons.visibility_off,
                      color: bull.isActive ? Colors.green : Colors.grey,
                      size: 20,
                    ),
                    onPressed: () => _toggleBullStatus(bull),
                    tooltip: isArabic
                        ? bull.isActive ? 'إخفاء' : 'إظهار'
                        : bull.isActive ? 'Masquer' : 'Afficher',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    onPressed: () => _deleteBull(bull),
                    tooltip: isArabic ? 'حذف' : 'Supprimer',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $value',
        style: GoogleFonts.cairo(
          fontSize: 10,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}