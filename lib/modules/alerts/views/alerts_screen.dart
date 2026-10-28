import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/alerts_controller.dart';
import '../../../data/models/alert_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AlertsController alertsController = Get.find<AlertsController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Alerts'),
        backgroundColor: AppColors.surfaceElevated,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: alertsController.refreshAlerts,
          ),
        ],
      ),
      body: Obx(() {
        if (alertsController.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (alertsController.hasError.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading alerts',
                  style: AppTextStyles.body1,
                ),
                const SizedBox(height: 8),
                Text(
                  alertsController.errorMessage.value,
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: alertsController.refreshAlerts,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (alertsController.alerts.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: alertsController.refreshAlerts,
          child: ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: alertsController.alerts.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final alert = alertsController.alerts[index];
              return _buildAlertCard(alert, alertsController);
            },
          ),
        );
      }),
    );
  }

  Widget _buildAlertCard(AlertModel alert, AlertsController controller) {
    Color iconColor;
    IconData iconData;
    String alertTitle;

    switch (alert.alertType) {
      case 'product_expiry':
        iconColor = AppColors.warning;
        iconData = Icons.warning_amber_outlined;
        alertTitle = 'Product Expiring Soon';
        break;
      case 'product_expired':
        iconColor = AppColors.error;
        iconData = Icons.error_outline;
        alertTitle = 'Product Expired';
        break;
      case 'task_due':
        iconColor = AppColors.warning;
        iconData = Icons.schedule_outlined;
        alertTitle = 'Task Due Soon';
        break;
      case 'task_overdue':
        iconColor = AppColors.error;
        iconData = Icons.error_outline;
        alertTitle = 'Task Overdue';
        break;
      default:
        iconColor = AppColors.info;
        iconData = Icons.info_outline;
        alertTitle = 'Alert';
    }

    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                iconData,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alertTitle,
                    style: AppTextStyles.body1.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (alert.itemName != null)
                    Text(
                      alert.itemName!,
                      style: AppTextStyles.body2,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    alert.alertMessage,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  // Show countdown for task alerts
                  if (alert.alertType == 'task_due')
                    Obx(() {
                      final countdown = controller.countdowns[alert.alertId];
                      if (countdown != null) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            countdown,
                            style: AppTextStyles.headline6.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(alert.alertDate),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            if (!alert.isRead)
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            'No Alerts',
            style: AppTextStyles.headline4.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: AppTextStyles.body2.copyWith(
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
