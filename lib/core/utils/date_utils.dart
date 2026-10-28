import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../constants/firebase_constants.dart';

class DateUtils {
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  static String formatDisplayDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatDisplayDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy • HH:mm').format(dateTime);
  }

  static int calculateRemainingDays(DateTime expiryDate) {
    // Normalize both dates to midnight for date-only comparison
    final now = DateTime.now();
    final normalizedNow = DateTime(now.year, now.month, now.day);
    final normalizedExpiryDate = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    final difference = normalizedExpiryDate.difference(normalizedNow);
    return difference.inDays;
  }

  static String getExpiryStatus(DateTime expiryDate) {
    final remainingDays = calculateRemainingDays(expiryDate);

    // Expired if expiry date is today or in the past
    if (remainingDays <= 0) {
      return FirebaseConstants.statusExpired;
    } else if (remainingDays <= AppConstants.expiryWarningThreshold) {
      return FirebaseConstants.statusExpiringSoon;
    } else {
      return FirebaseConstants.statusSafe;
    }
  }

  static String getExpiryStatusText(DateTime expiryDate) {
    final remainingDays = calculateRemainingDays(expiryDate);

    if (remainingDays < 0) {
      return 'Expired';
    } else if (remainingDays == 0) {
      return 'Expired'; // Changed from 'Expires today' to 'Expired'
    } else if (remainingDays == 1) {
      return 'Expires tomorrow';
    } else if (remainingDays <= AppConstants.expiryWarningThreshold) {
      return 'Expires in $remainingDays days';
    } else {
      return 'Safe';
    }
  }

  static bool isExpiringSoon(DateTime expiryDate) {
    final remainingDays = calculateRemainingDays(expiryDate);
    return remainingDays > 0 && remainingDays <= AppConstants.expiryWarningThreshold;
  }

  static bool isExpired(DateTime expiryDate) {
    final remainingDays = calculateRemainingDays(expiryDate);
    return remainingDays <= 0; // Changed from < 0 to <= 0 to include today
  }

  static bool isSafe(DateTime expiryDate) {
    final remainingDays = calculateRemainingDays(expiryDate);
    return remainingDays > AppConstants.expiryWarningThreshold;
  }

  static DateTime? parseDate(String dateString) {
    try {
      return DateFormat('yyyy-MM-dd').parse(dateString);
    } catch (e) {
      return null;
    }
  }

  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else {
      return '${(difference.inDays / 365).floor()} years ago';
    }
  }
}
