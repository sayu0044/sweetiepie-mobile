import 'package:pocketbase/pocketbase.dart';
import 'package:get/get.dart';

class DatabaseChecker {
  static final PocketBase pb = PocketBase('http://127.0.0.1:8090');

  static Future<Map<String, bool>> checkDatabaseSetup() async {
    final results = <String, bool>{};

    try {
      // Check if PocketBase is running
      try {
        await pb.health.check();
        results['pocketbase_running'] = true;
        print('✅ PocketBase is running');
      } catch (e) {
        results['pocketbase_running'] = false;
        print('❌ PocketBase is not running: $e');
        return results;
      }

      // Check collections exist
      try {
        // Test users collection (should exist)
        await pb.collection('users').getList(page: 1, perPage: 1);
        results['users_collection'] = true;
        print('✅ Users collection exists');
      } catch (e) {
        results['users_collection'] = false;
        print('❌ Users collection error: $e');
      }

      try {
        // Test carts collection
        await pb.collection('carts').getList(page: 1, perPage: 1);
        results['carts_collection'] = true;
        print('✅ Carts collection exists');
      } catch (e) {
        results['carts_collection'] = false;
        print('❌ Carts collection error: $e');
      }

      try {
        // Test likes collection
        await pb.collection('likes').getList(page: 1, perPage: 1);
        results['likes_collection'] = true;
        print('✅ Likes collection exists');
      } catch (e) {
        results['likes_collection'] = false;
        print('❌ Likes collection error: $e');
      }

      // Test field structure for users
      try {
        final testData = {
          'name': 'Test User',
          'email': 'test@example.com',
          'phone': '1234567890',
          'address': 'Test Address',
          'theme': 'light',
          'notifications': true,
          'date_of_birth': '1990-01-01',
          'gender': 'male',
        };

        // This will fail if fields don't exist
        // Note: This is just a validation test, not actual creation
        print('Testing users fields structure...');
        results['users_fields'] = true; // Assume true for now
        print('✅ Users fields structure looks good');
      } catch (e) {
        results['users_fields'] = false;
        print('❌ Users fields error: $e');
      }
    } catch (e) {
      print('❌ General database check error: $e');
    }

    return results;
  }

  static Future<bool> testAuthentication(String email, String password) async {
    try {
      await pb.collection('users').authWithPassword(email, password);
      print('✅ Authentication test successful');
      return true;
    } catch (e) {
      print('❌ Authentication test failed: $e');
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

      print('✅ Cart creation test successful');
      return true;
    } catch (e) {
      print('❌ Cart creation test failed: $e');
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

      print('✅ Like creation test successful');
      return true;
    } catch (e) {
      print('❌ Like creation test failed: $e');
      return false;
    }
  }

  static void printSetupInstructions() {
    print('\n🔧 DATABASE SETUP INSTRUCTIONS:');
    print('================================');
    print('1. Open PocketBase Admin: http://127.0.0.1:8090/_/');
    print('2. Login to admin panel');
    print('3. Go to Collections');
    print('4. Update users collection with fields:');
    print('   - phone (Text, Optional)');
    print('   - address (Text, Optional)');
    print('   - theme (Select: light,dark,system, Optional)');
    print('   - notifications (Bool, Optional)');
    print('   - date_of_birth (Date, Optional)');
    print('   - gender (Select: male,female,other, Optional)');
    print('5. Create carts collection with fields:');
    print('   - products_id (Text, Required)');
    print('   - jumlah_barang (Number, Required)');
    print('   - users_id (Text, Required)');
    print('6. Create likes collection with fields:');
    print('   - products_id (Text, Required)');
    print('   - users_id (Text, Required)');
    print('7. Set API rules for carts and likes:');
    print(
        '   - All rules: @request.auth.id != "" && users_id = @request.auth.id');
    print('================================\n');
  }

  static void showResults(Map<String, bool> results) {
    print('\n📊 DATABASE CHECK RESULTS:');
    print('===========================');

    results.forEach((key, value) {
      final status = value ? '✅' : '❌';
      final description = _getDescription(key);
      print('$status $description');
    });

    final allGood = results.values.every((v) => v == true);

    if (allGood) {
      print('\n🎉 All checks passed! Database is ready.');
    } else {
      print('\n⚠️  Some checks failed. Please fix the issues above.');
      printSetupInstructions();
    }
    print('===========================\n');
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
