// lib/pages/adminisration/administration_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafahat/pages/adminisration/add_training_card.dart';
import 'package:nafahat/pages/adminisration/add_categorie.dart';
import 'package:nafahat/pages/adminisration/edit_categorie.dart';
import 'package:nafahat/pages/adminisration/add_formateur.dart';
import 'package:nafahat/pages/adminisration/add_video_fav_page.dart';
import 'package:nafahat/pages/adminisration/edit_formation.dart';
import 'package:nafahat/pages/adminisration/users_list_page.dart';
import 'package:nafahat/pages/landing/widgets/BackToLandingButton.dart';
import 'package:nafahat/pages/users/edit_profile_page.dart';
import 'package:nafahat/pages/adminisration/add_duree.dart';
import 'package:nafahat/pages/adminisration/apparence_card.dart';
import 'package:nafahat/pages/adminisration/apparence_hero.dart';
import 'package:nafahat/services/training_service.dart';
import 'package:nafahat/services/video_service.dart';
import 'package:nafahat/services/adherent_service.dart';
import 'package:nafahat/models/training_model.dart';
import 'package:nafahat/models/video_model.dart';
import 'package:nafahat/models/formateur.dart';
import 'package:nafahat/models/adherent.dart';
import 'package:nafahat/providers/language_provider.dart';
import 'package:provider/provider.dart';
import 'edit_formateur.dart';
import 'dart:convert';
import 'package:nafahat/pages/adminisration/add_cible_page.dart';
import 'package:nafahat/services/cible_service.dart';
import 'package:nafahat/models/cible_model.dart';
import 'package:http/http.dart' as http;
import 'package:nafahat/pages/adminisration/add_typeFormation.dart';
import 'add_about.dart';
import 'package:nafahat/pages/adminisration/creerUserPage.dart';
import 'apparence_card_formateur.dart';
import 'package:nafahat/pages/users/inscription_adherent.dart';
import '../../services/navigation_service.dart';
import 'etat_paiement.dart';
import 'adherents_list_page.dart';

class AdministrationPage extends StatefulWidget {
  const AdministrationPage({super.key});

  @override
  State<AdministrationPage> createState() => _AdministrationPageState();
}

class _AdministrationPageState extends State<AdministrationPage> {
  int _selectedIndex = 0;
  bool _isFormationExpanded = true;
  bool _isApparenceExpanded = true;
  bool _isUserExpanded = true;

  // Pages
  final List<Widget> _pages = [
    const DashboardPage(),
    const FormationsManagementPage(),
    const CategoriesManagementPage(),
    const FormateursManagementPage(),
    const DureesManagementPage(),
    const TypesFormationManagementPage(),
    const CiblesManagementPage(),
    const ApparenceHeroPageWrapper(),
    const ApparenceCardPage(),
    const AddAboutPage(),
    const AdherentsListPage(),
    const CreerUserPage(),
    const InscriptionAdherentPage(),
    const VideosManagementPage(),
    const EtatPaiementPage(),
    const UsersListPage(),
    const ApparenceCardFormateurPage(),
  ];

  // Titres pour l'AppBar
  final List<String> _titles = [
    'Tableau de bord',
    'Formations',
    'Catégories',
    'Formateurs',
    'Durées',
    'Types de formation',
    'Cibles',
    'Apparence Hero',
    'Apparence des cartes',
    'À propos',
    'Adhérents',
    'Créer un utilisateur',
    'Inscription adhérent',
    'Vidéos',
    'paiement',
    'Liste des utilisateurs',
    'Apparence des formateur',
  ];

  final List<String> _titlesAr = [
    'لوحة القيادة',
    'التكوينات',
    'التصنيفات',
    'المكونين',
    'المدد',
    'أنواع التكوين',
    'الجمهور المستهدف',
    'مظهر الهيرو',
    'مظهر البطاقات',
    'عن المنصة',
    'المنخرطين',
    'إنشاء مستخدم',
    'تسجيل منخرط',
    'الفيديوهات',
    'حالة المدفوعات',
    'قائمة المستعملين ',
    'مظهر المكونين ',
  ];

  // Structure des menus avec groupes
  final List<Map<String, dynamic>> _menuGroups = [
    {
      'icon': Icons.school_outlined,
      'title': 'Formation',
      'titleAr': 'التكوين',
      'children': [
        {
          'icon': Icons.school_outlined,
          'title': 'Formations',
          'titleAr': 'التكوينات',
          'page': 1,
        },
        {
          'icon': Icons.person_outline,
          'title': 'Formateurs',
          'titleAr': 'المكونين',
          'page': 3,
        },
        {
          'icon': Icons.category_outlined,
          'title': 'Catégories',
          'titleAr': 'التصنيفات',
          'page': 2,
        },
        {
          'icon': Icons.access_time,
          'title': 'Durées',
          'titleAr': 'المدد',
          'page': 4,
        },
        {
          'icon': Icons.label_outlined,
          'title': 'Types Formation',
          'titleAr': 'أنواع التكوين',
          'page': 5,
        },
        {
          'icon': Icons.people_rounded,
          'title': 'Cibles',
          'titleAr': 'الجمهور المستهدف',
          'page': 6,
        },
        {
          'icon': Icons.video_library_outlined,
          'title': 'Vidéos',
          'titleAr': 'الفيديوهات',
          'page': 13, // Nouvel index
        },
      ],
    },
    {
      'icon': Icons.palette_outlined,
      'title': 'Apparence',
      'titleAr': 'المظهر',
      'children': [
        {
          'icon': Icons.slideshow_outlined,
          'title': 'Apparence Hero',
          'titleAr': 'مظهر الهيرو',
          'page': 7,
        },
        {
          'icon': Icons.palette_outlined,
          'title': 'Apparence Cartes',
          'titleAr': 'مظهر البطاقات',
          'page': 8,
        },
        {
          'icon': Icons.palette_outlined,
          'title': 'Apparence Formateur',
          'titleAr': 'مظهر المكونين',
          'page': 16,
        },
        {
          'icon': Icons.info_outline,
          'title': 'À propos',
          'titleAr': 'عن المنصة',
          'page': 9,
        },
      ],
    },
    {
      'icon': Icons.people_outline,
      'title': 'Utilisateurs & Adhérents',
      'titleAr': 'المستخدمون والمنخرطين',
      'children': [
        {
          'icon': Icons.people_outline,
          'title': 'Adhérents',
          'titleAr': 'المنخرطين',
          'page': 10,
        },
        {
          'icon': Icons.list_alt,
          'title': 'Liste des utilisateurs',
          'titleAr': 'قائمة المستعملين',
          'page': 15, // Nouvel index
        },
        {
          'icon': Icons.admin_panel_settings,
          'title': 'Créer un utilisateur',
          'titleAr': 'إنشاء مستخدم',
          'page': 11,
        },
        {
          'icon': Icons.person_add,
          'title': 'Inscription adhérent',
          'titleAr': 'تسجيل منخرط',
          'page': 12,
        },
        {
          'icon': Icons.verified,
          'title': 'État des paiements',
          'titleAr': 'حالة المدفوعات',
          'page': 14,
        },
      ],
    },
  ];

  // Mapping page index vers titre
  String _getTitleForIndex(int index, bool isArabic) {
    if (index >= 0 && index < _titles.length) {
      return isArabic ? _titlesAr[index] : _titles[index];
    }
    return isArabic ? 'لوحة القيادة' : 'Tableau de bord';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    // Version mobile - inchangée (liste plate)
    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          title: Consumer<LanguageProvider>(
            builder: (context, languageProvider, child) {
              return Text(
                _getTitleForIndex(_selectedIndex, languageProvider.isArabic),
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              );
            },
          ),
          backgroundColor: const Color(0xff0D443E),
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
          actions: [
            Consumer<LanguageProvider>(
              builder: (context, languageProvider, child) {
                return IconButton(
                  icon: const Icon(Icons.translate),
                  color: Colors.white,
                  onPressed: () {
                    languageProvider.toggleLanguage();
                    setState(() {});
                  },
                  tooltip: languageProvider.isArabic ? 'Français' : 'العربية',
                );
              },
            ),
          ],
        ),
        drawer: _buildDrawerMobile(),
        body: _pages[_selectedIndex],
      );
    }

    // Version web - avec menus déroulants
    return Scaffold(
      backgroundColor: const Color(0xfffcfbfa),
      body: Row(
        children: [
          _buildSideMenuWeb(),
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _pages[_selectedIndex]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DRAWER MOBILE - Version avec BackToLandingButton
  // ============================================================
  Widget _buildDrawerMobile() {
    // Version mobile : liste plate de tous les items (inchangée)
    final List<Map<String, dynamic>> flatMenuItems = [];
    for (var group in _menuGroups) {
      final children = group['children'] as List<Map<String, dynamic>>;
      flatMenuItems.addAll(children);
    }

    return Drawer(
      backgroundColor: const Color(0xff0D443E),
      child: Column(
        children: [
          Container(
            height: 120,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white24, width: 1),
              ),
            ),
            child: Consumer<LanguageProvider>(
              builder: (context, languageProvider, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Nafahat',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          languageProvider.isArabic
                              ? 'الإدارة'
                              : 'Administration',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    // ✅ Flèche landing page avec BackToLandingButton
                    const BackToLandingButton(),
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: flatMenuItems.length,
              itemBuilder: (context, index) {
                final item = flatMenuItems[index];
                final isSelected = _selectedIndex == item['page'];

                return Consumer<LanguageProvider>(
                  builder: (context, languageProvider, child) {
                    final title =
                        languageProvider.isArabic
                            ? (item['titleAr'] ?? item['title'])
                            : item['title'];
                    return ListTile(
                      leading: Icon(
                        item['icon'],
                        color:
                            isSelected
                                ? const Color(0xffd57653)
                                : Colors.white70,
                      ),
                      title: Text(
                        title,
                        style: GoogleFonts.poppins(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      selected: isSelected,
                      selectedTileColor: const Color(
                        0xffd57653,
                      ).withOpacity(0.2),
                      onTap: () {
                        setState(() {
                          _selectedIndex = item['page'];
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white24, width: 1)),
            ),
            child: Consumer<LanguageProvider>(
              builder: (context, languageProvider, child) {
                return ListTile(
                  leading: const Icon(
                    Icons.logout_rounded,
                    color: Colors.white70,
                  ),
                  title: Text(
                    languageProvider.isArabic ? 'تسجيل الخروج' : 'Déconnexion',
                    style: GoogleFonts.poppins(color: Colors.white70),
                  ),
                  onTap: () {
                    // TODO: Déconnexion
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SIDE MENU WEB - AVEC BackToLandingButton
  // ============================================================
  Widget _buildSideMenuWeb() {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isCollapsed = screenWidth < 900;

    return Container(
      width: isCollapsed ? 80 : 280,
      decoration: BoxDecoration(
        color: const Color(0xff0D443E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo avec flèche de redirection vers landing page
          Container(
            height: 80,
            padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 8 : 20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white24, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/logo.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Consumer<LanguageProvider>(
                    builder: (context, languageProvider, child) {
                      return Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nafahat',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  languageProvider.isArabic
                                      ? 'الإدارة'
                                      : 'Administration',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                            // ✅ Flèche de redirection vers landing page avec BackToLandingButton
                            const BackToLandingButton(),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),

          // Menu Items avec groupes et sous-menus
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _menuGroups.length,
              itemBuilder: (context, groupIndex) {
                final group = _menuGroups[groupIndex];
                final children =
                    group['children'] as List<Map<String, dynamic>>;

                // État d'expansion pour ce groupe
                bool isExpanded;
                if (group['title'] == 'Formation') {
                  isExpanded = _isFormationExpanded;
                } else if (group['title'] == 'Apparence') {
                  isExpanded = _isApparenceExpanded;
                } else {
                  isExpanded = _isUserExpanded;
                }

                return Column(
                  children: [
                    // En-tête du groupe (cliquable pour expand/collapse)
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (group['title'] == 'Formation') {
                            _isFormationExpanded = !_isFormationExpanded;
                          } else if (group['title'] == 'Apparence') {
                            _isApparenceExpanded = !_isApparenceExpanded;
                          } else {
                            _isUserExpanded = !_isUserExpanded;
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isCollapsed ? 0 : 16,
                          vertical: 12,
                        ),
                        child: Consumer<LanguageProvider>(
                          builder: (context, languageProvider, child) {
                            final title =
                                languageProvider.isArabic
                                    ? (group['titleAr'] ?? group['title'])
                                    : group['title'];
                            return Row(
                              mainAxisAlignment:
                                  isCollapsed
                                      ? MainAxisAlignment.center
                                      : MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      group['icon'],
                                      color: Colors.white70,
                                      size: 24,
                                    ),
                                    if (!isCollapsed) ...[
                                      const SizedBox(width: 16),
                                      Text(
                                        title,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white70,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (!isCollapsed)
                                  Icon(
                                    isExpanded
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    color: Colors.white54,
                                    size: 20,
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),

                    // Sous-menus (version dépliée)
                    if (isExpanded && !isCollapsed) ...[
                      ...children.map((child) {
                        final isSelected = _selectedIndex == child['page'];
                        return Consumer<LanguageProvider>(
                          builder: (context, languageProvider, childWidget) {
                            final displayTitle =
                                languageProvider.isArabic
                                    ? child['titleAr']
                                    : child['title'];
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedIndex = child['page'];
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                margin: const EdgeInsets.only(
                                  left: 24,
                                  right: 12,
                                  top: 2,
                                  bottom: 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? const Color(
                                            0xffd57653,
                                          ).withOpacity(0.2)
                                          : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      isSelected
                                          ? Border.all(
                                            color: const Color(
                                              0xffd57653,
                                            ).withOpacity(0.3),
                                            width: 1,
                                          )
                                          : null,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      child['icon'],
                                      color:
                                          isSelected
                                              ? const Color(0xffd57653)
                                              : Colors.white70,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        displayTitle,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight:
                                              isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                          color:
                                              isSelected
                                                  ? Colors.white
                                                  : Colors.white70,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ],

                    // Version collapsée - afficher les sous-menus en icônes
                    if (isCollapsed) ...[
                      ...children.map((child) {
                        final isSelected = _selectedIndex == child['page'];
                        return Consumer<LanguageProvider>(
                          builder: (context, languageProvider, childWidget) {
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedIndex = child['page'];
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? const Color(
                                            0xffd57653,
                                          ).withOpacity(0.2)
                                          : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      isSelected
                                          ? Border.all(
                                            color: const Color(
                                              0xffd57653,
                                            ).withOpacity(0.3),
                                            width: 1,
                                          )
                                          : null,
                                ),
                                child: Center(
                                  child: Icon(
                                    child['icon'],
                                    color:
                                        isSelected
                                            ? const Color(0xffd57653)
                                            : Colors.white70,
                                    size: 22,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ],

                    // Séparateur entre groupes
                    if (groupIndex < _menuGroups.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: Divider(
                          color: Colors.white.withOpacity(0.1),
                          thickness: 1,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // Footer (Déconnexion)
          Container(
            padding: EdgeInsets.all(isCollapsed ? 8 : 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white24, width: 1)),
            ),
            child: Row(
              mainAxisAlignment:
                  isCollapsed
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.white70),
                  onPressed: () {
                    // TODO: Déconnexion
                  },
                  tooltip: 'Déconnexion',
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 8),
                  Consumer<LanguageProvider>(
                    builder: (context, languageProvider, child) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            languageProvider.isArabic ? 'مدير' : 'Admin',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'admin@nafahat.com',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================
  Widget _buildHeader() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Consumer<LanguageProvider>(
            builder: (context, languageProvider, child) {
              return Text(
                _getTitleForIndex(_selectedIndex, languageProvider.isArabic),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xff2c221e),
                ),
              );
            },
          ),
          Row(
            children: [
              Consumer<LanguageProvider>(
                builder: (context, languageProvider, child) {
                  return IconButton(
                    icon: const Icon(Icons.translate),
                    color: Colors.grey[600],
                    onPressed: () {
                      languageProvider.toggleLanguage();
                      setState(() {});
                    },
                    tooltip: languageProvider.isArabic ? 'Français' : 'العربية',
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                color: Colors.grey[600],
                onPressed: () {},
              ),
              CircleAvatar(
                backgroundColor: const Color(0xff0D443E).withOpacity(0.1),
                child: const Icon(
                  Icons.person_outline,
                  color: Color(0xff0D443E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DASHBOARD PAGE
// ============================================================
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic
                ? 'مرحباً بكم في لوحة القيادة'
                : 'Bienvenue dans le tableau de bord',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: const Color(0xff2c221e),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isArabic
                ? 'إدارة التكوينات، التصنيفات، المكونين، الفيديوهات، المنخرطين، المدد والمظهر'
                : 'Gérez vos formations, catégories, formateurs, vidéos, adhérents, durées et apparence',
            style: GoogleFonts.poppins(color: const Color(0xff7c6e68)),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildStatCard(
                icon: Icons.school,
                title: isArabic ? 'التكوينات' : 'Formations',
                count: '12',
                color: const Color(0xffd57653),
              ),
              _buildStatCard(
                icon: Icons.category,
                title: isArabic ? 'التصنيفات' : 'Catégories',
                count: '5',
                color: const Color(0xff0D443E),
              ),
              _buildStatCard(
                icon: Icons.person,
                title: isArabic ? 'المكونين' : 'Formateurs',
                count: '8',
                color: Colors.blue[700]!,
              ),
              _buildStatCard(
                icon: Icons.video_library,
                title: isArabic ? 'الفيديوهات' : 'Vidéos',
                count: '6',
                color: Colors.purple[700]!,
              ),
              _buildStatCard(
                icon: Icons.people,
                title: isArabic ? 'المنخرطين' : 'Adhérents',
                count: '0',
                color: Colors.green[700]!,
              ),
              _buildStatCard(
                icon: Icons.access_time,
                title: isArabic ? 'المدد' : 'Durées',
                count: '4',
                color: Colors.orange[700]!,
              ),
              _buildStatCard(
                icon: Icons.palette,
                title: isArabic ? 'مظهر البطاقات' : 'Apparence Cartes',
                count: '⚙️',
                color: const Color(0xffC4A46C),
              ),
              _buildStatCard(
                icon: Icons.slideshow,
                title: isArabic ? 'مظهر الهيرو' : 'Apparence Hero',
                count: '🖼️',
                color: const Color(0xffd57653),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String count,
    required Color color,
  }) {
    return SizedBox(
      width: 180,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xff2c221e),
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xff7c6e68),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// WRAPPER POUR APPARENCE HERO
// ============================================================
class ApparenceHeroPageWrapper extends StatefulWidget {
  const ApparenceHeroPageWrapper({super.key});

  @override
  State<ApparenceHeroPageWrapper> createState() =>
      _ApparenceHeroPageWrapperState();
}

class _ApparenceHeroPageWrapperState extends State<ApparenceHeroPageWrapper> {
  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;
    return ApparenceHero(isArabic: isArabic);
  }
}

// ============================================================
// FORMATIONS MANAGEMENT PAGE
// ============================================================
class FormationsManagementPage extends StatefulWidget {
  const FormationsManagementPage({super.key});

  @override
  State<FormationsManagementPage> createState() =>
      _FormationsManagementPageState();
}

class _FormationsManagementPageState extends State<FormationsManagementPage> {
  List<TrainingModel> _formations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFormations();
  }

  Future<void> _loadFormations() async {
    setState(() => _isLoading = true);
    try {
      final trainings = await TrainingService.getTrainings();
      setState(() {
        _formations = trainings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur chargement formations: $e')),
      );
    }
  }

  Future<void> _deleteFormation(String id, String title) async {
    final isArabic =
        Provider.of<LanguageProvider>(context, listen: false).isArabic;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isArabic ? 'تأكيد الحذف' : 'Confirmer la suppression'),
            content: Text(
              isArabic
                  ? 'هل أنت متأكد من رغبتك في حذف التكوين "$title"؟'
                  : 'Êtes-vous sûr de vouloir supprimer la formation "$title" ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(isArabic ? 'إلغاء' : 'Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(isArabic ? 'حذف' : 'Supprimer'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final response = await http.delete(
          Uri.parse('${TrainingService.apiBaseUrl}/formations/hard/$id'),
          headers: {'Content-Type': 'application/json'},
        );

        final data = json.decode(response.body);

        if (response.statusCode == 200 && data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isArabic
                    ? 'تم حذف التكوين بنجاح'
                    : 'Formation supprimée avec succès',
              ),
              backgroundColor: const Color(0xff0D443E),
            ),
          );
          _loadFormations();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                data['message'] ??
                    (isArabic
                        ? 'خطأ في الحذف'
                        : 'Erreur lors de la suppression'),
              ),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showEditTrainingDialog(BuildContext context) {
    final isArabic =
        Provider.of<LanguageProvider>(context, listen: false).isArabic;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            isArabic ? 'تعديل تكوين' : 'Modifier une formation',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isArabic
                      ? 'اختر تكويناً من القائمة أدناه'
                      : 'Sélectionnez une formation dans la liste ci-dessous',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_formations.isEmpty)
                  Text(
                    isArabic
                        ? 'لا توجد تكوينات متاحة'
                        : 'Aucune formation disponible',
                    style: TextStyle(color: Colors.grey.shade600),
                  )
                else
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _formations.length,
                      itemBuilder: (context, index) {
                        final formation = _formations[index];
                        final title =
                            formation.titleFr.isNotEmpty
                                ? formation.titleFr
                                : formation.titleAr;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(
                              0xff0D443E,
                            ).withOpacity(0.1),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: const Color(0xff0D443E),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            'ID: ${formation.id}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: const Color(0xff0D443E),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => EditFormationPage(
                                      formationId: formation.id,
                                    ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                isArabic ? 'إلغاء' : 'Annuler',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic ? 'إدارة التكوينات' : 'Gestion des formations',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff2c221e),
                ),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddTrainingCardPage(),
                        ),
                      ).then((_) => _loadFormations());
                    },
                    icon: const Icon(Icons.add),
                    label: Text(isArabic ? 'إضافة' : 'Ajouter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff0D443E),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showEditTrainingDialog(context);
                    },
                    icon: const Icon(Icons.edit),
                    label: Text(isArabic ? 'تعديل' : 'Modifier'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffd57653),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _formations.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isArabic
                                ? 'لا توجد تكوينات'
                                : 'Aucune formation trouvée',
                            style: GoogleFonts.poppins(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                    : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _formations.length,
                        itemBuilder: (context, index) {
                          final formation = _formations[index];
                          final typeDisplay =
                              formation.typeFormation.isNotEmpty
                                  ? formation.typeFormation
                                  : (isArabic ? 'غير محدد' : 'Non défini');
                          final dureeDisplay =
                              formation.typeDuree.isNotEmpty
                                  ? formation.typeDuree
                                  : (isArabic ? 'غير محدد' : 'Non définie');
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(
                                0xffd57653,
                              ).withOpacity(0.1),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: const Color(0xffd57653),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              formation.titleFr.isNotEmpty
                                  ? formation.titleFr
                                  : formation.titleAr,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              '${isArabic ? 'النوع' : 'Type'}: $typeDisplay | ${isArabic ? 'المدة' : 'Durée'}: $dureeDisplay | ${isArabic ? 'السعر' : 'Prix'}: ${formation.price} DH',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Color(0xffd57653),
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => EditFormationPage(
                                              formationId: formation.id,
                                            ),
                                      ),
                                    ).then((_) => _loadFormations());
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    _deleteFormation(
                                      formation.id,
                                      formation.titleFr.isNotEmpty
                                          ? formation.titleFr
                                          : formation.titleAr,
                                    );
                                  },
                                  tooltip:
                                      isArabic
                                          ? 'حذف هذا التكوين'
                                          : 'Supprimer cette formation',
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CATEGORIES MANAGEMENT PAGE
// ============================================================
class CategoriesManagementPage extends StatefulWidget {
  const CategoriesManagementPage({super.key});

  @override
  State<CategoriesManagementPage> createState() =>
      _CategoriesManagementPageState();
}

class _CategoriesManagementPageState extends State<CategoriesManagementPage> {
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final categories = await TrainingService.getCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur chargement catégories: $e')),
      );
    }
  }

  Future<void> _deleteCategory(String id) async {
    final isArabic =
        Provider.of<LanguageProvider>(context, listen: false).isArabic;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isArabic ? 'تأكيد الحذف' : 'Confirmer la suppression'),
            content: Text(
              isArabic
                  ? 'هل أنت متأكد من رغبتك في حذف هذا التصنيف؟'
                  : 'Êtes-vous sûr de vouloir supprimer cette catégorie ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(isArabic ? 'إلغاء' : 'Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(isArabic ? 'حذف' : 'Supprimer'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final response = await http.delete(
          Uri.parse('${TrainingService.apiBaseUrl}/categories/$id'),
          headers: {'Content-Type': 'application/json'},
        );

        final data = json.decode(response.body);

        if (response.statusCode == 200 && data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isArabic
                    ? 'تم حذف التصنيف بنجاح'
                    : 'Catégorie supprimée avec succès',
              ),
              backgroundColor: const Color(0xff0D443E),
            ),
          );
          _loadCategories();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                data['message'] ??
                    (isArabic
                        ? 'خطأ في الحذف'
                        : 'Erreur lors de la suppression'),
              ),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic ? 'إدارة التصنيفات' : 'Gestion des catégories',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff2c221e),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddCategoriePage(),
                    ),
                  ).then((_) => _loadCategories());
                },
                icon: const Icon(Icons.add),
                label: Text(isArabic ? 'إضافة' : 'Ajouter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff0D443E),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _categories.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isArabic
                                ? 'لا توجد تصنيفات'
                                : 'Aucune catégorie trouvée',
                            style: GoogleFonts.poppins(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                    : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(
                                0xff0D443E,
                              ).withOpacity(0.1),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: const Color(0xff0D443E),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              isArabic
                                  ? (cat['categorie_ar'] ??
                                      cat['categorie_fr'] ??
                                      'Sans nom')
                                  : (cat['categorie_fr'] ?? 'Sans nom'),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              'ID: ${cat['id']}',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Color(0xffd57653),
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => EditCategoriePage(
                                              itemId: cat['id'].toString(),
                                              type: 'categorie',
                                            ),
                                      ),
                                    ).then((_) => _loadCategories());
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    _deleteCategory(cat['id'].toString());
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FORMATEURS MANAGEMENT PAGE
// ============================================================
class FormateursManagementPage extends StatefulWidget {
  const FormateursManagementPage({super.key});

  @override
  State<FormateursManagementPage> createState() =>
      _FormateursManagementPageState();
}

class _FormateursManagementPageState extends State<FormateursManagementPage> {
  List<Map<String, dynamic>> _formateurs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFormateurs();
  }

  Future<void> _loadFormateurs() async {
    setState(() => _isLoading = true);
    try {
      final formateurs = await TrainingService.getFormateurs();
      setState(() {
        _formateurs = formateurs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur chargement formateurs: $e')),
      );
    }
  }

  void _openEditFormateur(
    BuildContext context,
    Map<String, dynamic> formateurData,
  ) {
    final formateur = Formateur(
      id: formateurData['id'] ?? 0,
      nomPrenomFr: formateurData['nom_prenom_fr'] ?? '',
      nomPrenomAr: formateurData['nom_prenom_ar'] ?? '',
      email: formateurData['email'],
      telephone: formateurData['telephone'],
      bioFr: formateurData['bio_fr'],
      bioAr: formateurData['bio_ar'],
      idCategorie: formateurData['id_categorie'],
      photo: formateurData['photo'],
      categorieFr: formateurData['categorie_fr'],
      categorieAr: formateurData['categorie_ar'],
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditFormateurScreen(formateur: formateur),
      ),
    ).then((result) {
      if (result == true) {
        _loadFormateurs();
      }
    });
  }

  Future<void> _deleteFormateur(String id) async {
    final isArabic =
        Provider.of<LanguageProvider>(context, listen: false).isArabic;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isArabic ? 'تأكيد الحذف' : 'Confirmer la suppression'),
            content: Text(
              isArabic
                  ? 'هل أنت متأكد من رغبتك في حذف هذا المكون؟'
                  : 'Êtes-vous sûr de vouloir supprimer ce formateur ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(isArabic ? 'إلغاء' : 'Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(isArabic ? 'حذف' : 'Supprimer'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final response = await http.delete(
          Uri.parse('${TrainingService.apiBaseUrl}/formateurs/$id'),
          headers: {'Content-Type': 'application/json'},
        );

        final data = json.decode(response.body);

        if (response.statusCode == 200 && data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isArabic
                    ? 'تم حذف المكون بنجاح'
                    : 'Formateur supprimé avec succès',
              ),
              backgroundColor: const Color(0xff0D443E),
            ),
          );
          _loadFormateurs();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                data['message'] ??
                    (isArabic
                        ? 'خطأ في الحذف'
                        : 'Erreur lors de la suppression'),
              ),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic ? 'إدارة المكونين' : 'Gestion des formateurs',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff2c221e),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddFormateurPage(),
                    ),
                  ).then((_) => _loadFormateurs());
                },
                icon: const Icon(Icons.add),
                label: Text(isArabic ? 'إضافة' : 'Ajouter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff0D443E),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _formateurs.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isArabic
                                ? 'لا يوجد مكونين'
                                : 'Aucun formateur trouvé',
                            style: GoogleFonts.poppins(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                    : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _formateurs.length,
                        itemBuilder: (context, index) {
                          final f = _formateurs[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.withOpacity(0.1),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              isArabic
                                  ? (f['nom_prenom_ar'] ??
                                      f['nom_prenom_fr'] ??
                                      'Sans nom')
                                  : (f['nom_prenom_fr'] ?? 'Sans nom'),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              '${isArabic ? 'البريد الإلكتروني' : 'Email'}: ${f['email'] ?? 'N/A'} | ${isArabic ? 'الهاتف' : 'Tél'}: ${f['telephone'] ?? 'N/A'}',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Color(0xffd57653),
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    _openEditFormateur(context, f);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    _deleteFormateur(f['id'].toString());
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// VIDEOS MANAGEMENT PAGE
// ============================================================
class VideosManagementPage extends StatefulWidget {
  const VideosManagementPage({super.key});

  @override
  State<VideosManagementPage> createState() => _VideosManagementPageState();
}

class _VideosManagementPageState extends State<VideosManagementPage> {
  List<VideoModel> _videos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() => _isLoading = true);
    try {
      final videos = await VideoService.getVideos();
      setState(() {
        _videos = videos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur chargement vidéos: $e')));
    }
  }

  Future<void> _deleteVideo(String id) async {
    final isArabic =
        Provider.of<LanguageProvider>(context, listen: false).isArabic;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isArabic ? 'تأكيد الحذف' : 'Confirmer la suppression'),
            content: Text(
              isArabic
                  ? 'هل أنت متأكد من رغبتك في حذف هذا الفيديو؟'
                  : 'Êtes-vous sûr de vouloir supprimer cette vidéo ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(isArabic ? 'إلغاء' : 'Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(isArabic ? 'حذف' : 'Supprimer'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final response = await http.delete(
          Uri.parse('${TrainingService.apiBaseUrl}/videos/$id'),
          headers: {'Content-Type': 'application/json'},
        );

        final data = json.decode(response.body);

        if (response.statusCode == 200 && data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isArabic
                    ? 'تم حذف الفيديو بنجاح'
                    : 'Vidéo supprimée avec succès',
              ),
              backgroundColor: const Color(0xff0D443E),
            ),
          );
          _loadVideos();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                data['message'] ??
                    (isArabic
                        ? 'خطأ في الحذف'
                        : 'Erreur lors de la suppression'),
              ),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _editVideo(BuildContext context, VideoModel video) {
    final isArabic =
        Provider.of<LanguageProvider>(context, listen: false).isArabic;
    // TODO: Implémenter l'édition de vidéo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabic
              ? 'جاري تطوير تعديل الفيديو'
              : 'Fonctionnalité en développement',
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic ? 'إدارة الفيديوهات' : 'Gestion des vidéos',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff2c221e),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddVideoFavPage(),
                    ),
                  ).then((_) => _loadVideos());
                },
                icon: const Icon(Icons.add),
                label: Text(isArabic ? 'إضافة' : 'Ajouter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff0D443E),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _videos.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.video_library_outlined,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isArabic
                                ? 'لا توجد فيديوهات'
                                : 'Aucune vidéo trouvée',
                            style: GoogleFonts.poppins(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                    : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _videos.length,
                        itemBuilder: (context, index) {
                          final video = _videos[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.purple.withOpacity(0.1),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Colors.purple,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              isArabic
                                  ? (video.titleAr.isNotEmpty
                                      ? video.titleAr
                                      : video.titleFr)
                                  : (video.titleFr.isNotEmpty
                                      ? video.titleFr
                                      : video.titleAr),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              '${isArabic ? 'معرف يوتيوب' : 'ID YouTube'}: ${video.videoId}',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Color(0xffd57653),
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    _editVideo(context, video);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    _deleteVideo(video.id.toString());
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ADHERENTS MANAGEMENT PAGE
// ============================================================
class AdherentsManagementPage extends StatefulWidget {
  const AdherentsManagementPage({super.key});

  @override
  State<AdherentsManagementPage> createState() =>
      _AdherentsManagementPageState();
}

class _AdherentsManagementPageState extends State<AdherentsManagementPage> {
  List<Adherent> _adherents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdherents();
  }

  Future<void> _loadAdherents() async {
    setState(() => _isLoading = true);
    try {
      final adherents = await AdherentService.getAdherents();
      setState(() {
        _adherents = adherents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur chargement adhérents: $e')),
      );
    }
  }

  void _showEditAdherentDialog(BuildContext context) {
    final isArabic =
        Provider.of<LanguageProvider>(context, listen: false).isArabic;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            isArabic ? 'تعديل منخرط' : 'Modifier un adhérent',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isArabic
                      ? 'اختر منخرطاً من القائمة أدناه'
                      : 'Sélectionnez un adhérent dans la liste ci-dessous',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_adherents.isEmpty)
                  Text(
                    isArabic ? 'لا يوجد منخرطين' : 'Aucun adhérent disponible',
                    style: TextStyle(color: Colors.grey.shade600),
                  )
                else
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _adherents.length,
                      itemBuilder: (context, index) {
                        final adherent = _adherents[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(
                              0xff0D443E,
                            ).withOpacity(0.1),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: const Color(0xff0D443E),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            adherent.nomPrenom,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            adherent.email,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: const Color(0xff0D443E),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => EditProfilePage(
                                      adherentId: adherent.id.toString(),
                                      adherentData: adherent,
                                    ),
                              ),
                            ).then((_) => _loadAdherents());
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                isArabic ? 'إلغاء' : 'Annuler',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic ? 'إدارة المنخرطين' : 'Gestion des adhérents',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff2c221e),
                ),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Redirection vers inscription...'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: Text(isArabic ? 'إضافة' : 'Ajouter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff0D443E),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showEditAdherentDialog(context);
                    },
                    icon: const Icon(Icons.edit),
                    label: Text(isArabic ? 'تعديل' : 'Modifier'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffd57653),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _adherents.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isArabic
                                ? 'لا يوجد منخرطين'
                                : 'Aucun adhérent trouvé',
                            style: GoogleFonts.poppins(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                    : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _adherents.length,
                        itemBuilder: (context, index) {
                          final adherent = _adherents[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(
                                0xff0D443E,
                              ).withOpacity(0.1),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: const Color(0xff0D443E),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              adherent.nomPrenom,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              '${adherent.whatsapp} | ${adherent.email}',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Color(0xffd57653),
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => EditProfilePage(
                                              adherentId:
                                                  adherent.id.toString(),
                                              adherentData: adherent,
                                            ),
                                      ),
                                    ).then((_) => _loadAdherents());
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    // TODO: Implémenter suppression
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DUREES MANAGEMENT PAGE
// ============================================================
class DureesManagementPage extends StatefulWidget {
  const DureesManagementPage({super.key});

  @override
  State<DureesManagementPage> createState() => _DureesManagementPageState();
}

class _DureesManagementPageState extends State<DureesManagementPage> {
  List<Map<String, dynamic>> _durees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDurees();
  }

  Future<void> _loadDurees() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${TrainingService.apiBaseUrl}/duree'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _durees = List<Map<String, dynamic>>.from(data['data']);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors du chargement des durées'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur chargement durées: $e')));
    }
  }

  Future<void> _deleteDuree(String id) async {
    final isArabic =
        Provider.of<LanguageProvider>(context, listen: false).isArabic;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isArabic ? 'تأكيد الحذف' : 'Confirmer la suppression'),
            content: Text(
              isArabic
                  ? 'هل أنت متأكد من رغبتك في حذف هذه المدة؟'
                  : 'Êtes-vous sûr de vouloir supprimer cette durée ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(isArabic ? 'إلغاء' : 'Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(isArabic ? 'حذف' : 'Supprimer'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final response = await http.delete(
          Uri.parse('${TrainingService.apiBaseUrl}/duree/$id'),
          headers: {'Content-Type': 'application/json'},
        );

        final data = json.decode(response.body);

        if (response.statusCode == 200 && data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isArabic ? 'تم حذف المدة بنجاح' : 'Durée supprimée avec succès',
              ),
              backgroundColor: const Color(0xff0D443E),
            ),
          );
          _loadDurees();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                data['message'] ??
                    (isArabic
                        ? 'خطأ في الحذف'
                        : 'Erreur lors de la suppression'),
              ),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic ? 'إدارة المدد' : 'Gestion des durées',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff2c221e),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddDureePage(),
                    ),
                  ).then((_) => _loadDurees());
                },
                icon: const Icon(Icons.add),
                label: Text(isArabic ? 'إضافة' : 'Ajouter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff0D443E),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _durees.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isArabic ? 'لا توجد مدد' : 'Aucune durée trouvée',
                            style: GoogleFonts.poppins(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                    : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _durees.length,
                        itemBuilder: (context, index) {
                          final d = _durees[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(
                                0xff0D443E,
                              ).withOpacity(0.1),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: const Color(0xff0D443E),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              d['type_duree'] ?? 'Sans nom',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              'Ch1: ${d['ch1'] ?? '-'} | Ch2: ${d['ch2'] ?? '-'} | Ch3: ${d['ch3'] ?? '-'} | Ch4: ${d['ch4'] ?? '-'} | Ch5: ${d['ch5'] ?? '-'} | Ch6: ${d['ch6'] ?? '-'}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Color(0xffd57653),
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                AddDureePage(dureeToEdit: d),
                                      ),
                                    ).then((_) => _loadDurees());
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    _deleteDuree(d['id'].toString());
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TYPES DE FORMATION MANAGEMENT PAGE
// ============================================================
class TypesFormationManagementPage extends StatefulWidget {
  const TypesFormationManagementPage({super.key});

  @override
  State<TypesFormationManagementPage> createState() =>
      _TypesFormationManagementPageState();
}

class _TypesFormationManagementPageState
    extends State<TypesFormationManagementPage> {
  List<Map<String, dynamic>> _typesFormation = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTypesFormation();
  }

  Future<void> _loadTypesFormation() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${TrainingService.apiBaseUrl}/types-formation'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _typesFormation = List<Map<String, dynamic>>.from(data['data']);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors du chargement des types de formation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur chargement types de formation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteTypeFormation(String id) async {
    final isArabic =
        Provider.of<LanguageProvider>(context, listen: false).isArabic;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isArabic ? 'تأكيد الحذف' : 'Confirmer la suppression'),
            content: Text(
              isArabic
                  ? 'هل أنت متأكد من رغبتك في حذف هذا النوع؟'
                  : 'Êtes-vous sûr de vouloir supprimer ce type de formation ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(isArabic ? 'إلغاء' : 'Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(isArabic ? 'حذف' : 'Supprimer'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final response = await http.delete(
          Uri.parse('${TrainingService.apiBaseUrl}/types-formation/$id'),
          headers: {'Content-Type': 'application/json'},
        );

        final data = json.decode(response.body);

        if (response.statusCode == 200 && data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isArabic ? 'تم حذف النوع بنجاح' : 'Type supprimé avec succès',
              ),
              backgroundColor: const Color(0xff0D443E),
            ),
          );
          _loadTypesFormation();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                data['message'] ??
                    (isArabic
                        ? 'خطأ في الحذف'
                        : 'Erreur lors de la suppression'),
              ),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic
                    ? 'إدارة أنواع التكوين'
                    : 'Gestion des types de formation',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff2c221e),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddTypeFormationPage(),
                    ),
                  ).then((_) => _loadTypesFormation());
                },
                icon: const Icon(Icons.add),
                label: Text(isArabic ? 'إضافة' : 'Ajouter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff0D443E),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _typesFormation.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.label_outline,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isArabic
                                ? 'لا توجد أنواع'
                                : 'Aucun type de formation trouvé',
                            style: GoogleFonts.poppins(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                    : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _typesFormation.length,
                        itemBuilder: (context, index) {
                          final type = _typesFormation[index];
                          final chapters =
                              [
                                    type['ch1'],
                                    type['ch2'],
                                    type['ch3'],
                                    type['ch4'],
                                    type['ch5'],
                                    type['ch6'],
                                  ]
                                  .where(
                                    (ch) =>
                                        ch != null && ch.toString().isNotEmpty,
                                  )
                                  .length;

                          String chaptersDisplay = '';
                          if (chapters > 0) {
                            final List<String> chapterNames = [];
                            if (type['ch1'] != null &&
                                type['ch1'].toString().isNotEmpty) {
                              chapterNames.add('Ch1: ${type['ch1']}');
                            }
                            if (type['ch2'] != null &&
                                type['ch2'].toString().isNotEmpty) {
                              chapterNames.add('Ch2: ${type['ch2']}');
                            }
                            if (type['ch3'] != null &&
                                type['ch3'].toString().isNotEmpty) {
                              chapterNames.add('Ch3: ${type['ch3']}');
                            }
                            if (type['ch4'] != null &&
                                type['ch4'].toString().isNotEmpty) {
                              chapterNames.add('Ch4: ${type['ch4']}');
                            }
                            if (type['ch5'] != null &&
                                type['ch5'].toString().isNotEmpty) {
                              chapterNames.add('Ch5: ${type['ch5']}');
                            }
                            if (type['ch6'] != null &&
                                type['ch6'].toString().isNotEmpty) {
                              chapterNames.add('Ch6: ${type['ch6']}');
                            }
                            chaptersDisplay = chapterNames.join(' | ');
                          }

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(
                                0xffd57653,
                              ).withOpacity(0.1),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: const Color(0xffd57653),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              type['type_formation'] ?? 'Sans nom',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle:
                                chapters > 0
                                    ? Text(
                                      chaptersDisplay,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                    : Text(
                                      isArabic
                                          ? 'لا توجد فصول'
                                          : 'Aucun chapitre',
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 12,
                                      ),
                                    ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Color(0xffd57653),
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => AddTypeFormationPage(
                                              typeToEdit: type,
                                            ),
                                      ),
                                    ).then((_) => _loadTypesFormation());
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    _deleteTypeFormation(type['id'].toString());
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CIBLES MANAGEMENT PAGE
// ============================================================
class CiblesManagementPage extends StatefulWidget {
  const CiblesManagementPage({super.key});

  @override
  State<CiblesManagementPage> createState() => _CiblesManagementPageState();
}

class _CiblesManagementPageState extends State<CiblesManagementPage> {
  List<CibleModel> _cibles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCibles();
  }

  Future<void> _loadCibles() async {
    setState(() => _isLoading = true);
    try {
      final cibles = await CibleService.getCibles();
      setState(() {
        _cibles = cibles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      final isArabic =
          Provider.of<LanguageProvider>(context, listen: false).isArabic;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? '❌ Erreur de chargement des cibles'
                : '❌ Erreur de chargement des cibles',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteCible(CibleModel cible) async {
    final isArabic =
        Provider.of<LanguageProvider>(context, listen: false).isArabic;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isArabic ? 'تأكيد الحذف' : 'Confirmation'),
            content: Text(
              isArabic
                  ? 'هل أنت sûr de vouloir supprimer "${cible.nomCible}" ?'
                  : 'Voulez-vous vraiment supprimer "${cible.nomCible}" ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(isArabic ? 'إلغاء' : 'Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(isArabic ? 'حذف' : 'Supprimer'),
              ),
            ],
          ),
    );

    if (confirm == true && cible.id != null) {
      setState(() => _isLoading = true);
      final success = await CibleService.deleteCible(cible.id!);
      if (success) {
        setState(() {
          _cibles.removeWhere((c) => c.id == cible.id);
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic
                  ? '✅ تم حذف "${cible.nomCible}" بنجاح'
                  : '✅ "${cible.nomCible}" supprimée avec succès',
            ),
            backgroundColor: const Color(0xff0D443E),
          ),
        );
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToAddCible({CibleModel? cible}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddCiblePage(cible: cible)),
    );
    if (result == true) {
      _loadCibles();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic ? 'إدارة الجمهور المستهدف' : 'Gestion des cibles',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff2c221e),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _navigateToAddCible(),
                icon: const Icon(Icons.add),
                label: Text(isArabic ? 'إضافة' : 'Ajouter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff0D443E),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _cibles.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isArabic
                                ? 'لا توجد cibles'
                                : 'Aucune cible trouvée',
                            style: GoogleFonts.poppins(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                    : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _cibles.length,
                        itemBuilder: (context, index) {
                          final cible = _cibles[index];
                          final fields = cible.nonEmptyFields;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(
                                0xff0D443E,
                              ).withOpacity(0.1),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: const Color(0xff0D443E),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              cible.nomCible,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle:
                                fields.isNotEmpty
                                    ? Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children:
                                          fields.map((field) {
                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xffd57653,
                                                ).withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                field,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  color: const Color(
                                                    0xffd57653,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                    )
                                    : Text(
                                      isArabic ? 'Aucun champ' : 'Aucun champ',
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Color(0xffd57653),
                                    size: 20,
                                  ),
                                  onPressed:
                                      () => _navigateToAddCible(cible: cible),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () => _deleteCible(cible),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
