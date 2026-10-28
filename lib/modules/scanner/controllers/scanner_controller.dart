import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/services/ocr_service.dart';
import '../../../data/services/firestore_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/user_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class ScannerController extends GetxController {
  final OCRService _ocrService = OCRService();
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  // Reactive state
  final RxBool isLoading = false.obs;
  final RxBool isProcessingImage = false.obs;
  final RxBool isScanningCode = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString selectedImagePath = ''.obs;

  // Extracted data
  final RxString extractedProductName = ''.obs;
  final RxString extractedBrand = ''.obs;
  final Rx<DateTime?> extractedExpiryDate = Rx<DateTime?>(null);
  final RxString extractedBatchNumber = ''.obs;
  final RxString extractedRawText = ''.obs;
  final RxString scannedCode = ''.obs;

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
    // Check if permission is already granted
    if (await Permission.photos.isGranted) {
      return true;
    }
    if (await Permission.storage.isGranted) {
      return true;
    }

    // Request permission based on Android version
    // For Android 13+ (API 33+), use READ_MEDIA_IMAGES (Permission.photos)
    // For Android 12 and below, use READ_EXTERNAL_STORAGE (Permission.storage)
    final photosStatus = await Permission.photos.request();
    
    if (photosStatus.isGranted) {
      return true;
    }

    // If photos permission denied, try storage permission for older Android versions
    final storageStatus = await Permission.storage.request();
    return storageStatus.isGranted;
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

  Future<void> scanQRBarcode() async {
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

    isScanningCode.value = true;
    hasError.value = false;
    errorMessage.value = '';

    try {
      // Navigate to QR/Barcode scanner screen
      final result = await Get.toNamed('/scanner/qr-barcode');

      if (result != null && result is String) {
        scannedCode.value = result;
        await _processScannedCode(result);
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
    } finally {
      isScanningCode.value = false;
    }
  }

  Future<void> _processScannedCode(String code) async {
    debugPrint('=== Processing scanned code ===');
    debugPrint('Scanned code: $code');

    try {
      // Parse the scanned code to extract product information
      final productInfo = _parseScannedCode(code);

      // Update extracted data
      extractedProductName.value = productInfo['productName'] ?? '';
      extractedBrand.value = productInfo['brand'] ?? '';
      extractedExpiryDate.value = productInfo['expiryDate'];
      extractedBatchNumber.value = productInfo['batchNumber'] ?? '';
      extractedRawText.value = code;

      // Initialize editable data with extracted values
      productName.value = extractedProductName.value;
      expiryDate.value = extractedExpiryDate.value;
      // Use extracted brand as category if available
      if (extractedBrand.value.isNotEmpty && category.value.isEmpty) {
        category.value = extractedBrand.value;
      }

      // Update controllers
      productNameController.text = productName.value;
      quantityController.text = quantity.value.toString();
      categoryController.text = category.value;

      // Show message if some information was not found
      if (productName.value.isEmpty) {
        Get.snackbar(
          'Partial Data',
          'Some product information was not found. Please enter it manually.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.warning,
          colorText: Get.theme.colorScheme.onError,
          duration: const Duration(seconds: 3),
        );
      } else {
        Get.snackbar(
          'Success',
          'Code scanned successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      Get.snackbar(
        'Error',
        'Failed to process scanned code. Please enter product details manually.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }

  Map<String, dynamic> _parseScannedCode(String code) {
    debugPrint('=== Parsing scanned code ===');
    final productInfo = <String, dynamic>{};

    try {
      // Try to parse as JSON (for structured QR codes)
      if (code.startsWith('{') && code.endsWith('}')) {
        try {
          final jsonData = _parseJsonString(code);
          if (jsonData != null) {
            productInfo['productName'] = jsonData['name'] ?? jsonData['productName'] ?? jsonData['title'];
            productInfo['brand'] = jsonData['brand'] ?? jsonData['company'] ?? jsonData['manufacturer'];
            productInfo['batchNumber'] = jsonData['batch'] ?? jsonData['batchNumber'] ?? jsonData['lot'];
            productInfo['expiryDate'] = _parseDate(jsonData['expiry'] ?? jsonData['expiryDate'] ?? jsonData['exp']);
            debugPrint('✅ Parsed as JSON: $productInfo');
            return productInfo;
          }
        } catch (e) {
          debugPrint('⚠️ JSON parsing failed, trying other formats');
        }
      }

      // Try to parse as URL-encoded data
      if (code.contains('?') && code.contains('=')) {
        final uri = Uri.parse(code);
        final params = uri.queryParameters;
        productInfo['productName'] = params['name'] ?? params['product'] ?? params['title'];
        productInfo['brand'] = params['brand'] ?? params['company'];
        productInfo['batchNumber'] = params['batch'] ?? params['lot'];
        productInfo['expiryDate'] = _parseDate(params['expiry'] ?? params['exp']);
        if (productInfo['productName'] != null) {
          debugPrint('✅ Parsed as URL: $productInfo');
          return productInfo;
        }
      }

      // Try to parse as pipe-delimited format (common in barcodes)
      if (code.contains('|')) {
        final parts = code.split('|');
        if (parts.length >= 2) {
          productInfo['productName'] = parts[0];
          productInfo['brand'] = parts.length > 1 ? parts[1] : null;
          productInfo['batchNumber'] = parts.length > 2 ? parts[2] : null;
          productInfo['expiryDate'] = parts.length > 3 ? _parseDate(parts[3]) : null;
          debugPrint('✅ Parsed as pipe-delimited: $productInfo');
          return productInfo;
        }
      }

      // Try to parse as comma-delimited format
      if (code.contains(',')) {
        final parts = code.split(',');
        if (parts.length >= 2) {
          productInfo['productName'] = parts[0];
          productInfo['brand'] = parts.length > 1 ? parts[1] : null;
          productInfo['batchNumber'] = parts.length > 2 ? parts[2] : null;
          productInfo['expiryDate'] = parts.length > 3 ? _parseDate(parts[3]) : null;
          debugPrint('✅ Parsed as comma-delimited: $productInfo');
          return productInfo;
        }
      }

      // If no structured data found, use the code as product name/SKU
      if (code.isNotEmpty) {
        productInfo['productName'] = code;
        debugPrint('✅ Using code as product name: $code');
      }

      debugPrint('📋 Final parsed data: $productInfo');
      return productInfo;
    } catch (e) {
      debugPrint('❌ Error parsing code: $e');
      productInfo['productName'] = code; // Fallback to using code as name
      return productInfo;
    }
  }

  Map<String, dynamic>? _parseJsonString(String jsonString) {
    try {
      // Simple JSON parser for basic key-value pairs
      final result = <String, dynamic>{};
      final cleanString = jsonString.replaceAll('{', '').replaceAll('}', '').replaceAll('"', '').replaceAll("'", '');
      final pairs = cleanString.split(',');

      for (final pair in pairs) {
        final keyValue = pair.split(':');
        if (keyValue.length == 2) {
          result[keyValue[0].trim()] = keyValue[1].trim();
        }
      }
      return result;
    } catch (e) {
      debugPrint('❌ JSON parsing error: $e');
      return null;
    }
  }

  DateTime? _parseDate(dynamic dateValue) {
    if (dateValue == null) return null;

    try {
      if (dateValue is DateTime) {
        return dateValue;
      }

      if (dateValue is String) {
        // Try direct parsing
        try {
          final parsed = DateTime.parse(dateValue);
          if (parsed.year > 2000) {
            return parsed;
          }
        } catch (e) {
          debugPrint('❌ Date parsing error: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Date parsing error: $e');
    }

    return null;
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
      extractedBrand.value = productInfo['brand'] ?? '';
      extractedExpiryDate.value = productInfo['expiryDate'];
      extractedBatchNumber.value = productInfo['batchNumber'] ?? '';
      extractedRawText.value = productInfo['rawText'] ?? '';

      // Initialize editable data with extracted values
      productName.value = extractedProductName.value;
      expiryDate.value = extractedExpiryDate.value;
      // Use extracted brand as category if available
      if (extractedBrand.value.isNotEmpty && category.value.isEmpty) {
        category.value = extractedBrand.value;
      }

      // Update controllers
      productNameController.text = productName.value;
      quantityController.text = quantity.value.toString();
      categoryController.text = category.value;

      // Clear the temporary image path after OCR processing
      // Image is only used temporarily for extraction, not retained
      selectedImagePath.value = '';

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
    // Expiry date is required for tracking
    expiryDateError.value = expiryDate.value == null
        ? 'Expiry date is required'
        : '';

    return productNameError.value.isEmpty &&
        quantityError.value.isEmpty &&
        expiryDateError.value.isEmpty;
  }

  Future<void> saveProduct() async {
    if (!validateProductForm()) return;

    // Check if user is logged in via Firebase Auth
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      Get.snackbar(
        'Error',
        'User not logged in. Please login first.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return;
    }

    // Ensure expiry date is set
    if (expiryDate.value == null) {
      Get.snackbar(
        'Error',
        'Please select an expiry date',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return;
    }

    isLoading.value = true;
    try {
      // Use Firebase Auth UID directly
      final userId = firebaseUser.uid;

      // Ensure user document exists in Firestore
      final existingUser = await _firestoreService.getUser(userId);
      if (existingUser == null) {
        // Create user document if it doesn't exist
        final userModel = UserModel(
          userId: userId,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName,
          createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _firestoreService.createUser(userModel);
      }

      // Create product model with unique ID (no image upload for scanned products)
      final productId = '${DateTime.now().millisecondsSinceEpoch}_${firebaseUser.uid.substring(0, 8)}';
      final product = ProductModel.create(
        productId: productId,
        productName: productName.value,
        quantity: quantity.value,
        expiryDate: expiryDate.value!,
        productImage: null,
        category: category.value.isEmpty ? null : category.value,
      );

      // Update status to ensure accuracy
      final updatedProduct = ProductModel.updateStatus(product);

      // Save to Firestore
      await _firestoreService.createProduct(userId, updatedProduct);

      // Schedule expiry notifications if expiry date is in the future (date-only comparison)
      final now = DateTime.now();
      final normalizedNow = DateTime(now.year, now.month, now.day);
      final normalizedExpiryDate = DateTime(updatedProduct.expiryDate.year, updatedProduct.expiryDate.month, updatedProduct.expiryDate.day);
      if (normalizedExpiryDate.isAfter(normalizedNow)) {
        await _notificationService.scheduleProductExpiryNotifications(
          productId: updatedProduct.productId,
          productName: updatedProduct.productName,
          expiryDate: updatedProduct.expiryDate,
        );
      }

      // Use GetX root snackbar to persist across navigation
      Get.snackbar(
        'Success',
        AppConstants.successProductAdded,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
        margin: const EdgeInsets.all(16),
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
    extractedBrand.value = '';
    extractedExpiryDate.value = null;
    extractedBatchNumber.value = '';
    extractedRawText.value = '';
    scannedCode.value = '';
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
