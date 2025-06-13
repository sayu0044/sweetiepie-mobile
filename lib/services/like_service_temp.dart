import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sweetipie/models/like.dart';
import 'package:sweetipie/services/auth_service.dart';

class LikeServiceTemp extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  // Local storage for liked items per user (temporary)
  // Key = userId, Value = List of Like items
  final RxMap<String, List<Like>> _userLikedItems = <String, List<Like>>{}.obs;

  // Observable for triggering UI updates
  final RxInt _updateTrigger = 0.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    debugPrint(
        'LikeServiceTemp: Initialized with persistent user-isolated storage');

    // Load likes data from storage on init
    _loadLikesFromStorage();

    // Listen to auth changes
    _authService.currentUser.listen((user) async {
      if (user != null) {
        debugPrint(
            'LikeServiceTemp: User changed to ${user.id}, loading likes from storage...');

        // Load from storage when user logs in
        await _loadLikesFromStorage();

        // Then ensure user likes exist
        _ensureUserLikes(user.id);

        debugPrint(
            'LikeServiceTemp: Likes loaded for user ${user.id}, count: $likedItemCount');
      }
    });
  }

  // Get current user ID
  String get currentUserId => _authService.currentUser.value?.id ?? '';

  // Get liked items for current user only
  List<Like> get likedItems {
    if (currentUserId.isEmpty) return [];
    // Access the update trigger to make this reactive
    _updateTrigger.value;
    return _userLikedItems[currentUserId] ?? [];
  }

  // Load likes data from SharedPreferences
  Future<void> _loadLikesFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final likesDataJson = prefs.getString('user_likes');

      if (likesDataJson != null) {
        final likesData = json.decode(likesDataJson) as Map<String, dynamic>;

        // Convert stored data back to Like objects
        for (final entry in likesData.entries) {
          final userId = entry.key;
          final likesItemsJson = entry.value as List<dynamic>;

          final likeItems = likesItemsJson.map((itemJson) {
            final item = itemJson as Map<String, dynamic>;
            return Like(
              id: item['id'],
              productsId: item['productsId'],
              usersId: item['usersId'],
              created: DateTime.parse(item['created']),
              updated: DateTime.parse(item['updated']),
            );
          }).toList();

          _userLikedItems[userId] = likeItems;
        }

        debugPrint(
            'LikeServiceTemp: Loaded likes data for ${likesData.keys.length} users');
      }
    } catch (e) {
      debugPrint('LikeServiceTemp Error loading likes from storage: $e');
    }
  }

  // Save likes data to SharedPreferences
  Future<void> _saveLikesToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert Like objects to JSON-serializable format
      final likesData = <String, dynamic>{};
      for (final entry in _userLikedItems.entries) {
        final userId = entry.key;
        final likeItems = entry.value;

        likesData[userId] = likeItems
            .map((like) => {
                  'id': like.id,
                  'productsId': like.productsId,
                  'usersId': like.usersId,
                  'created': like.created.toIso8601String(),
                  'updated': like.updated.toIso8601String(),
                })
            .toList();
      }

      await prefs.setString('user_likes', json.encode(likesData));
      debugPrint('LikeServiceTemp: Likes data saved to storage');
    } catch (e) {
      debugPrint('LikeServiceTemp Error saving likes to storage: $e');
    }
  }

  // Initialize likes for user if not exists
  void _ensureUserLikes(String userId) {
    if (!_userLikedItems.containsKey(userId)) {
      _userLikedItems[userId] = <Like>[];
      debugPrint('LikeServiceTemp: Created new likes for user: $userId');
    }
  }

  // Trigger UI update safely
  void _triggerUIUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateTrigger.value++;
    });
  }

  // Add/Toggle like for a product (local storage)
  Future<bool> toggleLike(String productId) async {
    if (currentUserId.isEmpty) {
      debugPrint('LikeServiceTemp: No user logged in');
      Get.snackbar('Error', 'Please login first');
      return false;
    }

    try {
      debugPrint(
          'LikeServiceTemp: Toggling like for user $currentUserId - ProductID: $productId');

      // Ensure user has likes storage
      _ensureUserLikes(currentUserId);
      final userLikedItems = _userLikedItems[currentUserId]!;

      // Check if product is already liked by this user
      final existingLike = userLikedItems.firstWhereOrNull(
        (like) => like.productsId == productId && like.usersId == currentUserId,
      );

      if (existingLike != null) {
        // Unlike - remove from user's local storage
        debugPrint(
            'LikeServiceTemp: Removing like for user $currentUserId, product: $productId');
        userLikedItems.removeWhere((like) =>
            like.id == existingLike.id && like.usersId == currentUserId);

        await _saveLikesToStorage(); // Save to persistent storage
        _triggerUIUpdate(); // Force UI update
        Get.snackbar('Success', 'Removed from favorites');
        return false; // Product is now unliked
      } else {
        // Like - add to user's local storage
        final newLike = Like(
          id: '${currentUserId}_${DateTime.now().millisecondsSinceEpoch}', // User-specific ID
          productsId: productId,
          usersId: currentUserId,
          created: DateTime.now(),
          updated: DateTime.now(),
        );

        userLikedItems.add(newLike);

        await _saveLikesToStorage(); // Save to persistent storage
        _triggerUIUpdate(); // Force UI update
        debugPrint('LikeServiceTemp: Added new like for user $currentUserId');
        Get.snackbar('Success', 'Added to favorites');
        return true; // Product is now liked
      }
    } catch (e) {
      debugPrint('LikeServiceTemp Error toggling like: $e');
      Get.snackbar('Error', 'Failed to update favorites');
      return false;
    }
  }

  // Check if product is liked by current user (reactive)
  bool isLiked(String productId) {
    if (currentUserId.isEmpty) return false;
    // Access the update trigger to make this reactive
    _updateTrigger.value;
    final userLikes = likedItems; // This already filters by current user
    final result = userLikes.any((like) =>
        like.productsId == productId && like.usersId == currentUserId);
    debugPrint(
        'LikeServiceTemp: Checking isLiked for $productId by user $currentUserId: $result');
    return result;
  }

  // Get liked product IDs for current user
  List<String> get likedProductIds {
    if (currentUserId.isEmpty) return [];
    // Access the update trigger to make this reactive
    _updateTrigger.value;
    final userLikes = likedItems; // This already filters by current user
    return userLikes.map((like) => like.productsId).toList();
  }

  // Remove like by product ID for current user
  Future<bool> removeLike(String productId) async {
    if (currentUserId.isEmpty) return false;

    try {
      _ensureUserLikes(currentUserId);
      final userLikedItems = _userLikedItems[currentUserId]!;

      final existingLike = userLikedItems.firstWhereOrNull(
        (like) => like.productsId == productId && like.usersId == currentUserId,
      );

      if (existingLike != null) {
        userLikedItems.removeWhere((like) =>
            like.id == existingLike.id && like.usersId == currentUserId);

        _triggerUIUpdate(); // Force UI update
        await _saveLikesToStorage(); // Save to persistent storage
        Get.snackbar('Success', 'Removed from favorites');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('LikeServiceTemp Error removing like: $e');
      return false;
    }
  }

  // Clear all likes for current user
  Future<bool> clearAllLikes() async {
    if (currentUserId.isEmpty) return false;

    try {
      _ensureUserLikes(currentUserId);
      _userLikedItems[currentUserId]!.clear();

      _triggerUIUpdate(); // Force UI update
      await _saveLikesToStorage(); // Save to persistent storage
      Get.snackbar('Success', 'All favorites cleared');
      return true;
    } catch (e) {
      debugPrint('LikeServiceTemp Error clearing likes: $e');
      return false;
    }
  }

  // Get count of liked items for current user
  int get likedItemCount {
    if (currentUserId.isEmpty) return 0;
    return likedItems.length;
  }

  // Refresh liked items for current user
  Future<void> refreshLikes() async {
    if (currentUserId.isNotEmpty) {
      _ensureUserLikes(currentUserId);
    }
  }

  // Debug: Get all likes data for debugging
  Map<String, dynamic> getDebugInfo() {
    return {
      'currentUserId': currentUserId,
      'totalUsers': _userLikedItems.keys.length,
      'userLikeCounts': _userLikedItems
          .map((userId, items) => MapEntry(userId, items.length)),
      'currentUserLikes': likedItems.length,
    };
  }
}
