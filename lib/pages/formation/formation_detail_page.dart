// lib/pages/formations/formation_detail_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafahat/models/training_model.dart';
import 'package:nafahat/pages/widgets/cart_popup.dart';
import 'package:nafahat/services/training_service.dart';
import 'package:nafahat/services/auth_service.dart';
import 'package:nafahat/services/geo_service.dart';
import 'package:nafahat/services/payment_service.dart';
import 'package:nafahat/services/cmpl_user_service.dart';
import 'package:nafahat/services/cart_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nafahat/pages/widgets/navbar.dart';
import 'package:nafahat/pages/widgets/chatbot/chatbot_wrapper.dart';
import 'package:nafahat/pages/users/auth_page.dart';
import 'package:nafahat/pages/users/cmpl_info_form.dart';
import 'package:nafahat/pages/paiement/modalite_paiment.dart';
import 'package:nafahat/providers/language_provider.dart';
import 'package:provider/provider.dart';

// ============================================================
// SIMILAR TRAINING CARD WIDGET
// ============================================================
class SimilarTrainingCard extends StatelessWidget {
  final TrainingModel training;
  final bool isArabic;
  final String countryCode;
  final VoidCallback onTap;

  const SimilarTrainingCard({
    super.key,
    required this.training,
    required this.isArabic,
    required this.countryCode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final price = training.getFinalPriceForCurrency(countryCode);
    final symbol = TrainingModel.getCurrencySymbol(countryCode);
    final title = isArabic ? training.titleAr : training.titleFr;
    final trainer = training.trainer;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  image: training.imageUrl.isNotEmpty &&
                          training.imageUrl.startsWith('http')
                      ? DecorationImage(
                          image: NetworkImage(training.imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: training.imageUrl.isEmpty ||
                        !training.imageUrl.startsWith('http')
                    ? Icon(Icons.school, color: Colors.grey[400], size: 40)
                    : null,
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xff2c221e),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 12,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          trainer,
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xffd57653).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${price.toStringAsFixed(0)} $symbol',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xffd57653),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: const Color(0xffd57653),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// MAIN PAGE
// ============================================================
class FormationDetailPage extends StatefulWidget {
  final String formationId;

  const FormationDetailPage({
    super.key,
    required this.formationId,
  });

  @override
  State<FormationDetailPage> createState() => _FormationDetailPageState();
}

class _FormationDetailPageState extends State<FormationDetailPage> {
  // ============================================================
  // ÉTATS
  // ============================================================

  TrainingModel? _training;
  List<TrainingModel> _similarTrainings = [];
  bool _isLoading = true;
  bool _isLoadingSimilar = true;
  String? _errorMessage;

  bool _isArabic = true;
  String _countryCode = 'TN';
  bool _isLoadingCountry = true;

  bool _isAuthenticated = false;
  Map<String, dynamic>? _userData;
  bool _isCheckingAuth = true;

  bool _isProcessingPayment = false;
  bool _isAddingToCart = false;
  String? _currentPaymentId;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ============================================================
  // CYCLE DE VIE
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadLanguage(),
      _detectCountry(),
      _checkAuthStatus(),
      _loadFormation(),
      _loadSimilarTrainings(),
    ]);
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLang = prefs.getString('language');
      setState(() {
        _isArabic = savedLang == 'ar' || savedLang == null;
      });
    } catch (e) {
      print('❌ [LANGUE] Erreur: $e');
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

  Future<void> _checkAuthStatus() async {
    setState(() => _isCheckingAuth = true);
    try {
      _isAuthenticated = await AuthService.isAuthenticated();
      if (_isAuthenticated) {
        _userData = await AuthService.getUserData();
      }
    } catch (e) {
      print('❌ [AUTH] Erreur: $e');
    } finally {
      if (mounted) setState(() => _isCheckingAuth = false);
    }
  }

  Future<void> _refreshAuthStatus() async {
    _isAuthenticated = await AuthService.isAuthenticated();
    if (_isAuthenticated) {
      _userData = await AuthService.getUserData();
    }
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

  Future<void> _loadSimilarTrainings() async {
    setState(() => _isLoadingSimilar = true);
    try {
      final allTrainings = await TrainingService.getTrainings();
      final filtered = allTrainings
          .where(
            (t) =>
                t.id != widget.formationId &&
                t.categorieId == _training?.categorieId,
          )
          .take(10)
          .toList();

      filtered.shuffle();

      setState(() {
        _similarTrainings = filtered.take(6).toList();
        _isLoadingSimilar = false;
      });
    } catch (e) {
      setState(() => _isLoadingSimilar = false);
    }
  }

  // ============================================================
  // GESTION DU PANIER
  // ============================================================

  Future<void> _handleAddToCart() async {
    if (_training == null) return;

    if (!_isAuthenticated) {
      final result = await Navigator.pushNamed(
        context,
        '/login',
        arguments: {'returnToPrevious': true},
      );
      if (!mounted) return;
      await _refreshAuthStatus();
      if (!_isAuthenticated) {
        _showSnackBar(
          _isArabic
              ? '❌ Veuillez vous connecter pour ajouter au panier'
              : '❌ Veuillez vous connecter pour ajouter au panier',
          Colors.orange,
        );
        return;
      }
    }

    _addToCart();
  }

  void _addToCart() {
    if (_training == null) return;

    setState(() => _isAddingToCart = true);

    final price = _training!.getFinalPriceForCurrency(_countryCode);
    final symbol = TrainingModel.getCurrencySymbol(_countryCode);

    final cartItem = {
      'formationId': _training!.id,
      'titleFr': _training!.titleFr,
      'titleAr': _training!.titleAr,
      'imageUrl': _training!.imageUrl,
      'price': price,
      'currency': _countryCode,
      'currencySymbol': symbol,
      'quantity': 1,
      'categorieId': _training!.categorieId,
      'trainer': _training!.trainer,
    };

    CartService.addItem(cartItem).then((_) {
      setState(() => _isAddingToCart = false);
      if (mounted) {
        final title = _isArabic ? _training!.titleAr : _training!.titleFr;
        _showSnackBarWithAction(
          _isArabic
              ? '✅ تم إضافة "$title" إلى السلة'
              : '✅ "$title" ajouté au panier',
          Colors.green,
          label: _isArabic ? 'عرض' : 'Voir',
          onPressed: () {
            showDialog(
              context: context,
              barrierDismissible: true,
              barrierColor: Colors.black.withOpacity(0.4),
              builder: (context) => const CartPopup(),
            );
          },
        );
        CartService.notifyCartUpdate();
      }
    }).catchError((error) {
      setState(() => _isAddingToCart = false);
      _showSnackBar(
        _isArabic ? '❌ Erreur lors de l\'ajout' : '❌ Erreur lors de l\'ajout',
        Colors.red,
      );
    });
  }

  // ============================================================
  // GESTION DE L'INSCRIPTION
  // ============================================================

  Future<void> _handleInscription() async {
    if (_training == null) return;

    setState(() => _isProcessingPayment = true);

    try {
      if (_isAuthenticated) {
        final userId = _userData?['id']?.toString() ??
            await AuthService.getUserIdForPayment();
        if (userId == null) throw Exception('ID utilisateur non trouvé');

        final adherentId = int.tryParse(userId);
        if (adherentId == null) throw Exception('ID utilisateur invalide');

        // Vérification CMPL pour formations religieuses
        if (_training!.categorieId == 1) {
          final cmplExists = await CmplUserService.checkCmplExists(
            adherentId: adherentId,
            formationId: int.parse(_training!.id),
          );
          if (!cmplExists) {
            setState(() => _isProcessingPayment = false);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CmplInfoForm(
                  adherentId: adherentId,
                  formationId: int.parse(_training!.id),
                  formation: _training,
                  onComplete: () async {
                    await _refreshAuthStatus();
                    _handleInscription();
                  },
                ),
              ),
            );
            return;
          }
        }

        await _proceedToPayment(userId);
      } else {
        setState(() => _isProcessingPayment = false);
        final result = await Navigator.pushNamed(
          context,
          '/login',
          arguments: {'returnToPrevious': true},
        );
        if (!mounted) return;
        await _refreshAuthStatus();
        if (_isAuthenticated) {
          setState(() => _isProcessingPayment = true);
          final userId = _userData?['id']?.toString() ??
              await AuthService.getUserIdForPayment();
          if (userId != null) {
            await _proceedToPayment(userId);
          }
        }
      }
    } catch (e) {
      _showSnackBar('❌ Erreur: $e', Colors.red);
      setState(() => _isProcessingPayment = false);
    }
  }

  Future<void> _proceedToPayment(String userId) async {
    if (_training == null) return;

    try {
      final currency = TrainingModel.getCurrencySymbol(_countryCode);
      final result = await PaymentService.initiatePayment(
        formationId: _training!.id,
        userId: userId,
        currency: currency,
      );

      if (result['success'] == true) {
        final paymentId = result['paymentId']?.toString();
        if (paymentId != null && paymentId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ModalitePaimentPage(
                paymentId: paymentId,
                formationId: _training!.id,
                userId: userId,
                currency: _countryCode,
              ),
            ),
          );
        } else {
          throw Exception('ID de paiement manquant');
        }
      } else {
        throw Exception(result['message'] ?? 'Erreur paiement');
      }
    } catch (e) {
      throw Exception(e);
    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }

  // ============================================================
  // SNACKBAR HELPERS
  // ============================================================

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSnackBarWithAction(
    String message,
    Color color, {
    required String label,
    required VoidCallback onPressed,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: GoogleFonts.cairo()),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: label,
          textColor: Colors.white,
          onPressed: onPressed,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return ChatbotWrapper(
      apiBaseUrl: 'http://localhost:3000',
      langue: _isArabic ? 'ar' : 'fr',
      primaryColor: const Color(0xffd57653),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xfffcfbfa),
        body: Column(
          children: [
            // ============================================================
            // NAVBAR (responsif mobile/web)
            // ============================================================
            Navbar(
              isMobile: isMobile,
              scaffoldKey: _scaffoldKey,
            ),
            // ============================================================
            // BODY CONTENT
            // ============================================================
            Expanded(
              child: _isLoading || _isLoadingCountry || _isCheckingAuth
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xffd57653),
                      ),
                    )
                  : _errorMessage != null
                      ? _buildErrorWidget()
                      : _training == null
                          ? _buildNotFoundWidget()
                          : SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ============================================================
                                  // HERO SECTION (sans informations superposées)
                                  // ============================================================
                                  _buildHeroSection(),
                                  // ============================================================
                                  // CONTENT SECTION
                                  // ============================================================
                                  _buildContentSection(),
                                  // ============================================================
                                  // SIMILAR TRAININGS
                                  // ============================================================
                                  _buildSimilarTrainingsSection(),
                                  const SizedBox(height: 40),
                                ],
                              ),
                            ),
            ),
          ],
        ),
        // Overlay de chargement
        floatingActionButton: (_isProcessingPayment || _isAddingToCart)
            ? Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: Color(0xffd57653),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isAddingToCart
                              ? (_isArabic
                                  ? '⏳ جاري الإضافة إلى السلة...'
                                  : '⏳ Ajout au panier...')
                              : (_isArabic
                                  ? '⏳ جاري تحضير الدفع...'
                                  : '⏳ Préparation du paiement...'),
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  // ============================================================
  // HERO SECTION (propre, sans informations au-dessus)
  // ============================================================

  Widget _buildHeroSection() {
    final training = _training!;
    final isMobile = MediaQuery.of(context).size.width < 600;

    String imageUrl = training.imageUrl;
    if (imageUrl.contains('C:\\') || imageUrl.contains('assets/')) {
      imageUrl = 'assets/images/${imageUrl.split('/').last}';
    }
    if (imageUrl.isEmpty ||
        imageUrl.startsWith('file://') ||
        (!imageUrl.startsWith('assets/') && !imageUrl.startsWith('http'))) {
      imageUrl = 'https://picsum.photos/seed/${training.id}/1200/500';
    }

    return Stack(
      children: [
        // Image de fond (PURE, sans texte)
        Container(
          height: isMobile ? 250 : 400,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            image: imageUrl.startsWith('assets/')
                ? DecorationImage(
                    image: AssetImage(imageUrl),
                    fit: BoxFit.cover,
                  )
                : DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        // Flèche de retour (en haut à gauche)
        Positioned(
          top: isMobile ? 12 : 20,
          left: isMobile ? 12 : 20,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () => Navigator.pop(context),
              tooltip: _isArabic ? 'رجوع' : 'Retour',
            ),
          ),
        ),
        // Gradient léger en bas pour la lisibilité (optionnel mais propre)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 60,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.2),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CONTENT SECTION
  // ============================================================

  Widget _buildContentSection() {
    final training = _training!;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final price = training.getPriceForCurrency(_countryCode);
    final symbol = TrainingModel.getCurrencySymbol(_countryCode);
    final finalPrice = training.getFinalPriceForCurrency(_countryCode);
    final hasDiscount = training.hasDiscount;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 60,
        vertical: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ============================================================
          // BADGES (catégorie, type, etc.)
          // ============================================================
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildBadge(
                icon: Icons.school_outlined,
                text: training.typeFormation.isNotEmpty
                    ? training.typeFormation
                    : 'Formation',
                color: const Color(0xffd57653),
              ),
              if (training.categorieFr.isNotEmpty)
                _buildBadge(
                  icon: Icons.category_outlined,
                  text: _isArabic ? training.categorieAr : training.categorieFr,
                  color: const Color(0xff0D443E),
                ),
              if (training.categorieId == 1)
                _buildBadge(
                  icon: Icons.mosque_outlined,
                  text: _isArabic ? 'دورة دينية' : 'Formation religieuse',
                  color: Colors.blue.shade700,
                ),
              if (training.hasDiscount)
                _buildBadge(
                  icon: Icons.local_offer_outlined,
                  text: training.getDiscountTextForCurrency(
                    _countryCode,
                    _isArabic,
                  ),
                  color: Colors.red,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // ============================================================
          // TITRE
          // ============================================================
          Text(
            _isArabic ? training.titleAr : training.titleFr,
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 26 : 36,
              fontWeight: FontWeight.w800,
              color: const Color(0xff2c221e),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),

          // ============================================================
          // FORMATEUR
          // ============================================================
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                training.trainer,
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 14 : 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ============================================================
          // DESCRIPTION
          // ============================================================
          Text(
            _isArabic ? training.descriptionAr : training.descriptionFr,
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 16 : 18,
              height: 1.8,
              color: const Color(0xff4a3f3a),
            ),
          ),
          const SizedBox(height: 32),

          // ============================================================
          // INFORMATIONS EN GRILLE
          // ============================================================
          _buildInfoGrid(training, isMobile),
          const SizedBox(height: 32),

          // ============================================================
          // SECTION PRIX ET ACTIONS
          // ============================================================
          _buildPriceActionSection(
            training,
            isMobile,
            price,
            symbol,
            finalPrice,
            hasDiscount,
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(TrainingModel training, bool isMobile) {
    final items = [
      {
        'icon': Icons.person_outline_rounded,
        'label': _isArabic ? 'المكون' : 'Formateur',
        'value': training.trainer,
      },
      {
        'icon': Icons.calendar_today_rounded,
        'label': _isArabic ? 'الفترة' : 'Période',
        'value': training.period.isNotEmpty
            ? training.period
            : '${training.dateDebut} → ${training.dateFin}',
      },
      {
        'icon': Icons.access_time_rounded,
        'label': _isArabic ? 'المدة' : 'Durée',
        'value': training.typeDuree.isNotEmpty ? training.typeDuree : 'Non définie',
      },
      {
        'icon': Icons.people_outline_rounded,
        'label': _isArabic ? 'الجمهور المستهدف' : 'Public cible',
        'value': training.target,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 4,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xffd57653).withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xffd57653).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item['icon'] as IconData,
                  size: 20,
                  color: const Color(0xffd57653),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item['label'] as String,
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                item['value'] as String,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff2c221e),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // PRICE & ACTION SECTION
  // ============================================================

  Widget _buildPriceActionSection(
    TrainingModel training,
    bool isMobile,
    double price,
    String symbol,
    double finalPrice,
    bool hasDiscount,
  ) {
    final isUserLoggedIn = _isAuthenticated;

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xffd57653).withOpacity(0.05),
            const Color(0xffd57653).withOpacity(0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xffd57653).withOpacity(0.15),
        ),
      ),
      child: Column(
        children: [
          // Prix
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (hasDiscount) ...[
                Text(
                  '${price.toStringAsFixed(0)} $symbol',
                  style: GoogleFonts.cairo(
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Text(
                '${finalPrice.toStringAsFixed(0)} $symbol',
                style: GoogleFonts.cairo(
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xffd57653),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'TTC',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xff7c6e68),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _isArabic
                ? '💰 السعر بـ ${TrainingModel.getCurrencyName(_countryCode)}'
                : '💰 Prix en ${TrainingModel.getCurrencyName(_countryCode)}',
            style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey[500]),
          ),
          if (hasDiscount) ...[
            const SizedBox(height: 4),
            Text(
              _isArabic
                  ? '🎉 وفر ${(price - finalPrice).toStringAsFixed(0)} $symbol !'
                  : '🎉 Économisez ${(price - finalPrice).toStringAsFixed(0)} $symbol !',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Boutons
          Row(
            children: [
              // Ajouter au panier
              Expanded(
                child: OutlinedButton(
                  onPressed: (_isProcessingPayment || _isAddingToCart)
                      ? null
                      : _handleAddToCart,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xffd57653),
                    side: const BorderSide(color: Color(0xffd57653), width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: GoogleFonts.cairo(
                      fontSize: isMobile ? 13 : 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child:
                      _isAddingToCart
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xffd57653),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_cart_outlined, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  _isArabic ? 'أضف للسلة' : 'Ajouter',
                                ),
                              ],
                            ),
                ),
              ),
              const SizedBox(width: 12),

              // Payer
              Expanded(
                child: ElevatedButton(
                  onPressed: _isProcessingPayment ? null : _handleInscription,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffd57653),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                    textStyle: GoogleFonts.cairo(
                      fontSize: isMobile ? 13 : 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child:
                      _isProcessingPayment
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.payment_rounded, size: 20),
                                const SizedBox(width: 8),
                                Text(_isArabic ? 'الدفع' : 'Payer'),
                              ],
                            ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Statut connexion
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isUserLoggedIn
                    ? Icons.check_circle_outline_rounded
                    : Icons.info_outline_rounded,
                size: 16,
                color: isUserLoggedIn ? Colors.green[600] : Colors.grey[500],
              ),
              const SizedBox(width: 6),
              Text(
                isUserLoggedIn
                    ? (_isArabic ? '✅ أنت متصل' : '✅ Connecté')
                    : (_isArabic
                        ? '📱 Veuillez vous connecter'
                        : '📱 Veuillez vous connecter'),
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: isUserLoggedIn ? Colors.green[600] : Colors.grey[500],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Sécurité
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                _isArabic ? 'دفع آمن' : 'Paiement sécurisé',
                style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.support_agent_outlined,
                size: 14,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                _isArabic ? 'دعم 7/7' : 'Support 7j/7',
                style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SIMILAR TRAININGS SECTION
  // ============================================================

  Widget _buildSimilarTrainingsSection() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xffd57653),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isArabic ? '📚 دورات مشابهة' : '📚 Formations similaires',
                    style: GoogleFonts.cairo(
                      fontSize: isMobile ? 18 : 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff2c221e),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/formations');
                },
                child: Text(
                  _isArabic ? 'عرض الكل →' : 'Voir tout →',
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 13 : 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xffd57653),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Liste horizontale
          if (_isLoadingSimilar)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(color: Color(0xffd57653)),
              ),
            )
          else if (_similarTrainings.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Center(
                child: Text(
                  _isArabic
                      ? 'لا توجد دورات مشابهة حالياً'
                      : 'Aucune formation similaire disponible',
                  style: GoogleFonts.cairo(
                    color: Colors.grey[500],
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 230,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _similarTrainings.length,
                itemBuilder: (context, index) {
                  final training = _similarTrainings[index];
                  return SimilarTrainingCard(
                    training: training,
                    isArabic: _isArabic,
                    countryCode: _countryCode,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FormationDetailPage(
                            formationId: training.id,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR WIDGETS
  // ============================================================

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            _isArabic ? 'خطأ في التحميل' : 'Erreur de chargement',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.red[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: GoogleFonts.cairo(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffd57653),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _isArabic ? 'التكوين غير موجود' : 'Formation non trouvée',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}