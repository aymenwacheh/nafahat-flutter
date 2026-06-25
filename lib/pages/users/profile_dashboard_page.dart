import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nafahat/pages/users/edit_profile_page.dart';
import 'package:nafahat/src/features/landing/presentation/landing_page.dart';
import 'package:nafahat/src/features/landing/presentation/widgets/navbar.dart'
    show Navbar;
// Import de ta Navbar globale
// Pour récupérer tes AppColors

class ProfileDashboardPage extends StatefulWidget {
  const ProfileDashboardPage({super.key});

  @override
  State<ProfileDashboardPage> createState() => _ProfileDashboardPageState();
}

class _ProfileDashboardPageState extends State<ProfileDashboardPage> {
  bool isArabic = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Simulation des données de l'utilisateur connecté
  final Map<String, dynamic> userData = {
    "name": "Amine Ben Ali",
    "email": "amine.ba@ertiqa.com",
    "avatar":
        "assets/images/user_avatar.png", // Optionnel (ou icône par défaut)
  };

  // Liste des cycles payés par cet utilisateur
  final List<Map<String, String>> paidCycles = [
    {
      "titleFr": "Excellence Executive MBA",
      "titleAr": "الماجستير التنفيذي المتميز",
      "progress": "0.65", // 65% de progression
      "nextLessonFr": "Module 4 : Leadership Stratégique",
      "nextLessonAr": "الوحدة ٤: القيادة الاستراتيجية",
    },
    {
      "titleFr": "Tech & Intelligence Artificielle",
      "titleAr": "التكنولوجيا والذكاء الاصطناعي",
      "progress": "0.20", // 20% de progression
      "nextLessonFr": "Module 1 : Introduction au Machine Learning",
      "nextLessonAr": "الوحدة ١: مقدمة في تعلم الآلة",
    },
  ];

  void toggleLanguage() {
    setState(() {
      isArabic = !isArabic;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 850;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
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
                      const SizedBox(height: 120), // Espace sous la Navbar fixe
                      // 1. BLOC PROFIL / BIENVENUE
                      _buildHeaderSection(isMobile),
                      const SizedBox(height: 40),

                      // 2. SECTION MES CYCLES PAYÉS
                      _buildPaidCyclesSection(),
                      const SizedBox(height: 40),

                      // 3. SECTION AUTRES SERVICES
                      _buildOtherServicesSection(),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),

              // Ta Navbar réutilisée à l'identique !
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

  // --- WIDGET : EN-TÊTE DU COMPTE ---
  Widget _buildHeaderSection(bool isMobile) {
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
            child: const Icon(
              Icons.person_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic
                      ? "مرحباً، ${userData['name']}"
                      : "Bienvenue, ${userData['name']}",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userData['email'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
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
                  builder: (context) => EditProfilePage(isArabic: isArabic),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- WIDGET : LES CYCLES ACHETÉS ---
  Widget _buildPaidCyclesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? "دوراتي التدريبية" : "Mes Cycles Achetés",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 16),
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
                border: Border.all(color: AppColors.primary.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? cycle['titleAr']! : cycle['titleFr']!,
                    style: const TextStyle(
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
                    style: const TextStyle(
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
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            color: AppColors.primary,
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "${(progressValue * 100).toInt()}%",
                        style: const TextStyle(
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

  // --- WIDGET : AUTRES SERVICES (Attestations, Factures, Support) ---
  Widget _buildOtherServicesSection() {
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
          style: const TextStyle(
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
                onTap: () {}, // Action au clic sur le service
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
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                        ),
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
