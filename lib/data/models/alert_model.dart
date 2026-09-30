class AlertModel {
  final String alertId;
  final String alertType;
  final String alertMessage;
  final bool isRead;
  final DateTime alertDate;

  AlertModel({
    required this.alertId,
    required this.alertType,
    required this.alertMessage,
    required this.isRead,
    required this.alertDate,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      alertId: json['alertId'] as String,
      alertType: json['alertType'] as String,
      alertMessage: json['alertMessage'] as String,
      isRead: json['isRead'] as bool? ?? false,
      alertDate: DateTime.parse(json['alertDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alertId': alertId,
      'alertType': alertType,
      'alertMessage': alertMessage,
      'isRead': isRead,
      'alertDate': alertDate.toIso8601String(),
    };
  }

  AlertModel copyWith({
    String? alertId,
    String? alertType,
    String? alertMessage,
    bool? isRead,
    DateTime? alertDate,
  }) {
    return AlertModel(
      alertId: alertId ?? this.alertId,
      alertType: alertType ?? this.alertType,
      alertMessage: alertMessage ?? this.alertMessage,
      isRead: isRead ?? this.isRead,
      alertDate: alertDate ?? this.alertDate,
    );
  }

  static AlertModel create({
    required String alertId,
    required String alertType,
    required String alertMessage,
  }) {
    return AlertModel(
      alertId: alertId,
      alertType: alertType,
      alertMessage: alertMessage,
      isRead: false,
      alertDate: DateTime.now(),
    );
  }
}
