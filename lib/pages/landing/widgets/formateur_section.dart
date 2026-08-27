// lib/pages/landing/widgets/formateur_detail_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FormateurDetailPage extends StatelessWidget {
  final Map<String, dynamic> formateur;
  final bool isArabic;

  const FormateurDetailPage({
    super.key,
    required this.formateur,
    required this.isArabic,
  });

  static const Color primary = Color(0xffd57653);
  static const Color textDark = Color(0xff2c221e);

  String _getNom() {
    return isArabic
        ? (formateur['nom_prenom_ar'] ??
            formateur['nom_prenom_fr'] ??
            'Formateur')
        : (formateur['nom_prenom_fr'] ??
            formateur['nom_prenom_ar'] ??
            'Formateur');
  }

  String _getPhoto() {
    final photo = formateur['photo'] ?? '';
    if (photo.isNotEmpty && photo != 'null') {
      return photo;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.transparent, // Fond transparent
      body: Center(
        child: Container(
          width: isMobile ? double.infinity : 350, // Largeur fixe sur desktop
          padding: EdgeInsets.all(isMobile ? 24 : 32),
          decoration: BoxDecoration(
            color: Colors.white, // Carte blanche
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ Photo en cercle
              Container(
                width: isMobile ? 140 : 160,
                height: isMobile ? 140 : 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withOpacity(
                    0.1,
                  ), // Fond légèrement coloré si pas de photo
                ),
                child: ClipOval(child: _buildPhoto()),
              ),
              const SizedBox(height: 20),

              // ✅ Nom
              Text(
                _getNom(),
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 22 : 26,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto() {
    final photoUrl = _getPhoto();

    if (photoUrl.isNotEmpty) {
      return Image.network(
        photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value:
                  loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
              strokeWidth: 2,
              color: primary,
            ),
          );
        },
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: primary.withOpacity(0.1),
      child: Center(
        child: Icon(Icons.person, size: 60, color: primary.withOpacity(0.4)),
      ),
    );
  }
}
