import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sweetipie/services/user_settings_service.dart';
import 'package:sweetipie/services/auth_service.dart';
import 'package:sweetipie/screens/account/edit_profile_screen.dart';
import 'package:sweetipie/theme/app_theme.dart';
import 'package:sweetipie/routes/app_pages.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final UserSettingsService settingsService = Get.find<UserSettingsService>();
    final AuthService authService = Get.find<AuthService>();

    return Scaffold(
      backgroundColor: Colors.pink[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Obx(() {
                      final user = authService.currentUser.value;
                      final avatarUrl = settingsService.getAvatarUrl();
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundColor: AppTheme.primaryColor,
                          backgroundImage: avatarUrl != null
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: avatarUrl == null
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                        title: Text(
                          user?.data['name'] ?? 'User',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(user?.data['email'] ?? ''),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Get.to(() => const EditProfileScreen());
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Account Settings
            _buildSectionTitle('Account'),
            Card(
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.edit,
                    title: 'Edit Profile',
                    onTap: () {
                      Get.to(() => const EditProfileScreen());
                    },
                  ),
                  const Divider(height: 1),
                  _buildMenuItem(
                    icon: Icons.lock,
                    title: 'Change Password',
                    onTap: () {
                      _showChangePasswordDialog(context, settingsService);
                    },
                  ),
                  const Divider(height: 1),
                  _buildMenuItem(
                    icon: Icons.security,
                    title: 'Privacy & Security',
                    onTap: () {
                      Get.snackbar(
                          'Info', 'Privacy & Security settings coming soon');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // App Settings
            _buildSectionTitle('App Settings'),
            Card(
              child: Column(
                children: [
                  Obx(() {
                    final settings = settingsService.currentSettings.value;
                    return SwitchListTile(
                      secondary: const Icon(Icons.notifications),
                      title: const Text('Push Notifications'),
                      subtitle:
                          const Text('Receive order updates and promotions'),
                      value: settings?.notifications ?? true,
                      onChanged: (value) {
                        settingsService.updatePreferences(notifications: value);
                      },
                    );
                  }),
                  const Divider(height: 1),
                  _buildMenuItem(
                    icon: Icons.palette,
                    title: 'Theme',
                    subtitle: 'Light',
                    onTap: () {
                      _showThemeDialog(context, settingsService);
                    },
                  ),
                  const Divider(height: 1),
                  _buildMenuItem(
                    icon: Icons.language,
                    title: 'Language',
                    subtitle: 'English',
                    onTap: () {
                      Get.snackbar('Info', 'Language settings coming soon');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Support
            _buildSectionTitle('Support'),
            Card(
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.help,
                    title: 'Help Center',
                    onTap: () {
                      Get.snackbar('Info', 'Help Center coming soon');
                    },
                  ),
                  const Divider(height: 1),
                  _buildMenuItem(
                    icon: Icons.feedback,
                    title: 'Send Feedback',
                    onTap: () {
                      Get.snackbar('Info', 'Feedback form coming soon');
                    },
                  ),
                  const Divider(height: 1),
                  _buildMenuItem(
                    icon: Icons.info,
                    title: 'About',
                    onTap: () {
                      _showAboutDialog(context);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Danger Zone
            _buildSectionTitle('Account'),
            Card(
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.logout,
                    title: 'Logout',
                    titleColor: Colors.orange,
                    iconColor: Colors.orange,
                    onTap: () {
                      _showLogoutDialog(context, authService);
                    },
                  ),
                  const Divider(height: 1),
                  _buildMenuItem(
                    icon: Icons.delete_forever,
                    title: 'Delete Account',
                    titleColor: Colors.red,
                    iconColor: Colors.red,
                    onTap: () {
                      _showDeleteAccountDialog(context);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? titleColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(color: titleColor),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showChangePasswordDialog(
      BuildContext context, UserSettingsService settingsService) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: oldPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Current password is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value != newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          Obx(() => ElevatedButton(
                onPressed: settingsService.isLoading.value
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          final success = await settingsService.changePassword(
                            oldPasswordController.text,
                            newPasswordController.text,
                          );
                          if (success) {
                            Get.back();
                          }
                        }
                      },
                child: settingsService.isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Change'),
              )),
        ],
      ),
    );
  }

  void _showThemeDialog(
      BuildContext context, UserSettingsService settingsService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text('Light'),
              onTap: () {
                settingsService.updatePreferences(theme: 'light');
                Get.back();
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Dark'),
              onTap: () {
                settingsService.updatePreferences(theme: 'dark');
                Get.back();
                Get.snackbar('Info', 'Dark theme coming soon');
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_mode),
              title: const Text('System'),
              onTap: () {
                settingsService.updatePreferences(theme: 'system');
                Get.back();
                Get.snackbar('Info', 'System theme coming soon');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'SweetiePie',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.cake, size: 48),
      children: [
        const Text(
            'A delicious cake ordering app built with Flutter and PocketBase.'),
        const SizedBox(height: 16),
        const Text('© 2024 SweetiePie. All rights reserved.'),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              authService.logout();
              Get.offAllNamed(Routes.LOGIN);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.snackbar('Info', 'Account deletion feature coming soon');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
