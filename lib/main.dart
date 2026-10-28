import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/controllers/theme_controller.dart';
import 'data/services/firebase_service.dart';
import 'data/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await FirebaseService().initialize();

  // Initialize Notification Service
  await NotificationService().initialize();

  runApp(const NEXIAApp());
}

class NEXIAApp extends StatelessWidget {
  const NEXIAApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize ThemeController
    final themeController = Get.put(ThemeController());

    return GetMaterialApp(
      title: 'NEXIA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeController.currentThemeMode,
      initialRoute: AppRoutes.splash,
      getPages: AppPages.routes,
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
