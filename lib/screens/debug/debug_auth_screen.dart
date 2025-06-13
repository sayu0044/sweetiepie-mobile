import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sweetipie/services/auth_service.dart';
import 'package:sweetipie/services/cart_service.dart';
import 'package:sweetipie/services/like_service.dart';
import 'package:sweetipie/services/user_settings_service.dart';
import 'package:sweetipie/theme/app_theme.dart';
import 'package:sweetipie/utils/database_checker.dart';
import 'package:sweetipie/utils/api_rules_checker.dart';
import 'package:sweetipie/utils/api_debug_helper.dart';

class DebugAuthScreen extends StatelessWidget {
  const DebugAuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final cartService = Get.find<CartService>();
    final likeService = Get.find<LikeService>();
    final settingsService = Get.find<UserSettingsService>();

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
          'Debug Authentication',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Auth Status
            _buildSection(
              'Authentication Status',
              Column(
                children: [
                  Obx(() => _buildInfoRow(
                        'Is Authenticated',
                        authService.isAuthenticated ? '✅ Yes' : '❌ No',
                        authService.isAuthenticated ? Colors.green : Colors.red,
                      )),
                  Obx(() => _buildInfoRow(
                        'User ID',
                        authService.currentUser.value?.id ?? 'null',
                        authService.currentUser.value?.id != null
                            ? Colors.green
                            : Colors.red,
                      )),
                  Obx(() => _buildInfoRow(
                        'User Email',
                        authService.currentUser.value?.data['email'] ?? 'null',
                        authService.currentUser.value?.data['email'] != null
                            ? Colors.green
                            : Colors.red,
                      )),
                  Obx(() => _buildInfoRow(
                        'User Name',
                        authService.currentUser.value?.data['name'] ?? 'null',
                        authService.currentUser.value?.data['name'] != null
                            ? Colors.green
                            : Colors.red,
                      )),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Database Connection
            _buildSection(
              'Database Connection',
              Column(
                children: [
                  _buildInfoRow(
                    'PocketBase URL',
                    authService.pb.baseUrl,
                    Colors.blue,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      print('🔍 Starting database check...');
                      final results =
                          await DatabaseChecker.checkDatabaseSetup();
                      DatabaseChecker.showResults(results);

                      final allGood = results.values.every((v) => v == true);
                      Get.snackbar(
                        allGood ? 'Success' : 'Warning',
                        allGood
                            ? 'Database setup is complete!'
                            : 'Database setup incomplete. Check console.',
                        backgroundColor: allGood ? Colors.green : Colors.orange,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 5),
                      );
                    },
                    child: const Text('Check Database Setup'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      print('🔒 Starting API rules check...');

                      // First authenticate using current auth service
                      final authService = Get.find<AuthService>();
                      final currentUser = authService.currentUser.value;

                      if (currentUser != null) {
                        // Set auth in API checker's PocketBase instance
                        ApiRulesChecker.pb.authStore
                            .save(authService.pb.authStore.token, currentUser);
                      }

                      final results = await ApiRulesChecker.checkApiRules();
                      ApiRulesChecker.printResults(results);

                      final recommendation =
                          ApiRulesChecker.getRecommendation(results);

                      Get.snackbar(
                        results['success'] ? 'Success' : 'Issues Found',
                        recommendation,
                        backgroundColor:
                            results['success'] ? Colors.green : Colors.red,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 8),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text('Check API Rules',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Services Status
            _buildSection(
              'Services Status',
              Column(
                children: [
                  Obx(() => _buildInfoRow(
                        'Cart Service Items',
                        '${cartService.cartItems.length}',
                        Colors.blue,
                      )),
                  Obx(() => _buildInfoRow(
                        'Like Service Items',
                        '${likeService.likedItems.length}',
                        Colors.blue,
                      )),
                  Obx(() => _buildInfoRow(
                        'Settings Service',
                        settingsService.currentSettings.value != null
                            ? '✅ Loaded'
                            : '❌ Not loaded',
                        settingsService.currentSettings.value != null
                            ? Colors.green
                            : Colors.red,
                      )),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Test Actions
            _buildSection(
              'Test Actions',
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          print('Testing cart add...');
                          final success =
                              await cartService.addToCart('test_product', 1);
                          Get.snackbar(
                            success ? 'Success' : 'Failed',
                            success
                                ? 'Test item added to cart'
                                : 'Failed to add to cart',
                            backgroundColor:
                                success ? Colors.green : Colors.red,
                            colorText: Colors.white,
                          );
                        } catch (e) {
                          Get.snackbar(
                            'Error',
                            'Cart test failed: $e',
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                      ),
                      child: const Text('Test Add to Cart',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          print('Testing like toggle...');
                          final success =
                              await likeService.toggleLike('test_product');
                          Get.snackbar(
                            'Success',
                            success ? 'Test item liked' : 'Test item unliked',
                            backgroundColor: Colors.green,
                            colorText: Colors.white,
                          );
                        } catch (e) {
                          Get.snackbar(
                            'Error',
                            'Like test failed: $e',
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text('Test Toggle Like',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        print('🔍 Starting comprehensive API debug...');

                        await ApiDebugHelper.debugCartIssue();
                        await ApiDebugHelper.debugLikeIssue();
                        await ApiDebugHelper.testAllAPIRules();
                        ApiDebugHelper.printFixInstructions();

                        Get.snackbar(
                          'Debug Complete',
                          'Check console for detailed analysis',
                          backgroundColor: Colors.purple,
                          colorText: Colors.white,
                          duration: const Duration(seconds: 5),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                      ),
                      child: const Text('Debug Cart & Like Issues',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          print('Testing profile update...');
                          final success = await settingsService.updateProfile(
                            name: 'Test User ${DateTime.now().millisecond}',
                            phone: '081234567890',
                          );
                          Get.snackbar(
                            success ? 'Success' : 'Failed',
                            success
                                ? 'Profile updated'
                                : 'Failed to update profile',
                            backgroundColor:
                                success ? Colors.green : Colors.red,
                            colorText: Colors.white,
                          );
                        } catch (e) {
                          Get.snackbar(
                            'Error',
                            'Profile test failed: $e',
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                      ),
                      child: const Text('Test Update Profile',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Refresh Services
            _buildSection(
              'Service Management',
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await cartService.fetchCartItems();
                          await likeService.fetchLikedItems();
                          await settingsService.fetchUserSettings();
                          Get.snackbar(
                            'Success',
                            'All services refreshed',
                            backgroundColor: Colors.green,
                            colorText: Colors.white,
                          );
                        } catch (e) {
                          Get.snackbar(
                            'Error',
                            'Failed to refresh services: $e',
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                      ),
                      child: const Text('Refresh All Services',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
