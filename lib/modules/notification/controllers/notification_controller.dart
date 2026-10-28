import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/firestore_service.dart';

class NotificationController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final NotificationService _notificationService = NotificationService();
  final FirestoreService _firestoreService = FirestoreService();

  // Reactive state
  final RxBool isNotificationEnabled = false.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Notification preferences
  final RxBool expiryRemindersEnabled = true.obs;
  final RxBool expiredProductsEnabled = true.obs;
  final RxBool dailySummaryEnabled = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      await _notificationService.initialize();
      await _checkNotificationPermission();
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    }
  }

  Future<void> _checkNotificationPermission() async {
    try {
      await _notificationService.requestPermissions();
      isNotificationEnabled.value = true;
    } catch (e) {
      isNotificationEnabled.value = false;
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    }
  }

  Future<void> requestNotificationPermission() async {
    isLoading.value = true;
    try {
      await _notificationService.requestPermissions();
      isNotificationEnabled.value = true;
      Get.snackbar(
        'Success',
        'Notifications enabled',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
    } catch (e) {
      isNotificationEnabled.value = false;
      Get.snackbar(
        'Error',
        'Failed to enable notifications',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> checkAndScheduleNotifications() async {
    if (_authController.currentUser.value == null) return;

    try {
      final userId = _authController.currentUser.value!.userId;

      // Schedule product expiry notifications
      final products = await _firestoreService.getProducts(userId);
      for (final product in products) {
        // Only schedule if expiry date is in the future (date-only comparison)
        final now = DateTime.now();
        final normalizedNow = DateTime(now.year, now.month, now.day);
        final normalizedExpiryDate = DateTime(product.expiryDate.year, product.expiryDate.month, product.expiryDate.day);
        if (normalizedExpiryDate.isAfter(normalizedNow)) {
          await _notificationService.scheduleProductExpiryNotifications(
            productId: product.productId,
            productName: product.productName,
            expiryDate: product.expiryDate,
          );
        }
      }

      // Schedule task notifications
      final tasks = await _firestoreService.getTasks(userId);
      for (final task in tasks) {
        // Only schedule if task is not completed and has future due date/time
        if (!task.isCompleted && task.dueDate != null && task.dueTime != null) {
          final dueDateTime = DateTime(
            task.dueDate!.year,
            task.dueDate!.month,
            task.dueDate!.day,
            int.parse(task.dueTime!.split(':')[0]),
            int.parse(task.dueTime!.split(':')[1]),
          );
          if (dueDateTime.isAfter(DateTime.now())) {
            await _notificationService.scheduleTaskNotifications(
              taskId: task.taskId,
              taskTitle: task.title,
              dueDate: task.dueDate!,
              dueTime: task.dueTime,
            );
          }
        }
      }

      debugPrint('✅ All notifications rescheduled successfully');
    } catch (e) {
      debugPrint('Error scheduling notifications: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _notificationService.cancelAllNotifications();
      Get.snackbar(
        'Success',
        'All notifications cancelled',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to cancel notifications',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }

  Future<void> sendTestNotification() async {
    if (!isNotificationEnabled.value) {
      Get.snackbar(
        'Error',
        'Notifications are not enabled',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return;
    }

    try {
      // Schedule a test notification 5 seconds from now
      final testDate = DateTime.now().add(const Duration(seconds: 5));
      await _notificationService.scheduleNotification(
        DateTime.now().millisecondsSinceEpoch.hashCode,
        'NEXIA — Test Notification',
        'This is a test notification from NEXIA.',
        testDate,
      );
      Get.snackbar(
        'Success',
        'Test notification scheduled for 5 seconds from now',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send test notification',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }

  Future<void> updateNotificationPreference(String preferenceType, bool value) async {
    switch (preferenceType) {
      case 'expiryReminders':
        expiryRemindersEnabled.value = value;
        break;
      case 'expiredProducts':
        expiredProductsEnabled.value = value;
        break;
      case 'dailySummary':
        dailySummaryEnabled.value = value;
        break;
    }

    Get.snackbar(
      'Success',
      'Notification preference updated',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.primary,
      colorText: Get.theme.colorScheme.onPrimary,
    );
  }
}
