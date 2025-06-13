import 'package:get/get.dart';
import 'package:sweetipie/controllers/cart_controller.dart';
import 'package:sweetipie/models/cart.dart';
import 'package:sweetipie/models/order.dart';

import 'package:sweetipie/models/product.dart';
import 'package:sweetipie/services/auth_service.dart';

import 'package:pocketbase/pocketbase.dart';

class CheckoutController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  final CartController _cartController = Get.find<CartController>();
  
  // PocketBase instance
  final PocketBase pb = PocketBase('http://127.0.0.1:8090');

  // Observable variables
  final RxList<Map<String, dynamic>> cartItemsWithProducts = <Map<String, dynamic>>[].obs;
  final RxString selectedPaymentMethod = ''.obs;
  final RxString orderNotes = ''.obs;
  final RxBool isProcessing = false.obs;
  final RxDouble totalPrice = 0.0.obs;
  final RxInt totalItems = 0.obs;

  @override
  void onInit() {
    super.onInit();
    print('CheckoutController: Initializing...');
    
    // Sync auth from AuthService
    _syncAuthFromAuthService();
    
    // Load selected cart items for checkout
    _loadCartItemsForCheckout();
  }

  // Sync authentication from AuthService
  void _syncAuthFromAuthService() {
    try {
      final authToken = _authService.pb.authStore.token;
      final authModel = _authService.pb.authStore.model;

      if (authToken != null && authModel != null) {
        pb.authStore.save(authToken, authModel);
        print('CheckoutController: Auth synced from AuthService');
      } else {
        print('CheckoutController: No auth to sync');
      }
    } catch (e) {
      print('CheckoutController: Error syncing auth: $e');
    }
  }

  // Load selected cart items for checkout
  void _loadCartItemsForCheckout() {
    try {
      print('CheckoutController: Loading cart items for checkout...');
      
      // Get selected cart items from CartController
      final selectedItems = _cartController.cartItemsWithProducts
          .where((item) => _cartController.isItemSelected(item['cart'].id))
          .toList();

      cartItemsWithProducts.value = selectedItems;
      
      // Calculate totals
      _calculateTotals();
      
      print('CheckoutController: Loaded ${cartItemsWithProducts.length} items for checkout');
    } catch (e) {
      print('CheckoutController: Error loading cart items: $e');
    }
  }

  // Calculate totals
  void _calculateTotals() {
    double total = 0.0;
    int items = 0;

    for (var item in cartItemsWithProducts) {
      final cart = item['cart'] as Cart;
      final product = item['product'] as Product?;
      
      if (product != null) {
        total += cart.jumlahBarang * product.price;
        items += cart.jumlahBarang;
      }
    }

    totalPrice.value = total;
    totalItems.value = items;
  }

  // Process checkout
  Future<void> processCheckout() async {
    if (selectedPaymentMethod.value.isEmpty) {
      Get.snackbar(
        'Error',
        'Silakan pilih metode pembayaran',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return;
    }

    if (cartItemsWithProducts.isEmpty) {
      Get.snackbar(
        'Error',
        'Tidak ada item untuk checkout',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return;
    }

    try {
      isProcessing.value = true;
      print('CheckoutController: Processing checkout...');

      // 1. Create order
      final order = await _createOrder();
      print('CheckoutController: Order created with ID: ${order.id}');

      // 2. Create order items
      await _createOrderItems(order.id);
      print('CheckoutController: Order items created');

      // 3. Remove selected items from cart
      await _removeSelectedItemsFromCart();
      print('CheckoutController: Selected items removed from cart');

      // 4. Show success message
      Get.snackbar(
        'Pesanan Berhasil!',
        'Pesanan Anda telah dibuat dengan nomor: ${order.id}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
        duration: const Duration(seconds: 5),
      );

      // 5. Navigate to order payment screen
      Get.offAllNamed('/order-payment', arguments: {
        'orderId': order.id,
      });

    } catch (e) {
      print('CheckoutController: Error processing checkout: $e');
      Get.snackbar(
        'Error',
        'Gagal memproses pesanan. Silakan coba lagi.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isProcessing.value = false;
    }
  }

  // Create order in PocketBase
  Future<Order> _createOrder() async {
    final userId = _authService.currentUser.value?.id;
    if (userId == null || userId.isEmpty) {
      throw Exception('User not authenticated');
    }

    final orderData = {
      'users_id': userId,
      'payment_method': selectedPaymentMethod.value,
      'status': 'pending',
      'total_price': totalPrice.value,
      'order_date': DateTime.now().toIso8601String().split('T')[0],
      'catatan': orderNotes.value.isEmpty ? null : orderNotes.value,
    };

    print('CheckoutController: Creating order with data: $orderData');

    final record = await pb.collection('orders').create(body: orderData);
    return Order.fromJson(record.data);
  }

  // Create order items in PocketBase
  Future<void> _createOrderItems(String orderId) async {
    for (var item in cartItemsWithProducts) {
      final cart = item['cart'] as Cart;
      final product = item['product'] as Product?;
      
      if (product != null) {
        final subtotal = cart.jumlahBarang * product.price;
        
        final orderItemData = {
          'order_id': orderId,
          'products_id': cart.productsId,
          'quantity': cart.jumlahBarang,
          'unit_price': product.price,
          'subtotal': subtotal,
        };

        print('CheckoutController: Creating order item: $orderItemData');

        await pb.collection('order_items').create(body: orderItemData);
      }
    }
  }

  // Remove selected items from cart
  Future<void> _removeSelectedItemsFromCart() async {
    final selectedCartIds = cartItemsWithProducts
        .map((item) => (item['cart'] as Cart).id)
        .toList();

    for (String cartId in selectedCartIds) {
      try {
        await _cartController.removeFromCart(cartId);
      } catch (e) {
        print('CheckoutController: Error removing cart item $cartId: $e');
      }
    }

    // Refresh cart controller
    await _cartController.forceRefreshCart();
  }

  // Get current user ID
  String get currentUserId => _authService.currentUser.value?.id ?? '';

  // Check if user is authenticated
  bool get isAuthenticated => _authService.isAuthenticated;

  @override
  void onClose() {
    print('CheckoutController: Disposed');
    super.onClose();
  }
}
