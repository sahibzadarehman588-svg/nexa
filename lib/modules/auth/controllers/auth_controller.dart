import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/firestore_service.dart';
import '../../../core/utils/validators.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  // Reactive state
  final RxBool isLoading = false.obs;
  final RxBool isLoggedIn = false.obs;
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  // Form state
  final RxString email = ''.obs;
  final RxString password = ''.obs;
  final RxString name = ''.obs;
  final RxString confirmPassword = ''.obs;

  // Error state
  final RxString emailError = ''.obs;
  final RxString passwordError = ''.obs;
  final RxString nameError = ''.obs;
  final RxString confirmPasswordError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _checkAuthState();
  }

  void _checkAuthState() {
    _authService.authStateChanges().listen((user) {
      if (user != null) {
        isLoggedIn.value = true;
        _loadUserData(user.uid);
      } else {
        isLoggedIn.value = false;
        currentUser.value = null;
      }
    });
  }

  Future<void> _loadUserData(String userId) async {
    try {
      final user = await _firestoreService.getUser(userId);
      if (user != null) {
        currentUser.value = user;
      }
    } catch (e) {
      // Error loading user data
      debugPrint('Error loading user data: $e');
    }
  }

  // Validation methods
  bool validateLogin() {
    emailError.value = Validators.validateEmail(email.value) ?? '';
    passwordError.value = Validators.validatePassword(password.value) ?? '';
    return emailError.value.isEmpty && passwordError.value.isEmpty;
  }

  bool validateSignup() {
    nameError.value = Validators.validateName(name.value) ?? '';
    emailError.value = Validators.validateEmail(email.value) ?? '';
    passwordError.value = Validators.validatePassword(password.value) ?? '';
    confirmPasswordError.value = Validators.validateConfirmPassword(
      confirmPassword.value,
      password.value,
    ) ?? '';
    return nameError.value.isEmpty &&
        emailError.value.isEmpty &&
        passwordError.value.isEmpty &&
        confirmPasswordError.value.isEmpty;
  }

  // Login method
  Future<void> login() async {
    if (!validateLogin()) return;

    isLoading.value = true;
    try {
      final user = await _authService.signInWithEmailAndPassword(
        email.value,
        password.value,
      );

      // Check if user exists in Firestore
      final existingUser = await _firestoreService.getUser(user.userId);
      if (existingUser == null) {
        // Create user in Firestore if doesn't exist
        await _firestoreService.createUser(user);
      }

      currentUser.value = user;
      isLoggedIn.value = true;

      Get.snackbar(
        'Success',
        AppConstants.successLogin,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );

      Get.offAllNamed(AppRoutes.home);
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

  // Signup method
  Future<void> signup() async {
    if (!validateSignup()) return;

    isLoading.value = true;
    try {
      final user = await _authService.signUpWithEmailAndPassword(
        email.value,
        password.value,
        name.value,
      );

      // Create user in Firestore
      await _firestoreService.createUser(user);

      currentUser.value = user;
      isLoggedIn.value = true;

      Get.snackbar(
        'Success',
        AppConstants.successSignup,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );

      Get.offAllNamed(AppRoutes.home);
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

  // Logout method
  Future<void> logout() async {
    try {
      await _authService.signOut();
      isLoggedIn.value = false;
      currentUser.value = null;

      // Clear form data
      email.value = '';
      password.value = '';
      name.value = '';
      confirmPassword.value = '';

      Get.snackbar(
        'Success',
        AppConstants.successLogout,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );

      Get.offAllNamed(AppRoutes.login);
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

  // Password reset method
  Future<void> resetPassword() async {
    if (email.value.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your email address',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return;
    }

    isLoading.value = true;
    try {
      await _authService.sendPasswordResetEmail(email.value);
      Get.snackbar(
        'Success',
        'Password reset email sent successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
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

  // Navigation methods
  void goToSignup() {
    Get.toNamed(AppRoutes.signup);
  }

  void goToLogin() {
    Get.back();
  }

  void goToForgotPassword() {
    Get.dialog(
      AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              onChanged: (value) => email.value = value,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: resetPassword,
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }
}
