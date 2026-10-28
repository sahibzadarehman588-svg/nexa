class TaskModel {
  final String taskId;
  final String title;
  final String? description;
  final String priority;
  final DateTime? dueDate;
  final String? dueTime; // Format: "HH:mm" e.g., "14:30"
  final DateTime? startDate;
  final String? startTime; // Format: "HH:mm" e.g., "14:30"
  final DateTime? endDate;
  final String? endTime; // Format: "HH:mm" e.g., "14:30"
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TaskModel({
    required this.taskId,
    required this.title,
    this.description,
    required this.priority,
    this.dueDate,
    this.dueTime,
    this.startDate,
    this.startTime,
    this.endDate,
    this.endTime,
    required this.isCompleted,
    required this.createdAt,
    this.updatedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      taskId: json['taskId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: json['priority'] as String? ?? 'medium',
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      dueTime: json['dueTime'] as String?,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      startTime: json['startTime'] as String?,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      endTime: json['endTime'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'title': title,
      'description': description,
      'priority': priority,
      'dueDate': dueDate?.toIso8601String(),
      'dueTime': dueTime,
      'startDate': startDate?.toIso8601String(),
      'startTime': startTime,
      'endDate': endDate?.toIso8601String(),
      'endTime': endTime,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  TaskModel copyWith({
    String? taskId,
    String? title,
    String? description,
    String? priority,
    DateTime? dueDate,
    String? dueTime,
    DateTime? startDate,
    String? startTime,
    DateTime? endDate,
    String? endTime,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      startDate: startDate ?? this.startDate,
      startTime: startTime ?? this.startTime,
      endDate: endDate ?? this.endDate,
      endTime: endTime ?? this.endTime,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static TaskModel create({
    required String taskId,
    required String title,
    String? description,
    String priority = 'medium',
    DateTime? dueDate,
  }) {
    final now = DateTime.now();
    return TaskModel(
      taskId: taskId,
      title: title,
      description: description,
      priority: priority,
      dueDate: dueDate,
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
           dueDate!.month == now.month &&
           dueDate!.day == now.day;
  }
}
