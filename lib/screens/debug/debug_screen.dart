import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sweetipie/services/auth_service.dart';
import 'package:sweetipie/services/cart_service.dart';
import 'package:sweetipie/services/like_service.dart';
import 'package:sweetipie/services/database_service.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Screen'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Debug Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Auth Status
            GetBuilder<AuthService>(
              builder: (authService) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🔐 Authentication Status:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                            'Is Authenticated: ${authService.isAuthenticated}'),
                        Text(
                            'User ID: ${authService.currentUser.value?.id ?? "null"}'),
                        Text(
                            'User Email: ${authService.currentUser.value?.data['email'] ?? "null"}'),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Cart Status
            GetBuilder<CartService>(
              builder: (cartService) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🛒 Cart Status:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Cart Items: ${cartService.cartItemCount}'),
                        Text(
                            'Total Price: \$${cartService.totalPrice.value.toStringAsFixed(2)}'),
                        Text('Current User ID: ${cartService.currentUserId}'),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Like Status
            GetBuilder<LikeService>(
              builder: (likeService) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('❤️ Like Status:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Liked Items: ${likeService.likedItemCount}'),
                        Text('Current User ID: ${likeService.currentUserId}'),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Test Buttons
            const Text(
              'Test Actions:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final cartService = Get.find<CartService>();
                      final databaseService = Get.find<DatabaseService>();

                      // Get first product for testing
                      if (databaseService.products.isNotEmpty) {
                        final testProduct = databaseService.products.first;
                        print(
                            'Debug: Testing cart with product: ${testProduct.id} - ${testProduct.name}');

                        final result =
                            await cartService.addToCart(testProduct.id, 1);
                        print('Debug: Cart add result: $result');
                      } else {
                        print('Debug: No products available for testing');
                        Get.snackbar(
                            'Debug', 'No products available for testing');
                      }
                    },
                    child: const Text('Test Add to Cart'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final likeService = Get.find<LikeService>();
                      final databaseService = Get.find<DatabaseService>();

                      // Get first product for testing
                      if (databaseService.products.isNotEmpty) {
                        final testProduct = databaseService.products.first;
                        print(
                            'Debug: Testing like with product: ${testProduct.id} - ${testProduct.name}');

                        final result =
                            await likeService.toggleLike(testProduct.id);
                        print('Debug: Like toggle result: $result');
                      } else {
                        print('Debug: No products available for testing');
                        Get.snackbar(
                            'Debug', 'No products available for testing');
                      }
                    },
                    child: const Text('Test Toggle Like'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Refresh Services Button
            ElevatedButton(
              onPressed: () async {
                print('Debug: Refreshing all services...');

                try {
                  final cartService = Get.find<CartService>();
                  final likeService = Get.find<LikeService>();
                  final databaseService = Get.find<DatabaseService>();

                  await databaseService.refreshData();
                  await cartService.refreshCart();
                  await likeService.refreshLikes();

                  Get.snackbar('Debug', 'Services refreshed successfully');
                  print('Debug: All services refreshed successfully');
                } catch (e) {
                  print('Debug: Error refreshing services: $e');
                  Get.snackbar('Debug Error', 'Failed to refresh services: $e');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Refresh All Services'),
            ),
          ],
        ),
      ),
    );
  }
}
