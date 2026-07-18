// lib/widgets/training_card.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafahat/pages/adminisration/apparence_card.dart';
import 'package:nafahat/models/training_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nafahat/pages/formation/formation_detail_page.dart';
import 'package:nafahat/services/card_config_manager.dart';

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

  @override
  void initState() {
    super.initState();
    _configNotifier = CardConfigManager().configNotifier;
    _loadCardConfig();
    _configNotifier.addListener(_onConfigChanged);
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
    if (imageUrl.contains('C:\\') || imageUrl.contains('\\')) {
      String fileName = imageUrl.split('\\').last;
      return 'assets/images/$fileName';
    }
    if (imageUrl.contains('/') && imageUrl.startsWith('assets/')) {
      return imageUrl;
    }
    if (imageUrl.isEmpty ||
        imageUrl.startsWith('file://') ||
        imageUrl.startsWith('C:') ||
        (!imageUrl.startsWith('assets/') && !imageUrl.startsWith('http'))) {
      return 'https://picsum.photos/seed/${widget.training.id}/800/450';
    }
    return imageUrl;
  }

  @override
  Widget build(BuildContext context) {
    if (_cardConfig == null) {
      return const SizedBox.shrink();
    }

    final config = _cardConfig!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = widget.isMobile || screenWidth < 600;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            constraints.maxWidth > 0 ? constraints.maxWidth : 320.0;

        // ✅ Ajustement pour mobile : hauteur plus petite
        final cardHeight =
            constraints.maxHeight > 0
                ? constraints.maxHeight
                : (isMobile ? 340.0 : 420.0); // 👈 Réduit de 360 à 340

        // ✅ Ajustement des proportions
        final imageHeight = isMobile ? cardHeight * 0.50 : cardHeight * 0.52;
        final contentHeight = cardHeight - imageHeight;

        final title =
            widget.isArabic ? widget.training.titleAr : widget.training.titleFr;
        final description =
            widget.isArabic
                ? widget.training.descriptionAr
                : widget.training.descriptionFr;

        final imageUrl = _getValidImageUrl(widget.training.imageUrl);

        final durationDisplay =
            widget.training.typeDuree.isNotEmpty
                ? widget.training.typeDuree
                : 'Durée non définie';

        final periodDisplay =
            widget.training.dateDebut.isNotEmpty &&
                    widget.training.dateFin.isNotEmpty
                ? '${widget.training.dateDebut} - ${widget.training.dateFin}'
                : widget.training.period;

        final typeDisplay =
            widget.training.typeFormation.isNotEmpty
                ? widget.training.typeFormation
                : 'Formation';

        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          FormationDetailPage(formationId: widget.training.id),
                ),
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: cardWidth,
              height: cardHeight,
              transform:
                  isHovered && !isMobile
                      ? Matrix4.translationValues(0.0, -4.0, 0.0)
                      : Matrix4.identity(),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isHovered
                          ? const Color(0xffd57653)
                          : const Color(0xffd57653).withOpacity(0.05),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        isHovered
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
                  // Image
                  SizedBox(
                    height: imageHeight,
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildImage(imageUrl),
                          if (widget.training.hasDiscount &&
                              widget.training.discountValue != null)
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
                                  widget.training.getDiscountText(
                                    widget.isArabic,
                                  ),
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isMobile ? 7 : 9,
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
                                  fontSize: isMobile ? 7 : 9,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Contenu
                  SizedBox(
                    height: contentHeight,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : 10,
                        vertical: isMobile ? 4 : 6,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Titre et description
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Titre avec configuration
                              if (config.visibleFields.contains('title'))
                                Text(
                                  title,
                                  style: GoogleFonts.getFont(
                                    _extractFontFamily(config.titleFontFamily),
                                    fontSize:
                                        isMobile
                                            ? config.titleFontSize - 4
                                            : config.titleFontSize,
                                    fontWeight: config.titleFontWeight,
                                    color: config.titleColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 1),
                              Text(
                                description,
                                style: GoogleFonts.cairo(
                                  fontSize: isMobile ? 7 : 10,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xff7c6e68),
                                  height: 1.1,
                                ),
                                maxLines: isMobile ? 1 : 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),

                          // Informations avec configuration - Réduit pour mobile
                          if (!isMobile ||
                              config.visibleFields
                                      .where(
                                        (f) => [
                                          'duration',
                                          'period',
                                          'target',
                                          'trainer',
                                          'category',
                                        ].contains(f),
                                      )
                                      .length <=
                                  3) ...[
                            Column(
                              children: [
                                if (config.visibleFields.contains('duration'))
                                  _buildInfoRowWithConfig(
                                    Icons.access_time_rounded,
                                    widget.isArabic ? 'المدة : ' : 'Durée : ',
                                    durationDisplay,
                                    isMobile,
                                    config,
                                  ),
                                if (config.visibleFields.contains('period') &&
                                    !isMobile)
                                  _buildInfoRowWithConfig(
                                    Icons.calendar_today_rounded,
                                    widget.isArabic
                                        ? 'الفترة : '
                                        : 'Période : ',
                                    periodDisplay,
                                    isMobile,
                                    config,
                                  ),
                                if (config.visibleFields.contains('target') &&
                                    !isMobile)
                                  _buildInfoRowWithConfig(
                                    Icons.people_outline_rounded,
                                    widget.isArabic ? 'الجمهور : ' : 'Cible : ',
                                    widget.training.target,
                                    isMobile,
                                    config,
                                  ),
                                if (config.visibleFields.contains('trainer') &&
                                    !isMobile)
                                  _buildInfoRowWithConfig(
                                    Icons.person_outline_rounded,
                                    widget.isArabic
                                        ? 'المكون : '
                                        : 'Formateur : ',
                                    widget.training.trainer,
                                    isMobile,
                                    config,
                                  ),
                                if (config.visibleFields.contains('category') &&
                                    !isMobile)
                                  _buildInfoRowWithConfig(
                                    Icons.category_outlined,
                                    widget.isArabic
                                        ? 'التصنيف : '
                                        : 'Catégorie : ',
                                    widget.isArabic
                                        ? widget.training.categorieAr
                                        : widget.training.categorieFr,
                                    isMobile,
                                    config,
                                  ),
                              ],
                            ),
                          ],

                          // Bas de carte
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (config.visibleFields.contains('duration') &&
                                  !isMobile)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: isMobile ? 10 : 12,
                                      color: const Color(0xffd57653),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      durationDisplay,
                                      style: GoogleFonts.cairo(
                                        fontSize: isMobile ? 8 : 10,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xffd57653),
                                      ),
                                    ),
                                  ],
                                ),
                              if (config.visibleFields.contains('price'))
                                Row(
                                  children: [
                                    if (widget.training.hasDiscount &&
                                        widget.training.discountValue != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 3,
                                        ),
                                        child: Text(
                                          '${widget.training.price.toInt()} DH',
                                          style: GoogleFonts.cairo(
                                            fontSize: isMobile ? 7 : 9,
                                            fontWeight: FontWeight.w400,
                                            decoration:
                                                TextDecoration.lineThrough,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      '${widget.training.finalPrice.toInt()} DH',
                                      style: GoogleFonts.cairo(
                                        fontSize: isMobile ? 12 : 13,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xffd57653),
                                      ),
                                    ),
                                  ],
                                ),
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xffd57653,
                                  ).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  widget.isArabic
                                      ? Icons.arrow_back_rounded
                                      : Icons.arrow_forward_rounded,
                                  color: const Color(0xffd57653),
                                  size: isMobile ? 10 : 12,
                                ),
                              ),
                            ],
                          ),
                        ],
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
    bool isMobile,
    CardConfig config,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 0.5 : 0.5),
      child: Row(
        children: [
          Icon(icon, size: isMobile ? 8 : 10, color: const Color(0xffd57653)),
          const SizedBox(width: 2),
          Text(
            label,
            style: GoogleFonts.getFont(
              _extractFontFamily(config.labelFontFamily),
              fontSize:
                  isMobile ? config.labelFontSize - 2 : config.labelFontSize,
              fontWeight: config.labelFontWeight,
              color: config.labelColor,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.getFont(
                _extractFontFamily(config.valueFontFamily),
                fontSize:
                    isMobile ? config.valueFontSize - 2 : config.valueFontSize,
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
      return Image.asset(
        imageUrl,
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
              value:
                  loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
              color: const Color(0xffd57653),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
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
