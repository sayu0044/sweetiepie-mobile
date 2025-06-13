import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sweetipie/models/cart.dart';
import 'package:sweetipie/services/auth_service.dart';
import 'package:sweetipie/services/database_service.dart';

class CartServiceTemp extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final DatabaseService _databaseService = Get.find<DatabaseService>();

  // Local storage for cart items per user (temporary)
  // Key = userId, Value = List of Cart items
  final RxMap<String, List<Cart>> _userCartItems = <String, List<Cart>>{}.obs;

  // Observable for triggering UI updates
  final RxInt _updateTrigger = 0.obs;
  final RxBool isLoading = false.obs;
  final RxDouble totalPrice = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    debugPrint(
        'CartServiceTemp: Initialized with persistent user-isolated storage');

    // Load cart data from storage on init
    _loadCartFromStorage();

    // Listen to auth changes to update cart when user changes
    _authService.currentUser.listen((user) async {
      if (user != null) {
        debugPrint(
            'CartServiceTemp: User changed to ${user.id}, loading cart from storage...');

        // Load from storage when user logs in
        await _loadCartFromStorage();

        // Then refresh for current user
        _refreshCartForCurrentUser();

        debugPrint(
            'CartServiceTemp: Cart loaded for user ${user.id}, items count: $cartItemCount');
      } else {
        debugPrint('CartServiceTemp: User logged out, clearing cart display');
        totalPrice.value = 0.0;
      }
    });
  }

  // Get current user ID
  String get currentUserId => _authService.currentUser.value?.id ?? '';

  // Get cart items for current user only
  List<Cart> get cartItems {
    if (currentUserId.isEmpty) return [];
    // Access the update trigger to make this reactive
    _updateTrigger.value;
    return _userCartItems[currentUserId] ?? [];
  }

  // Initialize cart for user if not exists
  void _ensureUserCart(String userId) {
    if (!_userCartItems.containsKey(userId)) {
      _userCartItems[userId] = <Cart>[];
      debugPrint('CartServiceTemp: Created new cart for user: $userId');
    }
  }

  // Trigger UI update safely
  void _triggerUIUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateTrigger.value++;
    });
  }

  // Load cart data from SharedPreferences
  Future<void> _loadCartFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartDataJson = prefs.getString('user_carts');

      debugPrint('CartServiceTemp: Checking storage for cart data...');

      if (cartDataJson != null) {
        debugPrint('CartServiceTemp: Found cart data in storage, parsing...');
        final cartData = json.decode(cartDataJson) as Map<String, dynamic>;

        // Convert stored data back to Cart objects
        for (final entry in cartData.entries) {
          final userId = entry.key;
          final cartItemsJson = entry.value as List<dynamic>;

          final cartItems = cartItemsJson.map((itemJson) {
            final item = itemJson as Map<String, dynamic>;
            return Cart(
              id: item['id'],
              productsId: item['productsId'],
              jumlahBarang: item['jumlahBarang'],
              usersId: item['usersId'],
              created: DateTime.parse(item['created']),
              updated: DateTime.parse(item['updated']),
            );
          }).toList();

          _userCartItems[userId] = cartItems;
        }

        debugPrint(
            'CartServiceTemp: Loaded cart data for ${cartData.keys.length} users from storage');
        debugPrint(
            'CartServiceTemp: Available users in storage: ${cartData.keys.toList()}');

        // Log current user's cart if exists
        if (currentUserId.isNotEmpty && cartData.containsKey(currentUserId)) {
          debugPrint(
              'CartServiceTemp: Current user ($currentUserId) has ${cartData[currentUserId].length} items in storage');
        }

        _refreshCartForCurrentUser();
      } else {
        debugPrint('CartServiceTemp: No cart data found in storage');
      }
    } catch (e) {
      debugPrint('CartServiceTemp Error loading cart from storage: $e');
    }
  }

  // Save cart data to SharedPreferences
  Future<void> _saveCartToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert Cart objects to JSON-serializable format
      final cartData = <String, dynamic>{};
      for (final entry in _userCartItems.entries) {
        final userId = entry.key;
        final cartItems = entry.value;

        cartData[userId] = cartItems
            .map((cart) => {
                  'id': cart.id,
                  'productsId': cart.productsId,
                  'jumlahBarang': cart.jumlahBarang,
                  'usersId': cart.usersId,
                  'created': cart.created.toIso8601String(),
                  'updated': cart.updated.toIso8601String(),
                })
            .toList();
      }

      await prefs.setString('user_carts', json.encode(cartData));
      debugPrint('CartServiceTemp: Cart data saved to storage');
      debugPrint(
          'CartServiceTemp: Saved ${cartData.keys.length} users, current user ($currentUserId) has ${cartData[currentUserId]?.length ?? 0} items');
    } catch (e) {
      debugPrint('CartServiceTemp Error saving cart to storage: $e');
    }
  }

  // Refresh cart data for current user
  void _refreshCartForCurrentUser() {
    if (currentUserId.isNotEmpty) {
      _ensureUserCart(currentUserId);
      _calculateTotalPrice();
    }
  }

  // Add item to cart (local storage)
  Future<bool> addToCart(String productId, int quantity) async {
    if (currentUserId.isEmpty) {
      debugPrint('CartServiceTemp: No user logged in');
      Get.snackbar('Error', 'Please login first');
      return false;
    }

    try {
      isLoading.value = true;
      debugPrint(
          'CartServiceTemp: Adding to cart for user $currentUserId - ProductID: $productId, Quantity: $quantity');

      // Ensure user has a cart
      _ensureUserCart(currentUserId);

      // Get current user's cart items
      final userCartItems = _userCartItems[currentUserId]!;

      // Check if item already exists in user's cart
      final existingItemIndex = userCartItems.indexWhere(
        (item) => item.productsId == productId && item.usersId == currentUserId,
      );

      if (existingItemIndex != -1) {
        // Update existing item quantity
        final existingItem = userCartItems[existingItemIndex];
        final newQuantity = existingItem.jumlahBarang + quantity;

        debugPrint(
            'CartServiceTemp: Updating existing item for user $currentUserId, new quantity: $newQuantity');

        userCartItems[existingItemIndex] = existingItem.copyWith(
          jumlahBarang: newQuantity,
          updated: DateTime.now(),
        );

        // Force UI update by triggering reactivity
        _triggerUIUpdate();
        _calculateTotalPrice();
        await _saveCartToStorage(); // Save to persistent storage
        Get.snackbar('Success', 'Cart updated successfully');
        return true;
      } else {
        // Create new cart item for this user
        final newCartItem = Cart(
          id: '${currentUserId}_${DateTime.now().millisecondsSinceEpoch}', // User-specific ID
          productsId: productId,
          jumlahBarang: quantity,
          usersId: currentUserId,
          created: DateTime.now(),
          updated: DateTime.now(),
        );

        userCartItems.add(newCartItem);

        // Force UI update by triggering reactivity
        _triggerUIUpdate();
        _calculateTotalPrice();
        await _saveCartToStorage(); // Save to persistent storage

        debugPrint(
            'CartServiceTemp: Added new item to cart for user $currentUserId');
        Get.snackbar('Success', 'Item added to cart');
        return true;
      }
    } catch (e) {
      debugPrint('CartServiceTemp Error adding to cart: $e');
      Get.snackbar('Error', 'Failed to add item to cart');
    } finally {
      isLoading.value = false;
    }

    return false;
  }

  // Update cart item quantity
  Future<bool> updateCartItemQuantity(String cartId, int newQuantity) async {
    if (currentUserId.isEmpty) return false;

    try {
      if (newQuantity <= 0) {
        return await removeFromCart(cartId);
      }

      _ensureUserCart(currentUserId);
      final userCartItems = _userCartItems[currentUserId]!;

      final index = userCartItems.indexWhere(
          (item) => item.id == cartId && item.usersId == currentUserId);

      if (index != -1) {
        userCartItems[index] = userCartItems[index].copyWith(
          jumlahBarang: newQuantity,
          updated: DateTime.now(),
        );

        // Force UI update by triggering reactivity
        _triggerUIUpdate();
        _calculateTotalPrice();
        await _saveCartToStorage(); // Save to persistent storage

        debugPrint(
            'CartServiceTemp: Updated cart item quantity to $newQuantity');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('CartServiceTemp Error updating cart item: $e');
      return false;
    }
  }

  // Remove item from cart
  Future<bool> removeFromCart(String cartId) async {
    if (currentUserId.isEmpty) return false;

    try {
      _ensureUserCart(currentUserId);
      final userCartItems = _userCartItems[currentUserId]!;

      userCartItems.removeWhere(
          (item) => item.id == cartId && item.usersId == currentUserId);

      // Force UI update by triggering reactivity
      _triggerUIUpdate();
      _calculateTotalPrice();
      await _saveCartToStorage(); // Save to persistent storage

      Get.snackbar('Success', 'Item removed from cart');
      return true;
    } catch (e) {
      debugPrint('CartServiceTemp Error removing from cart: $e');
      return false;
    }
  }

  // Clear all cart items for current user
  Future<bool> clearCart() async {
    if (currentUserId.isEmpty) return false;

    try {
      _ensureUserCart(currentUserId);
      _userCartItems[currentUserId]!.clear();

      // Force UI update by triggering reactivity
      _triggerUIUpdate();
      _calculateTotalPrice();
      await _saveCartToStorage(); // Save to persistent storage

      Get.snackbar('Success', 'Cart cleared successfully');
      return true;
    } catch (e) {
      debugPrint('CartServiceTemp Error clearing cart: $e');
      return false;
    }
  }

  // Get cart item count for current user
  int get cartItemCount {
    if (currentUserId.isEmpty) return 0;
    final userCart = cartItems; // This already filters by current user
    return userCart.fold(0, (sum, item) => sum + item.jumlahBarang);
  }

  // Check if product is in current user's cart
  bool isInCart(String productId) {
    if (currentUserId.isEmpty) return false;
    final userCart = cartItems; // This already filters by current user
    return userCart.any((item) =>
        item.productsId == productId && item.usersId == currentUserId);
  }

  // Get quantity of specific product in current user's cart
  int getProductQuantityInCart(String productId) {
    if (currentUserId.isEmpty) return 0;
    final userCart = cartItems; // This already filters by current user
    final cartItem = userCart.firstWhereOrNull(
      (item) => item.productsId == productId && item.usersId == currentUserId,
    );
    return cartItem?.jumlahBarang ?? 0;
  }

  // Calculate total price using product data for current user
  void _calculateTotalPrice() {
    double total = 0.0;

    if (currentUserId.isNotEmpty) {
      final userCart = cartItems; // This already filters by current user
      for (final cartItem in userCart) {
        final product = _databaseService.getProductById(cartItem.productsId);
        if (product != null) {
          total += product.price * cartItem.jumlahBarang;
        }
      }
    }

    totalPrice.value = total;
    debugPrint(
        'CartServiceTemp: Total price calculated: \$${total.toStringAsFixed(2)}');
  }

  // Get cart items with product details for current user
  List<Map<String, dynamic>> getCartItemsWithProducts() {
    if (currentUserId.isEmpty) return [];

    final userCart = cartItems; // This already filters by current user
    return userCart.map((cartItem) {
      final product = _databaseService.getProductById(cartItem.productsId);
      return {
        'cart': cartItem,
        'product': product,
        'subtotal':
            product != null ? product.price * cartItem.jumlahBarang : 0.0,
      };
    }).toList();
  }

  // Refresh cart data for current user
  Future<void> refreshCart() async {
    _refreshCartForCurrentUser();
  }

  // Debug: Get all cart data for debugging
  Map<String, dynamic> getDebugInfo() {
    return {
      'currentUserId': currentUserId,
      'totalUsers': _userCartItems.keys.length,
      'userCartCounts':
          _userCartItems.map((userId, items) => MapEntry(userId, items.length)),
      'currentUserCartItems': cartItems.length,
      'totalPrice': totalPrice.value,
    };
  }
}
