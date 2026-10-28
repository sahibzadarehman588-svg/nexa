import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../controllers/tasks_controller.dart';
import '../../../data/models/task_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TasksController tasksController = Get.find<TasksController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tasks'),
        backgroundColor: AppColors.surfaceElevated,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: tasksController.navigateToAddTask,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: tasksController.refreshTasks,
        child: Column(
          children: [
            // Filter Tabs
            _buildFilterTabs(tasksController),
            const Divider(height: 1),

            // Tasks List
            Expanded(
              child: Obx(() {
                if (tasksController.isLoading.value) {
                  return _buildLoadingState();
                }

                if (tasksController.hasError.value) {
                  return _buildErrorState(tasksController);
                }

                if (tasksController.filteredTasks.isEmpty) {
                  return _buildEmptyState(tasksController);
                }

                return _buildTasksList(tasksController);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs(TasksController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Obx(() => Row(
            children: [
              _FilterTab(
                label: 'All',
                isSelected: controller.selectedFilter.value == 'All',
                onTap: () => controller.onFilterChanged('All'),
              ),
              _FilterTab(
                label: 'Pending',
                isSelected: controller.selectedFilter.value == 'Pending',
                onTap: () => controller.onFilterChanged('Pending'),
              ),
              _FilterTab(
                label: 'Completed',
                isSelected: controller.selectedFilter.value == 'Completed',
                onTap: () => controller.onFilterChanged('Completed'),
              ),
            ],
          )),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppColors.surfaceElevated,
          highlightColor: AppColors.surface,
          child: Card(
            color: AppColors.surface,
            margin: const EdgeInsets.only(bottom: 12.0),
            child: Container(
              height: 80,
              color: AppColors.surface,
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(TasksController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load tasks',
              style: AppTextStyles.headline6,
            ),
            const SizedBox(height: 8),
            Obx(() => Text(
                  controller.errorMessage.value,
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                )),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: controller.refreshTasks,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(TasksController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt_outlined,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              'No Tasks Found',
              style: AppTextStyles.headline6,
            ),
            const SizedBox(height: 8),
            Text(
              controller.selectedFilter.value == 'All'
                  ? 'Start by creating your first task'
                  : 'No tasks in this category',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (controller.selectedFilter.value == 'All')
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton.icon(
                  onPressed: controller.navigateToAddTask,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Task'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksList(TasksController controller) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: controller.filteredTasks.length,
      itemBuilder: (context, index) {
        final task = controller.filteredTasks[index];
        return _buildTaskCard(task, controller);
      },
    );
  }

  Widget _buildTaskCard(TaskModel task, TasksController controller) {
    Color priorityColor;
    String priorityText;

    switch (task.priority) {
      case 'high':
        priorityColor = AppColors.error;
        priorityText = 'High';
        break;
      case 'medium':
        priorityColor = AppColors.warning;
        priorityText = 'Medium';
        break;
      case 'low':
        priorityColor = AppColors.success;
        priorityText = 'Low';
        break;
      default:
        priorityColor = AppColors.textSecondary;
        priorityText = 'Medium';
    }

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () => controller.navigateToEditTask(task),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Checkbox
              Checkbox(
                value: task.isCompleted,
                onChanged: (value) => controller.toggleTaskCompletion(task),
                activeColor: AppColors.primary,
              ),

              // Task Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      task.title,
                      style: AppTextStyles.body1.copyWith(
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.isCompleted
                            ? AppColors.textDisabled
                            : AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (task.description != null && task.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          task.description!,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (task.dueDate != null)
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 12,
                                  color: task.isOverdue
                                      ? AppColors.error
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    app_date_utils.DateUtils.formatDisplayDate(task.dueDate!),
                                    style: AppTextStyles.caption.copyWith(
                                      color: task.isOverdue
                                          ? AppColors.error
                                          : AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: priorityColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              priorityText,
                              style: AppTextStyles.caption.copyWith(
                                color: priorityColor,
                                fontSize: 9,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: () => controller.navigateToEditTask(task),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () => controller.deleteTask(task),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: AppTextStyles.body2.copyWith(
              color: isSelected ? AppColors.surface : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
