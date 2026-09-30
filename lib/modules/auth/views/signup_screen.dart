import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sign Up'),
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.smart_toy_outlined,
                  size: 80,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Create Account',
                  style: AppTextStyles.headline3.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 32),
                Obx(() => TextField(
                  onChanged: (value) => authController.name.value = value,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    hintText: 'Enter your name',
                    prefixIcon: const Icon(Icons.person_outlined),
                    errorText: authController.nameError.value.isEmpty
                        ? null
                        : authController.nameError.value,
                  ),
                )),
                const SizedBox(height: 16),
                Obx(() => TextField(
                  onChanged: (value) => authController.email.value = value,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    errorText: authController.emailError.value.isEmpty
                        ? null
                        : authController.emailError.value,
                  ),
                )),
                const SizedBox(height: 16),
                Obx(() => TextField(
                  onChanged: (value) => authController.password.value = value,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    errorText: authController.passwordError.value.isEmpty
                        ? null
                        : authController.passwordError.value,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.visibility_outlined),
                      onPressed: () {
                        // TODO: Implement password visibility toggle
                      },
                    ),
                  ),
                  obscureText: true,
                )),
                const SizedBox(height: 16),
                Obx(() => TextField(
                  onChanged: (value) =>
                      authController.confirmPassword.value = value,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Confirm your password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    errorText: authController.confirmPasswordError.value.isEmpty
                        ? null
                        : authController.confirmPasswordError.value,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.visibility_outlined),
                      onPressed: () {
                        // TODO: Implement password visibility toggle
                      },
                    ),
                  ),
                  obscureText: true,
                )),
                const SizedBox(height: 24),
                Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: authController.isLoading.value
                        ? null
                        : authController.signup,
                    child: authController.isLoading.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.surface,
                            ),
                          )
                        : const Text('Sign Up'),
                  ),
                )),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: authController.goToLogin,
                  child: const Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
