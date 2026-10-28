import 'package:get/get.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../data/services/firestore_service.dart';
import '../../../data/models/product_model.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../core/routes/app_routes.dart';

class ExpiryController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final FirestoreService _firestoreService = FirestoreService();

  // Reactive state
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;

  // Products data
  final RxList<ProductModel> expiredProducts = <ProductModel>[].obs;
  final RxList<ProductModel> expiringSoonProducts = <ProductModel>[].obs;
  final RxList<ProductModel> safeProducts = <ProductModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadExpiryData();
  }

  Future<void> _loadExpiryData() async {
    if (_authController.currentUser.value == null) return;

    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';

    try {
      final userId = _authController.currentUser.value!.userId;
      
      // Load all products
      final allProducts = await _firestoreService.getProducts(userId);
      
      // Update statuses
      final updatedProducts = allProducts.map((p) => ProductModel.updateStatus(p)).toList();
      
      // Categorize by status
      expiredProducts.value = updatedProducts
          .where((p) => p.status == FirebaseConstants.statusExpired)
          .toList();
      
      expiringSoonProducts.value = updatedProducts
          .where((p) => p.status == FirebaseConstants.statusExpiringSoon)
          .toList();
      
      safeProducts.value = updatedProducts
          .where((p) => p.status == FirebaseConstants.statusSafe)
          .toList();
      
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshData() async {
    await _loadExpiryData();
  }

  void navigateToProductDetail(ProductModel product) {
    // Navigate to edit screen
    Get.toNamed(AppRoutes.editProduct, arguments: product)?.then((result) {
      if (result == true) {
        refreshData();
      }
    });
  }
}
