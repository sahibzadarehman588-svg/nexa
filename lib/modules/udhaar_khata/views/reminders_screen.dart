import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/udhaar_khata_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen>
    with SingleTickerProviderStateMixin {
  late final UdhaarKhataController controller;
  late final TabController tabController;

  @override
  void initState() {
    super.initState();
    controller = Get.find<UdhaarKhataController>();
    tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reminders'),
        backgroundColor: AppColors.primary,
        bottom: TabBar(
          controller: tabController,
          labelColor: Colors.black,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Overdue'),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          _UpcomingRemindersTab(controller: controller),
          _OverdueRemindersTab(controller: controller),
        ],
      ),
    );
  }
}

class _UpcomingRemindersTab extends StatelessWidget {
  final UdhaarKhataController controller;

  const _UpcomingRemindersTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: controller.getUpcomingReminders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load reminders',
                  style: AppTextStyles.headline6,
                ),
              ],
            ),
          );
        }

        final reminders = snapshot.data ?? [];

        if (reminders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No upcoming reminders',
                  style: AppTextStyles.headline6.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: reminders.length,
          itemBuilder: (context, index) {
            final reminder = reminders[index];
            return _ReminderCard(reminder: reminder);
          },
        );
      },
    );
  }
}

class _OverdueRemindersTab extends StatelessWidget {
  final UdhaarKhataController controller;

  const _OverdueRemindersTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: controller.getOverdueReminders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load reminders',
                  style: AppTextStyles.headline6,
                ),
              ],
            ),
          );
        }

        final reminders = snapshot.data ?? [];

        if (reminders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: AppColors.secondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No overdue reminders',
                  style: AppTextStyles.headline6.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: reminders.length,
          itemBuilder: (context, index) {
            final reminder = reminders[index];
            return _ReminderCard(reminder: reminder, isOverdue: true);
          },
        );
      },
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final Map<String, dynamic> reminder;
  final bool isOverdue;

  const _ReminderCard({
    required this.reminder,
    this.isOverdue = false,
  });

  @override
  Widget build(BuildContext context) {
    final type = reminder['type'] as String;
    final customerName = reminder['customerName'] as String;
    final reminderDate = reminder['reminderDate'] as DateTime;
    final amount = reminder['amount'] as double;

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      color: isOverdue
          ? AppColors.error.withValues(alpha: 0.1)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isOverdue
                    ? AppColors.error.withValues(alpha: 0.2)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                type == 'customer'
                    ? Icons.account_balance_wallet
                    : Icons.receipt_long,
                color: isOverdue ? AppColors.error : AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customerName,
                    style: AppTextStyles.subtitle1.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textOnTint,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type == 'customer'
                        ? 'Total Balance Reminder'
                        : 'Credit Entry Reminder',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.textSecondaryOnTint,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rs. ${amount.toStringAsFixed(0)}',
                    style: AppTextStyles.body2.copyWith(
                      color: isOverdue ? AppColors.error : AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('dd MMM').format(reminderDate),
                  style: AppTextStyles.subtitle1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm').format(reminderDate),
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (isOverdue) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Overdue',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
