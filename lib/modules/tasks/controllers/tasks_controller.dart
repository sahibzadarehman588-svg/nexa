import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/services/firestore_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/models/task_model.dart';
import '../../../core/routes/app_routes.dart';

class TasksController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  // Reactive state
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;

  // Tasks data
  final RxList<TaskModel> allTasks = <TaskModel>[].obs;
  final RxList<TaskModel> filteredTasks = <TaskModel>[].obs;

  // Filter
  final RxString selectedFilter = 'All'.obs;

  @override
  void onInit() {
    super.onInit();
    debugPrint('=== TasksController: onInit ===');
    _loadTasks();
    _reschedulePendingTaskNotifications();
  }

  Future<void> _reschedulePendingTaskNotifications() async {
    debugPrint('=== TasksController: Rescheduling pending task notifications ===');
    try {
      for (final task in allTasks) {
        // Only reschedule if task is not completed
        if (!task.isCompleted) {
          // Calculate start datetime if set
          DateTime? startDateTime;
          if (task.startDate != null && task.startTime != null && task.startTime!.isNotEmpty) {
            startDateTime = DateTime(
              task.startDate!.year,
              task.startDate!.month,
              task.startDate!.day,
              int.parse(task.startTime!.split(':')[0]),
              int.parse(task.startTime!.split(':')[1]),
            );
          }

          // Calculate end datetime if set
          DateTime? endDateTime;
          if (task.endDate != null && task.endTime != null && task.endTime!.isNotEmpty) {
            endDateTime = DateTime(
              task.endDate!.year,
              task.endDate!.month,
              task.endDate!.day,
              int.parse(task.endTime!.split(':')[0]),
              int.parse(task.endTime!.split(':')[1]),
            );
          }

          // Only reschedule if at least one time is in the future
          if ((startDateTime != null && startDateTime.isAfter(DateTime.now())) ||
              (endDateTime != null && endDateTime.isAfter(DateTime.now()))) {
            await _notificationService.scheduleTaskNotifications(
              taskId: task.taskId,
              taskTitle: task.title,
              dueDate: task.dueDate,
              dueTime: task.dueTime,
              startDate: task.startDate,
              startTime: task.startTime,
              endDate: task.endDate,
              endTime: task.endTime,
            );
            debugPrint('✅ Rescheduled notifications for task: ${task.taskId}');
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error rescheduling task notifications: $e');
    }
  }

  Future<void> _loadTasks() async {
    debugPrint('=== TasksController: _loadTasks START ===');

    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      debugPrint('❌ User is not logged in, skipping task load');
      return;
    }
    debugPrint('✅ User is logged in: ${firebaseUser.uid}');

    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';

    try {
      final userId = firebaseUser.uid;
      debugPrint('📱 Loading tasks for user: $userId');

      final tasks = await _firestoreService.getTasks(userId);
      debugPrint('📋 Retrieved ${tasks.length} tasks from Firestore');

      allTasks.value = tasks;
      _applyFilters();
      debugPrint('✅ Tasks loaded and filtered successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading tasks: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      hasError.value = true;
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading.value = false;
      debugPrint('=== TasksController: _loadTasks END ===');
    }
  }

  void _applyFilters() {
    filteredTasks.value = allTasks.where((task) {
      if (selectedFilter.value == 'All') return true;
      if (selectedFilter.value == 'Pending') return !task.isCompleted;
      if (selectedFilter.value == 'Completed') return task.isCompleted;
      return true;
    }).toList();
  }

  void onFilterChanged(String filter) {
    selectedFilter.value = filter;
    _applyFilters();
  }

  Future<void> toggleTaskCompletion(TaskModel task) async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        throw Exception('User not logged in');
      }

      final userId = firebaseUser.uid;
      final updatedTask = task.copyWith(
        isCompleted: !task.isCompleted,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateTask(userId, updatedTask);

      // Cancel notification if task is being marked as completed
      if (!task.isCompleted) {
        await _notificationService.cancelTaskNotifications(task.taskId);
      }
      // Reschedule notification if task is being marked as incomplete and has future start/end times
      else if ((task.startDate != null && task.startTime != null) ||
               (task.endDate != null && task.endTime != null)) {
        await _notificationService.scheduleTaskNotifications(
          taskId: task.taskId,
          taskTitle: task.title,
          dueDate: task.dueDate,
          dueTime: task.dueTime,
          startDate: task.startDate,
          startTime: task.startTime,
          endDate: task.endDate,
          endTime: task.endTime,
        );
      }

      // Update local list
      final index = allTasks.indexWhere((t) => t.taskId == task.taskId);
      if (index != -1) {
        allTasks[index] = updatedTask;
        _applyFilters();
      }

      Get.snackbar(
        'Success',
        task.isCompleted ? 'Task marked as pending' : 'Task completed',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }

  Future<void> deleteTask(TaskModel task) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Get.theme.colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        throw Exception('User not logged in');
      }

      final userId = firebaseUser.uid;

      // Cancel notification before deleting
      await _notificationService.cancelTaskNotifications(task.taskId);

      await _firestoreService.deleteTask(userId, task.taskId);

      // Remove from local list
      allTasks.remove(task);
      _applyFilters();

      Get.snackbar(
        'Success',
        'Task deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }

  Future<void> refreshTasks() async {
    await _loadTasks();
  }

  void navigateToAddTask() {
    debugPrint('=== TasksController: navigateToAddTask ===');
    Get.toNamed(AppRoutes.addTask)?.then((result) {
      debugPrint('🔙 Returned from Add Task screen with result: $result');
      if (result != null && result is TaskModel) {
        debugPrint('📝 Adding new task to local list: ${result.taskId}');
        // Add the new task to the beginning of the list
        allTasks.insert(0, result);
        _applyFilters();
        debugPrint('✅ Task added to local list and filters applied');

        // Show success notification on Tasks screen
        Get.snackbar(
          'Success',
          'Task added successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );
      } else if (result == true) {
        // Fallback for edit operations
        debugPrint('🔄 Refreshing tasks...');
        refreshTasks();
      }
    });
  }

  void navigateToEditTask(TaskModel task) {
    Get.toNamed(AppRoutes.editTask, arguments: task)?.then((result) {
      if (result != null && result is TaskModel) {
        debugPrint('📝 Updating task in local list: ${result.taskId}');
        // Update the task in the local list
        final index = allTasks.indexWhere((t) => t.taskId == result.taskId);
        if (index != -1) {
          allTasks[index] = result;
          _applyFilters();
          debugPrint('✅ Task updated in local list and filters applied');

          // Show success notification on Tasks screen
          Get.snackbar(
            'Success',
            'Task updated successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Get.theme.colorScheme.primary,
            colorText: Get.theme.colorScheme.onPrimary,
          );
        }
      } else if (result == true) {
        // Fallback
        refreshTasks();
      }
    });
  }
}
