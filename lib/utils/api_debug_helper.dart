import 'package:pocketbase/pocketbase.dart';
import 'package:get/get.dart';
import 'package:sweetipie/services/auth_service.dart';

class ApiDebugHelper {
  static Future<void> debugCartIssue() async {
    print('\n🔍 === DEBUGGING CART ISSUE ===');

    final authService = Get.find<AuthService>();
    final pb = authService.pb;

    // Check auth status
    print('Auth Status: ${authService.isAuthenticated}');
    print('User ID: ${authService.currentUser.value?.id}');
    print('Auth Token Valid: ${pb.authStore.isValid}');
    print('Auth Token: ${pb.authStore.token?.substring(0, 20)}...');

    try {
      // Test 1: Check if collection exists and accessible
      print('\n📋 Testing carts collection access...');
      final testList =
          await pb.collection('carts').getList(page: 1, perPage: 1);
      print(
          '✅ Carts collection accessible, found ${testList.totalItems} items');

      // Test 2: Check collection schema
      print('\n🔧 Checking collection schema...');
      try {
        // Try to create with minimal data to see which field fails
        final minimalData = {
          'products_id': 'test123',
          'jumlah_barang': 1,
          'users_id': authService.currentUser.value?.id,
        };

        print('Attempting to create with data: $minimalData');
        final record = await pb.collection('carts').create(body: minimalData);
        print('✅ Create test successful! Record ID: ${record.id}');

        // Clean up
        await pb.collection('carts').delete(record.id);
        print('✅ Cleanup successful');
      } catch (e) {
        print('❌ Create test failed: $e');

        // Parse the error
        final errorStr = e.toString();
        if (errorStr.contains('400')) {
          print('\n🚨 400 Error Analysis:');
          if (errorStr.contains('validation')) {
            print('- Field validation failed');
            print('- Check field types and requirements');
          }
          if (errorStr.contains('auth')) {
            print('- Authentication issue');
            print('- Check API rules');
          }
          if (errorStr.contains('required')) {
            print('- Required field missing');
            print('- Check schema for required fields');
          }
        }
      }
    } catch (e) {
      print('❌ Collection access failed: $e');
      if (e.toString().contains('404')) {
        print('🚨 Collection does not exist!');
      } else if (e.toString().contains('403')) {
        print('🚨 Permission denied - API rules not set!');
      }
    }

    print('\n=== END CART DEBUG ===\n');
  }

  static Future<void> debugLikeIssue() async {
    print('\n💖 === DEBUGGING LIKE ISSUE ===');

    final authService = Get.find<AuthService>();
    final pb = authService.pb;

    try {
      // Test likes collection
      print('📋 Testing likes collection access...');
      final testList =
          await pb.collection('likes').getList(page: 1, perPage: 1);
      print(
          '✅ Likes collection accessible, found ${testList.totalItems} items');

      // Test create
      print('\n🔧 Testing likes create...');
      final minimalData = {
        'products_id': 'test123',
        'users_id': authService.currentUser.value?.id,
      };

      print('Attempting to create with data: $minimalData');
      final record = await pb.collection('likes').create(body: minimalData);
      print('✅ Create test successful! Record ID: ${record.id}');

      // Clean up
      await pb.collection('likes').delete(record.id);
      print('✅ Cleanup successful');
    } catch (e) {
      print('❌ Likes test failed: $e');

      final errorStr = e.toString();
      if (errorStr.contains('400')) {
        print('\n🚨 400 Error Analysis:');
        print('- Check field validation');
        print('- Check API rules');
        print('- Check required fields');
      }
    }

    print('\n=== END LIKE DEBUG ===\n');
  }

  static Future<Map<String, dynamic>> getCollectionInfo(
      String collectionName) async {
    final authService = Get.find<AuthService>();
    final pb = authService.pb;

    try {
      // Try to get collection info via API
      final response = await pb.send('/api/collections/$collectionName');

      return {
        'success': true,
        'data': response,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<void> testAllAPIRules() async {
    print('\n🔒 === TESTING ALL API RULES ===');

    final authService = Get.find<AuthService>();
    final pb = authService.pb;
    final userId = authService.currentUser.value?.id;

    if (userId == null) {
      print('❌ No user logged in');
      return;
    }

    // Test carts API rules
    print('\n📋 Testing carts API rules...');
    await _testCollectionRules(pb, 'carts', {
      'products_id': 'test_product',
      'jumlah_barang': 1,
      'users_id': userId,
    });

    // Test likes API rules
    print('\n💖 Testing likes API rules...');
    await _testCollectionRules(pb, 'likes', {
      'products_id': 'test_product',
      'users_id': userId,
    });

    print('\n=== END API RULES TEST ===\n');
  }

  static Future<void> _testCollectionRules(
      PocketBase pb, String collection, Map<String, dynamic> testData) async {
    try {
      // Test LIST
      try {
        await pb.collection(collection).getList(page: 1, perPage: 1);
        print('✅ $collection LIST permission OK');
      } catch (e) {
        print('❌ $collection LIST failed: $e');
      }

      // Test CREATE
      try {
        final record = await pb.collection(collection).create(body: testData);
        print('✅ $collection CREATE permission OK');

        // Test UPDATE
        try {
          await pb.collection(collection).update(record.id, body: testData);
          print('✅ $collection UPDATE permission OK');
        } catch (e) {
          print('❌ $collection UPDATE failed: $e');
        }

        // Test DELETE
        try {
          await pb.collection(collection).delete(record.id);
          print('✅ $collection DELETE permission OK');
        } catch (e) {
          print('❌ $collection DELETE failed: $e');
        }
      } catch (e) {
        print('❌ $collection CREATE failed: $e');

        if (e.toString().contains('403')) {
          print(
              '🔧 FIX: Set CREATE rule to: @request.auth.id != "" && users_id = @request.auth.id');
        } else if (e.toString().contains('400')) {
          print('🔧 FIX: Check field validation or CREATE rule syntax');
        }
      }
    } catch (e) {
      print('❌ $collection collection test failed: $e');
    }
  }

  static void printFixInstructions() {
    print('\n🔧 === FIX INSTRUCTIONS ===');
    print('1. Open PocketBase Admin: http://127.0.0.1:8090/_/');
    print('2. For BOTH carts and likes collections:');
    print('   - Go to API Rules tab');
    print(
        '   - Set ALL rules to: @request.auth.id != "" && users_id = @request.auth.id');
    print('   - EXCEPT List/Search: @request.auth.id != ""');
    print('3. Save each collection');
    print('4. Test again');
    print('=========================\n');
  }
}
