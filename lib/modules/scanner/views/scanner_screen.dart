import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/scanner_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ScannerController scannerController = Get.find<ScannerController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Product Scanner'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.cancel),
            onPressed: scannerController.cancelScan,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Selection Section
            _buildImageSelectionSection(scannerController),
            const SizedBox(height: 24),

            // Image Preview Section
            Obx(() {
              if (scannerController.selectedImagePath.value.isEmpty) {
                return _buildEmptyImageState();
              }
              return _buildImagePreview(scannerController);
            }),
            const SizedBox(height: 24),

            // Processing Indicator
            Obx(() {
              if (scannerController.isProcessingImage.value) {
                return _buildProcessingIndicator();
              }
              return const SizedBox.shrink();
            }),
            const SizedBox(height: 24),

            // Extracted Data Section
            Obx(() {
              if (scannerController.extractedProductName.value.isEmpty &&
                  scannerController.selectedImagePath.value.isNotEmpty) {
                return _buildNoDataDetected(scannerController);
              }
              if (scannerController.extractedProductName.value.isNotEmpty ||
                  scannerController.extractedExpiryDate.value != null) {
                return _buildExtractedDataSection(scannerController);
              }
              return const SizedBox.shrink();
            }),
            const SizedBox(height: 24),

            // Product Form Section
            Obx(() {
              if (scannerController.selectedImagePath.value.isNotEmpty) {
                return _buildProductForm(scannerController, context);
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSelectionSection(ScannerController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Image',
              style: AppTextStyles.headline6,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: controller.pickImageFromCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.pickImageFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyImageState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.image_outlined,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              'No Image Selected',
              style: AppTextStyles.body1.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select an image to scan for product information',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(ScannerController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Selected Image',
                  style: AppTextStyles.headline6,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    controller.selectedImagePath.value = '';
                    controller.extractedProductName.value = '';
                    controller.extractedExpiryDate.value = null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(controller.selectedImagePath.value),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingIndicator() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
            Text(
              'Processing image...',
              style: AppTextStyles.body2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataDetected(ScannerController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: AppColors.warning,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No product information detected. Please enter details manually.',
                style: AppTextStyles.body2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtractedDataSection(ScannerController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Extracted Information',
              style: AppTextStyles.headline6,
            ),
            const SizedBox(height: 16),
            if (controller.extractedProductName.value.isNotEmpty)
              _buildExtractedField(
                'Product Name',
                controller.extractedProductName.value,
              ),
            if (controller.extractedExpiryDate.value != null)
              _buildExtractedField(
                'Expiry Date',
                app_date_utils.DateUtils.formatDisplayDate(
                  controller.extractedExpiryDate.value!,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Please review and edit the information below before saving.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtractedField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.body2,
          ),
        ],
      ),
    );
  }

  Widget _buildProductForm(ScannerController controller, BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Details',
              style: AppTextStyles.headline6,
            ),
            const SizedBox(height: 16),

            // Product Name
            Obx(() => TextField(
                  controller: controller.productNameController,
                  decoration: InputDecoration(
                    labelText: 'Product Name',
                    hintText: 'Enter product name',
                    prefixIcon: const Icon(Icons.inventory_2_outlined),
                    errorText: controller.productNameError.value.isEmpty
                        ? null
                        : controller.productNameError.value,
                  ),
                  onChanged: (value) => controller.productName.value = value,
                )),
            const SizedBox(height: 16),

            // Quantity
            Obx(() => TextField(
                  onChanged: (value) => controller.quantity.value =
                      int.tryParse(value) ?? 1,
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    hintText: 'Enter quantity',
                    prefixIcon: const Icon(Icons.format_list_numbered),
                    errorText: controller.quantityError.value.isEmpty
                        ? null
                        : controller.quantityError.value,
                  ),
                  keyboardType: TextInputType.number,
                  controller: controller.quantityController,
                )),
            const SizedBox(height: 16),

            // Expiry Date
            Obx(() => InkWell(
                  onTap: () => controller.selectExpiryDate(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Expiry Date',
                      hintText: 'Select expiry date',
                      prefixIcon: const Icon(Icons.calendar_today),
                      errorText: controller.expiryDateError.value.isEmpty
                          ? null
                          : controller.expiryDateError.value,
                      suffixIcon: const Icon(Icons.arrow_drop_down),
                    ),
                    child: Text(
                      controller.expiryDate.value != null
                          ? app_date_utils.DateUtils.formatDisplayDate(
                              controller.expiryDate.value!)
                          : 'Select date',
                      style: AppTextStyles.body2,
                    ),
                  ),
                )),
            const SizedBox(height: 16),

            // Category (Optional)
            Obx(() => TextField(
                  onChanged: (value) => controller.category.value = value,
                  decoration: const InputDecoration(
                    labelText: 'Category (Optional)',
                    hintText: 'Enter category',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  controller: controller.categoryController,
                )),
            const SizedBox(height: 24),

            // Save Button
            Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.saveProduct,
                    child: controller.isLoading.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.surface,
                            ),
                          )
                        : const Text('Save Product'),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
