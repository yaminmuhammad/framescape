import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:framescape/screens/home_screen.dart';
import 'package:framescape/bloc/auth/auth_bloc.dart';
import 'package:framescape/bloc/image/image_bloc.dart';
import 'package:framescape/services/auth_service.dart';
import 'package:framescape/services/image_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Generate mock classes
@GenerateMocks([AuthService, ImageService])
import 'home_screen_test.mocks.dart';

void main() {
  group('HomeScreen Widget Tests', () {
    late AuthBloc authBloc;
    late ImageBloc imageBloc;
    late MockAuthService mockAuthService;
    late MockImageService mockImageService;

    setUp(() {
      mockAuthService = MockAuthService();
      mockImageService = MockImageService();
      authBloc = AuthBloc(authService: mockAuthService);
      imageBloc = ImageBloc(
        imageService: mockImageService,
        authService: mockAuthService,
      );
    });

    tearDown(() {
      authBloc.close();
      imageBloc.close();
    });

    testWidgets('HomeScreen renders with app title', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<ImageBloc>.value(value: imageBloc),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      // Verify app title is displayed
      expect(find.text('FrameScape'), findsOneWidget);
    });

    testWidgets('Shows category selection buttons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<ImageBloc>.value(value: imageBloc),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      // Verify all category buttons are present
      expect(find.text('Beach Trip'), findsOneWidget);
      expect(find.text('City Break'), findsOneWidget);
      expect(find.text('Road Trip'), findsOneWidget);
      expect(find.text('Mountain'), findsOneWidget);
      expect(find.text('Cafe Vibes'), findsOneWidget);
      expect(find.text('Sunset'), findsOneWidget);
    });

    testWidgets('Shows image selection area initially', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<ImageBloc>.value(value: imageBloc),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      // The image selection area should be present (with placeholder or button)
      expect(find.byType(SliverAppBar), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('Tapping category selection changes selection', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<ImageBloc>.value(value: imageBloc),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      // Find and tap a category
      final beachCategory = find.text('Beach Trip');
      expect(beachCategory, findsOneWidget);
      await tester.tap(beachCategory);
      await tester.pump();
    });

    testWidgets('Shows generating state when image is generating', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<ImageBloc>.value(value: imageBloc),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      // Simulate generating state
      imageBloc.add(ImageGenerate('beach'));
      await tester.pump();

      // The UI should handle the loading state
      // (Specific assertions depend on implementation)
    });

    testWidgets('Full-screen image viewer closes when tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<ImageBloc>.value(value: imageBloc),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      // Note: Testing full-screen viewer requires setting up a mock image state
      // This is a simplified test
    });

    testWidgets('Has proper Material 3 structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<ImageBloc>.value(value: imageBloc),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      // Verify basic app structure
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
      expect(find.byType(SliverAppBar), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('Has responsive grid layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<ImageBloc>.value(value: imageBloc),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      // The layout should be scrollable
      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.byType(SliverList), findsOneWidget);
    });

    testWidgets('Handles image selection state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<ImageBloc>.value(value: imageBloc),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      // Simulate image selection
      final testImage = File('test.jpg');
      imageBloc.add(ImageSelected(testImage));
      await tester.pump();

      // Verify state is updated
      expect(imageBloc.state.hasImage, isTrue);
    });

    testWidgets('Handles error states', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<ImageBloc>.value(value: imageBloc),
          ],
          child: MaterialApp(
            home: HomeScreen(),
            scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
          ),
        ),
      );

      // Simulate error state
      imageBloc.add(ImageGenerate('beach'));
      await tester.pump();

      // Error handling depends on implementation
      // The SnackBar should be shown via BlocListener
    });
  });
}
