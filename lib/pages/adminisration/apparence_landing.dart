// lib/pages/adminisration/apparition_landing.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafahat/models/SectionOrderModel.dart';
import 'package:nafahat/services/SectionOrderService.dart';
import 'package:nafahat/providers/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

class ApparitionLandingPage extends StatefulWidget {
  const ApparitionLandingPage({super.key});

  @override
  State<ApparitionLandingPage> createState() => _ApparitionLandingPageState();
}

class _ApparitionLandingPageState extends State<ApparitionLandingPage> {
  List<SectionOrderModel> _sections = [];
  bool _isLoading = true;
  bool _isSaving = false;

  // Sections disponibles pour duplication avec couleurs
  final List<Map<String, dynamic>> _availableSections = [
    {
      'key': PredefinedSections.hero,
      'title': 'Hero Section',
      'titleAr': 'قسم الهيرو',
      'icon': Icons.home_outlined,
      'color': Colors.blue,
    },
    {
      'key': PredefinedSections.bulls,
      'title': 'Bulls Liens',
      'titleAr': 'وحدات الروابط',
      'icon': Icons.link_rounded,
      'color': Colors.orange,
    },
    {
      'key': PredefinedSections.trainings,
      'title': 'Formations',
      'titleAr': 'التكوينات',
      'icon': Icons.school_outlined,
      'color': const Color(0xff0D443E),
    },
    {
      'key': PredefinedSections.inscription,
      'title': 'Inscription',
      'titleAr': 'التسجيل',
      'icon': Icons.assignment_outlined,
      'color': Colors.green,
    },
    {
      'key': PredefinedSections.videos,
      'title': 'Vidéos Favorites',
      'titleAr': 'الفيديوهات المفضلة',
      'icon': Icons.video_library_outlined,
      'color': Colors.purple,
    },
    {
      'key': PredefinedSections.formateurs,
      'title': 'Formateurs',
      'titleAr': 'المكونين',
      'icon': Icons.person_outline,
      'color': const Color(0xffd57653),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  Future<void> _loadSections() async {
    setState(() => _isLoading = true);
    final sections = await SectionOrderService.loadSections();
    setState(() {
      _sections = sections;
      _isLoading = false;
    });
  }

  Future<void> _saveSections() async {
    setState(() => _isSaving = true);
    await SectionOrderService.saveSections(_sections);
    setState(() => _isSaving = false);
    
    final isArabic = Provider.of<LanguageProvider>(context, listen: false).isArabic;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabic ? '✅ تم حفظ الترتيب بنجاح' : '✅ Ordre sauvegardé avec succès',
          style: GoogleFonts.cairo(),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ============================================================
  // AJOUTER UNE SECTION EN DOUBLE
  // ============================================================
  void _addDuplicateSection(String sectionKey) {
    final baseSection = _availableSections.firstWhere(
      (s) => s['key'] == sectionKey,
      orElse: () => _availableSections.first,
    );

    // Compter combien de fois cette section existe déjà
    final existingCount = _sections.where((s) => s.sectionKey == sectionKey).length;

    final newSection = SectionOrderModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sectionKey: sectionKey,
      title: '${baseSection['title']} (${existingCount + 1})',
      titleAr: '${baseSection['titleAr']} (${existingCount + 1})',
      icon: baseSection['icon'] as IconData,
      order: _sections.length,
      isActive: true,
      isDuplicate: true,
    );

    setState(() {
      _sections.add(newSection);
      _updateOrders();
    });
  }

  // ============================================================
  // SUPPRIMER UNE SECTION
  // ============================================================
  void _removeSection(String id) {
    final section = _sections.firstWhere((s) => s.id == id);
    
    // Ne pas supprimer si c'est la seule instance de cette section
    final sameKeyCount = _sections.where((s) => s.sectionKey == section.sectionKey).length;
    if (sameKeyCount <= 1) {
      final isArabic = Provider.of<LanguageProvider>(context, listen: false).isArabic;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? '⚠️ Vous devez garder au moins une instance de cette section'
                : '⚠️ Vous devez garder au moins une instance de cette section',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() {
      _sections.removeWhere((s) => s.id == id);
      _updateOrders();
    });
  }

  // ============================================================
  // METTRE À JOUR LES ORDRES
  // ============================================================
  void _updateOrders() {
    for (int i = 0; i < _sections.length; i++) {
      _sections[i] = _sections[i].copyWith(order: i);
    }
  }

  // ============================================================
  // TOGGLE ACTIF/INACTIF
  // ============================================================
  void _toggleActive(String id) {
    setState(() {
      final index = _sections.indexWhere((s) => s.id == id);
      if (index != -1) {
        _sections[index] = _sections[index].copyWith(
          isActive: !_sections[index].isActive,
        );
      }
    });
  }

  // ============================================================
  // RÉINITIALISER
  // ============================================================
  Future<void> _resetToDefault() async {
    final isArabic = Provider.of<LanguageProvider>(context, listen: false).isArabic;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isArabic ? '⚠️ إعادة تعيين' : '⚠️ Réinitialiser',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          isArabic
              ? 'Voulez-vous vraiment réinitialiser l\'ordre des sections ?'
              : 'Voulez-vous vraiment réinitialiser l\'ordre des sections ?',
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
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(
              isArabic ? 'إعادة تعيين' : 'Réinitialiser',
              style: GoogleFonts.cairo(),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SectionOrderService.resetToDefault();
      await _loadSections();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? '✅ تم إعادة التعيين' : '✅ Réinitialisé avec succès',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: const Color(0xff0D443E),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
          isArabic ? '🎨 إدارة ترتيب الصفحة' : '🎨 Gestion de l\'ordre des sections',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.restore_rounded, color: Colors.red),
            onPressed: _resetToDefault,
            tooltip: isArabic ? 'إعادة تعيين' : 'Réinitialiser',
          ),
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded, color: Color(0xff0D443E)),
            onPressed: _isSaving ? null : _saveSections,
            tooltip: isArabic ? 'حفظ' : 'Sauvegarder',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xffd57653)))
          : Column(
              children: [
                // ============================================================
                // INFO BANNER
                // ============================================================
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xffd57653).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xffd57653).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: const Color(0xffd57653),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isArabic
                              ? '🔄 Glissez-déposez les sections pour les réorganiser. Une section en double affiche le même contenu à un emplacement différent.'
                              : '🔄 Glissez-déposez les sections pour les réorganiser. Une section en double affiche le même contenu à un emplacement différent.',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: const Color(0xff4a3f3a),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ============================================================
                // BOUTON AJOUTER UNE SECTION EN DOUBLE
                // ============================================================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showAddDuplicateDialog(context, isArabic),
                          icon: const Icon(Icons.copy_rounded, color: Color(0xffd57653)),
                          label: Text(
                            isArabic ? '➕ إضافة قسم مكرر' : '➕ Ajouter une section en double',
                            style: GoogleFonts.cairo(
                              color: const Color(0xffd57653),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xffd57653)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ============================================================
                // LISTE DES SECTIONS (DRAG & DROP)
                // ============================================================
                Expanded(
                  child: ReorderableGridView.builder(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: isMobile ? 350 : 400,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.4,
                    ),
                    itemCount: _sections.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (oldIndex < newIndex) {
                          newIndex -= 1;
                        }
                        final item = _sections.removeAt(oldIndex);
                        _sections.insert(newIndex, item);
                        _updateOrders();
                      });
                    },
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final section = _sections[index];
                      final isActive = section.isActive;
                      final isDuplicate = section.isDuplicate;
                      final displayTitle = isArabic ? section.titleAr : section.title;
                      
                      // ✅ Trouver la couleur associée à cette section
                      final color = _getSectionColor(section.sectionKey);
                      
                      return Card(
                        key: ValueKey(section.id),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isActive
                                ? color.withOpacity(0.3)
                                : Colors.grey[300]!,
                            width: isActive ? 2 : 1,
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isActive ? Colors.white : Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Handle (drag)
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.drag_handle_rounded,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  // Icon avec couleur
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      section.icon,
                                      color: color,
                                      size: 24,
                                    ),
                                  ),
                                  // Status
                                  Row(
                                    children: [
                                      if (isDuplicate)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.purple.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '🔄',
                                            style: GoogleFonts.cairo(fontSize: 10),
                                          ),
                                        ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: Icon(
                                          isActive
                                              ? Icons.visibility_rounded
                                              : Icons.visibility_off_rounded,
                                          color: isActive ? Colors.green : Colors.grey,
                                          size: 20,
                                        ),
                                        onPressed: () => _toggleActive(section.id),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        onPressed: () => _removeSection(section.id),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '#${section.order + 1} $displayTitle',
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                                  color: isActive
                                      ? const Color(0xff2c221e)
                                      : Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (isDuplicate)
                                Text(
                                  isArabic ? '📋 مكرر' : '📋 Dupliqué',
                                  style: GoogleFonts.cairo(
                                    fontSize: 10,
                                    color: Colors.purple[400],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveSections,
        backgroundColor: const Color(0xff0D443E),
        foregroundColor: Colors.white,
        child: _isSaving
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save_rounded),
        tooltip: isArabic ? 'حفظ الترتيب' : 'Sauvegarder l\'ordre',
      ),
    );
  }

  // ============================================================
  // RÉCUPÉRER LA COULEUR D'UNE SECTION
  // ============================================================
  Color _getSectionColor(String sectionKey) {
    final section = _availableSections.firstWhere(
      (s) => s['key'] == sectionKey,
      orElse: () => _availableSections.first,
    );
    return section['color'] as Color;
  }

  // ============================================================
  // DIALOGUE AJOUTER UNE SECTION EN DOUBLE
  // ============================================================
  void _showAddDuplicateDialog(BuildContext context, bool isArabic) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Text(
          isArabic ? '📋 إضافة قسم مكرر' : '📋 Ajouter une section en double',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isArabic
                  ? 'Sélectionnez une section à dupliquer :'
                  : 'Sélectionnez une section à dupliquer :',
              style: GoogleFonts.cairo(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            ..._availableSections.map((section) {
              final color = section['color'] as Color;
              return ListTile(
                leading: Icon(
                  section['icon'] as IconData,
                  color: color,
                ),
                title: Text(
                  isArabic ? section['titleAr'] : section['title'],
                  style: GoogleFonts.cairo(),
                ),
                trailing: Icon(Icons.copy_rounded, color: color),
                onTap: () {
                  Navigator.pop(context);
                  _addDuplicateSection(section['key']);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                tileColor: Colors.grey[50],
              );
            }).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              isArabic ? 'إلغاء' : 'Annuler',
              style: GoogleFonts.cairo(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}