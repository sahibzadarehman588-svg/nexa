class AppConstants {
  // App Info
  static const String appName = 'NEXIA';
  static const String appTagline = 'One App. One Intelligent Assistant.';
  static const String appVersion = '1.0.0';

  // Expiry Thresholds (in days)
  static const int expiryWarningThreshold = 7; // Warn if expiring within 7 days
  static const int expiryCriticalThreshold = 3; // Critical if expiring within 3 days

  // Pagination
  static const int defaultPageSize = 20;

  // Image Settings
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int imageQuality = 85;

  // Notification Settings
  static const int notificationExpiryCheckHour = 9; // Check at 9 AM
  static const String notificationChannelId = 'nexia_expiry_notifications';
  static const String notificationChannelName = 'Expiry Reminders';
  static const String notificationChannelDescription = 'Notifications for product expiry reminders';

  // Validation
  static const int minPasswordLength = 6;
  static const int maxProductNameLength = 100;
  static const int maxCategoryLength = 50;

  // Storage Paths
  static const String productsImagePath = 'products';
  static const String receiptsImagePath = 'receipts';
  static const String documentsImagePath = 'documents';

  // Error Messages
  static const String errorNoInternet = 'No internet connection. Please check your network.';
  static const String errorSomethingWentWrong = 'Something went wrong. Please try again.';
  static const String errorLoginFailed = 'Login failed. Please check your credentials.';
  static const String errorSignupFailed = 'Signup failed. Please try again.';
  static const String errorCameraPermission = 'Camera permission is required to scan products.';
  static const String errorStoragePermission = 'Storage permission is required to save images.';
  static const String errorInvalidImage = 'Invalid image format. Please select a valid image.';
  static const String errorOcrFailed = 'Failed to extract text from image. Please try again.';
  static const String errorAiServiceFailed = 'AI service is currently unavailable. Please try again later.';
  static const String errorAiNotConfigured = 'AI service is not configured. Please set your API key in settings.';

  // Success Messages
  static const String successLogin = 'Login successful!';
  static const String successSignup = 'Account created successfully!';
  static const String successProductAdded = 'Product Added Successfully';
  static const String successProductUpdated = 'Product updated successfully!';
  static const String successProductDeleted = 'Product deleted successfully!';
  static const String successLogout = 'Logged out successfully!';

  // Coming Soon Messages
  static const String comingSoon = 'Coming Soon';
  static const String comingSoonDescription = 'This feature is under development and will be available soon.';
}
