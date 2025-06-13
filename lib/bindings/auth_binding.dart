import 'package:get/get.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // AuthService already registered in InitialBinding
    // No additional bindings needed for auth screens
  }
}
