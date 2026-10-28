class FirebaseConstants {
  // Collection Names
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String productHistoryCollection = 'product_history';
  static const String alertsCollection = 'alerts';
  static const String expensesCollection = 'expenses';
  static const String tasksCollection = 'tasks';
  static const String customersCollection = 'customers';
  static const String creditEntriesCollection = 'credit_entries';
  static const String paymentsCollection = 'payments';

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

  // Field Names - Product History
  static const String historyIdField = 'historyId';
  static const String productIdField = 'productId';
  static const String statusEnteredDateField = 'statusEnteredDate';

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

  // Field Names - Task
  static const String taskIdField = 'taskId';
  static const String titleField = 'title';
  static const String descriptionField = 'description';
  static const String priorityField = 'priority';
  static const String dueDateField = 'dueDate';
  static const String isCompletedField = 'isCompleted';
  static const String taskCreatedAtField = 'createdAt';

  // Field Names - Customer
  static const String customerNameField = 'customerName';
  static const String customerPhoneField = 'customerPhone';
  static const String customerAddressField = 'customerAddress';
  static const String customerNotesField = 'customerNotes';
  static const String isArchivedField = 'isArchived';
  static const String customerReminderEnabledField = 'customerReminderEnabled';
  static const String customerReminderDateField = 'customerReminderDate';
  static const String customerReminderTimeField = 'customerReminderTime';

  // Field Names - Credit Entry
  static const String creditEntryIdField = 'creditEntryId';
  static const String amountField = 'amount';
  static const String itemDescriptionField = 'itemDescription';
  static const String itemNameField = 'itemName';
  static const String itemQuantityField = 'itemQuantity';
  static const String itemUnitField = 'itemUnit';
  static const String itemPriceField = 'itemPrice';
  static const String creditNotesField = 'creditNotes';
  static const String reminderEnabledField = 'reminderEnabled';
  static const String reminderDateField = 'reminderDate';
  static const String reminderTimeField = 'reminderTime';
  static const String isPaidField = 'isPaid';
  static const String paidAmountField = 'paidAmount';

  // Field Names - Payment
  static const String paymentIdField = 'paymentId';
  static const String paymentAmountField = 'paymentAmount';
  static const String paymentMethodField = 'paymentMethod';
  static const String paymentNotesField = 'paymentNotes';
  static const String paymentDateField = 'paymentDate';

  // Expiry Status Values
  static const String statusSafe = 'safe';
  static const String statusExpiringSoon = 'expiring_soon';
  static const String statusExpired = 'expired';

  // Alert Types
  static const String alertTypeExpiry = 'expiry';
  static const String alertTypeExpired = 'expired';
  static const String alertTypeSystem = 'system';
}
