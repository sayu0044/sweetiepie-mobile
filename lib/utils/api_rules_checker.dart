import 'package:pocketbase/pocketbase.dart';
import 'package:get/get.dart';

class ApiRulesChecker {
  static final PocketBase pb = PocketBase('http://127.0.0.1:8090');

  static Future<Map<String, dynamic>> checkApiRules() async {
    final results = <String, dynamic>{
      'success': true,
      'errors': <String>[],
      'warnings': <String>[],
      'collections': <String, bool>{},
    };

    try {
      print('🔍 Checking API Rules...');

      // Test if user is authenticated
      if (!pb.authStore.isValid) {
        results['errors'].add('User not authenticated. Please login first.');
        results['success'] = false;
        return results;
      }

      final userId = pb.authStore.model?.id;
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

  static Future<void> _testCartsCollection(String userId, Map<String, dynamic> results) async {
    try {
      print('Testing carts collection...');
      
      // Test list permission
      try {
        await pb.collection('carts').getList(page: 1, perPage: 1);
        print('✅ Carts list permission OK');
        results['collections']['carts_list'] = true;
      } catch (e) {
        print('❌ Carts list permission failed: $e');
        results['collections']['carts_list'] = false;
        results['errors'].add('Carts list permission failed. Check List/Search rule.');
      }

      // Test create permission
      try {
        final testData = {
          'products_id': 'test_product_${DateTime.now().millisecondsSinceEpoch}',
          'jumlah_barang': 1,
          'users_id': userId,
        };
        
        final record = await pb.collection('carts').create(body: testData);
        print('✅ Carts create permission OK');
        results['collections']['carts_create'] = true;
        
        // Clean up test data
        try {
          await pb.collection('carts').delete(record.id);
          print('✅ Carts delete permission OK');
          results['collections']['carts_delete'] = true;
        } catch (e) {
          print('❌ Carts delete permission failed: $e');
          results['collections']['carts_delete'] = false;
          results['warnings'].add('Carts delete permission failed. Check Delete rule.');
        }
        
      } catch (e) {
        print('❌ Carts create permission failed: $e');
        results['collections']['carts_create'] = false;
        results['collections']['carts_delete'] = false;
        
        if (e.toString().contains('400')) {
          results['errors'].add('Carts create failed with 400. Check field validation or Create rule.');
        } else if (e.toString().contains('403')) {
          results['errors'].add('Carts create forbidden. Set Create rule: @request.auth.id != "" && users_id = @request.auth.id');
        } else {
          results['errors'].add('Carts create failed: $e');
        }
      }

    } catch (e) {
      print('❌ Carts collection test failed: $e');
      results['collections']['carts_list'] = false;
      results['collections']['carts_create'] = false;
      results['collections']['carts_delete'] = false;
      results['errors'].add('Carts collection not accessible. Make sure it exists.');
    }
  }

  static Future<void> _testLikesCollection(String userId, Map<String, dynamic> results) async {
    try {
      print('Testing likes collection...');
      
      // Test list permission
      try {
        await pb.collection('likes').getList(page: 1, perPage: 1);
        print('✅ Likes list permission OK');
        results['collections']['likes_list'] = true;
      } catch (e) {
        print('❌ Likes list permission failed: $e');
        results['collections']['likes_list'] = false;
        results['errors'].add('Likes list permission failed. Check List/Search rule.');
      }

      // Test create permission
      try {
        final testData = {
          'products_id': 'test_product_${DateTime.now().millisecondsSinceEpoch}',
          'users_id': userId,
        };
        
        final record = await pb.collection('likes').create(body: testData);
        print('✅ Likes create permission OK');
        results['collections']['likes_create'] = true;
        
        // Clean up test data
        try {
          await pb.collection('likes').delete(record.id);
          print('✅ Likes delete permission OK');
          results['collections']['likes_delete'] = true;
        } catch (e) {
          print('❌ Likes delete permission failed: $e');
          results['collections']['likes_delete'] = false;
          results['warnings'].add('Likes delete permission failed. Check Delete rule.');
        }
        
      } catch (e) {
        print('❌ Likes create permission failed: $e');
        results['collections']['likes_create'] = false;
        results['collections']['likes_delete'] = false;
        
        if (e.toString().contains('400')) {
          results['errors'].add('Likes create failed with 400. Check field validation or Create rule.');
        } else if (e.toString().contains('403')) {
          results['errors'].add('Likes create forbidden. Set Create rule: @request.auth.id != "" && users_id = @request.auth.id');
        } else {
          results['errors'].add('Likes create failed: $e');
        }
      }

    } catch (e) {
      print('❌ Likes collection test failed: $e');
      results['collections']['likes_list'] = false;
      results['collections']['likes_create'] = false;
      results['collections']['likes_delete'] = false;
      results['errors'].add('Likes collection not accessible. Make sure it exists.');
    }
  }

  static Future<void> _testUsersCollection(String userId, Map<String, dynamic> results) async {
    try {
      print('Testing users collection...');
      
      // Test if can fetch own user record
      try {
        final user = await pb.collection('users').getOne(userId);
        print('✅ Users fetch permission OK');
        results['collections']['users_fetch'] = true;
        
        // Check if additional fields exist
        final data = user.data;
        final expectedFields = ['phone', 'address', 'theme', 'notifications', 'date_of_birth', 'gender'];
        final missingFields = <String>[];
        
        for (final field in expectedFields) {
          if (!data.containsKey(field)) {
            missingFields.add(field);
          }
        }
        
        if (missingFields.isNotEmpty) {
          results['warnings'].add('Users collection missing fields: ${missingFields.join(', ')}');
          print('⚠️ Users collection missing fields: ${missingFields.join(', ')}');
        } else {
          print('✅ Users collection has all required fields');
          results['collections']['users_fields'] = true;
        }
        
      } catch (e) {
        print('❌ Users fetch permission failed: $e');
        results['collections']['users_fetch'] = false;
        results['errors'].add('Cannot fetch user data. Check users collection permissions.');
      }

    } catch (e) {
      print('❌ Users collection test failed: $e');
      results['collections']['users_fetch'] = false;
      results['errors'].add('Users collection not accessible: $e');
    }
  }

  static void printResults(Map<String, dynamic> results) {
    print('\n📊 API RULES CHECK RESULTS:');
    print('=' * 40);
    
    // Print success status
    if (results['success']) {
      print('🎉 Overall Status: SUCCESS');
    } else {
      print('❌ Overall Status: FAILED');
    }
    
    print('\n📋 Collection Tests:');
    final collections = results['collections'] as Map<String, bool>;
    collections.forEach((key, value) {
      final status = value ? '✅' : '❌';
      print('$status $key');
    });
    
    // Print errors
    final errors = results['errors'] as List<String>;
    if (errors.isNotEmpty) {
      print('\n🚨 ERRORS:');
      for (final error in errors) {
        print('   • $error');
      }
    }
    
    // Print warnings
    final warnings = results['warnings'] as List<String>;
    if (warnings.isNotEmpty) {
      print('\n⚠️  WARNINGS:');
      for (final warning in warnings) {
        print('   • $warning');
      }
    }
    
    print('\n' + '=' * 40);
    
    if (!results['success']) {
      print('\n🔧 FOLLOW THESE STEPS TO FIX:');
      print('1. Open PocketBase Admin: http://127.0.0.1:8090/_/');
      print('2. Check each collection\'s API rules');
      print('3. Set rules as shown in fix_api_rules.md');
      print('4. Add missing fields to users collection');
      print('5. Test again');
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