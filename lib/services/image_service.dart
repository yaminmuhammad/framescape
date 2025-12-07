import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

/// Service for handling image generation via Cloud Functions.
class ImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Upload image to Firebase Storage
  /// Returns the storage path of the uploaded image
  Future<String> uploadImage(File imageFile, String userId) async {
    final imageId = _uuid.v4();
    final extension = imageFile.path.split('.').last;
    final storagePath = 'users/$userId/original/$imageId.$extension';

    final ref = _storage.ref().child(storagePath);
    await ref.putFile(imageFile);

    return storagePath;
  }

  /// Call Cloud Function to generate AI content from image
  /// Returns the generation result
  Future<GenerationResult> generateFromImage({
    required String imagePath,
    required String category,
  }) async {
    try {
      final callable = _functions.httpsCallable('generateImage');
      final result = await callable.call({
        'imagePath': imagePath,
        'category': category,
      });

      final data = result.data as Map<String, dynamic>;
      return GenerationResult(
        success: data['success'] ?? false,
        generatedId: data['generatedId'] ?? '',
        generatedImageUrls: List<String>.from(data['generatedImageUrls'] ?? []),
        createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
      );
    } on FirebaseFunctionsException catch (e) {
      throw ImageServiceException(e.message ?? 'Generation failed');
    }
  }

  /// Stream of user's generated images from Firestore
  Stream<List<GeneratedImage>> getUserImages(String userId) {
    return _firestore
        .collection('images')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GeneratedImage.fromFirestore(doc))
              .toList(),
        );
  }
}

/// Result from image generation
class GenerationResult {
  final bool success;
  final String generatedId;
  final List<String> generatedImageUrls;
  final DateTime createdAt;

  GenerationResult({
    required this.success,
    required this.generatedId,
    required this.generatedImageUrls,
    required this.createdAt,
  });
}

/// Model for generated image from Firestore
class GeneratedImage {
  final String id;
  final String userId;
  final String originalImagePath;
  final String prompt;
  final String generatedText;
  final DateTime createdAt;

  GeneratedImage({
    required this.id,
    required this.userId,
    required this.originalImagePath,
    required this.prompt,
    required this.generatedText,
    required this.createdAt,
  });

  factory GeneratedImage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GeneratedImage(
      id: doc.id,
      userId: data['userId'] ?? '',
      originalImagePath: data['originalImagePath'] ?? '',
      prompt: data['prompt'] ?? '',
      generatedText: data['generatedText'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Custom exception for image service errors
class ImageServiceException implements Exception {
  final String message;
  ImageServiceException(this.message);

  @override
  String toString() => message;
}
