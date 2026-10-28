import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../notification/controllers/notification_controller.dart';
import '../../../data/services/firestore_service.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/alert_model.dart';
import '../../../data/models/task_model.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/constants/firebase_constants.dart';

class HomeController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final FirestoreService _firestoreService = FirestoreService();
  late final NotificationController _notificationController;

  // Reactive state
  final RxString userName = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;

  // Statistics
  final RxInt totalProducts = 0.obs;
  final RxInt expiringSoonProducts = 0.obs;
  final RxInt expiredProducts = 0.obs;
  final RxInt availableProducts = 0.obs;
  final RxInt lowStockProducts = 0.obs;
  final RxInt pendingTasks = 0.obs;
  final RxInt totalTasks = 0.obs;
  final RxDouble totalOutstandingBalance = 0.0.obs;
  final RxInt customersWithBalance = 0.obs;

  // Data
  final RxList<ProductModel> recentProducts = <ProductModel>[].obs;
  final RxList<AlertModel> recentAlerts = <AlertModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
    
    // Listen to changes in AuthController's currentUser
    ever(_authController.currentUser, (user) {
      if (user != null) {
        userName.value = user.displayName ?? user.email.split('@')[0];
      }
    });
    
    // Initialize notification controller
    if (Get.isRegistered<NotificationController>()) {
      _notificationController = Get.find<NotificationController>();
    } else {
      _notificationController = Get.put(NotificationController());
    }

    _loadDashboardData();
  }

  @override
  void onReady() {
    super.onReady();
    // Refresh data when controller is ready
    refreshData();
  }

  void _loadUserData() {
    if (_authController.currentUser.value != null) {
      userName.value = _authController.currentUser.value!.displayName ??
          _authController.currentUser.value!.email.split('@')[0];
    }
  }

  Future<void> _loadDashboardData() async {
    if (_authController.currentUser.value == null) return;

    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';

    try {
      final userId = _authController.currentUser.value!.userId;

      // Load all data in parallel
      final results = await Future.wait([
        _loadProductStatistics(userId),
        _loadRecentProducts(userId),
        _loadRecentAlerts(userId),
        _loadTaskStatistics(userId),
        _loadUdhaarKhataStatistics(userId),
      ]);

      // Update statistics
      final stats = results[0] as Map<String, int>;
      totalProducts.value = stats['total'] ?? 0;
      expiringSoonProducts.value = stats['expiringSoon'] ?? 0;
      expiredProducts.value = stats['expired'] ?? 0;
      availableProducts.value = stats['available'] ?? 0;
      lowStockProducts.value = stats['lowStock'] ?? 0;
      pendingTasks.value = (results[3] as Map<String, int>)['pending'] ?? 0;
      totalTasks.value = (results[3] as Map<String, int>)['total'] ?? 0;

      // Update Udhaar Khata statistics
      final udhaarStats = results[4] as Map<String, dynamic>;
      totalOutstandingBalance.value = udhaarStats['totalOutstanding'] as double? ?? 0.0;
      customersWithBalance.value = udhaarStats['customersWithBalance'] as int? ?? 0;

      // Check and schedule notifications
      await _notificationController.checkAndScheduleNotifications();

    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, int>> _loadProductStatistics(String userId) async {
    try {
      final allProducts = await _firestoreService.getProducts(userId);
      
      // Update statuses based on current expiry dates
      final updatedProducts = allProducts.map((p) => ProductModel.updateStatus(p)).toList();
      
      final expiringSoon = updatedProducts
          .where((p) => p.status == FirebaseConstants.statusExpiringSoon)
          .toList();
      final expired = updatedProducts
          .where((p) => p.status == FirebaseConstants.statusExpired)
          .toList();

      // Calculate low stock (less than 5 items)
      final lowStock = updatedProducts.where((p) => p.quantity < 5).length;

      return {
        'total': updatedProducts.length,
        'expiringSoon': expiringSoon.length,
        'expired': expired.length,
        'available': updatedProducts.length - expired.length,
        'lowStock': lowStock,
      };
    } catch (e) {
      // Return default values if stats fail to load
      return {
        'total': 0,
        'expiringSoon': 0,
        'expired': 0,
        'available': 0,
        'lowStock': 0,
      };
    }
  }

  Future<void> _loadRecentProducts(String userId) async {
    try {
      final products = await _firestoreService.getProducts(userId);
      // Take first 5 products as recent
      recentProducts.value = products.take(5).toList();
    } catch (e) {
      // Set empty list if loading fails
      recentProducts.value = [];
    }
  }

  Future<void> _loadRecentAlerts(String userId) async {
    try {
      // Generate alerts from products and tasks
      final products = await _firestoreService.getProducts(userId);
      final tasks = await _firestoreService.getTasks(userId);

      // Generate product alerts
      final productAlerts = _generateProductAlerts(products);

      // Generate task alerts
      final taskAlerts = _generateTaskAlerts(tasks);

      // Combine and sort by date (newest first)
      final allAlerts = [...productAlerts, ...taskAlerts];
      allAlerts.sort((a, b) => b.alertDate.compareTo(a.alertDate));

      // Take first 5 alerts as recent
      recentAlerts.value = allAlerts.take(5).toList();
    } catch (e) {
      // Set empty list if loading fails
      recentAlerts.value = [];
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
    final now = DateTime.now();
    final List<AlertModel> alertList = [];

    for (final task in tasks) {
      if (task.isCompleted || task.dueDate == null) continue;

      final dueDate = task.dueDate!;
      final dueDateTime = DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day,
      );

      final difference = dueDateTime.difference(now);
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

  Future<Map<String, int>> _loadTaskStatistics(String userId) async {
    try {
      final tasks = await _firestoreService.getTasks(userId);
      final pendingTasks = tasks.where((task) => !task.isCompleted).length;
      return {
        'pending': pendingTasks,
        'total': tasks.length,
      };
    } catch (e) {
      // Return 0 if tasks fail to load
      return {
        'pending': 0,
        'total': 0,
      };
    }
  }

  Future<Map<String, dynamic>> _loadUdhaarKhataStatistics(String userId) async {
    try {
      // Calculate Udhaar Khata statistics manually
      final customers = await _firestoreService.getActiveCustomers(userId);
      double totalOutstanding = 0.0;
      int balanceCustomerCount = 0;

      for (final customer in customers) {
        final creditEntries = await _firestoreService.getCreditEntriesByCustomer(userId, customer.customerId);
        final payments = await _firestoreService.getPaymentsByCustomer(userId, customer.customerId);

        final customerCredit = creditEntries.fold<double>(0.0, (sum, entry) => sum + entry.amount);
        final customerPayments = payments.fold<double>(0.0, (sum, payment) => sum + payment.paymentAmount);
        final outstanding = customerCredit - customerPayments;

        totalOutstanding += outstanding;

        if (outstanding > 0) {
          balanceCustomerCount++;
        }
      }

      return {
        'totalOutstanding': totalOutstanding,
        'customersWithBalance': balanceCustomerCount,
      };
    } catch (e) {
      debugPrint('Error loading Udhaar Khata statistics: $e');
      // Return default values if stats fail to load
      return {
        'totalOutstanding': 0.0,
        'customersWithBalance': 0,
      };
    }
  }

  Future<void> refreshData() async {
    await _loadDashboardData();
  }

  void logout() {
    _authController.logout();
  }

  void navigateToScanner() async {
    final result = await Get.toNamed(AppRoutes.scanner);
    if (result == true) {
      // Refresh data when returning from scanner with success
      refreshData();
    }
  }

  void navigateToProducts() {
    Get.toNamed(AppRoutes.products)?.then((result) {
      if (result == true) {
        refreshData();
      }
    });
  }

  void navigateToInventory() {
    Get.toNamed(AppRoutes.inventory)?.then((result) {
      if (result == true) {
        refreshData();
      }
    });
  }

  void navigateToExpiry() {
    Get.toNamed(AppRoutes.expiry)?.then((result) {
      if (result == true) {
        refreshData();
      }
    });
  }

  void navigateToAIChat() {
    Get.toNamed(AppRoutes.aiChat);
  }

  void navigateToTasks() {
    Get.toNamed(AppRoutes.tasks)?.then((result) {
      if (result == true) {
        refreshData();
      }
    });
  }

  void navigateToDocumentAI() {
    Get.toNamed(AppRoutes.documentAi);
  }

  void navigateToReceiptScanner() {
    Get.toNamed(AppRoutes.receiptScanner);
  }

  void navigateToUdhaarKhata() {
    Get.toNamed(AppRoutes.udhaarKhata)?.then((result) {
      if (result == true) {
        refreshData();
      }
    });
  }
}
