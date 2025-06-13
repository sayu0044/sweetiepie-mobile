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
  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: Routes.SPLASH,
      page: () => const SplashScreen(),
    ),
    GetPage(
      name: Routes.LOGIN,
      page: () => const LoginScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.REGISTER,
      page: () => const RegisterScreen(),
    ),
    GetPage(
      name: Routes.HOME,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
    ),
    GetPage(name: Routes.FAVORITE, page: () => const FavoriteScreen()),
    GetPage(name: Routes.CART, page: () => const CartScreen()),
    GetPage(name: Routes.CHECKOUT, page: () => const CheckoutScreen()),
    GetPage(name: Routes.ORDER_PAYMENT, page: () => const OrderPaymentScreen()),
    GetPage(name: Routes.ORDER_SUCCESS, page: () => const OrderSuccessScreen()),
    GetPage(name: Routes.ACCOUNT, page: () => const AccountScreen()),
    GetPage(name: Routes.SETTINGS, page: () => const SettingsScreen()),
    GetPage(name: Routes.EDIT_PROFILE, page: () => const EditProfileScreen()),
    GetPage(name: Routes.DEBUG, page: () => const DebugScreen()),
    GetPage(name: Routes.DEBUG_AUTH, page: () => const DebugAuthScreen()),
  ];
}
