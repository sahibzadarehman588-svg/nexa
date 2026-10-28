import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/receipt_scanner_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class ReceiptScannerScreen extends StatelessWidget {
  const ReceiptScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ReceiptScannerController controller = Get.find<ReceiptScannerController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Receipt Scanner'),
        backgroundColor: AppColors.surfaceElevated,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistoryDialog(controller),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Image Preview
            Obx(() => _buildImagePreview(controller)),

            const SizedBox(height: 12),

            // Action Buttons
            _buildActionButtons(controller),

            const SizedBox(height: 16),

            // Extracted Data Section
            Obx(() => _buildExtractedDataSection(controller)),

            const SizedBox(height: 16),

            // Generated Summary Section
            Obx(() => _buildSummarySection(controller)),

            const SizedBox(height: 16),

            // Save Button
            Obx(() => _buildSaveButton(controller)),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(ReceiptScannerController controller) {
    if (controller.selectedImagePath.value.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long,
                size: 40,
                color: AppColors.textHint,
              ),
              const SizedBox(height: 8),
              Text(
                'No receipt selected',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        File(controller.selectedImagePath.value),
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildActionButtons(ReceiptScannerController controller) {
    return Row(
      children: [
        Expanded(
          child: Obx(() => ElevatedButton.icon(
            onPressed: controller.isProcessingImage.value
                ? null
                : controller.pickImageFromCamera,
            icon: const Icon(Icons.camera_alt, size: 18),
            label: const Text('Camera', style: TextStyle(fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          )),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Obx(() => ElevatedButton.icon(
            onPressed: controller.isProcessingImage.value
                ? null
                : controller.pickImageFromGallery,
            icon: const Icon(Icons.photo_library, size: 18),
            label: const Text('Gallery', style: TextStyle(fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          )),
        ),
      ],
    );
  }

  Widget _buildExtractedDataSection(ReceiptScannerController controller) {
    if (controller.extractedText.value.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Receipt Details',
                style: AppTextStyles.subtitle1.copyWith(
                  color: AppColors.primary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (controller.storeName.value.isNotEmpty)
            _buildDetailRow('Store', controller.storeName.value),
          if (controller.date.value.isNotEmpty)
            _buildDetailRow('Date', controller.date.value),
          if (controller.totalAmount.value.isNotEmpty)
            _buildDetailRow('Total', controller.totalAmount.value),
          const SizedBox(height: 12),
          if (controller.items.isNotEmpty) ...[
            Text(
              'Items',
              style: AppTextStyles.subtitle1.copyWith(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            ...controller.items.map((item) => _buildItemRow(item)),
          ],
          const SizedBox(height: 12),
          // Raw text section (collapsible)
          ExpansionTile(
            title: Text(
              'Raw OCR Text',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            tilePadding: EdgeInsets.zero,
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  controller.extractedText.value,
                  style: AppTextStyles.caption.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                onPressed: () => controller.copyText(controller.extractedText.value),
                tooltip: 'Copy',
              ),
              IconButton(
                icon: const Icon(Icons.share, size: 16),
                onPressed: () => controller.shareText(controller.extractedText.value),
                tooltip: 'Share',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body1.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              item['name'] ?? '',
              style: AppTextStyles.body2,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              item['price'] ?? '',
              style: AppTextStyles.body2.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(ReceiptScannerController controller) {
    if (controller.extractedText.value.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Obx(() => ElevatedButton.icon(
          onPressed: controller.isGeneratingSummary.value
              ? null
              : controller.generateSummary,
          icon: controller.isGeneratingSummary.value
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.surface,
                  ),
                )
              : const Icon(Icons.auto_awesome, size: 18),
          label: Text(
            controller.isGeneratingSummary.value
                ? 'Generating...'
                : 'Generate AI Summary',
            style: const TextStyle(fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        )),
        const SizedBox(height: 12),
        if (controller.generatedSummary.value.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.summarize,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI Summary',
                          style: AppTextStyles.subtitle1.copyWith(
                            color: AppColors.primary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy, size: 16),
                          onPressed: () => controller.copyText(controller.generatedSummary.value),
                          tooltip: 'Copy',
                        ),
                        IconButton(
                          icon: const Icon(Icons.share, size: 16),
                          onPressed: () => controller.shareText(controller.generatedSummary.value),
                          tooltip: 'Share',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  controller.generatedSummary.value,
                  style: AppTextStyles.body2.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSaveButton(ReceiptScannerController controller) {
    if (controller.extractedText.value.isEmpty) {
      return const SizedBox.shrink();
    }

    return Obx(() => ElevatedButton.icon(
      onPressed: controller.isLoading.value
          ? null
          : controller.saveReceipt,
      icon: controller.isLoading.value
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.surface,
              ),
            )
          : const Icon(Icons.save),
      label: Text(
        controller.isLoading.value ? 'Saving...' : 'Save Receipt',
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.success,
        foregroundColor: AppColors.surface,
      ),
    ));
  }

  void _showHistoryDialog(ReceiptScannerController controller) {
    if (controller.receiptHistory.isEmpty) {
      Get.snackbar(
        'History',
        'No saved receipts',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.dialog(
      AlertDialog(
        title: const Text('Receipt History'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: controller.receiptHistory.length,
            itemBuilder: (context, index) {
              final receipt = controller.receiptHistory[index];
              return ListTile(
                leading: const Icon(Icons.receipt_long),
                title: Text(
                  receipt['storeName']?.toString() ?? 'Unknown Store',
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${receipt['date'] ?? 'No date'} • ${receipt['totalAmount'] ?? 'No total'}',
                  style: AppTextStyles.caption,
                ),
                onTap: () {
                  Get.back();
                  _showReceiptDetailDialog(receipt);
                },
              );
            },
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

  void _showReceiptDetailDialog(Map<String, dynamic> receipt) {
    Get.dialog(
      AlertDialog(
        title: Text(receipt['storeName']?.toString() ?? 'Receipt Details'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (receipt['date'] != null)
                  _buildDetailRow('Date', receipt['date'].toString()),
                if (receipt['totalAmount'] != null)
                  _buildDetailRow('Total', receipt['totalAmount'].toString()),
                const SizedBox(height: 16),
                if (receipt['items'] != null) ...[
                  Text('Items', style: AppTextStyles.headline6.copyWith(fontSize: 16)),
                  const SizedBox(height: 8),
                  ...(receipt['items'] as List).map((item) => _buildItemRow(item)),
                ],
                const SizedBox(height: 16),
                if (receipt['summary'] != null) ...[
                  Text('AI Summary', style: AppTextStyles.headline6.copyWith(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(receipt['summary'].toString(), style: AppTextStyles.body2),
                ],
              ],
            ),
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
