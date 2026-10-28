import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../data/services/firestore_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/credit_entry_model.dart';
import '../../../data/models/payment_model.dart';
import '../../../core/theme/app_colors.dart';

class UdhaarKhataController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();
  final Uuid _uuid = const Uuid();

  // Reactive state
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;

  // Customer data
  final RxList<CustomerModel> customers = <CustomerModel>[].obs;
  final RxList<CustomerModel> filteredCustomers = <CustomerModel>[].obs;
  final RxString searchQuery = ''.obs;
  final RxBool showArchived = false.obs;

  // Selected customer
  final Rx<CustomerModel?> selectedCustomer = Rx<CustomerModel?>(null);
  final RxList<CreditEntryModel> customerCreditEntries = <CreditEntryModel>[].obs;
  final RxList<PaymentModel> customerPayments = <PaymentModel>[].obs;

  // Statistics
  final RxDouble totalCredit = 0.0.obs;
  final RxDouble totalPayments = 0.0.obs;
  final RxDouble totalOutstanding = 0.0.obs;
  final RxInt customersWithBalance = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    if (_authController.currentUser.value == null) return;

    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';

    try {
      final userId = _authController.currentUser.value!.userId;
      final allCustomers = await _firestoreService.getCustomers(userId);
      customers.value = allCustomers;
      _applyFilters();
      _calculateStatistics();
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  void _applyFilters() {
    filteredCustomers.value = customers.where((customer) {
      // Apply search filter
      if (searchQuery.value.isNotEmpty) {
        final query = searchQuery.value.toLowerCase();
        if (!customer.customerName.toLowerCase().contains(query) &&
            !(customer.customerPhone?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }

      // Apply archive filter
      if (showArchived.value) {
        return customer.isArchived;
      } else {
        return !customer.isArchived;
      }
    }).toList();
  }

  Future<void> _calculateStatistics() async {
    if (_authController.currentUser.value == null) return;

    try {
      final userId = _authController.currentUser.value!.userId;
      final activeCustomers = await _firestoreService.getActiveCustomers(userId);

      double totalCreditSum = 0.0;
      double totalPaymentsSum = 0.0;
      int balanceCustomerCount = 0;

      for (final customer in activeCustomers) {
        final creditEntries = await _firestoreService.getCreditEntriesByCustomer(userId, customer.customerId);
        final payments = await _firestoreService.getPaymentsByCustomer(userId, customer.customerId);

        final customerCredit = creditEntries.fold<double>(0.0, (sum, entry) => sum + entry.amount);
        final customerPayments = payments.fold<double>(0.0, (sum, payment) => sum + payment.paymentAmount);
        final outstanding = customerCredit - customerPayments;

        totalCreditSum += customerCredit;
        totalPaymentsSum += customerPayments;

        if (outstanding > 0) {
          balanceCustomerCount++;
        }
      }

      totalCredit.value = totalCreditSum;
      totalPayments.value = totalPaymentsSum;
      totalOutstanding.value = totalCreditSum - totalPaymentsSum;
      customersWithBalance.value = balanceCustomerCount;
    } catch (e) {
      debugPrint('Error calculating statistics: $e');
    }
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  void onShowArchivedChanged(bool value) {
    showArchived.value = value;
    _applyFilters();
  }

  // Customer operations
  Future<bool> createCustomer({
    required String name,
    String? phone,
    String? address,
    String? notes,
  }) async {
    if (_authController.currentUser.value == null) return false;

    isLoading.value = true;
    try {
      final userId = _authController.currentUser.value!.userId;
      final customerId = _uuid.v4();

      final customer = CustomerModel.create(
        customerId: customerId,
        customerName: name,
        customerPhone: phone,
        customerAddress: address,
        customerNotes: notes,
      );

      await _firestoreService.createCustomer(userId, customer);
      await _loadCustomers();
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateCustomer(CustomerModel customer) async {
    if (_authController.currentUser.value == null) return false;

    isLoading.value = true;
    try {
      final userId = _authController.currentUser.value!.userId;
      await _firestoreService.updateCustomer(userId, customer);
      await _loadCustomers();
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> archiveCustomer(String customerId) async {
    if (_authController.currentUser.value == null) return false;

    isLoading.value = true;
    try {
      final userId = _authController.currentUser.value!.userId;
      await _firestoreService.archiveCustomer(userId, customerId);

      // Cancel customer-level reminder
      await _notificationService.cancelCustomerBalanceReminder(customerId);

      await _loadCustomers();
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> unarchiveCustomer(String customerId) async {
    if (_authController.currentUser.value == null) return false;

    isLoading.value = true;
    try {
      final userId = _authController.currentUser.value!.userId;
      await _firestoreService.unarchiveCustomer(userId, customerId);
      await _loadCustomers();
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteCustomer(String customerId) async {
    if (_authController.currentUser.value == null) return false;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Customer'),
        content: const Text('This will permanently delete the customer and all their transaction history. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Get.theme.colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return false;

    isLoading.value = true;
    try {
      final userId = _authController.currentUser.value!.userId;

      // Cancel customer-level reminder
      await _notificationService.cancelCustomerBalanceReminder(customerId);

      // Cancel all credit entry reminders for this customer
      final creditEntries = await _firestoreService.getCreditEntriesByCustomer(userId, customerId);
      for (final entry in creditEntries) {
        await _notificationService.cancelCreditEntryReminder(entry.creditEntryId);
      }

      await _firestoreService.deleteCustomer(userId, customerId);
      await _loadCustomers();
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Load customer details
  Future<void> loadCustomerDetails(String customerId) async {
    if (_authController.currentUser.value == null) return;

    isLoading.value = true;
    try {
      final userId = _authController.currentUser.value!.userId;

      final customer = await _firestoreService.getCustomer(userId, customerId);
      if (customer != null) {
        selectedCustomer.value = customer;
      }

      final creditEntries = await _firestoreService.getCreditEntriesByCustomer(userId, customerId);
      customerCreditEntries.value = creditEntries;

      final payments = await _firestoreService.getPaymentsByCustomer(userId, customerId);
      customerPayments.value = payments;
    } catch (e) {
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      
      // Provide user-friendly message for Firestore index errors
      if (errorMessage.contains('failed-precondition') || errorMessage.contains('requires an index')) {
        errorMessage = 'Database index required. Please deploy Firestore indexes using: firebase deploy --only firestore:indexes';
      }
      
      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: AppColors.surface,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Calculate customer balance
  double getCustomerBalance() {
    final totalCredit = customerCreditEntries.fold<double>(0.0, (sum, entry) => sum + entry.amount);
    final totalPayments = customerPayments.fold<double>(0.0, (sum, payment) => sum + payment.paymentAmount);
    return totalCredit - totalPayments;
  }

  // Credit entry operations
  Future<bool> createCreditEntry({
    required String customerId,
    required double amount,
    DateTime? transactionDate,
    String? itemDescription,
    String? itemName,
    int? itemQuantity,
    String? itemUnit,
    double? itemPrice,
    String? creditNotes,
    bool reminderEnabled = false,
    DateTime? reminderDate,
    String? reminderTime,
  }) async {
    if (_authController.currentUser.value == null) return false;

    isLoading.value = true;
    try {
      final userId = _authController.currentUser.value!.userId;
      final creditEntryId = _uuid.v4();

      debugPrint('=== Creating Credit Entry ===');
      debugPrint('User ID: $userId');
      debugPrint('Customer ID: $customerId');
      debugPrint('Amount: $amount');
      debugPrint('Credit Entry ID: $creditEntryId');

      final creditEntry = CreditEntryModel.create(
        creditEntryId: creditEntryId,
        customerId: customerId,
        amount: amount,
        transactionDate: transactionDate,
        itemDescription: itemDescription,
        itemName: itemName,
        itemQuantity: itemQuantity,
        itemUnit: itemUnit,
        itemPrice: itemPrice,
        creditNotes: creditNotes,
        reminderEnabled: reminderEnabled,
        reminderDate: reminderDate,
        reminderTime: reminderTime,
      );

      debugPrint('Credit Entry JSON: ${creditEntry.toJson()}');

      await _firestoreService.createCreditEntry(userId, creditEntry);

      debugPrint('✅ Credit entry created successfully');

      // Schedule reminder if enabled
      if (reminderEnabled && reminderDate != null && reminderTime != null) {
        final customer = await _firestoreService.getCustomer(userId, customerId);
        if (customer != null) {
          await _notificationService.scheduleCreditEntryReminder(
            creditEntryId: creditEntryId,
            customerName: customer.customerName,
            amount: amount,
            reminderDate: reminderDate,
            reminderTime: reminderTime,
          );
        }
      }

      // Reload customer details
      await loadCustomerDetails(customerId);
      await _calculateStatistics();
      return true;
    } catch (e) {
      debugPrint('❌ Error creating credit entry: $e');
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: AppColors.surface,
        duration: const Duration(seconds: 5),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateCreditEntry(CreditEntryModel creditEntry) async {
    if (_authController.currentUser.value == null) return false;

    isLoading.value = true;
    try {
      final userId = _authController.currentUser.value!.userId;

      // Cancel old reminder if it existed
      if (creditEntry.reminderEnabled) {
        await _notificationService.cancelCreditEntryReminder(creditEntry.creditEntryId);
      }

      await _firestoreService.updateCreditEntry(userId, creditEntry);

      // Schedule new reminder if enabled
      if (creditEntry.reminderEnabled && creditEntry.reminderDate != null && creditEntry.reminderTime != null) {
        final customer = await _firestoreService.getCustomer(userId, creditEntry.customerId);
        if (customer != null) {
          await _notificationService.scheduleCreditEntryReminder(
            creditEntryId: creditEntry.creditEntryId,
            customerName: customer.customerName,
            amount: creditEntry.outstandingAmount,
            reminderDate: creditEntry.reminderDate,
            reminderTime: creditEntry.reminderTime,
          );
        }
      }

      await loadCustomerDetails(creditEntry.customerId);
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteCreditEntry(String creditEntryId) async {
    if (_authController.currentUser.value == null) return false;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Credit Entry'),
        content: const Text('Are you sure you want to delete this credit entry?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Get.theme.colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return false;

    isLoading.value = true;
    try {
      final userId = _authController.currentUser.value!.userId;

      // Cancel reminder
      await _notificationService.cancelCreditEntryReminder(creditEntryId);

      await _firestoreService.deleteCreditEntry(userId, creditEntryId);

      if (selectedCustomer.value != null) {
        await loadCustomerDetails(selectedCustomer.value!.customerId);
      }
      await _calculateStatistics();
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Payment operations with FIFO allocation
  Future<bool> createPayment({
    required String customerId,
    required double paymentAmount,
    DateTime? paymentDate,
    String? paymentMethod,
    String? paymentNotes,
  }) async {
    if (_authController.currentUser.value == null) return false;

    isLoading.value = true;
    try {
      final userId = _authController.currentUser.value!.userId;

      // Check if payment amount exceeds outstanding balance
      final outstandingBalance = getCustomerBalance();
      if (paymentAmount > outstandingBalance) {
        Get.snackbar(
          'Invalid Amount',
          'Payment amount cannot exceed outstanding balance of Rs. ${outstandingBalance.toStringAsFixed(0)}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.warning,
          colorText: AppColors.surface,
        );
        return false;
      }

      // Create payment record
      final paymentId = _uuid.v4();
      final payment = PaymentModel.create(
        paymentId: paymentId,
        customerId: customerId,
        paymentAmount: paymentAmount,
        paymentDate: paymentDate,
        paymentMethod: paymentMethod,
        paymentNotes: paymentNotes,
      );

      await _firestoreService.createPayment(userId, payment);

      // Allocate payment to unpaid credit entries using FIFO
      await _allocatePayment(userId, customerId, paymentAmount);

      // Check if customer balance is now zero and cancel customer-level reminder
      final newBalance = getCustomerBalance();
      if (newBalance <= 0 && selectedCustomer.value != null) {
        await _notificationService.cancelCustomerBalanceReminder(customerId);
      }

      await loadCustomerDetails(customerId);
      await _calculateStatistics();
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _allocatePayment(String userId, String customerId, double paymentAmount) async {
    // Get unpaid credit entries sorted by date (oldest first - FIFO)
    final unpaidEntries = await _firestoreService.getUnpaidCreditEntries(userId, customerId);
    unpaidEntries.sort((a, b) => a.transactionDate.compareTo(b.transactionDate));

    double remainingAmount = paymentAmount;

    for (final entry in unpaidEntries) {
      if (remainingAmount <= 0) break;

      final outstandingForEntry = entry.outstandingAmount;
      final allocation = remainingAmount > outstandingForEntry ? outstandingForEntry : remainingAmount;

      final updatedEntry = entry.copyWith(
        paidAmount: entry.paidAmount + allocation,
        isPaid: (entry.paidAmount + allocation) >= entry.amount,
      );

      await _firestoreService.updateCreditEntry(userId, updatedEntry);

      // Cancel reminder if entry is now fully paid
      if (updatedEntry.isFullyPaid) {
        await _notificationService.cancelCreditEntryReminder(entry.creditEntryId);
      }

      remainingAmount -= allocation;
    }
  }

  // Customer-level reminder operations
  Future<bool> updateCustomerReminder({
    required String customerId,
    required bool reminderEnabled,
    DateTime? reminderDate,
    String? reminderTime,
  }) async {
    if (_authController.currentUser.value == null) return false;

    isLoading.value = true;
    try {
      final userId = _authController.currentUser.value!.userId;
      final customer = await _firestoreService.getCustomer(userId, customerId);

      if (customer == null) return false;

      // Cancel old reminder if it existed
      if (customer.customerReminderEnabled) {
        await _notificationService.cancelCustomerBalanceReminder(customerId);
      }

      // Update customer
      final updatedCustomer = customer.copyWith(
        customerReminderEnabled: reminderEnabled,
        customerReminderDate: reminderDate,
        customerReminderTime: reminderTime,
      );

      await _firestoreService.updateCustomer(userId, updatedCustomer);

      // Schedule new reminder if enabled
      if (reminderEnabled && reminderDate != null && reminderTime != null) {
        await _notificationService.scheduleCustomerBalanceReminder(
          customerId: customerId,
          customerName: customer.customerName,
          reminderDate: reminderDate,
          reminderTime: reminderTime,
        );
      }

      // Reload customer details
      await loadCustomerDetails(customerId);
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Get upcoming reminders
  Future<List<Map<String, dynamic>>> getUpcomingReminders() async {
    if (_authController.currentUser.value == null) return [];

    try {
      final userId = _authController.currentUser.value!.userId;
      final customers = await _firestoreService.getActiveCustomers(userId);
      final now = DateTime.now();
      final List<Map<String, dynamic>> reminders = [];

      for (final customer in customers) {
        // Check customer-level reminder
        if (customer.hasCustomerReminder && !customer.isCustomerReminderOverdue) {
          final reminderDateTime = DateTime(
            customer.customerReminderDate!.year,
            customer.customerReminderDate!.month,
            customer.customerReminderDate!.day,
            int.parse(customer.customerReminderTime!.split(':')[0]),
            int.parse(customer.customerReminderTime!.split(':')[1]),
          );

          if (reminderDateTime.isAfter(now)) {
            final balance = await _getCustomerBalance(userId, customer.customerId);
            reminders.add({
              'type': 'customer',
              'id': customer.customerId,
              'customerName': customer.customerName,
              'reminderDate': reminderDateTime,
              'amount': balance,
            });
          }
        }

        // Check individual credit entry reminders
        final creditEntries = await _firestoreService.getCreditEntriesByCustomer(userId, customer.customerId);
        for (final entry in creditEntries) {
          if (entry.hasReminder && !entry.isReminderOverdue && !entry.isFullyPaid) {
            final reminderDateTime = DateTime(
              entry.reminderDate!.year,
              entry.reminderDate!.month,
              entry.reminderDate!.day,
              int.parse(entry.reminderTime!.split(':')[0]),
              int.parse(entry.reminderTime!.split(':')[1]),
            );

            if (reminderDateTime.isAfter(now)) {
              reminders.add({
                'type': 'credit_entry',
                'id': entry.creditEntryId,
                'customerName': customer.customerName,
                'reminderDate': reminderDateTime,
                'amount': entry.outstandingAmount,
              });
            }
          }
        }
      }

      // Sort by reminder date
      reminders.sort((a, b) => a['reminderDate'].compareTo(b['reminderDate']));
      return reminders;
    } catch (e) {
      debugPrint('Error getting upcoming reminders: $e');
      return [];
    }
  }

  // Get overdue reminders
  Future<List<Map<String, dynamic>>> getOverdueReminders() async {
    if (_authController.currentUser.value == null) return [];

    try {
      final userId = _authController.currentUser.value!.userId;
      final customers = await _firestoreService.getActiveCustomers(userId);
      final List<Map<String, dynamic>> reminders = [];

      for (final customer in customers) {
        // Check customer-level reminder
        if (customer.hasCustomerReminder && customer.isCustomerReminderOverdue) {
          final balance = await _getCustomerBalance(userId, customer.customerId);
          if (balance > 0) {
            reminders.add({
              'type': 'customer',
              'id': customer.customerId,
              'customerName': customer.customerName,
              'reminderDate': DateTime(
                customer.customerReminderDate!.year,
                customer.customerReminderDate!.month,
                customer.customerReminderDate!.day,
                int.parse(customer.customerReminderTime!.split(':')[0]),
                int.parse(customer.customerReminderTime!.split(':')[1]),
              ),
              'amount': balance,
            });
          }
        }

        // Check individual credit entry reminders
        final creditEntries = await _firestoreService.getCreditEntriesByCustomer(userId, customer.customerId);
        for (final entry in creditEntries) {
          if (entry.hasReminder && entry.isReminderOverdue && !entry.isFullyPaid) {
            reminders.add({
              'type': 'credit_entry',
              'id': entry.creditEntryId,
              'customerName': customer.customerName,
              'reminderDate': DateTime(
                entry.reminderDate!.year,
                entry.reminderDate!.month,
                entry.reminderDate!.day,
                int.parse(entry.reminderTime!.split(':')[0]),
                int.parse(entry.reminderTime!.split(':')[1]),
              ),
              'amount': entry.outstandingAmount,
            });
          }
        }
      }

      // Sort by reminder date (oldest first)
      reminders.sort((a, b) => a['reminderDate'].compareTo(b['reminderDate']));
      return reminders;
    } catch (e) {
      debugPrint('Error getting overdue reminders: $e');
      return [];
    }
  }

  Future<double> _getCustomerBalance(String userId, String customerId) async {
    try {
      final creditEntries = await _firestoreService.getCreditEntriesByCustomer(userId, customerId);
      final payments = await _firestoreService.getPaymentsByCustomer(userId, customerId);

      final totalCredit = creditEntries.fold<double>(0.0, (sum, entry) => sum + entry.amount);
      final totalPayments = payments.fold<double>(0.0, (sum, payment) => sum + payment.paymentAmount);

      return totalCredit - totalPayments;
    } catch (e) {
      return 0.0;
    }
  }

  void refreshData() {
    _loadCustomers();
  }
}
