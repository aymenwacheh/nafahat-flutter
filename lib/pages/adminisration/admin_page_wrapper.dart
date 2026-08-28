// lib/pages/adminisration/widgets/admin_page_wrapper.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafahat/providers/language_provider.dart';
import 'package:provider/provider.dart';

class AdminPageWrapper extends StatelessWidget {
  final Widget child;
  final String title;
  final String? titleAr;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final bool showBackButton;
  final Color backgroundColor;

  const AdminPageWrapper({
    super.key,
    required this.child,
    required this.title,
    this.titleAr,
    this.onBackPressed,
    this.actions,
    this.showBackButton = true,
    this.backgroundColor = const Color(0xFFF5F5F5),
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;
    final displayTitle = isArabic ? (titleAr ?? title) : title;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          displayTitle,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xff0D443E),
        foregroundColor: Colors.white,
        elevation: 0,
        leading:
            (showBackButton && isMobile)
                ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                  tooltip:
                      isArabic
                          ? 'العودة إلى لوحة القيادة'
                          : 'Retour au tableau de bord',
                )
                : null,
        actions: actions,
      ),
      body: child,
    );
  }
}
