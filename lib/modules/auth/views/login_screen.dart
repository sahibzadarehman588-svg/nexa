import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.background,
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
                  'NEXIA',
                  style: AppTextStyles.headline1.copyWith(
                    color: AppColors.primary,
                    fontSize: 48,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'One App. One Intelligent Assistant.',
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 48),
                Obx(() => TextField(
                  onChanged: (value) => authController.password.value = value,
                  decoration: InputDecoration(
                    labelText: 'Secret Password',
                    hintText: 'Enter Secret Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    errorText: authController.passwordError.value.isEmpty
                        ? null
                        : authController.passwordError.value,
                    suffixIcon: IconButton(
                      icon: Icon(authController.isLoginPasswordVisible.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () {
                        authController.toggleLoginPasswordVisibility();
                        setState(() {});
                      },
                    ),
                  ),
                  obscureText: !authController.isLoginPasswordVisible.value,
                )),
                const SizedBox(height: 24),
                Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: authController.isLoading.value
                        ? null
                        : authController.login,
                    child: authController.isLoading.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.surface,
                            ),
                          )
                        : const Text('Login'),
                  ),
                )),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: authController.goToForgotPasswordWithSecret,
                    child: const Text('Forgot Secret Password?'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: authController.goToSignup,
                  child: const Text('Don\'t have an account? Sign up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
