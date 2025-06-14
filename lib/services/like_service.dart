import 'package:pocketbase/pocketbase.dart';
import 'package:get/get.dart';
import 'package:sweetipie/models/like.dart';
import 'package:sweetipie/services/auth_service.dart';
import 'package:flutter/foundation.dart';

class LikeService extends GetxController {
  final PocketBase pb = PocketBase('http://127.0.0.1:8090');
  final AuthService _authService = Get.find<AuthService>();

  final RxList<Like> likedItems = <Like>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    debugPrint('LikeService: Initializing...');

    // Sync auth from AuthService
    _syncAuthFromAuthService();

    // Load liked items when service initializes
    if (_authService.isAuthenticated) {
      debugPrint('LikeService: User is authenticated, fetching liked items');
      fetchLikedItems();
    } else {
      debugPrint('LikeService: User not authenticated, skipping likes fetch');
    }

    // Listen to auth changes
    _authService.currentUser.listen((user) {
      if (user != null) {
        debugPrint('LikeService: User logged in: ${user.id}');
        _syncAuthFromAuthService();
        fetchLikedItems();
      } else {
        debugPrint('LikeService: User logged out, clearing likes');
        likedItems.clear();
      }
    });
  }

  // Sync authentication from AuthService
  void _syncAuthFromAuthService() {
    try {
      final authToken = _authService.pb.authStore.token;
      final authModel = _authService.pb.authStore.record;

      if (authToken.isNotEmpty) {
        pb.authStore.save(authToken, authModel);
        debugPrint('LikeService: Auth synced from AuthService');
        final tokenPreview = authToken.length > 20
            ? '${authToken.substring(0, 20)}...'
            : authToken;
        debugPrint('LikeService: Token: $tokenPreview');
        debugPrint('LikeService: User ID: ${authModel?.id}');
      } else {
        debugPrint('LikeService: No auth to sync');
      }
    } catch (e) {
      debugPrint('LikeService: Error syncing auth: $e');
    }
  }

  // Get current user ID
  String get currentUserId => _authService.currentUser.value?.id ?? '';

  // Check if user is properly authenticated
  bool get _isUserAuthenticated {
    final hasUser = currentUserId.isNotEmpty;
    final hasValidToken = pb.authStore.isValid;
    final authServiceAuthenticated = _authService.isAuthenticated;

    debugPrint(
        'LikeService: Auth check - hasUser: $hasUser, hasValidToken: $hasValidToken, authServiceAuth: $authServiceAuthenticated');

    return hasUser && hasValidToken && authServiceAuthenticated;
  }

  // Fetch all liked items for current user
  Future<void> fetchLikedItems() async {
    if (!_isUserAuthenticated) {
      debugPrint(
          'LikeService: Cannot fetch liked items - user not authenticated');
      return;
    }

    try {
      isLoading.value = true;
      debugPrint('LikeService: Fetching liked items for user: $currentUserId');

      // Ensure auth is synced before making request
      _syncAuthFromAuthService();

      final records = await pb.collection('likes').getFullList(
            filter: 'users_id = "$currentUserId"',
            sort: '-created',
          );

      likedItems.clear();
      for (final record in records) {
        likedItems.add(Like.fromJson(record.data));
      }

      debugPrint('LikeService: Fetched ${likedItems.length} liked items');
    } catch (e) {
      debugPrint('LikeService: Error fetching liked items: $e');

      // Handle specific authentication errors
      if (e.toString().contains('401') || e.toString().contains('403')) {
        debugPrint('LikeService: Authentication error, refreshing auth...');
        await _authService.refreshAuth();
      } else {
        Get.snackbar('Error', 'Failed to load liked items');
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Add/Toggle like for a product
  Future<bool> toggleLike(String productId) async {
    debugPrint('LikeService: toggleLike called - ProductID: $productId');

    if (!_isUserAuthenticated) {
      debugPrint('LikeService: User not authenticated for toggleLike');
      Get.snackbar('Error', 'Please login first to like items');
      return false;
    }

    try {
      debugPrint(
          'LikeService: Toggling like - ProductID: $productId, UserID: $currentUserId');

      // Ensure auth is synced before making request
      _syncAuthFromAuthService();

      // Check if product is already liked
      final existingLike = likedItems.firstWhereOrNull(
        (like) => like.productsId == productId,
      );

      if (existingLike != null) {
        // Unlike - remove from database
        debugPrint('LikeService: Removing like for product: $productId');

        // Verify like belongs to current user
        if (existingLike.usersId != currentUserId) {
          debugPrint('LikeService: Like does not belong to current user');
          Get.snackbar('Error', 'Invalid like item');
          return false;
        }

        // Check if like ID is valid before attempting delete
        if (existingLike.id.isEmpty) {
          debugPrint('LikeService: ❌ Like ID is empty, removing locally only');
          likedItems.removeWhere((like) =>
              like.productsId == productId && like.usersId == currentUserId);
          Get.snackbar('Success', 'Removed from favorites');
          await fetchLikedItems();
          return false; // Product is now unliked
        }

        debugPrint(
            'LikeService: Sending delete request for like: ${existingLike.id}');
        await pb.collection('likes').delete(existingLike.id);
        debugPrint('LikeService: Delete successful');

        likedItems.removeWhere((like) => like.id == existingLike.id);

        Get.snackbar('Success', 'Removed from favorites');
        await fetchLikedItems();
        return false; // Product is now unliked
      } else {
        // Like - add to database
        final likeData = {
          'products_id': productId,
          'users_id': currentUserId,
        };

        debugPrint('LikeService: Creating new like with data: $likeData');

        final record = await pb.collection('likes').create(body: likeData);
        debugPrint(
            'LikeService: Successfully created like record: ${record.id}');

        final newLike = Like.fromJson(record.data);

        likedItems.add(newLike);

        Get.snackbar('Success', 'Added to favorites');
        await fetchLikedItems();
        return true; // Product is now liked
      }
    } catch (e) {
      debugPrint('LikeService: Error toggling like: $e');

      // Handle specific error types
      if (e.toString().contains('401') || e.toString().contains('403')) {
        debugPrint('LikeService: Authentication error during toggleLike');
        Get.snackbar('Error', 'Authentication failed. Please login again.');
        await _authService.refreshAuth();
      } else if (e.toString().contains('404')) {
        debugPrint('LikeService: Like not found in database, removing locally');
        // Remove from local list if not found in database
        likedItems.removeWhere((like) => like.productsId == productId);
        Get.snackbar('Success', 'Removed from favorites');
        await fetchLikedItems();
        return false;
      } else if (e.toString().contains('400')) {
        debugPrint('LikeService: 400 Error - likely validation or auth issue');
        debugPrint('LikeService: Current user ID: $currentUserId');
        debugPrint(
            'LikeService: Auth service authenticated: ${_authService.isAuthenticated}');
        debugPrint('LikeService: PB auth store valid: ${pb.authStore.isValid}');
        Get.snackbar('Error',
            'Failed to update favorites. Please make sure you are logged in.');
      } else {
        Get.snackbar('Error', 'Failed to update favorites. Please try again.');
      }
      return false;
    }
  }

  // Check if product is liked
  bool isLiked(String productId) {
    return likedItems.any((like) => like.productsId == productId);
  }

  // Get liked product IDs
  List<String> get likedProductIds {
    return likedItems.map((like) => like.productsId).toList();
  }

  // Enhanced remove like by product ID with better error handling
  Future<bool> removeLike(String productId) async {
    if (!_isUserAuthenticated) {
      debugPrint('LikeService: User not authenticated for removeLike');
      Get.snackbar('Error', 'Please login to remove favorites');
      return false;
    }

    try {
      debugPrint('LikeService: Removing like for product: $productId');

      // Ensure auth is synced before making request
      _syncAuthFromAuthService();

      final existingLike = likedItems.firstWhereOrNull(
        (like) => like.productsId == productId,
      );

      if (existingLike != null) {
        // Verify like belongs to current user
        if (existingLike.usersId != currentUserId) {
          debugPrint('LikeService: Like does not belong to current user');
          Get.snackbar('Error', 'Invalid like item');
          return false;
        }

        debugPrint(
            'LikeService: Sending delete request for like: ${existingLike.id}');
        await pb.collection('likes').delete(existingLike.id);
        debugPrint('LikeService: Delete successful');

        likedItems.removeWhere((like) => like.id == existingLike.id);

        Get.snackbar('Success', 'Removed from favorites');
        await fetchLikedItems();
        return true;
      } else {
        debugPrint('LikeService: Like not found for product: $productId');
        Get.snackbar('Info', 'Item not in favorites');
        return false;
      }
    } catch (e) {
      debugPrint('LikeService: Error removing like: $e');

      if (e.toString().contains('401') || e.toString().contains('403')) {
        debugPrint('LikeService: Authentication error during removeLike');
        Get.snackbar('Error', 'Authentication failed. Please login again.');
        await _authService.refreshAuth();
      } else if (e.toString().contains('404')) {
        debugPrint('LikeService: Like not found in database, removing locally');
        // Remove from local list if not found in database
        likedItems.removeWhere((like) => like.productsId == productId);
        Get.snackbar('Success', 'Removed from favorites');
        await fetchLikedItems();
        return true;
      } else {
        Get.snackbar(
            'Error', 'Failed to remove from favorites. Please try again.');
      }
      return false;
    }
  }

  // Clear all likes for current user
  Future<bool> clearAllLikes() async {
    if (!_isUserAuthenticated) {
      debugPrint('LikeService: User not authenticated for clearAllLikes');
      return false;
    }

    try {
      isLoading.value = true;

      // Ensure auth is synced before making request
      _syncAuthFromAuthService();

      // Get all likes for current user
      final records = await pb.collection('likes').getFullList(
            filter: 'users_id = "$currentUserId"',
          );

      // Delete all likes
      for (final record in records) {
        await pb.collection('likes').delete(record.id);
      }

      likedItems.clear();

      Get.snackbar('Success', 'All favorites cleared');
      return true;
    } catch (e) {
      debugPrint('LikeService: Error clearing likes: $e');

      if (e.toString().contains('401') || e.toString().contains('403')) {
        debugPrint('LikeService: Authentication error during clearAllLikes');
        await _authService.refreshAuth();
      } else {
        Get.snackbar('Error', 'Failed to clear favorites');
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Get count of liked items
  int get likedItemCount => likedItems.length;

  // Refresh liked items
  Future<void> refreshLikes() async {
    await fetchLikedItems();
  }
}
