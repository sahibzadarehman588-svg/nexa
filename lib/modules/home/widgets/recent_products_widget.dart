import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/product_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;

class RecentProductsWidget extends StatelessWidget {
  final RxList<ProductModel> products;

  const RecentProductsWidget({
    super.key,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (products.isEmpty) {
        return _buildEmptyState();
      }

      return Card(
        color: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Products',
                    style: AppTextStyles.headline6,
                  ),
                  Text(
                    '${products.length} items',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: products.length > 3 ? 3 : products.length,
                separatorBuilder: (context, index) => Divider(
                  color: AppColors.divider,
                ),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return _buildProductItem(product);
                },
              ),
              if (products.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Center(
                    child: TextButton(
                      onPressed: () {
                        Get.toNamed(AppRoutes.products);
                      },
                      child: const Text('View All Products'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildProductItem(ProductModel product) {
    Color statusColor;
    String statusText;

    switch (product.status) {
      case 'safe':
        statusColor = AppColors.expirySafe;
        statusText = 'Safe';
        break;
      case 'expiring_soon':
        statusColor = AppColors.expiryExpiringSoon;
        statusText = 'Expiring Soon';
        break;
      case 'expired':
        statusColor = AppColors.expiryExpired;
        statusText = 'Expired';
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusText = 'Unknown';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // Product image or placeholder
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(8),
              image: product.productImage != null
                  ? DecorationImage(
                      image: NetworkImage(product.productImage!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: product.productImage == null
                ? Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.textHint,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  style: AppTextStyles.body2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Qty: ${product.quantity}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
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
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            app_date_utils.DateUtils.formatDisplayDate(product.expiryDate),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 12),
            Text(
              'No Products Yet',
              style: AppTextStyles.body1.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start by scanning your first product!',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
