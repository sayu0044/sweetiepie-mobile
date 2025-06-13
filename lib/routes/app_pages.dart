import 'package:get/get.dart';
import 'package:sweetipie/bindings/auth_binding.dart';
import 'package:sweetipie/bindings/home_binding.dart';
import 'package:sweetipie/screens/account/account_screen.dart';
import 'package:sweetipie/screens/auth/login_screen.dart';
import 'package:sweetipie/screens/auth/register_screen.dart';
import 'package:sweetipie/screens/cart/cart_screen.dart';
import 'package:sweetipie/screens/checkout/checkout_screen.dart';
import 'package:sweetipie/screens/debug/debug_screen.dart';
import 'package:sweetipie/screens/favorite/favorite_screen.dart';
import 'package:sweetipie/screens/home/home_screen.dart';
import 'package:sweetipie/screens/order/order_payment_screen.dart';
import 'package:sweetipie/screens/order/order_success_screen.dart';
import 'package:sweetipie/screens/splash/splash_screen.dart';
import 'package:sweetipie/screens/account/settings_screen.dart';
import 'package:sweetipie/screens/account/edit_profile_screen.dart';
import 'package:sweetipie/screens/debug/debug_auth_screen.dart';

part 'app_routes.dart';

class AppPages {
  static const initial = Routes.splash;

  static final routes = [
    GetPage(
      name: Routes.splash,
      page: () => const SplashScreen(),
    ),
    GetPage(
      name: Routes.login,
      page: () => const LoginScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.register,
      page: () => const RegisterScreen(),
    ),
    GetPage(
      name: Routes.home,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
    ),
    GetPage(name: Routes.favorite, page: () => const FavoriteScreen()),
    GetPage(name: Routes.cart, page: () => const CartScreen()),
    GetPage(name: Routes.checkout, page: () => const CheckoutScreen()),
    GetPage(name: Routes.orderPayment, page: () => const OrderPaymentScreen()),
    GetPage(name: Routes.orderSuccess, page: () => const OrderSuccessScreen()),
    GetPage(name: Routes.account, page: () => const AccountScreen()),
    GetPage(name: Routes.settings, page: () => const SettingsScreen()),
    GetPage(name: Routes.editProfile, page: () => const EditProfileScreen()),
    GetPage(name: Routes.debug, page: () => const DebugScreen()),
    GetPage(name: Routes.debugAuth, page: () => const DebugAuthScreen()),
  ];
}
