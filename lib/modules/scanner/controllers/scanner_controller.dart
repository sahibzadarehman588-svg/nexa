import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../data/services/ocr_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/firestore_service.dart';
import '../../../data/models/product_model.dart';
import '../../../core/constants/app_constants.dart';

class ScannerController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final OCRService _ocrService = OCRService();
  final StorageService _storageService = StorageService();
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _imagePicker = ImagePicker();

  // Reactive state
  final RxBool isLoading = false.obs;
  final RxBool isProcessingImage = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString selectedImagePath = ''.obs;

  // Extracted data
  final RxString extractedProductName = ''.obs;
  final Rx<DateTime?> extractedExpiryDate = Rx<DateTime?>(null);
  final RxString extractedRawText = ''.obs;

  // Editable data
  final RxString productName = ''.obs;
  final RxInt quantity = 1.obs;
  final Rx<DateTime?> expiryDate = Rx<DateTime?>(null);
  final RxString category = ''.obs;

  // Form errors
  final RxString productNameError = ''.obs;
  final RxString quantityError = ''.obs;
  final RxString expiryDateError = ''.obs;

  // Text editing controllers
  final TextEditingController productNameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    productNameController.text = productName.value;
    quantityController.text = quantity.value.toString();
    categoryController.text = category.value;
  }

  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<void> pickImageFromCamera() async {
    final hasPermission = await requestCameraPermission();
    if (!hasPermission) {
      Get.snackbar(
        'Permission Denied',
        AppConstants.errorCameraPermission,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: AppConstants.imageQuality,
      );

      if (image != null) {
        selectedImagePath.value = image.path;
        await _processImage(image.path);
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }

  Future<void> pickImageFromGallery() async {
    final hasPermission = await requestStoragePermission();
    if (!hasPermission) {
      Get.snackbar(
        'Permission Denied',
        AppConstants.errorStoragePermission,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: AppConstants.imageQuality,
      );

      if (image != null) {
        selectedImagePath.value = image.path;
        await _processImage(image.path);
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }

  Future<void> _processImage(String imagePath) async {
    isProcessingImage.value = true;
    hasError.value = false;
    errorMessage.value = '';

    try {
      final imageFile = File(imagePath);

      // Check file size
      final fileSize = await imageFile.length();
      if (fileSize > AppConstants.maxImageSize) {
        throw Exception(AppConstants.errorInvalidImage);
      }

      // Extract product information using OCR
      final productInfo = await _ocrService.extractProductInfo(imageFile);

      // Update extracted data
      extractedProductName.value = productInfo['productName'] ?? '';
      extractedExpiryDate.value = productInfo['expiryDate'];
      extractedRawText.value = productInfo['rawText'] ?? '';

      // Initialize editable data with extracted values
      productName.value = extractedProductName.value;
      expiryDate.value = extractedExpiryDate.value;
      
      // Update controllers
      productNameController.text = productName.value;
      quantityController.text = quantity.value.toString();
      categoryController.text = category.value;

      Get.snackbar(
        'Success',
        'Image processed successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isProcessingImage.value = false;
    }
  }

  bool validateProductForm() {
    productNameError.value = productName.value.isEmpty
        ? 'Product name is required'
        : '';
    quantityError.value = quantity.value < 0
        ? 'Quantity must be positive'
        : '';
    expiryDateError.value = expiryDate.value == null
        ? 'Expiry date is required'
        : '';

    return productNameError.value.isEmpty &&
        quantityError.value.isEmpty &&
        expiryDateError.value.isEmpty;
  }

  Future<void> saveProduct() async {
    if (!validateProductForm()) return;

    if (_authController.currentUser.value == null) {
      Get.snackbar(
        'Error',
        'User not logged in',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return;
    }

    isLoading.value = true;
    try {
      final userId = _authController.currentUser.value!.userId;
      String? imageUrl;

      // Upload image if selected
      if (selectedImagePath.value.isNotEmpty) {
        final imageFile = File(selectedImagePath.value);
        imageUrl = await _storageService.uploadProductImage(
          userId,
          DateTime.now().millisecondsSinceEpoch.toString(),
          imageFile,
        );
      }

      // Create product model
      final product = ProductModel.create(
        productId: DateTime.now().millisecondsSinceEpoch.toString(),
        productName: productName.value,
        quantity: quantity.value,
        expiryDate: expiryDate.value!,
        productImage: imageUrl,
        category: category.value.isEmpty ? null : category.value,
      );

      // Update status to ensure accuracy
      final updatedProduct = ProductModel.updateStatus(product);

      // Save to Firestore
      await _firestoreService.createProduct(userId, updatedProduct);

      Get.snackbar(
        'Success',
        AppConstants.successProductAdded,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );

      // Reset form
      _resetForm();

      // Navigate back and refresh home
      Get.back(result: true);
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _resetForm() {
    selectedImagePath.value = '';
    extractedProductName.value = '';
    extractedExpiryDate.value = null;
    extractedRawText.value = '';
    productName.value = '';
    quantity.value = 1;
    expiryDate.value = null;
    category.value = '';
    productNameError.value = '';
    quantityError.value = '';
    expiryDateError.value = '';
    hasError.value = false;
    errorMessage.value = '';
    
    // Reset controllers
    productNameController.clear();
    quantityController.clear();
    categoryController.clear();
  }

  void cancelScan() {
    _resetForm();
    Get.back();
  }

  void selectExpiryDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: expiryDate.value ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (picked != null) {
      expiryDate.value = picked;
    }
  }

  @override
  void onClose() {
    productNameController.dispose();
    quantityController.dispose();
    categoryController.dispose();
    super.onClose();
  }
}
