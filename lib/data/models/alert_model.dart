class AlertModel {
  final String alertId;
  final String alertType; // 'product_expiry', 'product_expired', 'task_due', 'task_overdue'
  final String alertMessage;
  final bool isRead;
  final DateTime alertDate;
  final String? referenceId; // productId or taskId
  final String? referenceType; // 'product' or 'task'
  final DateTime? targetDate; // expiryDate or dueDate
  final String? itemName; // productName or taskTitle
  final String? status; // 'active', 'expired', 'overdue'

  AlertModel({
    required this.alertId,
    required this.alertType,
    required this.alertMessage,
    required this.isRead,
    required this.alertDate,
    this.referenceId,
    this.referenceType,
    this.targetDate,
    this.itemName,
    this.status,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      alertId: json['alertId'] as String,
      alertType: json['alertType'] as String,
      alertMessage: json['alertMessage'] as String,
      isRead: json['isRead'] as bool? ?? false,
      alertDate: DateTime.parse(json['alertDate'] as String),
      referenceId: json['referenceId'] as String?,
      referenceType: json['referenceType'] as String?,
      targetDate: json['targetDate'] != null
          ? DateTime.parse(json['targetDate'] as String)
          : null,
      itemName: json['itemName'] as String?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alertId': alertId,
      'alertType': alertType,
      'alertMessage': alertMessage,
      'isRead': isRead,
      'alertDate': alertDate.toIso8601String(),
      'referenceId': referenceId,
      'referenceType': referenceType,
      'targetDate': targetDate?.toIso8601String(),
      'itemName': itemName,
      'status': status,
    };
  }

  AlertModel copyWith({
    String? alertId,
    String? alertType,
    String? alertMessage,
    bool? isRead,
    DateTime? alertDate,
    String? referenceId,
    String? referenceType,
    DateTime? targetDate,
    String? itemName,
    String? status,
  }) {
    return AlertModel(
      alertId: alertId ?? this.alertId,
      alertType: alertType ?? this.alertType,
      alertMessage: alertMessage ?? this.alertMessage,
      isRead: isRead ?? this.isRead,
      alertDate: alertDate ?? this.alertDate,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
      targetDate: targetDate ?? this.targetDate,
      itemName: itemName ?? this.itemName,
      status: status ?? this.status,
    );
  }

  static AlertModel create({
    required String alertId,
    required String alertType,
    required String alertMessage,
    String? referenceId,
    String? referenceType,
    DateTime? targetDate,
    String? itemName,
    String? status,
  }) {
    return AlertModel(
      alertId: alertId,
      alertType: alertType,
      alertMessage: alertMessage,
      isRead: false,
      alertDate: DateTime.now(),
      referenceId: referenceId,
      referenceType: referenceType,
      targetDate: targetDate,
      itemName: itemName,
      status: status,
    );
  }
}
