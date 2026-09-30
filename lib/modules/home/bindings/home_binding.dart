import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../notification/controllers/notification_controller.dart';
import '../../../data/services/firestore_service.dart';
import '../../../data/services/notification_service.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FirestoreService>(() => FirestoreService());
    Get.lazyPut<NotificationService>(() => NotificationService());
    
    // AuthController is already registered, but we can ensure it's available
    if (!Get.isRegistered<AuthController>()) {
      Get.lazyPut<AuthController>(() => AuthController());
    }
    
    if (!Get.isRegistered<NotificationController>()) {
      Get.lazyPut<NotificationController>(() => NotificationController());
    }
    
    Get.lazyPut<HomeController>(() => HomeController());
  }
}
