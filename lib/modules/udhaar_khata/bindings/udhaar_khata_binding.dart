import 'package:get/get.dart';
import '../controllers/udhaar_khata_controller.dart';

class UdhaarKhataBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UdhaarKhataController>(() => UdhaarKhataController());
  }
}
