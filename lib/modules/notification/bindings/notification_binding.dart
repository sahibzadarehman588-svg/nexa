import 'package:get/get.dart';
import '../controllers/notification_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/firestore_service.dart';

class NotificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NotificationService>(() => NotificationService());
    Get.lazyPut<FirestoreService>(() => FirestoreService());
    
    // AuthController is already registered, but we can ensure it's available
    if (!Get.isRegistered<AuthController>()) {
      Get.lazyPut<AuthController>(() => AuthController());
    }
    
    Get.lazyPut<NotificationController>(() => NotificationController());
  }
}
