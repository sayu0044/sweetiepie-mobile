import 'package:get/get.dart';
import 'package:sweetipie/services/order_service.dart';
import 'package:sweetipie/services/cart_service.dart';

class CheckoutController extends GetxController {
  final OrderService _orderService = Get.find<OrderService>();
  final CartService _cartService = Get.find<CartService>();

  final RxString selectedPaymentMethod = 'cash'.obs;
  final RxBool isProcessing = false.obs;
  final RxString customerName = ''.obs;
  final RxString customerPhone = ''.obs;
  final RxString customerAddress = ''.obs;
  final RxString specialNotes = ''.obs;

  // Payment method options
  final List<Map<String, dynamic>> paymentMethods = [
    {
      'id': 'cash',
      'name': 'Cash on Delivery',
      'icon': '💵',
      'description': 'Pay when you receive your order'
    },
    {
      'id': 'bank_transfer',
      'name': 'Bank Transfer',
      'icon': '🏦',
      'description': 'Transfer to our bank account'
    },
    {
      'id': 'digital_wallet',
      'name': 'Digital Wallet',
      'icon': '📱',
      'description': 'Pay with e-wallet (OVO, GoPay, DANA)'
    },
  ];

  // Get cart items and total
  List<Map<String, dynamic>> get cartItemsWithProducts =>
      _cartService.getCartItemsWithProducts();

  double get totalPrice => _cartService.totalPrice.value;

  int get itemCount => _cartService.cartItemCount;

  // Delivery fee (static for now)
  double get deliveryFee => 5.0;

  // Tax (10%)
  double get tax => totalPrice * 0.1;

  // Grand total
  double get grandTotal => totalPrice + deliveryFee + tax;

  @override
  void onInit() {
    super.onInit();
    print('CheckoutController: Initialized');
  }

  // Process checkout
  Future<bool> processCheckout() async {
    if (cartItemsWithProducts.isEmpty) {
      Get.snackbar('Error', 'Cart is empty');
      return false;
    }

    if (customerName.value.isEmpty) {
      Get.snackbar('Error', 'Please enter your name');
      return false;
    }

    if (customerPhone.value.isEmpty) {
      Get.snackbar('Error', 'Please enter your phone number');
      return false;
    }

    if (customerAddress.value.isEmpty) {
      Get.snackbar('Error', 'Please enter your delivery address');
      return false;
    }

    try {
      isProcessing.value = true;

      print('CheckoutController: Processing checkout...');
      print('Payment Method: ${selectedPaymentMethod.value}');
      print('Total Amount: \$${grandTotal.toStringAsFixed(2)}');

      // Create order through OrderService
      final success = await _orderService.createOrderFromCart(
        paymentMethodId: selectedPaymentMethod.value,
      );

      if (success) {
        // Navigate to order success screen
        Get.offAllNamed('/order-success', arguments: {
          'orderId': _orderService.currentOrderId.value,
          'total': grandTotal,
          'paymentMethod': selectedPaymentMethod.value,
        });

        // Reset form
        _resetForm();
        return true;
      }

      return false;
    } catch (e) {
      print('CheckoutController Error: $e');
      Get.snackbar('Error', 'Failed to process checkout');
      return false;
    } finally {
      isProcessing.value = false;
    }
  }

  // Reset form after successful checkout
  void _resetForm() {
    customerName.value = '';
    customerPhone.value = '';
    customerAddress.value = '';
    specialNotes.value = '';
    selectedPaymentMethod.value = 'cash';
  }

  // Get payment method info
  Map<String, dynamic>? getPaymentMethodInfo(String id) {
    return paymentMethods.firstWhereOrNull((method) => method['id'] == id);
  }

  // Validate form
  bool isFormValid() {
    return customerName.value.isNotEmpty &&
        customerPhone.value.isNotEmpty &&
        customerAddress.value.isNotEmpty;
  }
}
