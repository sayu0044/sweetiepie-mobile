import 'package:pocketbase/pocketbase.dart';
import 'package:flutter/foundation.dart';

class ApiRulesChecker {
  static final PocketBase pb = PocketBase('http://127.0.0.1:8090');

  static Future<Map<String, dynamic>> checkApiRules() async {
    debugPrint('🔍 === STARTING API RULES CHECK ===');

    final results = <String, dynamic>{
      'success': true,
      'errors': <String>[],
      'warnings': <String>[],
      'collections_tested': <String>[],
      'results': <String, dynamic>{},
    };

    try {
      // Check if user is authenticated
      if (!pb.authStore.isValid) {
        results['errors'].add('User not authenticated.');
        results['success'] = false;
        return results;
      }

      final userId = pb.authStore.record?.id;
      if (userId == null) {
        results['errors'].add('Invalid user session.');
        results['success'] = false;
        return results;
      }

      // Test carts collection
      await _testCartsCollection(userId, results);

      // Test likes collection
      await _testLikesCollection(userId, results);

      // Test users collection
      await _testUsersCollection(userId, results);
    } catch (e) {
      results['errors'].add('General error: $e');
      results['success'] = false;
    }

    return results;
  }

  static Future<void> _testCartsCollection(
      String userId, Map<String, dynamic> results) async {
    try {
      debugPrint('Testing carts collection...');

      // Test list permission
      try {
        await pb.collection('carts').getList(page: 1, perPage: 1);
        debugPrint('✅ Carts list permission OK');
        results['collections_tested'].add('carts_list');
        results['results']['carts_list'] = true;
      } catch (e) {
        debugPrint('❌ Carts list permission failed: $e');
        results['results']['carts_list'] = false;
        results['errors']
            .add('Carts list permission failed. Check List/Search rule.');
      }

      // Test create permission
      try {
        final testData = {
          'products_id':
              'test_product_${DateTime.now().millisecondsSinceEpoch}',
          'jumlah_barang': 1,
          'users_id': userId,
        };

        final record = await pb.collection('carts').create(body: testData);
        debugPrint('✅ Carts create permission OK');
        results['results']['carts_create'] = true;

        // Clean up test data
        try {
          await pb.collection('carts').delete(record.id);
          debugPrint('✅ Carts delete permission OK');
          results['results']['carts_delete'] = true;
        } catch (e) {
          debugPrint('❌ Carts delete permission failed: $e');
          results['results']['carts_delete'] = false;
          results['warnings']
              .add('Carts delete permission failed. Check Delete rule.');
        }
      } catch (e) {
        debugPrint('❌ Carts create permission failed: $e');
        results['results']['carts_create'] = false;
        results['results']['carts_delete'] = false;

        if (e.toString().contains('400')) {
          results['errors'].add(
              'Carts create failed with 400. Check field validation or Create rule.');
        } else if (e.toString().contains('403')) {
          results['errors'].add(
              'Carts create forbidden. Set Create rule: @request.auth.id != "" && users_id = @request.auth.id');
        } else {
          results['errors'].add('Carts create failed: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Carts collection test failed: $e');
      results['results']['carts_list'] = false;
      results['results']['carts_create'] = false;
      results['results']['carts_delete'] = false;
      results['errors']
          .add('Carts collection not accessible. Make sure it exists.');
    }
  }

  static Future<void> _testLikesCollection(
      String userId, Map<String, dynamic> results) async {
    try {
      debugPrint('Testing likes collection...');

      // Test list permission
      try {
        await pb.collection('likes').getList(page: 1, perPage: 1);
        debugPrint('✅ Likes list permission OK');
        results['collections_tested'].add('likes_list');
        results['results']['likes_list'] = true;
      } catch (e) {
        debugPrint('❌ Likes list permission failed: $e');
        results['results']['likes_list'] = false;
        results['errors']
            .add('Likes list permission failed. Check List/Search rule.');
      }

      // Test create permission
      try {
        final testData = {
          'products_id':
              'test_product_${DateTime.now().millisecondsSinceEpoch}',
          'users_id': userId,
        };

        final record = await pb.collection('likes').create(body: testData);
        debugPrint('✅ Likes create permission OK');
        results['results']['likes_create'] = true;

        // Clean up test data
        try {
          await pb.collection('likes').delete(record.id);
          debugPrint('✅ Likes delete permission OK');
          results['results']['likes_delete'] = true;
        } catch (e) {
          debugPrint('❌ Likes delete permission failed: $e');
          results['results']['likes_delete'] = false;
          results['warnings']
              .add('Likes delete permission failed. Check Delete rule.');
        }
      } catch (e) {
        debugPrint('❌ Likes create permission failed: $e');
        results['results']['likes_create'] = false;
        results['results']['likes_delete'] = false;

        if (e.toString().contains('400')) {
          results['errors'].add(
              'Likes create failed with 400. Check field validation or Create rule.');
        } else if (e.toString().contains('403')) {
          results['errors'].add(
              'Likes create forbidden. Set Create rule: @request.auth.id != "" && users_id = @request.auth.id');
        } else {
          results['errors'].add('Likes create failed: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Likes collection test failed: $e');
      results['results']['likes_list'] = false;
      results['results']['likes_create'] = false;
      results['results']['likes_delete'] = false;
      results['errors']
          .add('Likes collection not accessible. Make sure it exists.');
    }
  }

  static Future<void> _testUsersCollection(
      String userId, Map<String, dynamic> results) async {
    try {
      debugPrint('Testing users collection...');

      // Test if can fetch own user record
      try {
        final user = await pb.collection('users').getOne(userId);
        debugPrint('✅ Users fetch permission OK');
        results['results']['users_fetch'] = true;

        // Check if additional fields exist
        final data = user.data;
        final expectedFields = [
          'phone',
          'address',
          'theme',
          'notifications',
          'date_of_birth',
          'gender'
        ];
        final missingFields = <String>[];

        for (final field in expectedFields) {
          if (!data.containsKey(field)) {
            missingFields.add(field);
          }
        }

        if (missingFields.isNotEmpty) {
          results['warnings'].add(
              'Users collection missing fields: ${missingFields.join(', ')}');
          debugPrint(
              '⚠️ Users collection missing fields: ${missingFields.join(', ')}');
        } else {
          debugPrint('✅ Users collection has all required fields');
          results['results']['users_fields'] = true;
        }
      } catch (e) {
        debugPrint('❌ Users fetch permission failed: $e');
        results['results']['users_fetch'] = false;
        results['errors']
            .add('Cannot fetch user data. Check users collection permissions.');
      }
    } catch (e) {
      debugPrint('❌ Users collection test failed: $e');
      results['results']['users_fetch'] = false;
      results['errors'].add('Users collection not accessible: $e');
    }
  }

  static void debugPrintResults(Map<String, dynamic> results) {
    debugPrint('\n📊 API RULES CHECK RESULTS:');
    debugPrint('=' * 40);

    // debugPrint success status
    if (results['success']) {
      debugPrint('🎉 Overall Status: SUCCESS');
    } else {
      debugPrint('❌ Overall Status: FAILED');
    }

    debugPrint('\n📋 Collection Tests:');
    final collections = results['results'] as Map<String, bool>;
    collections.forEach((key, value) {
      final status = value ? '✅' : '❌';
      debugPrint('$status $key');
    });

    // debugPrint errors
    final errors = results['errors'] as List<String>;
    if (errors.isNotEmpty) {
      debugPrint('\n🚨 ERRORS:');
      for (final error in errors) {
        debugPrint('   • $error');
      }
    }

    // debugPrint warnings
    final warnings = results['warnings'] as List<String>;
    if (warnings.isNotEmpty) {
      debugPrint('\n⚠️  WARNINGS:');
      for (final warning in warnings) {
        debugPrint('   • $warning');
      }
    }

    debugPrint('=' * 40);

    if (!results['success']) {
      debugPrint('\n🔧 FOLLOW THESE STEPS TO FIX:');
      debugPrint('1. Open PocketBase Admin: http://127.0.0.1:8090/_/');
      debugPrint('2. Check each collection\'s API rules');
      debugPrint('3. Set rules as shown in fix_api_rules.md');
      debugPrint('4. Add missing fields to users collection');
      debugPrint('5. Test again');
    }
  }

  static String getRecommendation(Map<String, dynamic> results) {
    if (results['success']) {
      return 'All API rules are correctly configured! ✅';
    }

    final errors = results['errors'] as List<String>;
    if (errors.any((e) => e.contains('forbidden') || e.contains('403'))) {
      return 'API Rules not set correctly. Please follow fix_api_rules.md guide.';
    }

    if (errors.any((e) => e.contains('not accessible') || e.contains('404'))) {
      return 'Collections missing. Please create carts and likes collections.';
    }

    return 'Multiple issues found. Check the detailed errors above.';
  }
}
