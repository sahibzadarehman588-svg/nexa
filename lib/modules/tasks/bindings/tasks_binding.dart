import 'package:get/get.dart';
import '../controllers/tasks_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../data/services/firestore_service.dart';

class TasksBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FirestoreService>(() => FirestoreService());

    // AuthController is already registered, but we can ensure it's available
    if (!Get.isRegistered<AuthController>()) {
      Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
    }

    // Use Get.lazyPut with fenix: true to keep TasksController alive
    // across navigation between Tasks, Add Task, and Edit Task screens
    Get.lazyPut<TasksController>(() => TasksController(), fenix: true);
  }
}
