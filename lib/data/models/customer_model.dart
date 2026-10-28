class CustomerModel {
  final String customerId;
  final String customerName;
  final String? customerPhone;
  final String? customerAddress;
  final String? customerNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isArchived;
  final bool customerReminderEnabled;
  final DateTime? customerReminderDate;
  final String? customerReminderTime;

  CustomerModel({
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    this.customerAddress,
    this.customerNotes,
    required this.createdAt,
    required this.updatedAt,
    this.isArchived = false,
    this.customerReminderEnabled = false,
    this.customerReminderDate,
    this.customerReminderTime,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      customerId: json['customerId'] as String,
      customerName: json['customerName'] as String,
      customerPhone: json['customerPhone'] as String?,
      customerAddress: json['customerAddress'] as String?,
      customerNotes: json['customerNotes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isArchived: json['isArchived'] as bool? ?? false,
      customerReminderEnabled: json['customerReminderEnabled'] as bool? ?? false,
      customerReminderDate: json['customerReminderDate'] != null
          ? DateTime.parse(json['customerReminderDate'] as String)
          : null,
      customerReminderTime: json['customerReminderTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'customerNotes': customerNotes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isArchived': isArchived,
      'customerReminderEnabled': customerReminderEnabled,
      'customerReminderDate': customerReminderDate?.toIso8601String(),
      'customerReminderTime': customerReminderTime,
    };
  }

  CustomerModel copyWith({
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    String? customerNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isArchived,
    bool? customerReminderEnabled,
    DateTime? customerReminderDate,
    String? customerReminderTime,
  }) {
    return CustomerModel(
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      customerNotes: customerNotes ?? this.customerNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
      customerReminderEnabled: customerReminderEnabled ?? this.customerReminderEnabled,
      customerReminderDate: customerReminderDate ?? this.customerReminderDate,
      customerReminderTime: customerReminderTime ?? this.customerReminderTime,
    );
  }

  static CustomerModel create({
    required String customerId,
    required String customerName,
    String? customerPhone,
    String? customerAddress,
    String? customerNotes,
  }) {
    final now = DateTime.now();
    return CustomerModel(
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      customerNotes: customerNotes,
      createdAt: now,
      updatedAt: now,
      isArchived: false,
      customerReminderEnabled: false,
    );
  }

  bool get hasCustomerReminder {
    return customerReminderEnabled &&
        customerReminderDate != null &&
        customerReminderTime != null;
  }

  bool get isCustomerReminderOverdue {
    if (!hasCustomerReminder) return false;
    final reminderDateTime = DateTime(
      customerReminderDate!.year,
      customerReminderDate!.month,
      customerReminderDate!.day,
      int.parse(customerReminderTime!.split(':')[0]),
      int.parse(customerReminderTime!.split(':')[1]),
    );
    return reminderDateTime.isBefore(DateTime.now());
  }
}
