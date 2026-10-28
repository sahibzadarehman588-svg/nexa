import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('=== NotificationService: Initializing ===');

    // Initialize timezone
    tz_data.initializeTimeZones();
    debugPrint('✅ Timezones initialized');

    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Combined initialization settings
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    // Initialize the plugin
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    debugPrint('✅ FlutterLocalNotificationsPlugin initialized');

    // Request permissions
    await _requestPermissions();

    _isInitialized = true;
    debugPrint('=== NotificationService: Initialization complete ===');
  }

  Future<void> _requestPermissions() async {
    debugPrint('=== NotificationService: Requesting permissions ===');

    // Skip platform checks on Web
    if (kIsWeb) {
      debugPrint('🌐 Web platform - skipping permission checks');
      return;
    }

    if (Platform.isAndroid) {
      // Android 13+ requires explicit notification permission
      final status = await Permission.notification.request();
      debugPrint('📱 Android notification permission: ${status.isGranted}');

      // Android 12+ requires SCHEDULE_EXACT_ALARM permission for exact alarms
      if (Platform.isAndroid) {
        final exactAlarmStatus = await Permission.scheduleExactAlarm.request();
        debugPrint('📱 Android exact alarm permission: ${exactAlarmStatus.isGranted}');
      }
    }

    // iOS permissions are handled via DarwinInitializationSettings
    debugPrint('✅ Permissions requested');
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('=== NotificationService: Notification tapped ===');
    debugPrint('Payload: ${response.payload}');
    // Handle notification tap (e.g., navigate to specific task)
  }

  /// Schedule task start and end time notifications
  Future<void> scheduleTaskNotifications({
    required String taskId,
    required String taskTitle,
    required DateTime? dueDate,
    required String? dueTime,
    DateTime? startDate,
    String? startTime,
    DateTime? endDate,
    String? endTime,
  }) async {
    debugPrint('=== NotificationService: Scheduling task notifications ===');
    debugPrint('Task ID: $taskId');
    debugPrint('Task Title: $taskTitle');
    debugPrint('Start Date: ${startDate?.toIso8601String()}');
    debugPrint('Start Time: $startTime');
    debugPrint('End Date: ${endDate?.toIso8601String()}');
    debugPrint('End Time: $endTime');

    if (!_isInitialized) {
      await initialize();
    }

    // Check if exact alarm permission is granted
    AndroidScheduleMode scheduleMode;
    if (Platform.isAndroid) {
      final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
      if (exactAlarmStatus.isGranted) {
        scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
        debugPrint('✅ Using exact alarm mode');
      } else {
        scheduleMode = AndroidScheduleMode.inexact;
        debugPrint('⚠️ Exact alarm not permitted, using inexact mode');
      }
    } else {
      scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
    }

    // Android notification details
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Notifications for task start and end reminders',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    // iOS notification details
    const DarwinNotificationDetails iosDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // Combined notification details
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    final now = DateTime.now();

    // Schedule start time notification
    if (startDate != null && startTime != null && startTime.isNotEmpty) {
      final parts = startTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final startDateTime = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        hour,
        minute,
      );

      if (startDateTime.isAfter(now)) {
        final scheduledDate = tz.TZDateTime.from(startDateTime, tz.local);
        debugPrint('📅 Start notification scheduled: ${scheduledDate.toIso8601String()}');

        await _notificationsPlugin.zonedSchedule(
          taskId.hashCode, // Unique ID for start notification
          'Task Started',
          '$taskTitle — Task has started.',
          scheduledDate,
          notificationDetails,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dateAndTime,
          androidScheduleMode: scheduleMode,
        );
        debugPrint('✅ Task start notification scheduled');
      } else {
        debugPrint('⚠️ Start time is in the past, skipping start notification');
      }
    }

    // Schedule end time notification
    if (endDate != null && endTime != null && endTime.isNotEmpty) {
      final parts = endTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final endDateTime = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        hour,
        minute,
      );

      if (endDateTime.isAfter(now)) {
        final scheduledDate = tz.TZDateTime.from(endDateTime, tz.local);
        debugPrint('📅 End notification scheduled: ${scheduledDate.toIso8601String()}');

        await _notificationsPlugin.zonedSchedule(
          taskId.hashCode + 1, // Unique ID for end notification (taskId + 1)
          'Task Ended',
          '$taskTitle — Task time has finished.',
          scheduledDate,
          notificationDetails,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dateAndTime,
          androidScheduleMode: scheduleMode,
        );
        debugPrint('✅ Task end notification scheduled');
      } else {
        debugPrint('⚠️ End time is in the past, skipping end notification');
      }
    }

    // Fallback: if no start/end times, use due date/time for backward compatibility
    if ((startDate == null || startTime == null) &&
        (endDate == null || endTime == null) &&
        dueDate != null &&
        dueTime != null &&
        dueTime.isNotEmpty) {
      final parts = dueTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final dueDateTime = DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day,
        hour,
        minute,
      );

      if (dueDateTime.isAfter(now)) {
        final scheduledDate = tz.TZDateTime.from(dueDateTime, tz.local);
        debugPrint('📅 Due notification scheduled (fallback): ${scheduledDate.toIso8601String()}');

        await _notificationsPlugin.zonedSchedule(
          taskId.hashCode,
          'Task Reminder',
          '$taskTitle — Task time is now.',
          scheduledDate,
          notificationDetails,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dateAndTime,
          androidScheduleMode: scheduleMode,
        );
        debugPrint('✅ Task due notification scheduled (fallback)');
      }
    }

    debugPrint('✅ Task notifications scheduled successfully');
  }

  /// Cancel a specific task's notifications (start and end)
  Future<void> cancelTaskNotifications(String taskId) async {
    debugPrint('=== NotificationService: Canceling task notifications ===');
    debugPrint('Task ID: $taskId');

    if (!_isInitialized) {
      await initialize();
    }

    // Cancel both start and end notifications
    await _notificationsPlugin.cancel(taskId.hashCode); // Start notification
    await _notificationsPlugin.cancel(taskId.hashCode + 1); // End notification
    debugPrint('✅ Task notifications canceled');
  }

  /// Cancel all task reminders
  Future<void> cancelAllReminders() async {
    debugPrint('=== NotificationService: Canceling all reminders ===');

    if (!_isInitialized) {
      await initialize();
    }

    await _notificationsPlugin.cancelAll();
    debugPrint('✅ All reminders canceled');
  }

  /// Schedule product expiry notifications (1 day before + on expiry date)
  Future<void> scheduleProductExpiryNotifications({
    required String productId,
    required String productName,
    required DateTime expiryDate,
    int notificationHour = 9,
    int notificationMinute = 0,
  }) async {
    debugPrint('=== NotificationService: Scheduling product expiry notifications ===');
    debugPrint('Product ID: $productId');
    debugPrint('Product Name: $productName');
    debugPrint('Expiry Date: ${expiryDate.toIso8601String()}');

    if (!_isInitialized) {
      await initialize();
    }

    // Calculate notification times (default 9:00 AM)
    final expiryDateTime = DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day,
      notificationHour,
      notificationMinute,
    );

    final dayBeforeDateTime = expiryDateTime.subtract(const Duration(days: 1));

    // Check if exact alarm permission is granted
    AndroidScheduleMode scheduleMode;
    if (Platform.isAndroid) {
      final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
      if (exactAlarmStatus.isGranted) {
        scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
        debugPrint('✅ Using exact alarm mode');
      } else {
        scheduleMode = AndroidScheduleMode.inexact;
        debugPrint('⚠️ Exact alarm not permitted, using inexact mode');
      }
    } else {
      scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
    }

    // Android notification details
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'product_expiry',
      'Product Expiry',
      channelDescription: 'Notifications for product expiry alerts',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    // iOS notification details
    const DarwinNotificationDetails iosDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // Combined notification details
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    final now = DateTime.now();
    final normalizedNow = DateTime(now.year, now.month, now.day);

    // Schedule 1-day-before notification if in the future (date-only comparison)
    if (dayBeforeDateTime.isAfter(normalizedNow)) {
      final dayBeforeDate = tz.TZDateTime.from(dayBeforeDateTime, tz.local);
      debugPrint('📅 Day-before notification scheduled: ${dayBeforeDate.toIso8601String()}');

      await _notificationsPlugin.zonedSchedule(
        productId.hashCode, // Use productId hash for day-before notification
        'NEXIA — Expiry Alert',
        '$productName expires tomorrow.',
        dayBeforeDate,
        notificationDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
        androidScheduleMode: scheduleMode,
      );
      debugPrint('✅ Product 1-day-before notification scheduled');
    } else {
      debugPrint('⚠️ 1-day-before time is in the past, skipping');
    }

    // Schedule expiry day notification if in the future (date-only comparison)
    if (expiryDateTime.isAfter(normalizedNow)) {
      final expiryDateTZ = tz.TZDateTime.from(expiryDateTime, tz.local);
      debugPrint('📅 Expiry day notification scheduled: ${expiryDateTZ.toIso8601String()}');

      await _notificationsPlugin.zonedSchedule(
        productId.hashCode + 1, // Use productId hash + 1 for expiry day notification
        'NEXIA — Product Expired',
        '$productName has expired today.',
        expiryDateTZ,
        notificationDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
        androidScheduleMode: scheduleMode,
      );
      debugPrint('✅ Product expiry day notification scheduled');
    } else {
      debugPrint('⚠️ Expiry day time is in the past, skipping');
    }

    debugPrint('✅ Product expiry notifications scheduled successfully');
  }

  /// Cancel a specific product's expiry notifications
  Future<void> cancelProductExpiryNotifications(String productId) async {
    debugPrint('=== NotificationService: Canceling product expiry notifications ===');
    debugPrint('Product ID: $productId');

    if (!_isInitialized) {
      await initialize();
    }

    // Cancel both day-before and expiry day notifications
    await _notificationsPlugin.cancel(productId.hashCode);
    await _notificationsPlugin.cancel(productId.hashCode + 1);
    debugPrint('✅ Product expiry notifications canceled');
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) {
      return true; // Web doesn't require permission checks
    }
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      return status.isGranted;
    }
    return true; // iOS permissions are handled differently
  }

  /// Request notification permissions (for backward compatibility)
  Future<void> requestPermissions() async {
    await _requestPermissions();
  }

  /// Schedule a generic notification (for backward compatibility)
  Future<void> scheduleNotification(
    int notificationId,
    String title,
    String body,
    DateTime scheduledDate,
  ) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Check if scheduled time is in the past
    final now = DateTime.now();
    if (scheduledDate.isBefore(now)) {
      debugPrint('⚠️ Scheduled time is in the past, skipping notification');
      return;
    }

    final scheduledTZDate = tz.TZDateTime.from(scheduledDate, tz.local);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'product_reminders',
      'Product Reminders',
      channelDescription: 'Notifications for product expiry reminders',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notificationsPlugin.zonedSchedule(
      notificationId,
      title,
      body,
      scheduledTZDate,
      notificationDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Show expiry notification immediately (for backward compatibility)
  Future<void> showExpiryNotification(String productName, int remainingDays) async {
    if (!_isInitialized) {
      await initialize();
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'product_reminders',
      'Product Reminders',
      channelDescription: 'Notifications for product expiry reminders',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.hashCode,
      'Product Expiring Soon',
      '$productName will expire in $remainingDays days.',
      notificationDetails,
    );
  }

  /// Show expired notification immediately (for backward compatibility)
  Future<void> showExpiredNotification(String productName) async {
    if (!_isInitialized) {
      await initialize();
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'product_reminders',
      'Product Reminders',
      channelDescription: 'Notifications for product expiry reminders',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.hashCode + 1,
      'Product Expired',
      '$productName has expired.',
      notificationDetails,
    );
  }

  /// Cancel all notifications (for backward compatibility)
  Future<void> cancelAllNotifications() async {
    await cancelAllReminders();
  }

  /// Schedule individual credit entry reminder
  Future<void> scheduleCreditEntryReminder({
    required String creditEntryId,
    required String customerName,
    required double amount,
    required DateTime? reminderDate,
    required String? reminderTime,
  }) async {
    debugPrint('=== NotificationService: Scheduling credit entry reminder ===');
    debugPrint('Credit Entry ID: $creditEntryId');
    debugPrint('Customer Name: $customerName');
    debugPrint('Amount: $amount');
    debugPrint('Reminder Date: ${reminderDate?.toIso8601String()}');
    debugPrint('Reminder Time: $reminderTime');

    if (!_isInitialized) {
      await initialize();
    }

    if (reminderDate == null || reminderTime == null || reminderTime.isEmpty) {
      debugPrint('⚠️ Reminder date or time not provided, skipping');
      return;
    }

    final parts = reminderTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final reminderDateTime = DateTime(
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      hour,
      minute,
    );

    final now = DateTime.now();
    if (reminderDateTime.isBefore(now)) {
      debugPrint('⚠️ Reminder time is in the past, skipping');
      return;
    }

    // Check if exact alarm permission is granted
    AndroidScheduleMode scheduleMode;
    if (Platform.isAndroid) {
      final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
      if (exactAlarmStatus.isGranted) {
        scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
        debugPrint('✅ Using exact alarm mode');
      } else {
        scheduleMode = AndroidScheduleMode.inexact;
        debugPrint('⚠️ Exact alarm not permitted, using inexact mode');
      }
    } else {
      scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
    }

    // Android notification details
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'credit_reminders',
      'Credit Reminders',
      channelDescription: 'Notifications for credit entry reminders',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    // iOS notification details
    const DarwinNotificationDetails iosDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // Combined notification details
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    final scheduledDate = tz.TZDateTime.from(reminderDateTime, tz.local);
    debugPrint('📅 Credit entry reminder scheduled: ${scheduledDate.toIso8601String()}');

    // Use creditEntryId.hashCode + 100000 to avoid collision with task IDs
    final notificationId = creditEntryId.hashCode + 100000;

    await _notificationsPlugin.zonedSchedule(
      notificationId,
      'NEXIA — Credit Reminder',
      '$customerName owes Rs. ${amount.toStringAsFixed(0)}',
      scheduledDate,
      notificationDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      androidScheduleMode: scheduleMode,
      payload: 'credit_entry:$creditEntryId',
    );
    debugPrint('✅ Credit entry reminder scheduled with ID: $notificationId');
  }

  /// Cancel individual credit entry reminder
  Future<void> cancelCreditEntryReminder(String creditEntryId) async {
    debugPrint('=== NotificationService: Canceling credit entry reminder ===');
    debugPrint('Credit Entry ID: $creditEntryId');

    if (!_isInitialized) {
      await initialize();
    }

    final notificationId = creditEntryId.hashCode + 100000;
    await _notificationsPlugin.cancel(notificationId);
    debugPrint('✅ Credit entry reminder canceled with ID: $notificationId');
  }

  /// Schedule customer-level total balance reminder
  Future<void> scheduleCustomerBalanceReminder({
    required String customerId,
    required String customerName,
    required DateTime? reminderDate,
    required String? reminderTime,
  }) async {
    debugPrint('=== NotificationService: Scheduling customer balance reminder ===');
    debugPrint('Customer ID: $customerId');
    debugPrint('Customer Name: $customerName');
    debugPrint('Reminder Date: ${reminderDate?.toIso8601String()}');
    debugPrint('Reminder Time: $reminderTime');

    if (!_isInitialized) {
      await initialize();
    }

    if (reminderDate == null || reminderTime == null || reminderTime.isEmpty) {
      debugPrint('⚠️ Reminder date or time not provided, skipping');
      return;
    }

    final parts = reminderTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final reminderDateTime = DateTime(
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      hour,
      minute,
    );

    final now = DateTime.now();
    if (reminderDateTime.isBefore(now)) {
      debugPrint('⚠️ Reminder time is in the past, skipping');
      return;
    }

    // Check if exact alarm permission is granted
    AndroidScheduleMode scheduleMode;
    if (Platform.isAndroid) {
      final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
      if (exactAlarmStatus.isGranted) {
        scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
        debugPrint('✅ Using exact alarm mode');
      } else {
        scheduleMode = AndroidScheduleMode.inexact;
        debugPrint('⚠️ Exact alarm not permitted, using inexact mode');
      }
    } else {
      scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
    }

    // Android notification details
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'customer_balance_reminders',
      'Customer Balance Reminders',
      channelDescription: 'Notifications for customer total balance reminders',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    // iOS notification details
    const DarwinNotificationDetails iosDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // Combined notification details
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    final scheduledDate = tz.TZDateTime.from(reminderDateTime, tz.local);
    debugPrint('📅 Customer balance reminder scheduled: ${scheduledDate.toIso8601String()}');

    // Use customerId.hashCode + 200000 to avoid collision with task and credit entry IDs
    final notificationId = customerId.hashCode + 200000;

    await _notificationsPlugin.zonedSchedule(
      notificationId,
      'NEXIA — Balance Reminder',
      'Review the outstanding balance for $customerName',
      scheduledDate,
      notificationDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      androidScheduleMode: scheduleMode,
      payload: 'customer_balance:$customerId',
    );
    debugPrint('✅ Customer balance reminder scheduled with ID: $notificationId');
  }

  /// Cancel customer-level balance reminder
  Future<void> cancelCustomerBalanceReminder(String customerId) async {
    debugPrint('=== NotificationService: Canceling customer balance reminder ===');
    debugPrint('Customer ID: $customerId');

    if (!_isInitialized) {
      await initialize();
    }

    final notificationId = customerId.hashCode + 200000;
    await _notificationsPlugin.cancel(notificationId);
    debugPrint('✅ Customer balance reminder canceled with ID: $notificationId');
  }
}
