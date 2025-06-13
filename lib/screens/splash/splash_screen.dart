import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sweetipie/routes/app_pages.dart';
import 'package:sweetipie/services/auth_service.dart';
import 'package:sweetipie/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Wait a bit for splash effect
    await Future.delayed(const Duration(seconds: 2));

    try {
      final AuthService authService = Get.find<AuthService>();

      debugPrint('SplashScreen: Checking auth status...');
      debugPrint(
          'SplashScreen: Is authenticated: ${authService.isAuthenticated}');
      debugPrint(
          'SplashScreen: Current user: ${authService.currentUser.value?.id}');
      debugPrint(
          'SplashScreen: Current user email: ${authService.currentUser.value?.data['email']}');

      // Check if user is already authenticated
      if (authService.isAuthenticated) {
        debugPrint('SplashScreen: User is authenticated, navigating to HOME');
        // Navigate to home if authenticated
        Get.offAllNamed(Routes.home);
      } else {
        debugPrint(
            'SplashScreen: User is not authenticated, navigating to LOGIN');
        // Navigate to login if not authenticated
        Get.offAllNamed(Routes.login);
      }
    } catch (e) {
      // If there's an error, go to login
      debugPrint('SplashScreen: Error checking auth status: $e');
      Get.offAllNamed(Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(60),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.restaurant,
                size: 60,
                color: Color(0xFFFF6B6B),
              ),
            ),
            const SizedBox(height: 24),
            // App Name
            const Text(
              'SweetiePie',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            // Tagline
            const Text(
              'Best Bakery & Drinks',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 48),
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
