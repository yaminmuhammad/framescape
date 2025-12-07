part of 'image_bloc.dart';

/// Base class for image events
abstract class ImageEvent {}

/// Select an image from gallery or camera
class ImageSelected extends ImageEvent {
  final File imageFile;
  ImageSelected(this.imageFile);
}

/// Clear selected image
class ImageCleared extends ImageEvent {}

/// Generate AI content from the selected image
class ImageGenerate extends ImageEvent {
  final String category;
  ImageGenerate(this.category);
}

/// Load user's generation history
class ImageLoadHistory extends ImageEvent {}
