import 'package:get/get.dart';
import 'package:sweetipie/models/product.dart';
import 'package:sweetipie/models/cart.dart';
import 'package:sweetipie/services/cart_service.dart';

class CartController extends GetxController {
  final CartService _cartService = Get.find<CartService>();

  // Delegate to CartService for database-backed operations
  List<Map<String, dynamic>> get cartItemsWithProducts =>
      _cartService.getCartItemsWithProducts();

  // Get all cart items
  List<Cart> get cartItems => _cartService.cartItems;

  // Get selected cart items for checkout
  List<Cart> get selectedCartItems => _cartService.selectedCartItems;

  // Get selected cart items with product details for checkout
  List<Map<String, dynamic>> get selectedCartItemsWithProducts =>
      _cartService.getSelectedCartItemsWithProducts();

  double get total => _cartService.totalPrice.value;

  // Total price for selected items only
  double get selectedTotal => _cartService.selectedTotalPrice.value;

  int get itemCount => _cartService.cartItemCount;

  // Count of selected items only
  int get selectedItemCount => _cartService.selectedItemCount;

  bool get isLoading => _cartService.isLoading.value;

  // Check if all items are selected (tristate: true=all, false=none, null=some)
  bool? get allItemsSelected {
    if (cartItems.isEmpty) return false;

    final selectedCount = cartItems.where((item) => item.isSelected).length;
    final totalCount = cartItems.length;

    if (selectedCount == 0) return false; // None selected
    if (selectedCount == totalCount) return true; // All selected
    return null; // Some selected (indeterminate state)
  }

  // Check if any items are selected
  bool get hasSelectedItems {
    return selectedCartItems.isNotEmpty;
  }

  Future<void> addToCart(Product product, {int quantity = 1}) async {
    await _cartService.addToCart(product.id, quantity);
  }

  Future<void> updateQuantity(String cartId, int newQuantity) async {
    await _cartService.updateCartItemQuantity(cartId, newQuantity);
  }

  Future<void> removeFromCart(String cartId) async {
    await _cartService.removeFromCart(cartId);
  }

  Future<void> clearCart() async {
    await _cartService.clearCart();
  }

  // Toggle selection for a specific cart item
  Future<void> toggleItemSelection(String cartId) async {
    await _cartService.toggleItemSelection(cartId);
  }

  // Select/deselect all items
  Future<void> selectAllItems(bool selected) async {
    await _cartService.selectAllItems(selected);
  }

  // Proceed to checkout with selected items
  Future<bool> proceedToCheckout() async {
    return await _cartService.proceedToCheckout();
  }

  // Remove selected items after successful checkout
  Future<bool> removeSelectedItemsAfterCheckout() async {
    return await _cartService.removeSelectedItemsAfterCheckout();
  }

  bool isInCart(String productId) {
    return _cartService.isInCart(productId);
  }

  int getProductQuantity(String productId) {
    return _cartService.getProductQuantityInCart(productId);
  }

  // Check if a specific cart item is selected
  bool isItemSelected(String cartId) {
    final cartItem = cartItems.firstWhereOrNull((item) => item.id == cartId);
    return cartItem?.isSelected ?? false;
  }

  Future<void> refreshCart() async {
    await _cartService.refreshCart();
  }

  // Force refresh cart from database (useful after app restart)
  Future<void> forceRefreshCart() async {
    await _cartService.forceRefreshCart();
  }
}

// Legacy CartItem class for backwards compatibility
class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });
}
