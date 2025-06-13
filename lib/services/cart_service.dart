import 'package:pocketbase/pocketbase.dart';
import 'package:get/get.dart';
import 'package:sweetipie/models/cart.dart';
import 'package:sweetipie/models/product.dart';
import 'package:sweetipie/services/auth_service.dart';
import 'package:sweetipie/services/database_service.dart';

class CartService extends GetxController {
  final PocketBase pb = PocketBase('http://127.0.0.1:8090');
  final AuthService _authService = Get.find<AuthService>();
  final DatabaseService _databaseService = Get.find<DatabaseService>();

  final RxList<Cart> cartItems = <Cart>[].obs;
  final RxBool isLoading = false.obs;
  final RxDouble totalPrice = 0.0.obs;
  final RxDouble selectedTotalPrice = 0.0.obs; // For selective checkout

  // Helper method to convert PocketBase record to Cart
  Cart _recordToCart(dynamic record) {
    final recordData = Map<String, dynamic>.from(record.data);
    recordData['id'] = record.id;
    recordData['created'] = record.created;
    recordData['updated'] = record.updated;
    return Cart.fromJson(recordData);
  }

  @override
  void onInit() {
    super.onInit();
    print('CartService: Initializing...');

    // Sync auth from AuthService
    _syncAuthFromAuthService();

    // Load cart items when service initializes
    if (_authService.isAuthenticated) {
      print('CartService: User is authenticated, fetching cart items');
      fetchCartItems();
    } else {
      print('CartService: User not authenticated, skipping cart fetch');
    }

    // Listen to auth changes
    _authService.currentUser.listen((user) {
      if (user != null) {
        print('CartService: User logged in: ${user.id}');
        _syncAuthFromAuthService();
        fetchCartItems();
      } else {
        print('CartService: User logged out, clearing cart');
        cartItems.clear();
        totalPrice.value = 0.0;
        selectedTotalPrice.value = 0.0;
      }
    });
  }

  // Sync authentication from AuthService
  void _syncAuthFromAuthService() {
    try {
      final authToken = _authService.pb.authStore.token;
      final authModel = _authService.pb.authStore.model;

      if (authToken != null && authModel != null) {
        pb.authStore.save(authToken, authModel);
        print('CartService: Auth synced from AuthService');
        print('CartService: Token: ${authToken.substring(0, 20)}...');
        print('CartService: User ID: ${authModel.id}');
      } else {
        print('CartService: No auth to sync');
      }
    } catch (e) {
      print('CartService: Error syncing auth: $e');
    }
  }

  // Get current user ID
  String get currentUserId => _authService.currentUser.value?.id ?? '';

  // Check if user is properly authenticated
  bool get _isUserAuthenticated {
    final hasUser = currentUserId.isNotEmpty;
    final hasValidToken = pb.authStore.isValid;
    final authServiceAuthenticated = _authService.isAuthenticated;

    print(
        'CartService: Auth check - hasUser: $hasUser, hasValidToken: $hasValidToken, authServiceAuth: $authServiceAuthenticated');

    return hasUser && hasValidToken && authServiceAuthenticated;
  }

  // Fetch all cart items for current user
  Future<void> fetchCartItems() async {
    if (!_isUserAuthenticated) {
      print('CartService: Cannot fetch cart items - user not authenticated');
      return;
    }

    try {
      isLoading.value = true;
      print('CartService: Fetching cart items for user: $currentUserId');

      // Ensure auth is synced before making request
      _syncAuthFromAuthService();

      // DEBUG: Fetch all cart records to see what's in database
      final allRecords = await pb.collection('carts').getFullList();
      print('DEBUG: All cart records in database:');
      for (final record in allRecords) {
        print(
            '  Cart ID: ${record.id}, users_id: ${record.data['users_id']}, products_id: ${record.data['products_id']}, quantity: ${record.data['jumlah_barang']}, selected: ${record.data['is_selected']}');
      }
      print('DEBUG: Current user ID: $currentUserId');

      final records = await pb.collection('carts').getFullList(
            filter: 'users_id = "$currentUserId"',
            sort: '-created',
          );

      cartItems.clear();
      for (final record in records) {
        print('DEBUG: Processing record: ${record.data}');
        try {
          final cart = _recordToCart(record);
          print(
              'DEBUG: Parsed cart - ID: ${cart.id}, ProductID: ${cart.productsId}, UserID: ${cart.usersId}, Quantity: ${cart.jumlahBarang}, Selected: ${cart.isSelected}');
          if (cart.id.isNotEmpty) {
            cartItems.add(cart);
            print('DEBUG: Added cart to list');
          } else {
            print('DEBUG: Skipped cart because ID is empty');
          }
        } catch (e) {
          print('DEBUG: Error parsing cart: $e');
        }
      }

      print('CartService: Fetched ${cartItems.length} cart items');
      _calculateTotalPrice();
      _calculateSelectedTotalPrice();
    } catch (e) {
      print('CartService: Error fetching cart items: $e');

      // Handle specific authentication errors
      if (e.toString().contains('401') || e.toString().contains('403')) {
        print('CartService: Authentication error, refreshing auth...');
        Get.snackbar('Error', 'Session expired. Please login again.');
        await _authService.refreshAuth();
      } else {
        Get.snackbar('Error', 'Failed to load cart items');
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Add item to cart
  Future<bool> addToCart(String productId, int quantity) async {
    print(
        'CartService: addToCart called - ProductID: $productId, Quantity: $quantity');

    if (!_isUserAuthenticated) {
      print('CartService: User not authenticated for addToCart');
      Get.snackbar('Error', 'Please login first to add items to cart');
      return false;
    }

    try {
      isLoading.value = true;
      print(
          'CartService: Adding to cart - ProductID: $productId, Quantity: $quantity, UserID: $currentUserId');

      // Ensure auth is synced before making request
      _syncAuthFromAuthService();

      // Check if item already exists in cart
      final existingItemIndex = cartItems.indexWhere(
        (item) => item.productsId == productId,
      );

      if (existingItemIndex != -1) {
        // Update existing item quantity
        final existingItem = cartItems[existingItemIndex];
        final newQuantity = existingItem.jumlahBarang + quantity;

        print(
            'CartService: Updating existing item, new quantity: $newQuantity');

        final updated = await updateCartItemQuantity(
          existingItem.id,
          newQuantity,
        );

        if (updated) {
          Get.snackbar('Success', 'Cart updated successfully');
          await fetchCartItems();
          return true;
        }
      } else {
        // Create new cart item
        final cartData = {
          'products_id': productId,
          'jumlah_barang': quantity,
          'users_id': currentUserId,
          'is_selected': true, // Default to selected
        };

        print('CartService: Creating new cart item with data: $cartData');

        final record = await pb.collection('carts').create(body: cartData);
        print('CartService: Successfully created cart record: ${record.id}');

        final newCartItem = _recordToCart(record);
        cartItems.add(newCartItem);
        _calculateTotalPrice();
        _calculateSelectedTotalPrice();

        Get.snackbar('Success', 'Item added to cart');
        await fetchCartItems();
        return true;
      }
    } catch (e) {
      print('CartService: Error adding to cart: $e');
      _handleCartError(e);
      await fetchCartItems();
    } finally {
      isLoading.value = false;
    }
    return false;
  }

  // Enhanced update cart item quantity with better error handling
  Future<bool> updateCartItemQuantity(String cartId, int newQuantity) async {
    if (cartId.isEmpty) {
      print('CartService: Cannot update cart with empty ID');
      return false;
    }

    if (!_isUserAuthenticated) {
      print('CartService: User not authenticated for updateCartItemQuantity');
      Get.snackbar('Error', 'Please login to update cart items');
      return false;
    }

    try {
      if (newQuantity <= 0) {
        return await removeFromCart(cartId);
      }

      // Ensure auth is synced before making request
      _syncAuthFromAuthService();

      // Verify cart item belongs to current user
      final cartItem = cartItems.firstWhereOrNull((item) => item.id == cartId);
      if (cartItem == null) {
        print('CartService: Cart item not found');
        return false;
      }

      if (cartItem.usersId != currentUserId) {
        print('CartService: Cart item does not belong to current user');
        return false;
      }

      final updateData = {
        'jumlah_barang': newQuantity,
      };

      final record =
          await pb.collection('carts').update(cartId, body: updateData);
      final updatedItem = _recordToCart(record);

      // Update local cart items
      final index = cartItems.indexWhere((item) => item.id == cartId);
      if (index != -1) {
        cartItems[index] = updatedItem;
        _calculateTotalPrice();
        _calculateSelectedTotalPrice();
      }

      await fetchCartItems();
      return true;
    } catch (e) {
      print('CartService: Error updating cart item quantity: $e');
      _handleCartError(e);
      await fetchCartItems();
      return false;
    }
  }

  // Enhanced remove item from cart with better error handling
  Future<bool> removeFromCart(String cartId) async {
    if (cartId.isEmpty) {
      print('CartService: Cannot remove cart with empty ID');
      return false;
    }

    if (!_isUserAuthenticated) {
      print('CartService: User not authenticated for removeFromCart');
      Get.snackbar('Error', 'Please login to remove cart items');
      return false;
    }

    try {
      print('CartService: Removing cart item: $cartId');

      // Ensure auth is synced before making request
      _syncAuthFromAuthService();

      // Verify cart item belongs to current user
      final cartItem = cartItems.firstWhereOrNull((item) => item.id == cartId);
      if (cartItem == null) {
        print('CartService: Cart item not found locally: $cartId');
        Get.snackbar('Error', 'Cart item not found');
        return false;
      }

      if (cartItem.usersId != currentUserId) {
        print('CartService: Cart item does not belong to current user');
        Get.snackbar('Error', 'Invalid cart item');
        return false;
      }

      print('CartService: Sending delete request for cart: $cartId');
      await pb.collection('carts').delete(cartId);
      print('CartService: Delete successful');

      cartItems.removeWhere((item) => item.id == cartId);
      _calculateTotalPrice();
      _calculateSelectedTotalPrice();

      Get.snackbar('Success', 'Item removed from cart');
      await fetchCartItems();
      return true;
    } catch (e) {
      print('CartService: Error removing from cart: $e');

      if (e.toString().contains('401') || e.toString().contains('403')) {
        print('CartService: Authentication error during removeFromCart');
        Get.snackbar('Error', 'Authentication failed. Please login again.');
        await _authService.refreshAuth();
      } else if (e.toString().contains('404')) {
        print('CartService: Cart item not found in database, removing locally');
        // Remove from local list if not found in database
        cartItems.removeWhere((item) => item.id == cartId);
        _calculateTotalPrice();
        _calculateSelectedTotalPrice();
        Get.snackbar('Success', 'Item removed from cart');
        await fetchCartItems();
        return true;
      } else {
        Get.snackbar(
            'Error', 'Failed to remove item from cart. Please try again.');
      }
      return false;
    }
  }

  // Toggle item selection for checkout
  Future<bool> toggleItemSelection(String cartId) async {
    if (!_isUserAuthenticated) {
      print('CartService: User not authenticated for toggleItemSelection');
      return false;
    }

    try {
      final cartItem = cartItems.firstWhereOrNull((item) => item.id == cartId);
      if (cartItem == null) {
        print('CartService: Cart item not found for ID: $cartId');
        return false;
      }

      final currentState = cartItem.isSelected;
      final newSelectionState = !currentState;
      print(
          'CartService: Toggling selection for cart $cartId from $currentState to $newSelectionState');

      final updateData = {
        'is_selected': newSelectionState,
      };

      final record =
          await pb.collection('carts').update(cartId, body: updateData);
      print('CartService: Database updated successfully');

      final updatedItem = _recordToCart(record);
      print(
          'CartService: Updated item selection state: ${updatedItem.isSelected}');

      // Update local cart items
      final index = cartItems.indexWhere((item) => item.id == cartId);
      if (index != -1) {
        cartItems[index] = updatedItem;
        _calculateSelectedTotalPrice();
        print('CartService: Local cart updated at index $index');
      }

      await fetchCartItems();
      return true;
    } catch (e) {
      print('CartService: Error toggling item selection: $e');
      _handleCartError(e);
      await fetchCartItems();
      return false;
    }
  }

  // Select/deselect all items
  Future<void> selectAllItems(bool selected) async {
    if (!_isUserAuthenticated) {
      print('CartService: User not authenticated for selectAllItems');
      return;
    }

    try {
      print(
          'CartService: ${selected ? 'Selecting' : 'Unselecting'} all ${cartItems.length} items');

      // Update all items in database
      for (final item in cartItems) {
        final updateData = {
          'is_selected': selected,
        };
        print('CartService: Updating cart ${item.id} to selected: $selected');
        await pb.collection('carts').update(item.id, body: updateData);
      }

      // Update local items
      for (int i = 0; i < cartItems.length; i++) {
        cartItems[i] = cartItems[i].copyWith(isSelected: selected);
        print(
            'CartService: Local item ${i} updated to selected: ${cartItems[i].isSelected}');
      }

      _calculateSelectedTotalPrice();
      print('CartService: Refreshing cart after selectAllItems');
      await fetchCartItems();
    } catch (e) {
      print('CartService: Error selecting all items: $e');
      _handleCartError(e);
      await fetchCartItems();
    }
  }

  // Get selected cart items for checkout
  List<Cart> get selectedCartItems {
    return cartItems.where((item) => item.isSelected).toList();
  }

  // Get selected cart items with product details for checkout
  List<Map<String, dynamic>> getSelectedCartItemsWithProducts() {
    final selectedItems = selectedCartItems;
    return selectedItems.map((cartItem) {
      final product = _databaseService.getProductById(cartItem.productsId);
      return {
        'cart': cartItem,
        'product': product,
        'subtotal':
            product != null ? product.price * cartItem.jumlahBarang : 0.0,
      };
    }).toList();
  }

  // Calculate total price for selected items
  void _calculateSelectedTotalPrice() {
    double total = 0.0;

    for (final cartItem in selectedCartItems) {
      final product = _databaseService.getProductById(cartItem.productsId);
      if (product != null) {
        total += product.price * cartItem.jumlahBarang;
      }
    }

    selectedTotalPrice.value = total;
    print('CartService: Selected total price: \$${total.toStringAsFixed(2)}');
  }

  // Get count of selected items
  int get selectedItemCount {
    return selectedCartItems.fold(0, (sum, item) => sum + item.jumlahBarang);
  }

  // Proceed to checkout with selected items
  Future<bool> proceedToCheckout() async {
    final selectedItems = selectedCartItems;

    if (selectedItems.isEmpty) {
      Get.snackbar('Error', 'Please select at least one item to checkout');
      return false;
    }

    print(
        'CartService: Proceeding to checkout with ${selectedItems.length} items');
    print(
        'CartService: Selected total: \$${selectedTotalPrice.value.toStringAsFixed(2)}');

    // You can add checkout logic here
    // For example, navigate to checkout page or create order

    return true;
  }

  // Remove selected items from cart after successful checkout
  Future<bool> removeSelectedItemsAfterCheckout() async {
    if (!_isUserAuthenticated) {
      return false;
    }

    try {
      final selectedItems = selectedCartItems;

      for (final item in selectedItems) {
        await pb.collection('carts').delete(item.id);
      }

      // Remove from local list
      cartItems.removeWhere((item) => item.isSelected);
      _calculateTotalPrice();
      _calculateSelectedTotalPrice();

      print(
          'CartService: Removed ${selectedItems.length} items after checkout');
      await fetchCartItems();
      return true;
    } catch (e) {
      print('CartService: Error removing selected items: $e');
      await fetchCartItems();
      return false;
    }
  }

  // Clear all cart items for current user
  Future<bool> clearCart() async {
    if (!_isUserAuthenticated) {
      print('CartService: User not authenticated for clearCart');
      return false;
    }

    try {
      isLoading.value = true;
      print('CartService: ========== CLEARING CART ==========');
      print('CartService: Current user ID: $currentUserId');

      // Ensure auth is synced before making request
      _syncAuthFromAuthService();

      // Get all cart items for current user from database
      print('CartService: Fetching all cart items from database...');
      final records = await pb.collection('carts').getFullList(
            filter: 'users_id = "$currentUserId"',
          );

      print('CartService: Found ${records.length} items in database to delete');

      // Delete all items from database
      int deletedCount = 0;
      for (final record in records) {
        try {
          await pb.collection('carts').delete(record.id);
          deletedCount++;
          print('CartService: Deleted cart item: ${record.id}');
        } catch (e) {
          print('CartService: Failed to delete cart item ${record.id}: $e');
        }
      }

      // Clear local cart items
      cartItems.clear();
      _calculateTotalPrice();
      _calculateSelectedTotalPrice();

      print(
          'CartService: Successfully deleted $deletedCount items from database');
      print(
          'CartService: Local cart cleared, items count: ${cartItems.length}');
      print('CartService: ========== CART CLEARED ==========');

      Get.snackbar(
          'Success', 'Cart cleared successfully ($deletedCount items removed)');
      await fetchCartItems();
      return true;
    } catch (e) {
      print('CartService: ❌ Error clearing cart: $e');

      if (e.toString().contains('401') || e.toString().contains('403')) {
        print('CartService: Authentication error during clearCart');
        Get.snackbar('Error', 'Authentication failed. Please login again.');
        await _authService.refreshAuth();
      } else {
        Get.snackbar('Error', 'Failed to clear cart');
      }
      await fetchCartItems();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Force refresh cart from database
  Future<void> forceRefreshCart() async {
    print('CartService: Force refreshing cart from database...');
    cartItems.clear();
    totalPrice.value = 0.0;
    selectedTotalPrice.value = 0.0;
    await fetchCartItems();
  }

  // Regular refresh cart (alias for fetchCartItems)
  Future<void> refreshCart() async {
    print('CartService: Refreshing cart...');
    await fetchCartItems();
  }

  // Get cart item count
  int get cartItemCount {
    return cartItems.fold(0, (sum, item) => sum + item.jumlahBarang);
  }

  // Check if product is in cart
  bool isInCart(String productId) {
    return cartItems.any((item) => item.productsId == productId);
  }

  // Get quantity of specific product in cart
  int getProductQuantityInCart(String productId) {
    final cartItem = cartItems.firstWhereOrNull(
      (item) => item.productsId == productId,
    );
    return cartItem?.jumlahBarang ?? 0;
  }

  // Calculate total price using product data
  void _calculateTotalPrice() {
    double total = 0.0;

    for (final cartItem in cartItems) {
      final product = _databaseService.getProductById(cartItem.productsId);
      if (product != null) {
        total += product.price * cartItem.jumlahBarang;
      }
    }

    totalPrice.value = total;
    totalPrice.refresh();
  }

  // Get cart items with product details
  List<Map<String, dynamic>> getCartItemsWithProducts() {
    return cartItems.map((cartItem) {
      final product = _databaseService.getProductById(cartItem.productsId);
      return {
        'cart': cartItem,
        'product': product,
        'subtotal':
            product != null ? product.price * cartItem.jumlahBarang : 0.0,
      };
    }).toList();
  }

  // Helper method to handle cart errors
  void _handleCartError(dynamic e) {
    if (e.toString().contains('401') || e.toString().contains('403')) {
      print('CartService: Authentication error');
      Get.snackbar('Error', 'Session expired. Please login again.');
      _authService.refreshAuth();
    } else if (e.toString().contains('404')) {
      print('CartService: Resource not found');
      Get.snackbar('Error', 'Item not found. Please try again.');
    } else {
      print('CartService: Unexpected error: $e');
      Get.snackbar('Error', 'An unexpected error occurred. Please try again.');
    }
  }
}
