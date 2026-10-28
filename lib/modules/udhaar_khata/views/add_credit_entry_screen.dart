import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/udhaar_khata_controller.dart';
import '../../../core/theme/app_colors.dart';

class AddCreditEntryScreen extends StatefulWidget {
  const AddCreditEntryScreen({super.key});

  @override
  State<AddCreditEntryScreen> createState() => _AddCreditEntryScreenState();
}

class _AddCreditEntryScreenState extends State<AddCreditEntryScreen> {
  late final UdhaarKhataController controller;
  late final String customerId;

  final amountController = TextEditingController();
  final descriptionController = TextEditingController();
  final notesController = TextEditingController();

  // Item details
  final itemNameController = TextEditingController();
  final itemQuantityController = TextEditingController();
  final itemUnitController = TextEditingController();
  final itemPriceController = TextEditingController();

  // Date and time
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  // Reminder
  bool reminderEnabled = false;
  DateTime? reminderDate;
  TimeOfDay? reminderTime;

  // Guard against duplicate taps
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    controller = Get.find<UdhaarKhataController>();
    customerId = Get.arguments as String;
    // Load customer details to display customer name
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadCustomerDetails(customerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final customer = controller.selectedCustomer.value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Credit Entry'),
        backgroundColor: AppColors.surfaceElevated,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer info display
            if (customer != null)
              Card(
                color: AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.person, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Customer',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textDisabled,
                              ),
                            ),
                            Text(
                              customer.customerName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // Amount (required)
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (PKR) *',
                prefixText: 'Rs. ',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),

            // Transaction date and time
            Card(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Transaction Date & Time',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: const Text('Date'),
                            subtitle: Text(DateFormat('dd MMM yyyy').format(selectedDate)),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() => selectedDate = picked);
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: const Text('Time'),
                            subtitle: Text(selectedTime.format(context)),
                            trailing: const Icon(Icons.access_time),
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                              );
                              if (picked != null) {
                                setState(() => selectedTime = picked);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Optional item description
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Item Description (optional)',
                hintText: 'e.g., Rice, Sugar, etc.',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Optional itemized details
            ExpansionTile(
              title: const Text('Add Item Details (optional)'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: itemNameController,
                        decoration: const InputDecoration(
                          labelText: 'Item Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: itemQuantityController,
                              decoration: const InputDecoration(
                                labelText: 'Quantity',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: itemUnitController,
                              decoration: const InputDecoration(
                                labelText: 'Unit',
                                hintText: 'kg, pcs, etc.',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: itemPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Price per Unit (PKR)',
                          prefixText: 'Rs. ',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Optional notes
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Reminder settings
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
                        const Text(
                          'Reminder Settings',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Enable Reminder'),
                      value: reminderEnabled,
                      onChanged: (value) {
                        setState(() => reminderEnabled = value);
                      },
                    ),
                    if (reminderEnabled) ...[
                      const Divider(),
                      ListTile(
                        title: const Text('Reminder Date'),
                        subtitle: Text(
                          reminderDate != null
                              ? DateFormat('dd MMM yyyy').format(reminderDate!)
                              : 'Select date',
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: reminderDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => reminderDate = picked);
                          }
                        },
                      ),
                      ListTile(
                        title: const Text('Reminder Time'),
                        subtitle: Text(
                          reminderTime != null
                              ? reminderTime!.format(context)
                              : 'Select time',
                        ),
                        trailing: const Icon(Icons.access_time),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: reminderTime ?? TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setState(() => reminderTime = picked);
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: Obx(() => ElevatedButton(
                onPressed: _isSaving || controller.isLoading.value
                    ? null
                    : () async {
                        if (_isSaving) return;
                        _isSaving = true;

                        debugPrint('=== Save Button Pressed ===');
                        debugPrint('Amount text: "${amountController.text}"');

                        // Validate amount
                        final amount = double.tryParse(amountController.text);
                        debugPrint('Parsed amount: $amount');

                        if (amount == null || amount <= 0) {
                          debugPrint('❌ Invalid amount');
                          _isSaving = false;
                          Get.snackbar(
                            'Error',
                            'Please enter a valid amount greater than 0',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: AppColors.error,
                            colorText: AppColors.surface,
                          );
                          return;
                        }

                        // Validate reminder if enabled
                        if (reminderEnabled && (reminderDate == null || reminderTime == null)) {
                          _isSaving = false;
                          Get.snackbar(
                            'Error',
                            'Please select both reminder date and time',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: AppColors.error,
                            colorText: AppColors.surface,
                          );
                          return;
                        }

                        // Build transaction datetime
                        final transactionDateTime = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );

                        // Parse item details if provided
                        final itemQuantity = int.tryParse(itemQuantityController.text);
                        final itemPrice = double.tryParse(itemPriceController.text);

                        debugPrint('Calling createCreditEntry with amount: $amount');

                        final success = await controller.createCreditEntry(
                          customerId: customerId,
                          amount: amount,
                          transactionDate: transactionDateTime,
                          itemDescription: descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim(),
                          itemName: itemNameController.text.trim().isEmpty
                              ? null
                              : itemNameController.text.trim(),
                          itemQuantity: itemQuantity,
                          itemUnit: itemUnitController.text.trim().isEmpty
                              ? null
                              : itemUnitController.text.trim(),
                          itemPrice: itemPrice,
                          creditNotes: notesController.text.trim().isEmpty
                              ? null
                              : notesController.text.trim(),
                          reminderEnabled: reminderEnabled,
                          reminderDate: reminderDate,
                          reminderTime: reminderTime != null
                              ? '${reminderTime!.hour.toString().padLeft(2, '0')}:${reminderTime!.minute.toString().padLeft(2, '0')}'
                              : null,
                        );

                        debugPrint('CreateCreditEntry result: $success');
                        _isSaving = false;

                        if (success) {
                          Get.back(result: true);
                          Get.snackbar(
                            'Success',
                            'Credit entry added successfully',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: AppColors.primary,
                            colorText: AppColors.surface,
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving || controller.isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.surface),
                        ),
                      )
                    : const Text(
                        'Save Credit Entry',
                        style: TextStyle(fontSize: 16),
                      ),
              )),
            ),
          ],
        ),
      ),
    );
  }
}
