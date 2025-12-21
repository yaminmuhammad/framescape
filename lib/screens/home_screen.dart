import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/image/image_bloc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  String _selectedCategory = 'cyberpunk'; // Default from design
  String? _fullScreenImageUrl;

  // Updated categories to match Design
  final List<CategoryOption> _categories = [
    CategoryOption(
      id: 'cyberpunk',
      name: 'Cyberpunk',
      icon: Icons.auto_awesome,
    ),
    CategoryOption(id: 'studio', name: 'Studio', icon: Icons.camera_alt),
    CategoryOption(id: 'nature', name: 'Nature', icon: Icons.nature_people),
    CategoryOption(id: 'retro', name: 'Retro', icon: Icons.filter_vintage),
  ];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        context.read<ImageBloc>().add(ImageSelected(File(image.path)));
      }
    } catch (e) {
      // Handle permission errors etc
      debugPrint('Error picking image: $e');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.blue),
                ),
                title: const Text(
                  'Choose from Gallery',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.purple),
                ),
                title: const Text(
                  'Take a Photo',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _onGenerate() {
    context.read<ImageBloc>().add(ImageGenerate(_selectedCategory));
  }

  void _reset() {
    context.read<ImageBloc>().add(ImageCleared());
  }

  Future<void> _saveImageToGallery(String imageUrl) async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Downloading image...')));

      final response = await http.get(Uri.parse(imageUrl));
      final bytes = response.bodyBytes;
      final tempDir = await getTemporaryDirectory();
      final file = await File(
        '${tempDir.path}/image_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ).create();
      await file.writeAsBytes(bytes);

      await Gal.putImage(file.path, album: 'FrameScape');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved to Gallery!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareImage(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      final bytes = response.bodyBytes;
      final tempDir = await getTemporaryDirectory();
      final file = await File(
        '${tempDir.path}/image_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ).create();
      await file.writeAsBytes(bytes);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Check out my AI generated scene!');
    } catch (e) {
      debugPrint('Error sharing: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocConsumer<ImageBloc, ImageState>(
        listener: (context, state) {
          if (state.status == ImageStatus.error && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: colorScheme.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          return BlocListener<AuthBloc, AuthState>(
            listener: (context, authState) {
              if (authState.status == AuthStatus.error &&
                  authState.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(authState.errorMessage!),
                    backgroundColor: colorScheme.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            child: _buildBody(
              context,
              state,
              colorScheme,
              categories: _categories,
              selectedCategory: _selectedCategory,
              onCategorySelected: (id) {
                setState(() {
                  _selectedCategory = id;
                });
              },
              onGenerate: _onGenerate,
              onPickImage: _showImageSourceDialog,
              fullScreenImageUrl: _fullScreenImageUrl,
              onCloseFullScreen: () {
                setState(() {
                  _fullScreenImageUrl = null;
                });
              },
              onSaveImage: _saveImageToGallery,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ImageState state,
    ColorScheme colorScheme, {
    required List<CategoryOption> categories,
    required String selectedCategory,
    required Function(String) onCategorySelected,
    required VoidCallback onGenerate,
    required VoidCallback onPickImage,
    String? fullScreenImageUrl,
    required VoidCallback onCloseFullScreen,
    required Function(String) onSaveImage,
  }) {
    // Full Screen Image Viewer
    if (fullScreenImageUrl != null) {
      return _buildFullScreenViewer(
        colorScheme,
        fullScreenImageUrl: fullScreenImageUrl,
        onClose: onCloseFullScreen,
        onSave: onSaveImage,
      );
    }

    return Stack(
      children: [
        // Main Scrollable Content
        CustomScrollView(
          slivers: [
            // Top App Bar
            SliverAppBar(
              floating: true,
              pinned: true,
              backgroundColor: Theme.of(
                context,
              ).scaffoldBackgroundColor.withOpacity(0.7),
              surfaceTintColor: Colors.transparent,
              centerTitle: true,
              flexibleSpace: ClipRRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(color: Colors.transparent),
                ),
              ),
              title: Text(
                'FrameScape',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              actions: [],
            ),

            // Hero Text
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 24,
                ),
                child: Column(
                  children: [
                    Text(
                      state.hasResult
                          ? 'Your Scenes Are Ready!'
                          : state.isGenerating
                          ? 'Creating Magic.'
                          : state.status == ImageStatus.error
                          ? 'Generation Failed'
                          : 'Transform your photos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                        color: colorScheme.onSurface,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.hasResult
                          ? 'We\'ve transformed your photo into these amazing travel locations.'
                          : state.isGenerating
                          ? 'Hold tight while we generate your new social media scenes.'
                          : state.status == ImageStatus.error
                          ? 'We couldn\'t create your scene. Please give it another try.'
                          : 'Upload a selfie to generate 10+ social media scenes instantly.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurface.withOpacity(0.6),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverToBoxAdapter(
                child: _buildMainContent(
                  context,
                  state,
                  colorScheme,
                  onGenerate: _onGenerate,
                  onPickImage: _showImageSourceDialog,
                ),
              ),
            ),

            // Style Selector (Hidden if has result)
            if (!state.hasResult)
              SliverToBoxAdapter(
                child: Opacity(
                  opacity:
                      state.isGenerating || state.status == ImageStatus.error
                      ? 0.5
                      : 1.0,
                  child: IgnorePointer(
                    ignoring:
                        state.isGenerating || state.status == ImageStatus.error,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 32),
                      child: _buildStyleSelector(
                        colorScheme,
                        categories: categories,
                        selectedCategory: selectedCategory,
                        onCategorySelected: onCategorySelected,
                      ),
                    ),
                  ),
                ),
              ),

            // Recent Creations (Hidden if has result)
            if (!state.hasResult)
              SliverToBoxAdapter(
                child: Opacity(
                  opacity:
                      state.isGenerating || state.status == ImageStatus.error
                      ? 0.5
                      : 1.0,
                  child: IgnorePointer(
                    ignoring:
                        state.isGenerating || state.status == ImageStatus.error,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24, bottom: 120),
                      child: _buildRecentCreations(colorScheme),
                    ),
                  ),
                ),
              ),

            // Results Grid (Only if has result)
            if (state.hasResult) ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Generated Results',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${state.generatedImageUrls.length} variations',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildResultItem(
                      state.generatedImageUrls[index],
                      colorScheme,
                      index,
                    ),
                    childCount: state.generatedImageUrls.length,
                  ),
                ),
              ),
            ],
          ],
        ),

        // Bottom Floating Action Bar
        Positioned(
          bottom: 32,
          left: 24,
          right: 24,
          child: _buildBottomBar(
            state,
            colorScheme,
            onGenerate:
                _onGenerate, // Wait. _buildBody doesn't know _onGenerate??
            onPickImage: _showImageSourceDialog, // Same.
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    ImageState state,
    ColorScheme colorScheme, {
    required VoidCallback onGenerate,
    required VoidCallback onPickImage,
  }) {
    if (state.isGenerating) {
      return _buildLoadingState(context, colorScheme);
    } else if (state.status == ImageStatus.error) {
      return _buildErrorState(
        context,
        colorScheme,
        state.errorMessage ?? 'Unknown error',
        onRetry: onGenerate,
      );
    } else if (state.hasResult) {
      return _buildResultHeader(state, colorScheme);
    } else {
      return _buildUploadZone(state, colorScheme, onPickImage: onPickImage);
    }
  }

  Widget _buildUploadZone(
    ImageState state,
    ColorScheme colorScheme, {
    required VoidCallback onPickImage,
  }) {
    final hasImage = state.selectedImage != null;

    return GestureDetector(
      onTap: onPickImage,
      child: Container(
        height: 320,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? colorScheme.surfaceContainerHighest.withOpacity(0.5)
              : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: hasImage
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.3),
            width: hasImage ? 2 : 2,
            style: hasImage
                ? BorderStyle.solid
                : BorderStyle
                      .solid, // Using solid for selected, dashed ideally for empty but standard Border doesn't support dashed easily without package
          ),
          // Using a simple box shadow for elevation
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.04), // Softer shadow
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: hasImage
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(state.selectedImage!, fit: BoxFit.cover),
                    // Check successful icon overlay
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Tap to change photo',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_a_photo,
                        size: 32,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Tap to Upload',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Supported formats: JPG, PNG',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        'Select Photo',
                        style: TextStyle(
                          color: colorScheme.surface,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, ColorScheme colorScheme) {
    return Container(
      height: 360,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withOpacity(0.05),
            colorScheme.primary.withOpacity(0.1),
            colorScheme.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated background circles
          ...List.generate(3, (index) {
            return Positioned(
              top: 40 + (index * 30),
              right: 30 + (index * 20),
              child: Container(
                width: 60 - (index * 15),
                height: 60 - (index * 15),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary.withOpacity(0.08 - (index * 0.02)),
                ),
              ),
            );
          }),
          // Main content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated loader container
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.15),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Custom loader with glow
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow ring
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                colorScheme.primary.withOpacity(0.3),
                                colorScheme.primary.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                        // Progress indicator
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: colorScheme.primary,
                            backgroundColor: colorScheme.primary.withOpacity(
                              0.2,
                            ),
                          ),
                        ),
                        // Center icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.primary,
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withOpacity(0.4),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Title
                    Text(
                      'Creating Your Scenes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Subtitle
                    Text(
                      'AI is working its magic...',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    ColorScheme colorScheme,
    String error, {
    VoidCallback? onRetry,
  }) {
    return Container(
      height: 320,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? colorScheme.surfaceContainerHighest.withOpacity(0.5)
            : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.error.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 40,
              color: colorScheme.error,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Our AI encountered a temporary glitch. Please check your connection and retry.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry Generation'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.onSurface,
              side: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultHeader(ImageState state, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? colorScheme.surfaceContainerHighest
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: state.selectedImage != null
                  ? Image.file(state.selectedImage!, fit: BoxFit.cover)
                  : Container(color: Colors.grey),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ORIGINAL UPLOAD',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.selectedImage?.path.split('/').last ?? 'image.jpg',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, size: 18, color: colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleSelector(
    ColorScheme colorScheme, {
    required List<CategoryOption> categories,
    required String selectedCategory,
    required Function(String) onCategorySelected,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Choose Vibe',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = selectedCategory == category.id;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onCategorySelected(category.id);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.only(
                    left: 4,
                    right: 16,
                    top: 4,
                    bottom: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary
                        : (Theme.of(context).brightness == Brightness.dark
                              ? colorScheme.surfaceContainerHighest
                              : Colors.white),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.black.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          category.icon,
                          size: 20,
                          color: isSelected
                              ? Colors.black
                              : colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        category.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.black
                              : colorScheme.onSurface,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentCreations(ColorScheme colorScheme) {
    // Dummy Data for visual reference as in design
    final recentImages = [
      'https://lh3.googleusercontent.com/aida-public/AB6AXuDvfOTkVWICMWqLXRLV6fg4rcqs49t8TH2qmEq-QNTW_ipkb-6hhFcoCP3bNTbvCgmgpwYa4_6I-4UW558b-v5PccTEWaeMbbGcwkuJjI20hnalpBmuZ9uWUFZ_T61a7dQ9WLBlIkwy2jRw5kHYqwMpbeVttu1o0fxhHFqIdaxsGLPknOBTkn2JK7LMfQ0YIUll1SYLSn9OOwOLs99D56Fmu7sgbW5wmx6-yJQf8fSPOjqs6GZ1dWeka5bZULsGEJfjjJTqj4Rk2O0',
      'https://lh3.googleusercontent.com/aida-public/AB6AXuD_bgAG0bLGhRdMo6t-rU-2LO0hNSYWiPIV6tchIc9l_6Z5AHOgzwa21qK-YJhgDHzHUCMPu08YbxYgYsxbAS2EWZP8Y_2of1M074-oxuyHcm8Lffed6E6QATUZg3Pd6fNbjDeyumhwUv57TlqMsKILkGZWC3JDzuEVQaAFc7E-MQyx5KGxzK8Pl9FQ89uFeha57tXNs8nxRgj7cmYgL2FS5iMTA59njAFlnL9r-I3bOB2IsBTxNd_fG_rseLv4vUg6GQn98junkNg',
      'https://lh3.googleusercontent.com/aida-public/AB6AXuC3skJsVg3uDH0NFEcn0iYdKDKjzWB1ItMU5Cz84boE9Y3mAvWeyynty6OLq4PsJcl7EjPFon2q-KOhxnYyukRp1xGVjJ9DEjbZwG0JKZ66DVnldr5vfJDG3pjB6Gwjr6mIuclhfbwcLpLMUmGKOa16g9JwvcI9z6QSZDOVcUIJHC-wCV9RGQq6ZN6SjljBNfJsVMnEwZbSeoQOmZbPw6u4GYPiIWZHrh4QoVaa1T371FoU2t1VmUfZyQMLq_Hx3pXJJSsqHcu_B6Y',
    ];
    final recentTitles = ['Neon Portrait', 'Cyber City', 'Synthwave'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Recent Creations',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount: recentImages.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: colorScheme.surfaceContainerHighest,
                      image: DecorationImage(
                        image: NetworkImage(recentImages[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.download,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      recentTitles[index],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultItem(String imageUrl, ColorScheme colorScheme, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _fullScreenImageUrl = imageUrl;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: colorScheme.surfaceContainerHighest,
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05), // Softened shadow
              blurRadius: 8, // Softened blur
              offset: const Offset(0, 2), // Softened offset
            ),
          ],
        ),
        child: Stack(
          children: [
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                ),
              ),
            ),
            // Like / Download buttons
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _categories
                              .firstWhere(
                                (c) => c.id == _selectedCategory,
                                orElse: () => _categories[0],
                              )
                              .name
                              .toUpperCase(),
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Text(
                          'Generated Scene', // Dynamic name in real app
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _saveImageToGallery(imageUrl),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.download,
                        size: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(
    ImageState state,
    ColorScheme colorScheme, {
    required VoidCallback onGenerate,
    required VoidCallback onPickImage,
  }) {
    if (state.hasResult) {
      return Container(
        height: 56,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () {
              HapticFeedback.mediumImpact();
              _reset();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: Colors.black),
                SizedBox(width: 8),
                Text(
                  'Generate More',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state.isGenerating) {
      return Container(
        height: 56,
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.9),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.black,
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Generating...',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    if (state.status == ImageStatus.error) {
      return Container(
        height: 56,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: _reset, // Or retry
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.replay, color: Colors.black),
                SizedBox(width: 8),
                Text(
                  'Try Again',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Default state
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            HapticFeedback.mediumImpact();
            state.hasImage ? onGenerate() : onPickImage();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                state.hasImage ? Icons.auto_awesome : Icons.add_photo_alternate,
                color: Colors.black,
              ),
              const SizedBox(width: 8),
              Text(
                state.hasImage ? 'Generate Scenes' : 'Select Photo first',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Full Screen Viewer implementation reuse
  Widget _buildFullScreenViewer(
    ColorScheme colorScheme, {
    required String fullScreenImageUrl,
    required VoidCallback onClose,
    required Function(String) onSave,
  }) {
    return Container(
      // Simplified placeholder for length constraint, existing implementation was fine
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(fullScreenImageUrl, fit: BoxFit.contain),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: onClose,
            ),
          ),
          Positioned(
            bottom: 40,
            right: 20,
            child: FloatingActionButton(
              onPressed: () => onSave(fullScreenImageUrl),
              backgroundColor: Colors.white,
              child: const Icon(Icons.download, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryOption {
  final String id;
  final String name;
  final IconData icon;

  CategoryOption({required this.id, required this.name, required this.icon});
}
