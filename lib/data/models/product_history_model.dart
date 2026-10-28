class ProductHistoryModel {
  final String historyId;
  final String productId;
  final String productName;
  final String? category;
  final DateTime expiryDate;
  final String status; // 'expiring_soon' or 'expired'
  final DateTime statusEnteredDate;
  final int quantity;
  final String? productImage;

  ProductHistoryModel({
    required this.historyId,
    required this.productId,
    required this.productName,
    this.category,
    required this.expiryDate,
    required this.status,
    required this.statusEnteredDate,
    required this.quantity,
    this.productImage,
  });

  factory ProductHistoryModel.fromJson(Map<String, dynamic> json) {
    return ProductHistoryModel(
      historyId: json['historyId'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      category: json['category'] as String?,
      expiryDate: DateTime.parse(json['expiryDate'] as String),
      status: json['status'] as String,
      statusEnteredDate: DateTime.parse(json['statusEnteredDate'] as String),
      quantity: json['quantity'] as int,
      productImage: json['productImage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'historyId': historyId,
      'productId': productId,
      'productName': productName,
      'category': category,
      'expiryDate': expiryDate.toIso8601String(),
      'status': status,
      'statusEnteredDate': statusEnteredDate.toIso8601String(),
      'quantity': quantity,
      'productImage': productImage,
    };
  }

  ProductHistoryModel copyWith({
    String? historyId,
    String? productId,
    String? productName,
    String? category,
    DateTime? expiryDate,
    String? status,
    DateTime? statusEnteredDate,
    int? quantity,
    String? productImage,
  }) {
    return ProductHistoryModel(
      historyId: historyId ?? this.historyId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      category: category ?? this.category,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status ?? this.status,
      statusEnteredDate: statusEnteredDate ?? this.statusEnteredDate,
      quantity: quantity ?? this.quantity,
      productImage: productImage ?? this.productImage,
    );
  }

  static ProductHistoryModel create({
    required String historyId,
    required String productId,
    required String productName,
    String? category,
    required DateTime expiryDate,
    required String status,
    required int quantity,
    String? productImage,
  }) {
    return ProductHistoryModel(
      historyId: historyId,
      productId: productId,
      productName: productName,
      category: category,
      expiryDate: expiryDate,
      status: status,
      statusEnteredDate: DateTime.now(),
      quantity: quantity,
      productImage: productImage,
    );
  }
}
