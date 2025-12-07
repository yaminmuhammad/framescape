// Basic Flutter widget test for Photo AI App

import 'package:flutter_test/flutter_test.dart';
import 'package:framescape/main.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PhotoAIApp());

    // Verify that the app title is displayed
    expect(find.text('Photo AI'), findsOneWidget);

    // Verify Firebase Connected message is shown
    expect(find.text('Firebase Connected! 🔥'), findsOneWidget);
  });
}
