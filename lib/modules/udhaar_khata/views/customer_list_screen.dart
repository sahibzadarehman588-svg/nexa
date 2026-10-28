import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/udhaar_khata_controller.dart';
import '../../../data/models/customer_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';

class CustomerListScreen extends StatelessWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final UdhaarKhataController controller = Get.find<UdhaarKhataController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Udhaar Khata'),
        backgroundColor: AppColors.surfaceElevated,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Get.toNamed(AppRoutes.udhaarReminders),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats cards
          Obx(() => _buildStatsSection(controller)),
          const SizedBox(height: 16),

          // Search and filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search customers...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: controller.onSearchChanged,
                  ),
                ),
                const SizedBox(width: 8),
                Obx(() => IconButton(
                  icon: Icon(
                    controller.showArchived.value
                        ? Icons.archive
                        : Icons.unarchive,
                  ),
                  onPressed: () => controller.onShowArchivedChanged(
                    !controller.showArchived.value,
                  ),
                  tooltip: controller.showArchived.value
                      ? 'Show Active'
                      : 'Show Archived',
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Customer list
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.hasError.value) {
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
                        'Failed to load customers',
                        style: AppTextStyles.headline6,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        controller.errorMessage.value,
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: controller.refreshData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (controller.filteredCustomers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        controller.showArchived.value
                            ? 'No archived customers'
                            : 'No customers yet',
                        style: AppTextStyles.headline6.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (!controller.showArchived.value) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to add your first customer',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: controller.filteredCustomers.length,
                itemBuilder: (context, index) {
                  final customer = controller.filteredCustomers[index];
                  return _CustomerCard(
                    customer: customer,
                    onTap: () async {
                      await controller.loadCustomerDetails(customer.customerId);
                      Get.toNamed(AppRoutes.customerDetail, arguments: customer.customerId);
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCustomerDialog(controller),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatsSection(UdhaarKhataController controller) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'Total Credit',
              value: 'Rs. ${controller.totalCredit.value.toStringAsFixed(0)}',
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              label: 'Total Payments',
              value: 'Rs. ${controller.totalPayments.value.toStringAsFixed(0)}',
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              label: 'Outstanding',
              value: 'Rs. ${controller.totalOutstanding.value.toStringAsFixed(0)}',
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCustomerDialog(UdhaarKhataController controller) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final notesController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Add Customer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone (optional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                Get.snackbar(
                  'Error',
                  'Name is required',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.error,
                  colorText: AppColors.surface,
                );
                return;
              }

              final success = await controller.createCustomer(
                name: nameController.text.trim(),
                phone: phoneController.text.trim().isEmpty
                    ? null
                    : phoneController.text.trim(),
                address: addressController.text.trim().isEmpty
                    ? null
                    : addressController.text.trim(),
                notes: notesController.text.trim().isEmpty
                    ? null
                    : notesController.text.trim(),
              );

              if (success) {
                Get.back();
                Get.snackbar(
                  'Success',
                  'Customer added successfully',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.primary,
                  colorText: AppColors.surface,
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final CustomerModel customer;
  final VoidCallback onTap;

  const _CustomerCard({
    required this.customer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  customer.customerName[0].toUpperCase(),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.customerName,
                      style: AppTextStyles.subtitle1.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (customer.customerPhone != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        customer.customerPhone!,
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (customer.isArchived)
                Icon(
                  Icons.archive,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              value,
              style: AppTextStyles.headline6.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
