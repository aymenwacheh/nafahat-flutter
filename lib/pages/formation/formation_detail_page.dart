// lib/pages/formation/formation_detail_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafahat/models/training_model.dart';
import 'package:nafahat/services/training_service.dart';

class FormationDetailPage extends StatefulWidget {
  final String formationId;

  const FormationDetailPage({super.key, required this.formationId});

  @override
  State<FormationDetailPage> createState() => _FormationDetailPageState();
}

class _FormationDetailPageState extends State<FormationDetailPage> {
  TrainingModel? _training;
  bool _isLoading = true;
  bool _isArabic = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFormation();
  }

  Future<void> _loadFormation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final trainings = await TrainingService.getTrainings();
      final found = trainings.firstWhere(
        (t) => t.id == widget.formationId,
        orElse: () => throw Exception('Formation non trouvée'),
      );

      setState(() {
        _training = found;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xfffcfbfa),
      body: SafeArea(
        child: Stack(
          children: [
            // ✅ Contenu principal
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Color(0xffd57653)),
              )
            else if (_errorMessage != null)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
                    const SizedBox(height: 16),
                    Text(
                      _isArabic
                          ? 'Erreur de chargement'
                          : 'Erreur de chargement',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.red[400],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: GoogleFonts.poppins(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadFormation,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffd57653),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
            else if (_training == null)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 80,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isArabic ? 'التكوين غير موجود' : 'Formation non trouvée',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            else
              _buildDetailContent(isMobile),

            // ✅ Bouton retour
            Positioned(
              top: 16,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xff2c221e),
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailContent(bool isMobile) {
    final training = _training!;
    final title = _isArabic ? training.titleAr : training.titleFr;
    final description =
        _isArabic ? training.descriptionAr : training.descriptionFr;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Image de couverture
          _buildCoverImage(training, isMobile),

          // ✅ Contenu
          Padding(
            padding: EdgeInsets.all(isMobile ? 20 : 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Badges
                _buildBadges(training),

                const SizedBox(height: 16),

                // ✅ Titre
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 24 : 32,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xff2c221e),
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 12),

                // ✅ Description
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 15 : 17,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xff7c6e68),
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 32),

                // ✅ Informations détaillées
                _buildInfoSection(training, isMobile),

                const SizedBox(height: 32),

                // ✅ Call to Action - Payer
                _buildPaymentSection(training, isMobile),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage(TrainingModel training, bool isMobile) {
    String imageUrl = training.imageUrl;
    if (imageUrl.contains('C:\\') || imageUrl.contains('assets/')) {
      imageUrl = 'assets/images/${imageUrl.split('/').last}';
    }
    if (imageUrl.isEmpty ||
        imageUrl.startsWith('file://') ||
        (!imageUrl.startsWith('assets/') && !imageUrl.startsWith('http'))) {
      imageUrl = 'https://picsum.photos/seed/${training.id}/1200/500';
    }

    return Container(
      height: isMobile ? 250 : 400,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        image:
            imageUrl.startsWith('assets/')
                ? DecorationImage(
                  image: AssetImage(imageUrl),
                  fit: BoxFit.cover,
                )
                : DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
          ),
        ),
      ),
    );
  }

  Widget _buildBadges(TrainingModel training) {
    // ✅ Utilisation des nouveaux champs
    final typeDisplay =
        training.typeFormation.isNotEmpty
            ? training.typeFormation
            : 'Formation';
    final discountText =
        training.hasDiscount ? training.getDiscountText(_isArabic) : null;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // ✅ Type de formation
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xffd57653).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.school_outlined,
                size: 14,
                color: Color(0xffd57653),
              ),
              const SizedBox(width: 4),
              Text(
                typeDisplay,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xffd57653),
                ),
              ),
            ],
          ),
        ),

        // ✅ Catégorie
        if (training.categorieFr.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xff0D443E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.category_outlined,
                  size: 14,
                  color: Color(0xff0D443E),
                ),
                const SizedBox(width: 4),
                Text(
                  _isArabic ? training.categorieAr : training.categorieFr,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff0D443E),
                  ),
                ),
              ],
            ),
          ),

        // ✅ Réduction
        if (discountText != null && discountText.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_offer_outlined,
                  size: 14,
                  color: Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  discountText,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInfoSection(TrainingModel training, bool isMobile) {
    // ✅ Utilisation des nouveaux champs
    final dureeDisplay =
        training.typeDuree.isNotEmpty ? training.typeDuree : 'Non définie';

    // Période : on privilégie les dates si elles existent, sinon on utilise le champ period
    String periodeDisplay = '';
    if (training.dateDebut.isNotEmpty && training.dateFin.isNotEmpty) {
      periodeDisplay = '${training.dateDebut} → ${training.dateFin}';
    } else if (training.period.isNotEmpty) {
      periodeDisplay = training.period;
    } else {
      periodeDisplay = 'Non définie';
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffd57653).withOpacity(0.1)),
      ),
      child: Column(
        children: [
          // ✅ Ligne 1: Formateur
          _buildInfoRow(
            icon: Icons.person_outline_rounded,
            label: _isArabic ? 'المكون' : 'Formateur',
            value: training.trainer,
          ),
          const Divider(height: 24),

          // ✅ Ligne 2: Période
          _buildInfoRow(
            icon: Icons.calendar_today_rounded,
            label: _isArabic ? 'الفترة' : 'Période',
            value: periodeDisplay,
          ),
          const Divider(height: 24),

          // ✅ Ligne 3: Durée
          _buildInfoRow(
            icon: Icons.access_time_rounded,
            label: _isArabic ? 'المدة' : 'Durée',
            value: dureeDisplay,
          ),
          const Divider(height: 24),

          // ✅ Ligne 4: Cible
          _buildInfoRow(
            icon: Icons.people_outline_rounded,
            label: _isArabic ? 'الجمهور المستهدف' : 'Public cible',
            value: training.target,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xffd57653).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: const Color(0xffd57653)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xff7c6e68),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff2c221e),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSection(TrainingModel training, bool isMobile) {
    final hasDiscount = training.hasDiscount && training.discountValue != null;
    final originalPrice = training.price;
    final finalPrice = training.finalPrice;

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xffd57653).withOpacity(0.05),
            const Color(0xffd57653).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffd57653).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // ✅ Prix
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (hasDiscount) ...[
                Text(
                  '${originalPrice.toInt()} DH',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Text(
                '${finalPrice.toInt()} DH',
                style: GoogleFonts.poppins(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xffd57653),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'TTC',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xff7c6e68),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ✅ Informations supplémentaires
          if (hasDiscount)
            Text(
              _isArabic
                  ? 'Économisez ${training.discountValue?.toInt()} DH !'
                  : 'Économisez ${training.discountValue?.toInt()} DH !',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),

          const SizedBox(height: 20),

          // ✅ Bouton d'inscription
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _showPaymentDialog(context, training);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffd57653),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: Text(
                _isArabic ? '💰 التسجيل الآن' : '💰 S\'inscrire maintenant',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ✅ Message de confiance
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 16,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                _isArabic ? 'Paiement sécurisé' : 'Paiement sécurisé',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.support_agent_outlined,
                size: 16,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                _isArabic ? 'Support 7j/7' : 'Support 7j/7',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, TrainingModel training) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                const Icon(Icons.payment, color: Color(0xffd57653), size: 28),
                const SizedBox(width: 12),
                Text(
                  _isArabic
                      ? '📋 Résumé de la commande'
                      : '📋 Résumé de la commande',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isArabic ? 'Formation :' : 'Formation :',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  _isArabic ? training.titleAr : training.titleFr,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isArabic ? 'Total' : 'Total',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${training.finalPrice.toInt()} DH',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xffd57653),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  _isArabic ? 'Annuler' : 'Annuler',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showPaymentSuccess(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffd57653),
                  foregroundColor: Colors.white,
                ),
                child: Text(_isArabic ? '💰 Payer' : '💰 Payer'),
              ),
            ],
          ),
    );
  }

  void _showPaymentSuccess(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isArabic
                      ? '✅ Inscription réussie !'
                      : '✅ Inscription réussie !',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isArabic
                      ? 'Vous recevrez un email de confirmation'
                      : 'Vous recevrez un email de confirmation',
                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Retour à la page de détail
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffd57653),
                  foregroundColor: Colors.white,
                ),
                child: Text(_isArabic ? 'OK' : 'OK'),
              ),
            ],
          ),
    );
  }
}
