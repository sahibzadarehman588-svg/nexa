import 'package:get/get.dart';
import '../controllers/receipt_scanner_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../data/services/ocr_service.dart';
import '../../../data/services/ai_service.dart';
import '../../../data/services/storage_service.dart';

class ReceiptScannerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OCRService>(() => OCRService());
    Get.lazyPut<AIService>(() => AIService());
    Get.lazyPut<StorageService>(() => StorageService());
    
    // AuthController is already registered, but we can ensure it's available
    if (!Get.isRegistered<AuthController>()) {
      Get.lazyPut<AuthController>(() => AuthController());
    }
    
    Get.lazyPut<ReceiptScannerController>(() => ReceiptScannerController());
  }
}
