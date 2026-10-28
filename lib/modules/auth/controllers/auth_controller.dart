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
  final RxString secretPassword = ''.obs;
  final RxString name = ''.obs;
  final RxString confirmPassword = ''.obs;

  // Error state
  final RxString emailError = ''.obs;
  final RxString passwordError = ''.obs;
  final RxString secretPasswordError = ''.obs;
  final RxString nameError = ''.obs;
  final RxString confirmPasswordError = ''.obs;

  // Password visibility state
  final RxBool isPasswordVisible = false.obs;
  final RxBool isConfirmPasswordVisible = false.obs;
  final RxBool isSecretPasswordVisible = false.obs;
  final RxBool isLoginPasswordVisible = false.obs;

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
    passwordError.value = Validators.validatePassword(password.value) ?? '';
    return passwordError.value.isEmpty;
  }

  bool validateSignup() {
    nameError.value = Validators.validateName(name.value) ?? '';
    emailError.value = Validators.validateEmail(email.value) ?? '';
    passwordError.value = Validators.validatePassword(password.value) ?? '';
    confirmPasswordError.value = Validators.validateConfirmPassword(
      confirmPassword.value,
      password.value,
    ) ?? '';
    secretPasswordError.value = Validators.validatePassword(secretPassword.value) ?? '';
    return nameError.value.isEmpty &&
        emailError.value.isEmpty &&
        passwordError.value.isEmpty &&
        confirmPasswordError.value.isEmpty &&
        secretPasswordError.value.isEmpty;
  }

  // Login method
  Future<void> login() async {
    if (!validateLogin()) return;

    isLoading.value = true;
    try {
      // Query Firestore for user with matching secret password
      final user = await _firestoreService.getUserBySecretPassword(password.value);

      if (user == null) {
        throw Exception('Invalid Secret Password');
      }

      // Try to sign in with Firebase
      // First try with stored firebasePassword if available
      if (user.firebasePassword != null && user.firebasePassword!.isNotEmpty) {
        try {
          await _authService.signInWithEmailAndPassword(
            user.email,
            user.firebasePassword!,
          );
        } catch (e) {
          // If stored password fails, try with the secret password
          debugPrint('Stored Firebase password failed, trying with secret password');
          await _authService.signInWithEmailAndPassword(
            user.email,
            password.value,
          );
          // Update the stored password
          final updatedUser = user.copyWith(firebasePassword: password.value);
          await _firestoreService.updateUser(updatedUser);
          debugPrint('Updated firebasePassword to match secret password');
        }
      } else {
        // No stored firebasePassword, try with secret password
        await _authService.signInWithEmailAndPassword(
          user.email,
          password.value,
        );
        // Update the user document with the firebasePassword
        final updatedUser = user.copyWith(firebasePassword: password.value);
        await _firestoreService.updateUser(updatedUser);
        debugPrint('Updated user document with firebasePassword');
      }

      // User is now authenticated with Firebase
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

      // Add secret password, Firebase password, and role to user model
      final userWithSecret = user.copyWith(
        secretPassword: secretPassword.value,
        firebasePassword: password.value,
        role: 'user',
      );

      // Create user in Firestore with secret password, Firebase password, and role
      await _firestoreService.createUser(userWithSecret);

      currentUser.value = userWithSecret;
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
    Get.dialog(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _performLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Get.theme.colorScheme.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout() async {
    try {
      await _authService.signOut();
      isLoggedIn.value = false;
      currentUser.value = null;

      // Clear form data
      email.value = '';
      password.value = '';
      secretPassword.value = '';
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

  // Password reset method (for login screen - uses secret password)
  Future<void> resetPasswordWithSecret() async {
    if (password.value.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your Secret Password',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return;
    }

    isLoading.value = true;
    try {
      // Query Firestore for user with matching secret password
      final user = await _firestoreService.getUserBySecretPassword(password.value);

      if (user == null) {
        throw Exception('Invalid Secret Password');
      }

      // Send password reset email to the user's email
      await _authService.sendPasswordResetEmail(user.email);
      
      Get.snackbar(
        'Success',
        'Password reset email sent to ${user.email}. After resetting your Firebase password, you can set a new Secret Password.',
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

  // Update secret password method (for users who reset Firebase password)
  Future<void> updateSecretPassword(String newSecretPassword) async {
    if (currentUser.value == null) {
      throw Exception('No user logged in');
    }

    isLoading.value = true;
    try {
      final updatedUser = currentUser.value!.copyWith(
        secretPassword: newSecretPassword,
        firebasePassword: password.value, // Update Firebase password as well
      );

      await _firestoreService.updateUser(updatedUser);
      currentUser.value = updatedUser;

      Get.snackbar(
        'Success',
        'Secret Password updated successfully',
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
      isLoading.value = false;
    }
  }

  // Password reset method (for email input)
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

  // Password visibility toggle methods
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  void toggleSecretPasswordVisibility() {
    isSecretPasswordVisible.value = !isSecretPasswordVisible.value;
  }

  void toggleLoginPasswordVisibility() {
    isLoginPasswordVisible.value = !isLoginPasswordVisible.value;
  }

  // Navigation methods
  void goToSignup() {
    Get.toNamed(AppRoutes.signup);
  }

  void goToLogin() {
    Get.back();
  }

  void goToForgotPasswordWithSecret() {
    Get.dialog(
      AlertDialog(
        title: const Text('Reset Firebase Password'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your Secret Password to receive a password reset email for your Firebase account.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: resetPasswordWithSecret,
            child: const Text('Send Reset Email'),
          ),
        ],
      ),
    );
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
