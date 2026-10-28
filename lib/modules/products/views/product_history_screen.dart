import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/products_controller.dart';
import '../../../data/models/product_history_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../core/constants/firebase_constants.dart';

class ProductHistoryScreen extends StatelessWidget {
  const ProductHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String status = Get.arguments as String;
    final ProductsController productsController = Get.find<ProductsController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          status == FirebaseConstants.statusExpiringSoon
              ? 'Expiring History'
              : 'Expired History',
        ),
        backgroundColor: AppColors.surfaceElevated,
        foregroundColor: AppColors.textPrimary,
      ),
      body: FutureBuilder<List<ProductHistoryModel>>(
        future: productsController.loadProductHistory(status),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final historyList = snapshot.data ?? [];

          if (historyList.isEmpty) {
            return _buildEmptyState();
          }

          return _buildHistoryList(historyList);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState(String error) {
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
              'Failed to load history',
              style: AppTextStyles.headline6,
            ),
            const SizedBox(height: 8),
            Text(
              error.replaceAll('Exception: ', ''),
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_outlined,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              'No History Found',
              style: AppTextStyles.headline6,
            ),
            const SizedBox(height: 8),
            Text(
              'Products that enter expiring or expired status will appear here',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(List<ProductHistoryModel> historyList) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: historyList.length,
      itemBuilder: (context, index) {
        final history = historyList[index];
        return _buildHistoryCard(history);
      },
    );
  }

  Widget _buildHistoryCard(ProductHistoryModel history) {
    Color statusColor;
    String statusText;

    switch (history.status) {
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    image: history.productImage != null
                        ? DecorationImage(
                            image: NetworkImage(history.productImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: history.productImage == null
                      ? const Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.textHint,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        history.productName,
                        style: AppTextStyles.body1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (history.category != null)
                        Text(
                          history.category!,
                          style: AppTextStyles.caption,
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Qty: ${history.quantity}',
                            style: AppTextStyles.caption,
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
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expiry Date',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      app_date_utils.DateUtils.formatDisplayDate(history.expiryDate),
                      style: AppTextStyles.body2,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Status Since',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      app_date_utils.DateUtils.formatDisplayDate(history.statusEnteredDate),
                      style: AppTextStyles.body2,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
