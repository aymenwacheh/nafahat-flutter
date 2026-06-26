import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafahat/pages/formation/formation_detail_page.dart';
import 'package:nafahat/src/features/landing/presentation/widgets/video_fav_section.dart';
import 'widgets/hero_section.dart';
import 'widgets/navbar.dart';
import 'package:nafahat/models/training_model.dart';
import 'package:nafahat/services/training_service.dart';
import 'package:nafahat/pages/adminisration/add_training_card.dart';
import 'package:nafahat/pages/adminisration/add_video_fav_page.dart';
import 'package:nafahat/pages/adminisration/add_categorie.dart';
import 'package:nafahat/pages/adminisration/add_formateur.dart';
import 'package:nafahat/pages/adminisration/administration_page.dart';
import 'package:nafahat/pages/adminisration/edit_formation.dart';
import 'package:nafahat/pages/adminisration/edit_categorie.dart';
import 'package:nafahat/pages/users/edit_profile_page.dart';
import 'package:nafahat/pages/users/profile_dashboard_page.dart';
import 'package:nafahat/pages/users/auth_page.dart';

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
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.surface,
        drawer:
            isMobile
                ? _MobileDrawer(
                  isArabic: isArabic,
                  onLanguageToggle: toggleLanguage,
                )
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
    );
  }
}

// --- DRAWER MOBILE ---
class _MobileDrawer extends StatelessWidget {
  final bool isArabic;
  final VoidCallback onLanguageToggle;

  const _MobileDrawer({required this.isArabic, required this.onLanguageToggle});

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = true;
    final bool isUserLoggedIn = true;

    return Drawer(
      backgroundColor: Colors.white.withOpacity(0.92),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Column(
          children: [
            // --- En-tête du Drawer ---
            Container(
              height: 120,
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/logo.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic ? "نفحات" : "Nafahat",
                        style: GoogleFonts.cairo(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        isArabic
                            ? "منصة التدريب والتطوير"
                            : "Plateforme de formation",
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                children: [
                  // --- Liens principaux ---
                  _drawerTile(
                    icon: Icons.home_outlined,
                    title: isArabic ? "الرئيسية" : "Accueil",
                    onTap: () => Navigator.pop(context),
                  ),
                  _drawerTile(
                    icon: Icons.video_library_outlined,
                    title: isArabic ? "فيديوهات مميزة" : "Vidéos Favorites",
                    onTap: () => Navigator.pop(context),
                  ),
                  _drawerTile(
                    icon: Icons.school_outlined,
                    title: isArabic ? "الدورات" : "Cycles de Formation",
                    onTap: () => Navigator.pop(context),
                  ),
                  _drawerTile(
                    icon: Icons.info_outline,
                    title: isArabic ? "عن المنصة" : "À propos",
                    onTap: () => Navigator.pop(context),
                  ),

                  const Divider(height: 30, thickness: 1),

                  // --- ADMINISTRATION (avec sous-menus) ---
                  if (isAdmin)
                    ExpansionTile(
                      leading: Icon(
                        Icons.admin_panel_settings,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        isArabic ? "⚙️ الإدارة" : "⚙️ Administration",
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.primary,
                        ),
                      ),
                      iconColor: AppColors.primary,
                      collapsedIconColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      children: [
                        // --- Toutes les options d'administration ---
                        _drawerTile(
                          icon: Icons.dashboard_outlined,
                          title:
                              isArabic
                                  ? "🖥️ لوحة الإدارة الكاملة"
                                  : "🖥️ Administration complète",
                          padding: const EdgeInsets.only(left: 32),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const AdministrationPage(),
                              ),
                            );
                          },
                        ),
                        _drawerTile(
                          icon: Icons.add_circle_outline,
                          title: isArabic ? "إضافة تكوين" : "Ajouter formation",
                          padding: const EdgeInsets.only(left: 32),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const AddTrainingCardPage(),
                              ),
                            );
                          },
                        ),
                        _drawerTile(
                          icon: Icons.edit,
                          title:
                              isArabic
                                  ? "تعديل تكوين"
                                  : "Modifier une formation",
                          padding: const EdgeInsets.only(left: 32),
                          onTap: () {
                            Navigator.pop(context);
                            _showEditTrainingDialog(context);
                          },
                        ),
                        _drawerTile(
                          icon: Icons.category_outlined,
                          title: isArabic ? "إضافة تصنيف" : "Ajouter catégorie",
                          padding: const EdgeInsets.only(left: 32),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddCategoriePage(),
                              ),
                            );
                          },
                        ),
                        _drawerTile(
                          icon: Icons.edit,
                          title:
                              isArabic
                                  ? "تعديل تصنيف"
                                  : "Modifier une catégorie",
                          padding: const EdgeInsets.only(left: 32),
                          onTap: () {
                            Navigator.pop(context);
                            _showEditCategorieDialog(context);
                          },
                        ),
                        _drawerTile(
                          icon: Icons.person_add,
                          title: isArabic ? "إضافة مكون" : "Ajouter formateur",
                          padding: const EdgeInsets.only(left: 32),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddFormateurPage(),
                              ),
                            );
                          },
                        ),
                        _drawerTile(
                          icon: Icons.video_library_outlined,
                          title: isArabic ? "إضافة فيديو" : "Ajouter vidéo",
                          padding: const EdgeInsets.only(left: 32),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddVideoFavPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                  const Divider(height: 30, thickness: 1),

                  // --- PROFIL (avec sous-menus) ---
                  if (isUserLoggedIn)
                    ExpansionTile(
                      leading: Icon(
                        Icons.person_outline,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        isArabic ? "👤 حسابي" : "👤 Mon compte",
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.primary,
                        ),
                      ),
                      iconColor: AppColors.primary,
                      collapsedIconColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      children: [
                        _drawerTile(
                          icon: Icons.person_outline,
                          title: isArabic ? "ملفي الشخصي" : "Mon profil",
                          padding: const EdgeInsets.only(left: 32),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfilePage(),
                              ),
                            );
                          },
                        ),
                        _drawerTile(
                          icon: Icons.dashboard_outlined,
                          title: isArabic ? "لوحة التحكم" : "Tableau de bord",
                          padding: const EdgeInsets.only(left: 32),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const ProfileDashboardPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                  const Divider(height: 30, thickness: 1),

                  // --- TRAITER L'ACTIVITÉ ---
                  _drawerTile(
                    icon: Icons.build_circle_outlined,
                    title:
                        isArabic ? "🔧 معالجة النشاط" : "🔧 Traiter l'activité",
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Ajouter la logique pour traiter l'activité
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isArabic
                                ? 'معالجة النشاط - قريباً'
                                : 'Traitement de l\'activité - Bientôt disponible',
                          ),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                  ),

                  const Divider(height: 30, thickness: 1),

                  // --- DÉCONNEXION ---
                  if (isUserLoggedIn)
                    _drawerTile(
                      icon: Icons.logout_rounded,
                      title: isArabic ? "تسجيل الخروج" : "Déconnexion",
                      color: Colors.red,
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Logique de déconnexion
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isArabic
                                  ? "🔓 تم تسجيل الخروج بنجاح"
                                  : "🔓 Déconnexion réussie",
                            ),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 20),

                  // --- Bouton Langue ---
                  ListTile(
                    leading: const Icon(
                      Icons.language,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      isArabic ? "Changer en Français" : "تغيير إلى العربية",
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                        fontSize: 15,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onLanguageToggle();
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: AppColors.primary.withOpacity(0.06),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = AppColors.textDark,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color == AppColors.textDark ? AppColors.textMuted : color,
      ),
      title: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: Colors.transparent,
      hoverColor: AppColors.primary.withOpacity(0.05),
      contentPadding: padding,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
    );
  }

  // --- Dialogues d'édition ---
  void _showEditTrainingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            isArabic ? 'تعديل تكوين' : 'Modifier une formation',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isArabic
                      ? 'أدخل معرف التكوين لتعديله'
                      : 'Entrez l\'ID de la formation à modifier',
                  style: GoogleFonts.cairo(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    hintText: isArabic ? 'معرف التكوين' : 'ID de la formation',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  EditFormationPage(formationId: value.trim()),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                isArabic ? 'إلغاء' : 'Annuler',
                style: GoogleFonts.cairo(color: Colors.grey.shade600),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditCategorieDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            isArabic ? 'تعديل تصنيف' : 'Modifier une catégorie',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          content: Text(
            isArabic
                ? 'Entrez l\'ID de la catégorie à modifier'
                : 'Entrez l\'ID de la catégorie à modifier',
            style: GoogleFonts.cairo(color: Colors.grey.shade600, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                isArabic ? 'إلغاء' : 'Annuler',
                style: GoogleFonts.cairo(color: Colors.grey.shade600),
              ),
            ),
          ],
        );
      },
    );
  }
}

// --- SECTION CYCLES DE FORMATION ---
// (Le reste du code reste inchangé)
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

  // Filtres
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
      cardHeight = 380.0;
      rowsPerPage = 100;
    } else if (isTablet) {
      cardWidth = (screenWidth - 80) / 2 - 20;
      cardHeight = screenHeight * 0.48 > 440 ? 440 : screenHeight * 0.48;
      rowsPerPage = 2;
    } else {
      cardWidth = (screenWidth - 140) / 3 - 20;
      cardHeight = screenHeight * 0.48 > 460 ? 460 : screenHeight * 0.48;
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
                          child: _TrainingCard(
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
                              return _TrainingCard(
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
                          return _TrainingCard(
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

// --- CARTE DE FORMATION ---
class _TrainingCard extends StatefulWidget {
  final TrainingModel training;
  final bool isArabic;
  final VoidCallback onRefresh;
  final bool isMobile;

  const _TrainingCard({
    required this.training,
    required this.isArabic,
    required this.onRefresh,
    this.isMobile = false,
  });

  @override
  State<_TrainingCard> createState() => _TrainingCardState();
}

class _TrainingCardState extends State<_TrainingCard> {
  bool isHovered = false;

  String _extractFileName(String path) {
    if (path.contains('\\')) {
      return path.split('\\').last;
    } else if (path.contains('/')) {
      return path.split('/').last;
    }
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = widget.isMobile || screenWidth < 600;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            constraints.maxWidth > 0 ? constraints.maxWidth : 320.0;
        final cardHeight =
            constraints.maxHeight > 0
                ? constraints.maxHeight
                : (isMobile ? 380.0 : 440.0);

        final imageHeight = cardHeight * 0.55;
        final contentHeight = cardHeight * 0.45;

        final title =
            widget.isArabic ? widget.training.titleAr : widget.training.titleFr;
        final description =
            widget.isArabic
                ? widget.training.descriptionAr
                : widget.training.descriptionFr;

        String imageUrl = widget.training.imageUrl;
        if (imageUrl.contains('C:\\') || imageUrl.contains('assets/')) {
          String fileName = _extractFileName(imageUrl);
          imageUrl = 'assets/images/$fileName';
        }
        if (imageUrl.isEmpty ||
            imageUrl.startsWith('file://') ||
            (!imageUrl.startsWith('assets/') && !imageUrl.startsWith('http'))) {
          imageUrl = 'https://picsum.photos/seed/${widget.training.id}/800/450';
        }

        final durationDisplay =
            widget.training.typeDuree.isNotEmpty
                ? widget.training.typeDuree
                : 'Durée non définie';

        final periodDisplay =
            widget.training.dateDebut.isNotEmpty &&
                    widget.training.dateFin.isNotEmpty
                ? '${widget.training.dateDebut} - ${widget.training.dateFin}'
                : widget.training.period;

        final typeDisplay =
            widget.training.typeFormation.isNotEmpty
                ? widget.training.typeFormation
                : 'Formation';

        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          FormationDetailPage(formationId: widget.training.id),
                ),
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: cardWidth,
              height: cardHeight,
              transform:
                  isHovered && !isMobile
                      ? Matrix4.translationValues(0.0, -4.0, 0.0)
                      : Matrix4.identity(),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isHovered
                          ? AppColors.primary
                          : AppColors.primary.withOpacity(0.05),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        isHovered
                            ? AppColors.primaryDark.withOpacity(0.12)
                            : Colors.black.withOpacity(0.04),
                    blurRadius: isHovered ? 20 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  SizedBox(
                    height: imageHeight,
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildImage(imageUrl),
                          if (widget.training.hasDiscount &&
                              widget.training.discountValue != null)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.red, Colors.redAccent],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  widget.training.getDiscountText(
                                    widget.isArabic,
                                  ),
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isMobile ? 8 : 9,
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                typeDisplay,
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: isMobile ? 8 : 9,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Contenu
                  SizedBox(
                    height: contentHeight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Titre et description
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.cairo(
                                  fontSize: isMobile ? 13 : 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                description,
                                style: GoogleFonts.cairo(
                                  fontSize: isMobile ? 9 : 10,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textMuted,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),

                          // Informations
                          Column(
                            children: [
                              _buildInfoRow(
                                Icons.access_time_rounded,
                                widget.isArabic ? 'المدة : ' : 'Durée : ',
                                durationDisplay,
                                isMobile,
                              ),
                              const SizedBox(height: 2),
                              _buildInfoRow(
                                Icons.calendar_today_rounded,
                                widget.isArabic ? 'الفترة : ' : 'Période : ',
                                periodDisplay,
                                isMobile,
                              ),
                              const SizedBox(height: 2),
                              _buildInfoRow(
                                Icons.people_outline_rounded,
                                widget.isArabic ? 'الجمهور : ' : 'Cible : ',
                                widget.training.target,
                                isMobile,
                              ),
                            ],
                          ),

                          // Bas de carte
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: isMobile ? 10 : 12,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    durationDisplay,
                                    style: GoogleFonts.cairo(
                                      fontSize: isMobile ? 9 : 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  if (widget.training.hasDiscount &&
                                      widget.training.discountValue != null)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Text(
                                        '${widget.training.price.toInt()} DH',
                                        style: GoogleFonts.cairo(
                                          fontSize: isMobile ? 8 : 9,
                                          fontWeight: FontWeight.w400,
                                          decoration:
                                              TextDecoration.lineThrough,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ),
                                  Text(
                                    '${widget.training.finalPrice.toInt()} DH',
                                    style: GoogleFonts.cairo(
                                      fontSize: isMobile ? 12 : 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  widget.isArabic
                                      ? Icons.arrow_back_rounded
                                      : Icons.arrow_forward_rounded,
                                  color: AppColors.primary,
                                  size: isMobile ? 10 : 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    bool isMobile,
  ) {
    return Row(
      children: [
        Icon(icon, size: isMobile ? 8 : 10, color: AppColors.primary),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: isMobile ? 8 : 9,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 8 : 9,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: const Color(0xfff5f0ee),
          child: Center(
            child: CircularProgressIndicator(
              value:
                  loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
              color: AppColors.primary,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: const Color(0xfff5f0ee),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 30,
            color: AppColors.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 4),
          Text(
            widget.isArabic ? 'صورة غير متوفرة' : 'Image non disponible',
            style: GoogleFonts.cairo(
              fontSize: 10,
              color: AppColors.textMuted.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}
