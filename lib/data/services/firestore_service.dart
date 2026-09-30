import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/alert_model.dart';
import '../models/expense_model.dart';
import '../../core/constants/firebase_constants.dart';

abstract class FirestoreServiceInterface {
  // User operations
  Future<void> createUser(UserModel user);
  Future<UserModel?> getUser(String userId);
  Future<void> updateUser(UserModel user);

  // Product operations
  Future<String> createProduct(String userId, ProductModel product);
  Future<ProductModel?> getProduct(String userId, String productId);
  Future<List<ProductModel>> getProducts(String userId);
  Future<List<ProductModel>> getExpiringSoonProducts(String userId);
  Future<List<ProductModel>> getExpiredProducts(String userId);
  Future<void> updateProduct(String userId, ProductModel product);
  Future<void> deleteProduct(String userId, String productId);

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

  // Product operations
  @override
  Future<String> createProduct(String userId, ProductModel product) async {
    try {
      final docRef = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.productsCollection)
          .add(product.toJson());

      return docRef.id;
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
      final querySnapshot = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.productsCollection)
          .where(FirebaseConstants.statusField, isEqualTo: FirebaseConstants.statusExpiringSoon)
          .orderBy(FirebaseConstants.expiryDateField)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['productId'] = doc.id;
        return ProductModel.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get expiring soon products: $e');
    }
  }

  @override
  Future<List<ProductModel>> getExpiredProducts(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.productsCollection)
          .where(FirebaseConstants.statusField, isEqualTo: FirebaseConstants.statusExpired)
          .orderBy(FirebaseConstants.expiryDateField, descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['productId'] = doc.id;
        return ProductModel.fromJson(data);
      }).toList();
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
}
