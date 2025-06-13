import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sweetipie/services/auth_service.dart';
import 'package:sweetipie/services/database_service.dart';
import 'package:sweetipie/services/cart_service.dart';
import 'package:sweetipie/services/like_service.dart';
import 'package:sweetipie/services/order_service.dart';
import 'package:sweetipie/services/user_settings_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    debugPrint('InitialBinding: Registering core services...');

    // Register core services
    Get.put(AuthService(), permanent: true);
    debugPrint('InitialBinding: AuthService registered');

    Get.put(DatabaseService(), permanent: true);
    debugPrint('InitialBinding: DatabaseService registered');

    // Register cart and like services (persistent with PocketBase)
    Get.put(CartService(), permanent: true);
    debugPrint('InitialBinding: CartService registered');

    Get.put(LikeService(), permanent: true);
    debugPrint('InitialBinding: LikeService registered');

    // Register order service
    Get.put(OrderService(), permanent: true);
    debugPrint('InitialBinding: OrderService registered');

    // Register user settings service
    Get.put(UserSettingsService(), permanent: true);
    debugPrint('InitialBinding: UserSettingsService registered');

    debugPrint('InitialBinding: All services registered successfully');
  }
}
