import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:framescape/bloc/image/image_bloc.dart';
import 'package:framescape/services/auth_service.dart';
import 'package:framescape/services/image_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Generate mock classes
@GenerateMocks([ImageService, AuthService])
import 'image_bloc_test.mocks.dart';

void main() {
  group('ImageBloc', () {
    late ImageBloc imageBloc;
    late MockImageService mockImageService;
    late MockAuthService mockAuthService;

    setUp(() {
      mockImageService = MockImageService();
      mockAuthService = MockAuthService();
      imageBloc = ImageBloc(
        imageService: mockImageService,
        authService: mockAuthService,
      );
    });

    tearDown(() {
      imageBloc.close();
    });

    test('initial state is ImageState with correct defaults', () {
      expect(
        imageBloc.state,
        equals(const ImageState()),
      );
      expect(imageBloc.state.status, equals(ImageStatus.initial));
      expect(imageBloc.state.hasImage, isFalse);
      expect(imageBloc.state.hasResult, isFalse);
      expect(imageBloc.state.isGenerating, isFalse);
    });

    blocTest<ImageBloc, ImageState>(
      'emits [imageSelected] when ImageSelected',
      build: () {
        final testFile = File('test.jpg');
        return imageBloc;
      },
      act: (bloc) {
        final testFile = File('test.jpg');
        bloc.add(ImageSelected(testFile));
      },
      expect: () => [
        predicate<ImageState>((state) =>
            state.status == ImageStatus.imageSelected &&
            state.selectedImage != null),
      ],
      verify: (_) {
        // Verify that the image was selected
      },
    );

    blocTest<ImageBloc, ImageState>(
      'emits [initial] when ImageCleared',
      build: () => imageBloc,
      act: (bloc) => bloc.add(ImageCleared()),
      expect: () => [
        const ImageState(),
      ],
    );

    blocTest<ImageBloc, ImageState>(
      'emits [error] when ImageGenerate without image',
      build: () => imageBloc,
      act: (bloc) => bloc.add(ImageGenerate('beach')),
      expect: () => [
        predicate<ImageState>((state) =>
            state.status == ImageStatus.error &&
            state.errorMessage == 'Please select an image first'),
      ],
    );

    blocTest<ImageBloc, ImageState>(
      'emits [error] when ImageGenerate without authentication',
      build: () {
        when(mockAuthService.uid).thenReturn(null);
        final testFile = File('test.jpg');
        imageBloc.add(ImageSelected(testFile));
        return imageBloc;
      },
      act: (bloc) => bloc.add(ImageGenerate('beach')),
      expect: () => [
        predicate<ImageState>((state) =>
            state.status == ImageStatus.imageSelected &&
            state.selectedImage != null),
        predicate<ImageState>((state) =>
            state.status == ImageStatus.error &&
            state.errorMessage == 'User not authenticated'),
      ],
    );

    blocTest<ImageBloc, ImageState>(
      'emits [generating, generated] when ImageGenerate succeeds',
      build: () {
        when(mockAuthService.uid).thenReturn('user-123');
        when(mockImageService.uploadImage(any, 'user-123'))
            .thenAnswer((_) async => 'users/user-123/original/test.jpg');
        when(mockImageService.generateFromImage(
          imagePath: anyNamed('imagePath'),
          category: 'beach',
        )).thenAnswer((_) async {
          return GenerationResult(
            success: true,
            generatedId: 'gen-123',
            generatedImageUrls: [
              'https://example.com/image1.jpg',
              'https://example.com/image2.jpg',
              'https://example.com/image3.jpg',
            ],
            createdAt: DateTime.now(),
          );
        });
        final testFile = File('test.jpg');
        imageBloc.add(ImageSelected(testFile));
        return imageBloc;
      },
      act: (bloc) => bloc.add(ImageGenerate('beach')),
      expect: () => [
        // After ImageSelected
        predicate<ImageState>((state) =>
            state.status == ImageStatus.imageSelected &&
            state.selectedImage != null),
        // After ImageGenerate
        predicate<ImageState>((state) =>
            state.status == ImageStatus.generating &&
            state.selectedCategory == 'beach'),
        predicate<ImageState>((state) =>
            state.status == ImageStatus.generated &&
            state.selectedCategory == 'beach' &&
            state.generatedImageUrls != null &&
            state.generatedImageUrls!.length == 3),
      ],
      verify: (_) {
        verify(mockImageService.uploadImage(any, 'user-123')).called(1);
        verify(mockImageService.generateFromImage(
          imagePath: anyNamed('imagePath'),
          category: 'beach',
        )).called(1);
      },
    );

    blocTest<ImageBloc, ImageState>(
      'emits [generating, error] when ImageGenerate fails',
      build: () {
        when(mockAuthService.uid).thenReturn('user-123');
        when(mockImageService.uploadImage(any, 'user-123'))
            .thenAnswer((_) async => 'users/user-123/original/test.jpg');
        when(mockImageService.generateFromImage(
          imagePath: anyNamed('imagePath'),
          category: 'beach',
        )).thenThrow(Exception('Generation failed'));
        final testFile = File('test.jpg');
        imageBloc.add(ImageSelected(testFile));
        return imageBloc;
      },
      act: (bloc) => bloc.add(ImageGenerate('beach')),
      expect: () => [
        // After ImageSelected
        predicate<ImageState>((state) =>
            state.status == ImageStatus.imageSelected &&
            state.selectedImage != null),
        // After ImageGenerate
        predicate<ImageState>((state) =>
            state.status == ImageStatus.generating &&
            state.selectedCategory == 'beach'),
        predicate<ImageState>((state) =>
            state.status == ImageStatus.error &&
            state.errorMessage == 'Exception: Generation failed' &&
            state.selectedCategory == 'beach'),
      ],
      verify: (_) {
        verify(mockImageService.uploadImage(any, 'user-123')).called(1);
        verify(mockImageService.generateFromImage(
          imagePath: anyNamed('imagePath'),
          category: 'beach',
        )).called(1);
      },
    );

    test('ImageState.copyWith works correctly', () {
      final initialState = const ImageState();
      final newState = initialState.copyWith(
        status: ImageStatus.generating,
        selectedCategory: 'beach',
      );

      expect(newState.status, equals(ImageStatus.generating));
      expect(newState.selectedCategory, equals('beach'));
      expect(initialState.status, equals(ImageStatus.initial)); // Original unchanged
    });

    test('ImageState getters work correctly', () {
      final stateWithImage = ImageState(
        selectedImage: File('test.jpg'),
      );
      final stateGenerating = ImageState(status: ImageStatus.generating);
      final stateGenerated = ImageState(
        status: ImageStatus.generated,
        generatedImageUrls: ['url1', 'url2'],
      );

      expect(stateWithImage.hasImage, isTrue);
      expect(stateGenerating.isGenerating, isTrue);
      expect(stateGenerated.hasResult, isTrue);
    });
  });
}
