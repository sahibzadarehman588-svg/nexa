import 'package:get/get.dart';
import '../controllers/expiry_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../data/services/firestore_service.dart';

class ExpiryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FirestoreService>(() => FirestoreService());
    
    // AuthController is already registered, but we can ensure it's available
    if (!Get.isRegistered<AuthController>()) {
      Get.lazyPut<AuthController>(() => AuthController());
    }
    
    Get.lazyPut<ExpiryController>(() => ExpiryController());
  }
}
