import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../controllers/home_controller.dart';
import '../widgets/recent_alerts_widget.dart';
import '../widgets/recent_products_widget.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController homeController = Get.find<HomeController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('SAFA'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Get.toNamed('/notification-settings');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
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
                        'One App. Many Real-World Problems.',
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
      ],
    );
  }

  Widget _buildErrorState(HomeController controller) {
    return Column(
      children: [
        Card(
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
        // Quick Actions Grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.2,
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
      ],
    );
  }

  Widget _buildShimmerStats() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(
        child: Container(
          height: 120,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildShimmerQuickActions() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.2,
        children: List.generate(
          4,
          (index) => Card(
            child: Container(
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerRecentProducts() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(
        child: Container(
          height: 200,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildShimmerRecentAlerts() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(
        child: Container(
          height: 200,
          color: Colors.white,
        ),
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: AppTextStyles.headline6,
                textAlign: TextAlign.center,
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
