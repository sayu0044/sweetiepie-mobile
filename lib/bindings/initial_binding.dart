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
    print('InitialBinding: Registering core services...');

    // Register core services
    Get.put(AuthService(), permanent: true);
    print('InitialBinding: AuthService registered');

    Get.put(DatabaseService(), permanent: true);
    print('InitialBinding: DatabaseService registered');

    // Register cart and like services (persistent with PocketBase)
    Get.put(CartService(), permanent: true);
    print('InitialBinding: CartService registered');

    Get.put(LikeService(), permanent: true);
    print('InitialBinding: LikeService registered');

    // Register order service
    Get.put(OrderService(), permanent: true);
    print('InitialBinding: OrderService registered');

    // Register user settings service
    Get.put(UserSettingsService(), permanent: true);
    print('InitialBinding: UserSettingsService registered');

    print('InitialBinding: All services registered successfully');
  }
}
