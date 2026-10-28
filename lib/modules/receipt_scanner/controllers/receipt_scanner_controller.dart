import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../data/services/ocr_service.dart';
import '../../../data/services/ai_service.dart';
import '../../../data/services/firestore_service.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/models/user_model.dart';
import '../../../core/constants/app_constants.dart';

class ReceiptScannerController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final OCRService _ocrService = OCRService();
  final AIService _aiService = AIService();
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final ImagePicker _imagePicker = ImagePicker();

  // Reactive state
  final RxBool isLoading = false.obs;
  final RxBool isProcessingImage = false.obs;
  final RxBool isGeneratingSummary = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString selectedImagePath = ''.obs;

  // Extracted data
  final RxString extractedText = ''.obs;
  final RxString generatedSummary = ''.obs;
  final RxString storeName = ''.obs;
  final RxString date = ''.obs;
  final RxString totalAmount = ''.obs;
  final RxList<Map<String, dynamic>> items = <Map<String, dynamic>>[].obs;

  // Receipt history
  final RxList<Map<String, dynamic>> receiptHistory = <Map<String, dynamic>>[].obs;

  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
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
        await _processReceipt(image.path);
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
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: AppConstants.imageQuality,
      );

      if (image != null) {
        selectedImagePath.value = image.path;
        await _processReceipt(image.path);
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

  Future<void> _processReceipt(String imagePath) async {
    isProcessingImage.value = true;
    hasError.value = false;
    errorMessage.value = '';
    extractedText.value = '';
    generatedSummary.value = '';
    storeName.value = '';
    date.value = '';
    totalAmount.value = '';
    items.clear();

    try {
      final imageFile = File(imagePath);

      // Check file size
      final fileSize = await imageFile.length();
      if (fileSize > AppConstants.maxImageSize) {
        throw Exception(AppConstants.errorInvalidImage);
      }

      // Extract text using OCR
      final text = await _ocrService.extractTextFromImage(imageFile);
      extractedText.value = text;

      // Parse receipt data
      _parseReceiptData(text);

      // Clear the temporary image path after OCR processing
      // Image is only used temporarily for extraction, not retained
      selectedImagePath.value = '';

      Get.snackbar(
        'Success',
        'Receipt processed successfully',
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

  void _parseReceiptData(String text) {
    final lines = text.split('\n');

    // Try to extract store name (usually first non-empty line without numbers or currency)
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty &&
          !trimmed.contains('\$') &&
          !trimmed.contains('Total') &&
          !trimmed.contains('TOTAL') &&
          !RegExp(r'\d').hasMatch(trimmed) == false &&
          trimmed.length > 2) {
        storeName.value = trimmed;
        break;
      }
    }

    // Try to extract date
    final datePattern = RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\d{4}[/-]\d{1,2}[/-]\d{1,2}');
    for (final line in lines) {
      final match = datePattern.firstMatch(line);
      if (match != null) {
        date.value = match.group(0) ?? '';
        break;
      }
    }

    // Try to extract total amount (only if it actually contains a currency symbol)
    final totalPattern = RegExp(r'[Tt]otal[\s:]*\$?(\d+[.,]\d*)');
    for (final line in lines) {
      final match = totalPattern.firstMatch(line);
      if (match != null) {
        final amount = match.group(1) ?? '';
        // Only add $ if the line already contains it
        if (line.contains('\$')) {
          totalAmount.value = '\$$amount';
        } else {
          totalAmount.value = amount;
        }
        break;
      }
    }

    // Extract items (lines with prices - only add $ if present in original text)
    final itemPattern = RegExp(r'(.+?)\s+([\d.,]+)');
    for (final line in lines) {
      final trimmed = line.trim();
      // Skip lines that are likely totals, dates, or headers
      if (trimmed.toLowerCase().contains('total') ||
          trimmed.toLowerCase().contains('subtotal') ||
          trimmed.toLowerCase().contains('tax') ||
          datePattern.hasMatch(trimmed) ||
          trimmed.length < 3) {
        continue;
      }

      final match = itemPattern.firstMatch(trimmed);
      if (match != null) {
        final itemName = match.group(1)?.trim() ?? '';
        final priceStr = match.group(2) ?? '';
        
        // Validate that it looks like a price (numbers with decimal)
        if (itemName.isNotEmpty && priceStr.isNotEmpty && RegExp(r'^[\d.,]+$').hasMatch(priceStr)) {
          // Only add $ if the original line contains it
          final price = trimmed.contains('\$') ? '\$$priceStr' : priceStr;
          items.add({
            'name': itemName,
            'price': price,
          });
        }
      }
    }
  }

  Future<void> generateSummary() async {
    if (extractedText.value.isEmpty) {
      Get.snackbar(
        'Error',
        'No receipt data to summarize',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return;
    }

    isGeneratingSummary.value = true;
    try {
      final summary = await _aiService.summarizeDocument(extractedText.value);
      generatedSummary.value = summary;

      Get.snackbar(
        'Success',
        'Summary generated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isGeneratingSummary.value = false;
    }
  }

  Future<void> saveReceipt() async {
    if (extractedText.value.isEmpty) {
      Get.snackbar(
        'Error',
        'No receipt content to save',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return;
    }

    isLoading.value = true;
    try {
      // Check if user is logged in
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        throw Exception('User not logged in');
      }

      final userId = firebaseUser.uid;

      // Ensure user document exists
      final existingUser = await _firestoreService.getUser(userId);
      if (existingUser == null) {
        final userModel = UserModel(
          userId: userId,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _firestoreService.createUser(userModel);
      }

      // Parse total amount from string (remove $ and convert to double)
      double? totalAmountValue;
      if (totalAmount.value.isNotEmpty) {
        final cleanAmount = totalAmount.value.replaceAll('\$', '').replaceAll(',', '').trim();
        totalAmountValue = double.tryParse(cleanAmount);
      }

      // Create items list as strings
      final itemsList = items.map((item) => '${item['name']}: ${item['price']}').toList();

      // Parse expense date
      DateTime expenseDate = DateTime.now();
      if (date.value.isNotEmpty) {
        try {
          expenseDate = DateTime.parse(date.value);
        } catch (e) {
          debugPrint('Failed to parse date, using current date: $e');
        }
      }

      // Create expense model (no image upload)
      final expenseId = '${DateTime.now().millisecondsSinceEpoch}_$userId';
      final expense = ExpenseModel.create(
        expenseId: expenseId,
        merchantName: storeName.value.isNotEmpty ? storeName.value : 'Unknown Store',
        totalAmount: totalAmountValue ?? 0.0,
        receiptImage: null, // No image upload
        expenseDate: expenseDate,
        items: itemsList.isNotEmpty ? itemsList : null,
      );

      // Save to Firestore
      await _firestoreService.createExpense(userId, expense);

      // Add to local history
      final receipt = {
        'id': expenseId,
        'text': extractedText.value,
        'summary': generatedSummary.value,
        'storeName': storeName.value,
        'date': date.value,
        'totalAmount': totalAmount.value,
        'items': items.map((item) => {
          'name': item['name'],
          'price': item['price'],
        }).toList(),
        'imageUrl': null,
        'createdAt': DateTime.now().toIso8601String(),
      };

      receiptHistory.insert(0, receipt);

      Get.snackbar(
        'Success',
        'Receipt saved successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );

      // Reset form
      _resetForm();

      Get.back();
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
    extractedText.value = '';
    generatedSummary.value = '';
    storeName.value = '';
    date.value = '';
    totalAmount.value = '';
    items.clear();
    hasError.value = false;
    errorMessage.value = '';
  }

  void cancelScan() {
    _resetForm();
    Get.back();
  }

  void copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'Copied',
      'Text copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void shareText(String text) {
    // For now, just show a snackbar
    // In a real app, you would use share_plus package
    Get.snackbar(
      'Share',
      'Share functionality coming soon',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> loadReceiptHistory() async {
    if (_authController.currentUser.value == null) return;

    try {
      // In a real implementation, you would load from Firestore
      // For now, we'll use local storage
      // receiptHistory.value = await _firestoreService.getReceiptHistory(userId);
    } catch (e) {
      debugPrint('Failed to load receipt history: $e');
    }
  }
}
