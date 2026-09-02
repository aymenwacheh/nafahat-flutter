// lib/widgets/training_card.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafahat/models/training_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nafahat/pages/formation/formation_detail_page.dart';
import 'package:nafahat/services/card_config_manager.dart';
import 'package:nafahat/services/geo_service.dart';
import 'package:nafahat/models/card_config_model.dart';

class TrainingCard extends StatefulWidget {
  final TrainingModel training;
  final bool isArabic;
  final VoidCallback onRefresh;
  final bool isMobile;

  const TrainingCard({
    super.key,
    required this.training,
    required this.isArabic,
    required this.onRefresh,
    this.isMobile = false,
  });

  @override
  State<TrainingCard> createState() => _TrainingCardState();
}

class _TrainingCardState extends State<TrainingCard> {
  bool isHovered = false;
  CardConfig? _cardConfig;
  late ValueNotifier<CardConfig?> _configNotifier;
  String _countryCode = 'TN';
  bool _isLoadingCountry = true;

  static const String BASE_URL = 'http://www.nafahat-academy.com';
  static const String FALLBACK_IMAGE = 'https://picsum.photos/800/450';

  @override
  void initState() {
    super.initState();
    _configNotifier = CardConfigManager().configNotifier;
    _loadCardConfig();
    _configNotifier.addListener(_onConfigChanged);
    _detectCountry();
  }

  @override
  void dispose() {
    _configNotifier.removeListener(_onConfigChanged);
    super.dispose();
  }

  void _onConfigChanged() {
    final newConfig = _configNotifier.value;
    if (newConfig != null) {
      setState(() {
        _cardConfig = newConfig;
      });
    }
  }

  Future<void> _detectCountry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? savedCountry = prefs.getString('user_country');

      if (savedCountry != null && savedCountry.isNotEmpty) {
        setState(() {
          _countryCode = savedCountry;
          _isLoadingCountry = false;
        });
      } else {
        final countryCode = await GeoService.getUserCountryCode();
        await prefs.setString('user_country', countryCode);
        setState(() {
          _countryCode = countryCode;
          _isLoadingCountry = false;
        });
      }
    } catch (e) {
      setState(() {
        _countryCode = 'TN';
        _isLoadingCountry = false;
      });
    }
  }

  Future<void> _loadCardConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString('card_config_apparence');
      if (configJson != null && configJson.isNotEmpty) {
        final data = json.decode(configJson);
        final config = CardConfig.fromJson(data);
        setState(() {
          _cardConfig = config;
        });
        CardConfigManager().updateConfig(config);
      } else {
        final defaultConfig = CardConfig.defaultConfig();
        setState(() {
          _cardConfig = defaultConfig;
        });
        CardConfigManager().updateConfig(defaultConfig);
      }
    } catch (e) {
      final defaultConfig = CardConfig.defaultConfig();
      setState(() {
        _cardConfig = defaultConfig;
      });
      CardConfigManager().updateConfig(defaultConfig);
    }
  }

  String _extractFontFamily(String fontWithVariant) {
    if (fontWithVariant.contains('-')) {
      return fontWithVariant.split('-').first;
    }
    return fontWithVariant;
  }

  String _getValidImageUrl(String imageUrl) {
    String result;

    if (imageUrl.isEmpty || imageUrl == 'null' || imageUrl == 'NULL') {
      result = 'https://picsum.photos/seed/${widget.training.id}/800/450';
    } else if (imageUrl.contains('http://www.nafahat-academy.com') ||
        imageUrl.contains('https://www.nafahat-academy.com')) {
      result = imageUrl;
    } else if (imageUrl.contains('http://localhost:3000')) {
      if (imageUrl.contains('http://localhost:3000http://localhost:3000')) {
        result = imageUrl.replaceAll(
          'http://localhost:3000http://localhost:3000',
          'http://localhost:3000',
        );
      } else {
        result = imageUrl;
      }
    } else if (imageUrl.startsWith('http://') ||
        imageUrl.startsWith('https://')) {
      result = imageUrl;
    } else if (imageUrl.contains('C:\\') || imageUrl.contains('\\')) {
      String fileName = imageUrl.split('\\').last;
      result = '$BASE_URL/uploads/formations/$fileName';
    } else if (imageUrl.startsWith('/uploads')) {
      result = '$BASE_URL$imageUrl';
    } else if (imageUrl.startsWith('assets/')) {
      result = imageUrl;
    } else if (imageUrl.contains('.jpg') ||
        imageUrl.contains('.png') ||
        imageUrl.contains('.jpeg') ||
        imageUrl.contains('.gif') ||
        imageUrl.contains('.webp')) {
      result = '$BASE_URL/uploads/formations/$imageUrl';
    } else {
      result = 'https://picsum.photos/seed/${widget.training.id}/800/450';
    }

    if (!result.startsWith('http://') &&
        !result.startsWith('https://') &&
        !result.startsWith('assets/')) {
      result = 'https://picsum.photos/seed/${widget.training.id}/800/450';
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (_cardConfig == null || _isLoadingCountry) {
      return const SizedBox.shrink();
    }

    final config = _cardConfig!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = widget.isMobile || screenWidth < 600;

    final price = widget.training.getPriceForCurrency(_countryCode);
    final symbol = TrainingModel.getCurrencySymbol(_countryCode);
    final finalPrice = widget.training.getFinalPriceForCurrency(_countryCode);
    final hasDiscount = widget.training.hasDiscount;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobileDevice = widget.isMobile || MediaQuery.of(context).size.width < 600;
        
        final cardWidth = constraints.maxWidth > 0 
            ? constraints.maxWidth 
            : (isMobileDevice ? 210.0 : 210.0);

        final cardHeight = constraints.maxHeight > 0
            ? constraints.maxHeight
            : (isMobileDevice ? 310.0 : 320.0);

        final title = widget.isArabic ? widget.training.titleAr : widget.training.titleFr;
        final imageUrl = _getValidImageUrl(widget.training.imageUrl);

        final durationDisplay = widget.training.typeDuree.isNotEmpty
            ? widget.training.typeDuree
            : 'Durée non définie';

        final periodDisplay = widget.training.dateDebut.isNotEmpty &&
                widget.training.dateFin.isNotEmpty
            ? '${widget.training.dateDebut} - ${widget.training.dateFin}'
            : widget.training.period;

        final typeDisplay = widget.training.typeFormation.isNotEmpty
            ? widget.training.typeFormation
            : 'Formation';

        // ✅ MOBILE : Style Reel (tout superposé sur l'image)
        if (isMobileDevice) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FormationDetailPage(
                    formationId: widget.training.id.toString(),
                  ),
                ),
              );
            },
            child: SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // ✅ IMAGE EN PLEIN ÉCRAN
                    _buildImage(imageUrl),

                    // ✅ GRADIENT NOIR POUR LISIBILITÉ
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.2),
                            Colors.black.withOpacity(0.8),
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),

                    // ✅ BADGE DE RÉDUCTION EN HAUT
                    if (hasDiscount && widget.training.discountValue != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.red, Colors.redAccent],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.training.getDiscountText(widget.isArabic),
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 8,
                            ),
                          ),
                        ),
                      ),

                    // ✅ TYPE DE FORMATION EN HAUT GAUCHE
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          typeDisplay,
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    // ✅ TOUT LE TEXTE EN BAS (superposé sur l'image)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Titre
                          Text(
                            title,
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),

                          // Durée
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 12,
                                color: Colors.white.withOpacity(0.8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                durationDisplay,
                                style: GoogleFonts.cairo(
                                  fontSize: 10,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),

                          // Période
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 12,
                                color: Colors.white.withOpacity(0.8),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  periodDisplay,
                                  style: GoogleFonts.cairo(
                                    fontSize: 10,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          // Cible
                          if (widget.training.target.isNotEmpty) ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.people_outline_rounded,
                                  size: 12,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    widget.training.target,
                                    style: GoogleFonts.cairo(
                                      fontSize: 10,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // Formateur
                          if (widget.training.trainer.isNotEmpty) ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline_rounded,
                                  size: 12,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    widget.training.trainer,
                                    style: GoogleFonts.cairo(
                                      fontSize: 10,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // Catégorie
                          if (widget.isArabic 
                              ? widget.training.categorieAr.isNotEmpty 
                              : widget.training.categorieFr.isNotEmpty) ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.category_outlined,
                                  size: 12,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    widget.isArabic
                                        ? widget.training.categorieAr
                                        : widget.training.categorieFr,
                                    style: GoogleFonts.cairo(
                                      fontSize: 10,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 6),

                          // PRIX + BOUTON
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Prix
                              Row(
                                children: [
                                  if (hasDiscount && widget.training.discountValue != null)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Text(
                                        '${price.toInt()} $symbol',
                                        style: GoogleFonts.cairo(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w400,
                                          decoration: TextDecoration.lineThrough,
                                          color: Colors.white.withOpacity(0.6),
                                        ),
                                      ),
                                    ),
                                  Text(
                                    '${finalPrice.toInt()} $symbol',
                                    style: GoogleFonts.cairo(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),

                              // Flèche circulaire
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  widget.isArabic
                                      ? Icons.arrow_back_rounded
                                      : Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // ✅ DESKTOP : Style classique (280x320)
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FormationDetailPage(
                    formationId: widget.training.id.toString(),
                  ),
                ),
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: cardWidth,
              height: cardHeight,
              transform: isHovered
                  ? Matrix4.translationValues(0.0, -4.0, 0.0)
                  : Matrix4.identity(),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isHovered
                      ? const Color(0xffd57653)
                      : const Color(0xffd57653).withOpacity(0.05),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isHovered
                        ? const Color(0xff994a2b).withOpacity(0.12)
                        : Colors.black.withOpacity(0.04),
                    blurRadius: isHovered ? 20 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image (48% de la hauteur)
                  SizedBox(
                    height: 320 * 0.48,
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildImage(imageUrl),
                          if (hasDiscount && widget.training.discountValue != null)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.red, Colors.redAccent],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  widget.training.getDiscountText(widget.isArabic),
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 8,
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                typeDisplay,
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Informations en dessous
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (config.visibleFields.contains('title'))
                              Text(
                                title,
                                style: GoogleFonts.getFont(
                                  _extractFontFamily(config.titleFontFamily),
                                  fontSize: config.titleFontSize,
                                  fontWeight: config.titleFontWeight,
                                  color: config.titleColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            const SizedBox(height: 3),
                            if (config.visibleFields.contains('duration'))
                              _buildInfoRowWithConfig(
                                Icons.access_time_rounded,
                                widget.isArabic ? 'المدة : ' : 'Durée : ',
                                durationDisplay,
                                config,
                              ),
                            if (config.visibleFields.contains('period'))
                              _buildInfoRowWithConfig(
                                Icons.calendar_today_rounded,
                                widget.isArabic ? 'الفترة : ' : 'Période : ',
                                periodDisplay,
                                config,
                              ),
                            if (config.visibleFields.contains('target'))
                              _buildInfoRowWithConfig(
                                Icons.people_outline_rounded,
                                widget.isArabic ? 'الجمهور : ' : 'Cible : ',
                                widget.training.target,
                                config,
                              ),
                            if (config.visibleFields.contains('trainer'))
                              _buildInfoRowWithConfig(
                                Icons.person_outline_rounded,
                                widget.isArabic ? 'المكون : ' : 'Formateur : ',
                                widget.training.trainer,
                                config,
                              ),
                            if (config.visibleFields.contains('category'))
                              _buildInfoRowWithConfig(
                                Icons.category_outlined,
                                widget.isArabic ? 'التصنيف : ' : 'Catégorie : ',
                                widget.isArabic
                                    ? widget.training.categorieAr
                                    : widget.training.categorieFr,
                                config,
                              ),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.only(top: 4, bottom: 2),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  if (config.visibleFields.contains('duration'))
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 12,
                                          color: const Color(0xffd57653),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          durationDisplay,
                                          style: GoogleFonts.cairo(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xffd57653),
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (config.visibleFields.contains('price'))
                                    Row(
                                      children: [
                                        if (hasDiscount &&
                                            widget.training.discountValue != null)
                                          Padding(
                                            padding: const EdgeInsets.only(right: 4),
                                            child: Text(
                                              '${price.toInt()} $symbol',
                                              style: GoogleFonts.cairo(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w400,
                                                decoration: TextDecoration.lineThrough,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                          ),
                                        Text(
                                          '${finalPrice.toInt()} $symbol',
                                          style: GoogleFonts.cairo(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xffd57653),
                                          ),
                                        ),
                                      ],
                                    ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: isHovered
                                          ? const Color(0xffd57653)
                                          : const Color(0xffd57653).withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      widget.isArabic
                                          ? Icons.arrow_back_rounded
                                          : Icons.arrow_forward_rounded,
                                      color: isHovered ? Colors.white : const Color(0xffd57653),
                                      size: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRowWithConfig(
    IconData icon,
    String label,
    String value,
    CardConfig config,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          Icon(icon, size: 10, color: const Color(0xffd57653)),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.getFont(
                _extractFontFamily(config.labelFontFamily),
                fontSize: config.labelFontSize - 2,
                fontWeight: config.labelFontWeight,
                color: config.labelColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.getFont(
                _extractFontFamily(config.valueFontFamily),
                fontSize: config.valueFontSize - 2,
                fontWeight: config.valueFontWeight,
                color: config.valueColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.startsWith('assets/')) {
      final cleanPath = imageUrl.replaceFirst('assets/', '');
      return Image.asset(
        cleanPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: const Color(0xfff5f0ee),
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              color: const Color(0xffd57653),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        final fallbackUrl =
            'https://picsum.photos/seed/${widget.training.id}/800/450';
        if (imageUrl != fallbackUrl) {
          return Image.network(
            fallbackUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
          );
        }
        return _buildErrorWidget();
      },
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: const Color(0xfff5f0ee),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 30,
            color: const Color(0xffd57653).withOpacity(0.5),
          ),
          const SizedBox(height: 4),
          Text(
            widget.isArabic ? 'صورة غير متوفرة' : 'Image non disponible',
            style: GoogleFonts.cairo(
              fontSize: 10,
              color: const Color(0xff7c6e68).withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}