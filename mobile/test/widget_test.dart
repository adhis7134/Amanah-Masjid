// Flutter widget test for AmanahMasjid app.
// Verifies that the app launches and shows the expected UI elements.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amanah_masjid_mobile/main.dart';

void main() {
  testWidgets('AmanahMasjid app loads and shows title', (WidgetTester tester) async {
    // Build the app.
    await tester.pumpWidget(const AmanahMasjidApp());

    // Verify that a MaterialApp widget is present.
    expect(find.byType(MaterialApp), findsOneWidget);

    // Verify that the AppBar contains the correct title.
    // Adjust the string if your AppBar title differs.
    expect(find.widgetWithText(AppBar, 'AmanahMasjid'), findsOneWidget);

    // Verify that the home screen displays a welcome text.
    // Change the text here if you use a different welcome message.
    expect(find.text('Welcome to Amanah Masjid App'), findsOneWidget);
  });
}
