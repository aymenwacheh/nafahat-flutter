// lib/widgets/back_to_landing_button.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../services/navigation_service.dart';

class BackToLandingButton extends StatelessWidget {
  const BackToLandingButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;

    return Tooltip(
      message:
          isArabic
              ? 'الذهاب إلى الصفحة الرئيسية'
              : 'Aller à la page d\'accueil',
      child: InkWell(
        onTap: () {
          NavigationService.goBackToLanding();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xffd57653).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.home_rounded,
            color: const Color(0xffd57653),
            size: 20,
          ),
        ),
      ),
    );
  }
}
