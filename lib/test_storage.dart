import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Test file to check SharedPreferences storage
Future<void> testStorage() async {
  debugPrint('=== TESTING STORAGE ===');

  final prefs = await SharedPreferences.getInstance();

  // Test write
  final testData = {
    'test_user': [
      {
        'id': 'test123',
        'productsId': 'prod456',
        'jumlahBarang': 2,
        'usersId': 'test_user',
        'created': DateTime.now().toIso8601String(),
        'updated': DateTime.now().toIso8601String(),
      }
    ]
  };

  await prefs.setString('test_carts', json.encode(testData));
  debugPrint('✅ Test data written to storage');

  // Test read
  final readData = prefs.getString('test_carts');
  if (readData != null) {
    final decoded = json.decode(readData);
    debugPrint('✅ Test data read from storage: $decoded');
  } else {
    debugPrint('❌ Failed to read test data');
  }

  // Check actual cart data
  final actualCartData = prefs.getString('user_carts');
  if (actualCartData != null) {
    final decoded = json.decode(actualCartData);
    debugPrint('✅ Actual cart data found: $decoded');
  } else {
    debugPrint('❌ No actual cart data found');
  }

  debugPrint('=== STORAGE TEST COMPLETE ===');
}
