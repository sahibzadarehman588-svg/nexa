import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../controllers/home_controller.dart';
import '../widgets/recent_alerts_widget.dart';
import '../widgets/recent_products_widget.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController homeController = Get.find<HomeController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('NEXIA'),
        backgroundColor: AppColors.surfaceElevated,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            color: AppColors.textPrimary,
            onPressed: () {
              Get.toNamed(AppRoutes.alerts);
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            color: AppColors.textPrimary,
            onPressed: () {
              Get.toNamed(AppRoutes.profile);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            color: AppColors.textPrimary,
            onPressed: homeController.logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: homeController.refreshData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Obx(() => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${homeController.userName.value}!',
                        style: AppTextStyles.headline3,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'One App. One Intelligent Assistant.',
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  )),
              const SizedBox(height: 24),

              // Loading State
              Obx(() {
                if (homeController.isLoading.value) {
                  return _buildLoadingState();
                }

                // Error State
                if (homeController.hasError.value) {
                  return _buildErrorState(homeController);
                }

                // Normal State
                return _buildNormalState(homeController);
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
        _buildShimmerStats(),
        const SizedBox(height: 24),
        _buildShimmerQuickActions(),
        const SizedBox(height: 24),
        _buildShimmerRecentProducts(),
        const SizedBox(height: 24),
        _buildShimmerRecentAlerts(),
        const SizedBox(height: 24),
        _buildShimmerAdditionalFeatures(),
      ],
    );
  }

  Widget _buildErrorState(HomeController controller) {
    return Column(
      children: [
        Card(
          color: AppColors.surface,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load data',
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
        ),
      ],
    );
  }

  Widget _buildNormalState(HomeController controller) {
    return Column(
      children: [
        // Quick Actions Grid - Expanded to show all features
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            _buildQuickActionCard(
              icon: Icons.qr_code_scanner,
              title: 'Quick Scan',
              onTap: controller.navigateToScanner,
            ),
            _buildQuickActionCard(
              icon: Icons.inventory_2_outlined,
              title: 'My Products',
              onTap: controller.navigateToProducts,
            ),
            _buildQuickActionCard(
              icon: Icons.bar_chart_outlined,
              title: 'Inventory',
              onTap: controller.navigateToInventory,
            ),
            _buildQuickActionCard(
              icon: Icons.chat_outlined,
              title: 'AI Assistant',
              onTap: controller.navigateToAIChat,
            ),
            _buildQuickActionCard(
              icon: Icons.task_alt_outlined,
              title: 'Tasks',
              onTap: controller.navigateToTasks,
            ),
            _buildQuickActionCard(
              icon: Icons.warning_amber_outlined,
              title: 'Expiry',
              onTap: controller.navigateToExpiry,
            ),
            _buildQuickActionCard(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Udhaar Khata',
              onTap: controller.navigateToUdhaarKhata,
            ),
            _buildQuickActionCard(
              icon: Icons.receipt_long_outlined,
              title: 'Receipt Scanner',
              onTap: controller.navigateToReceiptScanner,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Stats Section
        Obx(() => Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Stats',
                      style: AppTextStyles.headline6,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          label: 'Total Products',
                          value: controller.totalProducts.value.toString(),
                          color: AppColors.primary,
                        ),
                        _StatItem(
                          label: 'Expiring Soon',
                          value: controller.expiringSoonProducts.value.toString(),
                          color: AppColors.warning,
                        ),
                        _StatItem(
                          label: 'Expired',
                          value: controller.expiredProducts.value.toString(),
                          color: AppColors.error,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )),
        const SizedBox(height: 24),

        // Recent Products
        RecentProductsWidget(
          products: controller.recentProducts,
        ),
        const SizedBox(height: 24),

        // Recent Alerts
        RecentAlertsWidget(
          alerts: controller.recentAlerts,
        ),
        const SizedBox(height: 24),

        // Additional Features Row
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.description_outlined,
                title: 'Document AI',
                onTap: controller.navigateToDocumentAI,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.settings_outlined,
                title: 'Notif. Settings',
                onTap: () => Get.toNamed(AppRoutes.notificationSettings),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildShimmerStats() {
    return Shimmer.fromColors(
      baseColor: AppColors.backgroundSecondary,
      highlightColor: AppColors.surface,
      child: Card(
        color: AppColors.surface,
        child: Container(
          height: 120,
        ),
      ),
    );
  }

  Widget _buildShimmerQuickActions() {
    return Shimmer.fromColors(
      baseColor: AppColors.backgroundSecondary,
      highlightColor: AppColors.surface,
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
        children: List.generate(
          8,
          (index) => Card(
            color: AppColors.surface,
            child: Container(
              color: AppColors.surface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerRecentProducts() {
    return Shimmer.fromColors(
      baseColor: AppColors.backgroundSecondary,
      highlightColor: AppColors.surface,
      child: Card(
        color: AppColors.surface,
        child: Container(
          height: 200,
        ),
      ),
    );
  }

  Widget _buildShimmerRecentAlerts() {
    return Shimmer.fromColors(
      baseColor: AppColors.backgroundSecondary,
      highlightColor: AppColors.surface,
      child: Card(
        color: AppColors.surface,
        child: Container(
          height: 200,
        ),
      ),
    );
  }

  Widget _buildShimmerAdditionalFeatures() {
    return Shimmer.fromColors(
      baseColor: AppColors.backgroundSecondary,
      highlightColor: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            child: Card(
              color: AppColors.surface,
              child: Container(
                height: 100,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Card(
              color: AppColors.surface,
              child: Container(
                height: 100,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: AppColors.primary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: AppTextStyles.subtitle2,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.headline4.copyWith(
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
