import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sweetipie/controllers/cart_controller.dart';
import 'package:sweetipie/models/cart.dart';
import 'package:sweetipie/models/product.dart';
import 'package:sweetipie/theme/app_theme.dart';
import 'package:sweetipie/widgets/bottom_nav_bar.dart';
import 'package:sweetipie/utils/notification_utils.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  CartScreenState createState() => CartScreenState();
}

class CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    // Force refresh cart when screen loads to ensure latest data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<CartController>().forceRefreshCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final CartController cartController = Get.find<CartController>();

    return Scaffold(
      backgroundColor: Colors.pink[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Cart',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(
              () => cartController.itemCount == 0
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Your cart is empty',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add some items to your cart',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : cartController.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            // Select All/None Row
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  Obx(() => Checkbox(
                                        value: cartController.allItemsSelected,
                                        tristate:
                                            true, // Allow indeterminate state
                                        onChanged: (bool? value) async {
                                          // Handle tristate logic
                                          final currentState =
                                              cartController.allItemsSelected;
                                          bool shouldSelectAll;

                                          if (currentState == true) {
                                            // All selected -> unselect all
                                            shouldSelectAll = false;
                                          } else {
                                            // None or some selected -> select all
                                            shouldSelectAll = true;
                                          }

                                          await cartController
                                              .selectAllItems(shouldSelectAll);
                                        },
                                        activeColor: AppTheme.primaryColor,
                                      )),
                                  Obx(() {
                                    final state =
                                        cartController.allItemsSelected;
                                    String text;

                                    if (state == true) {
                                      text = 'Unselect All';
                                    } else if (state == false) {
                                      text = 'Select All';
                                    } else {
                                      text = 'Select All';
                                    }

                                    return Text(
                                      text,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[700],
                                      ),
                                    );
                                  }),
                                  const Spacer(),
                                  Obx(() => Text(
                                        '${cartController.selectedItemCount} of ${cartController.itemCount} items selected',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      )),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            // Cart Items List
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount:
                                    cartController.cartItemsWithProducts.length,
                                itemBuilder: (context, index) {
                                  final itemData = cartController
                                      .cartItemsWithProducts[index];
                                  final Cart cart = itemData['cart'] as Cart;
                                  final Product? product =
                                      itemData['product'] as Product?;
                                  final double? subtotal =
                                      itemData['subtotal'] as double?;

                                  if (product == null) {
                                    return const SizedBox
                                        .shrink(); // Skip if product not found
                                  }

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          // Checkbox for selection
                                          Obx(() {
                                            final isSelected = cartController
                                                .isItemSelected(cart.id);
                                            return Checkbox(
                                              value: isSelected,
                                              onChanged: (bool? value) {
                                                cartController
                                                    .toggleItemSelection(
                                                        cart.id);
                                              },
                                              activeColor:
                                                  AppTheme.primaryColor,
                                            );
                                          }),
                                          const SizedBox(width: 8),
                                          // Product Image
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.network(
                                              product.image,
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  width: 80,
                                                  height: 80,
                                                  color: Colors.grey[200],
                                                  child: const Icon(Icons
                                                      .image_not_supported),
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // Product Details and Quantity Controls
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  product.name,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '\$${product.price.toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color:
                                                        AppTheme.primaryColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                // Quantity Controls
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        color: AppTheme
                                                            .primaryColor,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          IconButton(
                                                            icon: const Icon(
                                                                Icons.remove,
                                                                color: Colors
                                                                    .white),
                                                            iconSize: 16,
                                                            onPressed:
                                                                cart.id.isEmpty
                                                                    ? null
                                                                    : () async {
                                                                        final newQuantity =
                                                                            cart.jumlahBarang -
                                                                                1;
                                                                        if (newQuantity <=
                                                                            0) {
                                                                          await cartController
                                                                              .removeFromCart(cart.id);
                                                                        } else {
                                                                          await cartController.updateQuantity(
                                                                              cart.id,
                                                                              newQuantity);
                                                                        }
                                                                      },
                                                          ),
                                                          Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        8),
                                                            child: Text(
                                                              '${cart.jumlahBarang}',
                                                              style:
                                                                  const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                          IconButton(
                                                            icon: const Icon(
                                                                Icons.add,
                                                                color: Colors
                                                                    .white),
                                                            iconSize: 16,
                                                            onPressed:
                                                                cart.id.isEmpty
                                                                    ? null
                                                                    : () async {
                                                                        await cartController
                                                                            .updateQuantity(
                                                                          cart.id,
                                                                          cart.jumlahBarang +
                                                                              1,
                                                                        );
                                                                      },
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Subtotal
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '\$${subtotal?.toStringAsFixed(2) ?? '0.00'}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Subtotal',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
            ),
          ),
          // Bottom section with totals and checkout
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // All items total
                Obx(
                  () => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total (${cartController.itemCount} items):',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '\$${cartController.total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Selected items total
                Obx(
                  () => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Selected (${cartController.selectedItemCount} items):',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${cartController.selectedTotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Checkout button
                SizedBox(
                  width: double.infinity,
                  child: Obx(
                    () => ElevatedButton(
                      onPressed: cartController.hasSelectedItems
                          ? () async {
                              // Use selected items for checkout
                              final success =
                                  await cartController.proceedToCheckout();
                              if (success) {
                                Get.toNamed('/checkout');
                              } else {
                                NotificationUtils.showError(
                                    'Gagal memproses checkout. Silakan coba lagi.');
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        cartController.hasSelectedItems
                            ? 'Checkout Selected Items (${cartController.selectedItemCount})'
                            : 'Select items to checkout',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }
}
