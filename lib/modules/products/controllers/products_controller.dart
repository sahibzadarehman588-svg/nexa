import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../data/services/firestore_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/product_history_model.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../core/routes/app_routes.dart';

class ProductsController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();

  // Expose auth controller for use in screens
  AuthController get authController => _authController;
  FirestoreService get firestoreService => _firestoreService;

  // Reactive state
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;

  // Products data
  final RxList<ProductModel> allProducts = <ProductModel>[].obs;
  final RxList<ProductModel> filteredProducts = <ProductModel>[].obs;

  // Search and filter
  final RxString searchQuery = ''.obs;
  final RxString selectedCategory = 'All'.obs;
  final RxString selectedStatus = 'All'.obs;

  // Statistics
  final RxInt totalProducts = 0.obs;
  final RxInt expiringSoonProducts = 0.obs;
  final RxInt expiredProducts = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _loadProducts();
    _rescheduleProductExpiryNotifications();
  }

  Future<void> _rescheduleProductExpiryNotifications() async {
    debugPrint('=== ProductsController: Rescheduling product expiry notifications ===');
    try {
      for (final product in allProducts) {
        // Only reschedule if expiry date is in the future (date-only comparison)
        final now = DateTime.now();
        final normalizedNow = DateTime(now.year, now.month, now.day);
        final normalizedExpiryDate = DateTime(product.expiryDate.year, product.expiryDate.month, product.expiryDate.day);
        if (normalizedExpiryDate.isAfter(normalizedNow)) {
          await _notificationService.scheduleProductExpiryNotifications(
            productId: product.productId,
            productName: product.productName,
            expiryDate: product.expiryDate,
          );
          debugPrint('✅ Rescheduled notifications for product: ${product.productId}');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error rescheduling product expiry notifications: $e');
    }
  }

  Future<void> _loadProducts() async {
    if (_authController.currentUser.value == null) return;

    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';

    try {
      final userId = _authController.currentUser.value!.userId;
      final products = await _firestoreService.getProducts(userId);

      // Get existing history to avoid duplicates
      final expiringHistory = await _firestoreService.getProductHistory(userId, FirebaseConstants.statusExpiringSoon);
      final expiredHistory = await _firestoreService.getProductHistory(userId, FirebaseConstants.statusExpired);

      final expiringProductIds = expiringHistory.map((h) => h.productId).toSet();
      final expiredProductIds = expiredHistory.map((h) => h.productId).toSet();

      // Update product statuses and track history
      final updatedProducts = <ProductModel>[];
      for (var product in products) {
        final updatedProduct = ProductModel.updateStatus(product);
        updatedProducts.add(updatedProduct);

        // Track history if status changed to expiring_soon or expired
        await _trackProductHistory(userId, product, updatedProduct, expiringProductIds, expiredProductIds);
      }

      allProducts.value = updatedProducts;
      _applyFilters();
      _updateStatistics();
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _trackProductHistory(
    String userId,
    ProductModel oldProduct,
    ProductModel newProduct,
    Set<String> expiringProductIds,
    Set<String> expiredProductIds,
  ) async {
    // If status changed to expiring_soon
    if (oldProduct.status != FirebaseConstants.statusExpiringSoon &&
        newProduct.status == FirebaseConstants.statusExpiringSoon) {
      await _createHistoryEntry(
        userId,
        newProduct,
        FirebaseConstants.statusExpiringSoon,
      );
    }

    // If status changed to expired
    if (oldProduct.status != FirebaseConstants.statusExpired &&
        newProduct.status == FirebaseConstants.statusExpired) {
      await _createHistoryEntry(
        userId,
        newProduct,
        FirebaseConstants.statusExpired,
      );
    }

    // Backfill: If product is already expiring_soon but has no history record
    if (newProduct.status == FirebaseConstants.statusExpiringSoon &&
        !expiringProductIds.contains(newProduct.productId)) {
      await _createHistoryEntry(
        userId,
        newProduct,
        FirebaseConstants.statusExpiringSoon,
      );
    }

    // Backfill: If product is already expired but has no history record
    if (newProduct.status == FirebaseConstants.statusExpired &&
        !expiredProductIds.contains(newProduct.productId)) {
      await _createHistoryEntry(
        userId,
        newProduct,
        FirebaseConstants.statusExpired,
      );
    }
  }

  Future<void> _createHistoryEntry(
    String userId,
    ProductModel product,
    String status,
  ) async {
    try {
      // Use productId + status as unique key to avoid duplicates
      final historyId = '${product.productId}_$status';
      final history = ProductHistoryModel.create(
        historyId: historyId,
        productId: product.productId,
        productName: product.productName,
        category: product.category,
        expiryDate: product.expiryDate,
        status: status,
        quantity: product.quantity,
        productImage: product.productImage,
      );

      await _firestoreService.createProductHistory(userId, history);
    } catch (e) {
      // Log error but don't block the main flow
      debugPrint('Failed to create product history: $e');
    }
  }

  void _applyFilters() {
    filteredProducts.value = allProducts.where((product) {
      // Apply search filter
      if (searchQuery.value.isNotEmpty) {
        final query = searchQuery.value.toLowerCase();
        if (!product.productName.toLowerCase().contains(query) &&
            !(product.category?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }

      // Apply category filter
      if (selectedCategory.value != 'All') {
        if (product.category != selectedCategory.value) {
          return false;
        }
      }

      // Apply status filter
      if (selectedStatus.value != 'All') {
        if (product.status != selectedStatus.value) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _updateStatistics() {
    totalProducts.value = allProducts.length;
    expiringSoonProducts.value = allProducts
        .where((p) => p.status == FirebaseConstants.statusExpiringSoon)
        .length;
    expiredProducts.value = allProducts
        .where((p) => p.status == FirebaseConstants.statusExpired)
        .length;
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  void onCategoryChanged(String category) {
    selectedCategory.value = category;
    _applyFilters();
  }

  void onStatusChanged(String status) {
    selectedStatus.value = status;
    _applyFilters();
  }

  List<String> getCategories() {
    final categories = allProducts
        .map((p) => p.category)
        .where((c) => c != null && c.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    categories.sort();
    return ['All', ...categories];
  }

  Future<void> deleteProduct(ProductModel product) async {
    if (_authController.currentUser.value == null) return;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete ${product.productName}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Get.theme.colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    isLoading.value = true;
    try {
      final userId = _authController.currentUser.value!.userId;

      // Delete image from storage if exists
      if (product.productImage != null) {
        await _storageService.deleteImage(product.productImage!);
      }

      // Delete from Firestore
      await _firestoreService.deleteProduct(userId, product.productId);

      // Cancel expiry notifications
      await _notificationService.cancelProductExpiryNotifications(product.productId);

      // Remove from local list
      allProducts.remove(product);
      _applyFilters();
      _updateStatistics();

      Get.snackbar(
        'Success',
        'Product deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshProducts() async {
    await _loadProducts();
  }

  void navigateToProductDetail(ProductModel product) {
    // Navigate to edit screen for now (detail can be added later)
    navigateToEditProduct(product);
  }

  void navigateToAddProduct() {
    Get.toNamed(AppRoutes.addProduct)?.then((result) {
      if (result == true) {
        refreshProducts();
      }
    });
  }

  void navigateToEditProduct(ProductModel product) {
    Get.toNamed(AppRoutes.editProduct, arguments: product)?.then((result) {
      if (result == true) {
        refreshProducts();
      }
    });
  }

  Future<List<ProductHistoryModel>> loadProductHistory(String status) async {
    if (_authController.currentUser.value == null) return [];

    try {
      final userId = _authController.currentUser.value!.userId;
      return await _firestoreService.getProductHistory(userId, status);
    } catch (e) {
      debugPrint('Failed to load product history: $e');
      return [];
    }
  }

  void navigateToExpiringHistory() {
    Get.toNamed(AppRoutes.productHistory, arguments: FirebaseConstants.statusExpiringSoon);
  }

  void navigateToExpiredHistory() {
    Get.toNamed(AppRoutes.productHistory, arguments: FirebaseConstants.statusExpired);
  }
}
