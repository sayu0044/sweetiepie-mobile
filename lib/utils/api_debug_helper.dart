import 'package:pocketbase/pocketbase.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sweetipie/services/auth_service.dart';

class ApiDebugHelper {
  static Future<void> debugCartIssue() async {
    debugPrint('\n🔍 === DEBUGGING CART ISSUE ===');

    final authService = Get.find<AuthService>();
    final pb = authService.pb;

    // Check auth status
    debugPrint('Auth Status: ${authService.isAuthenticated}');
    debugPrint('User ID: ${authService.currentUser.value?.id}');
    debugPrint('Auth Token Valid: ${pb.authStore.isValid}');
    final debugToken = pb.authStore.token;
    final debugTokenPreview = debugToken.length > 20
        ? '${debugToken.substring(0, 20)}...'
        : debugToken;
    debugPrint('Auth Token: $debugTokenPreview');

    try {
      // Test 1: Check if collection exists and accessible
      debugPrint('\n📋 Testing carts collection access...');
      final testList =
          await pb.collection('carts').getList(page: 1, perPage: 1);
      debugPrint(
          '✅ Carts collection accessible, found ${testList.totalItems} items');

      // Test 2: Check collection schema
      debugPrint('\n🔧 Checking collection schema...');
      try {
        // Try to create with minimal data to see which field fails
        final minimalData = {
          'products_id': 'test123',
          'jumlah_barang': 1,
          'users_id': authService.currentUser.value?.id,
        };

        debugPrint('Attempting to create with data: $minimalData');
        final record = await pb.collection('carts').create(body: minimalData);
        debugPrint('✅ Create test successful! Record ID: ${record.id}');

        // Clean up
        await pb.collection('carts').delete(record.id);
        debugPrint('✅ Cleanup successful');
      } catch (e) {
        debugPrint('❌ Create test failed: $e');

        // Parse the error
        final errorStr = e.toString();
        if (errorStr.contains('400')) {
          debugPrint('\n🚨 400 Error Analysis:');
          if (errorStr.contains('validation')) {
            debugPrint('- Field validation failed');
            debugPrint('- Check field types and requirements');
          }
          if (errorStr.contains('auth')) {
            debugPrint('- Authentication issue');
            debugPrint('- Check API rules');
          }
          if (errorStr.contains('required')) {
            debugPrint('- Required field missing');
            debugPrint('- Check schema for required fields');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Collection access failed: $e');
      if (e.toString().contains('404')) {
        debugPrint('🚨 Collection does not exist!');
      } else if (e.toString().contains('403')) {
        debugPrint('🚨 Permission denied - API rules not set!');
      }
    }

    debugPrint('\n=== END CART DEBUG ===\n');
  }

  static Future<void> debugLikeIssue() async {
    debugPrint('\n💖 === DEBUGGING LIKE ISSUE ===');

    final authService = Get.find<AuthService>();
    final pb = authService.pb;

    try {
      // Test likes collection
      debugPrint('📋 Testing likes collection access...');
      final testList =
          await pb.collection('likes').getList(page: 1, perPage: 1);
      debugPrint(
          '✅ Likes collection accessible, found ${testList.totalItems} items');

      // Test create
      debugPrint('\n🔧 Testing likes create...');
      final minimalData = {
        'products_id': 'test123',
        'users_id': authService.currentUser.value?.id,
      };

      debugPrint('Attempting to create with data: $minimalData');
      final record = await pb.collection('likes').create(body: minimalData);
      debugPrint('✅ Create test successful! Record ID: ${record.id}');

      // Clean up
      await pb.collection('likes').delete(record.id);
      debugPrint('✅ Cleanup successful');
    } catch (e) {
      debugPrint('❌ Likes test failed: $e');

      final errorStr = e.toString();
      if (errorStr.contains('400')) {
        debugPrint('\n🚨 400 Error Analysis:');
        debugPrint('- Check field validation');
        debugPrint('- Check API rules');
        debugPrint('- Check required fields');
      }
    }

    debugPrint('\n=== END LIKE DEBUG ===\n');
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
    debugPrint('\n🔒 === TESTING ALL API RULES ===');

    final authService = Get.find<AuthService>();
    final pb = authService.pb;
    final userId = authService.currentUser.value?.id;

    if (userId == null) {
      debugPrint('❌ No user logged in');
      return;
    }

    // Test carts API rules
    debugPrint('\n📋 Testing carts API rules...');
    await _testCollectionRules(pb, 'carts', {
      'products_id': 'test_product',
      'jumlah_barang': 1,
      'users_id': userId,
    });

    // Test likes API rules
    debugPrint('\n💖 Testing likes API rules...');
    await _testCollectionRules(pb, 'likes', {
      'products_id': 'test_product',
      'users_id': userId,
    });

    debugPrint('\n=== END API RULES TEST ===\n');
  }

  static Future<void> _testCollectionRules(
      PocketBase pb, String collection, Map<String, dynamic> testData) async {
    try {
      // Test LIST
      try {
        await pb.collection(collection).getList(page: 1, perPage: 1);
        debugPrint('✅ $collection LIST permission OK');
      } catch (e) {
        debugPrint('❌ $collection LIST failed: $e');
      }

      // Test CREATE
      try {
        final record = await pb.collection(collection).create(body: testData);
        debugPrint('✅ $collection CREATE permission OK');

        // Test UPDATE
        try {
          await pb.collection(collection).update(record.id, body: testData);
          debugPrint('✅ $collection UPDATE permission OK');
        } catch (e) {
          debugPrint('❌ $collection UPDATE failed: $e');
        }

        // Test DELETE
        try {
          await pb.collection(collection).delete(record.id);
          debugPrint('✅ $collection DELETE permission OK');
        } catch (e) {
          debugPrint('❌ $collection DELETE failed: $e');
        }
      } catch (e) {
        debugPrint('❌ $collection CREATE failed: $e');

        if (e.toString().contains('403')) {
          debugPrint(
              '🔧 FIX: Set CREATE rule to: @request.auth.id != "" && users_id = @request.auth.id');
        } else if (e.toString().contains('400')) {
          debugPrint('🔧 FIX: Check field validation or CREATE rule syntax');
        }
      }
    } catch (e) {
      debugPrint('❌ $collection collection test failed: $e');
    }
  }

  static void debugPrintFixInstructions() {
    debugPrint('\n🔧 === FIX INSTRUCTIONS ===');
    debugPrint('1. Open PocketBase Admin: http://127.0.0.1:8090/_/');
    debugPrint('2. For BOTH carts and likes collections:');
    debugPrint('   - Go to API Rules tab');
    debugPrint(
        '   - Set ALL rules to: @request.auth.id != "" && users_id = @request.auth.id');
    debugPrint('   - EXCEPT List/Search: @request.auth.id != ""');
    debugPrint('3. Save each collection');
    debugPrint('4. Test again');
    debugPrint('=========================\n');
  }
}
