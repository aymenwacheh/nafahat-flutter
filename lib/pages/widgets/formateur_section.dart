// lib/pages/landing/widgets/formateur_section.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafahat/services/formateur_card_config_manager.dart';
import 'package:nafahat/services/training_service.dart';

class FormateurCard extends StatefulWidget {
  final Map<String, dynamic> formateur;
  final bool isArabic;

  const FormateurCard({
    super.key,
    required this.formateur,
    required this.isArabic,
  });

  @override
  State<FormateurCard> createState() => _FormateurCardState();
}

class _FormateurCardState extends State<FormateurCard> {
  late FormateurCardConfigManager _configManager;
  bool _isConfigLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    _configManager = FormateurCardConfigManager();
    await _configManager.loadConfig();
    setState(() {
      _isConfigLoaded = true;
    });
  }

  String _extractFontFamily(String fontWithVariant) {
    if (fontWithVariant.contains('-')) {
      return fontWithVariant.split('-').first;
    }
    return fontWithVariant;
  }

  TextStyle _getNameStyle() {
    if (!_isConfigLoaded) {
      return GoogleFonts.cairo(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: const Color(0xff2c221e),
      );
    }
    final family = _extractFontFamily(_configManager.getNameFontFamily());
    return GoogleFonts.getFont(
      family,
      fontSize: _configManager.getNameFontSize(),
      fontWeight: _configManager.getNameFontWeight(),
      color: _configManager.getNameColor(),
    );
  }

  TextStyle _getFieldsStyle() {
    if (!_isConfigLoaded) {
      return GoogleFonts.cairo(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.grey[700],
      );
    }
    final family = _extractFontFamily(_configManager.getFieldsFontFamily());
    return GoogleFonts.getFont(
      family,
      fontSize: _configManager.getFieldsFontSize(),
      fontWeight: _configManager.getFieldsFontWeight(),
      color: _configManager.getFieldsColor(),
    );
  }

  bool _isFieldVisible(String fieldId) {
    if (!_isConfigLoaded) return true;
    return _configManager.visibleFields.contains(fieldId);
  }

  String _getNom() {
    return widget.isArabic
        ? (widget.formateur['nom_prenom_ar'] ??
            widget.formateur['nom_prenom_fr'] ??
            'Formateur')
        : (widget.formateur['nom_prenom_fr'] ??
            widget.formateur['nom_prenom_ar'] ??
            'Formateur');
  }

  String _getSpecialite() {
    return widget.isArabic
        ? (widget.formateur['categorie_ar'] ??
            widget.formateur['categorie_fr'] ??
            '')
        : (widget.formateur['categorie_fr'] ??
            widget.formateur['categorie_ar'] ??
            '');
  }

  String _getBio() {
    return widget.isArabic
        ? (widget.formateur['bio_ar'] ?? widget.formateur['bio_fr'] ?? '')
        : (widget.formateur['bio_fr'] ?? widget.formateur['bio_ar'] ?? '');
  }

  String _getPhotoUrl() {
    final photo = widget.formateur['photo'] ?? '';
    if (photo.isNotEmpty && photo != 'null') {
      return '${TrainingService.apiBaseUrl.replaceAll('/api', '')}/uploads/formateurs/$photo';
    }
    return '';
  }

  String _getRating() {
    final note = widget.formateur['note'];
    if (note == null) return '4.5 ★';

    if (note is int) {
      return '${note.toDouble().toStringAsFixed(1)} ★';
    } else if (note is double) {
      return '${note.toStringAsFixed(1)} ★';
    } else if (note is String) {
      return '$note ★';
    }
    return '4.5 ★';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    // ✅ CORRECTION : utiliser des doubles
    final photoSize = isMobile ? 60.0 : 80.0; // ← Ajout de .0 pour être double

    final photoUrl = _getPhotoUrl();
    final nom = _getNom();
    final specialite = _getSpecialite();
    final bio = _getBio();

    return Container(
      padding: EdgeInsets.all(isMobile ? 8.0 : 12.0), // ← Ajout de .0
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Photo
          Container(
            width: photoSize,
            height: photoSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xffd57653).withOpacity(0.1),
            ),
            child: ClipOval(
              child:
                  photoUrl.isNotEmpty
                      ? Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholder(photoSize);
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
                              color: const Color(0xffd57653),
                            ),
                          );
                        },
                      )
                      : _buildPlaceholder(photoSize),
            ),
          ),
          const SizedBox(height: 8),

          // NOM
          if (_isFieldVisible('name'))
            Text(
              nom,
              style: _getNameStyle(),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

          // SPÉCIALITÉ
          if (_isFieldVisible('speciality') && specialite.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.psychology,
                    size: 12,
                    color:
                        _isConfigLoaded
                            ? _configManager.getFieldsColor()
                            : Colors.grey[700],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      specialite,
                      style: _getFieldsStyle(),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // EXPÉRIENCE / BIO
          if (_isFieldVisible('experience') && bio.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.work,
                    size: 12,
                    color:
                        _isConfigLoaded
                            ? _configManager.getFieldsColor()
                            : Colors.grey[700],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      bio.length > 25 ? '${bio.substring(0, 25)}...' : bio,
                      style: _getFieldsStyle(),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // NOTE
          if (_isFieldVisible('rating') && widget.formateur['note'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star,
                    size: 12,
                    color:
                        _isConfigLoaded
                            ? _configManager.getFieldsColor()
                            : Colors.grey[700],
                  ),
                  const SizedBox(width: 4),
                  Text(_getRating(), style: _getFieldsStyle()),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(double size) {
    return Container(
      color: const Color(0xffd57653).withOpacity(0.1),
      child: Center(
        child: Icon(
          Icons.person,
          size: size * 0.5,
          color: const Color(0xffd57653).withOpacity(0.4),
        ),
      ),
    );
  }
}
