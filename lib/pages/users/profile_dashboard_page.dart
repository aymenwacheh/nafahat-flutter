// lib/pages/users/profile_dashboard_page.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafahat/pages/users/edit_profile_page.dart';
import '../landing/landing_page.dart';
import '../landing/widgets/navbar.dart' show Navbar;
import '../../providers/language_provider.dart';
import '../../providers/user_provider.dart';
import '../landing/widgets/chatbot/chatbot_wrapper.dart';

class ProfileDashboardPage extends StatefulWidget {
  const ProfileDashboardPage({super.key});

  @override
  State<ProfileDashboardPage> createState() => _ProfileDashboardPageState();
}

class _ProfileDashboardPageState extends State<ProfileDashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Liste des cycles payés par cet utilisateur
  final List<Map<String, String>> paidCycles = [
    {
      "titleFr": "Excellence Executive MBA",
      "titleAr": "الماجستير التنفيذي المتميز",
      "progress": "0.65",
      "nextLessonFr": "Module 4 : Leadership Stratégique",
      "nextLessonAr": "الوحدة ٤: القيادة الاستراتيجية",
    },
    {
      "titleFr": "Tech & Intelligence Artificielle",
      "titleAr": "التكنولوجيا والذكاء الاصطناعي",
      "progress": "0.20",
      "nextLessonFr": "Module 1 : Introduction au Machine Learning",
      "nextLessonAr": "الوحدة ١: مقدمة في تعلم الآلة",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;
    final userProvider = Provider.of<UserProvider>(context);
    bool isMobile = MediaQuery.of(context).size.width < 850;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: ChatbotWrapper(
        apiBaseUrl: 'http://localhost:3000',
        langue: isArabic ? 'ar' : 'fr',
        primaryColor: AppColors.primary,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.surface,
          body: SafeArea(
            top: false,
            child: Stack(
              children: [
                // Contenu principal du Dashboard
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 120),
                        // 1. BLOC PROFIL / BIENVENUE
                        _buildHeaderSection(isArabic, isMobile, userProvider),
                        const SizedBox(height: 40),

                        // 2. SECTION MES CYCLES PAYÉS
                        _buildPaidCyclesSection(isArabic),
                        const SizedBox(height: 40),

                        // 3. SECTION AUTRES SERVICES
                        _buildOtherServicesSection(isArabic),
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),

                // Navbar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Navbar(isMobile: isMobile, scaffoldKey: _scaffoldKey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET : EN-TÊTE DU COMPTE ---
  Widget _buildHeaderSection(
    bool isArabic,
    bool isMobile,
    UserProvider userProvider,
  ) {
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
                    Text(
                      isArabic ? "مرحباً، $userName" : "Bienvenue, $userName",
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
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

  // --- WIDGET : LES CYCLES ACHETÉS ---
  Widget _buildPaidCyclesSection(bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? "دوراتي التدريبية" : "Mes Cycles Achetés",
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 16),
        if (paidCycles.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.05)),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 60,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isArabic
                        ? "لا توجد دورات مشتركة حالياً"
                        : "Aucun cycle acheté pour le moment",
                    style: GoogleFonts.cairo(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: paidCycles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final cycle = paidCycles[index];
              double progressValue = double.parse(cycle['progress']!);

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.01),
                      blurRadius: 10,
                    ),
                  ],
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.05),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? cycle['titleAr']! : cycle['titleFr']!,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isArabic
                          ? "الدرس التالي: ${cycle['nextLessonAr']}"
                          : "Prochain cours : ${cycle['nextLessonFr']}",
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Barre de progression
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progressValue,
                              backgroundColor: AppColors.primary.withOpacity(
                                0.1,
                              ),
                              color: AppColors.primary,
                              minHeight: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "${(progressValue * 100).toInt()}%",
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // --- WIDGET : AUTRES SERVICES ---
  Widget _buildOtherServicesSection(bool isArabic) {
    final List<Map<String, dynamic>> services = [
      {
        "icon": Icons.verified_rounded,
        "titleFr": "Mes Certificats",
        "titleAr": "شهاداتي",
      },
      {
        "icon": Icons.receipt_long_rounded,
        "titleFr": "Factures & Paiements",
        "titleAr": "الفواتير والمدفوعات",
      },
      {
        "icon": Icons.headset_mic_rounded,
        "titleFr": "Support Académique",
        "titleAr": "الدعم الأكاديمي",
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? "خدمات أخرى" : "Autres Services",
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 250,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            mainAxisExtent: 100,
          ),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.05)),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isArabic
                            ? "🔧 ${service['titleAr']} - قريباً"
                            : "🔧 ${service['titleFr']} - Bientôt disponible",
                        style: GoogleFonts.cairo(),
                      ),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        service['icon'] as IconData,
                        color: AppColors.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isArabic ? service['titleAr']! : service['titleFr']!,
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// 👈 AppColors
class AppColors {
  static const Color surface = Color(0xfffcfbfa);
  static const Color primary = Color(0xffd57653);
  static const Color textDark = Color(0xff2c221e);
  static const Color textMuted = Color(0xff7c6e68);
  static const Color primaryDark = Color(0xff994a2b);
}
