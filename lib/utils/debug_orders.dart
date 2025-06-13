import 'package:pocketbase/pocketbase.dart';
import 'package:get/get.dart';
import 'package:sweetipie/services/auth_service.dart';

class DebugOrdersUtil {
  static final PocketBase pb = PocketBase('http://127.0.0.1:8090');
  
  static Future<void> testOrdersCollection() async {
    try {
      print('=== DEBUG: Testing Orders Collection ===');
      
      // 1. Test basic health
      final health = await pb.health.check();
      print('✅ PocketBase Health: ${health.code} - ${health.message}');
      
      // 2. Test auth
      final AuthService authService = Get.find<AuthService>();
      if (authService.isAuthenticated) {
        pb.authStore.save(authService.pb.authStore.token, authService.pb.authStore.model);
        print('✅ Authentication synced');
        print('   User ID: ${authService.currentUser.value?.id}');
        print('   Token exists: ${authService.pb.authStore.token != null}');
      } else {
        print('❌ User not authenticated');
        return;
      }
      
      // 3. Test reading orders collection (check access rules)
      try {
        final records = await pb.collection('orders').getList(page: 1, perPage: 1);
        print('✅ Can read orders collection: ${records.totalItems} total records');
      } catch (e) {
        print('❌ Cannot read orders collection: $e');
        print('   This usually means access rules are too restrictive');
      }
      
      // 4. Test creating a simple order
      final testData = {
        'users_id': authService.currentUser.value?.id,
        'payment_method': 'QRIS',
        'status': 'pending',
        'total_price': 100.0,
        'order_date': DateTime.now().toIso8601String().split('T')[0],
      };
      
      print('🔍 Attempting to create test order with data:');
      testData.forEach((key, value) => print('   $key: $value (${value.runtimeType})'));
      
      try {
        final record = await pb.collection('orders').create(body: testData);
        print('✅ Test order created successfully!');
        print('   Order ID: ${record.id}');
        
        // Clean up test record
        try {
          await pb.collection('orders').delete(record.id);
          print('✅ Test order cleaned up');
        } catch (deleteError) {
          print('⚠️ Could not delete test order: $deleteError');
        }
        
      } catch (e) {
        print('❌ Failed to create test order:');
        print('   Error: $e');
        
        // Check if it's an access rule issue
        if (e.toString().contains('403') || e.toString().contains('unauthorized')) {
          print('   🔒 This looks like an ACCESS RULE issue!');
          print('   🔧 Check the Create Rule for orders collection');
        } else if (e.toString().contains('400')) {
          print('   📝 This looks like a VALIDATION issue!');
          print('   🔧 Check field requirements and data types');
        }
        
        // Test with even more minimal data
        print('🔍 Trying with only required fields...');
        final minimalData = {
          'users_id': authService.currentUser.value?.id,
          'total_price': 100.0,
        };
        
        try {
          final record = await pb.collection('orders').create(body: minimalData);
          print('✅ Minimal test order created!');
          await pb.collection('orders').delete(record.id);
          print('✅ Minimal test order cleaned up');
        } catch (e2) {
          print('❌ Even minimal data failed: $e2');
        }
      }
      
      // 5. Test order_items collection access
      try {
        final itemRecords = await pb.collection('order_items').getList(page: 1, perPage: 1);
        print('✅ Can read order_items collection: ${itemRecords.totalItems} total records');
      } catch (e) {
        print('❌ Cannot read order_items collection: $e');
      }
      
      print('=== DEBUG: Test Complete ===');
      
    } catch (e) {
      print('❌ DEBUG: General error: $e');
    }
  }
  
  static Future<void> checkAccessRules() async {
    try {
      print('=== DEBUG: Testing Access Rules ===');
      
      final AuthService authService = Get.find<AuthService>();
      if (authService.isAuthenticated) {
        pb.authStore.save(authService.pb.authStore.token, authService.pb.authStore.model);
        print('✅ User authenticated: ${authService.currentUser.value?.id}');
      } else {
        print('❌ User not authenticated');
        return;
      }
      
      // Test different operations to see which ones fail
      print('🔍 Testing different operations...');
      
      // Test 1: List orders
      try {
        await pb.collection('orders').getList(page: 1, perPage: 1);
        print('✅ LIST orders: ALLOWED');
      } catch (e) {
        print('❌ LIST orders: DENIED - $e');
      }
      
      // Test 2: Create order
      try {
        final testRecord = await pb.collection('orders').create(body: {
          'users_id': authService.currentUser.value?.id,
          'total_price': 1.0,
        });
        print('✅ CREATE orders: ALLOWED');
        
        // Test 3: Update order
        try {
          await pb.collection('orders').update(testRecord.id, body: {'total_price': 2.0});
          print('✅ UPDATE orders: ALLOWED');
        } catch (e) {
          print('❌ UPDATE orders: DENIED - $e');
        }
        
        // Test 4: Delete order
        try {
          await pb.collection('orders').delete(testRecord.id);
          print('✅ DELETE orders: ALLOWED');
        } catch (e) {
          print('❌ DELETE orders: DENIED - $e');
        }
        
      } catch (e) {
        print('❌ CREATE orders: DENIED - $e');
        print('   🔧 SOLUTION: Set CREATE rule to: @request.auth.id != ""');
        print('      This allows any authenticated user to create orders');
      }
      
      print('=== Access Rules Check Complete ===');
      
    } catch (e) {
      print('❌ Error checking access rules: $e');
    }
  }
  
  static Future<void> suggestAccessRules() async {
    print('=== RECOMMENDED ACCESS RULES ===');
    print('For orders collection:');
    print('  📝 List Rule: @request.auth.id != ""');  
    print('     (Allow authenticated users to list orders)');
    print('');
    print('  📝 View Rule: @request.auth.id != ""');
    print('     (Allow authenticated users to view orders)');
    print('');
    print('  📝 Create Rule: @request.auth.id != ""');
    print('     (Allow authenticated users to create orders)');
    print('');
    print('  📝 Update Rule: @request.auth.id != ""');
    print('     (Allow authenticated users to update orders)');
    print('');
    print('  📝 Delete Rule: @request.auth.id != ""');
    print('     (Allow authenticated users to delete orders)');
    print('');
    print('For order_items collection:');
    print('  📝 All Rules: @request.auth.id != ""');
    print('     (Same as orders collection)');
    print('================================');
  }
} 