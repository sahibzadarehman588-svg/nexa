import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait for splash animation
    await Future.delayed(const Duration(seconds: 2));

    final AuthController authController = Get.find<AuthController>();

    // Check if user is logged in
    if (authController.isLoggedIn.value) {
      Get.offAllNamed(AppRoutes.home);
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.smart_toy_outlined,
              size: 80,
              color: AppColors.surface,
            ),
            const SizedBox(height: 24),
            Text(
              'SAFA',
              style: AppTextStyles.headline1.copyWith(
                color: AppColors.surface,
                fontSize: 48,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'One App. Many Real-World Problems.',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.surface,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: AppColors.surface,
            ),
          ],
        ),
      ),
    );
  }
}
