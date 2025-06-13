import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sweetipie/theme/app_theme.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get arguments passed from payment screen
    final String? orderId = Get.arguments?['orderId'];
    final double? orderTotal = Get.arguments?['orderTotal'];
    final String? paymentMethod = Get.arguments?['paymentMethod'];

    return Scaffold(
      backgroundColor: Colors.pink[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 64,
                ),
              ),
              const SizedBox(height: 32),

              // Success Title
              const Text(
                'Pembayaran Berhasil!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Success Message
              Text(
                'Terima kasih! Pesanan Anda telah berhasil diproses.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Order Details Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Order ID
                      if (orderId != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order ID:',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '#${orderId.substring(0, 8)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Payment Method
                      if (paymentMethod != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Metode Pembayaran:',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  paymentMethod == 'QRIS' ? Icons.qr_code : Icons.store,
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  paymentMethod,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Total Amount
                      if (orderTotal != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Pembayaran:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '\$${orderTotal.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Action Buttons
              Column(
                children: [
                  // Continue Shopping Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => Get.offAllNamed('/home'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Lanjut Belanja',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // View Order History Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () {
                        // Navigate to order history
                        Get.offAllNamed('/home');
                        // You can add navigation to order history page here
                        Get.snackbar(
                          'Info',
                          'Fitur riwayat pesanan akan segera tersedia',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.primaryColor, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Lihat Riwayat Pesanan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
