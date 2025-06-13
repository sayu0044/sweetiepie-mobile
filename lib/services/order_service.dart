import 'package:get/get.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:sweetipie/models/order.dart';
import 'package:sweetipie/models/order_item.dart';
import 'package:sweetipie/services/auth_service.dart';
import 'package:sweetipie/services/database_service.dart';
import 'package:sweetipie/services/cart_service.dart';
import 'package:flutter/foundation.dart';

class OrderService extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final DatabaseService _databaseService = Get.find<DatabaseService>();
  final CartService _cartService = Get.find<CartService>();

  final RxList<Order> orders = <Order>[].obs;
  final RxBool isLoading = false.obs;
  final RxString currentOrderId = ''.obs;

  // Get current user ID
  String get currentUserId => _authService.currentUser.value?.id ?? '';

  // Get PocketBase instance
  PocketBase get pb => _authService.pb;

  @override
  void onInit() {
    super.onInit();
    debugPrint('OrderService: Initialized');

    // Listen to auth changes
    _authService.currentUser.listen((user) {
      if (user != null) {
        loadUserOrders();
      } else {
        orders.clear();
      }
    });
  }

  // Create new order from cart items
  Future<bool> createOrderFromCart({String paymentMethodId = 'cash'}) async {
    if (currentUserId.isEmpty) {
      Get.snackbar('Error', 'Please login first');
      return false;
    }

    try {
      isLoading.value = true;

      // Get cart items
      final cartItems = _cartService.cartItems;
      if (cartItems.isEmpty) {
        Get.snackbar('Error', 'Cart is empty');
        return false;
      }

      // Calculate total price
      double totalPrice = 0.0;
      for (final cartItem in cartItems) {
        final product = _databaseService.getProductById(cartItem.productsId);
        if (product != null) {
          totalPrice += product.price * cartItem.jumlahBarang;
        }
      }

      debugPrint(
          'OrderService: Creating order with total: \$${totalPrice.toStringAsFixed(2)}');

      // Create order data
      final orderData = {
        'users_id': currentUserId,
        'status': 'pending',
        'total_price': totalPrice,
      };

      debugPrint('OrderService: Creating order with data: $orderData');

      // Create order in PocketBase
      final orderRecord = await pb.collection('orders').create(body: orderData);
      final orderId = orderRecord.id;
      currentOrderId.value = orderId;

      debugPrint('OrderService: Created order with ID: $orderId');

      // Create order items
      List<Map<String, dynamic>> orderItemsData = [];
      for (final cartItem in cartItems) {
        final product = _databaseService.getProductById(cartItem.productsId);
        if (product != null) {
          final subtotal = cartItem.jumlahBarang * product.price;
          orderItemsData.add({
            'order_id': orderId,
            'products_id': cartItem.productsId,
            'quantity': cartItem.jumlahBarang,
            'unit_price': product.price,
            'subtotal': subtotal,
          });
        }
      }

      // Bulk create order items
      for (final itemData in orderItemsData) {
        await pb.collection('order_items').create(body: itemData);
      }

      debugPrint('OrderService: Created ${orderItemsData.length} order items');

      // Clear cart after successful order
      await _cartService.clearCart();

      // Reload user orders
      await loadUserOrders();

      Get.snackbar('Success', 'Order created successfully!');
      return true;
    } catch (e) {
      debugPrint('OrderService Error creating order: $e');
      Get.snackbar('Error', 'Failed to create order: ${e.toString()}');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Load user orders
  Future<void> loadUserOrders() async {
    if (currentUserId.isEmpty) return;

    try {
      isLoading.value = true;

      final records = await pb.collection('orders').getList(
            filter: 'users_id = "$currentUserId"',
            sort: '-created',
          );

      orders.value = records.items.map((record) {
        return Order.fromJson(record.toJson());
      }).toList();

      debugPrint(
          'OrderService: Loaded ${orders.length} orders for user $currentUserId');
    } catch (e) {
      debugPrint('OrderService Error loading orders: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Get order items for a specific order
  Future<List<OrderItem>> getOrderItems(String orderId) async {
    try {
      final records = await pb.collection('order_items').getList(
            filter: 'order_id = "$orderId"',
          );

      return records.items.map((record) {
        return OrderItem.fromJson(record.toJson());
      }).toList();
    } catch (e) {
      debugPrint('OrderService Error loading order items: $e');
      return [];
    }
  }

  // Update order status
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      await pb.collection('orders').update(orderId, body: {
        'status': status,
      });

      // Reload orders
      await loadUserOrders();

      Get.snackbar('Success', 'Order status updated to $status');
      return true;
    } catch (e) {
      debugPrint('OrderService Error updating order status: $e');
      Get.snackbar('Error', 'Failed to update order status');
      return false;
    }
  }

  // Get order by ID
  Order? getOrderById(String orderId) {
    return orders.firstWhereOrNull((order) => order.id == orderId);
  }

  // Get order items with product details
  Future<List<Map<String, dynamic>>> getOrderItemsWithProducts(
      String orderId) async {
    final orderItems = await getOrderItems(orderId);

    return orderItems.map((orderItem) {
      final product = _databaseService.getProductById(orderItem.productsId);
      return {
        'order_item': orderItem,
        'product': product,
        'subtotal': orderItem.subtotal,
      };
    }).toList();
  }

  // Get orders count
  int get ordersCount => orders.length;

  // Get pending orders count
  int get pendingOrdersCount =>
      orders.where((order) => order.status == 'pending').length;

  // Get completed orders count
  int get completedOrdersCount =>
      orders.where((order) => order.status == 'completed').length;
}
