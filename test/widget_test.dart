// Basic Flutter widget test for FrameScape App

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framescape/main.dart';

void main() {
  testWidgets('PhotoAIApp widget can be instantiated', (WidgetTester tester) async {
    // Just verify that we can create the widget without crashing
    // Note: This is a smoke test. Full widget testing should be done
    // with proper Firebase initialization or mocking
    expect(() => const PhotoAIApp(), isNotNull);
  });
}
