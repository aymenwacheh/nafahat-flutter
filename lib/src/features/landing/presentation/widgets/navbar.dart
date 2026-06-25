// lib/widgets/navbar.dart
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:nafahat/pages/adminisration/add_training_card.dart';
import 'package:nafahat/pages/adminisration/administration_page.dart';
import 'package:nafahat/pages/adminisration/edit_formation.dart';
import 'package:nafahat/pages/adminisration/add_categorie.dart';
import 'package:nafahat/pages/adminisration/edit_categorie.dart';
import 'package:nafahat/pages/adminisration/add_formateur.dart';
import 'package:nafahat/pages/adminisration/add_video_fav_page.dart';
import 'package:nafahat/pages/users/auth_page.dart';
import 'package:nafahat/pages/users/profile_dashboard_page.dart';
import 'package:nafahat/src/features/landing/presentation/landing_page.dart';
import 'package:nafahat/services/training_service.dart';

class Navbar extends StatelessWidget {
  final bool isArabic;
  final bool isMobile;
  final VoidCallback onLanguageToggle;
  final GlobalKey<ScaffoldState> scaffoldKey;

  final bool isUserLoggedIn = false;
  final bool isAdmin = true;

  static const Color nafahatGreen = Color(0xff0D443E);

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
              // Logo
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
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: nafahatGreen,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),

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

                    // Bouton langue
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

                    // ✅ MENU ADMINISTRATION
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
                                style: const TextStyle(
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
                          if (value == 'go_to_admin') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const AdministrationPage(),
                              ),
                            );
                          } else if (value == 'add_training') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const AddTrainingCardPage(),
                              ),
                            );
                          } else if (value == 'edit_training') {
                            _showEditTrainingDialog(context);
                          } else if (value == 'add_categorie') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddCategoriePage(),
                              ),
                            );
                          } else if (value == 'edit_categorie') {
                            _showEditCategorieDialog(context);
                          } else if (value == 'add_formateur') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddFormateurPage(),
                              ),
                            );
                          } else if (value == 'add_video') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddVideoFavPage(),
                              ),
                            );
                          } else if (value == 'manage_trainings') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Gestion des formations - Bientôt disponible',
                                ),
                              ),
                            );
                          }
                        },
                        itemBuilder:
                            (context) => [
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
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: nafahatGreen,
                                            ),
                                          ),
                                          Text(
                                            isArabic
                                                ? "Accéder à toutes les fonctionnalités"
                                                : "Accéder à toutes les fonctionnalités",
                                            style: TextStyle(
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
                                    ),
                                  ],
                                ),
                              ),
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
                                    ),
                                  ],
                                ),
                              ),
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
                                    ),
                                  ],
                                ),
                              ),
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
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
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
                                    ),
                                  ],
                                ),
                              ),
                            ],
                      ),

                    const SizedBox(width: 15),

                    // Authentification
                    isUserLoggedIn
                        ? InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const ProfileDashboardPage(),
                              ),
                            );
                          },
                          child: CircleAvatar(
                            backgroundColor: nafahatGreen.withOpacity(0.1),
                            child: const Icon(
                              Icons.person_outline_rounded,
                              color: nafahatGreen,
                            ),
                          ),
                        )
                        : ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AuthPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: nafahatGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            isArabic ? "حسابي" : "S'inscrire",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                  ],
                ),
            ],
          ),
        ),
      ),
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
            style: const TextStyle(
              color: Color(0xff2c221e),
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  void _showEditTrainingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            isArabic ? 'Modifier une formation' : 'Modifier une formation',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isArabic
                      ? 'Entrez l\'ID de la formation à modifier'
                      : 'Entrez l\'ID de la formation à modifier',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    hintText:
                        isArabic ? 'ID de la formation' : 'ID de la formation',
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
                            ? 'Erreur de chargement des formations'
                            : 'Erreur de chargement des formations',
                        style: TextStyle(color: Colors.red.shade400),
                      );
                    }
                    final formations = snapshot.data!;
                    if (formations.isEmpty) {
                      return Text(
                        isArabic
                            ? 'Aucune formation disponible'
                            : 'Aucune formation disponible',
                        style: TextStyle(color: Colors.grey.shade600),
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
                                style: TextStyle(
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
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              'ID: ${formation['id']}',
                              style: TextStyle(
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
                style: TextStyle(color: Colors.grey.shade600),
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

  // ✅ Dialogue pour modifier une catégorie
  void _showEditCategorieDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            isArabic ? 'Modifier une catégorie' : 'Modifier une catégorie',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isArabic
                      ? 'Sélectionnez une catégorie dans la liste ci-dessous'
                      : 'Sélectionnez une catégorie dans la liste ci-dessous',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
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
                            ? 'Aucune catégorie disponible'
                            : 'Aucune catégorie disponible',
                        style: TextStyle(color: Colors.grey.shade600),
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
                                style: TextStyle(
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
                              style: GoogleFonts.poppins(
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
                              style: TextStyle(
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
                style: TextStyle(color: Colors.grey.shade600),
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
