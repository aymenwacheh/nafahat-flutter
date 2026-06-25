// lib/widgets/training_card.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TrainingCard extends StatefulWidget {
  final String title;
  final String description;
  final String duration;
  final String trainer;
  final String target;
  final String period;
  final String imageUrl;
  final String formationId;
  final bool isArabic;
  final double? price;
  final bool? hasDiscount;
  final double? discountValue;
  final bool isMobile; // ✅ Nouveau paramètre

  const TrainingCard({
    super.key,
    required this.title,
    required this.description,
    required this.duration,
    required this.trainer,
    required this.target,
    required this.period,
    required this.imageUrl,
    required this.formationId,
    required this.isArabic,
    this.price,
    this.hasDiscount,
    this.discountValue,
    this.isMobile = false, // ✅ Valeur par défaut
  });

  @override
  State<TrainingCard> createState() => _TrainingCardState();
}

class _TrainingCardState extends State<TrainingCard> {
  bool isHovered = false;

  void _navigateToDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TrainingDetailPage(formationId: widget.formationId),
      ),
    );
  }

  String _extractFileName(String path) {
    if (path.contains('\\')) {
      return path.split('\\').last;
    } else if (path.contains('/')) {
      return path.split('/').last;
    }
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = widget.isMobile || screenWidth < 600;

    // ✅ La carte utilise LayoutBuilder pour s'adapter à son conteneur
    return LayoutBuilder(
      builder: (context, constraints) {
        // ✅ Dimensions calculées dynamiquement
        final cardWidth =
            constraints.maxWidth > 0 ? constraints.maxWidth : 320.0;
        final cardHeight =
            constraints.maxHeight > 0
                ? constraints.maxHeight
                : (isMobile ? 380.0 : 440.0);

        final imageHeight = cardHeight * 0.55;
        final contentHeight = cardHeight * 0.45;

        // ✅ Gestion de l'image
        String imageUrl = widget.imageUrl;
        if (imageUrl.contains('C:\\') || imageUrl.contains('assets/')) {
          String fileName = _extractFileName(imageUrl);
          imageUrl = 'assets/images/$fileName';
        }
        if (imageUrl.isEmpty ||
            imageUrl.startsWith('file://') ||
            (!imageUrl.startsWith('assets/') && !imageUrl.startsWith('http'))) {
          imageUrl = 'https://picsum.photos/seed/${widget.formationId}/800/450';
        }

        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: GestureDetector(
            onTap: _navigateToDetail,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: cardWidth,
              height: cardHeight,
              transform:
                  isHovered && !isMobile
                      ? (Matrix4.identity()..translate(0, -4))
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
                  // ✅ IMAGE (55% de la carte)
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
                          if (widget.hasDiscount == true &&
                              widget.discountValue != null)
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
                                  widget.isArabic ? 'خصم' : 'Promo',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isMobile ? 8 : 9,
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
                                widget.isArabic ? 'تكوين' : 'Formation',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: isMobile ? 8 : 9,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ✅ CONTENU (45% de la carte)
                  SizedBox(
                    height: contentHeight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Titre et description
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: GoogleFonts.poppins(
                                  fontSize: isMobile ? 13 : 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xff2c221e),
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.description,
                                style: GoogleFonts.poppins(
                                  fontSize: isMobile ? 9 : 10,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xff7c6e68),
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),

                          // Informations
                          Column(
                            children: [
                              _buildInfoRow(
                                Icons.person_outline_rounded,
                                widget.isArabic ? 'المكون : ' : 'Formateur : ',
                                widget.trainer,
                                isMobile,
                              ),
                              const SizedBox(height: 2),
                              _buildInfoRow(
                                Icons.calendar_today_rounded,
                                widget.isArabic ? 'الفترة : ' : 'Période : ',
                                widget.period,
                                isMobile,
                              ),
                              const SizedBox(height: 2),
                              _buildInfoRow(
                                Icons.people_outline_rounded,
                                widget.isArabic ? 'الجمهور : ' : 'Cible : ',
                                widget.target,
                                isMobile,
                              ),
                            ],
                          ),

                          // Bas de carte
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Durée
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: isMobile ? 10 : 12,
                                    color: const Color(0xffd57653),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.duration,
                                    style: GoogleFonts.poppins(
                                      fontSize: isMobile ? 9 : 10,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xffd57653),
                                    ),
                                  ),
                                ],
                              ),
                              // Prix
                              Row(
                                children: [
                                  if (widget.hasDiscount == true &&
                                      widget.discountValue != null)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Text(
                                        '${widget.price?.toInt() ?? 0} DH',
                                        style: GoogleFonts.poppins(
                                          fontSize: isMobile ? 8 : 9,
                                          fontWeight: FontWeight.w400,
                                          decoration:
                                              TextDecoration.lineThrough,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ),
                                  Text(
                                    '${_getFinalPrice().toInt()} DH',
                                    style: GoogleFonts.poppins(
                                      fontSize: isMobile ? 12 : 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xffd57653),
                                    ),
                                  ),
                                ],
                              ),
                              // Flèche
                              Container(
                                padding: const EdgeInsets.all(3),
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

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    bool isMobile,
  ) {
    return Row(
      children: [
        Icon(icon, size: isMobile ? 8 : 10, color: const Color(0xffd57653)),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 8 : 9,
            fontWeight: FontWeight.w600,
            color: const Color(0xff7c6e68),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 8 : 9,
              fontWeight: FontWeight.w500,
              color: const Color(0xff2c221e),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  double _getFinalPrice() {
    if (widget.hasDiscount == true && widget.discountValue != null) {
      return (widget.price ?? 0) - widget.discountValue!;
    }
    return widget.price ?? 0;
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
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: const Color(0xff7c6e68).withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// Page de détail
class TrainingDetailPage extends StatelessWidget {
  final String formationId;

  const TrainingDetailPage({super.key, required this.formationId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail de la formation'),
        backgroundColor: const Color(0xffd57653),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Formation ID: $formationId',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            const Text('Contenu détaillé de la formation à venir...'),
          ],
        ),
      ),
    );
  }
}
