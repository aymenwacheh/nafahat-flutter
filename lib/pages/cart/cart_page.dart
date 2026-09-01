// lib/pages/cart/cart_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafahat/services/cart_service.dart';
import 'package:nafahat/services/auth_service.dart';
import 'package:nafahat/services/payment_service.dart';
import 'package:nafahat/pages/formation/formation_detail_page.dart';
import 'package:nafahat/pages/paiement/modalite_paiment.dart';
import 'package:nafahat/pages/users/auth_page.dart';
import 'package:nafahat/providers/language_provider.dart';
import 'package:nafahat/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = true;
  bool _isProcessingPayment = false;
  bool _isArabic = true;
  String _countryCode = 'TN';
  bool _isAuthenticated = false;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadCart();
    _loadLanguage();
    _detectCountry();
    _checkAuthStatus();
  }

  // ============================================================
  // CHARGEMENT DES DONNÉES
  // ============================================================

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
        });
      } else {
        setState(() {
          _countryCode = 'TN';
        });
      }
    } catch (e) {
      setState(() {
        _countryCode = 'TN';
      });
      print('❌ [PAYS] Erreur, défaut: TN');
    }
  }

  Future<void> _checkAuthStatus() async {
    try {
      _isAuthenticated = await AuthService.isAuthenticated();
      if (_isAuthenticated) {
        _userData = await AuthService.getUserData();
        print('🟡 [AUTH] ID: ${_userData?['id']}');
      }
    } catch (e) {
      print('❌ [AUTH] Erreur: $e');
    }
  }

  Future<void> _refreshAuthStatus() async {
    _isAuthenticated = await AuthService.isAuthenticated();
    if (_isAuthenticated) {
      _userData = await AuthService.getUserData();
    }
  }

  Future<void> _loadCart() async {
    setState(() => _isLoading = true);
    _cartItems = await CartService.loadCart();
    setState(() => _isLoading = false);
  }

  // ============================================================
  // GESTION DU PANIER
  // ============================================================

  Future<void> _updateQuantity(int index, int newQuantity) async {
    final item = _cartItems[index];
    final formationId = item['formationId'];
    
    if (newQuantity <= 0) {
      await CartService.removeItem(formationId);
      _cartItems.removeAt(index);
    } else {
      await CartService.updateQuantity(formationId, newQuantity);
      _cartItems[index]['quantity'] = newQuantity;
    }
    setState(() {});
    await CartService.notifyCartUpdate();
  }

  Future<void> _clearCart() async {
    await CartService.clearCart();
    _cartItems.clear();
    setState(() {});
    await CartService.notifyCartUpdate();
  }

  double _getTotalPrice() {
    return _cartItems.fold(
      0.0,
      (sum, item) => sum + ((item['price'] as num?)?.toDouble() ?? 0.0) * ((item['quantity'] as int?) ?? 1),
    );
  }

  String _getCurrencySymbol() {
    if (_cartItems.isNotEmpty) {
      return _cartItems.first['currencySymbol'] ?? 'TND';
    }
    return 'TND';
  }

  // ============================================================
  // PAIEMENT GROUPÉ
  // ============================================================

  Future<void> _handleGroupPayment() async {
    print('═══════════════════════════════════════════════════════════');
    print('🟢 [PANIER] PAIEMENT GROUPÉ');
    print('═══════════════════════════════════════════════════════════');

    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isArabic ? '❌ السلة فارغة' : '❌ Le panier est vide',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Vérifier si l'utilisateur est connecté
    if (!_isAuthenticated) {
      print('🟡 [PANIER] Utilisateur non connecté - Redirection vers login');
      final result = await Navigator.pushNamed(
        context,
        '/login',
        arguments: {'returnToPrevious': true},
      );

      if (!mounted) return;
      await _refreshAuthStatus();

      if (_isAuthenticated) {
        print('🟢 [PANIER] Utilisateur connecté après login');
        _proceedToGroupPayment();
      } else {
        print('🟡 [PANIER] Annulation du paiement');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isArabic
                    ? '❌ Veuillez vous connecter pour payer'
                    : '❌ Veuillez vous connecter pour payer',
                style: GoogleFonts.cairo(),
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      return;
    }

    _proceedToGroupPayment();
  }

  Future<void> _proceedToGroupPayment() async {
    setState(() => _isProcessingPayment = true);

    try {
      final userId = _userData?['id']?.toString();
      if (userId == null) {
        throw Exception('ID utilisateur non trouvé');
      }

      // Récupérer la devise
      final currency = _getCurrencySymbol();

      // Préparer les données pour le paiement groupé
      // Note: Cette partie dépend de votre API backend
      // Vous devrez adapter selon votre PaymentService
      
      // Option 1: Paiement pour la première formation du panier
      // (à adapter selon votre logique métier)
      final firstItem = _cartItems.first;
      final formationId = firstItem['formationId'];

      print('🟡 [PANIER] Paiement pour la formation: $formationId');
      print('🟡 [PANIER] Total du panier: ${_getTotalPrice()} $currency');
      print('🟡 [PANIER] Nombre d\'articles: ${_cartItems.length}');

      // Pour l'instant, on redirige vers la page de paiement
      // avec la première formation
      // Vous devrez adapter votre PaymentService pour accepter plusieurs formations
      
      // Si votre API supporte le paiement groupé, utilisez cette approche:
      // final result = await PaymentService.initiateGroupPayment(
      //   formationIds: _cartItems.map((item) => item['formationId']).toList(),
      //   userId: userId,
      //   currency: currency,
      //   totalAmount: _getTotalPrice(),
      // );

      // Sinon, pour l'instant on utilise le paiement simple pour la première formation
      final result = await PaymentService.initiatePayment(
        formationId: formationId,
        userId: userId,
        currency: currency,
      );

      if (result['success'] == true) {
        final paymentId = result['paymentId']?.toString();
        if (paymentId != null && paymentId.isNotEmpty) {
          print('🟢 [PANIER] Paiement initié, ID: $paymentId');
          
          // Naviguer vers ModalitePaimentPage
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ModalitePaimentPage(
                paymentId: paymentId,
                formationId: formationId,
                userId: userId,
                currency: _countryCode,
              ),
            ),
          ).then((_) {
            // Rafraîchir le panier au retour
            _loadCart();
          });
        } else {
          throw Exception('ID de paiement manquant');
        }
      } else {
        throw Exception(result['message'] ?? 'Erreur paiement');
      }
    } catch (e) {
      print('❌ [PANIER] Erreur paiement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ ${_isArabic ? 'Erreur de paiement' : 'Erreur de paiement'}: $e',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffcfbfa),
      appBar: AppBar(
        title: Text(
          _isArabic ? '🛒 سلة التسوق' : '🛒 Panier',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          if (_cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _clearCart,
              tooltip: _isArabic ? 'تفريغ السلة' : 'Vider le panier',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cartItems.isEmpty
              ? _buildEmptyCart()
              : _buildCartContent(),
      bottomNavigationBar: _cartItems.isNotEmpty ? _buildBottomBar() : null,
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _isArabic ? 'السلة فارغة' : 'Panier vide',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isArabic
                ? 'أضف دورات إلى سلة التسوق الخاصة بك'
                : 'Ajoutez des formations à votre panier',
            style: GoogleFonts.poppins(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffd57653),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _isArabic ? 'تصفح الدورات' : 'Parcourir les formations',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cartItems.length,
      itemBuilder: (context, index) {
        final item = _cartItems[index];
        final title = _isArabic 
            ? (item['titleAr'] ?? item['titleFr'] ?? 'Sans titre')
            : (item['titleFr'] ?? item['titleAr'] ?? 'Sans titre');
        final symbol = item['currencySymbol'] ?? 'TND';
        final price = (item['price'] as num?)?.toDouble() ?? 0.0;
        final quantity = item['quantity'] as int? ?? 1;
        final imageUrl = item['imageUrl'] ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Image
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    image: imageUrl.isNotEmpty && imageUrl.startsWith('http')
                        ? DecorationImage(
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: (imageUrl.isEmpty || !imageUrl.startsWith('http'))
                      ? Icon(Icons.school, color: Colors.grey[400], size: 30)
                      : null,
                ),
                const SizedBox(width: 12),
                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${price.toStringAsFixed(2)} $symbol',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xffd57653),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 24),
                            onPressed: () => _updateQuantity(index, quantity - 1),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$quantity',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 24),
                            onPressed: () => _updateQuantity(index, quantity + 1),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Bouton supprimer
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _updateQuantity(index, 0),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    final total = _getTotalPrice();
    final symbol = _getCurrencySymbol();
    final isUserLoggedIn = _isAuthenticated;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isArabic ? 'المجموع' : 'Total',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${total.toStringAsFixed(2)} $symbol',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: const Color(0xffd57653),
                      ),
                    ),
                    if (!isUserLoggedIn)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _isArabic
                              ? '⚠️ Connexion requise pour payer'
                              : '⚠️ Connexion requise pour payer',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _isProcessingPayment ? null : _handleGroupPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff0D443E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(120, 50),
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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.payment_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _isArabic ? '💳 الدفع' : '💳 Payer',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
              ),
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
                _isArabic ? '🔒 Paiement sécurisé' : '🔒 Paiement sécurisé',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.shopping_bag_outlined,
                size: 14,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                '${_cartItems.length} ${_isArabic ? 'عناصر' : 'articles'}',
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