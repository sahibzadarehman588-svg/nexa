import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/product_history_model.dart';
import '../models/alert_model.dart';
import '../models/expense_model.dart';
import '../models/task_model.dart';
import '../models/customer_model.dart';
import '../models/credit_entry_model.dart';
import '../models/payment_model.dart';
import '../../core/constants/firebase_constants.dart';

abstract class FirestoreServiceInterface {
  // User operations
  Future<void> createUser(UserModel user);
  Future<UserModel?> getUser(String userId);
  Future<UserModel?> getUserBySecretPassword(String secretPassword);
  Future<void> updateUser(UserModel user);

  // Product operations
  Future<String> createProduct(String userId, ProductModel product);
  Future<ProductModel?> getProduct(String userId, String productId);
  Future<List<ProductModel>> getProducts(String userId);
  Future<List<ProductModel>> getExpiringSoonProducts(String userId);
  Future<List<ProductModel>> getExpiredProducts(String userId);
  Future<void> updateProduct(String userId, ProductModel product);
  Future<void> deleteProduct(String userId, String productId);

  // Product History operations
  Future<String> createProductHistory(String userId, ProductHistoryModel history);
  Future<List<ProductHistoryModel>> getProductHistory(String userId, String status);
  Future<void> deleteProductHistory(String userId, String historyId);

  // Alert operations
  Future<String> createAlert(String userId, AlertModel alert);
  Future<List<AlertModel>> getAlerts(String userId);
  Future<void> markAlertAsRead(String userId, String alertId);
  Future<void> deleteAlert(String userId, String alertId);

  // Expense operations
  Future<String> createExpense(String userId, ExpenseModel expense);
  Future<ExpenseModel?> getExpense(String userId, String expenseId);
  Future<List<ExpenseModel>> getExpenses(String userId);
  Future<void> updateExpense(String userId, ExpenseModel expense);
  Future<void> deleteExpense(String userId, String expenseId);

  // Task operations
  Future<String> createTask(String userId, TaskModel task);
  Future<TaskModel?> getTask(String userId, String taskId);
  Future<List<TaskModel>> getTasks(String userId);
  Future<List<TaskModel>> getPendingTasks(String userId);
  Future<List<TaskModel>> getCompletedTasks(String userId);
  Future<void> updateTask(String userId, TaskModel task);
  Future<void> deleteTask(String userId, String taskId);

  // Customer operations
  Future<String> createCustomer(String userId, CustomerModel customer);
  Future<CustomerModel?> getCustomer(String userId, String customerId);
  Future<List<CustomerModel>> getCustomers(String userId);
  Future<List<CustomerModel>> getActiveCustomers(String userId);
  Future<List<CustomerModel>> getArchivedCustomers(String userId);
  Future<void> updateCustomer(String userId, CustomerModel customer);
  Future<void> archiveCustomer(String userId, String customerId);
  Future<void> unarchiveCustomer(String userId, String customerId);
  Future<void> deleteCustomer(String userId, String customerId);

  // Credit Entry operations
  Future<String> createCreditEntry(String userId, CreditEntryModel creditEntry);
  Future<CreditEntryModel?> getCreditEntry(String userId, String creditEntryId);
  Future<List<CreditEntryModel>> getCreditEntriesByCustomer(String userId, String customerId);
  Future<List<CreditEntryModel>> getUnpaidCreditEntries(String userId, String customerId);
  Future<void> updateCreditEntry(String userId, CreditEntryModel creditEntry);
  Future<void> deleteCreditEntry(String userId, String creditEntryId);

  // Payment operations
  Future<String> createPayment(String userId, PaymentModel payment);
  Future<PaymentModel?> getPayment(String userId, String paymentId);
  Future<List<PaymentModel>> getPaymentsByCustomer(String userId, String customerId);
  Future<void> updatePayment(String userId, PaymentModel payment);
  Future<void> deletePayment(String userId, String paymentId);
}

class FirestoreService implements FirestoreServiceInterface {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User operations
  @override
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(user.userId)
          .set(user.toJson());
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  @override
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .get();

      if (!doc.exists) return null;

      return UserModel.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  @override
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(user.userId)
          .update(user.toJson());
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  @override
  Future<UserModel?> getUserBySecretPassword(String secretPassword) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .where('secretPassword', isEqualTo: secretPassword)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      return UserModel.fromJson(querySnapshot.docs.first.data());
    } catch (e) {
      throw Exception('Failed to get user by secret password: $e');
    }
  }

  // Product operations
  @override
  Future<String> createProduct(String userId, ProductModel product) async {
    try {
      // Check if user document exists first
      final userDoc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        throw Exception('User document does not exist. Please ensure you are logged in properly.');
      }

      // Use the product's productId as the document ID
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.productsCollection)
          .doc(product.productId)
          .set(product.toJson());

      return product.productId;
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  @override
  Future<ProductModel?> getProduct(String userId, String productId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.productsCollection)
          .doc(productId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      data['productId'] = doc.id;
      return ProductModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get product: $e');
    }
  }

  @override
  Future<List<ProductModel>> getProducts(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.productsCollection)
          .orderBy(FirebaseConstants.createdDateField, descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['productId'] = doc.id;
        return ProductModel.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get products: $e');
    }
  }

  @override
  Future<List<ProductModel>> getExpiringSoonProducts(String userId) async {
    try {
      // Get all products and filter on client side for accurate date comparison
      final allProducts = await getProducts(userId);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final warningDate = today.add(const Duration(days: 7));

      final expiringSoonProducts = allProducts.where((product) {
        final productDate = DateTime(product.expiryDate.year, product.expiryDate.month, product.expiryDate.day);
        return productDate.isAtSameMomentAs(tomorrow) || 
               (productDate.isAfter(tomorrow) && productDate.isBefore(warningDate)) || 
               productDate.isAtSameMomentAs(warningDate);
      }).toList();

      // Sort by expiry date ascending
      expiringSoonProducts.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
      
      return expiringSoonProducts;
    } catch (e) {
      throw Exception('Failed to get expiring soon products: $e');
    }
  }

  @override
  Future<List<ProductModel>> getExpiredProducts(String userId) async {
    try {
      // Get all products and filter on client side for accurate date comparison
      final allProducts = await getProducts(userId);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      final expiredProducts = allProducts.where((product) {
        final productDate = DateTime(product.expiryDate.year, product.expiryDate.month, product.expiryDate.day);
        return productDate.isBefore(tomorrow);
      }).toList();

      // Sort by expiry date descending
      expiredProducts.sort((a, b) => b.expiryDate.compareTo(a.expiryDate));
      
      return expiredProducts;
    } catch (e) {
      throw Exception('Failed to get expired products: $e');
    }
  }

  @override
  Future<void> updateProduct(String userId, ProductModel product) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.productsCollection)
          .doc(product.productId)
          .update(product.toJson());
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  @override
  Future<void> deleteProduct(String userId, String productId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.productsCollection)
          .doc(productId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  // Product History operations
  @override
  Future<String> createProductHistory(String userId, ProductHistoryModel history) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.productHistoryCollection)
          .doc(history.historyId)
          .set(history.toJson());

      return history.historyId;
    } catch (e) {
      throw Exception('Failed to create product history: $e');
    }
  }

  @override
  Future<List<ProductHistoryModel>> getProductHistory(String userId, String status) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.productHistoryCollection)
          .where(FirebaseConstants.statusField, isEqualTo: status)
          .get();

      final historyList = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['historyId'] = doc.id;
        return ProductHistoryModel.fromJson(data);
      }).toList();

      // Sort by statusEnteredDate in descending order on client side
      historyList.sort((a, b) => b.statusEnteredDate.compareTo(a.statusEnteredDate));

      return historyList;
    } catch (e) {
      throw Exception('Failed to get product history: $e');
    }
  }

  @override
  Future<void> deleteProductHistory(String userId, String historyId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.productHistoryCollection)
          .doc(historyId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete product history: $e');
    }
  }

  // Alert operations
  @override
  Future<String> createAlert(String userId, AlertModel alert) async {
    try {
      final docRef = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.alertsCollection)
          .add(alert.toJson());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create alert: $e');
    }
  }

  @override
  Future<List<AlertModel>> getAlerts(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.alertsCollection)
          .orderBy(FirebaseConstants.alertDateField, descending: true)
          .limit(50)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['alertId'] = doc.id;
        return AlertModel.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get alerts: $e');
    }
  }

  @override
  Future<void> markAlertAsRead(String userId, String alertId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.alertsCollection)
          .doc(alertId)
          .update({FirebaseConstants.isReadField: true});
    } catch (e) {
      throw Exception('Failed to mark alert as read: $e');
    }
  }

  @override
  Future<void> deleteAlert(String userId, String alertId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.alertsCollection)
          .doc(alertId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete alert: $e');
    }
  }

  // Expense operations
  @override
  Future<String> createExpense(String userId, ExpenseModel expense) async {
    try {
      final docRef = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.expensesCollection)
          .add(expense.toJson());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create expense: $e');
    }
  }

  @override
  Future<ExpenseModel?> getExpense(String userId, String expenseId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.expensesCollection)
          .doc(expenseId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      data['expenseId'] = doc.id;
      return ExpenseModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get expense: $e');
    }
  }

  @override
  Future<List<ExpenseModel>> getExpenses(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.expensesCollection)
          .orderBy(FirebaseConstants.expenseDateField, descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['expenseId'] = doc.id;
        return ExpenseModel.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get expenses: $e');
    }
  }

  @override
  Future<void> updateExpense(String userId, ExpenseModel expense) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.expensesCollection)
          .doc(expense.expenseId)
          .update(expense.toJson());
    } catch (e) {
      throw Exception('Failed to update expense: $e');
    }
  }

  @override
  Future<void> deleteExpense(String userId, String expenseId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.expensesCollection)
          .doc(expenseId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete expense: $e');
    }
  }

  // Task operations
  @override
  Future<String> createTask(String userId, TaskModel task) async {
    debugPrint('=== FirestoreService: createTask START ===');
    debugPrint('📱 User ID: $userId');
    debugPrint('🆔 Task ID: ${task.taskId}');
    debugPrint('📝 Task data: ${task.toJson()}');

    try {
      // Check if user document exists first
      debugPrint('🔍 Checking user document existence...');
      final userDoc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .get();

      debugPrint('📄 User document exists: ${userDoc.exists}');

      if (!userDoc.exists) {
        debugPrint('❌ User document does not exist');
        throw Exception('User document does not exist. Please ensure you are logged in properly.');
      }

      // Use the task's taskId as the document ID
      debugPrint('💾 Writing task to Firestore...');
      debugPrint('📂 Collection path: ${FirebaseConstants.usersCollection}/$userId/${FirebaseConstants.tasksCollection}/${task.taskId}');

      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.tasksCollection)
          .doc(task.taskId)
          .set(task.toJson());

      debugPrint('✅ Task written to Firestore successfully');
      debugPrint('=== FirestoreService: createTask END ===');
      return task.taskId;
    } catch (e, stackTrace) {
      debugPrint('❌ Error in createTask: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      throw Exception('Failed to create task: $e');
    }
  }

  @override
  Future<TaskModel?> getTask(String userId, String taskId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.tasksCollection)
          .doc(taskId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      data['taskId'] = doc.id;
      return TaskModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get task: $e');
    }
  }

  @override
  Future<List<TaskModel>> getTasks(String userId) async {
    debugPrint('=== FirestoreService: getTasks START ===');
    debugPrint('📱 User ID: $userId');

    try {
      debugPrint('🔍 Querying tasks collection...');
      final querySnapshot = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.tasksCollection)
          .orderBy(FirebaseConstants.taskCreatedAtField, descending: true)
          .get();

      debugPrint('📋 Retrieved ${querySnapshot.docs.length} documents');

      final tasks = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['taskId'] = doc.id;
        return TaskModel.fromJson(data);
      }).toList();

      debugPrint('✅ Parsed ${tasks.length} tasks');
      debugPrint('=== FirestoreService: getTasks END ===');
      return tasks;
    } catch (e, stackTrace) {
      debugPrint('❌ Error in getTasks: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      throw Exception('Failed to get tasks: $e');
    }
  }

  @override
  Future<List<TaskModel>> getPendingTasks(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.tasksCollection)
          .where(FirebaseConstants.isCompletedField, isEqualTo: false)
          .orderBy(FirebaseConstants.dueDateField)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['taskId'] = doc.id;
        return TaskModel.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get pending tasks: $e');
    }
  }

  @override
  Future<List<TaskModel>> getCompletedTasks(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.tasksCollection)
          .where(FirebaseConstants.isCompletedField, isEqualTo: true)
          .orderBy(FirebaseConstants.createdAtField, descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['taskId'] = doc.id;
        return TaskModel.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get completed tasks: $e');
    }
  }

  @override
  Future<void> updateTask(String userId, TaskModel task) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.tasksCollection)
          .doc(task.taskId)
          .update(task.toJson());
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  @override
  Future<void> deleteTask(String userId, String taskId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.tasksCollection)
          .doc(taskId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  // Customer operations
  @override
  Future<String> createCustomer(String userId, CustomerModel customer) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.customersCollection)
          .doc(customer.customerId)
          .set(customer.toJson());

      return customer.customerId;
    } catch (e) {
      throw Exception('Failed to create customer: $e');
    }
  }

  @override
  Future<CustomerModel?> getCustomer(String userId, String customerId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.customersCollection)
          .doc(customerId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      data['customerId'] = doc.id;
      return CustomerModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get customer: $e');
    }
  }

  @override
  Future<List<CustomerModel>> getCustomers(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.customersCollection)
          .orderBy(FirebaseConstants.createdAtField, descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['customerId'] = doc.id;
        return CustomerModel.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get customers: $e');
    }
  }

  @override
  Future<List<CustomerModel>> getActiveCustomers(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.customersCollection)
          .where(FirebaseConstants.isArchivedField, isEqualTo: false)
          .orderBy(FirebaseConstants.createdAtField, descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['customerId'] = doc.id;
        return CustomerModel.fromJson(data);
      }).toList();
    } catch (e) {
      String errorMsg = 'Failed to get active customers';
      if (e.toString().contains('failed-precondition')) {
        errorMsg += '. Firestore index required. Deploy indexes with: firebase deploy --only firestore:indexes';
      }
      throw Exception('$errorMsg: $e');
    }
  }

  @override
  Future<List<CustomerModel>> getArchivedCustomers(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.customersCollection)
          .where(FirebaseConstants.isArchivedField, isEqualTo: true)
          .orderBy(FirebaseConstants.createdAtField, descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['customerId'] = doc.id;
        return CustomerModel.fromJson(data);
      }).toList();
    } catch (e) {
      String errorMsg = 'Failed to get archived customers';
      if (e.toString().contains('failed-precondition')) {
        errorMsg += '. Firestore index required. Deploy indexes with: firebase deploy --only firestore:indexes';
      }
      throw Exception('$errorMsg: $e');
    }
  }

  @override
  Future<void> updateCustomer(String userId, CustomerModel customer) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.customersCollection)
          .doc(customer.customerId)
          .update(customer.copyWith(updatedAt: DateTime.now()).toJson());
    } catch (e) {
      throw Exception('Failed to update customer: $e');
    }
  }

  @override
  Future<void> archiveCustomer(String userId, String customerId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.customersCollection)
          .doc(customerId)
          .update({
            FirebaseConstants.isArchivedField: true,
            FirebaseConstants.updatedAtField: DateTime.now().toIso8601String(),
          });
    } catch (e) {
      throw Exception('Failed to archive customer: $e');
    }
  }

  @override
  Future<void> unarchiveCustomer(String userId, String customerId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.customersCollection)
          .doc(customerId)
          .update({
            FirebaseConstants.isArchivedField: false,
            FirebaseConstants.updatedAtField: DateTime.now().toIso8601String(),
          });
    } catch (e) {
      throw Exception('Failed to unarchive customer: $e');
    }
  }

  @override
  Future<void> deleteCustomer(String userId, String customerId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.customersCollection)
          .doc(customerId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete customer: $e');
    }
  }

  // Credit Entry operations
  @override
  Future<String> createCreditEntry(String userId, CreditEntryModel creditEntry) async {
    try {
      // Check if user document exists first
      final userDoc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        throw Exception('User document does not exist. Please ensure you are logged in properly.');
      }

      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.creditEntriesCollection)
          .doc(creditEntry.creditEntryId)
          .set(creditEntry.toJson());

      return creditEntry.creditEntryId;
    } catch (e) {
      throw Exception('Failed to create credit entry: $e');
    }
  }

  @override
  Future<CreditEntryModel?> getCreditEntry(String userId, String creditEntryId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.creditEntriesCollection)
          .doc(creditEntryId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      data['creditEntryId'] = doc.id;
      return CreditEntryModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get credit entry: $e');
    }
  }

  @override
  Future<List<CreditEntryModel>> getCreditEntriesByCustomer(String userId, String customerId) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.creditEntriesCollection)
          .where('customerId', isEqualTo: customerId)
          .orderBy(FirebaseConstants.createdAtField, descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['creditEntryId'] = doc.id;
        return CreditEntryModel.fromJson(data);
      }).toList();
    } catch (e) {
      String errorMsg = 'Failed to get credit entries';
      if (e.toString().contains('failed-precondition')) {
        errorMsg += '. Firestore index required. Deploy indexes with: firebase deploy --only firestore:indexes';
      }
      throw Exception('$errorMsg: $e');
    }
  }

  @override
  Future<List<CreditEntryModel>> getUnpaidCreditEntries(String userId, String customerId) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.creditEntriesCollection)
          .where('customerId', isEqualTo: customerId)
          .where(FirebaseConstants.isPaidField, isEqualTo: false)
          .orderBy(FirebaseConstants.createdAtField, descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['creditEntryId'] = doc.id;
        return CreditEntryModel.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get unpaid credit entries: $e');
    }
  }

  @override
  Future<void> updateCreditEntry(String userId, CreditEntryModel creditEntry) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.creditEntriesCollection)
          .doc(creditEntry.creditEntryId)
          .update(creditEntry.copyWith(updatedAt: DateTime.now()).toJson());
    } catch (e) {
      throw Exception('Failed to update credit entry: $e');
    }
  }

  @override
  Future<void> deleteCreditEntry(String userId, String creditEntryId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.creditEntriesCollection)
          .doc(creditEntryId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete credit entry: $e');
    }
  }

  // Payment operations
  @override
  Future<String> createPayment(String userId, PaymentModel payment) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.paymentsCollection)
          .doc(payment.paymentId)
          .set(payment.toJson());

      return payment.paymentId;
    } catch (e) {
      throw Exception('Failed to create payment: $e');
    }
  }

  @override
  Future<PaymentModel?> getPayment(String userId, String paymentId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.paymentsCollection)
          .doc(paymentId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      data['paymentId'] = doc.id;
      return PaymentModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get payment: $e');
    }
  }

  @override
  Future<List<PaymentModel>> getPaymentsByCustomer(String userId, String customerId) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.paymentsCollection)
          .where('customerId', isEqualTo: customerId)
          .orderBy(FirebaseConstants.paymentDateField, descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['paymentId'] = doc.id;
        return PaymentModel.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get payments: $e');
    }
  }

  @override
  Future<void> updatePayment(String userId, PaymentModel payment) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.paymentsCollection)
          .doc(payment.paymentId)
          .update(payment.copyWith(updatedAt: DateTime.now()).toJson());
    } catch (e) {
      throw Exception('Failed to update payment: $e');
    }
  }

  @override
  Future<void> deletePayment(String userId, String paymentId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.paymentsCollection)
          .doc(paymentId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete payment: $e');
    }
  }
}
