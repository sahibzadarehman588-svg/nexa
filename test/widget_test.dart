// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexia/core/theme/app_colors.dart';
import 'package:nexia/core/theme/app_text_styles.dart';

void main() {
  testWidgets('NEXIA splash screen displays correctly', (WidgetTester tester) async {
    // Build a simple splash screen widget for testing
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          primaryColor: AppColors.primary,
        ),
        home: Scaffold(
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
        ),
      ),
    );

    // Verify that the splash screen elements are displayed
    expect(find.text('NEXIA'), findsOneWidget);
    expect(find.text('One App. One Intelligent Assistant.'), findsOneWidget);
    expect(find.byIcon(Icons.smart_toy_outlined), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
