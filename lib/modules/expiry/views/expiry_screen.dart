import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../controllers/expiry_controller.dart';
import '../../../data/models/product_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../core/constants/firebase_constants.dart';

class ExpiryScreen extends StatelessWidget {
  const ExpiryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ExpiryController expiryController = Get.find<ExpiryController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Expiry Management'),
        backgroundColor: AppColors.surfaceElevated,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: expiryController.refreshData,
          ),
        ],
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            // Tab Bar
            const TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: 'Expired'),
                Tab(text: 'Expiring Soon'),
                Tab(text: 'Safe'),
              ],
            ),
            const Divider(height: 1),

            // Tab Content
            Expanded(
              child: TabBarView(
                children: [
                  _buildExpiredTab(expiryController),
                  _buildExpiringSoonTab(expiryController),
                  _buildSafeTab(expiryController),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiredTab(ExpiryController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return _buildLoadingState();
      }

      if (controller.hasError.value) {
        return _buildErrorState(controller);
      }

      if (controller.expiredProducts.isEmpty) {
        return _buildEmptyState('No expired products');
      }

      return _buildProductList(controller.expiredProducts, controller);
    });
  }

  Widget _buildExpiringSoonTab(ExpiryController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return _buildLoadingState();
      }

      if (controller.hasError.value) {
        return _buildErrorState(controller);
      }

      if (controller.expiringSoonProducts.isEmpty) {
        return _buildEmptyState('No products expiring soon');
      }

      return _buildProductList(controller.expiringSoonProducts, controller);
    });
  }

  Widget _buildSafeTab(ExpiryController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return _buildLoadingState();
      }

      if (controller.hasError.value) {
        return _buildErrorState(controller);
      }

      if (controller.safeProducts.isEmpty) {
        return _buildEmptyState('No safe products');
      }

      return _buildProductList(controller.safeProducts, controller);
    });
  }

  Widget _buildProductList(List<ProductModel> products, ExpiryController controller) {
    return RefreshIndicator(
      onRefresh: controller.refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return _buildProductCard(product, controller);
        },
      ),
    );
  }

  Widget _buildProductCard(ProductModel product, ExpiryController controller) {
    final isExpired = product.status == FirebaseConstants.statusExpired;
    final statusColor = isExpired ? AppColors.expiryExpired : AppColors.expiryExpiringSoon;
    final remainingDays = app_date_utils.DateUtils.calculateRemainingDays(product.expiryDate);
    final statusText = isExpired
        ? 'Expired ${remainingDays.abs()} days ago'
        : 'Expires in $remainingDays days';

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () => controller.navigateToProductDetail(product),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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

              // Expiry Date
              SizedBox(
                width: 70,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      app_date_utils.DateUtils.formatDisplayDate(product.expiryDate),
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                    const SizedBox(height: 4),
                    if (isExpired)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Expired',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildErrorState(ExpiryController controller) {
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
              onPressed: controller.refreshData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppColors.success,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTextStyles.headline6,
            ),
          ],
        ),
      ),
    );
  }
}
