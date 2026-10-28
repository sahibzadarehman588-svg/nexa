import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/udhaar_khata_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class ReceivePaymentScreen extends StatefulWidget {
  const ReceivePaymentScreen({super.key});

  @override
  State<ReceivePaymentScreen> createState() => _ReceivePaymentScreenState();
}

class _ReceivePaymentScreenState extends State<ReceivePaymentScreen> {
  late final UdhaarKhataController controller;
  late final String customerId;

  final amountController = TextEditingController();
  final methodController = TextEditingController();
  final notesController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    controller = Get.find<UdhaarKhataController>();
    customerId = Get.arguments as String;
  }

  @override
  Widget build(BuildContext context) {
    final balance = controller.getCustomerBalance();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Receive Payment'),
        backgroundColor: AppColors.surfaceElevated,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Outstanding balance card
            Card(
              color: AppColors.surface,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
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
                        color: AppColors.warning,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ),
            ),
            const SizedBox(height: 24),

            // Payment amount
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: 'Payment Amount (PKR) *',
                prefixText: 'Rs. ',
                border: const OutlineInputBorder(),
                helperText: 'Maximum: Rs. ${balance.toStringAsFixed(0)}',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),

            // Quick amount buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuickAmountButton(
                  label: 'Full Payment',
                  amount: balance,
                  onTap: () {
                    amountController.text = balance.toStringAsFixed(0);
                  },
                ),
                _QuickAmountButton(
                  label: 'Half',
                  amount: balance / 2,
                  onTap: () {
                    amountController.text = (balance / 2).toStringAsFixed(0);
                  },
                ),
                _QuickAmountButton(
                  label: 'Quarter',
                  amount: balance / 4,
                  onTap: () {
                    amountController.text = (balance / 4).toStringAsFixed(0);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Payment date and time
            Card(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Date & Time',
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

            // Payment method (optional)
            TextField(
              controller: methodController,
              decoration: const InputDecoration(
                labelText: 'Payment Method (optional)',
                hintText: 'e.g., Cash, Bank Transfer, etc.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Notes (optional)
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Receive payment button
            SizedBox(
              width: double.infinity,
              child: Obx(() => ElevatedButton(
                onPressed: (_isSaving || controller.isLoading.value) ? null : () async {
                  // Validate amount
                  final amount = double.tryParse(amountController.text);
                  if (amount == null || amount <= 0) {
                    Get.snackbar(
                      'Error',
                      'Please enter a valid amount greater than 0',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppColors.error,
                      colorText: AppColors.surface,
                    );
                    return;
                  }

                  if (amount > balance) {
                    Get.snackbar(
                      'Invalid Amount',
                      'Payment amount cannot exceed outstanding balance of Rs. ${balance.toStringAsFixed(0)}',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppColors.warning,
                      colorText: AppColors.surface,
                    );
                    return;
                  }

                  // Set loading state to prevent duplicate submissions
                  setState(() => _isSaving = true);

                  // Build payment datetime
                  final paymentDateTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );

                  try {
                    final success = await controller.createPayment(
                      customerId: customerId,
                      paymentAmount: amount,
                      paymentDate: paymentDateTime,
                      paymentMethod: methodController.text.trim().isEmpty
                          ? null
                          : methodController.text.trim(),
                      paymentNotes: notesController.text.trim().isEmpty
                          ? null
                          : notesController.text.trim(),
                    );

                    if (success) {
                      Get.back(result: true);
                      Get.snackbar(
                        'Success',
                        'Payment received successfully',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppColors.primary,
                        colorText: AppColors.surface,
                      );
                    } else {
                      Get.snackbar(
                        'Error',
                        'Payment failed. Please try again.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppColors.error,
                        colorText: AppColors.surface,
                      );
                    }
                  } catch (e) {
                    Get.snackbar(
                      'Error',
                      'Payment failed. Please try again.',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppColors.error,
                      colorText: AppColors.surface,
                    );
                  } finally {
                    // Clear loading state
                    if (mounted) {
                      setState(() => _isSaving = false);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: (_isSaving || controller.isLoading.value)
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.surface,
                        ),
                      )
                    : const Text(
                        'Receive Payment',
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

class _QuickAmountButton extends StatelessWidget {
  final String label;
  final double amount;
  final VoidCallback onTap;

  const _QuickAmountButton({
    required this.label,
    required this.amount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text('$label (Rs. ${amount.toStringAsFixed(0)})'),
    );
  }
}
