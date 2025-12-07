part of 'image_bloc.dart';

/// Possible image states
enum ImageStatus { initial, imageSelected, generating, generated, error }

/// Image state class
class ImageState {
  final ImageStatus status;
  final File? selectedImage;
  final List<String> generatedImageUrls;
  final String? errorMessage;
  final List<GeneratedImage> history;
  final String? selectedCategory;

  const ImageState({
    this.status = ImageStatus.initial,
    this.selectedImage,
    this.generatedImageUrls = const [],
    this.errorMessage,
    this.history = const [],
    this.selectedCategory,
  });

  /// Copy with method
  ImageState copyWith({
    ImageStatus? status,
    File? selectedImage,
    List<String>? generatedImageUrls,
    String? errorMessage,
    List<GeneratedImage>? history,
    bool clearImage = false,
    bool clearGeneratedImages = false,
    String? selectedCategory,
  }) {
    return ImageState(
      status: status ?? this.status,
      selectedImage: clearImage ? null : (selectedImage ?? this.selectedImage),
      generatedImageUrls: clearGeneratedImages
          ? []
          : (generatedImageUrls ?? this.generatedImageUrls),
      errorMessage: errorMessage,
      history: history ?? this.history,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }

  /// Helper getters
  bool get hasImage => selectedImage != null;
  bool get isGenerating => status == ImageStatus.generating;
  bool get hasResult =>
      status == ImageStatus.generated && generatedImageUrls.isNotEmpty;
}
