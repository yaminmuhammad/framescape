part of 'image_bloc.dart';

/// Possible image states
enum ImageStatus { initial, imageSelected, generating, generated, error }

/// Image state class
class ImageState {
  final ImageStatus status;
  final File? selectedImage;
  final String? generatedText;
  final String? errorMessage;
  final List<GeneratedImage> history;

  const ImageState({
    this.status = ImageStatus.initial,
    this.selectedImage,
    this.generatedText,
    this.errorMessage,
    this.history = const [],
  });

  /// Copy with method
  ImageState copyWith({
    ImageStatus? status,
    File? selectedImage,
    String? generatedText,
    String? errorMessage,
    List<GeneratedImage>? history,
    bool clearImage = false,
    bool clearGeneratedText = false,
  }) {
    return ImageState(
      status: status ?? this.status,
      selectedImage: clearImage ? null : (selectedImage ?? this.selectedImage),
      generatedText: clearGeneratedText
          ? null
          : (generatedText ?? this.generatedText),
      errorMessage: errorMessage,
      history: history ?? this.history,
    );
  }

  /// Helper getters
  bool get hasImage => selectedImage != null;
  bool get isGenerating => status == ImageStatus.generating;
  bool get hasResult =>
      status == ImageStatus.generated && generatedText != null;
}
