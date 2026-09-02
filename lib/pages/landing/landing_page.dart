// lib/pages/landing/landing_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafahat/models/bull_model.dart';

import 'package:provider/provider.dart';

// Models
import 'package:nafahat/models/card_config_model.dart';
import 'package:nafahat/models/training_model.dart';
import 'package:nafahat/models/SectionOrderModel.dart';

// Services
import 'package:nafahat/services/training_service.dart';
import 'package:nafahat/services/bull_service.dart';
import 'package:nafahat/services/card_config_service.dart';
import 'package:nafahat/services/SectionOrderService.dart';

// Providers
import 'package:nafahat/providers/language_provider.dart';

// Widgets
import 'package:nafahat/pages/widgets/inscription_section.dart';
import 'package:nafahat/pages/widgets/video_fav_section.dart';
import 'package:nafahat/pages/widgets/hero_section.dart';
import 'package:nafahat/pages/widgets/navbar.dart';
import 'package:nafahat/pages/widgets/training_card_section.dart';
import 'package:nafahat/pages/widgets/formateur_section.dart';

import 'package:nafahat/pages/widgets/all_video_page.dart';
import 'package:nafahat/pages/widgets/bull_lien_section.dart';


// Admin pages
import 'package:nafahat/pages/adminisration/add_training_card.dart';

// --- PALETTE DE COULEURS ---
class AppColors {
  static const Color primary = Color(0xffd57653);
  static const Color primaryDark = Color(0xff994a2b);
  static const Color primaryLight = Color(0xfffae6de);
  static const Color surface = Color(0xfffcfbfa);
  static const Color textDark = Color(0xff2c221e);
  static const Color textMuted = Color(0xff7c6e68);
}

// ============================================================
// LANDING PAGE PRINCIPALE
// ============================================================
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _trainingSectionKey = GlobalKey<_TrainingCyclesSectionState>();

  // États pour les sections dynamiques
  List<SectionOrderModel> _sections = [];
  bool _sectionsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  // ============================================================
  // CHARGEMENT DES SECTIONS
  // ============================================================
  Future<void> _loadSections() async {
    final sections = await SectionOrderService.loadSections();
    setState(() {
      _sections = sections.where((s) => s.isActive).toList();
      _sectionsLoaded = true;
    });
  }

  // ============================================================
  // GESTIONNAIRE DE CLIC SUR BULL - NAVIGATION INTELLIGENTE
  // ============================================================
  void _handleBullTap(BuildContext context, BullModel bull) {
    print('🔗 [BULL] Clic sur: ${bull.title}');
    print('   📍 Lien: ${bull.link}');
    
    final link = bull.link;
    
    // ✅ Si c'est un lien vers une catégorie
    if (link.startsWith('/categorie/')) {
      final categorieId = link.replaceAll('/categorie/', '');
      print('   🏷️ Navigation vers catégorie: $categorieId');
      
      Navigator.pushNamed(
        context,
        '/formations',
        arguments: {'categorieId': categorieId},
      );
      return;
    }
    
    // ✅ Si c'est un lien vers un formateur
    if (link.startsWith('/formateur/')) {
      final formateurId = link.replaceAll('/formateur/', '');
      print('   👤 Navigation vers formateur: $formateurId');
      
      Navigator.pushNamed(
        context,
        '/formations',
        arguments: {'formateurId': formateurId},
      );
      return;
    }
    
    // ✅ Si c'est un lien vers une vidéo
    if (link.startsWith('/video/')) {
      final videoId = link.replaceAll('/video/', '');
      print('   🎬 Navigation vers vidéo: $videoId');
      
      Navigator.pushNamed(
        context,
        '/video/$videoId',
      );
      return;
    }
    
    // ✅ Si c'est un lien vers une section (scroll)
    if (link.startsWith('/section/')) {
      final sectionKey = link.replaceAll('/section/', '');
      print('   📑 Navigation vers section: $sectionKey');
      
      _scrollToSection(sectionKey);
      return;
    }
    
    // ✅ Navigation normale (page)
    print('   🔗 Navigation normale vers: $link');
    Navigator.pushNamed(context, link);
  }

  // ============================================================
  // SCROLL VERS UNE SECTION
  // ============================================================
  void _scrollToSection(String sectionKey) {
    final sectionIndex = _sections.indexWhere((s) => s.sectionKey == sectionKey);
    if (sectionIndex != -1) {
      print('   📍 Section trouvée à l\'index: $sectionIndex');
      
      final scrollable = Scrollable.of(context);
      if (scrollable != null) {
        final double position = sectionIndex * 400.0;
        scrollable.position.animateTo(
          position,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    } else {
      print('   ⚠️ Section non trouvée: $sectionKey');
    }
  }

  // ============================================================
  // SECTION BULLS LIENS
  // ============================================================
  Widget _buildBullsSection(bool isArabic, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 50,
        vertical: 8,
      ),
      child: FutureBuilder<List<BullModel>>(
        future: BullService.getBulls(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 50,
              child: Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildDefaultBulls(isArabic);
          }

          final bulls = snapshot.data!;
          final activeBulls = bulls.where((b) => b.isActive).toList();

          if (activeBulls.isEmpty) {
            return _buildDefaultBulls(isArabic);
          }

          return BullsList(
            bulls: activeBulls,
            onBullTap: (bull) {
              _handleBullTap(context, bull);
            },
          );
        },
      ),
    );
  }

  Widget _buildDefaultBulls(bool isArabic) {
    final bulls = BullService.getDefaultBulls();
    return BullsList(
      bulls: bulls,
      onBullTap: (bull) {
        _handleBullTap(context, bull);
      },
    );
  }

  // ============================================================
  // RENDU DES SECTIONS DYNAMIQUES
  // ============================================================
  Widget _buildSection(SectionOrderModel section, bool isMobile, bool isArabic) {
    switch (section.sectionKey) {
      case PredefinedSections.hero:
        return HeroSection(isArabic: isArabic);

      case PredefinedSections.bulls:
        return _buildBullsSection(isArabic, isMobile);

      case PredefinedSections.trainings:
        return _TrainingCyclesSection(
          key: _trainingSectionKey,
          isArabic: isArabic,
        );

      case PredefinedSections.inscription:
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 0 : 20,
            vertical: 10,
          ),
          child: InscriptionSection(
            isArabic: isArabic,
            fullWidth: true,
            showIcon: true,
            showSubtitle: true,
          ),
        );

      case PredefinedSections.videos:
        return VideoFavSection(isArabic: isArabic);

      case PredefinedSections.formateurs:
        return _FormateurSection(isArabic: isArabic);

      default:
        return const SizedBox.shrink();
    }
  }

  // ============================================================
  // BUILD PRINCIPAL
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isArabic = languageProvider.isArabic;
    final bool isMobile = MediaQuery.of(context).size.width < 850;

    if (!_sectionsLoaded) {
      return Scaffold(
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.surface,
        drawer: isMobile
            ? Navbar(
                isMobile: true,
                scaffoldKey: _scaffoldKey,
              ).buildDrawer(context)
            : null,
        body: SafeArea(
          top: false,
          child: Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 90),

                    // ✅ SECTIONS DYNAMIQUES (selon l'ordre défini dans l'admin)
                    ..._sections.map((section) {
                      return _buildSection(section, isMobile, isArabic);
                    }).toList(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Navbar(isMobile: isMobile, scaffoldKey: _scaffoldKey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void refreshTrainings() {
    _trainingSectionKey.currentState?.refreshTrainings();
  }
}

// ============================================================
// SECTION FORMATIONS (UNE SEULE LIGNE)
// ============================================================
class _TrainingCyclesSection extends StatefulWidget {
  final bool isArabic;

  const _TrainingCyclesSection({super.key, required this.isArabic});

  @override
  State<_TrainingCyclesSection> createState() => _TrainingCyclesSectionState();
}

class _TrainingCyclesSectionState extends State<_TrainingCyclesSection> {
  List<TrainingModel> _allTrainings = [];
  List<TrainingModel> _filteredTrainings = [];
  List<TrainingModel> _displayedTrainings = [];
  bool _isLoading = true;

  CardConfig _config = CardConfig.defaultConfig();
  bool _isConfigLoaded = false;

  String _selectedCategorie = 'Toutes';
  String _selectedTypeFormation = 'Tous';
  String _selectedFormateur = 'Tous';
  List<String> _categories = ['Toutes'];
  List<String> _typesFormation = ['Tous'];
  List<String> _formateurs = ['Tous'];

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await CardConfigService().loadConfig();
      setState(() {
        _config = config;
        _isConfigLoaded = true;
      });
      await _loadTrainings();
    } catch (e) {
      setState(() {
        _config = CardConfig.defaultConfig();
        _isConfigLoaded = true;
      });
      await _loadTrainings();
    }
  }

  List<TrainingModel> _getTrainingsToDisplay() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (_allTrainings.isEmpty) return [];

    if (isMobile && _isConfigLoaded) {
      final displayCount = _config.mobileDisplayCount;
      final selectedIds = _config.mobileSelectedTrainings;

      if (selectedIds.isNotEmpty) {
        final selected = <TrainingModel>[];
        for (final id in selectedIds) {
          try {
            final training = _allTrainings.firstWhere((t) => t.id == id);
            selected.add(training);
          } catch (e) {}
        }
        if (selected.isNotEmpty) {
          return selected.take(displayCount).toList();
        }
      }
      return _allTrainings.take(displayCount).toList();
    }

    return _allTrainings.take(6).toList();
  }

  Future<void> _loadTrainings() async {
    try {
      final trainings = await TrainingService.getTrainings();
      setState(() {
        _allTrainings = trainings.reversed.toList();
        _extractFilters();
        _applyFilters();
        _updateDisplayedTrainings();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _allTrainings = [];
        _filteredTrainings = [];
        _displayedTrainings = [];
        _isLoading = false;
      });
    }
  }

  void _updateDisplayedTrainings() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      _displayedTrainings = _getTrainingsToDisplay();
    } else {
      _displayedTrainings = _allTrainings.take(6).toList();
    }
  }

  void _extractFilters() {
    final cats = <String>{'Toutes'};
    final types = <String>{'Tous'};
    final formateurs = <String>{'Tous'};

    for (var t in _allTrainings) {
      if (t.categorieFr.isNotEmpty) cats.add(t.categorieFr);
      if (t.categorieAr.isNotEmpty) cats.add(t.categorieAr);
      if (t.typeFormation.isNotEmpty) types.add(t.typeFormation);
      if (t.trainer.isNotEmpty) formateurs.add(t.trainer);
    }

    setState(() {
      _categories = cats.toList();
      _typesFormation = types.toList();
      _formateurs = formateurs.toList();

      if (!_categories.contains(_selectedCategorie)) {
        _selectedCategorie = 'Toutes';
      }
      if (!_typesFormation.contains(_selectedTypeFormation)) {
        _selectedTypeFormation = 'Tous';
      }
      if (!_formateurs.contains(_selectedFormateur)) {
        _selectedFormateur = 'Tous';
      }
    });
  }

  void _applyFilters() {
    _filteredTrainings = _allTrainings.where((t) {
      bool matchCategorie = _selectedCategorie == 'Toutes' ||
          t.categorieFr == _selectedCategorie ||
          t.categorieAr == _selectedCategorie;
      bool matchType = _selectedTypeFormation == 'Tous' ||
          t.typeFormation == _selectedTypeFormation;
      bool matchFormateur = _selectedFormateur == 'Tous' ||
          t.trainer == _selectedFormateur;
      return matchCategorie && matchType && matchFormateur;
    }).toList();

    _updateDisplayedTrainings();
  }

  Future<void> refreshTrainings() async {
    setState(() => _isLoading = true);
    await _loadConfig();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final paddingHorizontal = isMobile ? 0.0 : (isTablet ? 32.0 : 50.0);

    _updateDisplayedTrainings();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: paddingHorizontal,
        vertical: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16.0 : 0.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.isArabic
                      ? "برامجنا التدريبية"
                      : "Nos Cycles de Formation",
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 22 : 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                Row(
                  children: [
                    if (isMobile && _allTrainings.length > 3)
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AllTrainingsPage(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                        child: Text(
                          widget.isArabic
                              ? 'اكتشف المزيد >>>'
                              : 'Découvrir plus >>>',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AppColors.primary),
                      onPressed: refreshTrainings,
                      tooltip: widget.isArabic ? 'تحديث' : 'Rafraîchir',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

         
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_allTrainings.isEmpty)
            _buildEmptyState()
          else if (_displayedTrainings.isEmpty && isMobile)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 48,
                      color: AppColors.textMuted.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.isArabic
                          ? 'Aucune formation disponible pour l\'affichage mobile'
                          : 'Aucune formation disponible pour l\'affichage mobile',
                      style: GoogleFonts.cairo(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AllTrainingsPage(),
                          ),
                        );
                      },
                      child: Text(
                        widget.isArabic
                            ? 'Voir toutes les formations'
                            : 'Voir toutes les formations',
                        style: GoogleFonts.cairo(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_filteredTrainings.isEmpty && !isMobile)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  widget.isArabic
                      ? 'لا توجد تكوينات تطابق الفلتر'
                      : 'Aucune formation ne correspond aux filtres',
                  style: GoogleFonts.cairo(
                    color: AppColors.textMuted,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else
            _buildTrainingRow(isMobile, isTablet),
        ],
      ),
    );
  }

  Widget _buildTrainingRow(bool isMobile, bool isTablet) {
    final trainings = isMobile ? _displayedTrainings : _filteredTrainings;

    double cardWidth;
    double cardHeight;

    if (isMobile) {
      cardWidth = 220.0;
      cardHeight = 240.0;
    } else if (isTablet) {
      cardWidth = 280.0;
      cardHeight = 300.0;
    } else {
      cardWidth = 300.0;
      cardHeight = 320.0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16.0 : 0.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.isArabic
                    ? '${trainings.length} تكوين'
                    : '${trainings.length} formation${trainings.length > 1 ? 's' : ''}',
                style: GoogleFonts.cairo(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
              if (!isMobile && _allTrainings.length > 6)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AllTrainingsPage(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        widget.isArabic
                            ? 'اكتشف المزيد من الدورات'
                            : 'Découvrir plus de formations',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: cardHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: trainings.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 12, left: 4),
                child: SizedBox(
                  width: cardWidth,
                  height: cardHeight,
                  child: TrainingCard(
                    training: trainings[index],
                    isArabic: widget.isArabic,
                    onRefresh: refreshTrainings,
                    isMobile: isMobile,
                  ),
                ),
              );
            },
          ),
        ),
        if (isMobile && _allTrainings.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AllTrainingsPage(),
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              child: Text(
                widget.isArabic
                    ? 'اكتشف المزيد من الدورات >>>'
                    : 'Découvrir plus de formations >>>',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildElegantFilter({
    required String value,
    required List<String> items,
    required String label,
    required IconData icon,
    required ValueChanged<String?> onChanged,
    required bool isArabic,
  }) {
    final uniqueItems = items.toSet().toList();
    final selectedValue = uniqueItems.contains(value) ? value : uniqueItems.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
        borderRadius: BorderRadius.circular(30),
        color: Colors.white,
      ),
      child: DropdownButton<String>(
        value: selectedValue,
        underline: const SizedBox(),
        hint: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        items: uniqueItems.map((item) {
          String displayText = item;
          if (item == 'Tous' || item == 'Toutes') {
            displayText = isArabic ? 'الكل' : 'Tous';
          } else {
            if (isArabic) {
              for (var t in _allTrainings) {
                if (t.categorieFr == item && t.categorieAr.isNotEmpty) {
                  displayText = t.categorieAr;
                  break;
                }
              }
            }
          }
          return DropdownMenuItem<String>(
            value: item,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                displayText,
                style: GoogleFonts.cairo(fontSize: 13),
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        icon: Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
        dropdownColor: Colors.white,
        style: GoogleFonts.cairo(color: AppColors.textDark),
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.school_outlined,
            size: 80,
            color: AppColors.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            widget.isArabic
                ? 'لا توجد تكوينات حالياً'
                : 'Aucune formation disponible',
            style: GoogleFonts.cairo(color: AppColors.textMuted, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isArabic
                ? 'قم بإضافة تكوين جديد من لوحة التحكم'
                : 'Ajoutez une formation depuis le panneau d\'administration',
            style: GoogleFonts.cairo(
              color: AppColors.textMuted.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddTrainingCardPage(),
                ),
              ).then((_) {
                refreshTrainings();
              });
            },
            icon: const Icon(Icons.add),
            label: Text(
              widget.isArabic ? 'إضافة تكوين' : 'Ajouter une formation',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION FORMATEURS (UNE SEULE LIGNE)
// ============================================================
class _FormateurSection extends StatefulWidget {
  final bool isArabic;

  const _FormateurSection({required this.isArabic});

  @override
  State<_FormateurSection> createState() => _FormateurSectionState();
}

class _FormateurSectionState extends State<_FormateurSection> {
  List<Map<String, dynamic>> _formateurs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFormateurs();
  }

  Future<void> _loadFormateurs() async {
    try {
      final formateurs = await TrainingService.getFormateurs();
      setState(() {
        _formateurs = formateurs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _formateurs = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = widget.isArabic;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 50,
        vertical: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'مكونونا' : 'Nos Formateurs',
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 22 : 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isArabic
                ? 'خبراء في مجالاتهم لمرافقتك في رحلتك التعليمية'
                : 'Des experts dans leurs domaines pour vous accompagner',
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 14 : 16,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_formateurs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 48,
                      color: AppColors.textMuted.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isArabic
                          ? 'لا يوجد مكونين حالياً'
                          : 'Aucun formateur disponible',
                      style: GoogleFonts.cairo(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            _buildFormateurRow(isMobile),
        ],
      ),
    );
  }

  Widget _buildFormateurRow(bool isMobile) {
    final displayedFormateurs =
        _formateurs.length > 8 ? _formateurs.sublist(0, 8) : _formateurs;

    double cardWidth = isMobile ? 180.0 : 220.0;
    double cardHeight = isMobile ? 195.0 : 225.0;

    return SizedBox(
      height: cardHeight + 20,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: displayedFormateurs.length,
        itemBuilder: (context, index) {
          final formateur = displayedFormateurs[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12, left: 4),
            child: SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: FormateurCard(
                formateur: formateur,
                isArabic: widget.isArabic,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// PAGE "TOUTES LES FORMATIONS"
// ============================================================
class AllTrainingsPage extends StatefulWidget {
  const AllTrainingsPage({super.key});

  @override
  State<AllTrainingsPage> createState() => _AllTrainingsPageState();
}

class _AllTrainingsPageState extends State<AllTrainingsPage> {
  List<TrainingModel> _trainings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllTrainings();
  }

  Future<void> _loadAllTrainings() async {
    try {
      final trainings = await TrainingService.getTrainings();
      setState(() {
        _trainings = trainings.reversed.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _trainings = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isArabic ? 'جميع التكوينات' : 'Toutes les formations',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllTrainings,
            tooltip: isArabic ? 'تحديث' : 'Rafraîchir',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _trainings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 80,
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isArabic
                            ? 'لا توجد تكوينات حالياً'
                            : 'Aucune formation disponible',
                        style: GoogleFonts.cairo(
                          color: AppColors.textMuted,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: EdgeInsets.all(isMobile ? 12 : 24),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 1 : 3,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _trainings.length,
                    itemBuilder: (context, index) {
                      return TrainingCard(
                        training: _trainings[index],
                        isArabic: isArabic,
                        onRefresh: _loadAllTrainings,
                        isMobile: isMobile,
                      );
                    },
                  ),
                ),
    );
  }
}