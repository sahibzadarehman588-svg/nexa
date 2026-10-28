import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Use fenix: true to keep AuthController alive across the app
    // since it's a core controller that manages authentication state
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
  }
}
