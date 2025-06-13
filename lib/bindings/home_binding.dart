import 'package:get/get.dart';
import 'package:sweetipie/controllers/home_controller.dart';
import 'package:sweetipie/controllers/cart_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Register controllers for home screen
    Get.put(HomeController());
    Get.put(CartController());

    // Services already registered in InitialBinding
  }
}
