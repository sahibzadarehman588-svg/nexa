import '../../core/utils/date_utils.dart' as utils;
import '../../core/constants/firebase_constants.dart';

class ProductModel {
  final String productId;
  final String productName;
  final int quantity;
  final DateTime expiryDate;
  final String? productImage;
  final String? category;
  final DateTime createdDate;
  final String status;
  final int remainingDays;

  ProductModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.expiryDate,
    this.productImage,
    this.category,
    required this.createdDate,
    required this.status,
    required this.remainingDays,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final expiryDate = DateTime.parse(json['expiryDate'] as String);
    final createdDate = DateTime.parse(json['createdDate'] as String);

    return ProductModel(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      quantity: json['quantity'] as int,
      expiryDate: expiryDate,
      productImage: json['productImage'] as String?,
      category: json['category'] as String?,
      createdDate: createdDate,
      status: json['status'] as String? ?? FirebaseConstants.statusSafe,
      remainingDays: json['remainingDays'] as int? ?? utils.DateUtils.calculateRemainingDays(expiryDate),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'expiryDate': expiryDate.toIso8601String(),
      'productImage': productImage,
      'category': category,
      'createdDate': createdDate.toIso8601String(),
      'status': status,
      'remainingDays': remainingDays,
    };
  }

  ProductModel copyWith({
    String? productId,
    String? productName,
    int? quantity,
    DateTime? expiryDate,
    String? productImage,
    String? category,
    DateTime? createdDate,
    String? status,
    int? remainingDays,
  }) {
    return ProductModel(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      expiryDate: expiryDate ?? this.expiryDate,
      productImage: productImage ?? this.productImage,
      category: category ?? this.category,
      createdDate: createdDate ?? this.createdDate,
      status: status ?? this.status,
      remainingDays: remainingDays ?? this.remainingDays,
    );
  }

  static ProductModel create({
    required String productId,
    required String productName,
    required int quantity,
    required DateTime expiryDate,
    String? productImage,
    String? category,
  }) {
    final now = DateTime.now();
    final remainingDays = utils.DateUtils.calculateRemainingDays(expiryDate);
    final status = utils.DateUtils.getExpiryStatus(expiryDate);

    return ProductModel(
      productId: productId,
      productName: productName,
      quantity: quantity,
      expiryDate: expiryDate,
      productImage: productImage,
      category: category,
      createdDate: now,
      status: status,
      remainingDays: remainingDays,
    );
  }

  static ProductModel updateStatus(ProductModel product) {
    final remainingDays = utils.DateUtils.calculateRemainingDays(product.expiryDate);
    final status = utils.DateUtils.getExpiryStatus(product.expiryDate);

    return product.copyWith(
      status: status,
      remainingDays: remainingDays,
    );
  }
}
