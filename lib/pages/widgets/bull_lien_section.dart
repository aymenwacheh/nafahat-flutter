// lib/pages/landing/widgets/bull_lien_section.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafahat/models/bull_model.dart';
import 'package:nafahat/providers/language_provider.dart';
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
    
    // ✅ Si c'est un lien vers un formateur
    if (link.startsWith('/formateur/')) {
      final formateurId = link.replaceAll('/formateur/', '');
      print('   👤 Navigation vers formateur: $formateurId');
      
      Navigator.pushNamed(
        context,
        '/formations',
        arguments: {'formateurId': formateurId},
      );
      return;
    }
    
    // ✅ Si c'est un lien vers une vidéo
    if (link.startsWith('/video/')) {
      final videoId = link.replaceAll('/video/', '');
      print('   🎬 Navigation vers vidéo: $videoId');
      
      Navigator.pushNamed(
        context,
        '/video/$videoId',
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