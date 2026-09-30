import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/firestore_service.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/alert_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;

class NotificationController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final NotificationService _notificationService = NotificationService();
  final FirestoreService _firestoreService = FirestoreService();

  // Reactive state
  final RxBool isNotificationEnabled = false.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

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
      final products = await _firestoreService.getProducts(userId);

      for (final product in products) {
        await _scheduleProductNotification(product);
      }
    } catch (e) {
      debugPrint('Error scheduling notifications: $e');
    }
  }

  Future<void> _scheduleProductNotification(ProductModel product) async {
    final remainingDays = app_date_utils.DateUtils.calculateRemainingDays(product.expiryDate);

    // Schedule notification for products expiring soon
    if (remainingDays > 0 && remainingDays <= AppConstants.expiryWarningThreshold) {
      final notificationId = product.productId.hashCode;
      final scheduledDate = product.expiryDate.subtract(const Duration(days: 1));

      await _notificationService.scheduleNotification(
        notificationId,
        'Product Expiring Soon',
        '${product.productName} will expire in $remainingDays days.',
        scheduledDate,
      );
    }

    // Create alert in Firestore for expired products
    if (remainingDays < 0) {
      await _createExpiryAlert(product);
    }
  }

  Future<void> _createExpiryAlert(ProductModel product) async {
    if (_authController.currentUser.value == null) return;

    try {
      final userId = _authController.currentUser.value!.userId;
      final remainingDays = app_date_utils.DateUtils.calculateRemainingDays(product.expiryDate);
      final absDays = remainingDays.abs();

      final alert = AlertModel.create(
        alertId: DateTime.now().millisecondsSinceEpoch.toString(),
        alertType: FirebaseConstants.alertTypeExpired,
        alertMessage: '${product.productName} expired $absDays days ago',
      );

      await _firestoreService.createAlert(userId, alert);
    } catch (e) {
      debugPrint('Error creating expiry alert: $e');
    }
  }

  Future<void> scheduleExpiryReminder(ProductModel product) async {
    final remainingDays = app_date_utils.DateUtils.calculateRemainingDays(product.expiryDate);

    if (remainingDays > 0) {
      await _notificationService.showExpiryNotification(
        product.productName,
        remainingDays,
      );
    } else {
      await _notificationService.showExpiredNotification(product.productName);
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

  Future<void> updateProductStatuses() async {
    if (_authController.currentUser.value == null) return;

    try {
      final userId = _authController.currentUser.value!.userId;
      final products = await _firestoreService.getProducts(userId);

      for (final product in products) {
        final newStatus = app_date_utils.DateUtils.getExpiryStatus(product.expiryDate);
        final newRemainingDays = app_date_utils.DateUtils.calculateRemainingDays(product.expiryDate);

        // Update if status changed
        if (product.status != newStatus || product.remainingDays != newRemainingDays) {
          final updatedProduct = product.copyWith(
            status: newStatus,
            remainingDays: newRemainingDays,
          );
          await _firestoreService.updateProduct(userId, updatedProduct);
        }
      }
    } catch (e) {
      debugPrint('Error updating product statuses: $e');
    }
  }
}
