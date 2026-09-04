// lib/pages/widgets/mobile_bottom_nav.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafahat/providers/language_provider.dart';
import 'package:provider/provider.dart';

class MobileBottomNav extends StatelessWidget {
  const MobileBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    // Ne s'affiche que sur mobile
    if (!isMobile) return const SizedBox.shrink();

    return Container(
      height: 65,
      decoration: BoxDecoration(
        color: const Color(0xff0D443E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Profil (gauche)
          _buildNavItem(
            context,
            icon: Icons.person_outline_rounded,
            label: 'Profil',
            onTap: () => Navigator.pushNamed(context, '/profile'),
          ),

          // Home (milieu - plus grand)
          _buildNavItem(
            context,
            icon: Icons.home_rounded,
            label: 'Accueil',
            onTap: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/landing',
              (route) => false,
            ),
            isCenter: true,
          ),

          // Retour (droite)
          _buildNavItem(
            context,
            icon: Icons.arrow_back_rounded,
            label: 'Retour',
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isCenter = false,
  }) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;
    
    // Labels en arabe
    String displayLabel = label;
    if (isArabic) {
      if (label == 'Profil') displayLabel = 'الملف الشخصي';
      else if (label == 'Accueil') displayLabel = 'الرئيسية';
      else if (label == 'Retour') displayLabel = 'رجوع';
    }

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: isCenter ? 4 : 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(isCenter ? 10 : 6),
                decoration: BoxDecoration(
                  color: isCenter ? Colors.white.withOpacity(0.2) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: isCenter ? 30 : 24,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                displayLabel,
                style: GoogleFonts.cairo(
                  fontSize: 10,
                  color: Colors.white70,
                  fontWeight: isCenter ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}