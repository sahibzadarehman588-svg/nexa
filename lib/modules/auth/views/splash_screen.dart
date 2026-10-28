import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    // Use microtask to avoid timer issues in tests
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndNavigate();
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    // Listen to Firebase Auth state changes to get the persisted session
    final authStateChanges = FirebaseAuth.instance.authStateChanges();

    // Wait for the first auth state event (this will fire with the persisted session)
    final firstEvent = await authStateChanges.first;

    if (!mounted) return;

    if (firstEvent != null) {
      // User is logged in (session persisted by Firebase)
      debugPrint('✅ User already logged in: ${firstEvent.email}');
      Get.offAllNamed(AppRoutes.home);
    } else {
      // No user logged in
      debugPrint('ℹ️ No user logged in');
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
              'NEXIA',
              style: AppTextStyles.headline1.copyWith(
                color: AppColors.surface,
                fontSize: 48,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'One App. One Intelligent Assistant.',
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
