class PaymentModel {
  final String paymentId;
  final String customerId;
  final double paymentAmount;
  final DateTime paymentDate;
  final String? paymentMethod;
  final String? paymentNotes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PaymentModel({
    required this.paymentId,
    required this.customerId,
    required this.paymentAmount,
    required this.paymentDate,
    this.paymentMethod,
    this.paymentNotes,
    required this.createdAt,
    this.updatedAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      paymentId: json['paymentId'] as String,
      customerId: json['customerId'] as String,
      paymentAmount: (json['paymentAmount'] as num).toDouble(),
      paymentDate: DateTime.parse(json['paymentDate'] as String),
      paymentMethod: json['paymentMethod'] as String?,
      paymentNotes: json['paymentNotes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentId': paymentId,
      'customerId': customerId,
      'paymentAmount': paymentAmount,
      'paymentDate': paymentDate.toIso8601String(),
      'paymentMethod': paymentMethod,
      'paymentNotes': paymentNotes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  PaymentModel copyWith({
    String? paymentId,
    String? customerId,
    double? paymentAmount,
    DateTime? paymentDate,
    String? paymentMethod,
    String? paymentNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentModel(
      paymentId: paymentId ?? this.paymentId,
      customerId: customerId ?? this.customerId,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentNotes: paymentNotes ?? this.paymentNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static PaymentModel create({
    required String paymentId,
    required String customerId,
    required double paymentAmount,
    DateTime? paymentDate,
    String? paymentMethod,
    String? paymentNotes,
  }) {
    final now = DateTime.now();
    return PaymentModel(
      paymentId: paymentId,
      customerId: customerId,
      paymentAmount: paymentAmount,
      paymentDate: paymentDate ?? now,
      paymentMethod: paymentMethod,
      paymentNotes: paymentNotes,
      createdAt: now,
      updatedAt: now,
    );
  }
}
