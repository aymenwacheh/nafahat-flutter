// lib/landing/landing_page.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafahat/pages/formation/formation_detail_page.dart';
import 'widgets/video_fav_section.dart';
import 'widgets/hero_section.dart';
import 'widgets/navbar.dart';
import 'package:nafahat/models/training_model.dart';
import 'package:nafahat/services/training_service.dart';
import 'package:nafahat/pages/adminisration/add_training_card.dart';
import 'widgets/chatbot/chatbot_wrapper.dart';
import 'widgets/training_card.dart'; // 👈 NOUVEL IMPORT

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
  bool isArabic = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _trainingSectionKey = GlobalKey<_TrainingCyclesSectionState>();

  void toggleLanguage() {
    setState(() {
      isArabic = !isArabic;
    });
  }

  void refreshTrainings() {
    _trainingSectionKey.currentState?.refreshTrainings();
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 850;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: ChatbotWrapper(
        apiBaseUrl:
            'http://localhost:3000', // À adapter selon votre configuration
        langue: isArabic ? 'ar' : 'fr',
        primaryColor: AppColors.primary,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.surface,
          drawer:
              isMobile
                  ? Navbar(
                    isArabic: isArabic,
                    isMobile: true,
                    onLanguageToggle: toggleLanguage,
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
                      _TrainingCyclesSection(
                        key: _trainingSectionKey,
                        isArabic: isArabic,
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Navbar(
                    isArabic: isArabic,
                    isMobile: isMobile,
                    onLanguageToggle: toggleLanguage,
                    scaffoldKey: _scaffoldKey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
  bool _isLoading = true;
  int _currentPage = 0;
  final int _itemsPerPage = 6;

  String _selectedCategorie = 'Toutes';
  String _selectedTypeFormation = 'Tous';
  String _selectedFormateur = 'Tous';
  List<String> _categories = ['Toutes'];
  List<String> _typesFormation = ['Tous'];
  List<String> _formateurs = ['Tous'];

  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    _loadTrainings();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void _initPageController() {
    if (_pageController == null && _totalPages > 1) {
      _pageController = PageController(initialPage: _currentPage);
    }
  }

  Future<void> _loadTrainings() async {
    try {
      final trainings = await TrainingService.getTrainings();
      _allTrainings = trainings.reversed.toList();
      _extractFilters();
      _applyFilters();
      setState(() => _isLoading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initPageController();
      });
    } catch (e) {
      setState(() {
        _allTrainings = [];
        _filteredTrainings = [];
        _isLoading = false;
      });
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

    _currentPage = 0;
    _pageController?.dispose();
    _pageController = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPageController();
    });
  }

  Future<void> refreshTrainings() async {
    setState(() => _isLoading = true);
    await _loadTrainings();
  }

  int get _totalPages =>
      _filteredTrainings.isEmpty
          ? 0
          : (_filteredTrainings.length / _itemsPerPage).ceil();

  void _nextPage() {
    if (_pageController != null && _currentPage < _totalPages - 1) {
      setState(() => _currentPage++);
      _pageController!.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_pageController != null && _currentPage > 0) {
      setState(() => _currentPage--);
      _pageController!.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final paddingHorizontal = isMobile ? 0.0 : (isTablet ? 32.0 : 50.0);

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
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.primary),
                  onPressed: refreshTrainings,
                  tooltip: widget.isArabic ? 'تحديث' : 'Rafraîchir',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (!_isLoading && _allTrainings.isNotEmpty) ...[
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
          else if (_filteredTrainings.isEmpty)
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
    int rowsPerPage;

    if (isMobile) {
      cardWidth = screenWidth;
      cardHeight = 360.0;
      rowsPerPage = 100;
    } else if (isTablet) {
      cardWidth = (screenWidth - 80) / 2 - 20;
      cardHeight = screenHeight * 0.45 > 400 ? 400 : screenHeight * 0.45;
      rowsPerPage = 2;
    } else {
      cardWidth = (screenWidth - 140) / 3 - 20;
      cardHeight = screenHeight * 0.45 > 420 ? 420 : screenHeight * 0.45;
      rowsPerPage = 2;
    }

    final itemsPerPage = rowsPerPage * crossAxisCount;

    double gridHeight;
    if (isMobile) {
      gridHeight =
          (cardHeight * _filteredTrainings.length) +
          (20 * (_filteredTrainings.length - 1));
      gridHeight = gridHeight > 600 ? 600 : gridHeight;
    } else {
      gridHeight = (cardHeight * rowsPerPage) + (20 * (rowsPerPage - 1));
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
                    ? '${_filteredTrainings.length} تكوين'
                    : '${_filteredTrainings.length} formation${_filteredTrainings.length > 1 ? 's' : ''}',
                style: GoogleFonts.cairo(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
              if (_totalPages > 1 && !isMobile)
                Text(
                  widget.isArabic
                      ? 'صفحة ${_currentPage + 1} / $_totalPages'
                      : 'Page ${_currentPage + 1} / $_totalPages',
                  style: GoogleFonts.cairo(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ),
        Container(
          constraints: BoxConstraints(
            minHeight: cardHeight,
            maxHeight: isMobile ? double.infinity : gridHeight,
          ),
          child:
              isMobile
                  ? ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _filteredTrainings.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: SizedBox(
                          width: cardWidth,
                          height: cardHeight,
                          child: TrainingCard(
                            // 👈 REMPLACÉ _TrainingCard par TrainingCard
                            training: _filteredTrainings[index],
                            isArabic: widget.isArabic,
                            onRefresh: refreshTrainings,
                            isMobile: true,
                          ),
                        ),
                      );
                    },
                  )
                  : (_totalPages > 1 && _pageController != null
                      ? PageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() => _currentPage = index);
                        },
                        children: List.generate(_totalPages, (pageIndex) {
                          final start = pageIndex * itemsPerPage;
                          final end = start + itemsPerPage;
                          final pageItems = _filteredTrainings.sublist(
                            start,
                            end > _filteredTrainings.length
                                ? _filteredTrainings.length
                                : end,
                          );
                          return GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  childAspectRatio: cardWidth / cardHeight,
                                  crossAxisSpacing: 20.0,
                                  mainAxisSpacing: 20.0,
                                ),
                            itemCount: pageItems.length,
                            itemBuilder: (context, index) {
                              return TrainingCard(
                                // 👈 REMPLACÉ _TrainingCard par TrainingCard
                                training: pageItems[index],
                                isArabic: widget.isArabic,
                                onRefresh: refreshTrainings,
                                isMobile: false,
                              );
                            },
                          );
                        }),
                      )
                      : GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: cardWidth / cardHeight,
                          crossAxisSpacing: 20.0,
                          mainAxisSpacing: 20.0,
                        ),
                        itemCount: _filteredTrainings.length,
                        itemBuilder: (context, index) {
                          return TrainingCard(
                            // 👈 REMPLACÉ _TrainingCard par TrainingCard
                            training: _filteredTrainings[index],
                            isArabic: widget.isArabic,
                            onRefresh: refreshTrainings,
                            isMobile: false,
                          );
                        },
                      )),
        ),
        if (_totalPages > 1 && !isMobile)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _prevPage,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          _currentPage > 0
                              ? AppColors.primary
                              : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.isArabic
                          ? Icons.arrow_forward_rounded
                          : Icons.arrow_back_rounded,
                      color:
                          _currentPage > 0
                              ? Colors.white
                              : Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                  style: IconButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: List.generate(_totalPages, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            _currentPage == index
                                ? AppColors.primary
                                : Colors.grey.shade300,
                      ),
                    );
                  }),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _nextPage,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          _currentPage < _totalPages - 1
                              ? AppColors.primary
                              : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.isArabic
                          ? Icons.arrow_back_rounded
                          : Icons.arrow_forward_rounded,
                      color:
                          _currentPage < _totalPages - 1
                              ? Colors.white
                              : Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                  style: IconButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
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
