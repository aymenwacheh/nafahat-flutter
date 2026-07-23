// lib/pages/landing/landing_page.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafahat/models/card_config_model.dart';
import 'package:nafahat/pages/formation/formation_detail_page.dart';
import 'package:nafahat/pages/landing/widgets/inscription_section.dart';
import 'package:provider/provider.dart';
import 'package:nafahat/providers/language_provider.dart';
import 'widgets/video_fav_section.dart';
import 'widgets/hero_section.dart';
import 'widgets/navbar.dart';
import 'package:nafahat/models/training_model.dart';
import 'package:nafahat/services/training_service.dart';
import 'package:nafahat/pages/adminisration/add_training_card.dart';
import 'widgets/training_card.dart';
import 'package:nafahat/pages/landing/widgets/navbar.dart';
import 'package:nafahat/services/card_config_service.dart';
import 'package:nafahat/pages/adminisration/apparence_card.dart';

// --- PALETTE DE COULEURS ---
class AppColors {
  static const Color primary = Color(0xffd57653);
  static const Color primaryDark = Color(0xff994a2b);
  static const Color primaryLight = Color(0xfffae6de);
  static const Color surface = Color(0xfffcfbfa);
  static const Color textDark = Color(0xff2c221e);
  static const Color textMuted = Color(0xff7c6e68);
}

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _trainingSectionKey = GlobalKey<_TrainingCyclesSectionState>();

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isArabic = languageProvider.isArabic;
    bool isMobile = MediaQuery.of(context).size.width < 850;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.surface,
        drawer:
            isMobile
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
                    HeroSection(isArabic: isArabic),
                    VideoFavSection(isArabic: isArabic),

                    Padding(
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
                    ),

                    _TrainingCyclesSection(
                      key: _trainingSectionKey,
                      isArabic: isArabic,
                    ),

                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 0 : 20,
                        vertical: 10,
                      ),
                      child: InscriptionSection(
                        isArabic: isArabic,
                        fullWidth: true,
                        showIcon: true,
                        showSubtitle: true,
                        customText:
                            isArabic
                                ? 'ابدأ رحلتك الآن'
                                : 'Commencez votre parcours',
                      ),
                    ),
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

// --- SECTION CYCLES DE FORMATION ---
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

  // Configuration
  CardConfig _config = CardConfig.defaultConfig();
  bool _isConfigLoaded = false;

  // Filtres
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

  // Charger la configuration
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

  @override
  void dispose() {
    super.dispose();
  }

  // Récupérer les formations à afficher selon la config
  List<TrainingModel> _getTrainingsToDisplay() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (_allTrainings.isEmpty) return [];

    if (isMobile && _isConfigLoaded) {
      // MOBILE : Utiliser la configuration
      final displayCount = _config.mobileDisplayCount;
      final selectedIds = _config.mobileSelectedTrainings;

      // Si des formations sont sélectionnées explicitement
      if (selectedIds.isNotEmpty) {
        final selected = <TrainingModel>[];
        for (final id in selectedIds) {
          try {
            final training = _allTrainings.firstWhere((t) => t.id == id);
            selected.add(training);
          } catch (e) {
            // Formation non trouvée, ignorer
          }
        }
        if (selected.isNotEmpty) {
          // Limiter au nombre demandé
          return selected.take(displayCount).toList();
        }
      }

      // Sinon, prendre les N premières formations (les plus récentes car reversed)
      return _allTrainings.take(displayCount).toList();
    }

    // WEB : Toujours les 6 dernières formations (les plus récentes)
    return _allTrainings.take(6).toList();
  }

  Future<void> _loadTrainings() async {
    try {
      final trainings = await TrainingService.getTrainings();
      setState(() {
        _allTrainings = trainings.reversed.toList();
        _extractFilters();
        _applyFilters();

        // Mettre à jour l'affichage avec la nouvelle config
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
      // Mobile : utiliser la configuration
      _displayedTrainings = _getTrainingsToDisplay();
    } else {
      // Web : toujours les 6 dernières formations
      _displayedTrainings = _allTrainings.take(6).toList();
    }
  }

  void _extractFilters() {
    final cats = <String>{'Toutes'};
    final types = <String>{'Tous'};
    final formateurs = <String>{'Tous'};

    for (var t in _allTrainings) {
      if (t.categorieFr.isNotEmpty) cats.add(t.categorieFr);
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
    _filteredTrainings =
        _allTrainings.where((t) {
          bool matchCategorie =
              _selectedCategorie == 'Toutes' ||
              t.categorieFr == _selectedCategorie;
          bool matchType =
              _selectedTypeFormation == 'Tous' ||
              t.typeFormation == _selectedTypeFormation;
          bool matchFormateur =
              _selectedFormateur == 'Tous' || t.trainer == _selectedFormateur;
          return matchCategorie && matchType && matchFormateur;
        }).toList();

    // Mettre à jour l'affichage selon le contexte (mobile ou web)
    _updateDisplayedTrainings();
  }

  Future<void> refreshTrainings() async {
    setState(() => _isLoading = true);
    await _loadConfig();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final paddingHorizontal = isMobile ? 0.0 : (isTablet ? 32.0 : 50.0);

    // Mettre à jour l'affichage à chaque build
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
                    // Bouton "Voir plus" en version mobile
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
                              ? 'اكتشف المزيد من الدورات >>>'
                              : 'Découvrir plus de formations >>>',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
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
          const SizedBox(height: 16),

          // Filtres (uniquement en version desktop)
          if (!isMobile && !_isLoading && _allTrainings.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16.0 : 0.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildElegantFilter(
                      value: _selectedCategorie,
                      items: _categories,
                      label: widget.isArabic ? 'التصنيف' : 'Catégorie',
                      icon: Icons.category_outlined,
                      onChanged: (value) {
                        setState(() {
                          _selectedCategorie = value!;
                          _applyFilters();
                        });
                      },
                      isArabic: widget.isArabic,
                    ),
                    const SizedBox(width: 8),
                    _buildElegantFilter(
                      value: _selectedTypeFormation,
                      items: _typesFormation,
                      label: widget.isArabic ? 'النوع' : 'Type',
                      icon: Icons.school_outlined,
                      onChanged: (value) {
                        setState(() {
                          _selectedTypeFormation = value!;
                          _applyFilters();
                        });
                      },
                      isArabic: widget.isArabic,
                    ),
                    const SizedBox(width: 8),
                    _buildElegantFilter(
                      value: _selectedFormateur,
                      items: _formateurs,
                      label: widget.isArabic ? 'المكون' : 'Formateur',
                      icon: Icons.person_outline,
                      onChanged: (value) {
                        setState(() {
                          _selectedFormateur = value!;
                          _applyFilters();
                        });
                      },
                      isArabic: widget.isArabic,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

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
            _buildTrainingGrid(isMobile, isTablet, screenWidth, screenHeight),
        ],
      ),
    );
  }

  Widget _buildTrainingGrid(
    bool isMobile,
    bool isTablet,
    double screenWidth,
    double screenHeight,
  ) {
    final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);

    double cardWidth;
    double cardHeight;

    final trainings = isMobile ? _displayedTrainings : _filteredTrainings;

    if (isMobile) {
      cardWidth = screenWidth;
      cardHeight = 310.0;
    } else if (isTablet) {
      cardWidth = (screenWidth - 80) / 2 - 20;
      cardHeight = screenHeight * 0.45 > 400 ? 400 : screenHeight * 0.45;
    } else {
      cardWidth = (screenWidth - 140) / 3 - 20;
      cardHeight = screenHeight * 0.45 > 420 ? 420 : screenHeight * 0.45;
    }

    return Column(
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
              // 🔥 Bouton "Découvrir plus" pour la version web
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
                        widget.isArabic
                            ? Icons.arrow_forward_rounded
                            : Icons.arrow_forward_rounded,
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
        Container(
          constraints: BoxConstraints(
            minHeight: cardHeight,
            maxHeight: isMobile ? double.infinity : cardHeight * 2 + 20,
          ),
          child:
              isMobile
                  ? ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: trainings.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: SizedBox(
                          width: cardWidth,
                          height: cardHeight,
                          child: TrainingCard(
                            training: trainings[index],
                            isArabic: widget.isArabic,
                            onRefresh: refreshTrainings,
                            isMobile: true,
                          ),
                        ),
                      );
                    },
                  )
                  : GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: cardWidth / cardHeight,
                      crossAxisSpacing: 20.0,
                      mainAxisSpacing: 20.0,
                    ),
                    itemCount: trainings.length,
                    itemBuilder: (context, index) {
                      return TrainingCard(
                        training: trainings[index],
                        isArabic: widget.isArabic,
                        onRefresh: refreshTrainings,
                        isMobile: false,
                      );
                    },
                  ),
        ),
        // 🔥 Bouton "Voir toutes les formations" en bas de la grille (web uniquement)
        if (!isMobile && _allTrainings.length > 6)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllTrainingsPage(),
                    ),
                  );
                },
                icon: Icon(
                  widget.isArabic
                      ? Icons.arrow_forward_rounded
                      : Icons.arrow_forward_rounded,
                  size: 20,
                ),
                label: Text(
                  widget.isArabic
                      ? 'اكتشف جميع الدورات التدريبية'
                      : 'Découvrir toutes les formations',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
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
    final selectedValue =
        uniqueItems.contains(value) ? value : uniqueItems.first;

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
        items:
            uniqueItems.map((item) {
              String displayText = item;
              if (item == 'Tous' || item == 'Toutes') {
                displayText = isArabic ? 'الكل' : 'Tous';
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

// --- PAGE "TOUTES LES FORMATIONS" ---
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
      body:
          _isLoading
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
