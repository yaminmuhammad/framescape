import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/image/image_bloc.dart';

/// Main home screen with Apple Design style - Social Media Photo AI
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  String _selectedCategory = 'beach';

  final List<CategoryOption> _categories = [
    CategoryOption(id: 'beach', name: 'Beach Trip', icon: Icons.beach_access),
    CategoryOption(id: 'city', name: 'City Break', icon: Icons.location_city),
    CategoryOption(id: 'roadtrip', name: 'Road Trip', icon: Icons.directions_car),
    CategoryOption(id: 'mountain', name: 'Mountain', icon: Icons.terrain),
    CategoryOption(id: 'cafe', name: 'Cafe Vibes', icon: Icons.local_cafe),
    CategoryOption(id: 'sunset', name: 'Sunset', icon: Icons.wb_sunny),
  ];

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (image != null && mounted) {
      context.read<ImageBloc>().add(ImageSelected(File(image.path)));
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _onGenerate() {
    context.read<ImageBloc>().add(ImageGenerate(_selectedCategory));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: BlocConsumer<ImageBloc, ImageState>(
          listener: (context, state) {
            if (state.status == ImageStatus.error &&
                state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            return CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  floating: true,
                  backgroundColor: colorScheme.surface,
                  surfaceTintColor: Colors.transparent,
                  title: Text(
                    'FrameScape',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  centerTitle: false,
                  actions: [
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, authState) {
                        return IconButton(
                          icon: Icon(
                            authState.isAuthenticated
                                ? Icons.person
                                : Icons.person_outline,
                            color: colorScheme.primary,
                          ),
                          onPressed: () {
                            // Show user info or login
                          },
                        );
                      },
                    ),
                  ],
                ),

                // Content
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Image Selection Area
                      _buildImageArea(state, colorScheme),
                      const SizedBox(height: 24),

                      // Category Selection
                      _buildCategorySection(colorScheme),
                      const SizedBox(height: 20),

                      // Generate Button
                      _buildGenerateButton(state, colorScheme),
                      const SizedBox(height: 32),

                      // Results Section
                      if (state.hasResult) ...[
                        _buildResultSection(state, colorScheme),
                      ],
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildImageArea(ImageState state, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 280,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: state.hasImage
                ? colorScheme.primary.withOpacity(0.5)
                : colorScheme.outline.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: state.hasImage
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: state.hasImage
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(state.selectedImage!, fit: BoxFit.cover),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Material(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            context.read<ImageBloc>().add(ImageCleared());
                          },
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 40,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tap to select an image',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'From gallery or camera',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Scene',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategory == category.id;
              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category.id;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 80,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outline.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          category.icon,
                          size: 28,
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category.name.split(' ').first,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? colorScheme.onPrimary
                                : colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateButton(ImageState state, ColorScheme colorScheme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 56,
      child: ElevatedButton(
        onPressed: state.isGenerating || !state.hasImage ? null : _onGenerate,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.surfaceContainerHighest,
          disabledForegroundColor: colorScheme.outline,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: state.hasImage ? 4 : 0,
          shadowColor: colorScheme.primary.withOpacity(0.4),
        ),
        child: state.isGenerating
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Generating...',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 22,
                    color: state.hasImage
                        ? colorScheme.onPrimary
                        : colorScheme.outline,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Generate Magic',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: state.hasImage
                          ? colorScheme.onPrimary
                          : colorScheme.outline,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildResultSection(ImageState state, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome, color: colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Generated Images',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Grid of generated images
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: state.generatedImageUrls.length,
          itemBuilder: (context, index) {
            return _buildGeneratedImageTile(state, colorScheme, index);
          },
        ),
        const SizedBox(height: 16),
        // Share/Save buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement save to gallery
                },
                icon: const Icon(Icons.download, size: 20),
                label: const Text('Save All'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement share
                },
                icon: const Icon(Icons.share, size: 20),
                label: const Text('Share'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.secondaryContainer,
                  foregroundColor: colorScheme.onSecondaryContainer,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGeneratedImageTile(
    ImageState state,
    ColorScheme colorScheme,
    int index,
  ) {
    final imageUrl = index < state.generatedImageUrls.length
        ? state.generatedImageUrls[index]
        : null;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: state.isGenerating
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  // Actual generated image
                  if (imageUrl != null)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: colorScheme.primaryContainer.withOpacity(0.3),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                size: 48,
                                color: colorScheme.outline,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Failed to load',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      color: colorScheme.primaryContainer.withOpacity(0.3),
                      child: const Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  // Overlay with action buttons
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FloatingActionButton.small(
                          heroTag: 'save_$index',
                          onPressed: () {
                            if (imageUrl != null) {
                              _saveImageToGallery(imageUrl);
                            }
                          },
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.download,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        FloatingActionButton.small(
                          heroTag: 'share_$index',
                          onPressed: () {
                            if (imageUrl != null) {
                              _shareImage(imageUrl);
                            }
                          },
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.share,
                            size: 16,
                            color: colorScheme.primary,
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

  void _saveImageToGallery(String imageUrl) {
    // TODO: Implement save to gallery using image_downloader or similar package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Save feature coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareImage(String imageUrl) {
    // TODO: Implement share using share_plus package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share feature coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Category option model
class CategoryOption {
  final String id;
  final String name;
  final IconData icon;

  CategoryOption({
    required this.id,
    required this.name,
    required this.icon,
  });
}
