import 'package:pocketbase/pocketbase.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:sweetipie/services/auth_service.dart';

class DebugOrdersUtil {
  static final PocketBase pb = PocketBase('http://127.0.0.1:8090');

  static Future<void> testOrdersCollection() async {
    try {
      debugPrint('=== DEBUG: Testing Orders Collection ===');

      // 1. Test basic health
      final health = await pb.health.check();
      debugPrint('✅ PocketBase Health: ${health.code} - ${health.message}');

      // 2. Test auth
      final AuthService authService = Get.find<AuthService>();
      if (authService.isAuthenticated) {
        pb.authStore.save(
            authService.pb.authStore.token, authService.pb.authStore.record);
        debugPrint('✅ Authentication synced');
        debugPrint('   User ID: ${authService.currentUser.value?.id}');
        debugPrint(
            '   Token exists: ${authService.pb.authStore.token.isNotEmpty}');
      } else {
        debugPrint('❌ User not authenticated');
        return;
      }

      // 3. Test reading orders collection (check access rules)
      try {
        final records =
            await pb.collection('orders').getList(page: 1, perPage: 1);
        debugPrint(
            '✅ Can read orders collection: ${records.totalItems} total records');
      } catch (e) {
        debugPrint('❌ Cannot read orders collection: $e');
        debugPrint('   This usually means access rules are too restrictive');
      }

      // 4. Test creating a simple order
      final testData = {
        'users_id': authService.currentUser.value?.id,
        'payment_method': 'QRIS',
        'status': 'pending',
        'total_price': 100.0,
        'order_date': DateTime.now().toIso8601String().split('T')[0],
      };

      debugPrint('🔍 Attempting to create test order with data:');
      testData.forEach(
          (key, value) => debugPrint('   $key: $value (${value.runtimeType})'));

      try {
        final record = await pb.collection('orders').create(body: testData);
        debugPrint('✅ Test order created successfully!');
        debugPrint('   Order ID: ${record.id}');

        // Clean up test record
        try {
          await pb.collection('orders').delete(record.id);
          debugPrint('✅ Test order cleaned up');
        } catch (deleteError) {
          debugPrint('⚠️ Could not delete test order: $deleteError');
        }
      } catch (e) {
        debugPrint('❌ Failed to create test order:');
        debugPrint('   Error: $e');

        // Check if it's an access rule issue
        if (e.toString().contains('403') ||
            e.toString().contains('unauthorized')) {
          debugPrint('   🔒 This looks like an ACCESS RULE issue!');
          debugPrint('   🔧 Check the Create Rule for orders collection');
        } else if (e.toString().contains('400')) {
          debugPrint('   📝 This looks like a VALIDATION issue!');
          debugPrint('   🔧 Check field requirements and data types');
        }

        // Test with even more minimal data
        debugPrint('🔍 Trying with only required fields...');
        final minimalData = {
          'users_id': authService.currentUser.value?.id,
          'total_price': 100.0,
        };

        try {
          final record =
              await pb.collection('orders').create(body: minimalData);
          debugPrint('✅ Minimal test order created!');
          await pb.collection('orders').delete(record.id);
          debugPrint('✅ Minimal test order cleaned up');
        } catch (e2) {
          debugPrint('❌ Even minimal data failed: $e2');
        }
      }

      // 5. Test order_items collection access
      try {
        final itemRecords =
            await pb.collection('order_items').getList(page: 1, perPage: 1);
        debugPrint(
            '✅ Can read order_items collection: ${itemRecords.totalItems} total records');
      } catch (e) {
        debugPrint('❌ Cannot read order_items collection: $e');
      }

      debugPrint('=== DEBUG: Test Complete ===');
    } catch (e) {
      debugPrint('❌ DEBUG: General error: $e');
    }
  }

  static Future<void> checkAccessRules() async {
    try {
      debugPrint('=== DEBUG: Testing Access Rules ===');

      final AuthService authService = Get.find<AuthService>();
      if (authService.isAuthenticated) {
        pb.authStore.save(
            authService.pb.authStore.token, authService.pb.authStore.record);
        debugPrint(
            '✅ User authenticated: ${authService.currentUser.value?.id}');
      } else {
        debugPrint('❌ User not authenticated');
        return;
      }

      // Test different operations to see which ones fail
      debugPrint('🔍 Testing different operations...');

      // Test 1: List orders
      try {
        await pb.collection('orders').getList(page: 1, perPage: 1);
        debugPrint('✅ LIST orders: ALLOWED');
      } catch (e) {
        debugPrint('❌ LIST orders: DENIED - $e');
      }

      // Test 2: Create order
      try {
        final testRecord = await pb.collection('orders').create(body: {
          'users_id': authService.currentUser.value?.id,
          'total_price': 1.0,
        });
        debugPrint('✅ CREATE orders: ALLOWED');

        // Test 3: Update order
        try {
          await pb
              .collection('orders')
              .update(testRecord.id, body: {'total_price': 2.0});
          debugPrint('✅ UPDATE orders: ALLOWED');
        } catch (e) {
          debugPrint('❌ UPDATE orders: DENIED - $e');
        }

        // Test 4: Delete order
        try {
          await pb.collection('orders').delete(testRecord.id);
          debugPrint('✅ DELETE orders: ALLOWED');
        } catch (e) {
          debugPrint('❌ DELETE orders: DENIED - $e');
        }
      } catch (e) {
        debugPrint('❌ CREATE orders: DENIED - $e');
        debugPrint(
            '   🔧 SOLUTION: Set CREATE rule to: @request.auth.id != ""');
        debugPrint('      This allows any authenticated user to create orders');
      }

      debugPrint('=== Access Rules Check Complete ===');
    } catch (e) {
      debugPrint('❌ Error checking access rules: $e');
    }
  }

  static Future<void> suggestAccessRules() async {
    debugPrint('=== RECOMMENDED ACCESS RULES ===');
    debugPrint('For orders collection:');
    debugPrint('  📝 List Rule: @request.auth.id != ""');
    debugPrint('     (Allow authenticated users to list orders)');
    debugPrint('');
    debugPrint('  📝 View Rule: @request.auth.id != ""');
    debugPrint('     (Allow authenticated users to view orders)');
    debugPrint('');
    debugPrint('  📝 Create Rule: @request.auth.id != ""');
    debugPrint('     (Allow authenticated users to create orders)');
    debugPrint('');
    debugPrint('  📝 Update Rule: @request.auth.id != ""');
    debugPrint('     (Allow authenticated users to update orders)');
    debugPrint('');
    debugPrint('  📝 Delete Rule: @request.auth.id != ""');
    debugPrint('     (Allow authenticated users to delete orders)');
    debugPrint('');
    debugPrint('For order_items collection:');
    debugPrint('  📝 All Rules: @request.auth.id != ""');
    debugPrint('     (Same as orders collection)');
    debugPrint('================================');
  }
}
