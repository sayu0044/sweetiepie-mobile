import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sweetipie/routes/app_pages.dart';
import 'package:sweetipie/theme/app_theme.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag_outlined),
          activeIcon: Icon(Icons.shopping_bag),
          label: 'Shop',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite_border),
          activeIcon: Icon(Icons.favorite),
          label: 'Favorite',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Account',
        ),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            Get.offAllNamed(Routes.home);
            break;
          case 1:
            if (Get.currentRoute != Routes.cart) {
              Get.toNamed(Routes.cart);
            }
            break;
          case 2:
            if (Get.currentRoute != Routes.favorite) {
              Get.toNamed(Routes.favorite);
            }
            break;
          case 3:
            if (Get.currentRoute != Routes.account) {
              Get.toNamed(Routes.account);
            }
            break;
        }
      },
    );
  }
}
