import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../controllers/products_controller.dart';
import '../../../data/models/product_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../core/constants/firebase_constants.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProductsController productsController = Get.find<ProductsController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Products'),
        backgroundColor: AppColors.surfaceElevated,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: productsController.navigateToAddProduct,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: productsController.refreshProducts,
        child: Column(
          children: [
            // Search and Filter Section
            _buildSearchAndFilterSection(productsController),
            const Divider(height: 1),

            // Products List
            Expanded(
              child: Obx(() {
                if (productsController.isLoading.value) {
                  return _buildLoadingState();
                }

                if (productsController.hasError.value) {
                  return _buildErrorState(productsController);
                }

                if (productsController.filteredProducts.isEmpty) {
                  return _buildEmptyState(productsController);
                }

                return _buildProductsList(productsController);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterSection(ProductsController controller) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      color: AppColors.surface,
      child: Column(
        children: [
          // Search Bar
          TextField(
            onChanged: controller.onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              suffixIcon: Obx(() {
                if (controller.searchQuery.value.isNotEmpty) {
                  return IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => controller.onSearchChanged(''),
                  );
                }
                return const SizedBox.shrink();
              }),
            ),
          ),
          const SizedBox(height: 8),

          // Filter Row
          Row(
            children: [
              Expanded(
                child: Obx(() => DropdownButtonFormField<String>(
                      initialValue: controller.selectedCategory.value,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: controller.getCategories().map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category, style: TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          controller.onCategoryChanged(value);
                        }
                      },
                    )),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Obx(() => DropdownButtonFormField<String>(
                      initialValue: controller.selectedStatus.value,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(
                          value: FirebaseConstants.statusSafe,
                          child: Text('Safe', style: TextStyle(fontSize: 13)),
                        ),
                        DropdownMenuItem(
                          value: FirebaseConstants.statusExpiringSoon,
                          child: Text('Expiring Soon', style: TextStyle(fontSize: 13)),
                        ),
                        DropdownMenuItem(
                          value: FirebaseConstants.statusExpired,
                          child: Text('Expired', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          controller.onStatusChanged(value);
                        }
                      },
                    )),
              ),
            ],
          ),

          // Statistics Row
          const SizedBox(height: 8),
          Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatChip(
                    label: 'Total',
                    value: controller.totalProducts.value.toString(),
                    color: AppColors.primary,
                    onTap: null,
                  ),
                  _StatChip(
                    label: 'Expiring',
                    value: controller.expiringSoonProducts.value.toString(),
                    color: AppColors.warning,
                    onTap: controller.navigateToExpiringHistory,
                  ),
                  _StatChip(
                    label: 'Expired',
                    value: controller.expiredProducts.value.toString(),
                    color: AppColors.error,
                    onTap: controller.navigateToExpiredHistory,
                  ),
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppColors.surfaceElevated,
          highlightColor: AppColors.surface,
          child: Card(
            color: AppColors.surface,
            margin: const EdgeInsets.only(bottom: 12.0),
            child: Container(
              height: 100,
              color: AppColors.surface,
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(ProductsController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load products',
              style: AppTextStyles.headline6,
            ),
            const SizedBox(height: 8),
            Obx(() => Text(
                  controller.errorMessage.value,
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                )),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: controller.refreshProducts,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ProductsController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              'No Products Found',
              style: AppTextStyles.headline6,
            ),
            const SizedBox(height: 8),
            Text(
              controller.searchQuery.value.isNotEmpty ||
                      controller.selectedCategory.value != 'All' ||
                      controller.selectedStatus.value != 'All'
                  ? 'Try adjusting your filters'
                  : 'Start by adding your first product',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (controller.searchQuery.value.isEmpty &&
                controller.selectedCategory.value == 'All' &&
                controller.selectedStatus.value == 'All')
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton.icon(
                  onPressed: controller.navigateToAddProduct,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Product'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsList(ProductsController controller) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: controller.filteredProducts.length,
      itemBuilder: (context, index) {
        final product = controller.filteredProducts[index];
        return _buildProductCard(product, controller);
      },
    );
  }

  Widget _buildProductCard(ProductModel product, ProductsController controller) {
    Color statusColor;
    String statusText;

    switch (product.status) {
      case FirebaseConstants.statusSafe:
        statusColor = AppColors.expirySafe;
        statusText = 'Safe';
        break;
      case FirebaseConstants.statusExpiringSoon:
        statusColor = AppColors.expiryExpiringSoon;
        statusText = 'Expiring Soon';
        break;
      case FirebaseConstants.statusExpired:
        statusColor = AppColors.expiryExpired;
        statusText = 'Expired';
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusText = 'Unknown';
    }

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () => controller.navigateToProductDetail(product),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Product Image
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  image: product.productImage != null
                      ? DecorationImage(
                          image: NetworkImage(product.productImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: product.productImage == null
                    ? const Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.textHint,
                        size: 28,
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.productName,
                      style: AppTextStyles.body1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (product.category != null)
                      Text(
                        product.category!,
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Qty: ${product.quantity}',
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              statusText,
                              style: AppTextStyles.caption.copyWith(
                                color: statusColor,
                                fontSize: 9,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Expiry Date and Actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    app_date_utils.DateUtils.formatDisplayDate(product.expiryDate),
                    style: AppTextStyles.caption.copyWith(fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () => controller.navigateToEditProduct(product),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: () => controller.deleteProduct(product),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTextStyles.headline6.copyWith(
                color: color,
                fontSize: 14,
              ),
            ),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
