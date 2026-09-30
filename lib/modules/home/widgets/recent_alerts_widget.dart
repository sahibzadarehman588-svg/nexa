import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/alert_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;

class RecentAlertsWidget extends StatelessWidget {
  final RxList<AlertModel> alerts;

  const RecentAlertsWidget({
    super.key,
    required this.alerts,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (alerts.isEmpty) {
        return _buildEmptyState();
      }

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Alerts',
                    style: AppTextStyles.headline6,
                  ),
                  Text(
                    '${alerts.length} alerts',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: alerts.length > 3 ? 3 : alerts.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  return _buildAlertItem(alert);
                },
              ),
              if (alerts.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Center(
                    child: TextButton(
                      onPressed: () {
                        // TODO: Navigate to alerts screen
                      },
                      child: const Text('View All Alerts'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildAlertItem(AlertModel alert) {
    Color iconColor;
    IconData iconData;

    switch (alert.alertType) {
      case 'expiry':
        iconColor = AppColors.warning;
        iconData = Icons.warning_amber_outlined;
        break;
      case 'expired':
        iconColor = AppColors.error;
        iconData = Icons.error_outline;
        break;
      default:
        iconColor = AppColors.info;
        iconData = Icons.info_outline;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              iconData,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.alertMessage,
                  style: AppTextStyles.body2,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  app_date_utils.DateUtils.getRelativeTime(alert.alertDate),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          if (!alert.isRead)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              Icons.notifications_none_outlined,
              size: 48,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 12),
            Text(
              'No Recent Alerts',
              style: AppTextStyles.body1.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'re all caught up!',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}
