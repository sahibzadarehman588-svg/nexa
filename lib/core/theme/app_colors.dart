import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF6C8CFF);
  static const Color primaryDark = Color(0xFF5A78E8);
  static const Color primaryLight = Color(0xFF8AA0FF);

  // Secondary Colors
  static const Color secondary = Color(0xFF35D0BA);
  static const Color secondaryDark = Color(0xFF2DB3A5);
  static const Color secondaryLight = Color(0xFF4DE0CC);

  // Accent Colors
  static const Color accent = Color(0xFFFF647C);
  static const Color accentDark = Color(0xFFE8556D);
  static const Color accentLight = Color(0xFFFF8B9E);

  // Dark Theme Background Colors
  static const Color background = Color(0xFF0B0F14);
  static const Color backgroundSecondary = Color(0xFF111820);
  static const Color surface = Color(0xFF18212B);
  static const Color surfaceElevated = Color(0xFF202B38);
  static const Color cardBackground = Color(0xFF18212B);

  // Light Theme Background Colors (for reference, not used in dark mode)
  static const Color backgroundLight = Color(0xFFF5F7FB);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardBackgroundLight = Color(0xFFFFFFFF);

  // Dark Theme Text Colors
  static const Color textPrimary = Color(0xFFF5F7FA);
  static const Color textSecondary = Color(0xFFA7B0BE);
  static const Color textHint = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFF4B5563);

  // Light Theme Text Colors (for reference)
  static const Color textPrimaryLight = Color(0xFF172033);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textHintLight = Color(0xFF94A3B8);
  static const Color textDisabledLight = Color(0xFFCBD5E1);

  // Text on Tinted Backgrounds
  static const Color textOnTint = Color(0xFFF5F7FA);
  static const Color textSecondaryOnTint = Color(0xFFA7B0BE);

  // Status Colors
  static const Color success = Color(0xFF35C98A);
  static const Color warning = Color(0xFFF5B942);
  static const Color error = Color(0xFFFF647C);
  static const Color info = Color(0xFF6C8CFF);
  static const Color onWarning = Color(0xFFFFFFFF);

  // Divider Colors
  static const Color divider = Color(0xFF2A3543);
  static const Color border = Color(0xFF2A3543);

  // Shadow Colors
  static const Color shadow = Color(0x1A000000);
  static const Color shadowDark = Color(0x33000000);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryLight, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondaryLight, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Expiry Status Colors
  static const Color expirySafe = Color(0xFF35C98A);
  static const Color expiryExpiringSoon = Color(0xFFF5B942);
  static const Color expiryExpired = Color(0xFFFF647C);
}
