// lib/pages/landing/widgets/navbar.dart
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:nafahat/pages/landing/landing_page.dart';
import 'about.dart';
import 'package:nafahat/pages/widgets/all_video_page.dart';
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
import 'package:nafahat/services/auth_service.dart';
import 'package:nafahat/services/cart_service.dart';
import 'package:provider/provider.dart';
import 'package:nafahat/services/training_service.dart';
import 'package:nafahat/pages/widgets/cart_popup.dart';
import 'package:nafahat/pages/adminisration/add_about.dart';
import 'package:nafahat/pages/adminisration/apparence_hero.dart';
import 'package:nafahat/pages/adminisration/apparence_landing.dart';
import 'package:nafahat/pages/adminisration/apparence_card_formateur.dart';
import 'package:nafahat/pages/adminisration/apparence_bull.dart';
import 'package:nafahat/pages/adminisration/adherents_list_page.dart';
import 'package:nafahat/pages/adminisration/users_list_page.dart';
import 'package:nafahat/pages/adminisration/etat_paiement.dart';
import 'package:nafahat/pages/adminisration/add_cible_page.dart';
import 'package:nafahat/pages/adminisration/edit_formateur.dart';

class Navbar extends StatelessWidget {
  final bool isMobile;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  static const Color nafahatGreen = Color(0xff0D443E);
  static const Color nafahatGold = Color(0xffC4A46C);

  const Navbar({super.key, required this.isMobile, this.scaffoldKey});

  // ============================================================
  // MÉTHODE DE DÉCONNEXION UNIFIÉE
  // ============================================================
  void _performLogout(BuildContext context) async {
    final isArabic = Provider.of<LanguageProvider>(context, listen: false).isArabic;
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    await userProvider.logout();
    AuthService.logout();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? "🔓 تم تسجيل الخروج بنجاح" : "🔓 Déconnexion réussie",
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: nafahatGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LandingPage()),
        (route) => false,
      );
    }
  }

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

  // ============================================================
  // OUVRIR / FERMER LE DRAWER
  // ============================================================
  void _openDrawer() {
    if (scaffoldKey == null || scaffoldKey!.currentState == null) return;
    scaffoldKey!.currentState!.openDrawer();
  }

  void _closeDrawer(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _closeDrawerAndNavigate(BuildContext context, Widget page) {
    _closeDrawer(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
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

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: isMobile ? 70 : 80,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 40,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            border: Border(
              bottom: BorderSide(
                color: nafahatGreen.withOpacity(0.06),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLogo(isArabic, isMobile),
              if (isMobile) _buildMobileMenuButton(),
              if (!isMobile)
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildSearchBar(isArabic),
                      const SizedBox(width: 16),
                      _buildDesktopMenu(context, isArabic),
                      const SizedBox(width: 16),
                      if (canViewAdmin) _buildAdminMenu(context, isArabic),
                      _buildCartIcon(context, isArabic),
                      _buildUserSection(context, isArabic, userProvider),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOGO
  // ============================================================
  Widget _buildLogo(bool isArabic, bool isMobile) {
    return Row(
      children: [
        Text(
          isArabic ? "نفحات" : "Nafahat",
          style: GoogleFonts.cairo(
            fontSize: isMobile ? 20 : 26,
            fontWeight: FontWeight.w800,
            color: nafahatGreen,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: nafahatGold,
            shape: BoxShape.circle,
          ),
        ),
        Text(
          isArabic ? "أكاديمية" : "Academy",
          style: GoogleFonts.cairo(
            fontSize: isMobile ? 12 : 16,
            fontWeight: FontWeight.w400,
            color: nafahatGold,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BARRE DE RECHERCHE
  // ============================================================
  Widget _buildSearchBar(bool isArabic) {
    return Container(
      width: 220,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.search_rounded, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: isArabic ? 'ابحث عن دورة...' : 'Rechercher un cours...',
                hintStyle: GoogleFonts.cairo(
                  fontSize: 13,
                  color: Colors.grey.shade400,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onSubmitted: (value) {},
            ),
          ),
          const SizedBox(width: 4),
          Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: nafahatGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: Colors.white,
              ),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  // ============================================================
  // ICONE PANIER
  // ============================================================
  Widget _buildCartIcon(BuildContext context, bool isArabic) {
    return StreamBuilder<int>(
      stream: CartService.cartCountStream,
      initialData: 0,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Stack(
          children: [
            IconButton(
              icon: Icon(
                Icons.shopping_cart_outlined,
                color: nafahatGreen,
                size: 24,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: true,
                  barrierColor: Colors.black.withOpacity(0.4),
                  builder: (context) => const CartPopup(),
                );
              },
              tooltip: isArabic ? 'السلة' : 'Panier',
            ),
            if (count > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: nafahatGold,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      count > 99 ? '99+' : count.toString(),
                      style: GoogleFonts.cairo(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ============================================================
  // MENU DESKTOP
  // ============================================================
  Widget _buildDesktopMenu(BuildContext context, bool isArabic) {
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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AllTrainingsPage()),
            );
          },
        ),
        _navLink(
          context: context,
          title: isArabic ? "فيديوهات" : "Vidéos",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AllVideoPage()),
            );
          },
        ),
        _navLink(
          context: context,
          title: isArabic ? "عن المنصة" : "À propos",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AboutPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _navLink({
    required BuildContext context,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Text(
            title,
            style: GoogleFonts.cairo(
              color: const Color(0xff2c221e),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION UTILISATEUR
  // ============================================================
  Widget _buildUserSection(
    BuildContext context,
    bool isArabic,
    UserProvider userProvider,
  ) {
    if (userProvider.isLoggedIn) {
      return PopupMenuButton<String>(
        tooltip: isArabic ? "حسابي" : "Mon compte",
        offset: const Offset(0, 50),
        onSelected: (value) => _handleAccountAction(context, value, isArabic),
        itemBuilder: (context) => _buildAccountPopupItems(context, isArabic, userProvider),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: nafahatGreen.withOpacity(0.06),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: nafahatGreen.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
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
              Text(
                userProvider.displayName,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: nafahatGreen,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_drop_down, color: nafahatGreen, size: 20),
            ],
          ),
        ),
      );
    } else {
      return Row(
        children: [
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InscriptionAdherentPage(),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: nafahatGreen,
              side: BorderSide(color: nafahatGreen.withOpacity(0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(isArabic ? 'انضم' : "S'inscrire"),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AuthPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: nafahatGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 0,
              textStyle: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(isArabic ? 'تسجيل الدخول' : 'Se connecter'),
          ),
        ],
      );
    }
  }

  // ============================================================
  // MENU ADMINISTRATION - WEB (Popup) - COMPLET
  // ============================================================
  Widget _buildAdminMenu(BuildContext context, bool isArabic) {
    return PopupMenuButton<String>(
      tooltip: isArabic ? "لوحة التحكم" : "Administration",
      offset: const Offset(0, 50),
      onSelected: (value) => _handleAdminAction(context, value, isArabic),
      itemBuilder: (context) => _buildAdminPopupItems(context, isArabic),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: nafahatGreen.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(Icons.admin_panel_settings, color: nafahatGreen, size: 18),
            const SizedBox(width: 4),
            Text(
              isArabic ? "الإدارة" : "Admin",
              style: GoogleFonts.cairo(
                color: nafahatGreen,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PopupMenuItem<String>> _buildAdminPopupItems(
    BuildContext context,
    bool isArabic,
  ) {
    final items = <PopupMenuItem<String>>[];

    // En-tête - Accès à l'administration complète
    items.add(
      PopupMenuItem<String>(
        value: 'go_to_admin',
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: nafahatGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.dashboard_outlined, color: nafahatGreen, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'لوحة الإدارة الكاملة' : 'Administration complète',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: nafahatGreen,
                    ),
                  ),
                  Text(
                    isArabic ? 'Accéder à toutes les fonctionnalités' : 'Accéder à toutes les fonctionnalités',
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

    items.add(const PopupMenuItem<String>(
      enabled: false,
      child: Divider(height: 1, thickness: 1, color: Colors.grey),
    ));

    // ============================================================
    // GROUPE FORMATION
    // ============================================================
    final formationItems = [
      {'value': 'add_training', 'icon': Icons.add_circle_outline, 'title': isArabic ? 'إضافة تكوين' : 'Ajouter une formation'},
      {'value': 'edit_training', 'icon': Icons.edit, 'title': isArabic ? 'تعديل تكوين' : 'Modifier une formation'},
      {'value': 'add_duree', 'icon': Icons.access_time, 'title': isArabic ? 'إضافة مدة' : 'Ajouter une durée'},
      {'value': 'add_categorie', 'icon': Icons.category, 'title': isArabic ? 'إضافة تصنيف' : 'Ajouter une catégorie'},
      {'value': 'edit_categorie', 'icon': Icons.edit, 'title': isArabic ? 'تعديل تصنيف' : 'Modifier une catégorie'},
      {'value': 'add_type_formation', 'icon': Icons.label_outline, 'title': isArabic ? 'إضافة نوع تكوين' : 'Ajouter un type de formation'},
      {'value': 'edit_type_formation', 'icon': Icons.edit_note, 'title': isArabic ? 'إدارة أنواع التكوين' : 'Gérer les types de formation'},
      {'value': 'add_formateur', 'icon': Icons.person_add, 'title': isArabic ? 'إضافة مكون' : 'Ajouter un formateur'},
      {'value': 'add_video', 'icon': Icons.video_library, 'title': isArabic ? 'إضافة فيديو' : 'Ajouter une vidéo'},
      {'value': 'manage_trainings', 'icon': Icons.edit_note, 'title': isArabic ? 'إدارة التكوينات' : 'Gérer les formations'},
    ];

    for (final item in formationItems) {
      items.add(
        PopupMenuItem<String>(
          value: item['value'] as String,
          child: Row(
            children: [
              Icon(item['icon'] as IconData, color: nafahatGreen, size: 20),
              const SizedBox(width: 12),
              Text(item['title'] as String, style: GoogleFonts.cairo()),
            ],
          ),
        ),
      );
    }

    items.add(const PopupMenuItem<String>(
      enabled: false,
      child: Divider(height: 1, thickness: 1, color: Colors.grey),
    ));

    // ============================================================
    // GROUPE APPARE NCE - COMPLET
    // ============================================================
    final apparenceItems = [
      {'value': 'apparence_landing', 'icon': Icons.home_work_outlined, 'title': isArabic ? 'مظهر الصفحة الرئيسية' : 'Apparence Landing'},
      {'value': 'apparence_hero', 'icon': Icons.slideshow_outlined, 'title': isArabic ? 'مظهر الهيرو' : 'Apparence Hero'},
      {'value': 'apparence_card', 'icon': Icons.palette_outlined, 'title': isArabic ? 'مظهر البطاقات' : 'Apparence Cartes'},
      {'value': 'apparence_formateur', 'icon': Icons.person_outline, 'title': isArabic ? 'مظهر المكونين' : 'Apparence Formateur'},
      {'value': 'apparence_bull', 'icon': Icons.apps_outlined, 'title': isArabic ? 'مظهر الوحدات' : 'Apparence Bull'},
      {'value': 'add_about', 'icon': Icons.info_outline, 'title': isArabic ? 'عن المنصة' : 'À propos'},
    ];

    for (final item in apparenceItems) {
      items.add(
        PopupMenuItem<String>(
          value: item['value'] as String,
          child: Row(
            children: [
              Icon(item['icon'] as IconData, color: nafahatGreen, size: 20),
              const SizedBox(width: 12),
              Text(item['title'] as String, style: GoogleFonts.cairo()),
            ],
          ),
        ),
      );
    }

    items.add(const PopupMenuItem<String>(
      enabled: false,
      child: Divider(height: 1, thickness: 1, color: Colors.grey),
    ));

    // ============================================================
    // GROUPE UTILISATEURS & ADHÉRENTS - COMPLET
    // ============================================================
    final userItems = [
      {'value': 'adherents', 'icon': Icons.people_outline, 'title': isArabic ? 'المنخرطين' : 'Adhérents'},
      {'value': 'users_list', 'icon': Icons.list_alt, 'title': isArabic ? 'قائمة المستعملين' : 'Liste des utilisateurs'},
      {'value': 'creer_user', 'icon': Icons.admin_panel_settings_rounded, 'title': isArabic ? 'إنشاء مستخدم' : 'Créer un utilisateur'},
      {'value': 'inscription_adherent', 'icon': Icons.person_add, 'title': isArabic ? 'تسجيل منخرط' : 'Inscription adhérent'},
      {'value': 'etat_paiement', 'icon': Icons.verified, 'title': isArabic ? 'حالة المدفوعات' : 'État des paiements'},
    ];

    for (final item in userItems) {
      // Vérifier la permission pour créer un utilisateur
      if (item['value'] == 'creer_user' && !_canCreateUser(context)) {
        continue;
      }
      items.add(
        PopupMenuItem<String>(
          value: item['value'] as String,
          child: Row(
            children: [
              Icon(item['icon'] as IconData, color: nafahatGreen, size: 20),
              const SizedBox(width: 12),
              Text(item['title'] as String, style: GoogleFonts.cairo()),
            ],
          ),
        ),
      );
    }

    return items;
  }

  // ============================================================
  // GESTIONNAIRE D'ACTIONS ADMIN - COMPLET
  // ============================================================
  void _handleAdminAction(BuildContext context, String value, bool isArabic) {
    switch (value) {
      case 'go_to_admin':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AdministrationPage()),
        );
        break;
      
      // Formation
      case 'add_training':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddTrainingCardPage()),
        );
        break;
      case 'edit_training':
        _showEditTrainingDialog(context, isArabic);
        break;
      case 'add_duree':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddDureePage()),
        );
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
      case 'manage_trainings':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic ? 'إدارة التكوينات - قريباً' : 'Gestion des formations - Bientôt disponible',
            ),
          ),
        );
        break;
      
      // Apparence
      case 'apparence_landing':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ApparitionLandingPage()),
        );
        break;
      case 'apparence_hero':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ApparenceHero(isArabic: isArabic)),
        );
        break;
      case 'apparence_card':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ApparenceCardPage()),
        );
        break;
      case 'apparence_formateur':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ApparenceCardFormateurPage()),
        );
        break;
      case 'apparence_bull':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ApparitionBullPage()),
        );
        break;
      case 'add_about':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddAboutPage()),
        );
        break;
      
      // Utilisateurs & Adhérents
      case 'adherents':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AdherentsListPage()),
        );
        break;
      case 'users_list':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UsersListPage()),
        );
        break;
      case 'creer_user':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreerUserPage()),
        );
        break;
      case 'inscription_adherent':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const InscriptionAdherentPage()),
        );
        break;
      case 'etat_paiement':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EtatPaiementPage()),
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

      if (userProvider.isAdherent || userProvider.isFormateur) {
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
          const PopupMenuItem<String>(
            enabled: false,
            child: Divider(height: 1, thickness: 1, color: Colors.grey),
          ),
        );
        continue;
      }

      final isDanger = item['isDanger'] ?? false;
      items.add(
        PopupMenuItem<String>(
          value: item['value'] as String,
          child: Row(
            children: [
              Icon(
                item['icon'] as IconData,
                color: isDanger ? Colors.red : nafahatGreen,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                item['title'] as String,
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
              isArabic ? '🔧 إدارة الحساب - قريباً' : '🔧 Gestion de compte - Bientôt disponible',
            ),
            backgroundColor: nafahatGreen,
          ),
        );
        break;
      case 'logout':
        _performLogout(context);
        break;
    }
  }

  // ============================================================
  // BOUTON MOBILE HAMBURGER
  // ============================================================
  Widget _buildMobileMenuButton() {
    return IconButton(
      icon: const Icon(Icons.menu_rounded, color: nafahatGreen, size: 28),
      onPressed: _openDrawer,
      tooltip: 'Menu',
      splashColor: nafahatGreen.withOpacity(0.2),
    );
  }

  // ============================================================
  // DRAWER MOBILE - COMPLET
  // ============================================================
  Widget buildDrawer(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;
    final userProvider = Provider.of<UserProvider>(context);
    final canViewAdmin = _canViewAdmin(context);

    return Drawer(
      backgroundColor: Colors.white.withOpacity(0.95),
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
                  // Menu principal
                  _drawerTile(
                    icon: Icons.home_outlined,
                    title: isArabic ? "الرئيسية" : "Accueil",
                    onTap: () => _closeDrawerAndNavigate(context, const LandingPage()),
                  ),
                  _drawerTile(
                    icon: Icons.school_outlined,
                    title: isArabic ? "الدورات" : "Cycles de Formation",
                    onTap: () => _closeDrawerAndNavigate(context, const AllTrainingsPage()),
                  ),
                  _drawerTile(
                    icon: Icons.video_library_outlined,
                    title: isArabic ? "فيديوهات مميزة" : "Vidéos Favorites",
                    onTap: () => _closeDrawerAndNavigate(context, const AllVideoPage()),
                  ),
                  _drawerTile(
                    icon: Icons.info_outline,
                    title: isArabic ? "عن المنصة" : "À propos",
                    onTap: () => _closeDrawerAndNavigate(context, const AboutPage()),
                  ),
                  _drawerTile(
                    icon: Icons.shopping_cart_outlined,
                    title: isArabic ? "🛒 السلة" : "🛒 Panier",
                    onTap: () {
                      _closeDrawer(context);
                      showDialog(
                        context: context,
                        barrierDismissible: true,
                        barrierColor: Colors.black.withOpacity(0.4),
                        builder: (context) => const CartPopup(),
                      );
                    },
                  ),

                  const Divider(height: 30, thickness: 1.5, color: nafahatGreen),

                  // Section Admin - COMPLETE
                  if (canViewAdmin) _buildDrawerAdminSection(context, isArabic),

                  // Section Compte
                  _buildDrawerAccountSection(context, isArabic, userProvider),

                  // Bouton Langue
                  const SizedBox(height: 10),
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

  // ============================================================
  // EN-TÊTE DU DRAWER
  // ============================================================
  Widget _buildDrawerHeader(bool isArabic, UserProvider userProvider) {
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
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    isArabic ? "نفحات" : "Nafahat",
                    style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: nafahatGold,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Text(
                    isArabic ? "أكاديمية" : "Academy",
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: nafahatGold,
                    ),
                  ),
                ],
              ),
              Text(
                isArabic ? "منصة التدريب والتطوير" : "Plateforme de formation",
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              if (userProvider.isLoggedIn && userProvider.userRole != null)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
        ],
      ),
    );
  }

  // ============================================================
  // SECTION ADMIN DANS LE DRAWER - COMPLETE
  // ============================================================
  Widget _buildDrawerAdminSection(BuildContext context, bool isArabic) {
    final canCreateUser = _canCreateUser(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: nafahatGreen.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: nafahatGreen.withOpacity(0.1)),
      ),
      child: ExpansionTile(
        leading: Icon(
          Icons.admin_panel_settings,
          color: nafahatGreen,
          size: 22,
        ),
        title: Text(
          isArabic ? "⚙️ الإدارة" : "⚙️ Administration",
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: nafahatGreen,
          ),
        ),
        iconColor: nafahatGold,
        collapsedIconColor: nafahatGold,
        tilePadding: const EdgeInsets.symmetric(horizontal: 8),
        childrenPadding: const EdgeInsets.only(left: 16, bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        children: [
          // ============================================================
          // SOUS-GROUPE FORMATION
          // ============================================================
          _buildAdminSubGroup(
            context: context,
            isArabic: isArabic,
            icon: Icons.school_outlined,
            title: isArabic ? 'التكوين' : 'Formation',
            items: [
              {'value': 'add_training', 'icon': Icons.add_circle_outline, 'title': isArabic ? 'إضافة تكوين' : 'Ajouter une formation'},
              {'value': 'edit_training', 'icon': Icons.edit, 'title': isArabic ? 'تعديل تكوين' : 'Modifier une formation'},
              {'value': 'add_duree', 'icon': Icons.access_time, 'title': isArabic ? 'إضافة مدة' : 'Ajouter une durée'},
              {'value': 'add_categorie', 'icon': Icons.category, 'title': isArabic ? 'إضافة تصنيف' : 'Ajouter une catégorie'},
              {'value': 'edit_categorie', 'icon': Icons.edit, 'title': isArabic ? 'تعديل تصنيف' : 'Modifier une catégorie'},
              {'value': 'add_type_formation', 'icon': Icons.label_outline, 'title': isArabic ? 'إضافة نوع تكوين' : 'Ajouter un type de formation'},
              {'value': 'edit_type_formation', 'icon': Icons.edit_note, 'title': isArabic ? 'إدارة أنواع التكوين' : 'Gérer les types de formation'},
              {'value': 'add_formateur', 'icon': Icons.person_add, 'title': isArabic ? 'إضافة مكون' : 'Ajouter un formateur'},
              {'value': 'add_video', 'icon': Icons.video_library, 'title': isArabic ? 'إضافة فيديو' : 'Ajouter une vidéo'},
              {'value': 'manage_trainings', 'icon': Icons.edit_note, 'title': isArabic ? 'إدارة التكوينات' : 'Gérer les formations'},
            ],
          ),
          
          // ============================================================
          // SOUS-GROUPE APPARE NCE - COMPLET
          // ============================================================
          _buildAdminSubGroup(
            context: context,
            isArabic: isArabic,
            icon: Icons.palette_outlined,
            title: isArabic ? 'المظهر' : 'Apparence',
            items: [
              {'value': 'apparence_landing', 'icon': Icons.home_work_outlined, 'title': isArabic ? 'مظهر الصفحة الرئيسية' : 'Apparence Landing'},
              {'value': 'apparence_hero', 'icon': Icons.slideshow_outlined, 'title': isArabic ? 'مظهر الهيرو' : 'Apparence Hero'},
              {'value': 'apparence_card', 'icon': Icons.palette_outlined, 'title': isArabic ? 'مظهر البطاقات' : 'Apparence Cartes'},
              {'value': 'apparence_formateur', 'icon': Icons.person_outline, 'title': isArabic ? 'مظهر المكونين' : 'Apparence Formateur'},
              {'value': 'apparence_bull', 'icon': Icons.apps_outlined, 'title': isArabic ? 'مظهر الوحدات' : 'Apparence Bull'},
              {'value': 'add_about', 'icon': Icons.info_outline, 'title': isArabic ? 'عن المنصة' : 'À propos'},
            ],
          ),
          
          // ============================================================
          // SOUS-GROUPE UTILISATEURS & ADHÉRENTS - COMPLET
          // ============================================================
          _buildAdminSubGroup(
            context: context,
            isArabic: isArabic,
            icon: Icons.people_outline,
            title: isArabic ? 'المستخدمون والمنخرطين' : 'Utilisateurs & Adhérents',
            items: [
              {'value': 'adherents', 'icon': Icons.people_outline, 'title': isArabic ? 'المنخرطين' : 'Adhérents'},
              {'value': 'users_list', 'icon': Icons.list_alt, 'title': isArabic ? 'قائمة المستعملين' : 'Liste des utilisateurs'},
              if (canCreateUser)
                {'value': 'creer_user', 'icon': Icons.admin_panel_settings_rounded, 'title': isArabic ? 'إنشاء مستخدم' : 'Créer un utilisateur'},
              {'value': 'inscription_adherent', 'icon': Icons.person_add, 'title': isArabic ? 'تسجيل منخرط' : 'Inscription adhérent'},
              {'value': 'etat_paiement', 'icon': Icons.verified, 'title': isArabic ? 'حالة المدفوعات' : 'État des paiements'},
            ],
          ),
          
          // Lien vers l'administration complète
          _drawerTile(
            icon: Icons.dashboard_outlined,
            title: isArabic ? 'لوحة الإدارة الكاملة' : 'Administration complète',
            padding: const EdgeInsets.only(left: 32, right: 8),
            onTap: () {
              _closeDrawer(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdministrationPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SOUS-GROUPE ADMIN
  // ============================================================
  Widget _buildAdminSubGroup({
    required BuildContext context,
    required bool isArabic,
    required IconData icon,
    required String title,
    required List<Map<String, dynamic>> items,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 16, top: 2, bottom: 2),
      decoration: BoxDecoration(
        color: nafahatGreen.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: nafahatGreen, size: 18),
        title: Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: nafahatGreen,
          ),
        ),
        iconColor: nafahatGold,
        collapsedIconColor: nafahatGold,
        tilePadding: const EdgeInsets.symmetric(horizontal: 8),
        childrenPadding: const EdgeInsets.only(left: 16, bottom: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        children: items.map((item) {
          return _drawerTile(
            icon: item['icon'] as IconData,
            title: item['title'] as String,
            padding: const EdgeInsets.only(left: 32, right: 8),
            onTap: () {
              _closeDrawer(context);
              _handleAdminAction(context, item['value'] as String, isArabic);
            },
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // SECTION COMPTE DANS LE DRAWER
  // ============================================================
  Widget _buildDrawerAccountSection(
    BuildContext context,
    bool isArabic,
    UserProvider userProvider,
  ) {
    final bool isLoggedIn = userProvider.isLoggedIn;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: nafahatGreen.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: nafahatGreen.withOpacity(0.1)),
      ),
      child: ExpansionTile(
        leading: Icon(
          isLoggedIn ? Icons.person_rounded : Icons.person_outline_rounded,
          color: nafahatGreen,
          size: 22,
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
        iconColor: nafahatGold,
        collapsedIconColor: nafahatGold,
        tilePadding: const EdgeInsets.symmetric(horizontal: 8),
        childrenPadding: const EdgeInsets.only(left: 16, bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        children: _getAccountMenuItems(isArabic, userProvider)
            .where((item) => !item.containsKey('isDivider'))
            .map((item) {
              final isDanger = item['isDanger'] ?? false;
              return _drawerTile(
                icon: item['icon'] as IconData,
                title: item['title'] as String,
                color: isDanger ? Colors.red : null,
                padding: const EdgeInsets.only(left: 32, right: 8),
                onTap: () {
                  _closeDrawer(context);
                  _handleAccountAction(context, item['value'] as String, isArabic);
                },
              );
            }).toList(),
      ),
    );
  }

  // ============================================================
  // WIDGET TILE DU DRAWER
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
      leading: Icon(icon, color: color ?? const Color(0xff7c6e68), size: 20),
      title: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      tileColor: Colors.transparent,
      hoverColor: nafahatGreen.withOpacity(0.05),
      contentPadding: padding,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
      dense: true,
    );
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
                  isArabic ? 'اختر تكويناً من القائمة أدناه' : 'Sélectionnez une formation dans la liste ci-dessous',
                  style: GoogleFonts.cairo(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
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
                    if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                      return Text(
                        isArabic ? 'لا توجد تكوينات متاحة' : 'Aucune formation disponible',
                        style: GoogleFonts.cairo(color: Colors.grey.shade600),
                      );
                    }
                    final formations = snapshot.data!;
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
                          final title = isArabic
                              ? formation['titre_ar'] ?? formation['titre_fr'] ?? 'Sans titre'
                              : formation['titre_fr'] ?? formation['titre_ar'] ?? 'Sans titre';
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
                              title as String,
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
                            trailing: Icon(Icons.chevron_right, color: nafahatGreen),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditFormationPage(
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
      debugPrint('❌ Erreur chargement formations: $e');
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
                  isArabic ? 'اختر تصنيفاً من القائمة أدناه' : 'Sélectionnez une catégorie dans la liste ci-dessous',
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
                    if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                      return Text(
                        isArabic ? 'لا توجد تصنيفات متاحة' : 'Aucune catégorie disponible',
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
                          final name = isArabic
                              ? cat['categorie_ar'] ?? cat['categorie_fr']
                              : cat['categorie_fr'] ?? cat['categorie_ar'];
                          final parentName = cat['parent_fr'] ?? cat['parent_ar'];
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
                                  ? (isArabic ? 'الأب: $parentName' : 'Parent: $parentName')
                                  : (isArabic ? 'تصنيف رئيسي' : 'Catégorie principale'),
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            trailing: Icon(Icons.chevron_right, color: nafahatGreen),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditCategoriePage(
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
      debugPrint('❌ Erreur chargement catégories: $e');
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
                  isArabic ? 'اختر نوع تكوين من القائمة أدناه' : 'Sélectionnez un type de formation dans la liste ci-dessous',
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
                    if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                      return Text(
                        isArabic ? 'لا توجد أنواع تكوين متاحة' : 'Aucun type de formation disponible',
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
                          final chapters = [
                            type['ch1'],
                            type['ch2'],
                            type['ch3'],
                            type['ch4'],
                            type['ch5'],
                            type['ch6'],
                          ].where((ch) => ch != null && ch.toString().isNotEmpty).length;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xffd57653).withOpacity(0.1),
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
                            trailing: Icon(Icons.chevron_right, color: nafahatGreen),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddTypeFormationPage(
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
      debugPrint('❌ Erreur chargement types de formation: $e');
      return [];
    }
  }
}