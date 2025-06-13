import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sweetipie/routes/app_pages.dart';
import 'package:sweetipie/theme/app_theme.dart';
import 'package:sweetipie/services/auth_service.dart';
import 'package:sweetipie/controllers/home_controller.dart';
import 'package:sweetipie/screens/account/settings_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  String? _getAvatarUrl(dynamic user) {
    if (user?.data['avatar'] != null && user.data['avatar'].isNotEmpty) {
      final authService = Get.find<AuthService>();
      return '${authService.pb.baseURL}/api/files/${user.collectionId}/${user.id}/${user.data['avatar']}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();

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
          'Account',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Obx(() {
              final user = authService.currentUser.value;
              final avatarUrl = _getAvatarUrl(user);
              return Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.primaryColor,
                    child: avatarUrl != null
                        ? ClipOval(
                            child: Image.network(
                              avatarUrl,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  HomeController.guestAvatar,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                          )
                        : SizedBox(
                            width: 100,
                            height: 100,
                            child: Image.asset(
                              HomeController.guestAvatar,
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.data['name'] ?? 'User',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  Text(
                    user?.data['email'] ?? '',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.greyColor,
                        ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 32),
            _buildMenuItem(
              context,
              icon: Icons.shopping_bag_outlined,
              title: 'My Orders',
              onTap: () {},
            ),
            _buildMenuItem(
              context,
              icon: Icons.location_on_outlined,
              title: 'Delivery Addresses',
              onTap: () {},
            ),
            _buildMenuItem(
              context,
              icon: Icons.payment_outlined,
              title: 'Payment Methods',
              onTap: () {},
            ),
            _buildMenuItem(
              context,
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              onTap: () {},
            ),
            _buildMenuItem(
              context,
              icon: Icons.settings_outlined,
              title: 'Settings',
              onTap: () {
                Get.to(() => const SettingsScreen());
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () {},
            ),
            _buildMenuItem(
              context,
              icon: Icons.logout,
              title: 'Logout',
              onTap: () {
                authService.logout();
                Get.offAllNamed(Routes.login);
              },
              isDestructive: true,
            ),
            const SizedBox(height: 20),

            // Debug Button (development only)
            _buildMenuItem(
              context,
              icon: Icons.bug_report,
              title: 'Debug Auth & DB',
              onTap: () => Get.toNamed('/debug-auth'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : null,
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: isDestructive ? Colors.red : null,
            ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
