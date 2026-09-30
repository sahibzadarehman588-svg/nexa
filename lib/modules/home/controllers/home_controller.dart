import 'package:get/get.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../notification/controllers/notification_controller.dart';
import '../../../data/services/firestore_service.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/alert_model.dart';
import '../../../core/routes/app_routes.dart';

class HomeController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final FirestoreService _firestoreService = FirestoreService();
  late final NotificationController _notificationController;

  // Reactive state
  final RxString userName = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;

  // Statistics
  final RxInt totalProducts = 0.obs;
  final RxInt expiringSoonProducts = 0.obs;
  final RxInt expiredProducts = 0.obs;
  final RxInt availableProducts = 0.obs;

  // Data
  final RxList<ProductModel> recentProducts = <ProductModel>[].obs;
  final RxList<AlertModel> recentAlerts = <AlertModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
    
    // Initialize notification controller
    if (Get.isRegistered<NotificationController>()) {
      _notificationController = Get.find<NotificationController>();
    } else {
      _notificationController = Get.put(NotificationController());
    }
    
    _loadDashboardData();
  }

  @override
  void onReady() {
    super.onReady();
    // Refresh data when controller is ready
    refreshData();
  }

  void _loadUserData() {
    if (_authController.currentUser.value != null) {
      userName.value = _authController.currentUser.value!.displayName ??
          _authController.currentUser.value!.email.split('@')[0];
    }
  }

  Future<void> _loadDashboardData() async {
    if (_authController.currentUser.value == null) return;

    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';

    try {
      final userId = _authController.currentUser.value!.userId;

      // Load all data in parallel
      final results = await Future.wait([
        _loadProductStatistics(userId),
        _loadRecentProducts(userId),
        _loadRecentAlerts(userId),
      ]);

      // Update statistics
      final stats = results[0] as Map<String, int>;
      totalProducts.value = stats['total'] ?? 0;
      expiringSoonProducts.value = stats['expiringSoon'] ?? 0;
      expiredProducts.value = stats['expired'] ?? 0;
      availableProducts.value = stats['available'] ?? 0;

      // Check and schedule notifications
      await _notificationController.checkAndScheduleNotifications();

    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, int>> _loadProductStatistics(String userId) async {
    try {
      final allProducts = await _firestoreService.getProducts(userId);
      final expiringSoon = await _firestoreService.getExpiringSoonProducts(userId);
      final expired = await _firestoreService.getExpiredProducts(userId);

      return {
        'total': allProducts.length,
        'expiringSoon': expiringSoon.length,
        'expired': expired.length,
        'available': allProducts.length - expired.length,
      };
    } catch (e) {
      throw Exception('Failed to load product statistics: $e');
    }
  }

  Future<void> _loadRecentProducts(String userId) async {
    try {
      final products = await _firestoreService.getProducts(userId);
      // Take first 5 products as recent
      recentProducts.value = products.take(5).toList();
    } catch (e) {
      throw Exception('Failed to load recent products: $e');
    }
  }

  Future<void> _loadRecentAlerts(String userId) async {
    try {
      final alerts = await _firestoreService.getAlerts(userId);
      // Take first 5 alerts as recent
      recentAlerts.value = alerts.take(5).toList();
    } catch (e) {
      throw Exception('Failed to load recent alerts: $e');
    }
  }

  Future<void> refreshData() async {
    await _loadDashboardData();
  }

  void logout() {
    _authController.logout();
  }

  void navigateToScanner() async {
    final result = await Get.toNamed(AppRoutes.scanner);
    if (result == true) {
      // Refresh data when returning from scanner with success
      refreshData();
    }
  }

  void navigateToProducts() {
    Get.toNamed(AppRoutes.products)?.then((result) {
      if (result == true) {
        refreshData();
      }
    });
  }

  void navigateToInventory() {
    Get.toNamed(AppRoutes.inventory)?.then((result) {
      if (result == true) {
        refreshData();
      }
    });
  }

  void navigateToAIChat() {
    // TODO: Navigate to AI chat in Phase 10
    Get.snackbar(
      'Coming Soon',
      'AI Chat Assistant - Coming in Phase 10',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void navigateToDocumentAI() {
    // TODO: Navigate to document AI in Phase 8
    Get.snackbar(
      'Coming Soon',
      'Document AI - Coming in Phase 8',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void navigateToReceiptScanner() {
    // TODO: Navigate to receipt scanner in Phase 9
    Get.snackbar(
      'Coming Soon',
      'Receipt Scanner - Coming in Phase 9',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
