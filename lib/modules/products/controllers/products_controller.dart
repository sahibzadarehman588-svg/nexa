import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../data/services/firestore_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/models/product_model.dart';
import '../../../core/constants/firebase_constants.dart';

class ProductsController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

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
  }

  Future<void> _loadProducts() async {
    if (_authController.currentUser.value == null) return;

    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';

    try {
      final userId = _authController.currentUser.value!.userId;
      final products = await _firestoreService.getProducts(userId);
      
      // Update product statuses
      final updatedProducts = products.map((p) => ProductModel.updateStatus(p)).toList();
      
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
    // TODO: Navigate to product detail screen
    Get.snackbar(
      'Coming Soon',
      'Product Detail - Coming in Phase 5',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void navigateToAddProduct() {
    // Navigate to scanner to add new product
    Get.toNamed('/scanner')?.then((result) {
      if (result == true) {
        refreshProducts();
      }
    });
  }

  void navigateToEditProduct(ProductModel product) {
    // TODO: Navigate to edit product screen
    Get.snackbar(
      'Coming Soon',
      'Edit Product - Coming in Phase 5',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
