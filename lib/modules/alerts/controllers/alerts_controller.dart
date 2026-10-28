import 'package:get/get.dart';
import '../../../data/services/firestore_service.dart';
import '../../../data/models/alert_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/task_model.dart';
import '../../auth/controllers/auth_controller.dart';
import 'dart:async';

class AlertsController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();

  // Reactive state
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  final RxList<AlertModel> alerts = <AlertModel>[].obs;

  // Countdown timer for task alerts
  Timer? _countdownTimer;
  final RxMap<String, String> countdowns = <String, String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _loadAlerts();
    _startCountdownTimer();
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    super.onClose();
  }

  Future<void> _loadAlerts() async {
    if (_authController.currentUser.value == null) return;

    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';

    try {
      final userId = _authController.currentUser.value!.userId;

      // Load products and tasks to generate alerts
      final products = await _firestoreService.getProducts(userId);
      final tasks = await _firestoreService.getTasks(userId);

      // Generate alerts from products
      final productAlerts = _generateProductAlerts(products);

      // Generate alerts from tasks
      final taskAlerts = _generateTaskAlerts(tasks);

      // Combine and sort by date (newest first)
      final allAlerts = [...productAlerts, ...taskAlerts];
      allAlerts.sort((a, b) => b.alertDate.compareTo(a.alertDate));

      alerts.value = allAlerts;
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  List<AlertModel> _generateProductAlerts(List<ProductModel> products) {
    final List<AlertModel> alertList = [];

    for (final product in products) {
      final remainingDays = product.remainingDays;

      // Product expiring in 5 days or less
      if (remainingDays <= 5 && remainingDays > 0) {
        final alertId = 'product_${product.productId}_expiry';
        final alert = AlertModel.create(
          alertId: alertId,
          alertType: 'product_expiry',
          alertMessage: '${product.productName} expires in $remainingDays day${remainingDays == 1 ? '' : 's'}.',
          referenceId: product.productId,
          referenceType: 'product',
          targetDate: product.expiryDate,
          itemName: product.productName,
          status: 'active',
        );
        alertList.add(alert);
      }
      // Product already expired
      else if (remainingDays <= 0) {
        final alertId = 'product_${product.productId}_expired';
        final alert = AlertModel.create(
          alertId: alertId,
          alertType: 'product_expired',
          alertMessage: '${product.productName} has expired.',
          referenceId: product.productId,
          referenceType: 'product',
          targetDate: product.expiryDate,
          itemName: product.productName,
          status: 'expired',
        );
        alertList.add(alert);
      }
    }

    return alertList;
  }

  List<AlertModel> _generateTaskAlerts(List<TaskModel> tasks) {
    final List<AlertModel> alertList = [];

    for (final task in tasks) {
      if (task.isCompleted || task.dueDate == null) continue;

      final dueDate = task.dueDate!;
      final dueDateTime = DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day,
      );

      final difference = dueDateTime.difference(DateTime.now());
      final hoursRemaining = difference.inHours;

      // Task due in 24 hours or less
      if (hoursRemaining <= 24 && hoursRemaining > 0) {
        final alertId = 'task_${task.taskId}_due';
        final alert = AlertModel.create(
          alertId: alertId,
          alertType: 'task_due',
          alertMessage: '${task.title} is due in $hoursRemaining hour${hoursRemaining == 1 ? '' : 's'}.',
          referenceId: task.taskId,
          referenceType: 'task',
          targetDate: dueDateTime,
          itemName: task.title,
          status: 'active',
        );
        alertList.add(alert);
      }
      // Task overdue
      else if (hoursRemaining <= 0) {
        final alertId = 'task_${task.taskId}_overdue';
        final alert = AlertModel.create(
          alertId: alertId,
          alertType: 'task_overdue',
          alertMessage: '${task.title} is overdue.',
          referenceId: task.taskId,
          referenceType: 'task',
          targetDate: dueDateTime,
          itemName: task.title,
          status: 'overdue',
        );
        alertList.add(alert);
      }
    }

    return alertList;
  }

  void _startCountdownTimer() {
    // Update countdowns every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCountdowns();
    });
  }

  void _updateCountdowns() {
    final now = DateTime.now();
    final Map<String, String> newCountdowns = {};

    for (final alert in alerts) {
      if (alert.alertType == 'task_due' && alert.targetDate != null) {
        final difference = alert.targetDate!.difference(now);
        
        if (difference.inSeconds > 0) {
          // Format as HH:MM:SS
          final hours = difference.inHours.toString().padLeft(2, '0');
          final minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');
          final seconds = (difference.inSeconds % 60).toString().padLeft(2, '0');
          newCountdowns[alert.alertId] = '$hours:$minutes:$seconds';
        } else {
          // Task is overdue, show 00:00:00
          newCountdowns[alert.alertId] = '00:00:00';
        }
      }
    }

    countdowns.value = newCountdowns;
  }

  Future<void> markAsRead(String alertId) async {
    try {
      final index = alerts.indexWhere((alert) => alert.alertId == alertId);
      if (index != -1) {
        final updatedAlert = alerts[index].copyWith(isRead: true);
        alerts[index] = updatedAlert;
        alerts.refresh();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }

  Future<void> refreshAlerts() async {
    await _loadAlerts();
  }
}
