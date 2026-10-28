import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/udhaar_khata_controller.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/credit_entry_model.dart';
import '../../../data/models/payment_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';

class CustomerDetailScreen extends StatelessWidget {
  const CustomerDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final UdhaarKhataController controller = Get.find<UdhaarKhataController>();
    final customerId = Get.arguments as String;

    // Load customer details when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadCustomerDetails(customerId);
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Customer Details'),
        backgroundColor: AppColors.surfaceElevated,
        foregroundColor: AppColors.textPrimary,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                _showEditCustomerDialog(controller);
              } else if (value == 'archive') {
                await controller.archiveCustomer(customerId);
                Get.back();
              } else if (value == 'delete') {
                final deleted = await controller.deleteCustomer(customerId);
                if (deleted) {
                  Get.back();
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'archive',
                child: Row(
                  children: [
                    Icon(Icons.archive),
                    SizedBox(width: 8),
                    Text('Archive'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final customer = controller.selectedCustomer.value;
        if (customer == null) {
          return const Center(child: Text('Customer not found'));
        }

        final balance = controller.getCustomerBalance();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer info card
              Card(
                color: AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            radius: 32,
                            child: Text(
                              customer.customerName[0].toUpperCase(),
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
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
                                  style: AppTextStyles.headline5,
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
                                if (customer.customerAddress != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    customer.customerAddress!,
                                    style: AppTextStyles.body2.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (customer.customerNotes != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Notes: ${customer.customerNotes}',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Balance card
              Card(
                color: AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        'Outstanding Balance',
                        style: AppTextStyles.subtitle1.copyWith(
                          color: AppColors.textOnTint,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rs. ${balance.toStringAsFixed(0)}',
                        style: AppTextStyles.headline3.copyWith(
                          color: balance > 0 ? AppColors.warning : AppColors.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final result = await Get.toNamed(
                                  AppRoutes.addCreditEntry,
                                  arguments: customerId,
                                );
                                // Refresh customer details if credit was added successfully
                                if (result == true) {
                                  controller.loadCustomerDetails(customerId);
                                }
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Credit', style: TextStyle(fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: balance > 0
                                  ? () async {
                                      final result = await Get.toNamed(
                                        AppRoutes.receivePayment,
                                        arguments: customerId,
                                      );
                                      // Refresh customer details if payment was received successfully
                                      if (result == true) {
                                        controller.loadCustomerDetails(customerId);
                                      }
                                    }
                                  : null,
                              icon: const Icon(Icons.payment, size: 18),
                              label: const Text('Receive Payment', style: TextStyle(fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: balance > 0
                                    ? AppColors.secondary
                                    : AppColors.textDisabled,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Customer reminder settings
              Card(
                color: AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.notifications_outlined,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Customer-Level Reminder',
                            style: AppTextStyles.subtitle1.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Enable Reminder'),
                        subtitle: customer.hasCustomerReminder
                            ? Text(
                                'Reminder set for ${DateFormat('dd MMM yyyy, HH:mm').format(
                                  DateTime(
                                    customer.customerReminderDate!.year,
                                    customer.customerReminderDate!.month,
                                    customer.customerReminderDate!.day,
                                    int.parse(customer.customerReminderTime!.split(':')[0]),
                                    int.parse(customer.customerReminderTime!.split(':')[1]),
                                  ),
                                )}',
                              )
                            : const Text('No reminder set'),
                        value: customer.customerReminderEnabled,
                        onChanged: (value) async {
                          if (value) {
                            _showCustomerReminderDialog(controller, customer);
                          } else {
                            await controller.updateCustomerReminder(
                              customerId: customer.customerId,
                              reminderEnabled: false,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Transaction history
              Text(
                'Transaction History',
                style: AppTextStyles.headline6,
              ),
              const SizedBox(height: 12),

              if (controller.customerCreditEntries.isEmpty &&
                  controller.customerPayments.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No transactions yet'),
                  ),
                )
              else
                _buildTransactionList(controller, balance),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTransactionList(UdhaarKhataController controller, double balance) {
    // Combine and sort transactions by date
    final transactions = <Map<String, dynamic>>[];

    for (final entry in controller.customerCreditEntries) {
      transactions.add({
        'type': 'credit',
        'date': entry.transactionDate,
        'data': entry,
      });
    }

    for (final payment in controller.customerPayments) {
      transactions.add({
        'type': 'payment',
        'date': payment.paymentDate,
        'data': payment,
      });
    }

    transactions.sort((a, b) => b['date'].compareTo(a['date']));

    return Column(
      children: transactions.map((transaction) {
        if (transaction['type'] == 'credit') {
          final entry = transaction['data'] as CreditEntryModel;
          return _CreditEntryCard(
            entry: entry,
            onTap: () => _showCreditEntryOptions(controller, entry),
          );
        } else {
          final payment = transaction['data'] as PaymentModel;
          return _PaymentCard(payment: payment);
        }
      }).toList(),
    );
  }

  void _showEditCustomerDialog(UdhaarKhataController controller) {
    final customer = controller.selectedCustomer.value;
    if (customer == null) return;

    final nameController = TextEditingController(text: customer.customerName);
    final phoneController = TextEditingController(text: customer.customerPhone ?? '');
    final addressController = TextEditingController(text: customer.customerAddress ?? '');
    final notesController = TextEditingController(text: customer.customerNotes ?? '');

    Get.dialog(
      AlertDialog(
        title: const Text('Edit Customer'),
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

              final updatedCustomer = customer.copyWith(
                customerName: nameController.text.trim(),
                customerPhone: phoneController.text.trim().isEmpty
                    ? null
                    : phoneController.text.trim(),
                customerAddress: addressController.text.trim().isEmpty
                    ? null
                    : addressController.text.trim(),
                customerNotes: notesController.text.trim().isEmpty
                    ? null
                    : notesController.text.trim(),
              );

              final success = await controller.updateCustomer(updatedCustomer);
              if (success) {
                Get.back();
                Get.snackbar(
                  'Success',
                  'Customer updated successfully',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.primary,
                  colorText: AppColors.surface,
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCustomerReminderDialog(
    UdhaarKhataController controller,
    CustomerModel customer,
  ) {
    DateTime? selectedDate = customer.customerReminderDate;
    TimeOfDay? selectedTime = customer.customerReminderTime != null
        ? TimeOfDay(
            hour: int.parse(customer.customerReminderTime!.split(':')[0]),
            minute: int.parse(customer.customerReminderTime!.split(':')[1]),
          )
        : null;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Set Reminder'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Date'),
                  subtitle: Text(
                    selectedDate != null
                        ? DateFormat('dd MMM yyyy').format(selectedDate!)
                        : 'Select date',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
                ),
                ListTile(
                  title: const Text('Time'),
                  subtitle: Text(
                    selectedTime != null
                        ? selectedTime!.format(context)
                        : 'Select time',
                  ),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime ?? TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setState(() => selectedTime = picked);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedDate == null || selectedTime == null) {
                    Get.snackbar(
                      'Error',
                      'Please select both date and time',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppColors.error,
                      colorText: AppColors.surface,
                    );
                    return;
                  }

                  final success = await controller.updateCustomerReminder(
                    customerId: customer.customerId,
                    reminderEnabled: true,
                    reminderDate: selectedDate,
                    reminderTime: '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}',
                  );

                  if (success) {
                    Get.back();
                    Get.snackbar(
                      'Success',
                      'Reminder set successfully',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppColors.primary,
                      colorText: AppColors.surface,
                    );
                  }
                },
                child: const Text('Set Reminder'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCreditEntryOptions(
    UdhaarKhataController controller,
    CreditEntryModel entry,
  ) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Get.theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View Details'),
              onTap: () {
                Get.back();
                _showCreditEntryDetails(controller, entry);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Get.back();
                // Navigate to edit screen (to be implemented)
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text('Delete', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Get.back();
                controller.deleteCreditEntry(entry.creditEntryId);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreditEntryDetails(
    UdhaarKhataController controller,
    CreditEntryModel entry,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Credit Entry Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow('Amount', 'Rs. ${entry.amount.toStringAsFixed(0)}'),
              _DetailRow('Date', DateFormat('dd MMM yyyy, HH:mm').format(entry.transactionDate)),
              if (entry.itemDescription != null) _DetailRow('Description', entry.itemDescription!),
              if (entry.hasItemDetails) ...[
                _DetailRow('Item', entry.itemName!),
                _DetailRow('Quantity', '${entry.itemQuantity} ${entry.itemUnit ?? ''}'),
                _DetailRow('Price', 'Rs. ${entry.itemPrice?.toStringAsFixed(0) ?? ''}'),
              ],
              if (entry.creditNotes != null) _DetailRow('Notes', entry.creditNotes!),
              _DetailRow('Paid Amount', 'Rs. ${entry.paidAmount.toStringAsFixed(0)}'),
              _DetailRow('Outstanding', 'Rs. ${entry.outstandingAmount.toStringAsFixed(0)}'),
              if (entry.hasReminder) ...[
                _DetailRow('Reminder', DateFormat('dd MMM yyyy, HH:mm').format(
                  DateTime(
                    entry.reminderDate!.year,
                    entry.reminderDate!.month,
                    entry.reminderDate!.day,
                    int.parse(entry.reminderTime!.split(':')[0]),
                    int.parse(entry.reminderTime!.split(':')[1]),
                  ),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _CreditEntryCard extends StatelessWidget {
  final CreditEntryModel entry;
  final VoidCallback onTap;

  const _CreditEntryCard({
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_upward,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.itemDescription ?? 'Credit Entry',
                      style: AppTextStyles.subtitle1.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM yyyy').format(entry.transactionDate),
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rs. ${entry.amount.toStringAsFixed(0)}',
                    style: AppTextStyles.subtitle1.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (entry.paidAmount > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Paid: Rs. ${entry.paidAmount.toStringAsFixed(0)}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
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

class _PaymentCard extends StatelessWidget {
  final PaymentModel payment;

  const _PaymentCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.arrow_downward,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Received',
                    style: AppTextStyles.subtitle1.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMM yyyy').format(payment.paymentDate),
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (payment.paymentMethod != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      payment.paymentMethod!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              'Rs. ${payment.paymentAmount.toStringAsFixed(0)}',
              style: AppTextStyles.subtitle1.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: AppTextStyles.body2.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body2,
            ),
          ),
        ],
      ),
    );
  }
}
