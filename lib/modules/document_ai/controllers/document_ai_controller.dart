import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../data/services/ocr_service.dart';
import '../../../data/services/ai_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../core/constants/app_constants.dart';

class DocumentAIController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final OCRService _ocrService = OCRService();
  final AIService _aiService = AIService();
  final StorageService _storageService = StorageService();
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

  // Document history
  final RxList<Map<String, dynamic>> documentHistory = <Map<String, dynamic>>[].obs;

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
        await _processDocument(image.path);
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
        await _processDocument(image.path);
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

  Future<void> _processDocument(String imagePath) async {
    isProcessingImage.value = true;
    hasError.value = false;
    errorMessage.value = '';
    extractedText.value = '';
    generatedSummary.value = '';

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

      Get.snackbar(
        'Success',
        'Text extracted successfully',
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

  Future<void> generateSummary() async {
    if (extractedText.value.isEmpty) {
      Get.snackbar(
        'Error',
        'No text to summarize',
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

  Future<void> saveDocument() async {
    if (extractedText.value.isEmpty) {
      Get.snackbar(
        'Error',
        'No document content to save',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return;
    }

    isLoading.value = true;
    try {
      String? imageUrl;

      // Upload image if selected
      if (selectedImagePath.value.isNotEmpty && _authController.currentUser.value != null) {
        final imageFile = File(selectedImagePath.value);
        final userId = _authController.currentUser.value!.userId;
        imageUrl = await _storageService.uploadDocumentImage(
          userId,
          DateTime.now().millisecondsSinceEpoch.toString(),
          imageFile,
        );
      }

      // Add to history
      final document = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'text': extractedText.value,
        'summary': generatedSummary.value,
        'imageUrl': imageUrl,
        'createdAt': DateTime.now().toIso8601String(),
      };

      documentHistory.insert(0, document);

      Get.snackbar(
        'Success',
        'Document saved successfully',
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
    hasError.value = false;
    errorMessage.value = '';
  }

  void cancelScan() {
    _resetForm();
    Get.back();
  }

  void copyText() {
    // TODO: Implement text copying
    Get.snackbar(
      'Coming Soon',
      'Text copying - Coming Soon',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void shareText() {
    // TODO: Implement text sharing
    Get.snackbar(
      'Coming Soon',
      'Text sharing - Coming Soon',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
