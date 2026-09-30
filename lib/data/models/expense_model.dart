class ExpenseModel {
  final String expenseId;
  final String merchantName;
  final double totalAmount;
  final String? receiptImage;
  final DateTime expenseDate;
  final List<String>? items;
  final DateTime createdDate;

  ExpenseModel({
    required this.expenseId,
    required this.merchantName,
    required this.totalAmount,
    this.receiptImage,
    required this.expenseDate,
    this.items,
    required this.createdDate,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      expenseId: json['expenseId'] as String,
      merchantName: json['merchantName'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      receiptImage: json['receiptImage'] as String?,
      expenseDate: DateTime.parse(json['expenseDate'] as String),
      items: (json['items'] as List<dynamic>?)?.cast<String>(),
      createdDate: DateTime.parse(json['createdDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'expenseId': expenseId,
      'merchantName': merchantName,
      'totalAmount': totalAmount,
      'receiptImage': receiptImage,
      'expenseDate': expenseDate.toIso8601String(),
      'items': items,
      'createdDate': createdDate.toIso8601String(),
    };
  }

  ExpenseModel copyWith({
    String? expenseId,
    String? merchantName,
    double? totalAmount,
    String? receiptImage,
    DateTime? expenseDate,
    List<String>? items,
    DateTime? createdDate,
  }) {
    return ExpenseModel(
      expenseId: expenseId ?? this.expenseId,
      merchantName: merchantName ?? this.merchantName,
      totalAmount: totalAmount ?? this.totalAmount,
      receiptImage: receiptImage ?? this.receiptImage,
      expenseDate: expenseDate ?? this.expenseDate,
      items: items ?? this.items,
      createdDate: createdDate ?? this.createdDate,
    );
  }

  static ExpenseModel create({
    required String expenseId,
    required String merchantName,
    required double totalAmount,
    String? receiptImage,
    required DateTime expenseDate,
    List<String>? items,
  }) {
    return ExpenseModel(
      expenseId: expenseId,
      merchantName: merchantName,
      totalAmount: totalAmount,
      receiptImage: receiptImage,
      expenseDate: expenseDate,
      items: items,
      createdDate: DateTime.now(),
    );
  }
}
