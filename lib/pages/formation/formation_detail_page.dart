// lib/pages/formations/formation_detail_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafahat/models/training_model.dart';
import 'package:nafahat/services/training_service.dart';
import 'package:nafahat/services/auth_service.dart';
import 'package:nafahat/services/geo_service.dart';
import 'package:nafahat/services/payment_service.dart';
import 'package:nafahat/services/cmpl_user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../landing/widgets/chatbot/chatbot_wrapper.dart';
import '../users/auth_page.dart';
import '../users/cmpl_info_form.dart';
import '../paiement/modalite_paiment.dart';

class FormationDetailPage extends StatefulWidget {
  final String formationId;

  const FormationDetailPage({super.key, required this.formationId});

  @override
  State<FormationDetailPage> createState() => _FormationDetailPageState();
}

class _FormationDetailPageState extends State<FormationDetailPage> {
  // ============================================================
  // ÉTATS
  // ============================================================

  TrainingModel? _training;
  bool _isLoading = true;
  String? _errorMessage;

  bool _isArabic = true;
  String _countryCode = 'TN';
  bool _isLoadingCountry = true;

  bool _isAuthenticated = false;
  Map<String, dynamic>? _userData;
  bool _isCheckingAuth = true;

  bool _isProcessingPayment = false;
  String? _currentPaymentId;

  // ============================================================
  // CYCLE DE VIE
  // ============================================================

  @override
  void initState() {
    super.initState();
    print('═══════════════════════════════════════════════════════════');
    print('🔵 [INIT] FormationDetailPage - ID: ${widget.formationId}');
    print('═══════════════════════════════════════════════════════════');
    _loadFormation();
    _loadUserLanguage();
    _detectCountry();
    _checkAuthStatus();
  }

  @override
  void dispose() {
    print('🔴 [DISPOSE] FormationDetailPage');
    super.dispose();
  }

  // ============================================================
  // CHARGEMENT DES DONNÉES
  // ============================================================

  Future<void> _loadUserLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLang = prefs.getString('language');
      setState(() {
        _isArabic = savedLang == 'ar' || savedLang == null;
      });
      print('🟡 [LANGUE] $_isArabic');
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
        print('🟡 [PAYS] Chargé: $_countryCode');
      } else {
        final countryCode = await GeoService.getUserCountryCode();
        await prefs.setString('user_country', countryCode);
        setState(() {
          _countryCode = countryCode;
          _isLoadingCountry = false;
        });
        print('🟡 [PAYS] Détecté: $_countryCode');
      }
    } catch (e) {
      setState(() {
        _countryCode = 'TN';
        _isLoadingCountry = false;
      });
      print('❌ [PAYS] Erreur, défaut: TN');
    }
  }

  Future<void> _checkAuthStatus() async {
    print('🔵 [AUTH] Vérification...');
    setState(() => _isCheckingAuth = true);
    try {
      _isAuthenticated = await AuthService.isAuthenticated();
      print('🟡 [AUTH] Authentifié: $_isAuthenticated');

      if (_isAuthenticated) {
        _userData = await AuthService.getUserData();
        print('🟡 [AUTH] ID: ${_userData?['id']}');
        print('🟡 [AUTH] Nom: ${_userData?['nomPrenom']}');
      }
    } catch (e) {
      print('❌ [AUTH] Erreur: $e');
    } finally {
      if (mounted) setState(() => _isCheckingAuth = false);
    }
  }

  Future<void> _refreshAuthStatus() async {
    print('🔵 [AUTH] Rafraîchissement du statut...');
    _isAuthenticated = await AuthService.isAuthenticated();
    print('🟡 [AUTH] Authentifié: $_isAuthenticated');
    if (_isAuthenticated) {
      _userData = await AuthService.getUserData();
      print('🟡 [AUTH] ID: ${_userData?['id']}');
      print('🟡 [AUTH] Nom: ${_userData?['nomPrenom']}');
    }
  }

  Future<void> _loadFormation() async {
    print('🔵 [FORMATION] Chargement...');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final trainings = await TrainingService.getTrainings();
      final found = trainings.firstWhere(
        (t) => t.id == widget.formationId,
        orElse: () {
          throw Exception('Formation non trouvée');
        },
      );

      print('🟢 [FORMATION] Trouvée: ${found.titleFr}');
      print('🟢 [FORMATION] categorieId: ${found.categorieId}');

      setState(() {
        _training = found;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ [FORMATION] Erreur: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // GESTION DE LA LANGUE
  // ============================================================

  void _toggleLanguage() {
    setState(() {
      _isArabic = !_isArabic;
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('language', _isArabic ? 'ar' : 'fr');
    });
    print('🟡 [LANGUE] Bascule: ${_isArabic ? "AR" : "FR"}');
  }

  // ============================================================
  // VÉRIFICATIONS
  // ============================================================

  bool _isFormationReligieuse() {
    if (_training == null) return false;
    final isReligieuse = _training!.categorieId == 1;
    print(
      '🟡 [CATÉGORIE] Religieuse: $isReligieuse (id: ${_training!.categorieId})',
    );
    return isReligieuse;
  }

  Future<bool> _checkCmplExists(int adherentId) async {
    if (_training == null) return false;
    print('🔵 [CMPL] Vérification pour adherentId: $adherentId');
    try {
      final exists = await CmplUserService.checkCmplExists(
        adherentId: adherentId,
        formationId: int.parse(_training!.id),
      );
      print('🟡 [CMPL] Existe: $exists');
      return exists;
    } catch (e) {
      print('❌ [CMPL] Erreur: $e');
      return false;
    }
  }

  // ============================================================
  // NAVIGATIONS
  // ============================================================

  void _navigateToPaymentPage(String paymentId) {
    print('🔵 [NAVIGATION] Vers paiement, ID: $paymentId');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ModalitePaimentPage(
              paymentId: paymentId,
              formationId: _training?.id,
              userId: _userData?['id']?.toString(),
              currency: _countryCode,
            ),
      ),
    );
  }

  void _navigateToCmplInfoForm(int adherentId, {VoidCallback? onComplete}) {
    if (_training == null) return;
    print('═══════════════════════════════════════════════════════════');
    print('🔵 [CMPL] REDIRECTION VERS CmplInfoForm');
    print('🔵 [CMPL] adherentId: $adherentId');
    print('🔵 [CMPL] formationId: ${_training!.id}');
    print('═══════════════════════════════════════════════════════════');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CmplInfoForm(
              adherentId: adherentId,
              formationId: int.parse(_training!.id),
              formation: _training,
              onComplete:
                  onComplete ??
                  () async {
                    print('🟢 [CMPL] Formulaire complété');
                    await _refreshAuthStatus();
                    _handleInscription();
                  },
            ),
      ),
    );
  }

  // ============================================================
  // GESTION DE L'INSCRIPTION / PAIEMENT - NOUVELLE LOGIQUE
  // ============================================================

  Future<void> _handleInscription() async {
    print('═══════════════════════════════════════════════════════════');
    print('🔵 [INSCRIPTION] DEBUT');
    print('═══════════════════════════════════════════════════════════');

    if (_training == null) {
      print('❌ [INSCRIPTION] Formation null');
      return;
    }

    print('🟡 [INSCRIPTION] Formation: ${_training!.titleFr}');
    print('🟡 [INSCRIPTION] categorieId: ${_training!.categorieId}');
    print('🟡 [INSCRIPTION] Authentifié: $_isAuthenticated');

    setState(() => _isProcessingPayment = true);

    try {
      // ==========================================================
      // SCÉNARIO 1: UTILISATEUR DÉJÀ CONNECTÉ
      // ==========================================================
      if (_isAuthenticated) {
        print('🟢 [INSCRIPTION] SCÉNARIO 1: Utilisateur connecté');

        final userId =
            _userData?['id']?.toString() ??
            await AuthService.getUserIdForPayment();
        print('🟡 [INSCRIPTION] userId: $userId');

        if (userId == null) {
          throw Exception('ID utilisateur non trouvé');
        }

        final adherentId = int.tryParse(userId);
        if (adherentId == null) {
          throw Exception('ID utilisateur invalide: $userId');
        }

        // ✅ VÉRIFICATION: Formation religieuse ?
        if (_isFormationReligieuse()) {
          print('🟡 [INSCRIPTION] Formation religieuse détectée');

          final cmplExists = await _checkCmplExists(adherentId);

          if (!cmplExists) {
            print('🔴 [INSCRIPTION] Infos complémentaires manquantes');
            print('🔴 [INSCRIPTION] Redirection vers CmplInfoForm');
            setState(() => _isProcessingPayment = false);
            _navigateToCmplInfoForm(adherentId);
            return;
          } else {
            print('🟢 [INSCRIPTION] Infos déjà remplies');
          }
        } else {
          print('🟢 [INSCRIPTION] Formation non religieuse');
        }

        print('🟢 [INSCRIPTION] Redirection vers paiement...');
        await _proceedToPayment(userId);
        return;
      }

      // ==========================================================
      // SCÉNARIO 2: UTILISATEUR NON CONNECTÉ
      // ==========================================================
      print('🟡 [INSCRIPTION] SCÉNARIO 2: Utilisateur non connecté');

      // ✅ REDIRECTION VERS AUTH_PAGE AVEC PARAMÈTRE
      print('🟡 [INSCRIPTION] SCÉNARIO 2: Utilisateur non connecté');

      setState(() => _isProcessingPayment = false);

      // ✅ REDIRECTION VERS AUTH_PAGE AVEC PARAMÈTRE
      final result = await Navigator.pushNamed(
        context,
        '/login',
        arguments: {'returnToPrevious': true}, // 👈 PASSER LE PARAMÈTRE
      );

      print('═══════════════════════════════════════════════════════════');
      print('🔵 [INSCRIPTION] RETOUR D\'AUTH_PAGE');
      print('🔵 [INSCRIPTION] result: $result');
      print('═══════════════════════════════════════════════════════════');

      if (!mounted) return;

      // ✅ Après le retour d'AuthPage, vérifier si l'utilisateur est maintenant connecté
      await _refreshAuthStatus();

      if (_isAuthenticated) {
        print('🟢 [INSCRIPTION] Utilisateur connecté après AuthPage');

        final userId =
            _userData?['id']?.toString() ??
            await AuthService.getUserIdForPayment();
        if (userId != null) {
          setState(() => _isProcessingPayment = true);
          await _proceedToPayment(userId);
        } else {
          print('❌ [INSCRIPTION] ID utilisateur non trouvé après connexion');
          throw Exception('ID utilisateur non trouvé');
        }
      } else {
        print('🟡 [INSCRIPTION] Utilisateur non connecté après AuthPage');
        // L'utilisateur a annulé ou n'a pas réussi à se connecter
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isArabic
                    ? '❌ Veuillez vous connecter pour continuer'
                    : '❌ Veuillez vous connecter pour continuer',
                style: GoogleFonts.cairo(),
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ [INSCRIPTION] Erreur: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e', style: GoogleFonts.cairo()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
      print('🔵 [INSCRIPTION] FIN');
    }
  }

  // ============================================================
  // PAIEMENT
  // ============================================================

  Future<void> _proceedToPayment(String userId) async {
    print('═══════════════════════════════════════════════════════════');
    print('🔵 [PAIEMENT] DEBUT');
    print('🔵 [PAIEMENT] userId: $userId');
    print('═══════════════════════════════════════════════════════════');

    if (_training == null) {
      print('❌ [PAIEMENT] Formation null');
      return;
    }

    final currency = TrainingModel.getCurrencySymbol(_countryCode);
    print('🟡 [PAIEMENT] Devise: $currency');

    try {
      print('🟡 [PAIEMENT] Appel à PaymentService.initiatePayment()...');
      final result = await PaymentService.initiatePayment(
        formationId: _training!.id,
        userId: userId,
        currency: currency,
      );
      print('🟡 [PAIEMENT] Résultat: $result');

      if (result['success'] == true) {
        final paymentId = result['paymentId']?.toString();
        if (paymentId != null && paymentId.isNotEmpty) {
          print('🟢 [PAIEMENT] Succès, ID: $paymentId');
          _navigateToPaymentPage(paymentId);
        } else {
          throw Exception('ID de paiement manquant');
        }
      } else {
        throw Exception(result['message'] ?? 'Erreur paiement');
      }
    } catch (e) {
      print('❌ [PAIEMENT] Erreur: $e');
      throw Exception(e);
    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return ChatbotWrapper(
      apiBaseUrl: 'http://localhost:3000',
      langue: _isArabic ? 'ar' : 'fr',
      primaryColor: const Color(0xffd57653),
      child: Scaffold(
        backgroundColor: const Color(0xfffcfbfa),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xff2c221e),
            ),
            onPressed: () {
              print('🔵 [NAVIGATION] Retour');
              Navigator.pop(context);
            },
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: const Color(0xffd57653).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Text(
                  _isArabic ? '🇫🇷 FR' : '🇸🇦 AR',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: const Color(0xffd57653),
                  ),
                ),
                onPressed: _toggleLanguage,
                tooltip: _isArabic ? 'Français' : 'العربية',
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            if (_isLoading || _isLoadingCountry || _isCheckingAuth)
              const Center(
                child: CircularProgressIndicator(color: Color(0xffd57653)),
              )
            else if (_errorMessage != null)
              _buildErrorWidget()
            else if (_training == null)
              _buildNotFoundWidget()
            else
              _buildDetailContent(isMobile),

            if (_isProcessingPayment)
              Container(
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
                          _isArabic
                              ? '⏳ جاري تحضير الدفع...'
                              : '⏳ Préparation du paiement...',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
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
    );
  }

  // ============================================================
  // WIDGETS DE BUILD
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
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailContent(bool isMobile) {
    final training = _training!;
    final title = _isArabic ? training.titleAr : training.titleFr;
    final description =
        _isArabic ? training.descriptionAr : training.descriptionFr;

    final price = training.getPriceForCurrency(_countryCode);
    final symbol = TrainingModel.getCurrencySymbol(_countryCode);
    final finalPrice = training.getFinalPriceForCurrency(_countryCode);
    final hasDiscount = training.hasDiscount;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCoverImage(training, isMobile),
          Padding(
            padding: EdgeInsets.all(isMobile ? 20 : 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBadges(training),
                const SizedBox(height: 16),
                _buildTitle(title, isMobile),
                const SizedBox(height: 12),
                _buildDescription(description, isMobile),
                const SizedBox(height: 32),
                _buildInfoSection(training, isMobile),
                const SizedBox(height: 32),
                _buildPaymentSection(
                  training,
                  isMobile,
                  price,
                  symbol,
                  finalPrice,
                  hasDiscount,
                ),
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

  Widget _buildTitle(String title, bool isMobile) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: isMobile ? 24 : 32,
        fontWeight: FontWeight.w800,
        color: const Color(0xff2c221e),
        height: 1.2,
      ),
    );
  }

  Widget _buildDescription(String description, bool isMobile) {
    return Text(
      description,
      style: GoogleFonts.poppins(
        fontSize: isMobile ? 15 : 17,
        fontWeight: FontWeight.w400,
        color: const Color(0xff7c6e68),
        height: 1.6,
      ),
    );
  }

  Widget _buildBadges(TrainingModel training) {
    final typeDisplay =
        training.typeFormation.isNotEmpty
            ? training.typeFormation
            : 'Formation';
    final discountText =
        training.hasDiscount
            ? training.getDiscountTextForCurrency(_countryCode, _isArabic)
            : null;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
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
        if (training.categorieId == 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.mosque_outlined,
                  size: 14,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  _isArabic ? 'دورة دينية' : 'Formation religieuse',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xffd57653).withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xffd57653).withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.public_rounded,
                size: 14,
                color: Color(0xffd57653),
              ),
              const SizedBox(width: 4),
              Text(
                '${TrainingModel.getCurrencySymbol(_countryCode)} ($_countryCode)',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xffd57653),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(TrainingModel training, bool isMobile) {
    final dureeDisplay =
        training.typeDuree.isNotEmpty ? training.typeDuree : 'Non définie';

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
          _buildInfoRow(
            icon: Icons.person_outline_rounded,
            label: _isArabic ? 'المكون' : 'Formateur',
            value: training.trainer,
          ),
          const Divider(height: 24),
          _buildInfoRow(
            icon: Icons.calendar_today_rounded,
            label: _isArabic ? 'الفترة' : 'Période',
            value: periodeDisplay,
          ),
          const Divider(height: 24),
          _buildInfoRow(
            icon: Icons.access_time_rounded,
            label: _isArabic ? 'المدة' : 'Durée',
            value: dureeDisplay,
          ),
          const Divider(height: 24),
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

  Widget _buildPaymentSection(
    TrainingModel training,
    bool isMobile,
    double price,
    String symbol,
    double finalPrice,
    bool hasDiscount,
  ) {
    final isUserLoggedIn = _isAuthenticated;
    final isReligieuse = _isFormationReligieuse();

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
          if (isReligieuse) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isArabic
                        ? '📖 معلومات إضافية مطلوبة'
                        : '📖 Informations supplémentaires requises',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (hasDiscount) ...[
                Text(
                  '${price.toStringAsFixed(0)} $symbol',
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
                '${finalPrice.toStringAsFixed(0)} $symbol',
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
          const SizedBox(height: 8),
          Text(
            _isArabic
                ? '💰 السعر بـ ${TrainingModel.getCurrencyName(_countryCode)}'
                : '💰 Prix en ${TrainingModel.getCurrencyName(_countryCode)}',
            style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[500]),
          ),
          const SizedBox(height: 12),
          if (hasDiscount)
            Text(
              _isArabic
                  ? '🎉 وفر ${(price - finalPrice).toStringAsFixed(0)} $symbol !'
                  : '🎉 Économisez ${(price - finalPrice).toStringAsFixed(0)} $symbol !',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessingPayment ? null : _handleInscription,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffd57653),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
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
                          Text(
                            _isArabic ? '💳 الدفع الآن' : '💳 Payer maintenant',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
            ),
          ),
          const SizedBox(height: 12),
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
              const SizedBox(width: 4),
              Text(
                isUserLoggedIn
                    ? (_isArabic ? '✅ أنت متصل' : '✅ Vous êtes connecté')
                    : (_isArabic
                        ? '📱 Veuillez vous connecter'
                        : '📱 Veuillez vous connecter'),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: isUserLoggedIn ? Colors.green[600] : Colors.grey[500],
                ),
              ),
              if (!isUserLoggedIn) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffd57653).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _isArabic ? 'Connexion requise' : 'Connexion requise',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xffd57653),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 14,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                _isArabic ? 'دفع آمن' : 'Paiement sécurisé',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
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
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
