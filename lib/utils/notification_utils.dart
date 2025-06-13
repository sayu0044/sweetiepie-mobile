import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationUtils {
  // Standard notification settings
  static const Duration _shortDuration = Duration(seconds: 2);
  static const Duration _mediumDuration = Duration(seconds: 3);
  static const SnackPosition _position = SnackPosition.TOP;
  
  // Success notification (green)
  static void showSuccess(String message, {String title = 'Berhasil'}) {
    Get.snackbar(
      title,
      message,
      snackPosition: _position,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: _shortDuration,
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }
  
  // Error notification (red)
  static void showError(String message, {String title = 'Error'}) {
    Get.snackbar(
      title,
      message,
      snackPosition: _position,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: _shortDuration,
      icon: const Icon(Icons.error, color: Colors.white),
    );
  }
  
  // Warning notification (orange)
  static void showWarning(String message, {String title = 'Perhatian'}) {
    Get.snackbar(
      title,
      message,
      snackPosition: _position,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      duration: _shortDuration,
      icon: const Icon(Icons.warning, color: Colors.white),
    );
  }
  
  // Info notification (blue)
  static void showInfo(String message, {String title = 'Info'}) {
    Get.snackbar(
      title,
      message,
      snackPosition: _position,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: _shortDuration,
      icon: const Icon(Icons.info, color: Colors.white),
    );
  }
  
  // Cart specific notifications
  static void showCartAdded(String productName) {
    showSuccess('$productName ditambahkan ke keranjang');
  }
  
  static void showCartUpdated() {
    showSuccess('Keranjang diperbarui');
  }
  
  static void showCartRemoved() {
    showWarning('Item dihapus dari keranjang');
  }
  
  // Order specific notifications
  static void showOrderSuccess(String orderId) {
    Get.snackbar(
      'Pesanan Berhasil!',
      'Pesanan Anda telah dibuat dengan nomor: $orderId',
      snackPosition: _position,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: _mediumDuration,
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }
  
  static void showPaymentSuccess() {
    Get.snackbar(
      'Pembayaran Berhasil!',
      'Terima kasih! Pesanan Anda telah berhasil diproses.',
      snackPosition: _position,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: _mediumDuration,
      icon: const Icon(Icons.payment, color: Colors.white),
    );
  }
} 