import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../controllers/inventory_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final InventoryController inventoryController = Get.find<InventoryController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Inventory Overview'),
        backgroundColor: AppColors.surfaceElevated,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: inventoryController.refreshInventory,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: inventoryController.refreshInventory,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Inventory Overview',
                style: AppTextStyles.headline4,
              ),
              const SizedBox(height: 8),
              Text(
                'Track your products and expiry dates',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Content
              Obx(() {
                if (inventoryController.isLoading.value) {
                  return _buildLoadingState();
                }

                if (inventoryController.hasError.value) {
                  return _buildErrorState(inventoryController);
                }

                if (inventoryController.allProducts.isEmpty) {
                  return _buildEmptyState(inventoryController);
                }

                return _buildInventoryOverview(inventoryController);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        _buildShimmerHealthCard(),
        const SizedBox(height: 16),
        _buildShimmerStatsGrid(),
        const SizedBox(height: 16),
        _buildShimmerCategoryBreakdown(),
        const SizedBox(height: 16),
        _buildShimmerExpiryTimeline(),
      ],
    );
  }

  Widget _buildShimmerHealthCard() {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceElevated,
      highlightColor: AppColors.surface,
      child: Card(
        color: AppColors.surface,
        child: Container(
          height: 120,
          color: AppColors.surface,
        ),
      ),
    );
  }

  Widget _buildShimmerStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 400 ? 2 : 3;
        final childAspectRatio = constraints.maxWidth < 400 ? 1.3 : 1.1;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: childAspectRatio,
          children: List.generate(
            6,
            (index) => Shimmer.fromColors(
              baseColor: AppColors.surfaceElevated,
              highlightColor: AppColors.surface,
              child: Card(
                color: AppColors.surface,
                child: Container(
                  color: AppColors.surface,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerCategoryBreakdown() {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceElevated,
      highlightColor: AppColors.surface,
      child: Card(
        color: AppColors.surface,
        child: Container(
          height: 200,
          color: AppColors.surface,
        ),
      ),
    );
  }

  Widget _buildShimmerExpiryTimeline() {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceElevated,
      highlightColor: AppColors.surface,
      child: Card(
        color: AppColors.surface,
        child: Container(
          height: 150,
          color: AppColors.surface,
        ),
      ),
    );
  }

  Widget _buildErrorState(InventoryController controller) {
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
              'Failed to load inventory',
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
              onPressed: controller.refreshInventory,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(InventoryController controller) {
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
              'No Products in Inventory',
              style: AppTextStyles.headline6,
            ),
            const SizedBox(height: 8),
            Text(
              'Start by adding your first product',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 350) {
                  return Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: controller.navigateToScanner,
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Scan Product'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: controller.navigateToProducts,
                          icon: const Icon(Icons.list),
                          label: const Text('View Products'),
                        ),
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: controller.navigateToScanner,
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Scan Product'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: controller.navigateToProducts,
                        icon: const Icon(Icons.list),
                        label: const Text('View Products'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryOverview(InventoryController controller) {
    return Column(
      children: [
        // Health Score Card
        _buildHealthScoreCard(controller),
        const SizedBox(height: 16),

        // Statistics Grid
        _buildStatisticsGrid(controller),
        const SizedBox(height: 16),

        // Category Breakdown
        _buildCategoryBreakdown(controller),
        const SizedBox(height: 16),

        // Expiry Timeline
        _buildExpiryTimeline(controller),
        const SizedBox(height: 16),

        // Quick Actions
        _buildQuickActions(controller),
      ],
    );
  }

  Widget _buildHealthScoreCard(InventoryController controller) {
    Color healthColor;
    switch (controller.inventoryHealth.value) {
      case 'Excellent':
        healthColor = AppColors.expirySafe;
        break;
      case 'Good':
        healthColor = AppColors.success;
        break;
      case 'Fair':
        healthColor = AppColors.warning;
        break;
      case 'Poor':
        healthColor = AppColors.error;
        break;
      case 'Critical':
        healthColor = AppColors.error;
        break;
      default:
        healthColor = AppColors.textSecondary;
    }

    return Card(
      color: AppColors.surface,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      color: healthColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Inventory Health',
                      style: AppTextStyles.headline6,
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: healthColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: healthColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    controller.inventoryHealth.value,
                    style: AppTextStyles.body2.copyWith(
                      color: healthColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() => LinearProgressIndicator(
                  value: controller.healthScore.value / 100,
                  backgroundColor: AppColors.backgroundSecondary,
                  valueColor: AlwaysStoppedAnimation<Color>(healthColor),
                )),
            const SizedBox(height: 8),
            Obx(() => Text(
                  '${controller.healthScore.value.toStringAsFixed(0)}% Health Score',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsGrid(InventoryController controller) {
    return Card(
      color: AppColors.surface,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Statistics',
                  style: AppTextStyles.headline6,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                // Adjust crossAxisCount based on screen width
                final crossAxisCount = constraints.maxWidth < 400 ? 2 : 3;
                final childAspectRatio = constraints.maxWidth < 400 ? 1.3 : 1.1;

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: childAspectRatio,
                  children: [
                    _StatCard(
                      label: 'Total Products',
                      value: controller.totalProducts.value.toString(),
                      icon: Icons.inventory_2_outlined,
                      color: AppColors.primary,
                    ),
                    _StatCard(
                      label: 'Total Quantity',
                      value: controller.totalQuantity.value.toString(),
                      icon: Icons.format_list_numbered,
                      color: AppColors.info,
                    ),
                    _StatCard(
                      label: 'Low Stock',
                      value: controller.lowStockProducts.value.toString(),
                      icon: Icons.inventory_2,
                      color: AppColors.accent,
                    ),
                    _StatCard(
                      label: 'Expiring Soon',
                      value: controller.expiringSoonProducts.value.toString(),
                      icon: Icons.warning_amber_outlined,
                      color: AppColors.warning,
                    ),
                    _StatCard(
                      label: 'Expired',
                      value: controller.expiredProducts.value.toString(),
                      icon: Icons.error_outline,
                      color: AppColors.error,
                    ),
                    _StatCard(
                      label: 'Available',
                      value: controller.availableProducts.value.toString(),
                      icon: Icons.check_circle_outline,
                      color: AppColors.success,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown(InventoryController controller) {
    return Card(
      color: AppColors.surface,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.category,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Category Breakdown',
                  style: AppTextStyles.headline6,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.categoryBreakdown.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text('No categories yet'),
                  ),
                );
              }

              return Column(
                children: controller.categoryBreakdown.entries.map((entry) {
                  final category = entry.key;
                  final count = entry.value;
                  final percentage = (count / controller.totalProducts.value * 100).toStringAsFixed(1);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category,
                                style: AppTextStyles.body2,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$count items ($percentage%)',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 100,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.backgroundSecondary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: count / controller.totalProducts.value,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiryTimeline(InventoryController controller) {
    return Card(
      color: AppColors.surface,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timeline,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Expiry Timeline',
                  style: AppTextStyles.headline6,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() {
              return Column(
                children: controller.expiryTimeline.entries.map((entry) {
                  final period = entry.key;
                  final count = entry.value;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            period,
                            style: AppTextStyles.caption,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.backgroundSecondary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: controller.totalProducts.value > 0
                                  ? count / controller.totalProducts.value
                                  : 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _getTimelineColor(period),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          count.toString(),
                          style: AppTextStyles.body2,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getTimelineColor(String period) {
    switch (period) {
      case '0-7 days':
        return AppColors.error;
      case '8-14 days':
        return AppColors.warning;
      case '15-30 days':
        return AppColors.info;
      case '31-60 days':
        return AppColors.success;
      case '60+ days':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildQuickActions(InventoryController controller) {
    return Card(
      color: AppColors.surface,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flash_on,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: AppTextStyles.headline6,
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _QuickActionButton(
                  icon: Icons.qr_code_scanner,
                  label: 'Add Product',
                  color: AppColors.primary,
                  onTap: controller.navigateToScanner,
                ),
                _QuickActionButton(
                  icon: Icons.list,
                  label: 'View All',
                  color: AppColors.info,
                  onTap: controller.navigateToProducts,
                ),
                _QuickActionButton(
                  icon: Icons.event_available,
                  label: 'Expiry',
                  color: AppColors.warning,
                  onTap: controller.navigateToExpiry,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: color,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: AppTextStyles.headline4.copyWith(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 10,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
