import 'package:get/get.dart';
import 'package:sweetipie/services/auth_service.dart';

class HomeController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  RxString userName = 'Guest'.obs;
  RxString userAvatar = ''.obs;

  static const String guestAvatar = 'assets/images/guest.png';

  @override
  void onInit() {
    super.onInit();
    updateUserInfo();
    // Listen to user changes
    ever(_authService.currentUser, (_) => updateUserInfo());
  }

  void updateUserInfo() {
    final user = _authService.currentUser.value;
    if (user != null) {
      userName.value = user.data['name'] ?? 'User';

      // Check if user has avatar
      if (user.data['avatar'] != null && user.data['avatar'].isNotEmpty) {
        final avatarUrl =
            '${_authService.pb.baseURL}/api/files/${user.collectionId}/${user.id}/${user.data['avatar']}';
        userAvatar.value = avatarUrl;
      } else {
        userAvatar.value = guestAvatar;
      }
    } else {
      userName.value = 'Guest';
      userAvatar.value = guestAvatar;
    }
  }
}
