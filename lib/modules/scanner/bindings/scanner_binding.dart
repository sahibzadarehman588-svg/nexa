import 'package:get/get.dart';
import '../controllers/scanner_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../data/services/ocr_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/firestore_service.dart';

class ScannerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OCRService>(() => OCRService());
    Get.lazyPut<StorageService>(() => StorageService());
    Get.lazyPut<FirestoreService>(() => FirestoreService());
    
    // AuthController is already registered, but we can ensure it's available
    if (!Get.isRegistered<AuthController>()) {
      Get.lazyPut<AuthController>(() => AuthController());
    }
    
    Get.lazyPut<ScannerController>(() => ScannerController());
  }
}
