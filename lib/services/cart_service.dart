// lib/services/cart_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/rxdart.dart';

class CartService {
  static const String _cartKey = 'cart';
  
  // Stream pour le compteur du panier
  static final BehaviorSubject<int> _cartCountSubject = BehaviorSubject<int>.seeded(0);
  static Stream<int> get cartCountStream => _cartCountSubject.stream;
  static int get currentCount => _cartCountSubject.value;

  // Charger le panier
  static Future<List<Map<String, dynamic>>> loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartString = prefs.getString(_cartKey);
      if (cartString != null && cartString.isNotEmpty) {
        final List<dynamic> decoded = json.decode(cartString);
        return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (e) {
      print('❌ [CartService] Erreur chargement: $e');
    }
    return [];
  }

  // Sauvegarder le panier
  static Future<void> saveCart(List<Map<String, dynamic>> cart) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cartKey, json.encode(cart));
      _updateCount(cart);
    } catch (e) {
      print('❌ [CartService] Erreur sauvegarde: $e');
    }
  }

  // Ajouter un article
  static Future<void> addItem(Map<String, dynamic> item) async {
    final cart = await loadCart();
    final index = cart.indexWhere(
      (i) => i['formationId'] == item['formationId'],
    );
    
    if (index != -1) {
      // ✅ Conversion explicite en int
      final currentQuantity = cart[index]['quantity'] as int? ?? 1;
      cart[index]['quantity'] = currentQuantity + 1;
    } else {
      cart.add(item);
    }
    
    await saveCart(cart);
  }

  // Supprimer un article
  static Future<void> removeItem(String formationId) async {
    final cart = await loadCart();
    cart.removeWhere((item) => item['formationId'] == formationId);
    await saveCart(cart);
  }

  // Vider le panier
  static Future<void> clearCart() async {
    await saveCart([]);
  }

  // Mettre à jour la quantité
  static Future<void> updateQuantity(String formationId, int quantity) async {
    final cart = await loadCart();
    final index = cart.indexWhere((item) => item['formationId'] == formationId);
    
    if (index != -1) {
      if (quantity <= 0) {
        cart.removeAt(index);
      } else {
        cart[index]['quantity'] = quantity;
      }
      await saveCart(cart);
    }
  }

  // Obtenir le nombre total d'articles
  static Future<int> getTotalItems() async {
    final cart = await loadCart();
    int total = 0;
    for (var item in cart) {
      // ✅ Conversion explicite en int
      final quantity = item['quantity'] as int? ?? 1;
      total += quantity;
    }
    return total;
  }

  // Obtenir le prix total
  static Future<double> getTotalPrice() async {
    final cart = await loadCart();
    double total = 0.0;
    for (var item in cart) {
      // ✅ Conversions explicites
      final price = (item['price'] as num?)?.toDouble() ?? 0.0;
      final quantity = item['quantity'] as int? ?? 1;
      total += price * quantity;
    }
    return total;
  }

  // Vérifier si un article existe dans le panier
  static Future<bool> isInCart(String formationId) async {
    final cart = await loadCart();
    return cart.any((item) => item['formationId'] == formationId);
  }

  // Obtenir la quantité d'un article spécifique
  static Future<int> getItemQuantity(String formationId) async {
    final cart = await loadCart();
    final index = cart.indexWhere((item) => item['formationId'] == formationId);
    if (index != -1) {
      return cart[index]['quantity'] as int? ?? 0;
    }
    return 0;
  }

  // Mettre à jour le compteur
  static void _updateCount(List<Map<String, dynamic>> cart) {
    int count = 0;
    for (var item in cart) {
      // ✅ Conversion explicite en int
      final quantity = item['quantity'] as int? ?? 1;
      count += quantity;
    }
    _cartCountSubject.add(count);
  }

  // Notifier une mise à jour du panier (pour rafraîchir le badge)
  static Future<void> notifyCartUpdate() async {
    final cart = await loadCart();
    _updateCount(cart);
  }

  // Initialiser le compteur au démarrage
  static Future<void> init() async {
    final cart = await loadCart();
    _updateCount(cart);
  }

  // Disposer le stream
  static void dispose() {
    _cartCountSubject.close();
  }
}