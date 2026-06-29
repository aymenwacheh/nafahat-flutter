// lib/widgets/navbar.dart
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:nafahat/pages/users/inscription_adherent.dart';
import 'package:nafahat/pages/adminisration/add_training_card.dart';
import 'package:nafahat/pages/adminisration/administration_page.dart';
import 'package:nafahat/pages/adminisration/edit_formation.dart';
import 'package:nafahat/pages/adminisration/add_categorie.dart';
import 'package:nafahat/pages/adminisration/edit_categorie.dart';
import 'package:nafahat/pages/adminisration/add_formateur.dart';
import 'package:nafahat/pages/adminisration/add_video_fav_page.dart';
import 'package:nafahat/pages/adminisration/add_duree.dart';
import 'package:nafahat/pages/users/auth_page.dart';
import 'package:nafahat/pages/users/profile_dashboard_page.dart';
import 'package:nafahat/pages/users/edit_profile_page.dart';
import '/landing/landing_page.dart';
import 'package:nafahat/services/training_service.dart';

class Navbar extends StatelessWidget {
  final bool isArabic;
  final bool isMobile;
  final VoidCallback onLanguageToggle;
  final GlobalKey<ScaffoldState> scaffoldKey;

  final bool isUserLoggedIn = true;
  final bool isAdmin = true;

  static const Color nafahatGreen = Color(0xff0D443E);
  static const Color nafahatGold = Color(0xffC4A46C);

  const Navbar({
    super.key,
    required this.isArabic,
    required this.isMobile,
    required this.onLanguageToggle,
    required this.scaffoldKey,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 85,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 50,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.75),
            border: Border(
              bottom: BorderSide(
                color: nafahatGreen.withOpacity(0.08),
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ---- Logo ----
              _buildLogo(),
              // ---- Menu ----
              if (isMobile)
                _buildMobileMenuButton()
              else
                _buildDesktopMenu(context),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOGO
  // ============================================================
  Widget _buildLogo() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            image: const DecorationImage(
              image: AssetImage('assets/images/logo.jpg'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          isArabic ? "نفحات" : "Nafahat",
          style: GoogleFonts.cairo(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: nafahatGreen,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BOUTON MENU MOBILE
  // ============================================================
  Widget _buildMobileMenuButton() {
    return IconButton(
      icon: const Icon(Icons.menu_rounded, color: nafahatGreen, size: 30),
      onPressed: () => scaffoldKey.currentState?.openDrawer(),
    );
  }

  // ============================================================
  // MENU DESKTOP
  // ============================================================
  Widget _buildDesktopMenu(BuildContext context) {
    return Row(
      children: [
        _navLink(
          context: context,
          title: isArabic ? "الرئيسية" : "Accueil",
          onTap: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LandingPage()),
              (route) => false,
            );
          },
        ),
        _navLink(
          context: context,
          title: isArabic ? "الدورات" : "Cycles",
          onTap: () {},
        ),
        _navLink(
          context: context,
          title: isArabic ? "عن المنصة" : "À propos",
          onTap: () {},
        ),
        const SizedBox(width: 15),
        // ---- Bouton Langue ----
        IconButton(
          icon: const Icon(Icons.language, color: nafahatGreen, size: 22),
          onPressed: onLanguageToggle,
          tooltip: isArabic ? "Français" : "العربية",
        ),
        const SizedBox(width: 15),
        // ---- MENU ADMINISTRATION ----
        if (isAdmin) _buildAdminMenu(context),
        const SizedBox(width: 15),
        // ---- MENU COMPTE ----
        _buildAccountMenu(context),
      ],
    );
  }

  // ============================================================
  // MENU ADMINISTRATION (Desktop & Mobile partagé)
  // ============================================================
  List<Map<String, dynamic>> get _adminMenuItems {
    return [
      {
        'value': 'go_to_admin',
        'icon': Icons.dashboard_outlined,
        'titleFr': 'Administration complète',
        'titleAr': 'لوحة الإدارة الكاملة',
        'subtitleFr': 'Accéder à toutes les fonctionnalités',
        'subtitleAr': 'Accéder à toutes les fonctionnalités',
        'isHeader': true,
      },
      {'isDivider': true},
      {
        'value': 'add_training',
        'icon': Icons.add_circle_outline,
        'titleFr': 'Ajouter une formation',
        'titleAr': 'إضافة تكوين',
      },
      {
        'value': 'edit_training',
        'icon': Icons.edit,
        'titleFr': 'Modifier une formation',
        'titleAr': 'تعديل تكوين',
      },
      {'isDivider': true},
      {
        'value': 'add_duree',
        'icon': Icons.access_time,
        'titleFr': 'Ajouter une durée',
        'titleAr': 'إضافة مدة',
      },
      {'isDivider': true},
      {
        'value': 'add_categorie',
        'icon': Icons.category,
        'titleFr': 'Ajouter une catégorie',
        'titleAr': 'إضافة تصنيف',
      },
      {
        'value': 'edit_categorie',
        'icon': Icons.edit,
        'titleFr': 'Modifier une catégorie',
        'titleAr': 'تعديل تصنيف',
      },
      {'isDivider': true},
      {
        'value': 'add_formateur',
        'icon': Icons.person_add,
        'titleFr': 'Ajouter un formateur',
        'titleAr': 'إضافة مكون',
      },
      {'isDivider': true},
      {
        'value': 'add_video',
        'icon': Icons.video_library,
        'titleFr': 'Ajouter une vidéo',
        'titleAr': 'إضافة فيديو',
      },
      {'isDivider': true},
      {
        'value': 'manage_trainings',
        'icon': Icons.edit_note,
        'titleFr': 'Gérer les formations',
        'titleAr': 'إدارة التكوينات',
      },
    ];
  }

  Widget _buildAdminMenu(BuildContext context) {
    return PopupMenuButton<String>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: nafahatGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.admin_panel_settings,
              color: nafahatGreen,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              isArabic ? "الإدارة" : "Admin",
              style: GoogleFonts.cairo(
                color: nafahatGreen,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      tooltip: isArabic ? "لوحة التحكم" : "Administration",
      offset: const Offset(0, 50),
      onSelected: (value) => _handleAdminAction(context, value),
      itemBuilder: (context) => _buildAdminPopupItems(context),
    );
  }

  List<PopupMenuItem<String>> _buildAdminPopupItems(BuildContext context) {
    final items = <PopupMenuItem<String>>[];

    for (final item in _adminMenuItems) {
      if (item['isDivider'] == true) {
        // ✅ Correction : utiliser PopupMenuItem avec Divider au lieu de PopupMenuDivider
        items.add(
          PopupMenuItem<String>(
            enabled: false,
            child: const Divider(height: 1, thickness: 1, color: Colors.grey),
          ),
        );
        continue;
      }

      if (item['isHeader'] == true) {
        items.add(
          PopupMenuItem<String>(
            value: item['value'],
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: nafahatGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(item['icon'], color: nafahatGreen, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic ? item['titleAr'] : item['titleFr'],
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: nafahatGreen,
                        ),
                      ),
                      Text(
                        isArabic ? item['subtitleAr'] : item['subtitleFr'],
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      items.add(
        PopupMenuItem<String>(
          value: item['value'],
          child: Row(
            children: [
              Icon(item['icon'], color: nafahatGreen, size: 20),
              const SizedBox(width: 12),
              Text(
                isArabic ? item['titleAr'] : item['titleFr'],
                style: GoogleFonts.cairo(),
              ),
            ],
          ),
        ),
      );
    }

    return items;
  }

  void _handleAdminAction(BuildContext context, String value) {
    switch (value) {
      case 'go_to_admin':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AdministrationPage()),
        );
        break;
      case 'add_training':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddTrainingCardPage()),
        );
        break;
      case 'edit_training':
        _showEditTrainingDialog(context);
        break;
      case 'add_categorie':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddCategoriePage()),
        );
        break;
      case 'edit_categorie':
        _showEditCategorieDialog(context);
        break;
      case 'add_formateur':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddFormateurPage()),
        );
        break;
      case 'add_video':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddVideoFavPage()),
        );
        break;
      case 'add_duree':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddDureePage()),
        );
        break;
      case 'manage_trainings':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic
                  ? 'إدارة التكوينات - قريباً'
                  : 'Gestion des formations - Bientôt disponible',
            ),
          ),
        );
        break;
    }
  }

  // ============================================================
  // MENU COMPTE (Desktop & Mobile partagé)
  // ============================================================
  List<Map<String, dynamic>> get _accountMenuItems {
    return [
      {
        'value': 'create_account',
        'icon': Icons.person_add,
        'titleFr': 'Créer un compte',
        'titleAr': 'إنشاء حساب',
      },
      {
        'value': 'authentification',
        'icon': Icons.login,
        'titleFr': 'Authentification',
        'titleAr': 'تسجيل الدخول',
      },
      {
        'value': 'profile',
        'icon': Icons.person_outline,
        'titleFr': 'Mon profil',
        'titleAr': 'ملفي الشخصي',
      },
      {
        'value': 'dashboard',
        'icon': Icons.dashboard_outlined,
        'titleFr': 'Tableau de bord',
        'titleAr': 'لوحة التحكم',
      },
      {'isDivider': true},
      {
        'value': 'logout',
        'icon': Icons.logout_rounded,
        'titleFr': 'Déconnexion',
        'titleAr': 'تسجيل الخروج',
        'isDanger': true,
      },
    ];
  }

  Widget _buildAccountMenu(BuildContext context) {
    return PopupMenuButton<String>(
      child: CircleAvatar(
        backgroundColor: nafahatGreen.withOpacity(0.1),
        child: const Icon(Icons.person_outline_rounded, color: nafahatGreen),
      ),
      tooltip: isArabic ? "حسابي" : "Mon compte",
      offset: const Offset(0, 50),
      onSelected: (value) => _handleAccountAction(context, value),
      itemBuilder: (context) => _buildAccountPopupItems(context),
    );
  }

  List<PopupMenuItem<String>> _buildAccountPopupItems(BuildContext context) {
    final items = <PopupMenuItem<String>>[];

    for (final item in _accountMenuItems) {
      if (item['isDivider'] == true) {
        // ✅ Correction : utiliser PopupMenuItem avec Divider
        items.add(
          PopupMenuItem<String>(
            enabled: false,
            child: const Divider(height: 1, thickness: 1, color: Colors.grey),
          ),
        );
        continue;
      }

      final isDanger = item['isDanger'] ?? false;
      items.add(
        PopupMenuItem<String>(
          value: item['value'],
          child: Row(
            children: [
              Icon(
                item['icon'],
                color: isDanger ? Colors.red : nafahatGreen,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                isArabic ? item['titleAr'] : item['titleFr'],
                style: GoogleFonts.cairo(color: isDanger ? Colors.red : null),
              ),
            ],
          ),
        ),
      );
    }

    return items;
  }

  void _handleAccountAction(BuildContext context, String value) {
    switch (value) {
      case 'create_account':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const InscriptionAdherentPage(),
          ),
        );
        break;
      case 'authentification':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AuthPage()),
        );
        break;
      case 'profile':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EditProfilePage()),
        );
        break;
      case 'dashboard':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileDashboardPage()),
        );
        break;
      case 'logout':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic ? "🔓 تم تسجيل الخروج بنجاح" : "🔓 Déconnexion réussie",
            ),
            backgroundColor: nafahatGreen,
          ),
        );
        break;
    }
  }

  // ============================================================
  // DRAWER MOBILE (Centralisé ici)
  // ============================================================
  Widget buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white.withOpacity(0.92),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Column(
          children: [
            // --- En-tête ---
            _buildDrawerHeader(),
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
                    onTap:
                        () => _closeDrawerAndNavigate(
                          context,
                          const LandingPage(),
                        ),
                  ),
                  _drawerTile(
                    icon: Icons.video_library_outlined,
                    title: isArabic ? "فيديوهات مميزة" : "Vidéos Favorites",
                    onTap: () => _closeDrawer(context),
                  ),
                  _drawerTile(
                    icon: Icons.school_outlined,
                    title: isArabic ? "الدورات" : "Cycles de Formation",
                    onTap: () => _closeDrawer(context),
                  ),
                  _drawerTile(
                    icon: Icons.info_outline,
                    title: isArabic ? "عن المنصة" : "À propos",
                    onTap: () => _closeDrawer(context),
                  ),
                  const Divider(height: 30, thickness: 1),

                  // --- ADMINISTRATION ---
                  if (isAdmin) _buildDrawerAdminSection(context),
                  const Divider(height: 30, thickness: 1),

                  // --- COMPTE ---
                  if (isUserLoggedIn) _buildDrawerAccountSection(context),
                  const Divider(height: 30, thickness: 1),

                  // --- TRAITER L'ACTIVITÉ ---
                  _drawerTile(
                    icon: Icons.build_circle_outlined,
                    title:
                        isArabic ? "🔧 معالجة النشاط" : "🔧 Traiter l'activité",
                    onTap: () {
                      _closeDrawer(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isArabic
                                ? 'معالجة النشاط - قريباً'
                                : 'Traitement de l\'activité - Bientôt disponible',
                          ),
                          backgroundColor: nafahatGreen,
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
                        _closeDrawer(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isArabic
                                  ? "🔓 تم تسجيل الخروج بنجاح"
                                  : "🔓 Déconnexion réussie",
                            ),
                            backgroundColor: nafahatGreen,
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 20),

                  // --- Bouton Langue ---
                  ListTile(
                    leading: const Icon(Icons.language, color: nafahatGreen),
                    title: Text(
                      isArabic ? "Changer en Français" : "تغيير إلى العربية",
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff2c221e),
                        fontSize: 15,
                      ),
                    ),
                    onTap: () {
                      _closeDrawer(context);
                      onLanguageToggle();
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: nafahatGreen.withOpacity(0.06),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      height: 120,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [nafahatGreen, nafahatGreen.withOpacity(0.8)],
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
                isArabic ? "منصة التدريب والتطوير" : "Plateforme de formation",
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerAdminSection(BuildContext context) {
    return ExpansionTile(
      leading: Icon(Icons.admin_panel_settings, color: nafahatGreen),
      title: Text(
        isArabic ? "⚙️ الإدارة" : "⚙️ Administration",
        style: GoogleFonts.cairo(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: nafahatGreen,
        ),
      ),
      iconColor: nafahatGreen,
      collapsedIconColor: nafahatGreen,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      children:
          _adminMenuItems
              .where(
                (item) =>
                    !item.containsKey('isDivider') &&
                    !item.containsKey('isHeader'),
              )
              .map((item) {
                return _drawerTile(
                  icon: item['icon'],
                  title: isArabic ? item['titleAr'] : item['titleFr'],
                  padding: const EdgeInsets.only(left: 32),
                  onTap: () {
                    _closeDrawer(context);
                    _handleAdminAction(context, item['value']);
                  },
                );
              })
              .toList(),
    );
  }

  Widget _buildDrawerAccountSection(BuildContext context) {
    return ExpansionTile(
      leading: Icon(Icons.person_outline, color: nafahatGreen),
      title: Text(
        isArabic ? "👤 حسابي" : "👤 Mon compte",
        style: GoogleFonts.cairo(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: nafahatGreen,
        ),
      ),
      iconColor: nafahatGreen,
      collapsedIconColor: nafahatGreen,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      children:
          _accountMenuItems.where((item) => !item.containsKey('isDivider')).map(
            (item) {
              final isDanger = item['isDanger'] ?? false;
              return _drawerTile(
                icon: item['icon'],
                title: isArabic ? item['titleAr'] : item['titleFr'],
                color: isDanger ? Colors.red : null,
                padding: const EdgeInsets.only(left: 32),
                onTap: () {
                  _closeDrawer(context);
                  _handleAccountAction(context, item['value']);
                },
              );
            },
          ).toList(),
    );
  }

  Widget _drawerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  }) {
    final textColor = color ?? const Color(0xff2c221e);
    return ListTile(
      leading: Icon(icon, color: color ?? const Color(0xff7c6e68)),
      title: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: Colors.transparent,
      hoverColor: nafahatGreen.withOpacity(0.05),
      contentPadding: padding,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
    );
  }

  void _closeDrawer(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _closeDrawerAndNavigate(BuildContext context, Widget page) {
    Navigator.of(context).pop();
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  // ============================================================
  // LIENS NAVIGATION
  // ============================================================
  Widget _navLink({
    required BuildContext context,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            title,
            style: GoogleFonts.cairo(
              color: const Color(0xff2c221e),
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DIALOGUES ADMINISTRATION
  // ============================================================
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
                const SizedBox(height: 16),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _loadFormationsList(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return Text(
                        isArabic
                            ? 'خطأ في تحميل التكوينات'
                            : 'Erreur de chargement des formations',
                        style: GoogleFonts.cairo(color: Colors.red.shade400),
                      );
                    }
                    final formations = snapshot.data!;
                    if (formations.isEmpty) {
                      return Text(
                        isArabic
                            ? 'لا توجد تكوينات متاحة'
                            : 'Aucune formation disponible',
                        style: GoogleFonts.cairo(color: Colors.grey.shade600),
                      );
                    }
                    return Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: formations.length,
                        itemBuilder: (context, index) {
                          final formation = formations[index];
                          final title =
                              isArabic
                                  ? formation['titre_ar'] ??
                                      formation['titre_fr'] ??
                                      'Sans titre'
                                  : formation['titre_fr'] ??
                                      formation['titre_ar'] ??
                                      'Sans titre';
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: nafahatGreen.withOpacity(0.1),
                              child: Text(
                                '${index + 1}',
                                style: GoogleFonts.cairo(
                                  color: nafahatGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              'ID: ${formation['id']}',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: nafahatGreen,
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => EditFormationPage(
                                        formationId: formation['id'].toString(),
                                      ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    );
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

  Future<List<Map<String, dynamic>>> _loadFormationsList() async {
    try {
      final response = await http.get(
        Uri.parse('${TrainingService.apiBaseUrl}/formations/admin/all'),
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
      print('❌ Erreur chargement formations: $e');
      return [];
    }
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
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isArabic
                      ? 'اختر تصنيفاً من القائمة أدناه'
                      : 'Sélectionnez une catégorie dans la liste ci-dessous',
                  style: GoogleFonts.cairo(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _loadCategoriesList(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data!.isEmpty) {
                      return Text(
                        isArabic
                            ? 'لا توجد تصنيفات متاحة'
                            : 'Aucune catégorie disponible',
                        style: GoogleFonts.cairo(color: Colors.grey.shade600),
                      );
                    }
                    final categories = snapshot.data!;
                    return Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          final name =
                              isArabic
                                  ? cat['categorie_ar'] ?? cat['categorie_fr']
                                  : cat['categorie_fr'] ?? cat['categorie_ar'];
                          final parentName =
                              cat['parent_fr'] ?? cat['parent_ar'];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: nafahatGreen.withOpacity(0.1),
                              child: Text(
                                '${index + 1}',
                                style: GoogleFonts.cairo(
                                  color: nafahatGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              name ?? 'Sans nom',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              parentName != null
                                  ? (isArabic
                                      ? 'الأب: $parentName'
                                      : 'Parent: $parentName')
                                  : (isArabic
                                      ? 'تصنيف رئيسي'
                                      : 'Catégorie principale'),
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: nafahatGreen,
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => EditCategoriePage(
                                        itemId: cat['id'].toString(),
                                        type: 'categorie',
                                      ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    );
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

  Future<List<Map<String, dynamic>>> _loadCategoriesList() async {
    try {
      final response = await http.get(
        Uri.parse('${TrainingService.apiBaseUrl}/categories'),
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
      print('❌ Erreur chargement catégories: $e');
      return [];
    }
  }
}
