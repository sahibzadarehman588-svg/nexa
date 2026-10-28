class CreditEntryModel {
  final String creditEntryId;
  final String customerId;
  final double amount;
  final DateTime transactionDate;
  final String? itemDescription;
  final String? itemName;
  final int? itemQuantity;
  final String? itemUnit;
  final double? itemPrice;
  final String? creditNotes;
  final bool reminderEnabled;
  final DateTime? reminderDate;
  final String? reminderTime;
  final bool isPaid;
  final double paidAmount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CreditEntryModel({
    required this.creditEntryId,
    required this.customerId,
    required this.amount,
    required this.transactionDate,
    this.itemDescription,
    this.itemName,
    this.itemQuantity,
    this.itemUnit,
    this.itemPrice,
    this.creditNotes,
    this.reminderEnabled = false,
    this.reminderDate,
    this.reminderTime,
    this.isPaid = false,
    this.paidAmount = 0.0,
    required this.createdAt,
    this.updatedAt,
  });

  factory CreditEntryModel.fromJson(Map<String, dynamic> json) {
    return CreditEntryModel(
      creditEntryId: json['creditEntryId'] as String,
      customerId: json['customerId'] as String,
      amount: (json['amount'] as num).toDouble(),
      transactionDate: DateTime.parse(json['transactionDate'] as String),
      itemDescription: json['itemDescription'] as String?,
      itemName: json['itemName'] as String?,
      itemQuantity: json['itemQuantity'] as int?,
      itemUnit: json['itemUnit'] as String?,
      itemPrice: json['itemPrice'] != null
          ? (json['itemPrice'] as num).toDouble()
          : null,
      creditNotes: json['creditNotes'] as String?,
      reminderEnabled: json['reminderEnabled'] as bool? ?? false,
      reminderDate: json['reminderDate'] != null
          ? DateTime.parse(json['reminderDate'] as String)
          : null,
      reminderTime: json['reminderTime'] as String?,
      isPaid: json['isPaid'] as bool? ?? false,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'creditEntryId': creditEntryId,
      'customerId': customerId,
      'amount': amount,
      'transactionDate': transactionDate.toIso8601String(),
      'itemDescription': itemDescription,
      'itemName': itemName,
      'itemQuantity': itemQuantity,
      'itemUnit': itemUnit,
      'itemPrice': itemPrice,
      'creditNotes': creditNotes,
      'reminderEnabled': reminderEnabled,
      'reminderDate': reminderDate?.toIso8601String(),
      'reminderTime': reminderTime,
      'isPaid': isPaid,
      'paidAmount': paidAmount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  CreditEntryModel copyWith({
    String? creditEntryId,
    String? customerId,
    double? amount,
    DateTime? transactionDate,
    String? itemDescription,
    String? itemName,
    int? itemQuantity,
    String? itemUnit,
    double? itemPrice,
    String? creditNotes,
    bool? reminderEnabled,
    DateTime? reminderDate,
    String? reminderTime,
    bool? isPaid,
    double? paidAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CreditEntryModel(
      creditEntryId: creditEntryId ?? this.creditEntryId,
      customerId: customerId ?? this.customerId,
      amount: amount ?? this.amount,
      transactionDate: transactionDate ?? this.transactionDate,
      itemDescription: itemDescription ?? this.itemDescription,
      itemName: itemName ?? this.itemName,
      itemQuantity: itemQuantity ?? this.itemQuantity,
      itemUnit: itemUnit ?? this.itemUnit,
      itemPrice: itemPrice ?? this.itemPrice,
      creditNotes: creditNotes ?? this.creditNotes,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderDate: reminderDate ?? this.reminderDate,
      reminderTime: reminderTime ?? this.reminderTime,
      isPaid: isPaid ?? this.isPaid,
      paidAmount: paidAmount ?? this.paidAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static CreditEntryModel create({
    required String creditEntryId,
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
  }) {
    final now = DateTime.now();
    return CreditEntryModel(
      creditEntryId: creditEntryId,
      customerId: customerId,
      amount: amount,
      transactionDate: transactionDate ?? now,
      itemDescription: itemDescription,
      itemName: itemName,
      itemQuantity: itemQuantity,
      itemUnit: itemUnit,
      itemPrice: itemPrice,
      creditNotes: creditNotes,
      reminderEnabled: reminderEnabled,
      reminderDate: reminderDate,
      reminderTime: reminderTime,
      isPaid: false,
      paidAmount: 0.0,
      createdAt: now,
      updatedAt: now,
    );
  }

  double get outstandingAmount {
    return amount - paidAmount;
  }

  bool get isFullyPaid {
    return paidAmount >= amount;
  }

  bool get isPartiallyPaid {
    return paidAmount > 0 && paidAmount < amount;
  }

  bool get hasReminder {
    return reminderEnabled &&
        reminderDate != null &&
        reminderTime != null;
  }

  bool get isReminderOverdue {
    if (!hasReminder) return false;
    final reminderDateTime = DateTime(
      reminderDate!.year,
      reminderDate!.month,
      reminderDate!.day,
      int.parse(reminderTime!.split(':')[0]),
      int.parse(reminderTime!.split(':')[1]),
    );
    return reminderDateTime.isBefore(DateTime.now());
  }

  bool get hasItemDetails {
    return itemName != null &&
        itemName!.isNotEmpty &&
        itemQuantity != null &&
        itemQuantity! > 0;
  }
}
