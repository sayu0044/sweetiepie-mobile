import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sweetipie/controllers/cart_controller.dart';
import 'package:sweetipie/models/product.dart';
import 'package:sweetipie/widgets/like_button_widget.dart';
import 'package:sweetipie/theme/app_theme.dart';

class ProductCardWidget extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCardWidget({
    Key? key,
    required this.product,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final CartController cartController = Get.find<CartController>();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with Like Button
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image.network(
                    product.image,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 150,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                // Like Button positioned at top right
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: LikeIconButton(
                      productId: product.id,
                      iconSize: 20,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ),
              ],
            ),
            // Product Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Product Description
                    Text(
                      product.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Price and Cart Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        // Cart quantity or Add button
                        Obx(() {
                          final quantity =
                              cartController.getProductQuantity(product.id);

                          if (quantity > 0) {
                            // Show quantity controls
                            return Container(
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove,
                                        color: Colors.white),
                                    iconSize: 16,
                                    onPressed: () async {
                                      print(
                                          'ProductCard: Decreasing quantity for product ${product.id}');
                                      // Get cart item to update quantity
                                      final cartItems =
                                          cartController.cartItemsWithProducts;
                                      final cartItem =
                                          cartItems.firstWhereOrNull(
                                        (item) =>
                                            (item['product'] as Product?)?.id ==
                                            product.id,
                                      );

                                      if (cartItem != null) {
                                        final cart = cartItem['cart'];
                                        final newQuantity =
                                            cart.jumlahBarang - 1;

                                        if (newQuantity <= 0) {
                                          // Remove item if quantity becomes 0
                                          await cartController
                                              .removeFromCart(cart.id);
                                        } else {
                                          await cartController.updateQuantity(
                                            cart.id,
                                            newQuantity,
                                          );
                                        }
                                      }
                                    },
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Text(
                                      '$quantity',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add,
                                        color: Colors.white),
                                    iconSize: 16,
                                    onPressed: () async {
                                      print(
                                          'ProductCard: Increasing quantity for product ${product.id}');
                                      // Add one more quantity to this specific product
                                      await cartController.addToCart(product,
                                          quantity: 1);
                                    },
                                  ),
                                ],
                              ),
                            );
                          } else {
                            // Show add to cart button
                            return ElevatedButton(
                              onPressed: () async {
                                await cartController.addToCart(product);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_shopping_cart, size: 16),
                                  SizedBox(width: 4),
                                  Text('Add'),
                                ],
                              ),
                            );
                          }
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
