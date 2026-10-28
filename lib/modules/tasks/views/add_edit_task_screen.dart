import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/firestore_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';

class AddEditTaskScreen extends StatefulWidget {
  const AddEditTaskScreen({super.key});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  String _priority = 'medium';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args != null && args is TaskModel) {
      _initializeEditMode(args);
    }
  }

  void _initializeEditMode(TaskModel task) {
    _titleController.text = task.title;
    _descriptionController.text = task.description ?? '';
    _dueDate = task.dueDate;
    _priority = task.priority;
    _startDate = task.startDate;
    _endDate = task.endDate;

    // Parse dueTime if exists
    if (task.dueTime != null && task.dueTime!.isNotEmpty) {
      final parts = task.dueTime!.split(':');
      if (parts.length == 2) {
        _dueTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }

    // Parse startTime if exists
    if (task.startTime != null && task.startTime!.isNotEmpty) {
      final parts = task.startTime!.split(':');
      if (parts.length == 2) {
        _startTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }

    // Parse endTime if exists
    if (task.endTime != null && task.endTime!.isNotEmpty) {
      final parts = task.endTime!.split(':');
      if (parts.length == 2) {
        _endTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _selectDueTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() => _dueTime = picked);
    }
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  Future<void> _saveTask() async {
    debugPrint('=== AddEditTaskScreen: _saveTask START ===');

    // Prevent duplicate submissions
    if (_isLoading) {
      debugPrint('⚠️ Save already in progress, ignoring duplicate tap');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ Form validation failed');
      return;
    }
    debugPrint('✅ Form validation passed');

    setState(() => _isLoading = true);

    try {
      // Check if user is logged in
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        debugPrint('❌ User is not logged in');
        throw Exception('User not logged in');
      }
      debugPrint('✅ User is logged in: ${firebaseUser.uid}');

      final userId = firebaseUser.uid;
      debugPrint('📱 User ID: $userId');

      final args = Get.arguments;
      debugPrint('📋 Arguments: $args (is TaskModel: ${args is TaskModel})');

      // Ensure user document exists in Firestore
      debugPrint('🔍 Checking if user document exists in Firestore...');
      final existingUser = await _firestoreService.getUser(userId);
      if (existingUser == null) {
        debugPrint('⚠️ User document does not exist, creating it...');
        // Create user document if it doesn't exist
        final userModel = UserModel(
          userId: userId,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _firestoreService.createUser(userModel);
        debugPrint('✅ User document created');
      } else {
        debugPrint('✅ User document exists');
      }

      if (args == null || args is! TaskModel) {
        // Add new task
        debugPrint('➕ Creating new task...');
        final taskId = '${DateTime.now().millisecondsSinceEpoch}';
        debugPrint('🆔 Generated Task ID: $taskId');

        // Format times as "HH:mm"
        final dueTimeString = _dueTime != null
            ? '${_dueTime!.hour.toString().padLeft(2, '0')}:${_dueTime!.minute.toString().padLeft(2, '0')}'
            : null;
        final startTimeString = _startTime != null
            ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
            : null;
        final endTimeString = _endTime != null
            ? '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}'
            : null;

        final task = TaskModel.create(
          taskId: taskId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          priority: _priority,
          dueDate: _dueDate,
        ).copyWith(
          dueTime: dueTimeString,
          startDate: _startDate,
          startTime: startTimeString,
          endDate: _endDate,
          endTime: endTimeString,
        );
        debugPrint('📝 Task created locally: ${task.toJson()}');

        debugPrint('💾 Saving task to Firestore...');
        await _firestoreService.createTask(userId, task);
        debugPrint('✅ Task saved to Firestore successfully');

        // Schedule notifications if start/end date and time are set
        if ((_startDate != null && _startTime != null) ||
            (_endDate != null && _endTime != null)) {
          await _notificationService.scheduleTaskNotifications(
            taskId: taskId,
            taskTitle: task.title,
            dueDate: _dueDate,
            dueTime: dueTimeString,
            startDate: _startDate,
            startTime: startTimeString,
            endDate: _endDate,
            endTime: endTimeString,
          );
        }

        // Return the created task so TasksController can add it immediately
        debugPrint('🔙 Navigating back with created task');
        Get.back(result: task);
      } else {
        // Update existing task
        debugPrint('✏️ Updating existing task...');
        final existingTask = args;

        // Format times as "HH:mm"
        final dueTimeString = _dueTime != null
            ? '${_dueTime!.hour.toString().padLeft(2, '0')}:${_dueTime!.minute.toString().padLeft(2, '0')}'
            : null;
        final startTimeString = _startTime != null
            ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
            : null;
        final endTimeString = _endTime != null
            ? '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}'
            : null;

        final updatedTask = existingTask.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          priority: _priority,
          dueDate: _dueDate,
          dueTime: dueTimeString,
          startDate: _startDate,
          startTime: startTimeString,
          endDate: _endDate,
          endTime: endTimeString,
          updatedAt: DateTime.now(),
        );

        await _firestoreService.updateTask(userId, updatedTask);
        debugPrint('✅ Task updated in Firestore successfully');

        // Cancel old notifications and schedule new ones
        await _notificationService.cancelTaskNotifications(existingTask.taskId);
        if ((_startDate != null && _startTime != null) ||
            (_endDate != null && _endTime != null)) {
          await _notificationService.scheduleTaskNotifications(
            taskId: existingTask.taskId,
            taskTitle: updatedTask.title,
            dueDate: _dueDate,
            dueTime: dueTimeString,
            startDate: _startDate,
            startTime: startTimeString,
            endDate: _endDate,
            endTime: endTimeString,
          );
        }

        // Return the updated task so TasksController can update it immediately
        debugPrint('🔙 Navigating back with updated task');
        Get.back(result: updatedTask);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error saving task: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      setState(() => _isLoading = false);
      debugPrint('=== AddEditTaskScreen: _saveTask END ===');
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final isEditMode = args != null && args is TaskModel;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Task' : 'Add Task'),
        backgroundColor: AppColors.surfaceElevated,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  hintText: 'Enter task title',
                  prefixIcon: Icon(Icons.task_alt),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Task title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Enter task description',
                  prefixIcon: Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 16),

              // Priority
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  prefixIcon: Icon(Icons.flag),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'low',
                    child: Text('Low'),
                  ),
                  DropdownMenuItem(
                    value: 'medium',
                    child: Text('Medium'),
                  ),
                  DropdownMenuItem(
                    value: 'high',
                    child: Text('High'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _priority = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Due Date
              InkWell(
                onTap: _selectDueDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Due Date (Optional)',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _dueDate != null
                        ? DateFormat('yyyy-MM-dd').format(_dueDate!)
                        : 'Select due date',
                    style: TextStyle(
                      color: _dueDate != null
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Due Time
              InkWell(
                onTap: _selectDueTime,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Due Time (Optional)',
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  child: Text(
                    _dueTime != null
                        ? _dueTime!.format(context)
                        : 'Select due time',
                    style: TextStyle(
                      color: _dueTime != null
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Start Date
              InkWell(
                onTap: _selectStartDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Start Date (Optional)',
                    prefixIcon: Icon(Icons.play_arrow),
                  ),
                  child: Text(
                    _startDate != null
                        ? DateFormat('yyyy-MM-dd').format(_startDate!)
                        : 'Select start date',
                    style: TextStyle(
                      color: _startDate != null
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Start Time
              InkWell(
                onTap: _selectStartTime,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Start Time (Optional)',
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  child: Text(
                    _startTime != null
                        ? _startTime!.format(context)
                        : 'Select start time',
                    style: TextStyle(
                      color: _startTime != null
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // End Date
              InkWell(
                onTap: _selectEndDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'End Date (Optional)',
                    prefixIcon: Icon(Icons.stop),
                  ),
                  child: Text(
                    _endDate != null
                        ? DateFormat('yyyy-MM-dd').format(_endDate!)
                        : 'Select end date',
                    style: TextStyle(
                      color: _endDate != null
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // End Time
              InkWell(
                onTap: _selectEndTime,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'End Time (Optional)',
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  child: Text(
                    _endTime != null
                        ? _endTime!.format(context)
                        : 'Select end time',
                    style: TextStyle(
                      color: _endTime != null
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveTask,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.surface,
                          ),
                        )
                      : Text(isEditMode ? 'Update Task' : 'Add Task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
