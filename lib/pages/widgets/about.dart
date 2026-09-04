// lib/pages/landing/widgets/about.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nafahat/providers/language_provider.dart';
import 'package:nafahat/providers/about_provider.dart';
import 'package:nafahat/models/about_model.dart';
import 'package:nafahat/pages/widgets/navbar.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;
    final aboutProvider = Provider.of<AboutProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final isDesktop = screenWidth >= 900;

    // Clé pour le scaffold (nécessaire pour le drawer)
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    // Créer une instance unique du Navbar
    final navbar = Navbar(
      isMobile: isMobile,
      scaffoldKey: scaffoldKey,
    );

    // Charger les données si pas encore chargées
    if (!aboutProvider.hasData && !aboutProvider.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        aboutProvider.loadAbout();
      });
    }

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xfffcfbfa),
      // ============================================================
      // DRAWER MOBILE - POUR QUE LE MENU FONCTIONNE
      // ============================================================
      drawer: navbar.buildDrawer(context),
      body: Column(
        children: [
          // ============================================================
          // NAVBAR (responsif mobile/web)
          // ============================================================
          navbar,
          // ============================================================
          // CONTENU PRINCIPAL
          // ============================================================
          Expanded(
            child: aboutProvider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xff0D443E),
                    ),
                  )
                : aboutProvider.hasData
                    ? _buildContent(
                        context,
                        aboutProvider.about!,
                        isArabic,
                        isMobile,
                        isTablet,
                        isDesktop,
                        screenWidth,
                        screenHeight,
                      )
                    : _buildErrorState(context, isArabic, isMobile),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AboutModel about,
    bool isArabic,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
    double screenWidth,
    double screenHeight,
  ) {
    // Calcul des marges et paddings responsives
    final horizontalPadding = isMobile ? 16.0 : (isTablet ? 32.0 : 60.0);
    final verticalPadding = isMobile ? 16.0 : (isTablet ? 24.0 : 40.0);
    final cardPadding = isMobile ? 16.0 : (isTablet ? 20.0 : 28.0);
    final titleSize = isMobile ? 24.0 : (isTablet ? 30.0 : 36.0);
    final subtitleSize = isMobile ? 16.0 : (isTablet ? 20.0 : 24.0);
    final bodySize = isMobile ? 14.0 : (isTablet ? 16.0 : 18.0);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo et titre
          _buildHeader(
            context,
            about,
            isArabic,
            isMobile,
            isDesktop,
            titleSize,
            subtitleSize,
          ),
          const SizedBox(height: 24),

          // Contenu principal - Vision & Mission
          _buildContentSection(
            context,
            about,
            isArabic,
            isMobile,
            isDesktop,
            cardPadding,
            bodySize,
          ),
          const SizedBox(height: 32),

          // Équipe
          _buildTeamSection(
            context,
            about,
            isArabic,
            isMobile,
            isDesktop,
            screenWidth,
            cardPadding,
            bodySize,
          ),
          const SizedBox(height: 32),

          // Statistiques
          _buildStatsSection(
            context,
            about,
            isArabic,
            isMobile,
            isDesktop,
            screenWidth,
            cardPadding,
            bodySize,
          ),
          const SizedBox(height: 32),

          // Contact et réseaux sociaux
          _buildContactSection(
            context,
            about,
            isArabic,
            isMobile,
            isDesktop,
            cardPadding,
            bodySize,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, bool isArabic, bool isMobile) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: isMobile ? 48 : 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'خطأ في تحميل البيانات' : 'Erreur de chargement',
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 16 : 20,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isArabic ? 'يرجى المحاولة مرة أخرى' : 'Veuillez réessayer',
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 13 : 15,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                final provider = Provider.of<AboutProvider>(
                  context,
                  listen: false,
                );
                provider.loadAbout();
              },
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: Text(isArabic ? 'إعادة المحاولة' : 'Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff0D443E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AboutModel about,
    bool isArabic,
    bool isMobile,
    bool isDesktop,
    double titleSize,
    double subtitleSize,
  ) {
    return Column(
      children: [
        // Logo avec ombre moderne
        Container(
          width: isMobile ? 80 : (isDesktop ? 130 : 100),
          height: isMobile ? 80 : (isDesktop ? 130 : 100),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isMobile ? 16 : 24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff0D443E).withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 12),
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isMobile ? 16 : 24),
            child: Image.asset('assets/images/logo.jpg', fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 20),

        // Titre
        Text(
          isArabic ? about.titleAr : about.titleFr,
          style: GoogleFonts.cairo(
            fontSize: titleSize,
            fontWeight: FontWeight.bold,
            color: const Color(0xff0D443E),
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Slogan avec couleur dorée
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xffC4A46C).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isArabic ? about.sloganAr : about.sloganFr,
            style: GoogleFonts.cairo(
              fontSize: subtitleSize,
              fontWeight: FontWeight.w600,
              color: const Color(0xffC4A46C),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Sous-titre
        Text(
          isArabic ? about.subtitleAr : about.subtitleFr,
          style: GoogleFonts.cairo(
            fontSize: isMobile ? 14 : (isDesktop ? 18 : 16),
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),

        // Petit slogan
        Text(
          isArabic
              ? 'تعلم، طبق، وارتقِ بنفسك'
              : 'Apprenez, appliquez et élevez-vous',
          style: GoogleFonts.cairo(
            fontSize: isMobile ? 12 : 14,
            color: Colors.grey.shade500,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),

        // CTA - Appel à l'action
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xff0D443E),
                const Color(0xff0D443E).withOpacity(0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff0D443E).withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            isArabic ? about.ctaAr : about.ctaFr,
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 13 : 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Séparateur décoratif
        Container(
          width: isMobile ? 60 : 100,
          height: 4,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xffC4A46C),
                const Color(0xffC4A46C).withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildContentSection(
    BuildContext context,
    AboutModel about,
    bool isArabic,
    bool isMobile,
    bool isDesktop,
    double cardPadding,
    double bodySize,
  ) {
    final String title =
        isArabic ? 'رؤيتنا ورسالتنا' : 'Notre vision et mission';
    final String description =
        isArabic ? about.descriptionAr : about.descriptionFr;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: const Color(0xff0D443E).withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre avec icône
          Row(
            children: [
              Container(
                width: 4,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xffC4A46C),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 18 : (isDesktop ? 24 : 20),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff0D443E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            description,
            style: GoogleFonts.cairo(
              fontSize: bodySize,
              height: 1.8,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: 20),

          // Valeurs / Thèmes en chips
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children:
                about.values.map((value) {
                  return _buildValueChip(context, value, isMobile);
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildValueChip(BuildContext context, String label, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 18,
        vertical: isMobile ? 8 : 10,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xff0D443E).withOpacity(0.08),
            const Color(0xff0D443E).withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xff0D443E).withOpacity(0.12)),
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: isMobile ? 12 : 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xff0D443E),
        ),
      ),
    );
  }

  Widget _buildTeamSection(
    BuildContext context,
    AboutModel about,
    bool isArabic,
    bool isMobile,
    bool isDesktop,
    double screenWidth,
    double cardPadding,
    double bodySize,
  ) {
    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: const Color(0xff0D443E).withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xffC4A46C),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                isArabic ? '👥 فريقنا' : '👥 Notre équipe',
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 18 : (isDesktop ? 24 : 20),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff0D443E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (about.teamMembers.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  isArabic
                      ? 'لا يوجد أعضاء في الفريق'
                      : 'Aucun membre d\'équipe',
                  style: GoogleFonts.cairo(
                    fontSize: bodySize,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            )
          else if (isMobile)
            // Mobile: Liste verticale avec scroll
            Column(
              children:
                  about.teamMembers.map((member) {
                    return _buildTeamMemberCard(
                      context,
                      member,
                      isMobile,
                      isDesktop,
                    );
                  }).toList(),
            )
          else
            // Desktop/Tablet: Grille responsive
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isDesktop ? 3 : 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: about.teamMembers.length,
              itemBuilder: (context, index) {
                return _buildTeamMemberCard(
                  context,
                  about.teamMembers[index],
                  isMobile,
                  isDesktop,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTeamMemberCard(
    BuildContext context,
    TeamMember member,
    bool isMobile,
    bool isDesktop,
  ) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xff0D443E).withOpacity(0.04),
            const Color(0xff0D443E).withOpacity(0.01),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xff0D443E).withOpacity(0.08)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar avec gradient
          Container(
            width: isMobile ? 56 : (isDesktop ? 72 : 64),
            height: isMobile ? 56 : (isDesktop ? 72 : 64),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xff0D443E),
                  const Color(0xff0D443E).withOpacity(0.7),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff0D443E).withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: isMobile ? 30 : (isDesktop ? 38 : 34),
            ),
          ),
          const SizedBox(height: 12),

          // Nom
          Text(
            member.name,
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 14 : (isDesktop ? 18 : 16),
              fontWeight: FontWeight.w700,
              color: const Color(0xff2c221e),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // Rôle
          Text(
            isArabic ? member.roleAr : member.roleFr,
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 11 : (isDesktop ? 14 : 13),
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(
    BuildContext context,
    AboutModel about,
    bool isArabic,
    bool isMobile,
    bool isDesktop,
    double screenWidth,
    double cardPadding,
    double bodySize,
  ) {
    final stats = [
      {
        'value': about.stat1Value,
        'label': isArabic ? about.stat1LabelAr : about.stat1LabelFr,
        'icon': Icons.school_rounded,
      },
      {
        'value': about.stat2Value,
        'label': isArabic ? about.stat2LabelAr : about.stat2LabelFr,
        'icon': Icons.people_rounded,
      },
      {
        'value': about.stat3Value,
        'label': isArabic ? about.stat3LabelAr : about.stat3LabelFr,
        'icon': Icons.person_rounded,
      },
      {
        'value': about.stat4Value,
        'label': isArabic ? about.stat4LabelAr : about.stat4LabelFr,
        'icon': Icons.star_rounded,
      },
    ];

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xff0D443E),
            const Color(0xff0D443E).withOpacity(0.92),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff0D443E).withOpacity(0.25),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? '📊 إنجازاتنا' : '📊 Nos réalisations',
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 18 : (isDesktop ? 24 : 20),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          // Grille de statistiques responsive
          if (isMobile)
            // Mobile: 2x2 grille
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: stats.length,
              itemBuilder: (context, index) {
                return _buildStatCard(stats[index], isMobile, isDesktop);
              },
            )
          else
            // Desktop/Tablet: Ligne horizontale
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children:
                  stats.map((stat) {
                    return Expanded(
                      child: _buildStatCard(stat, isMobile, isDesktop),
                    );
                  }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    Map<String, dynamic> stat,
    bool isMobile,
    bool isDesktop,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 0 : 4),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            stat['icon'],
            color: const Color(0xffC4A46C),
            size: isMobile ? 24 : (isDesktop ? 32 : 28),
          ),
          const SizedBox(height: 6),
          Text(
            stat['value']!,
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 22 : (isDesktop ? 34 : 28),
              fontWeight: FontWeight.bold,
              color: const Color(0xffC4A46C),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            stat['label']!,
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 10 : (isDesktop ? 14 : 12),
              color: Colors.white.withOpacity(0.85),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(
    BuildContext context,
    AboutModel about,
    bool isArabic,
    bool isMobile,
    bool isDesktop,
    double cardPadding,
    double bodySize,
  ) {
    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: const Color(0xff0D443E).withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xffC4A46C),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                isArabic ? '📬 تواصل معنا' : '📬 Contactez-nous',
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 18 : (isDesktop ? 24 : 20),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff0D443E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Contacts
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildContactItem(
                context,
                Icons.email_outlined,
                about.email,
                isMobile,
                isDesktop,
                () => _launchEmail(about.email),
              ),
              _buildContactItem(
                context,
                Icons.phone_outlined,
                about.phone,
                isMobile,
                isDesktop,
                () => _launchPhone(about.phone),
              ),
              _buildContactItem(
                context,
                Icons.location_on_outlined,
                isArabic ? about.addressAr : about.addressFr,
                isMobile,
                isDesktop,
                null,
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(height: 1, color: Colors.grey),
          const SizedBox(height: 20),

          // Réseaux sociaux
          Text(
            isArabic ? 'تابعنا على' : 'Suivez-nous sur',
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 14 : (isDesktop ? 18 : 16),
              fontWeight: FontWeight.w600,
              color: const Color(0xff0D443E),
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (about.facebookUrl != null && about.facebookUrl!.isNotEmpty)
                _buildSocialButton(
                  context,
                  Icons.facebook_rounded,
                  'Facebook',
                  const Color(0xff1877F2),
                  () => _launchUrl(about.facebookUrl!),
                  isMobile,
                  isDesktop,
                ),
              if (about.youtubeUrl != null && about.youtubeUrl!.isNotEmpty)
                _buildSocialButton(
                  context,
                  Icons.play_circle_filled_rounded,
                  'YouTube',
                  const Color(0xffFF0000),
                  () => _launchUrl(about.youtubeUrl!),
                  isMobile,
                  isDesktop,
                ),
              if (about.telegramUrl != null && about.telegramUrl!.isNotEmpty)
                _buildSocialButton(
                  context,
                  Icons.send_rounded,
                  'Telegram',
                  const Color(0xff0088cc),
                  () => _launchUrl(about.telegramUrl!),
                  isMobile,
                  isDesktop,
                ),
              if (about.instagramUrl != null && about.instagramUrl!.isNotEmpty)
                _buildSocialButton(
                  context,
                  Icons.camera_alt_rounded,
                  'Instagram',
                  const Color(0xffE4405F),
                  () => _launchUrl(about.instagramUrl!),
                  isMobile,
                  isDesktop,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(
    BuildContext context,
    IconData icon,
    String text,
    bool isMobile,
    bool isDesktop,
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 14 : (isDesktop ? 22 : 18),
          vertical: isMobile ? 10 : (isDesktop ? 16 : 14),
        ),
        decoration: BoxDecoration(
          color: const Color(0xff0D443E).withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xff0D443E).withOpacity(0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isMobile ? 18 : (isDesktop ? 24 : 20),
              color: const Color(0xff0D443E),
            ),
            const SizedBox(width: 10),
            Text(
              text,
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 12 : (isDesktop ? 16 : 14),
                color: const Color(0xff2c221e),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
    bool isMobile,
    bool isDesktop,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : (isDesktop ? 24 : 20),
          vertical: isMobile ? 10 : (isDesktop ? 14 : 12),
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isMobile ? 18 : (isDesktop ? 24 : 20),
              color: color,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 12 : (isDesktop ? 16 : 14),
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fonctions de lancement
  void _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Erreur lancement URL: $e');
    }
  }

  void _launchEmail(String email) async {
    final Uri uri = Uri.parse('mailto:$email');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Erreur lancement email: $e');
    }
  }

  void _launchPhone(String phone) async {
    final Uri uri = Uri.parse('tel:$phone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Erreur lancement téléphone: $e');
    }
  }
}