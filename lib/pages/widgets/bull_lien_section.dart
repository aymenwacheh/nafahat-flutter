// lib/pages/landing/widgets/bull_lien_section.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafahat/models/bull_model.dart';
import 'package:nafahat/providers/language_provider.dart';
import 'package:nafahat/pages/formateur/formateur_detail_page.dart';
import 'package:nafahat/pages/formation/video_detail_page.dart';
import 'package:nafahat/pages/widgets/about.dart';
import 'package:nafahat/pages/widgets/shared_navigation_shell.dart';
import 'package:provider/provider.dart';

class BullLien extends StatelessWidget {
  final BullModel bull;
  final VoidCallback? onTap;

  const BullLien({
    super.key,
    required this.bull,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;
    
    // Choisir le titre selon la langue
    String title = bull.title;
    if (isArabic && bull.titleAr != null && bull.titleAr!.isNotEmpty) {
      title = bull.titleAr!;
    } else if (!isArabic && bull.titleFr != null && bull.titleFr!.isNotEmpty) {
      title = bull.titleFr!;
    }

    return GestureDetector(
      onTap: onTap ?? () {
        // ✅ Navigation intelligente selon le type de lien
        _handleBullNavigation(context, bull);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: bull.backgroundColor,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: bull.borderColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: bull.backgroundColor.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: bull.fontSize,
            fontWeight: FontWeight.w600,
            color: bull.textColor,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GESTIONNAIRE DE NAVIGATION INTELLIGENTE
  // ============================================================
  void _handleBullNavigation(BuildContext context, BullModel bull) {
    print('🔗 [BULL] Clic sur: ${bull.title}');
    print('   📍 Lien: ${bull.link}');
    
    final link = bull.link;
    
    // ✅ Si c'est un lien vers une catégorie
    if (link.startsWith('/categorie/')) {
      final categorieId = link.replaceAll('/categorie/', '');
      print('   🏷️ Navigation vers catégorie: $categorieId');
      
      Navigator.pushNamed(
        context,
        '/formations',
        arguments: {'categorieId': categorieId},
      );
      return;
    }
    
    // ✅ Si c'est un lien vers un formateur : ouvrir sa fiche d'information.
    if (link.startsWith('/formateur/')) {
      final formateurId = link.replaceAll('/formateur/', '').trim();
      print('   👤 Navigation vers la fiche formateur: $formateurId');

      if (formateurId.isNotEmpty) {
        Navigator.push(
          context,
          NafahatPageRoute(
            builder: (context) =>
                FormateurDetailPage(formateurId: formateurId),
          ),
        );
      }
      return;
    }
    
    // ✅ Si c'est un lien vers une vidéo : ouvrir directement sa fiche.
    if (link.startsWith('/video/')) {
      final videoId = link.replaceAll('/video/', '').trim();
      print('   🎬 Navigation vers vidéo: $videoId');

      if (videoId.isNotEmpty) {
        Navigator.push(
          context,
          NafahatPageRoute(
            builder: (context) => VideoDetailPage(videoId: videoId),
          ),
        );
      }
      return;
    }
    
    // ✅ Si c'est un lien vers une formation
    if (link.startsWith('/formation/')) {
      final formationId = link.replaceAll('/formation/', '').trim();
      if (formationId.isNotEmpty) {
        Navigator.pushNamed(context, '/formation/$formationId');
      }
      return;
    }

    // ✅ Section de la landing page.
    if (link.startsWith('/section/')) {
      final section = link.replaceAll('/section/', '').trim();
      Navigator.pushNamed(
        context,
        '/landing',
        arguments: {'section': section},
      );
      return;
    }

    if (link == '/' || link == '/landing') {
      Navigator.pushNamedAndRemoveUntil(context, '/landing', (route) => false);
      return;
    }

    if (link == '/about' || link == '/contact') {
      Navigator.push(
        context,
        NafahatPageRoute(builder: (context) => const AboutPage()),
      );
      return;
    }

    // ✅ Navigation standard
    print('   🔗 Navigation normale vers: $link');
    Navigator.pushNamed(context, link);
  }
}

// ============================================================
// LISTE DES BULLS
// ============================================================
class BullsList extends StatelessWidget {
  final List<BullModel> bulls;
  final Function(BullModel)? onBullTap;

  const BullsList({
    super.key,
    required this.bulls,
    this.onBullTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeBulls = bulls.where((b) => b.isActive).toList();
    
    if (activeBulls.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: activeBulls.map((bull) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: BullLien(
              bull: bull,
              onTap: onBullTap != null ? () => onBullTap!(bull) : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}