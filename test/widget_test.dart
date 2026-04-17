
// This is a basic Flutter widget test for the Click & Fix app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:click_and_fix/main.dart';  // Updated to match your project name

void main() {
  testWidgets('App starts with login page', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app starts with the Login page (check for "Login" in AppBar title).
    expect(find.text('Login'), findsOneWidget);

    // Optional: You can add more tests here, e.g., tapping the login button after filling fields.
    // For now, this confirms the app loads without errors and shows the expected initial screen.
  });
}