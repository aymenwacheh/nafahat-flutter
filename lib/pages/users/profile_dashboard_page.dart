// lib/pages/users/profile_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:nafahat/pages/widgets/mobile_bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafahat/pages/users/edit_profile_page.dart';
import 'package:nafahat/pages/widgets/navbar.dart' show Navbar;
import 'package:nafahat/providers/language_provider.dart';
import 'package:nafahat/providers/user_provider.dart';
import 'package:nafahat/pages/widgets/chatbot/chatbot_wrapper.dart';
import 'package:nafahat/models/training_model.dart';
import 'package:nafahat/pages/widgets/training_card_section.dart';
import 'package:nafahat/services/payment_service.dart';
import 'package:nafahat/services/training_service.dart';

class ProfileDashboardPage extends StatefulWidget {
  const ProfileDashboardPage({super.key});

  @override
  State<ProfileDashboardPage> createState() => _ProfileDashboardPageState();
}

class _ProfileDashboardPageState extends State<ProfileDashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _showEnCours = false;
  bool _showTerminees = false;

  List<TrainingModel> _formationsEnCours = [];
  List<TrainingModel> _formationsTerminees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserFormations();
  }

  Future<void> _loadUserFormations() async {
    setState(() => _isLoading = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.isLoggedIn && userProvider.userId != null) {
        final userId = userProvider.userId!.toString();

        final payments = await PaymentService.getUserPayments(userId);
        final validPayments =
            payments.where((p) => p['statut_paiement'] == 'valide').toList();

        List<TrainingModel> formations = [];
        for (var payment in validPayments) {
          final formationId = payment['formation_id'];
          if (formationId != null) {
            try {
              final training = await TrainingService.getTraining(
                formationId.toString(),
              );
              if (training != null) {
                formations.add(training);
              }
            } catch (e) {
              print('❌ Erreur chargement formation $formationId: $e');
            }
          }
        }

        final now = DateTime.now();
        _formationsEnCours =
            formations.where((f) {
              if (f.dateFin.isEmpty) return true;
              try {
                final dateFin = DateTime.parse(f.dateFin);
                return dateFin.isAfter(now);
              } catch (_) {
                return true;
              }
            }).toList();

        _formationsTerminees =
            formations.where((f) {
              if (f.dateFin.isEmpty) return false;
              try {
                final dateFin = DateTime.parse(f.dateFin);
                return dateFin.isBefore(now);
              } catch (_) {
                return false;
              }
            }).toList();
      }
    } catch (e) {
      print('❌ Erreur chargement formations: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;
    final userProvider = Provider.of<UserProvider>(context);
    final isMobile = MediaQuery.of(context).size.width < 850;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: ChatbotWrapper(
        apiBaseUrl: 'http://localhost:3000',
        langue: isArabic ? 'ar' : 'fr',
        primaryColor: AppColors.primary,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.surface,
          drawer: Navbar(
            isMobile: isMobile,
            scaffoldKey: _scaffoldKey,
          ).buildDrawer(context),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                // Contenu principal
                Expanded(
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(top: 100),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildProfileSection(isArabic, userProvider),
                              const SizedBox(height: 32),

                              _buildSectionHeader(
                                isArabic: isArabic,
                                titleFr: 'Mes Formations en Cours',
                                titleAr: 'تكويناتي الجارية',
                                isExpanded: _showEnCours,
                                onToggle: () {
                                  setState(() {
                                    _showEnCours = !_showEnCours;
                                    _showTerminees = false;
                                  });
                                },
                              ),
                              if (_showEnCours) ...[
                                const SizedBox(height: 16),
                                _buildFormationsGrid(
                                  _formationsEnCours,
                                  isArabic,
                                  isMobile,
                                ),
                              ],
                              const SizedBox(height: 24),

                              _buildSectionHeader(
                                isArabic: isArabic,
                                titleFr: 'Mes Formations Terminées',
                                titleAr: 'تكويناتي المنتهية',
                                isExpanded: _showTerminees,
                                onToggle: () {
                                  setState(() {
                                    _showTerminees = !_showTerminees;
                                    _showEnCours = false;
                                  });
                                },
                              ),
                              if (_showTerminees) ...[
                                const SizedBox(height: 16),
                                _buildFormationsGrid(
                                  _formationsTerminees,
                                  isArabic,
                                  isMobile,
                                ),
                              ],
                              const SizedBox(height: 60),
                            ],
                          ),
                        ),
                      ),

                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 85,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Navbar(
                            isMobile: isMobile,
                            scaffoldKey: _scaffoldKey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // ============================================================
                // ✅ MOBILE BOTTOM NAVIGATION
                // ============================================================
                //const MobileBottomNav(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(bool isArabic, UserProvider userProvider) {
    final userName =
        userProvider.isLoggedIn ? userProvider.displayName : 'Utilisateur';
    final userEmail =
        userProvider.isLoggedIn
            ? (userProvider.userEmail ?? 'email@exemple.com')
            : 'email@exemple.com';
    final userRole =
        userProvider.isLoggedIn && userProvider.userRole != null
            ? userProvider.userRole!.libelle
            : '';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              userProvider.isLoggedIn ? userProvider.initials : 'U',
              style: GoogleFonts.cairo(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        isArabic ? "مرحباً، $userName" : "Bienvenue, $userName",
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (userRole.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          userRole,
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
                if (userProvider.isLoggedIn &&
                    userProvider.userWhatsapp != null)
                  Text(
                    userProvider.userWhatsapp!,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppColors.textMuted.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.edit_note_rounded,
              color: AppColors.primary,
              size: 28,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfilePage(),
                ),
              );
            },
            tooltip: isArabic ? "تعديل الملف الشخصي" : "Modifier le profil",
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required bool isArabic,
    required String titleFr,
    required String titleAr,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color:
              isExpanded ? AppColors.primary.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpanded ? AppColors.primary : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isArabic ? titleAr : titleFr,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            if (_isLoading)
              const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormationsGrid(
    List<TrainingModel> formations,
    bool isArabic,
    bool isMobile,
  ) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (formations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.school_outlined, size: 60, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                isArabic
                    ? 'لا توجد تكوينات في هذه الفئة'
                    : 'Aucune formation dans cette catégorie',
                style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isTablet = screenWidth >= 600 && screenWidth < 1200;

        int crossAxisCount;
        if (isMobile) {
          crossAxisCount = 1;
        } else if (isTablet) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 3;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: isMobile ? 0.85 : 0.75,
            crossAxisSpacing: isMobile ? 0 : 16,
            mainAxisSpacing: isMobile ? 12 : 16,
          ),
          itemCount: formations.length,
          itemBuilder: (context, index) {
            return TrainingCard(
              training: formations[index],
              isArabic: isArabic,
              onRefresh: _loadUserFormations,
              isMobile: isMobile,
            );
          },
        );
      },
    );
  }
}

class AppColors {
  static const Color surface = Color(0xfffcfbfa);
  static const Color primary = Color(0xffd57653);
  static const Color textDark = Color(0xff2c221e);
  static const Color textMuted = Color(0xff7c6e68);
  static const Color primaryDark = Color(0xff994a2b);
}