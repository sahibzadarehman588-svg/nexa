import 'package:get/get.dart';
import 'app_routes.dart';
import '../../modules/auth/views/splash_screen.dart';
import '../../modules/auth/views/login_screen.dart';
import '../../modules/auth/views/signup_screen.dart';
import '../../modules/home/views/home_screen.dart';
import '../../modules/scanner/views/scanner_screen.dart';
import '../../modules/products/views/products_screen.dart';
import '../../modules/notification/views/notification_settings_screen.dart';
import '../../modules/inventory/views/inventory_screen.dart';
import '../../modules/auth/bindings/auth_binding.dart';
import '../../modules/home/bindings/home_binding.dart';
import '../../modules/scanner/bindings/scanner_binding.dart';
import '../../modules/products/bindings/products_binding.dart';
import '../../modules/notification/bindings/notification_binding.dart';
import '../../modules/inventory/bindings/inventory_binding.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.signup,
      page: () => const SignupScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.scanner,
      page: () => const ScannerScreen(),
      binding: ScannerBinding(),
    ),
    GetPage(
      name: AppRoutes.products,
      page: () => const ProductsScreen(),
      binding: ProductsBinding(),
    ),
    GetPage(
      name: AppRoutes.notificationSettings,
      page: () => const NotificationSettingsScreen(),
      binding: NotificationBinding(),
    ),
    GetPage(
      name: AppRoutes.inventory,
      page: () => const InventoryScreen(),
      binding: InventoryBinding(),
    ),
    // Additional routes will be added in subsequent phases
  ];
}
