import 'package:get/get.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../data/services/firestore_service.dart';
import '../../../data/models/product_model.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../core/routes/app_routes.dart';

class InventoryController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final FirestoreService _firestoreService = FirestoreService();

  // Reactive state
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;

  // Products data
  final RxList<ProductModel> allProducts = <ProductModel>[].obs;

  // Statistics
  final RxInt totalProducts = 0.obs;
  final RxInt expiringSoonProducts = 0.obs;
  final RxInt expiredProducts = 0.obs;
  final RxInt availableProducts = 0.obs;
  final RxInt lowStockProducts = 0.obs;
  final RxInt totalQuantity = 0.obs;

  // Category breakdown
  final RxMap<String, int> categoryBreakdown = <String, int>{}.obs;

  // Expiry timeline data
  final RxMap<String, int> expiryTimeline = <String, int>{}.obs;

  // Inventory health
  final RxString inventoryHealth = 'Good'.obs;
  final RxDouble healthScore = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    _loadInventoryData();
  }

  Future<void> _loadInventoryData() async {
    if (_authController.currentUser.value == null) return;

    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';

    try {
      final userId = _authController.currentUser.value!.userId;
      final products = await _firestoreService.getProducts(userId);
      
      allProducts.value = products;
      _calculateStatistics();
      _calculateCategoryBreakdown();
      _calculateExpiryTimeline();
      _calculateInventoryHealth();
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  void _calculateStatistics() {
    totalProducts.value = allProducts.length;
    expiringSoonProducts.value = allProducts
        .where((p) => p.status == FirebaseConstants.statusExpiringSoon)
        .length;
    expiredProducts.value = allProducts
        .where((p) => p.status == FirebaseConstants.statusExpired)
        .length;
    availableProducts.value = allProducts
        .where((p) => p.status == FirebaseConstants.statusSafe)
        .length;
    lowStockProducts.value = allProducts
        .where((p) => p.quantity < 5)
        .length;
    totalQuantity.value = allProducts.fold(0, (sum, p) => sum + p.quantity);
  }

  void _calculateCategoryBreakdown() {
    final breakdown = <String, int>{};
    
    for (final product in allProducts) {
      final category = product.category ?? 'Uncategorized';
      breakdown[category] = (breakdown[category] ?? 0) + 1;
    }
    
    categoryBreakdown.value = breakdown;
  }

  void _calculateExpiryTimeline() {
    final timeline = <String, int>{
      '0-7 days': 0,
      '8-14 days': 0,
      '15-30 days': 0,
      '31-60 days': 0,
      '60+ days': 0,
    };
    
    for (final product in allProducts) {
      final remainingDays = product.remainingDays;
      
      if (remainingDays <= 7) {
        timeline['0-7 days'] = (timeline['0-7 days'] ?? 0) + 1;
      } else if (remainingDays <= 14) {
        timeline['8-14 days'] = (timeline['8-14 days'] ?? 0) + 1;
      } else if (remainingDays <= 30) {
        timeline['15-30 days'] = (timeline['15-30 days'] ?? 0) + 1;
      } else if (remainingDays <= 60) {
        timeline['31-60 days'] = (timeline['31-60 days'] ?? 0) + 1;
      } else {
        timeline['60+ days'] = (timeline['60+ days'] ?? 0) + 1;
      }
    }
    
    expiryTimeline.value = timeline;
  }

  void _calculateInventoryHealth() {
    if (allProducts.isEmpty) {
      inventoryHealth.value = 'No Data';
      healthScore.value = 0.0;
      return;
    }

    final expiredRatio = expiredProducts.value / totalProducts.value;
    final expiringSoonRatio = expiringSoonProducts.value / totalProducts.value;
    
    // Calculate health score (0-100)
    double score = 100 - (expiredRatio * 50) - (expiringSoonRatio * 30);
    score = score.clamp(0.0, 100.0);
    
    healthScore.value = score;
    
    // Determine health status
    if (score >= 80) {
      inventoryHealth.value = 'Excellent';
    } else if (score >= 60) {
      inventoryHealth.value = 'Good';
    } else if (score >= 40) {
      inventoryHealth.value = 'Fair';
    } else if (score >= 20) {
      inventoryHealth.value = 'Poor';
    } else {
      inventoryHealth.value = 'Critical';
    }
  }

  List<ProductModel> getExpiringSoonProducts() {
    return allProducts
        .where((p) => p.status == FirebaseConstants.statusExpiringSoon)
        .toList()
      ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
  }

  List<ProductModel> getExpiredProducts() {
    return allProducts
        .where((p) => p.status == FirebaseConstants.statusExpired)
        .toList()
      ..sort((a, b) => b.expiryDate.compareTo(a.expiryDate));
  }

  Future<void> refreshInventory() async {
    await _loadInventoryData();
  }

  void navigateToProducts() {
    Get.toNamed(AppRoutes.products)?.then((result) {
      if (result == true) {
        refreshInventory();
      }
    });
  }

  void navigateToScanner() {
    Get.toNamed(AppRoutes.scanner)?.then((result) {
      if (result == true) {
        refreshInventory();
      }
    });
  }

  void navigateToExpiry() {
    Get.toNamed(AppRoutes.expiry)?.then((result) {
      if (result == true) {
        refreshInventory();
      }
    });
  }
}
