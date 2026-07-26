// lib/pages/landing/widgets/navbar.dart
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:nafahat/pages/landing/landing_page.dart';
import 'package:nafahat/pages/users/inscription_adherent.dart';
import 'package:nafahat/pages/adminisration/add_training_card.dart';
import 'package:nafahat/pages/adminisration/administration_page.dart';
import 'package:nafahat/pages/adminisration/edit_formation.dart';
import 'package:nafahat/pages/adminisration/add_categorie.dart';
import 'package:nafahat/pages/adminisration/edit_categorie.dart';
import 'package:nafahat/pages/adminisration/add_formateur.dart';
import 'package:nafahat/pages/adminisration/add_video_fav_page.dart';
import 'package:nafahat/pages/adminisration/add_duree.dart';
import 'package:nafahat/pages/adminisration/add_typeFormation.dart';
import 'package:nafahat/pages/adminisration/apparence_card.dart';
import 'package:nafahat/pages/adminisration/creerUserPage.dart';
import 'package:nafahat/pages/users/auth_page.dart';
import 'package:nafahat/pages/users/profile_dashboard_page.dart';
import 'package:nafahat/pages/users/edit_profile_page.dart';
import 'package:nafahat/providers/language_provider.dart';
import 'package:nafahat/providers/user_provider.dart';
import 'package:provider/provider.dart';
import '../landing_page.dart';
import 'package:nafahat/services/training_service.dart';

class Navbar extends StatelessWidget {
  final bool isMobile;
  final GlobalKey<ScaffoldState> scaffoldKey;

  static const Color nafahatGreen = Color(0xff0D443E);
  static const Color nafahatGold = Color(0xffC4A46C);

  const Navbar({super.key, required this.isMobile, required this.scaffoldKey});

  // ============================================================
  // MÉTHODES DE PERMISSION
  // ============================================================
  bool _canViewAdmin(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    return userProvider.canViewAdmin;
  }

  bool _canCreateUser(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    return userProvider.canCreateUser;
  }

  bool _canViewAdminPages(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    return userProvider.canViewAdminPages;
  }

  // ============================================================
  // MENU ADMINISTRATION - ITEMS AVEC PERMISSIONS
  // ============================================================
  List<Map<String, dynamic>> _getAdminMenuItems(
    BuildContext context,
    bool isArabic,
  ) {
    final canCreateUser = _canCreateUser(context);

    final items = <Map<String, dynamic>>[
      {
        'value': 'go_to_admin',
        'icon': Icons.dashboard_outlined,
        'title': isArabic ? 'لوحة الإدارة الكاملة' : 'Administration complète',
        'subtitle':
            isArabic
                ? 'Accéder à toutes les fonctionnalités'
                : 'Accéder à toutes les fonctionnalités',
        'isHeader': true,
      },
      {'isDivider': true},
      {
        'value': 'add_training',
        'icon': Icons.add_circle_outline,
        'title': isArabic ? 'إضافة تكوين' : 'Ajouter une formation',
      },
      {
        'value': 'edit_training',
        'icon': Icons.edit,
        'title': isArabic ? 'تعديل تكوين' : 'Modifier une formation',
      },
      {'isDivider': true},
      {
        'value': 'add_duree',
        'icon': Icons.access_time,
        'title': isArabic ? 'إضافة مدة' : 'Ajouter une durée',
      },
      {'isDivider': true},
      {
        'value': 'add_categorie',
        'icon': Icons.category,
        'title': isArabic ? 'إضافة تصنيف' : 'Ajouter une catégorie',
      },
      {
        'value': 'edit_categorie',
        'icon': Icons.edit,
        'title': isArabic ? 'تعديل تصنيف' : 'Modifier une catégorie',
      },
      {'isDivider': true},
      {
        'value': 'add_type_formation',
        'icon': Icons.label_outline,
        'title': isArabic ? 'إضافة نوع تكوين' : 'Ajouter un type de formation',
      },
      {
        'value': 'edit_type_formation',
        'icon': Icons.edit_note,
        'title':
            isArabic ? 'إدارة أنواع التكوين' : 'Gérer les types de formation',
      },
      {'isDivider': true},
      {
        'value': 'add_formateur',
        'icon': Icons.person_add,
        'title': isArabic ? 'إضافة مكون' : 'Ajouter un formateur',
      },
      {'isDivider': true},
      {
        'value': 'add_video',
        'icon': Icons.video_library,
        'title': isArabic ? 'إضافة فيديو' : 'Ajouter une vidéo',
      },
      {'isDivider': true},
      {
        'value': 'manage_trainings',
        'icon': Icons.edit_note,
        'title': isArabic ? 'إدارة التكوينات' : 'Gérer les formations',
      },
      {'isDivider': true},
      {
        'value': 'apparence_card',
        'icon': Icons.palette_outlined,
        'title': isArabic ? 'مظهر البطاقات' : 'Apparence des cartes',
      },
    ];

    // ✅ Ajouter la création d'utilisateur UNIQUEMENT pour SUPER ADMIN
    if (canCreateUser) {
      items.addAll([
        {'isDivider': true},
        {
          'value': 'creer_user',
          'icon': Icons.admin_panel_settings_rounded,
          'title': isArabic ? 'إنشاء مستخدم' : 'Créer un utilisateur',
          'isAdminOnly': true,
        },
      ]);
    }

    return items;
  }

  // ============================================================
  // BUILD PRINCIPAL
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final isArabic = languageProvider.isArabic;
    final canViewAdmin = _canViewAdmin(context);
    final isLoggedIn = userProvider.isLoggedIn;

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
              _buildLogo(isArabic),
              if (isMobile)
                _buildMobileMenuButton()
              else
                _buildDesktopMenu(
                  context,
                  isArabic,
                  languageProvider,
                  userProvider,
                  canViewAdmin,
                  isLoggedIn,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MENU DESKTOP
  // ============================================================
  Widget _buildDesktopMenu(
    BuildContext context,
    bool isArabic,
    LanguageProvider languageProvider,
    UserProvider userProvider,
    bool canViewAdmin,
    bool isLoggedIn,
  ) {
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
        IconButton(
          icon: const Icon(Icons.language, color: nafahatGreen, size: 22),
          onPressed: () {
            languageProvider.toggleLanguage();
          },
          tooltip: isArabic ? "Français" : "العربية",
        ),
        const SizedBox(width: 15),

        // ✅ Menu Admin - UNIQUEMENT si l'utilisateur a les droits
        if (canViewAdmin) ...[
          _buildAdminMenu(context, isArabic),
          const SizedBox(width: 15),
        ],

        // ✅ "Hello, Nom" + Menu Compte
        _buildAccountSection(context, isArabic, userProvider, isLoggedIn),
      ],
    );
  }

  // ============================================================
  // SECTION COMPTE AVEC "HELLO, NOM"
  // ============================================================
  Widget _buildAccountSection(
    BuildContext context,
    bool isArabic,
    UserProvider userProvider,
    bool isLoggedIn,
  ) {
    return Row(
      children: [
        if (isLoggedIn) ...[
          // ✅ Affichage "Hello, Nom"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: nafahatGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                // Avatar avec initiales
                CircleAvatar(
                  radius: 14,
                  backgroundColor: nafahatGreen,
                  child: Text(
                    userProvider.initials,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Texte "Bonjour, Nom"
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isArabic ? 'مرحباً' : 'Bonjour',
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    Text(
                      userProvider.displayName,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: nafahatGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                // Badge rôle
                if (userProvider.userRole != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: nafahatGold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      userProvider.userRole!.libelle,
                      style: GoogleFonts.cairo(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: nafahatGold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
        ],
        // Menu compte
        _buildAccountMenu(context, isArabic, userProvider),
      ],
    );
  }

  // ============================================================
  // MENU ADMINISTRATION
  // ============================================================
  Widget _buildAdminMenu(BuildContext context, bool isArabic) {
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
      onSelected: (value) => _handleAdminAction(context, value, isArabic),
      itemBuilder: (context) => _buildAdminPopupItems(context, isArabic),
    );
  }

  List<PopupMenuItem<String>> _buildAdminPopupItems(
    BuildContext context,
    bool isArabic,
  ) {
    final items = <PopupMenuItem<String>>[];
    final menuItems = _getAdminMenuItems(context, isArabic);

    for (final item in menuItems) {
      if (item['isDivider'] == true) {
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
                        item['title'],
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: nafahatGreen,
                        ),
                      ),
                      Text(
                        item['subtitle'],
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

      // ✅ Vérifier si l'item est réservé au Super Admin
      if (item['isAdminOnly'] == true && !_canCreateUser(context)) {
        continue;
      }

      items.add(
        PopupMenuItem<String>(
          value: item['value'],
          child: Row(
            children: [
              Icon(item['icon'], color: nafahatGreen, size: 20),
              const SizedBox(width: 12),
              Text(item['title'], style: GoogleFonts.cairo()),
            ],
          ),
        ),
      );
    }

    return items;
  }

  void _handleAdminAction(BuildContext context, String value, bool isArabic) {
    switch (value) {
      case 'go_to_admin':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AdministrationPage()),
        );
        break;
      case 'creer_user':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreerUserPage()),
        );
        break;
      case 'add_training':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddTrainingCardPage()),
        );
        break;
      case 'edit_training':
        _showEditTrainingDialog(context, isArabic);
        break;
      case 'add_categorie':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddCategoriePage()),
        );
        break;
      case 'edit_categorie':
        _showEditCategorieDialog(context, isArabic);
        break;
      case 'add_type_formation':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddTypeFormationPage()),
        );
        break;
      case 'edit_type_formation':
        _showEditTypeFormationDialog(context, isArabic);
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
      case 'apparence_card':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ApparenceCardPage()),
        );
        break;
    }
  }

  // ============================================================
  // MENU COMPTE
  // ============================================================
  List<Map<String, dynamic>> _getAccountMenuItems(
    bool isArabic,
    UserProvider userProvider,
  ) {
    final bool isLoggedIn = userProvider.isLoggedIn;
    final bool isAdherentOrFormateur =
        userProvider.isAdherent || userProvider.isFormateur;

    final items = <Map<String, dynamic>>[];

    if (isLoggedIn) {
      items.addAll([
        {
          'value': 'profile',
          'icon': Icons.person_outline,
          'title': isArabic ? 'ملفي الشخصي' : 'Mon profil',
        },
        {
          'value': 'dashboard',
          'icon': Icons.dashboard_outlined,
          'title': isArabic ? 'لوحة التحكم' : 'Tableau de bord',
        },
      ]);

      if (isAdherentOrFormateur) {
        items.add({
          'value': 'account_management',
          'icon': Icons.settings_outlined,
          'title': isArabic ? 'إدارة الحساب' : 'Gestion de compte',
        });
      }

      items.add({'isDivider': true});
      items.add({
        'value': 'logout',
        'icon': Icons.logout_rounded,
        'title': isArabic ? 'تسجيل الخروج' : 'Déconnexion',
        'isDanger': true,
      });
    } else {
      // ✅ Utilisateur NON connecté - Afficher "Créer un compte" et "Authentification"
      items.addAll([
        {
          'value': 'create_account',
          'icon': Icons.person_add,
          'title': isArabic ? 'إنشاء حساب' : 'Créer un compte',
        },
        {
          'value': 'authentification',
          'icon': Icons.login,
          'title': isArabic ? 'تسجيل الدخول' : 'Authentification',
        },
      ]);
    }

    return items;
  }

  Widget _buildAccountMenu(
    BuildContext context,
    bool isArabic,
    UserProvider userProvider,
  ) {
    return PopupMenuButton<String>(
      child: CircleAvatar(
        backgroundColor: nafahatGreen.withOpacity(0.1),
        child: Icon(
          userProvider.isLoggedIn
              ? Icons.person_rounded
              : Icons.person_outline_rounded,
          color: nafahatGreen,
        ),
      ),
      tooltip: isArabic ? "حسابي" : "Mon compte",
      offset: const Offset(0, 50),
      onSelected: (value) => _handleAccountAction(context, value, isArabic),
      itemBuilder:
          (context) => _buildAccountPopupItems(context, isArabic, userProvider),
    );
  }

  List<PopupMenuItem<String>> _buildAccountPopupItems(
    BuildContext context,
    bool isArabic,
    UserProvider userProvider,
  ) {
    final items = <PopupMenuItem<String>>[];
    final menuItems = _getAccountMenuItems(isArabic, userProvider);

    for (final item in menuItems) {
      if (item['isDivider'] == true) {
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
                item['title'],
                style: GoogleFonts.cairo(color: isDanger ? Colors.red : null),
              ),
            ],
          ),
        ),
      );
    }

    return items;
  }

  void _handleAccountAction(BuildContext context, String value, bool isArabic) {
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
      case 'account_management':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic
                  ? '🔧 إدارة الحساب - قريباً'
                  : '🔧 Gestion de compte - Bientôt disponible',
            ),
            backgroundColor: nafahatGreen,
          ),
        );
        break;
      case 'logout':
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.logout();
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
  // DRAWER MOBILE
  // ============================================================
  Widget buildDrawer(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;
    final userProvider = Provider.of<UserProvider>(context);
    final canViewAdmin = _canViewAdmin(context);
    final isLoggedIn = userProvider.isLoggedIn;
    final isAdherentOrFormateur =
        userProvider.isAdherent || userProvider.isFormateur;

    return Drawer(
      backgroundColor: Colors.white.withOpacity(0.92),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Column(
          children: [
            _buildDrawerHeader(isArabic, userProvider),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                children: [
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

                  // ✅ Section Admin - UNIQUEMENT si l'utilisateur a les droits
                  if (canViewAdmin) _buildDrawerAdminSection(context, isArabic),

                  const Divider(height: 30, thickness: 1),

                  // ✅ Section Compte - pour tous les utilisateurs (connectés ou non)
                  _buildDrawerAccountSection(context, isArabic, userProvider),

                  const Divider(height: 30, thickness: 1),

                  // ✅ Gestion de compte - pour Adhérent ou Formateur (connecté)
                  if (isLoggedIn && isAdherentOrFormateur)
                    _drawerTile(
                      icon: Icons.settings_outlined,
                      title: isArabic ? "إدارة الحساب" : "Gestion de compte",
                      onTap: () {
                        _closeDrawer(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isArabic
                                  ? '🔧 إدارة الحساب - قريباً'
                                  : '🔧 Gestion de compte - Bientôt disponible',
                            ),
                            backgroundColor: nafahatGreen,
                          ),
                        );
                      },
                    ),

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

                  // ✅ Déconnexion - UNIQUEMENT si connecté
                  if (isLoggedIn)
                    _drawerTile(
                      icon: Icons.logout_rounded,
                      title: isArabic ? "تسجيل الخروج" : "Déconnexion",
                      color: Colors.red,
                      onTap: () {
                        _closeDrawer(context);
                        userProvider.logout();
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

                  // ✅ Bouton de langue
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
                      Provider.of<LanguageProvider>(
                        context,
                        listen: false,
                      ).toggleLanguage();
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

  Widget _buildDrawerHeader(bool isArabic, UserProvider userProvider) {
    return Container(
      height: 130,
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
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? "نفحات" : "Nafahat",
                  style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  isArabic
                      ? "منصة التدريب والتطوير"
                      : "Plateforme de formation",
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                if (userProvider.isLoggedIn && userProvider.userRole != null)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '👤 ${userProvider.displayName} • ${userProvider.userRole!.libelle}',
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (!userProvider.isLoggedIn)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isArabic ? '⚠️ غير مسجل الدخول' : '⚠️ Non connecté',
                      style: GoogleFonts.cairo(
                        fontSize: 9,
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerAdminSection(BuildContext context, bool isArabic) {
    final canCreateUser = _canCreateUser(context);

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
      children: [
        ..._getAdminMenuItems(context, isArabic)
            .where(
              (item) =>
                  !item.containsKey('isDivider') &&
                  !item.containsKey('isHeader') &&
                  (item['isAdminOnly'] != true || canCreateUser),
            )
            .map((item) {
              return _drawerTile(
                icon: item['icon'],
                title: item['title'],
                padding: const EdgeInsets.only(left: 32),
                onTap: () {
                  _closeDrawer(context);
                  _handleAdminAction(context, item['value'], isArabic);
                },
              );
            })
            .toList(),
      ],
    );
  }

  // ============================================================
  // SECTION COMPTE DANS LE DRAWER (MOBILE)
  // ============================================================
  Widget _buildDrawerAccountSection(
    BuildContext context,
    bool isArabic,
    UserProvider userProvider,
  ) {
    final bool isLoggedIn = userProvider.isLoggedIn;

    return ExpansionTile(
      leading: Icon(
        isLoggedIn ? Icons.person_rounded : Icons.person_outline_rounded,
        color: nafahatGreen,
      ),
      title: Text(
        isLoggedIn
            ? (isArabic ? "👤 حسابي" : "👤 Mon compte")
            : (isArabic ? "👤 حساب" : "👤 Compte"),
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
          _getAccountMenuItems(
            isArabic,
            userProvider,
          ).where((item) => !item.containsKey('isDivider')).map((item) {
            final isDanger = item['isDanger'] ?? false;
            return _drawerTile(
              icon: item['icon'],
              title: item['title'],
              color: isDanger ? Colors.red : null,
              padding: const EdgeInsets.only(left: 32),
              onTap: () {
                _closeDrawer(context);
                _handleAccountAction(context, item['value'], isArabic);
              },
            );
          }).toList(),
    );
  }

  // ============================================================
  // WIDGETS COMMUNS
  // ============================================================
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

  Widget _buildLogo(bool isArabic) {
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

  Widget _buildMobileMenuButton() {
    return IconButton(
      icon: const Icon(Icons.menu_rounded, color: nafahatGreen, size: 30),
      onPressed: () => scaffoldKey.currentState?.openDrawer(),
    );
  }

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

  void _closeDrawer(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _closeDrawerAndNavigate(BuildContext context, Widget page) {
    Navigator.of(context).pop();
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  // ============================================================
  // DIALOGUES ADMINISTRATION
  // ============================================================
  void _showEditTrainingDialog(BuildContext context, bool isArabic) {
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

  void _showEditCategorieDialog(BuildContext context, bool isArabic) {
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

  void _showEditTypeFormationDialog(BuildContext context, bool isArabic) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            isArabic ? 'تعديل نوع تكوين' : 'Modifier un type de formation',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isArabic
                      ? 'اختر نوع تكوين من القائمة أدناه'
                      : 'Sélectionnez un type de formation dans la liste ci-dessous',
                  style: GoogleFonts.cairo(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _loadTypesFormationList(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data!.isEmpty) {
                      return Text(
                        isArabic
                            ? 'لا توجد أنواع تكوين متاحة'
                            : 'Aucun type de formation disponible',
                        style: GoogleFonts.cairo(color: Colors.grey.shade600),
                      );
                    }
                    final types = snapshot.data!;
                    return Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: types.length,
                        itemBuilder: (context, index) {
                          final type = types[index];
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

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(
                                0xffd57653,
                              ).withOpacity(0.1),
                              child: Text(
                                '${index + 1}',
                                style: GoogleFonts.cairo(
                                  color: const Color(0xffd57653),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              type['type_formation'] ?? 'Sans nom',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              '$chapters chapitre${chapters > 1 ? 's' : ''}',
                              style: GoogleFonts.cairo(
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
                                      (context) => AddTypeFormationPage(
                                        typeToEdit: type,
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

  Future<List<Map<String, dynamic>>> _loadTypesFormationList() async {
    try {
      final response = await http.get(
        Uri.parse('${TrainingService.apiBaseUrl}/types-formation'),
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
      print('❌ Erreur chargement types de formation: $e');
      return [];
    }
  }
}
