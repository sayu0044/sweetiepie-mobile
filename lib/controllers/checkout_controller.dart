import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sweetipie/controllers/cart_controller.dart';
import 'package:sweetipie/models/cart.dart';
import 'package:sweetipie/models/order.dart';
import 'package:sweetipie/models/product.dart';
import 'package:sweetipie/services/auth_service.dart';
import 'package:sweetipie/utils/debug_orders.dart';
import 'package:sweetipie/utils/notification_utils.dart';
import 'package:flutter/foundation.dart';

import 'package:pocketbase/pocketbase.dart';

class CheckoutController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  final CartController _cartController = Get.find<CartController>();

  // PocketBase instance
  final PocketBase pb = PocketBase('http://127.0.0.1:8090');

  // Observable variables
  final RxList<Map<String, dynamic>> cartItemsWithProducts =
      <Map<String, dynamic>>[].obs;
  final RxString selectedPaymentMethod = ''.obs;
  final RxString orderNotes = ''.obs;
  final RxBool isProcessing = false.obs;
  final RxDouble totalPrice = 0.0.obs;
  final RxInt totalItems = 0.obs;

  @override
  void onInit() {
    super.onInit();
    debugPrint('CheckoutController: Initializing...');

    // Sync auth from AuthService
    _syncAuthFromAuthService();

    // Load selected cart items for checkout
    _loadCartItemsForCheckout();
  }

  // Sync authentication from AuthService
  void _syncAuthFromAuthService() {
    try {
      final authToken = _authService.pb.authStore.token;
      final authModel = _authService.pb.authStore.record;

      if (authToken.isNotEmpty) {
        pb.authStore.save(authToken, authModel);
        debugPrint('CheckoutController: Auth synced from AuthService');
      } else {
        debugPrint('CheckoutController: No auth to sync');
      }
    } catch (e) {
      debugPrint('CheckoutController: Error syncing auth: $e');
    }
  }

  // Load selected cart items for checkout
  void _loadCartItemsForCheckout() {
    try {
      debugPrint('CheckoutController: Loading cart items for checkout...');

      // Get selected cart items from CartController
      final selectedItems = _cartController.cartItemsWithProducts
          .where((item) => _cartController.isItemSelected(item['cart'].id))
          .toList();

      cartItemsWithProducts.value = selectedItems;

      // Calculate totals
      _calculateTotals();

      debugPrint(
          'CheckoutController: Loaded ${cartItemsWithProducts.length} items for checkout');
    } catch (e) {
      debugPrint('CheckoutController: Error loading cart items: $e');
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
      NotificationUtils.showError('Silakan pilih metode pembayaran');
      return;
    }

    if (cartItemsWithProducts.isEmpty) {
      NotificationUtils.showError('Tidak ada item untuk checkout');
      return;
    }

    try {
      isProcessing.value = true;
      debugPrint('CheckoutController: Processing checkout...');

      // 1. Create order
      final order = await _createOrder();
      debugPrint('CheckoutController: Order created with ID: ${order.id}');

      // 2. Create order items
      await _createOrderItems(order.id);
      debugPrint('CheckoutController: Order items created');

      // 3. Remove selected items from cart
      await _removeSelectedItemsFromCart();
      debugPrint('CheckoutController: Selected items removed from cart');

      // 4. Show success message
      NotificationUtils.showOrderSuccess(order.id);

      // 5. Navigate to order payment screen
      Get.offAllNamed('/order-payment', arguments: {
        'orderId': order.id,
      });
    } catch (e) {
      debugPrint('CheckoutController: Error processing checkout: $e');

      // Run debug tests when checkout fails
      debugPrint('🔍 Running debug tests to identify the issue...');
      await DebugOrdersUtil.testOrdersCollection();
      await DebugOrdersUtil.suggestAccessRules();

      // Check if it's a collections issue
      if (e.toString().contains('Failed to create record') ||
          e.toString().contains('status: 400') ||
          e.toString().contains('collection')) {
        NotificationUtils.showError(
          'Collection "orders" belum dibuat di PocketBase. Silakan buat collection orders dan order_items terlebih dahulu.',
          title: 'Database Error',
        );
      } else {
        NotificationUtils.showError(
            'Gagal memproses pesanan. Silakan coba lagi.');
      }
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

    // Format order data properly for PocketBase
    final orderData = <String, dynamic>{
      'users_id': userId,
      'payment_method': selectedPaymentMethod.value,
      'status': 'pending',
      'total_price': totalPrice.value.toDouble(), // Ensure it's a double
      'order_date': DateTime.now().toIso8601String().split('T')[0], // Date only
    };

    // Only add catatan if it's not empty
    if (orderNotes.value.isNotEmpty) {
      orderData['catatan'] = orderNotes.value;
    }

    debugPrint('CheckoutController: Creating order with data: $orderData');

    try {
      final record = await pb.collection('orders').create(body: orderData);
      debugPrint(
          'CheckoutController: Order record created successfully: ${record.data}');
      return Order.fromJson(record.data);
    } catch (e) {
      debugPrint('CheckoutController: Detailed error creating order: $e');

      // Try with minimal data first to isolate the issue
      final minimalData = <String, dynamic>{
        'users_id': userId,
        'payment_method': selectedPaymentMethod.value,
        'status': 'pending',
        'total_price': totalPrice.value.toDouble(),
        'order_date': DateTime.now().toIso8601String().split('T')[0],
      };

      debugPrint(
          'CheckoutController: Retrying with minimal data: $minimalData');
      final record = await pb.collection('orders').create(body: minimalData);
      return Order.fromJson(record.data);
    }
  }

  // Create order items in PocketBase
  Future<void> _createOrderItems(String orderId) async {
    for (var item in cartItemsWithProducts) {
      final cart = item['cart'] as Cart;
      final product = item['product'] as Product?;

      if (product != null) {
        final subtotal = cart.jumlahBarang * product.price;

        final orderItemData = <String, dynamic>{
          'order_id': orderId,
          'products_id': cart.productsId,
          'quantity': cart.jumlahBarang,
          'unit_price': product.price.toDouble(), // Ensure it's a double
          'subtotal': subtotal.toDouble(), // Ensure it's a double
        };

        debugPrint('CheckoutController: Creating order item: $orderItemData');

        try {
          await pb.collection('order_items').create(body: orderItemData);
          debugPrint('CheckoutController: Order item created successfully');
        } catch (e) {
          debugPrint('CheckoutController: Error creating order item: $e');
          rethrow; // Re-throw to handle in parent function
        }
      }
    }
  }

  // Remove selected items from cart
  Future<void> _removeSelectedItemsFromCart() async {
    final selectedCartIds =
        cartItemsWithProducts.map((item) => (item['cart'] as Cart).id).toList();

    for (String cartId in selectedCartIds) {
      try {
        await _cartController.removeFromCart(cartId);
      } catch (e) {
        debugPrint('CheckoutController: Error removing cart item $cartId: $e');
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
    debugPrint('CheckoutController: Disposed');
    super.onClose();
  }
}
