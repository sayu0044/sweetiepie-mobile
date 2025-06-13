import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:sweetipie/models/order.dart';
import 'package:sweetipie/models/order_item.dart';

import 'package:sweetipie/services/auth_service.dart';
import 'package:sweetipie/services/database_service.dart';

class OrderPaymentController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final DatabaseService _databaseService = Get.find<DatabaseService>();

  // PocketBase instance
  final PocketBase pb = PocketBase('http://127.0.0.1:8090');

  // Observable variables
  final Rx<Order?> order = Rx<Order?>(null);
  final Rx<RecordModel?> user = Rx<RecordModel?>(null);
  final RxList<Map<String, dynamic>> orderItemsWithProducts =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isProcessing = false.obs;

  @override
  void onInit() {
    super.onInit();
    debugPrint('OrderPaymentController: Initializing...');

    // Sync auth from AuthService
    _syncAuthFromAuthService();

    // Get current user info
    user.value = _authService.currentUser.value;
  }

  // Sync authentication from AuthService
  void _syncAuthFromAuthService() {
    try {
      final authToken = _authService.pb.authStore.token;
      final authModel = _authService.pb.authStore.record;

      if (authToken.isNotEmpty) {
        pb.authStore.save(authToken, authModel);
        debugPrint('OrderPaymentController: Auth synced from AuthService');
      } else {
        debugPrint('OrderPaymentController: No auth to sync');
      }
    } catch (e) {
      debugPrint('OrderPaymentController: Error syncing auth: $e');
    }
  }

  // Load order details
  Future<void> loadOrderDetails(String orderId) async {
    try {
      isLoading.value = true;
      debugPrint('OrderPaymentController: Loading order details for: $orderId');

      // 1. Load order
      final orderRecord = await pb.collection('orders').getOne(orderId);
      order.value = Order.fromJson(orderRecord.data);
      debugPrint('OrderPaymentController: Order loaded: ${order.value?.id}');

      // 2. Load order items
      await _loadOrderItems(orderId);
    } catch (e) {
      debugPrint('OrderPaymentController: Error loading order details: $e');
      Get.snackbar(
        'Error',
        'Gagal memuat detail pesanan',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Load order items with product details
  Future<void> _loadOrderItems(String orderId) async {
    try {
      debugPrint(
          'OrderPaymentController: Loading order items for order: $orderId');

      // Get order items from PocketBase
      final orderItemsRecords = await pb.collection('order_items').getFullList(
            filter: 'order_id = "$orderId"',
            sort: 'created',
          );

      List<Map<String, dynamic>> itemsWithProducts = [];

      for (var record in orderItemsRecords) {
        final orderItem = OrderItem.fromJson(record.data);
        final product = _databaseService.getProductById(orderItem.productsId);

        itemsWithProducts.add({
          'order_item': orderItem,
          'product': product,
        });
      }

      orderItemsWithProducts.value = itemsWithProducts;
      debugPrint(
          'OrderPaymentController: Loaded ${itemsWithProducts.length} order items');
    } catch (e) {
      debugPrint('OrderPaymentController: Error loading order items: $e');
    }
  }

  // Confirm QRIS payment
  Future<void> confirmQRISPayment() async {
    try {
      isProcessing.value = true;
      debugPrint('OrderPaymentController: Confirming QRIS payment...');

      await _updateOrderStatus('completed');

      Get.snackbar(
        'Pembayaran Berhasil!',
        'Pembayaran QRIS Anda telah dikonfirmasi',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
        duration: const Duration(seconds: 3),
      );

      // Navigate to success page
      _navigateToSuccessPage();
    } catch (e) {
      debugPrint('OrderPaymentController: Error confirming QRIS payment: $e');
      Get.snackbar(
        'Error',
        'Gagal mengkonfirmasi pembayaran. Silakan coba lagi.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isProcessing.value = false;
    }
  }

  // Confirm cash payment
  Future<void> confirmCashPayment() async {
    try {
      isProcessing.value = true;
      debugPrint('OrderPaymentController: Confirming cash payment...');

      await _updateOrderStatus('completed');

      Get.snackbar(
        'Pembayaran Berhasil!',
        'Pembayaran di kasir telah dikonfirmasi',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
        duration: const Duration(seconds: 3),
      );

      // Navigate to success page
      _navigateToSuccessPage();
    } catch (e) {
      debugPrint('OrderPaymentController: Error confirming cash payment: $e');
      Get.snackbar(
        'Error',
        'Gagal mengkonfirmasi pembayaran. Silakan coba lagi.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isProcessing.value = false;
    }
  }

  // Cancel order
  Future<void> cancelOrder() async {
    // Show confirmation dialog
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Batalkan Pesanan'),
        content: const Text('Apakah Anda yakin ingin membatalkan pesanan ini?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
                foregroundColor: Get.theme.colorScheme.error),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        isProcessing.value = true;
        debugPrint('OrderPaymentController: Cancelling order...');

        await _updateOrderStatus('cancelled');

        Get.snackbar(
          'Pesanan Dibatalkan',
          'Pesanan Anda telah dibatalkan',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
          duration: const Duration(seconds: 3),
        );

        // Navigate back to checkout or home
        Get.offAllNamed('/home');
      } catch (e) {
        debugPrint('OrderPaymentController: Error cancelling order: $e');
        Get.snackbar(
          'Error',
          'Gagal membatalkan pesanan. Silakan coba lagi.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
      } finally {
        isProcessing.value = false;
      }
    }
  }

  // Update order status in database
  Future<void> _updateOrderStatus(String status) async {
    if (order.value == null) return;

    try {
      await pb.collection('orders').update(
        order.value!.id,
        body: {'status': status},
      );

      // Update local order object
      order.value = order.value!.copyWith(status: status);
      debugPrint('OrderPaymentController: Order status updated to: $status');
    } catch (e) {
      debugPrint('OrderPaymentController: Error updating order status: $e');
      rethrow;
    }
  }

  // Navigate to success page
  void _navigateToSuccessPage() {
    Get.offAllNamed('/order-success', arguments: {
      'orderId': order.value?.id,
      'orderTotal': order.value?.totalPrice,
      'paymentMethod': order.value?.paymentMethod,
    });
  }

  // Get current user ID
  String get currentUserId => _authService.currentUser.value?.id ?? '';

  // Check if user is authenticated
  bool get isAuthenticated => _authService.isAuthenticated;

  @override
  void onClose() {
    debugPrint('OrderPaymentController: Disposed');
    super.onClose();
  }
}
