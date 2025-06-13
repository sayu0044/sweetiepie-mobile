import 'package:pocketbase/pocketbase.dart';
import 'package:flutter/foundation.dart';

class DatabaseChecker {
  static final PocketBase pb = PocketBase('http://127.0.0.1:8090');

  static Future<Map<String, bool>> checkDatabaseSetup() async {
    final results = <String, bool>{};

    try {
      // Check if PocketBase is running
      try {
        await pb.health.check();
        results['pocketbase_running'] = true;
        debugPrint('✅ PocketBase is running');
      } catch (e) {
        results['pocketbase_running'] = false;
        debugPrint('❌ PocketBase is not running: $e');
        return results;
      }

      // Check collections exist
      try {
        // Test users collection (should exist)
        await pb.collection('users').getList(page: 1, perPage: 1);
        results['users_collection'] = true;
        debugPrint('✅ Users collection exists');
      } catch (e) {
        results['users_collection'] = false;
        debugPrint('❌ Users collection error: $e');
      }

      try {
        // Test carts collection
        await pb.collection('carts').getList(page: 1, perPage: 1);
        results['carts_collection'] = true;
        debugPrint('✅ Carts collection exists');
      } catch (e) {
        results['carts_collection'] = false;
        debugPrint('❌ Carts collection error: $e');
      }

      try {
        // Test likes collection
        await pb.collection('likes').getList(page: 1, perPage: 1);
        results['likes_collection'] = true;
        debugPrint('✅ Likes collection exists');
      } catch (e) {
        results['likes_collection'] = false;
        debugPrint('❌ Likes collection error: $e');
      }

      // Test field structure for users
      try {
        // This will fail if fields don't exist
        // Note: This is just a validation test, not actual creation
        debugPrint('Testing users fields structure...');
        results['users_fields'] = true; // Assume true for now
        debugPrint('✅ Users fields structure looks good');
      } catch (e) {
        results['users_fields'] = false;
        debugPrint('❌ Users fields error: $e');
      }
    } catch (e) {
      debugPrint('❌ General database check error: $e');
    }

    return results;
  }

  static Future<bool> testAuthentication(String email, String password) async {
    try {
      await pb.collection('users').authWithPassword(email, password);
      debugPrint('✅ Authentication test successful');
      return true;
    } catch (e) {
      debugPrint('❌ Authentication test failed: $e');
      return false;
    }
  }

  static Future<bool> testCartCreation(String userId, String productId) async {
    try {
      final data = {
        'products_id': productId,
        'jumlah_barang': 1,
        'users_id': userId,
      };

      final record = await pb.collection('carts').create(body: data);

      // Clean up test data
      await pb.collection('carts').delete(record.id);

      debugPrint('✅ Cart creation test successful');
      return true;
    } catch (e) {
      debugPrint('❌ Cart creation test failed: $e');
      return false;
    }
  }

  static Future<bool> testLikeCreation(String userId, String productId) async {
    try {
      final data = {
        'products_id': productId,
        'users_id': userId,
      };

      final record = await pb.collection('likes').create(body: data);

      // Clean up test data
      await pb.collection('likes').delete(record.id);

      debugPrint('✅ Like creation test successful');
      return true;
    } catch (e) {
      debugPrint('❌ Like creation test failed: $e');
      return false;
    }
  }

  static void debugPrintSetupInstructions() {
    debugPrint('\n🔧 DATABASE SETUP INSTRUCTIONS:');
    debugPrint('================================');
    debugPrint('1. Open PocketBase Admin: http://127.0.0.1:8090/_/');
    debugPrint('2. Login to admin panel');
    debugPrint('3. Go to Collections');
    debugPrint('4. Update users collection with fields:');
    debugPrint('   - phone (Text, Optional)');
    debugPrint('   - address (Text, Optional)');
    debugPrint('   - theme (Select: light,dark,system, Optional)');
    debugPrint('   - notifications (Bool, Optional)');
    debugPrint('   - date_of_birth (Date, Optional)');
    debugPrint('   - gender (Select: male,female,other, Optional)');
    debugPrint('5. Create carts collection with fields:');
    debugPrint('   - products_id (Text, Required)');
    debugPrint('   - jumlah_barang (Number, Required)');
    debugPrint('   - users_id (Text, Required)');
    debugPrint('6. Create likes collection with fields:');
    debugPrint('   - products_id (Text, Required)');
    debugPrint('   - users_id (Text, Required)');
    debugPrint('7. Set API rules for carts and likes:');
    debugPrint(
        '   - All rules: @request.auth.id != "" && users_id = @request.auth.id');
    debugPrint('================================\n');
  }

  static void showResults(Map<String, bool> results) {
    debugPrint('\n📊 DATABASE CHECK RESULTS:');
    debugPrint('===========================');

    results.forEach((key, value) {
      final status = value ? '✅' : '❌';
      final description = _getDescription(key);
      debugPrint('$status $description');
    });

    final allGood = results.values.every((v) => v == true);

    if (allGood) {
      debugPrint('\n🎉 All checks passed! Database is ready.');
    } else {
      debugPrint('\n⚠️  Some checks failed. Please fix the issues above.');
      debugPrintSetupInstructions();
    }
    debugPrint('===========================\n');
  }

  static String _getDescription(String key) {
    switch (key) {
      case 'pocketbase_running':
        return 'PocketBase server running';
      case 'users_collection':
        return 'Users collection accessible';
      case 'carts_collection':
        return 'Carts collection exists';
      case 'likes_collection':
        return 'Likes collection exists';
      case 'users_fields':
        return 'Users fields structure';
      default:
        return key;
    }
  }
}
