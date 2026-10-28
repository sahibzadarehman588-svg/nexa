import 'package:get/get.dart';
import '../controllers/products_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../data/services/firestore_service.dart';
import '../../../data/services/storage_service.dart';

class ProductsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FirestoreService>(() => FirestoreService());
    Get.lazyPut<StorageService>(() => StorageService());

    // AuthController is already registered, but we can ensure it's available
    if (!Get.isRegistered<AuthController>()) {
      Get.lazyPut<AuthController>(() => AuthController());
    }

    // Use Get.lazyPut with fenix: true to keep ProductsController alive
    // across navigation between Products, Add Product, and Scanner screens
    // fenix: true allows the controller to be recreated when needed but keeps it in memory
    Get.lazyPut<ProductsController>(() => ProductsController(), fenix: true);
  }
}
