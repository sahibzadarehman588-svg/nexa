import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../data/services/firestore_service.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/controllers/auth_controller.dart';

class ProfileController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();
  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Reactive state
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isUploadingPhoto = false.obs;

  // User data
  final RxString name = ''.obs;
  final RxString email = ''.obs;
  final RxString profilePhotoUrl = ''.obs;

  // Edit state
  final RxString editedName = ''.obs;
  final RxBool isEditing = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
  }

  void _loadUserData() {
    if (_authController.currentUser.value != null) {
      name.value = _authController.currentUser.value!.displayName ?? '';
      email.value = _authController.currentUser.value!.email;
      
      // Only set profile photo URL if it's valid and not empty
      final photoUrl = _authController.currentUser.value!.profilePhotoUrl ?? '';
      if (photoUrl.isNotEmpty && _isValidImageUrl(photoUrl)) {
        profilePhotoUrl.value = photoUrl;
      } else {
        profilePhotoUrl.value = '';
      }
      
      editedName.value = name.value;
    }
  }

  bool _isValidImageUrl(String url) {
    // Basic validation to check if URL looks like a valid image URL
    if (url.isEmpty) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }

  void startEditing() {
    isEditing.value = true;
    editedName.value = name.value;
  }

  void cancelEditing() {
    isEditing.value = false;
    editedName.value = name.value;
  }

  Future<void> saveName() async {
    if (editedName.value.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Name cannot be empty',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return;
    }

    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';

    try {
      final currentUser = _authController.currentUser.value;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      final updatedUser = currentUser.copyWith(
        displayName: editedName.value.trim(),
      );

      await _firestoreService.updateUser(updatedUser);

      // Update local state
      name.value = editedName.value.trim();
      isEditing.value = false;

      // Update AuthController user data
      _authController.currentUser.value = updatedUser;

      Get.snackbar(
        'Success',
        'Profile Updated Successfully',
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
      isLoading.value = false;
    }
  }

  Future<void> pickImageFromCamera() async {
    try {
      // Check camera permission
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        Get.snackbar(
          'Error',
          'Camera permission is required',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
        return;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadProfilePhoto(image);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
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
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadProfilePhoto(image);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }

  Future<void> _uploadProfilePhoto(XFile image) async {
    isUploadingPhoto.value = true;

    try {
      final currentUser = _authController.currentUser.value;
      if (currentUser == null) {
        debugPrint('❌ Profile Photo Upload: No user logged in');
        throw Exception('No user logged in');
      }

      debugPrint('📸 Profile Photo Upload Started');
      debugPrint('👤 User ID: ${currentUser.userId}');
      debugPrint('📁 Image Path: ${image.path}');
      debugPrint('📏 Image Size: ${await image.length()} bytes');

      // Verify file exists and is readable
      final file = File(image.path);
      if (!await file.exists()) {
        debugPrint('❌ Profile Photo Upload: File does not exist at ${image.path}');
        throw Exception('Selected image file does not exist');
      }

      // Log Firebase Storage configuration
      try {
        final app = Firebase.app();
        debugPrint('🔥 Firebase App: ${app.name}');
        debugPrint('🪣 Storage Bucket: ${_storage.bucket}');
      } catch (e) {
        debugPrint('❌ Firebase app check failed: $e');
      }

      // Upload to Firebase Storage with consistent path and filename
      final storagePath = 'profile_images/${currentUser.userId}/profile.jpg';
      debugPrint('📤 Storage Path: $storagePath');
      
      final storageRef = _storage.ref().child(storagePath);
      
      debugPrint('⏳ Starting upload...');
      final uploadTask = storageRef.putFile(file);

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        debugPrint('📊 Upload Progress: ${(snapshot.bytesTransferred / snapshot.totalBytes * 100).toStringAsFixed(1)}%');
      });

      // Wait for upload to complete
      final snapshot = await uploadTask;
      debugPrint('✅ Upload completed successfully');
      debugPrint('📊 Upload State: ${snapshot.state}');
      
      if (snapshot.state != TaskState.success) {
        debugPrint('❌ Upload failed with state: ${snapshot.state}');
        throw Exception('Upload failed with state: ${snapshot.state}');
      }

      debugPrint('🔗 Getting download URL...');
      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('✅ Download URL obtained: $downloadUrl');

      // Update Firestore with the photo URL
      debugPrint('💾 Updating Firestore user document...');
      final updatedUser = currentUser.copyWith(
        profilePhotoUrl: downloadUrl,
      );

      await _firestoreService.updateUser(updatedUser);
      debugPrint('✅ Firestore updated successfully');

      // Update local state
      profilePhotoUrl.value = downloadUrl;

      // Update AuthController user data
      _authController.currentUser.value = updatedUser;

      Get.snackbar(
        'Success',
        'Profile photo updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
    } on FirebaseException catch (e) {
      debugPrint('❌ FirebaseException during upload:');
      debugPrint('   Code: ${e.code}');
      debugPrint('   Message: ${e.message}');
      debugPrint('   Stack Trace: ${e.stackTrace}');
      
      String errorMessage;
      switch (e.code) {
        case 'object-not-found':
          errorMessage = 'Storage bucket or path not found. Please check Firebase configuration.';
          break;
        case 'permission-denied':
        case 'unauthorized':
          errorMessage = 'Permission denied. User does not have access to upload profile photos.';
          break;
        case 'bucket-not-found':
          errorMessage = 'Firebase Storage bucket not found. Please check Firebase project configuration.';
          break;
        case 'canceled':
          errorMessage = 'Upload was canceled.';
          break;
        case 'unknown':
          errorMessage = 'Unknown error occurred during upload.';
          break;
        default:
          errorMessage = 'Upload failed: ${e.message ?? e.code}';
      }
      
      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } catch (e) {
      debugPrint('❌ Exception during upload: $e');
      debugPrint('   Stack Trace: ${StackTrace.current}');
      
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      
      // Provide user-friendly error message for common errors
      if (errorMessage.contains('object-not-found') || 
          errorMessage.contains('No object exists')) {
        errorMessage = 'Storage configuration error. Please check Firebase setup.';
      } else if (errorMessage.contains('permission-denied') || 
                 errorMessage.contains('unauthorized')) {
        errorMessage = 'Permission denied. Please check your account settings.';
      } else if (errorMessage.contains('network')) {
        errorMessage = 'Network error. Please check your connection and try again.';
      } else if (errorMessage.contains('File does not exist')) {
        errorMessage = 'Selected image file not found. Please try again.';
      }
      
      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isUploadingPhoto.value = false;
    }
  }

  void showImagePickerBottomSheet() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Get.theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose Photo',
              style: AppTextStyles.headline6,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Get.back();
                pickImageFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Get.back();
                pickImageFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> logout() async {
    await _authController.logout();
  }
}
