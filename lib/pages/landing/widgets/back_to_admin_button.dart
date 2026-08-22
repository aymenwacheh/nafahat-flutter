// lib/widgets/back_to_admin_button.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/language_provider.dart';
import '../../../services/navigation_service.dart';

class BackToAdminButton extends StatelessWidget {
  const BackToAdminButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;

    return TextButton.icon(
      onPressed: () {
        NavigationService.goBackToAdmin();
      },
      icon: Icon(Icons.dashboard_rounded, color: Colors.white, size: 18),
      label: Text(
        isArabic ? 'لوحة التحكم' : 'Tableau de bord',
        style: GoogleFonts.cairo(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: const Color(0xff0D443E).withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
