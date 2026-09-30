import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/notification_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final NotificationController notificationController = Get.find<NotificationController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: AppColors.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Notification Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Notifications',
                        style: AppTextStyles.headline6,
                      ),
                      Obx(() => Switch(
                            value: notificationController.isNotificationEnabled.value,
                            onChanged: (value) {
                              if (value) {
                                notificationController.requestNotificationPermission();
                              } else {
                                notificationController.cancelAllNotifications();
                              }
                            },
                          )),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Obx(() => Text(
                        notificationController.isNotificationEnabled.value
                            ? 'Notifications are enabled. You will receive alerts for expiring products.'
                            : 'Notifications are disabled. Enable to receive expiry alerts.',
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Notification Preferences Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notification Preferences',
                    style: AppTextStyles.headline6,
                  ),
                  const SizedBox(height: 16),
                  _buildNotificationPreference(
                    'Expiry Reminders',
                    'Get notified when products are about to expire',
                    true,
                  ),
                  const Divider(),
                  _buildNotificationPreference(
                    'Expired Products',
                    'Get notified when products have expired',
                    true,
                  ),
                  const Divider(),
                  _buildNotificationPreference(
                    'Daily Summary',
                    'Get a daily summary of your inventory',
                    false,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Test Notification Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Test Notifications',
                    style: AppTextStyles.headline6,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Send a test notification to verify your settings',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Obx(() => SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: notificationController.isNotificationEnabled.value
                              ? () {
                                  // TODO: Implement test notification
                                  Get.snackbar(
                                    'Test',
                                    'Test notification sent',
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                }
                              : null,
                          child: const Text('Send Test Notification'),
                        ),
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Information Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Notifications are scheduled based on product expiry dates. Make sure to grant notification permissions for the best experience.',
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationPreference(
    String title,
    String description,
    bool isEnabled,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.body1,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: isEnabled,
          onChanged: (value) {
            // TODO: Implement preference saving
            Get.snackbar(
              'Coming Soon',
              'Notification preferences - Coming Soon',
              snackPosition: SnackPosition.BOTTOM,
            );
          },
        ),
      ],
    );
  }
}
