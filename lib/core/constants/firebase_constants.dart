class FirebaseConstants {
  // Collection Names
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String alertsCollection = 'alerts';
  static const String expensesCollection = 'expenses';

  // Field Names - User
  static const String userIdField = 'userId';
  static const String emailField = 'email';
  static const String displayNameField = 'displayName';
  static const String createdAtField = 'createdAt';
  static const String updatedAtField = 'updatedAt';

  // Field Names - Product
  static const String productNameField = 'productName';
  static const String quantityField = 'quantity';
  static const String expiryDateField = 'expiryDate';
  static const String productImageField = 'productImage';
  static const String categoryField = 'category';
  static const String createdDateField = 'createdDate';
  static const String statusField = 'status';
  static const String remainingDaysField = 'remainingDays';

  // Field Names - Alert
  static const String alertTypeField = 'alertType';
  static const String alertMessageField = 'alertMessage';
  static const String isReadField = 'isRead';
  static const String alertDateField = 'alertDate';

  // Field Names - Expense
  static const String merchantNameField = 'merchantName';
  static const String totalAmountField = 'totalAmount';
  static const String receiptImageField = 'receiptImage';
  static const String expenseDateField = 'expenseDate';
  static const String itemsField = 'items';

  // Expiry Status Values
  static const String statusSafe = 'safe';
  static const String statusExpiringSoon = 'expiring_soon';
  static const String statusExpired = 'expired';

  // Alert Types
  static const String alertTypeExpiry = 'expiry';
  static const String alertTypeExpired = 'expired';
  static const String alertTypeSystem = 'system';
}
