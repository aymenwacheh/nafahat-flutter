// lib/pages/adminisration/administration_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafahat/pages/adminisration/add_training_card.dart';
import 'package:nafahat/pages/adminisration/add_categorie.dart';
import 'package:nafahat/pages/adminisration/edit_categorie.dart';
import 'package:nafahat/pages/adminisration/add_formateur.dart';
import 'package:nafahat/pages/adminisration/add_video_fav_page.dart';
import 'package:nafahat/pages/adminisration/edit_formation.dart';
import 'package:nafahat/pages/users/edit_profile_page.dart';
import 'package:nafahat/services/training_service.dart';
import 'package:nafahat/services/video_service.dart';
import 'package:nafahat/services/adherent_service.dart';
import 'package:nafahat/models/training_model.dart';
import 'package:nafahat/models/video_model.dart';
import 'package:nafahat/models/adherent.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AdministrationPage extends StatefulWidget {
  const AdministrationPage({super.key});

  @override
  State<AdministrationPage> createState() => _AdministrationPageState();
}

class _AdministrationPageState extends State<AdministrationPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const FormationsManagementPage(),
    const CategoriesManagementPage(),
    const FormateursManagementPage(),
    const VideosManagementPage(),
    const AdherentsManagementPage(), // ✅ Nouvelle page Adhérents
  ];

  final List<String> _titles = [
    'Tableau de bord',
    'Formations',
    'Catégories',
    'Formateurs',
    'Vidéos',
    'Adhérents',
  ];

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.dashboard_outlined, 'title': 'Tableau de bord', 'page': 0},
    {'icon': Icons.school_outlined, 'title': 'Formations', 'page': 1},
    {'icon': Icons.category_outlined, 'title': 'Catégories', 'page': 2},
    {'icon': Icons.person_outline, 'title': 'Formateurs', 'page': 3},
    {'icon': Icons.video_library_outlined, 'title': 'Vidéos', 'page': 4},
    {
      'icon': Icons.people_outline,
      'title': 'Adhérents',
      'page': 5,
      'badge': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            _titles[_selectedIndex],
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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
        ),
        drawer: _buildDrawer(isMobile),
        body: _pages[_selectedIndex],
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xfffcfbfa),
      body: Row(
        children: [
          _buildSideMenu(isMobile, isTablet),
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
  // SIDE MENU
  // ============================================================
  Widget _buildSideMenu(bool isMobile, bool isTablet) {
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
          // ---- Logo ----
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
                        'Administration',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // ---- Menu Items ----
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                final isSelected = _selectedIndex == item['page'];
                final hasBadge = item['badge'] ?? false;
                return _buildMenuItem(
                  icon: item['icon'],
                  title: item['title'],
                  isSelected: isSelected,
                  isCollapsed: isCollapsed,
                  hasBadge: hasBadge,
                  onTap: () {
                    setState(() {
                      _selectedIndex = item['page'];
                    });
                  },
                );
              },
            ),
          ),

          // ---- Footer (Déconnexion) ----
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin',
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
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required bool isCollapsed,
    required VoidCallback onTap,
    bool hasBadge = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: EdgeInsets.symmetric(
          horizontal: isCollapsed ? 0 : 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? const Color(0xffd57653).withOpacity(0.2)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border:
              isSelected
                  ? Border.all(
                    color: const Color(0xffd57653).withOpacity(0.3),
                    width: 1,
                  )
                  : null,
        ),
        child: Row(
          mainAxisAlignment:
              isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Stack(
              children: [
                Icon(
                  icon,
                  color: isSelected ? const Color(0xffd57653) : Colors.white70,
                  size: 24,
                ),
                if (hasBadge && !isCollapsed)
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '!',
                        style: GoogleFonts.poppins(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (!isCollapsed) ...[
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                ),
              ),
              if (hasBadge)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Nouveau',
                    style: GoogleFonts.poppins(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DRAWER (Mobile)
  // ============================================================
  Widget _buildDrawer(bool isMobile) {
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
            child: Column(
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
                  'Administration',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                final isSelected = _selectedIndex == item['page'];
                final hasBadge = item['badge'] ?? false;
                return ListTile(
                  leading: Stack(
                    children: [
                      Icon(
                        item['icon'],
                        color:
                            isSelected
                                ? const Color(0xffd57653)
                                : Colors.white70,
                      ),
                      if (hasBadge)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '!',
                              style: GoogleFonts.poppins(
                                fontSize: 6,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    item['title'],
                    style: GoogleFonts.poppins(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  trailing:
                      hasBadge
                          ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Nouveau',
                              style: GoogleFonts.poppins(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          )
                          : null,
                  selected: isSelected,
                  selectedTileColor: const Color(0xffd57653).withOpacity(0.2),
                  onTap: () {
                    setState(() {
                      _selectedIndex = item['page'];
                    });
                    Navigator.pop(context);
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
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.white70),
              title: Text(
                'Déconnexion',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
              onTap: () {
                // TODO: Déconnexion
              },
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
          Text(
            _titles[_selectedIndex],
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xff2c221e),
            ),
          ),
          Row(
            children: [
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
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bienvenue dans le tableau de bord',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: const Color(0xff2c221e),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gérez vos formations, catégories, formateurs, vidéos et adhérents',
            style: GoogleFonts.poppins(color: const Color(0xff7c6e68)),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _buildStatCard(
                icon: Icons.school,
                title: 'Formations',
                count: '12',
                color: const Color(0xffd57653),
              ),
              _buildStatCard(
                icon: Icons.category,
                title: 'Catégories',
                count: '5',
                color: const Color(0xff0D443E),
              ),
              _buildStatCard(
                icon: Icons.person,
                title: 'Formateurs',
                count: '8',
                color: Colors.blue[700]!,
              ),
              _buildStatCard(
                icon: Icons.video_library,
                title: 'Vidéos',
                count: '6',
                color: Colors.purple[700]!,
              ),
              _buildStatCard(
                icon: Icons.people,
                title: 'Adhérents',
                count: '0',
                color: Colors.green[700]!,
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
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 16),
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

  void _showEditTrainingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Modifier une formation',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sélectionnez une formation dans la liste ci-dessous',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_formations.isEmpty)
                  Text(
                    'Aucune formation disponible',
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
                'Annuler',
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
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gestion des formations',
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
                    label: const Text('Ajouter'),
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
                    label: const Text('Modifier'),
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
                            'Aucune formation trouvée',
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
                                  : 'Non défini';
                          final dureeDisplay =
                              formation.typeDuree.isNotEmpty
                                  ? formation.typeDuree
                                  : 'Non définie';
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
                              'Type: $typeDisplay | Durée: $dureeDisplay | Prix: ${formation.price} DH',
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
                                    // TODO: Implémenter la suppression
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gestion des catégories',
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
                label: const Text('Ajouter'),
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
                            'Aucune catégorie trouvée',
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
                              cat['categorie_fr'] ?? 'Sans nom',
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gestion des formateurs',
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
                label: const Text('Ajouter'),
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
                            'Aucun formateur trouvé',
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
                              f['nom_prenom_fr'] ?? 'Sans nom',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              'ID: ${f['id']}',
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
                                    // TODO: Implémenter modification formateur
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gestion des vidéos',
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
                label: const Text('Ajouter'),
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
                            'Aucune vidéo trouvée',
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
                              video.titleFr.isNotEmpty
                                  ? video.titleFr
                                  : video.titleAr,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              'ID YouTube: ${video.videoId}',
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
                                    // TODO: Implémenter modification vidéo
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
// ADHERENTS MANAGEMENT PAGE (NOUVEAU)
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
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Modifier un adhérent',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sélectionnez un adhérent dans la liste ci-dessous',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_adherents.isEmpty)
                  Text(
                    'Aucun adhérent disponible',
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
                'Annuler',
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
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gestion des adhérents',
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
                      // TODO: Rediriger vers InscriptionAdherentPage
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Redirection vers inscription...'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter'),
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
                    label: const Text('Modifier'),
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
                            'Aucun adhérent trouvé',
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
