// lib/widgets/navbar.dart
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:nafahat/pages/adminisration/add_training_card.dart';
import 'package:nafahat/pages/adminisration/administration_page.dart';
import 'package:nafahat/pages/adminisration/edit_formation.dart';
import 'package:nafahat/pages/adminisration/add_categorie.dart';
import 'package:nafahat/pages/adminisration/edit_categorie.dart';
import 'package:nafahat/pages/adminisration/add_formateur.dart';
import 'package:nafahat/pages/adminisration/add_video_fav_page.dart';
import 'package:nafahat/pages/users/auth_page.dart';
import 'package:nafahat/pages/users/profile_dashboard_page.dart';
import 'package:nafahat/pages/users/edit_profile_page.dart';
import 'package:nafahat/src/features/landing/presentation/landing_page.dart';
import 'package:nafahat/services/training_service.dart';
import 'package:nafahat/providers/language_provider.dart';

class Navbar extends StatelessWidget {
  final bool isArabic;
  final bool isMobile;
  final VoidCallback onLanguageToggle;
  final GlobalKey<ScaffoldState> scaffoldKey;

  final bool isUserLoggedIn = true; // ✅ Mis à true pour tester
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
              Row(
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
              ),

              // ---- Menu Mobile (Drawer) ----
              if (isMobile)
                IconButton(
                  icon: const Icon(
                    Icons.menu_rounded,
                    color: nafahatGreen,
                    size: 30,
                  ),
                  onPressed: () => scaffoldKey.currentState?.openDrawer(),
                )
              else
                // ---- Menu Desktop ----
                Row(
                  children: [
                    _navLink(
                      context: context,
                      title: isArabic ? "الرئيسية" : "Accueil",
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LandingPage(),
                          ),
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
                      icon: const Icon(
                        Icons.language,
                        color: nafahatGreen,
                        size: 22,
                      ),
                      onPressed: onLanguageToggle,
                      tooltip: isArabic ? "Français" : "العربية",
                    ),
                    const SizedBox(width: 15),

                    // ---- MENU ADMINISTRATION ----
                    if (isAdmin)
                      PopupMenuButton<String>(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
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
                        onSelected: (value) {
                          switch (value) {
                            case 'go_to_admin':
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const AdministrationPage(),
                                ),
                              );
                              break;
                            case 'add_training':
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const AddTrainingCardPage(),
                                ),
                              );
                              break;
                            case 'edit_training':
                              _showEditTrainingDialog(context);
                              break;
                            case 'add_categorie':
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const AddCategoriePage(),
                                ),
                              );
                              break;
                            case 'edit_categorie':
                              _showEditCategorieDialog(context);
                              break;
                            case 'add_formateur':
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const AddFormateurPage(),
                                ),
                              );
                              break;
                            case 'add_video':
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddVideoFavPage(),
                                ),
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
                        },
                        itemBuilder:
                            (context) => [
                              // Dashboard
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
                                      child: const Icon(
                                        Icons.dashboard_outlined,
                                        color: nafahatGreen,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isArabic
                                                ? "🖥️ لوحة الإدارة الكاملة"
                                                : "🖥️ Administration complète",
                                            style: GoogleFonts.cairo(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: nafahatGreen,
                                            ),
                                          ),
                                          Text(
                                            isArabic
                                                ? "Accéder à toutes les fonctionnalités"
                                                : "Accéder à toutes les fonctionnalités",
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
                              const PopupMenuDivider(),

                              // Formations
                              PopupMenuItem<String>(
                                value: 'add_training',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.add_circle_outline,
                                      color: nafahatGreen,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      isArabic
                                          ? "إضافة تكوين"
                                          : "Ajouter une formation",
                                      style: GoogleFonts.cairo(),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'edit_training',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.edit,
                                      color: nafahatGreen,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      isArabic
                                          ? "تعديل تكوين"
                                          : "Modifier une formation",
                                      style: GoogleFonts.cairo(),
                                    ),
                                  ],
                                ),
                              ),

                              // Catégories
                              PopupMenuItem<String>(
                                value: 'add_categorie',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.category,
                                      color: nafahatGreen,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      isArabic
                                          ? "إضافة تصنيف"
                                          : "Ajouter une catégorie",
                                      style: GoogleFonts.cairo(),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'edit_categorie',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.edit,
                                      color: nafahatGreen,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      isArabic
                                          ? "تعديل تصنيف"
                                          : "Modifier une catégorie",
                                      style: GoogleFonts.cairo(),
                                    ),
                                  ],
                                ),
                              ),

                              // Formateurs
                              PopupMenuItem<String>(
                                value: 'add_formateur',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.person_add,
                                      color: nafahatGreen,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      isArabic
                                          ? "إضافة مكون"
                                          : "Ajouter un formateur",
                                      style: GoogleFonts.cairo(),
                                    ),
                                  ],
                                ),
                              ),

                              // Vidéos
                              PopupMenuItem<String>(
                                value: 'add_video',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.video_library,
                                      color: nafahatGreen,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      isArabic
                                          ? "إضافة فيديو"
                                          : "Ajouter une vidéo",
                                      style: GoogleFonts.cairo(),
                                    ),
                                  ],
                                ),
                              ),

                              const PopupMenuDivider(),

                              // Gestion des formations
                              PopupMenuItem<String>(
                                value: 'manage_trainings',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.edit_note,
                                      color: nafahatGreen,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      isArabic
                                          ? "إدارة التكوينات"
                                          : "Gérer les formations",
                                      style: GoogleFonts.cairo(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                      ),

                    const SizedBox(width: 15),

                    // ---- MENU COMPTE ----
                    PopupMenuButton<String>(
                      child: CircleAvatar(
                        backgroundColor: nafahatGreen.withOpacity(0.1),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          color: nafahatGreen,
                        ),
                      ),
                      tooltip: isArabic ? "حسابي" : "Mon compte",
                      offset: const Offset(0, 50),
                      onSelected: (value) {
                        switch (value) {
                          case 'profile':
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfilePage(),
                              ),
                            );
                            break;
                          case 'dashboard':
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const ProfileDashboardPage(),
                              ),
                            );
                            break;
                          case 'logout':
                            // TODO: Déconnexion
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
                            break;
                        }
                      },
                      itemBuilder:
                          (context) => [
                            // Mon profil
                            PopupMenuItem<String>(
                              value: 'profile',
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.person_outline,
                                    color: nafahatGreen,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    isArabic ? "ملفي الشخصي" : "Mon profil",
                                    style: GoogleFonts.cairo(),
                                  ),
                                ],
                              ),
                            ),
                            // Tableau de bord
                            PopupMenuItem<String>(
                              value: 'dashboard',
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.dashboard_outlined,
                                    color: nafahatGreen,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    isArabic
                                        ? "لوحة التحكم"
                                        : "Tableau de bord",
                                    style: GoogleFonts.cairo(),
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            // Déconnexion
                            PopupMenuItem<String>(
                              value: 'logout',
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.logout_rounded,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    isArabic ? "تسجيل الخروج" : "Déconnexion",
                                    style: GoogleFonts.cairo(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // WIDGETS PRIVÉS
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
