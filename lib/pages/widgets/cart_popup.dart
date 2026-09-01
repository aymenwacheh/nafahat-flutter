// lib/pages/cart/cart_popup.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafahat/services/cart_service.dart';
import 'package:nafahat/services/auth_service.dart';
import 'package:nafahat/services/payment_service.dart';
import 'package:nafahat/pages/paiement/modalite_paiment.dart';
import 'package:nafahat/providers/language_provider.dart';
import 'package:nafahat/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartPopup extends StatefulWidget {
  const CartPopup({super.key});

  @override
  State<CartPopup> createState() => _CartPopupState();
}

class _CartPopupState extends State<CartPopup> {
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = true;
  bool _isProcessingPayment = false;
  String _countryCode = 'TN';
  bool _isAuthenticated = false;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadCart();
    _detectCountry();
    _checkAuthStatus();
  }

  // ============================================================
  // CHARGEMENT DES DONNÉES
  // ============================================================

  Future<void> _loadCart() async {
    setState(() => _isLoading = true);
    _cartItems = await CartService.loadCart();
    setState(() => _isLoading = false);
  }

  Future<void> _detectCountry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? savedCountry = prefs.getString('user_country');
      setState(() {
        _countryCode = savedCountry?.isNotEmpty == true ? savedCountry! : 'TN';
      });
    } catch (e) {
      setState(() => _countryCode = 'TN');
    }
  }

  Future<void> _checkAuthStatus() async {
    try {
      _isAuthenticated = await AuthService.isAuthenticated();
      if (_isAuthenticated) {
        _userData = await AuthService.getUserData();
      }
    } catch (e) {
      print('❌ [AUTH] Erreur: $e');
    }
  }

  // ============================================================
  // GESTION DU PANIER
  // ============================================================

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

  // ============================================================
  // PAIEMENT DIRECT (SANS PASSER PAR CART_PAGE)
  // ============================================================

  Future<void> _handlePayment() async {
    print('═══════════════════════════════════════════════════════════');
    print('🟢 [POPUP PANIER] PAIEMENT DIRECT');
    print('═══════════════════════════════════════════════════════════');

    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isArabic() ? '❌ السلة فارغة' : '❌ Le panier est vide',
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
      print('🟡 [POPUP] Utilisateur non connecté - Redirection vers login');
      
      // Fermer le popup
      Navigator.pop(context);
      
      final result = await Navigator.pushNamed(
        context,
        '/login',
        arguments: {'returnToPrevious': true},
      );

      if (!mounted) return;
      await _checkAuthStatus();

      if (_isAuthenticated) {
        print('🟢 [POPUP] Utilisateur connecté après login');
        // Rouvrir le popup
        showDialog(
          context: context,
          barrierDismissible: true,
          barrierColor: Colors.black.withOpacity(0.4),
          builder: (context) => const CartPopup(),
        );
      }
      return;
    }

    // Procéder au paiement
    await _proceedToPayment();
  }

  Future<void> _proceedToPayment() async {
    setState(() => _isProcessingPayment = true);

    try {
      final userId = _userData?['id']?.toString();
      if (userId == null) {
        throw Exception('ID utilisateur non trouvé');
      }

      // Prendre la première formation du panier
      // (à adapter selon votre logique métier)
      final firstItem = _cartItems.first;
      final formationId = firstItem['formationId'];
      final currency = _getCurrencySymbol();

      print('🟡 [POPUP] Paiement formation: $formationId');
      print('🟡 [POPUP] Total: ${_getTotalPrice()} $currency');

      final result = await PaymentService.initiatePayment(
        formationId: formationId,
        userId: userId,
        currency: currency,
      );

      if (result['success'] == true) {
        final paymentId = result['paymentId']?.toString();
        if (paymentId != null && paymentId.isNotEmpty) {
          print('🟢 [POPUP] Paiement initié, ID: $paymentId');
          
          // Fermer le popup
          Navigator.pop(context);
          
          // Naviguer vers ModalitePaimentPage (le paiement continue)
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
          );
        } else {
          throw Exception('ID de paiement manquant');
        }
      } else {
        throw Exception(result['message'] ?? 'Erreur paiement');
      }
    } catch (e) {
      print('❌ [POPUP] Erreur paiement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ ${_isArabic() ? 'Erreur de paiement' : 'Erreur de paiement'}: $e',
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

  bool _isArabic() {
    return Provider.of<LanguageProvider>(context, listen: false).isArabic;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;
    final size = MediaQuery.of(context).size;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: size.width * 0.9,
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ============================================================
            // HEADER
            // ============================================================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xff0D443E),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isArabic ? '🛒 سلة التسوق' : '🛒 Panier',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            
            // ============================================================
            // CONTENU
            // ============================================================
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _cartItems.isEmpty
                      ? _buildEmptyCart(isArabic)
                      : _buildCartContent(isArabic),
            ),
            
            // ============================================================
            // FOOTER
            // ============================================================
            if (_cartItems.isNotEmpty) _buildFooter(isArabic),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCart(bool isArabic) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            isArabic ? 'السلة فارغة' : 'Panier vide',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isArabic ? 'أضف دورات إلى سلة التسوق الخاصة بك' : 'Ajoutez des formations à votre panier',
            style: GoogleFonts.cairo(color: Colors.grey[500], fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              isArabic ? 'تصفح الدورات' : 'Parcourir les formations',
              style: GoogleFonts.cairo(color: const Color(0xffd57653)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(bool isArabic) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _cartItems.length,
      itemBuilder: (context, index) {
        final item = _cartItems[index];
        final title = isArabic 
            ? (item['titleAr'] ?? item['titleFr'] ?? 'Sans titre')
            : (item['titleFr'] ?? item['titleAr'] ?? 'Sans titre');
        final symbol = item['currencySymbol'] ?? 'TND';
        final price = (item['price'] as num?)?.toDouble() ?? 0.0;
        final quantity = item['quantity'] as int? ?? 1;
        final imageUrl = item['imageUrl'] ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
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
                      ? Icon(Icons.school, color: Colors.grey[400], size: 24)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${price.toStringAsFixed(2)} $symbol',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xffd57653),
                          fontSize: 14,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 20),
                            onPressed: () => _updateQuantity(index, quantity - 1),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$quantity',
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 20),
                            onPressed: () => _updateQuantity(index, quantity + 1),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
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

  Widget _buildFooter(bool isArabic) {
    final total = _getTotalPrice();
    final symbol = _getCurrencySymbol();
    final isUserLoggedIn = _isAuthenticated;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'المجموع' : 'Total',
                      style: GoogleFonts.cairo(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${total.toStringAsFixed(2)} $symbol',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: const Color(0xff0D443E),
                      ),
                    ),
                    if (!isUserLoggedIn)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isArabic ? '⚠️ Connexion requise' : '⚠️ Connexion requise',
                          style: GoogleFonts.cairo(
                            fontSize: 9,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: _clearCart,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    child: Text(
                      isArabic ? 'تفريغ' : 'Vider',
                      style: GoogleFonts.cairo(fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isProcessingPayment ? null : _handlePayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff0D443E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: _isProcessingPayment
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            children: [
                              const Icon(Icons.payment_rounded, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                isArabic ? 'الدفع' : 'Payer',
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isArabic 
                ? '💳 Paiement sécurisé · ${_cartItems.length} article${_cartItems.length > 1 ? 's' : ''}'
                : '💳 Paiement sécurisé · ${_cartItems.length} article${_cartItems.length > 1 ? 's' : ''}',
            style: GoogleFonts.cairo(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}