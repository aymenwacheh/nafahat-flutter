// lib/widgets/inscription_section.dart
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafahat/pages/users/inscription_adherent.dart';
import 'package:provider/provider.dart';

// --- PALETTE DE COULEURS (même que landing) ---
class AppColors {
  static const Color primary = Color(0xffd57653);
  static const Color primaryDark = Color(0xff994a2b);
  static const Color primaryLight = Color(0xfffae6de);
  static const Color surface = Color(0xfffcfbfa);
  static const Color textDark = Color(0xff2c221e);
  static const Color textMuted = Color(0xff7c6e68);
}

class InscriptionSection extends StatefulWidget {
  final bool isArabic;
  final bool fullWidth;
  final double? height;
  final String? customText;
  final Color? buttonColor;
  final Color? textColor;
  final bool showIcon;
  final bool showSubtitle;
  final EdgeInsetsGeometry? padding;

  const InscriptionSection({
    super.key,
    required this.isArabic,
    this.fullWidth = false,
    this.height,
    this.customText,
    this.buttonColor,
    this.textColor,
    this.showIcon = true,
    this.showSubtitle = true,
    this.padding,
  });

  @override
  State<InscriptionSection> createState() => _InscriptionSectionState();
}

class _InscriptionSectionState extends State<InscriptionSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  // Texts in both languages
  final Map<String, Map<String, String>> _texts = {
    'fr': {
      'title': 'Rejoignez notre communauté',
      'subtitle':
          'Inscrivez-vous dès maintenant et bénéficiez de nos formations',
      'button': 'Inscrivez-vous maintenant',
      'button_short': 'Inscrivez-vous',
      'cta': 'Commencez votre parcours',
      'benefits': 'Accédez à toutes nos formations',
    },
    'ar': {
      'title': 'انضم إلى مجتمعنا',
      'subtitle': 'سجل الآن واستفد من تكويناتنا',
      'button': 'سجل الآن',
      'button_short': 'سجل',
      'cta': 'ابدأ رحلتك',
      'benefits': 'الوصول إلى جميع تكويناتنا',
    },
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isArabic = widget.isArabic;
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final bool isTablet =
        MediaQuery.of(context).size.width >= 600 &&
        MediaQuery.of(context).size.width < 900;
    final double screenWidth = MediaQuery.of(context).size.width;

    // Get text based on language
    String getText(String key) {
      if (widget.customText != null && key == 'button') {
        return widget.customText!;
      }
      return _texts[isArabic ? 'ar' : 'fr']?[key] ?? _texts['fr']![key]!;
    }

    // Different button text variations
    final List<String> buttonTexts = [
      getText('button'),
      getText('cta'),
      getText('button_short'),
      getText('benefits'),
    ];

    final int textIndex = DateTime.now().second % buttonTexts.length;
    final String displayText = buttonTexts[textIndex];

    final double buttonHeight = widget.height ?? (isMobile ? 50 : 60);
    final double buttonWidth =
        widget.fullWidth
            ? double.infinity
            : (isMobile ? screenWidth - 60 : 280);
    final double fontSize = isMobile ? 15 : 17;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding:
          widget.padding ??
          EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : (isTablet ? 40 : 60),
            vertical: isMobile ? 30 : 50,
          ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight.withOpacity(0.3),
            AppColors.surface,
            AppColors.primaryLight.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 16 : 24),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Titre
          Text(
            getText('title'),
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 22 : (isTablet ? 28 : 32),
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // Sous-titre
          if (widget.showSubtitle)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 0 : 20),
              child: Text(
                getText('subtitle'),
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 14 : 16,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 24),

          // Bouton animé
          MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isHovered ? 1.05 : _pulseAnimation.value,
                  child: SizedBox(
                    width: buttonWidth,
                    height: buttonHeight,
                    child: ElevatedButton(
                      onPressed: () {
                        _navigateToInscription(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            widget.buttonColor ?? AppColors.primary,
                        foregroundColor: widget.textColor ?? Colors.white,
                        elevation: _isHovered ? 8 : 4,
                        shadowColor: AppColors.primary.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            isMobile ? 25 : 30,
                          ),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 20 : 28,
                          vertical: isMobile ? 12 : 16,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.showIcon && !isArabic) ...[
                            Flexible(
                              child: Text(
                                displayText,
                                style: GoogleFonts.cairo(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w600,
                                  color: widget.textColor ?? Colors.white,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                            _buildIcon(isMobile, isArabic),
                          ] else if (widget.showIcon && isArabic) ...[
                            _buildIcon(isMobile, isArabic),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                displayText,
                                style: GoogleFonts.cairo(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w600,
                                  color: widget.textColor ?? Colors.white,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ] else ...[
                            Flexible(
                              child: Text(
                                displayText,
                                style: GoogleFonts.cairo(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w600,
                                  color: widget.textColor ?? Colors.white,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Effet de brillance animé
          if (_isHovered)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.transparent,
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(isMobile ? 25 : 30),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIcon(bool isMobile, bool isArabic) {
    return Icon(
      isArabic ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
      size: isMobile ? 20 : 24,
      color: widget.textColor ?? Colors.white,
    );
  }

  void _navigateToInscription(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const InscriptionAdherentPage()),
    );
  }
}
