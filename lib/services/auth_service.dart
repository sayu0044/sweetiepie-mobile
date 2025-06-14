import 'package:pocketbase/pocketbase.dart';
import 'package:get/get.dart';
import 'package:sweetipie/services/cart_service.dart';
import 'package:sweetipie/services/like_service.dart';
import 'package:sweetipie/services/user_settings_service.dart';
import 'package:flutter/foundation.dart';

class AuthService extends GetxController {
  final PocketBase pb =
      PocketBase('http://127.0.0.1:8090'); // Local PocketBase URL
  final Rx<RecordModel?> currentUser = Rx<RecordModel?>(null);

  @override
  void onInit() {
    super.onInit();
    debugPrint('AuthService: Initializing...');

    // Check if there's already a valid auth token
    _checkExistingAuth();
  }

  // Check for existing authentication
  Future<void> _checkExistingAuth() async {
    try {
      debugPrint('AuthService: Checking existing auth...');
      debugPrint('AuthService: Token valid: ${pb.authStore.isValid}');
      final token = pb.authStore.token;
      final tokenPreview =
          token.length > 20 ? '${token.substring(0, 20)}...' : token;
      debugPrint('AuthService: Token: $tokenPreview');

      if (pb.authStore.isValid) {
        debugPrint('AuthService: Found valid existing auth');
        currentUser.value = pb.authStore.record as RecordModel;
        debugPrint('AuthService: Current user ID: ${currentUser.value?.id}');

        // Initialize services with existing auth
        await _initializeUserServices();
      } else {
        debugPrint('AuthService: No valid existing auth found');
      }
    } catch (e) {
      debugPrint('AuthService: Error checking existing auth: $e');
    }
  }

  Future<void> login(String email, String password) async {
    try {
      debugPrint('AuthService: Attempting login for: $email');

      final authData = await pb.collection('users').authWithPassword(
            email,
            password,
          );

      debugPrint('AuthService: Login successful');
      debugPrint('AuthService: User ID: ${authData.record.id}');
      final loginToken = pb.authStore.token;
      final loginTokenPreview = loginToken.length > 20
          ? '${loginToken.substring(0, 20)}...'
          : loginToken;
      debugPrint('AuthService: Token: $loginTokenPreview');

      currentUser.value = authData.record;

      // Ensure all PocketBase instances use the same auth
      await _syncAuthAcrossServices();

      // Initialize other services after successful login
      await _initializeUserServices();

      debugPrint('AuthService: Login process completed successfully');
    } catch (e) {
      debugPrint('Login error: $e'); // For debugging
      if (e is ClientException) {
        final errorMessage = e.response['message'] ?? 'Login failed';
        debugPrint('AuthService: Login failed with message: $errorMessage');
        throw errorMessage;
      }
      throw 'Failed to login. Please check your credentials.';
    }
  }

  // Sync authentication across all services
  Future<void> _syncAuthAcrossServices() async {
    try {
      debugPrint('AuthService: Syncing auth across services...');

      // Get current auth data
      final token = pb.authStore.token;
      final model = pb.authStore.record;

      if (token.isNotEmpty) {
        // Sync to CartService if registered
        if (Get.isRegistered<CartService>()) {
          final cartService = Get.find<CartService>();
          cartService.pb.authStore.save(token, model);
          debugPrint('AuthService: CartService auth synced');
        }

        // Sync to LikeService if registered
        if (Get.isRegistered<LikeService>()) {
          final likeService = Get.find<LikeService>();
          likeService.pb.authStore.save(token, model);
          debugPrint('AuthService: LikeService auth synced');
        }

        // Sync to UserSettingsService if registered
        if (Get.isRegistered<UserSettingsService>()) {
          final settingsService = Get.find<UserSettingsService>();
          settingsService.pb.authStore.save(token, model);
          debugPrint('AuthService: UserSettingsService auth synced');
        }
      }

      debugPrint('AuthService: Auth sync completed');
    } catch (e) {
      debugPrint('AuthService: Error syncing auth: $e');
    }
  }

  // Initialize user-dependent services after login
  Future<void> _initializeUserServices() async {
    try {
      debugPrint('AuthService: Initializing user services...');
      debugPrint('AuthService: User ID: ${currentUser.value?.id}');
      debugPrint(
          'AuthService: User email: ${currentUser.value?.data['email']}');

      // Import services using Get.find to avoid circular dependency
      if (Get.isRegistered<CartService>()) {
        debugPrint('AuthService: Initializing CartService...');
        final cartService = Get.find<CartService>();
        await cartService.fetchCartItems();
        debugPrint(
            'AuthService: CartService initialized, items: ${cartService.cartItems.length}');
      }

      if (Get.isRegistered<LikeService>()) {
        debugPrint('AuthService: Initializing LikeService...');
        final likeService = Get.find<LikeService>();
        await likeService.fetchLikedItems();
        debugPrint(
            'AuthService: LikeService initialized, items: ${likeService.likedItems.length}');
      }

      if (Get.isRegistered<UserSettingsService>()) {
        debugPrint('AuthService: Initializing UserSettingsService...');
        final settingsService = Get.find<UserSettingsService>();
        await settingsService.fetchUserSettings();
        debugPrint('AuthService: UserSettingsService initialized');
      }

      debugPrint('AuthService: All user services initialized successfully');
    } catch (e) {
      debugPrint('AuthService: Error initializing user services: $e');
    }
  }

  Future<void> register(String email, String password, String name) async {
    try {
      debugPrint('AuthService: Attempting registration for: $email');

      final body = <String, dynamic>{
        "email": email,
        "password": password,
        "passwordConfirm": password,
        "name": name,
        "emailVisibility": true,
      };

      await pb.collection('users').create(body: body);
      debugPrint('AuthService: Registration successful');

      // After registration, login automatically
      await login(email, password);
    } catch (e) {
      debugPrint('Registration error: $e'); // For debugging
      if (e is ClientException) {
        final errorMessage = e.response['message'] ?? 'Registration failed';
        debugPrint(
            'AuthService: Registration failed with message: $errorMessage');
        throw errorMessage;
      }
      throw 'Failed to register. Please try again.';
    }
  }

  Future<void> logout() async {
    try {
      debugPrint('AuthService: Logging out...');

      pb.authStore.clear();
      currentUser.value = null;

      // Clear auth from other services
      await _clearAuthFromServices();

      debugPrint('AuthService: Logout completed');
    } catch (e) {
      debugPrint('AuthService: Error during logout: $e');
    }
  }

  // Clear authentication from all services
  Future<void> _clearAuthFromServices() async {
    try {
      debugPrint('AuthService: Clearing auth from services...');

      // Clear from CartService if registered
      if (Get.isRegistered<CartService>()) {
        final cartService = Get.find<CartService>();
        cartService.pb.authStore.clear();
        cartService.cartItems.clear();
        cartService.totalPrice.value = 0.0;
        debugPrint('AuthService: CartService auth cleared');
      }

      // Clear from LikeService if registered
      if (Get.isRegistered<LikeService>()) {
        final likeService = Get.find<LikeService>();
        likeService.pb.authStore.clear();
        likeService.likedItems.clear();
        debugPrint('AuthService: LikeService auth cleared');
      }

      // Clear from UserSettingsService if registered
      if (Get.isRegistered<UserSettingsService>()) {
        final settingsService = Get.find<UserSettingsService>();
        settingsService.pb.authStore.clear();
        settingsService.currentSettings.value = null;
        debugPrint('AuthService: UserSettingsService auth cleared');
      }

      debugPrint('AuthService: Auth clearing completed');
    } catch (e) {
      debugPrint('AuthService: Error clearing auth from services: $e');
    }
  }

  bool get isAuthenticated {
    final isValid = pb.authStore.isValid;
    final hasUser = currentUser.value != null;
    debugPrint(
        'AuthService: isAuthenticated check - Token valid: $isValid, Has user: $hasUser');
    return isValid && hasUser;
  }

  // Force refresh authentication status
  Future<void> refreshAuth() async {
    try {
      debugPrint('AuthService: Refreshing auth...');

      if (pb.authStore.isValid) {
        // Try to verify the token is still valid
        final userId = pb.authStore.record?.id;
        if (userId != null) {
          await pb.collection('users').getOne(userId);
        }

        currentUser.value = pb.authStore.record as RecordModel;
        await _syncAuthAcrossServices();
        debugPrint('AuthService: Auth refresh successful');
      } else {
        debugPrint('AuthService: Auth refresh failed - invalid token');
        await logout();
      }
    } catch (e) {
      debugPrint('AuthService: Auth refresh error: $e');
      await logout();
    }
  }
}
