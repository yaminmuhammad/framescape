import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/auth_service.dart';
import '../../services/image_service.dart';

part 'image_event.dart';
part 'image_state.dart';

/// BLoC for handling image selection and AI generation
class ImageBloc extends Bloc<ImageEvent, ImageState> {
  final ImageService _imageService;
  final AuthService _authService;

  ImageBloc({ImageService? imageService, AuthService? authService})
    : _imageService = imageService ?? ImageService(),
      _authService = authService ?? AuthService(),
      super(const ImageState()) {
    on<ImageSelected>(_onImageSelected);
    on<ImageCleared>(_onImageCleared);
    on<ImageGenerate>(_onImageGenerate);
  }

  void _onImageSelected(ImageSelected event, Emitter<ImageState> emit) {
    emit(
      state.copyWith(
        status: ImageStatus.imageSelected,
        selectedImage: event.imageFile,
        clearGeneratedText: true,
      ),
    );
  }

  void _onImageCleared(ImageCleared event, Emitter<ImageState> emit) {
    emit(const ImageState());
  }

  Future<void> _onImageGenerate(
    ImageGenerate event,
    Emitter<ImageState> emit,
  ) async {
    if (state.selectedImage == null) {
      emit(
        state.copyWith(
          status: ImageStatus.error,
          errorMessage: 'Please select an image first',
        ),
      );
      return;
    }

    final userId = _authService.uid;
    if (userId == null) {
      emit(
        state.copyWith(
          status: ImageStatus.error,
          errorMessage: 'User not authenticated',
        ),
      );
      return;
    }

    emit(state.copyWith(status: ImageStatus.generating));

    try {
      // Upload image to Storage
      final imagePath = await _imageService.uploadImage(
        state.selectedImage!,
        userId,
      );

      // Call Cloud Function
      final result = await _imageService.generateFromImage(
        imagePath: imagePath,
        prompt: event.prompt,
      );

      emit(
        state.copyWith(
          status: ImageStatus.generated,
          generatedText: result.generatedText,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: ImageStatus.error, errorMessage: e.toString()),
      );
    }
  }
}
