import 'package:pocketbase/pocketbase.dart';
import 'package:get/get.dart';
import 'package:sweetipie/services/cart_service.dart';
import 'package:sweetipie/services/like_service.dart';
import 'package:sweetipie/services/user_settings_service.dart';

class AuthService extends GetxController {
  final PocketBase pb =
      PocketBase('http://127.0.0.1:8090'); // Local PocketBase URL
  final Rx<RecordModel?> currentUser = Rx<RecordModel?>(null);

  @override
  void onInit() {
    super.onInit();
    print('AuthService: Initializing...');

    // Check if there's already a valid auth token
    _checkExistingAuth();
  }

  // Check for existing authentication
  Future<void> _checkExistingAuth() async {
    try {
      print('AuthService: Checking existing auth...');
      print('AuthService: Token valid: ${pb.authStore.isValid}');
      print(
          'AuthService: Token: ${pb.authStore.token?.substring(0, 20) ?? 'null'}...');

      if (pb.authStore.isValid && pb.authStore.model != null) {
        print('AuthService: Found valid existing auth');
        currentUser.value = pb.authStore.model as RecordModel;
        print('AuthService: Current user ID: ${currentUser.value?.id}');

        // Initialize services with existing auth
        await _initializeUserServices();
      } else {
        print('AuthService: No valid existing auth found');
      }
    } catch (e) {
      print('AuthService: Error checking existing auth: $e');
    }
  }

  Future<void> login(String email, String password) async {
    try {
      print('AuthService: Attempting login for: $email');

      final authData = await pb.collection('users').authWithPassword(
            email,
            password,
          );

      print('AuthService: Login successful');
      print('AuthService: User ID: ${authData.record?.id}');
      print('AuthService: Token: ${pb.authStore.token?.substring(0, 20)}...');

      currentUser.value = authData.record;

      // Ensure all PocketBase instances use the same auth
      await _syncAuthAcrossServices();

      // Initialize other services after successful login
      await _initializeUserServices();

      print('AuthService: Login process completed successfully');
    } catch (e) {
      print('Login error: $e'); // For debugging
      if (e is ClientException) {
        final errorMessage = e.response['message'] ?? 'Login failed';
        print('AuthService: Login failed with message: $errorMessage');
        throw errorMessage;
      }
      throw 'Failed to login. Please check your credentials.';
    }
  }

  // Sync authentication across all services
  Future<void> _syncAuthAcrossServices() async {
    try {
      print('AuthService: Syncing auth across services...');

      // Get current auth data
      final token = pb.authStore.token;
      final model = pb.authStore.model;

      if (token != null && model != null) {
        // Sync to CartService if registered
        if (Get.isRegistered<CartService>()) {
          final cartService = Get.find<CartService>();
          cartService.pb.authStore.save(token, model);
          print('AuthService: CartService auth synced');
        }

        // Sync to LikeService if registered
        if (Get.isRegistered<LikeService>()) {
          final likeService = Get.find<LikeService>();
          likeService.pb.authStore.save(token, model);
          print('AuthService: LikeService auth synced');
        }

        // Sync to UserSettingsService if registered
        if (Get.isRegistered<UserSettingsService>()) {
          final settingsService = Get.find<UserSettingsService>();
          settingsService.pb.authStore.save(token, model);
          print('AuthService: UserSettingsService auth synced');
        }
      }

      print('AuthService: Auth sync completed');
    } catch (e) {
      print('AuthService: Error syncing auth: $e');
    }
  }

  // Initialize user-dependent services after login
  Future<void> _initializeUserServices() async {
    try {
      print('AuthService: Initializing user services...');
      print('AuthService: User ID: ${currentUser.value?.id}');
      print('AuthService: User email: ${currentUser.value?.data['email']}');

      // Import services using Get.find to avoid circular dependency
      if (Get.isRegistered<CartService>()) {
        print('AuthService: Initializing CartService...');
        final cartService = Get.find<CartService>();
        await cartService.fetchCartItems();
        print(
            'AuthService: CartService initialized, items: ${cartService.cartItems.length}');
      }

      if (Get.isRegistered<LikeService>()) {
        print('AuthService: Initializing LikeService...');
        final likeService = Get.find<LikeService>();
        await likeService.fetchLikedItems();
        print(
            'AuthService: LikeService initialized, items: ${likeService.likedItems.length}');
      }

      if (Get.isRegistered<UserSettingsService>()) {
        print('AuthService: Initializing UserSettingsService...');
        final settingsService = Get.find<UserSettingsService>();
        await settingsService.fetchUserSettings();
        print('AuthService: UserSettingsService initialized');
      }

      print('AuthService: All user services initialized successfully');
    } catch (e) {
      print('AuthService: Error initializing user services: $e');
    }
  }

  Future<void> register(String email, String password, String name) async {
    try {
      print('AuthService: Attempting registration for: $email');

      final body = <String, dynamic>{
        "email": email,
        "password": password,
        "passwordConfirm": password,
        "name": name,
        "emailVisibility": true,
      };

      await pb.collection('users').create(body: body);
      print('AuthService: Registration successful');

      // After registration, login automatically
      await login(email, password);
    } catch (e) {
      print('Registration error: $e'); // For debugging
      if (e is ClientException) {
        final errorMessage = e.response['message'] ?? 'Registration failed';
        print('AuthService: Registration failed with message: $errorMessage');
        throw errorMessage;
      }
      throw 'Failed to register. Please try again.';
    }
  }

  Future<void> logout() async {
    try {
      print('AuthService: Logging out...');

      pb.authStore.clear();
      currentUser.value = null;

      // Clear auth from other services
      await _clearAuthFromServices();

      print('AuthService: Logout completed');
    } catch (e) {
      print('AuthService: Error during logout: $e');
    }
  }

  // Clear authentication from all services
  Future<void> _clearAuthFromServices() async {
    try {
      print('AuthService: Clearing auth from services...');

      // Clear from CartService if registered
      if (Get.isRegistered<CartService>()) {
        final cartService = Get.find<CartService>();
        cartService.pb.authStore.clear();
        cartService.cartItems.clear();
        cartService.totalPrice.value = 0.0;
        print('AuthService: CartService auth cleared');
      }

      // Clear from LikeService if registered
      if (Get.isRegistered<LikeService>()) {
        final likeService = Get.find<LikeService>();
        likeService.pb.authStore.clear();
        likeService.likedItems.clear();
        print('AuthService: LikeService auth cleared');
      }

      // Clear from UserSettingsService if registered
      if (Get.isRegistered<UserSettingsService>()) {
        final settingsService = Get.find<UserSettingsService>();
        settingsService.pb.authStore.clear();
        settingsService.currentSettings.value = null;
        print('AuthService: UserSettingsService auth cleared');
      }

      print('AuthService: Auth clearing completed');
    } catch (e) {
      print('AuthService: Error clearing auth from services: $e');
    }
  }

  bool get isAuthenticated {
    final isValid = pb.authStore.isValid;
    final hasUser = currentUser.value != null;
    print(
        'AuthService: isAuthenticated check - Token valid: $isValid, Has user: $hasUser');
    return isValid && hasUser;
  }

  // Force refresh authentication status
  Future<void> refreshAuth() async {
    try {
      print('AuthService: Refreshing auth...');

      if (pb.authStore.isValid && pb.authStore.model != null) {
        // Try to verify the token is still valid
        final userId = pb.authStore.model?.id;
        if (userId != null) {
          await pb.collection('users').getOne(userId);
        }

        currentUser.value = pb.authStore.model as RecordModel;
        await _syncAuthAcrossServices();
        print('AuthService: Auth refresh successful');
      } else {
        print('AuthService: Auth refresh failed - invalid token');
        await logout();
      }
    } catch (e) {
      print('AuthService: Auth refresh error: $e');
      await logout();
    }
  }
}
