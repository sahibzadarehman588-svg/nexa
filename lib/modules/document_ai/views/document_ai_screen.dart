import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/document_ai_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class DocumentAIScreen extends StatelessWidget {
  const DocumentAIScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DocumentAIController controller = Get.find<DocumentAIController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Document AI'),
        backgroundColor: AppColors.surfaceElevated,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistoryDialog(controller),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Preview
            Obx(() => _buildImagePreview(controller)),

            const SizedBox(height: 16),

            // Action Buttons
            _buildActionButtons(controller),

            const SizedBox(height: 24),

            // Extracted Text Section
            Obx(() => _buildExtractedTextSection(controller)),

            const SizedBox(height: 24),

            // Generated Summary Section
            Obx(() => _buildSummarySection(controller)),

            const SizedBox(height: 24),

            // Save Button
            Obx(() => _buildSaveButton(controller)),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(DocumentAIController controller) {
    if (controller.selectedImagePath.value.isEmpty) {
      return Container(
        height: 200,
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
                Icons.description,
                size: 48,
                color: AppColors.textHint,
              ),
              const SizedBox(height: 8),
              Text(
                'No document selected',
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
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildActionButtons(DocumentAIController controller) {
    return Row(
      children: [
        Expanded(
          child: Obx(() => ElevatedButton.icon(
            onPressed: controller.isProcessingImage.value
                ? null
                : controller.pickImageFromCamera,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Camera'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
            ),
          )),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Obx(() => ElevatedButton.icon(
            onPressed: controller.isProcessingImage.value
                ? null
                : controller.pickImageFromGallery,
            icon: const Icon(Icons.photo_library),
            label: const Text('Gallery'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.surface,
            ),
          )),
        ),
      ],
    );
  }

  Widget _buildExtractedTextSection(DocumentAIController controller) {
    if (controller.extractedText.value.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
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
                    Icons.text_snippet,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Extracted Text',
                    style: AppTextStyles.headline6.copyWith(
                      color: AppColors.primary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () => controller.copyText(controller.extractedText.value),
                    tooltip: 'Copy',
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, size: 18),
                    onPressed: () => controller.shareText(controller.extractedText.value),
                    tooltip: 'Share',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            controller.extractedText.value,
            style: AppTextStyles.body2,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _showFullTextDialog(
              'Extracted Text',
              controller.extractedText.value,
            ),
            child: const Text('View Full Text'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(DocumentAIController controller) {
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
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.surface,
                  ),
                )
              : const Icon(Icons.auto_awesome),
          label: Text(
            controller.isGeneratingSummary.value
                ? 'Generating...'
                : 'Generate AI Summary',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.surface,
          ),
        )),
        const SizedBox(height: 16),
        if (controller.generatedSummary.value.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16.0),
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
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI Summary',
                          style: AppTextStyles.headline6.copyWith(
                            color: AppColors.primary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          onPressed: () => controller.copyText(controller.generatedSummary.value),
                          tooltip: 'Copy',
                        ),
                        IconButton(
                          icon: const Icon(Icons.share, size: 18),
                          onPressed: () => controller.shareText(controller.generatedSummary.value),
                          tooltip: 'Share',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  controller.generatedSummary.value,
                  style: AppTextStyles.body2,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSaveButton(DocumentAIController controller) {
    if (controller.extractedText.value.isEmpty) {
      return const SizedBox.shrink();
    }

    return Obx(() => ElevatedButton.icon(
      onPressed: controller.isLoading.value
          ? null
          : controller.saveDocument,
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
        controller.isLoading.value ? 'Saving...' : 'Save Document',
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.success,
        foregroundColor: AppColors.surface,
      ),
    ));
  }

  void _showFullTextDialog(String title, String text) {
    Get.dialog(
      AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(text),
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

  void _showHistoryDialog(DocumentAIController controller) {
    if (controller.documentHistory.isEmpty) {
      Get.snackbar(
        'History',
        'No saved documents',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.dialog(
      AlertDialog(
        title: const Text('Document History'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: controller.documentHistory.length,
            itemBuilder: (context, index) {
              final doc = controller.documentHistory[index];
              return ListTile(
                leading: const Icon(Icons.description),
                title: Text(
                  doc['text'].toString().substring(
                    0,
                    doc['text'].toString().length > 30 ? 30 : doc['text'].toString().length,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  DateTime.parse(doc['createdAt']).toString().split('.')[0],
                  style: AppTextStyles.caption,
                ),
                onTap: () {
                  Get.back();
                  _showFullTextDialog(
                    'Document Summary',
                    doc['summary']?.toString() ?? doc['text'].toString(),
                  );
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
}
