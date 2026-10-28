import 'package:get/get.dart';
import 'app_routes.dart';
import '../../modules/auth/views/splash_screen.dart';
import '../../modules/auth/views/login_screen.dart';
import '../../modules/auth/views/signup_screen.dart';
import '../../modules/home/views/home_screen.dart';
import '../../modules/scanner/views/scanner_screen.dart';
import '../../modules/scanner/views/qr_barcode_scanner_screen.dart';
import '../../modules/products/views/products_screen.dart';
import '../../modules/products/views/add_edit_product_screen.dart';
import '../../modules/products/views/product_history_screen.dart';
import '../../modules/expiry/views/expiry_screen.dart';
import '../../modules/tasks/views/tasks_screen.dart';
import '../../modules/tasks/views/add_edit_task_screen.dart';
import '../../modules/ai/views/ai_chat_screen.dart';
import '../../modules/document_ai/views/document_ai_screen.dart';
import '../../modules/receipt_scanner/views/receipt_scanner_screen.dart';
import '../../modules/notification/views/notification_settings_screen.dart';
import '../../modules/inventory/views/inventory_screen.dart';
import '../../modules/profile/views/profile_screen.dart';
import '../../modules/alerts/views/alerts_screen.dart';
import '../../modules/udhaar_khata/views/customer_list_screen.dart';
import '../../modules/udhaar_khata/views/customer_detail_screen.dart';
import '../../modules/udhaar_khata/views/add_credit_entry_screen.dart';
import '../../modules/udhaar_khata/views/receive_payment_screen.dart';
import '../../modules/udhaar_khata/views/reminders_screen.dart';
import '../../modules/auth/bindings/auth_binding.dart';
import '../../modules/home/bindings/home_binding.dart';
import '../../modules/scanner/bindings/scanner_binding.dart';
import '../../modules/products/bindings/products_binding.dart';
import '../../modules/expiry/bindings/expiry_binding.dart';
import '../../modules/tasks/bindings/tasks_binding.dart';
import '../../modules/ai/bindings/ai_binding.dart';
import '../../modules/document_ai/bindings/document_ai_binding.dart';
import '../../modules/receipt_scanner/bindings/receipt_scanner_binding.dart';
import '../../modules/notification/bindings/notification_binding.dart';
import '../../modules/inventory/bindings/inventory_binding.dart';
import '../../modules/profile/bindings/profile_binding.dart';
import '../../modules/alerts/bindings/alerts_binding.dart';
import '../../modules/udhaar_khata/bindings/udhaar_khata_binding.dart';

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
      name: AppRoutes.qrBarcodeScanner,
      page: () => const QRBarcodeScannerScreen(),
    ),
    GetPage(
      name: AppRoutes.products,
      page: () => const ProductsScreen(),
      binding: ProductsBinding(),
    ),
    GetPage(
      name: AppRoutes.addProduct,
      page: () => const AddEditProductScreen(),
      binding: ProductsBinding(),
    ),
    GetPage(
      name: AppRoutes.editProduct,
      page: () => const AddEditProductScreen(),
      binding: ProductsBinding(),
    ),
    GetPage(
      name: AppRoutes.productHistory,
      page: () => const ProductHistoryScreen(),
      binding: ProductsBinding(),
    ),
    GetPage(
      name: AppRoutes.notificationSettings,
      page: () => const NotificationSettingsScreen(),
      binding: NotificationBinding(),
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileScreen(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.alerts,
      page: () => const AlertsScreen(),
      binding: AlertsBinding(),
    ),
    GetPage(
      name: AppRoutes.inventory,
      page: () => const InventoryScreen(),
      binding: InventoryBinding(),
    ),
    GetPage(
      name: AppRoutes.expiry,
      page: () => const ExpiryScreen(),
      binding: ExpiryBinding(),
    ),
    GetPage(
      name: AppRoutes.tasks,
      page: () => const TasksScreen(),
      binding: TasksBinding(),
    ),
    GetPage(
      name: AppRoutes.addTask,
      page: () => const AddEditTaskScreen(),
      binding: TasksBinding(),
    ),
    GetPage(
      name: AppRoutes.editTask,
      page: () => const AddEditTaskScreen(),
      binding: TasksBinding(),
    ),
    GetPage(
      name: AppRoutes.aiChat,
      page: () => const AIChatScreen(),
      binding: AIBinding(),
    ),
    GetPage(
      name: AppRoutes.documentAi,
      page: () => const DocumentAIScreen(),
      binding: DocumentAIBinding(),
    ),
    GetPage(
      name: AppRoutes.receiptScanner,
      page: () => const ReceiptScannerScreen(),
      binding: ReceiptScannerBinding(),
    ),
    GetPage(
      name: AppRoutes.udhaarKhata,
      page: () => const CustomerListScreen(),
      binding: UdhaarKhataBinding(),
    ),
    GetPage(
      name: AppRoutes.customerDetail,
      page: () => const CustomerDetailScreen(),
      binding: UdhaarKhataBinding(),
    ),
    GetPage(
      name: AppRoutes.addCreditEntry,
      page: () => const AddCreditEntryScreen(),
      binding: UdhaarKhataBinding(),
    ),
    GetPage(
      name: AppRoutes.receivePayment,
      page: () => const ReceivePaymentScreen(),
      binding: UdhaarKhataBinding(),
    ),
    GetPage(
      name: AppRoutes.udhaarReminders,
      page: () => const RemindersScreen(),
      binding: UdhaarKhataBinding(),
    ),
    // Additional routes will be added in subsequent phases
  ];
}
