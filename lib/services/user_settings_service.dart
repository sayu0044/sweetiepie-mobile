import 'package:pocketbase/pocketbase.dart';
import 'package:get/get.dart';
import 'package:sweetipie/models/user_settings.dart';
import 'package:sweetipie/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class UserSettingsService extends GetxController {
  final PocketBase pb = PocketBase('http://127.0.0.1:8090');
  final AuthService _authService = Get.find<AuthService>();

  final Rx<UserSettings?> currentSettings = Rx<UserSettings?>(null);
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    debugPrint('UserSettingsService: Initializing...');

    // Sync auth from AuthService
    _syncAuthFromAuthService();

    // Load user settings when service initializes
    if (_authService.isAuthenticated) {
      debugPrint(
          'UserSettingsService: User is authenticated, fetching settings');
      fetchUserSettings();
    } else {
      debugPrint(
          'UserSettingsService: User not authenticated, skipping settings fetch');
    }

    // Listen to auth changes
    _authService.currentUser.listen((user) {
      if (user != null) {
        debugPrint('UserSettingsService: User logged in: ${user.id}');
        _syncAuthFromAuthService();
        fetchUserSettings();
      } else {
        debugPrint('UserSettingsService: User logged out, clearing settings');
        currentSettings.value = null;
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
        debugPrint('UserSettingsService: Auth synced from AuthService');
        final tokenPreview = authToken.length > 20
            ? '${authToken.substring(0, 20)}...'
            : authToken;
        debugPrint('UserSettingsService: Token: $tokenPreview');
        debugPrint('UserSettingsService: User ID: ${authModel?.id}');
      } else {
        debugPrint('UserSettingsService: No auth to sync');
      }
    } catch (e) {
      debugPrint('UserSettingsService: Error syncing auth: $e');
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
        'UserSettingsService: Auth check - hasUser: $hasUser, hasValidToken: $hasValidToken, authServiceAuth: $authServiceAuthenticated');

    return hasUser && hasValidToken && authServiceAuthenticated;
  }

  // Fetch user settings from PocketBase users collection
  Future<void> fetchUserSettings() async {
    if (!_isUserAuthenticated) {
      debugPrint(
          'UserSettingsService: Cannot fetch settings - user not authenticated');
      return;
    }

    try {
      isLoading.value = true;
      debugPrint(
          'UserSettingsService: Fetching user settings for user: $currentUserId');

      // Ensure auth is synced before making request
      _syncAuthFromAuthService();

      // Get user record from users collection
      final record = await pb.collection('users').getOne(currentUserId);

      // Convert to UserSettings model
      final settingsData = {
        'id': record.id,
        'name': record.data['name'] ?? '',
        'email': record.data['email'] ?? '',
        'phone': record.data['phone'],
        'address': record.data['address'],
        'avatar': record.data['avatar'],
        'theme': record.data['theme'],
        'notifications': record.data['notifications'] ?? true,
        'date_of_birth': record.data['date_of_birth'],
        'gender': record.data['gender'],
        'created': record.get<String>('created'),
        'updated': record.get<String>('updated'),
      };

      currentSettings.value = UserSettings.fromJson(settingsData);
      debugPrint('UserSettingsService: User settings loaded successfully');
    } catch (e) {
      debugPrint('UserSettingsService: Error fetching user settings: $e');

      // Handle specific authentication errors
      if (e.toString().contains('401') || e.toString().contains('403')) {
        debugPrint(
            'UserSettingsService: Authentication error, refreshing auth...');
        await _authService.refreshAuth();
      } else {
        Get.snackbar('Error', 'Failed to load user settings');
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? address,
    DateTime? dateOfBirth,
    String? gender,
  }) async {
    debugPrint('UserSettingsService: updateProfile called');

    if (!_isUserAuthenticated) {
      debugPrint(
          'UserSettingsService: User not authenticated for updateProfile');
      Get.snackbar('Error', 'Please login first to update profile');
      return false;
    }

    try {
      isLoading.value = true;
      debugPrint(
          'UserSettingsService: Updating user profile for user: $currentUserId');

      // Ensure auth is synced before making request
      _syncAuthFromAuthService();

      final updateData = <String, dynamic>{};

      if (name != null) updateData['name'] = name;
      if (phone != null) updateData['phone'] = phone;
      if (address != null) updateData['address'] = address;
      if (dateOfBirth != null) {
        updateData['date_of_birth'] =
            '${dateOfBirth.year}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}';
      }
      if (gender != null) updateData['gender'] = gender;

      debugPrint('UserSettingsService: Update data: $updateData');

      final record = await pb.collection('users').update(
            currentUserId,
            body: updateData,
          );

      debugPrint('UserSettingsService: Profile updated successfully');

      // Update AuthService current user
      _authService.currentUser.value = record;

      // Refresh settings
      await fetchUserSettings();

      Get.snackbar('Success', 'Profile updated successfully');
      return true;
    } catch (e) {
      debugPrint('UserSettingsService: Error updating profile: $e');

      // Handle specific error types
      if (e.toString().contains('401') || e.toString().contains('403')) {
        debugPrint(
            'UserSettingsService: Authentication error during updateProfile');
        Get.snackbar('Error', 'Authentication failed. Please login again.');
        await _authService.refreshAuth();
      } else if (e.toString().contains('400')) {
        debugPrint('UserSettingsService: 400 Error - likely validation issue');
        Get.snackbar(
            'Error', 'Failed to update profile. Please check your data.');
      } else {
        Get.snackbar('Error', 'Failed to update profile. Please try again.');
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Update user preferences (theme, notifications)
  Future<bool> updatePreferences({
    String? theme,
    bool? notifications,
  }) async {
    debugPrint('UserSettingsService: updatePreferences called');

    if (!_isUserAuthenticated) {
      debugPrint(
          'UserSettingsService: User not authenticated for updatePreferences');
      Get.snackbar('Error', 'Please login first to update preferences');
      return false;
    }

    try {
      isLoading.value = true;
      debugPrint(
          'UserSettingsService: Updating user preferences for user: $currentUserId');

      // Ensure auth is synced before making request
      _syncAuthFromAuthService();

      final updateData = <String, dynamic>{};

      if (theme != null) updateData['theme'] = theme;
      if (notifications != null) updateData['notifications'] = notifications;

      debugPrint('UserSettingsService: Preferences data: $updateData');

      await pb.collection('users').update(
            currentUserId,
            body: updateData,
          );

      debugPrint('UserSettingsService: Preferences updated successfully');

      // Refresh settings
      await fetchUserSettings();

      Get.snackbar('Success', 'Preferences updated successfully');
      return true;
    } catch (e) {
      debugPrint('UserSettingsService: Error updating preferences: $e');

      // Handle specific error types
      if (e.toString().contains('401') || e.toString().contains('403')) {
        debugPrint(
            'UserSettingsService: Authentication error during updatePreferences');
        Get.snackbar('Error', 'Authentication failed. Please login again.');
        await _authService.refreshAuth();
      } else {
        Get.snackbar(
            'Error', 'Failed to update preferences. Please try again.');
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Upload and update avatar
  Future<bool> updateAvatar(String filePath) async {
    debugPrint('UserSettingsService: updateAvatar called');

    if (!_isUserAuthenticated) {
      debugPrint(
          'UserSettingsService: User not authenticated for updateAvatar');
      Get.snackbar('Error', 'Please login first to update avatar');
      return false;
    }

    try {
      isLoading.value = true;
      debugPrint(
          'UserSettingsService: Updating user avatar for user: $currentUserId');

      // Ensure auth is synced before making request
      _syncAuthFromAuthService();

      // Create FormData for file upload
      final formData = <String, dynamic>{
        'avatar': http.MultipartFile.fromPath('avatar', filePath),
      };

      final record = await pb.collection('users').update(
            currentUserId,
            body: formData,
          );

      debugPrint('UserSettingsService: Avatar updated successfully');

      // Update AuthService current user
      _authService.currentUser.value = record;

      // Refresh settings
      await fetchUserSettings();

      Get.snackbar('Success', 'Avatar updated successfully');
      return true;
    } catch (e) {
      debugPrint('UserSettingsService: Error updating avatar: $e');

      // Handle specific error types
      if (e.toString().contains('401') || e.toString().contains('403')) {
        debugPrint(
            'UserSettingsService: Authentication error during updateAvatar');
        Get.snackbar('Error', 'Authentication failed. Please login again.');
        await _authService.refreshAuth();
      } else {
        Get.snackbar('Error', 'Failed to update avatar. Please try again.');
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Get avatar URL
  String? getAvatarUrl() {
    final user = _authService.currentUser.value;
    if (user?.data['avatar'] != null && user!.data['avatar'].isNotEmpty) {
      return '${pb.baseURL}/api/files/${user.collectionId}/${user.id}/${user.data['avatar']}';
    }
    return null;
  }

  // Change password
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    debugPrint('UserSettingsService: changePassword called');

    if (!_isUserAuthenticated) {
      debugPrint(
          'UserSettingsService: User not authenticated for changePassword');
      Get.snackbar('Error', 'Please login first to change password');
      return false;
    }

    try {
      isLoading.value = true;
      debugPrint(
          'UserSettingsService: Changing password for user: $currentUserId');

      // Ensure auth is synced before making request
      _syncAuthFromAuthService();

      final updateData = {
        'oldPassword': oldPassword,
        'password': newPassword,
        'passwordConfirm': newPassword,
      };

      debugPrint('UserSettingsService: Attempting password change...');

      await pb.collection('users').update(
            currentUserId,
            body: updateData,
          );

      debugPrint('UserSettingsService: Password changed successfully');
      Get.snackbar('Success', 'Password changed successfully');
      return true;
    } catch (e) {
      debugPrint('UserSettingsService: Error changing password: $e');

      // Handle specific error types
      if (e.toString().contains('401') || e.toString().contains('403')) {
        debugPrint(
            'UserSettingsService: Authentication error during changePassword');
        Get.snackbar('Error', 'Authentication failed. Please login again.');
        await _authService.refreshAuth();
      } else if (e.toString().contains('Old password is incorrect') ||
          e.toString().contains('old password')) {
        debugPrint('UserSettingsService: Old password incorrect');
        Get.snackbar('Error', 'Old password is incorrect');
      } else if (e.toString().contains('400')) {
        debugPrint('UserSettingsService: Password validation error');
        Get.snackbar('Error',
            'Password validation failed. Please check your password requirements.');
      } else {
        Get.snackbar('Error', 'Failed to change password. Please try again.');
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Refresh user settings
  Future<void> refreshSettings() async {
    await fetchUserSettings();
  }
}
