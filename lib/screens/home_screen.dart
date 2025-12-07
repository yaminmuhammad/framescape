import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/image/image_bloc.dart';

/// Main home screen with Apple Design style - Social Media Photo AI
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  String _selectedCategory = 'beach';
  String? _fullScreenImageUrl;

  final List<CategoryOption> _categories = [
    CategoryOption(id: 'beach', name: 'Beach Trip', icon: Icons.beach_access),
    CategoryOption(id: 'city', name: 'City Break', icon: Icons.location_city),
    CategoryOption(
      id: 'roadtrip',
      name: 'Road Trip',
      icon: Icons.directions_car,
    ),
    CategoryOption(id: 'mountain', name: 'Mountain', icon: Icons.terrain),
    CategoryOption(id: 'cafe', name: 'Cafe Vibes', icon: Icons.local_cafe),
    CategoryOption(id: 'sunset', name: 'Sunset', icon: Icons.wb_sunny),
  ];

  @override
  void initState() {
    super.initState();
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
            final mainContent = CustomScrollView(
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
                  // actions: [
                  //   BlocBuilder<AuthBloc, AuthState>(
                  //     builder: (context, authState) {
                  //       return IconButton(
                  //         icon: Icon(
                  //           authState.isAuthenticated
                  //               ? Icons.person
                  //               : Icons.person_outline,
                  //           color: colorScheme.primary,
                  //         ),
                  //         onPressed: () {
                  //           // Show user info or login
                  //         },
                  //       );
                  //     },
                  //   ),
                  // ],
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
                      if (state.hasResult || state.isGenerating) ...[
                        _buildResultSection(state, colorScheme),
                      ],
                    ]),
                  ),
                ),
              ],
            );

            // Full-screen image viewer
            if (_fullScreenImageUrl != null) {
              return Stack(
                children: [
                  mainContent,
                  _FullScreenImageViewer(
                    imageUrl: _fullScreenImageUrl!,
                    onClose: () {
                      setState(() {
                        _fullScreenImageUrl = null;
                      });
                    },
                    onSave: _saveImageToGallery,
                    onShare: _shareImage,
                  ),
                ],
              );
            }

            return mainContent;
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
        // Header with animated icon
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: state.isGenerating
              ? Row(
                  key: const ValueKey('generating'),
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Generating Magic...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                )
              : Row(
                  key: const ValueKey('generated'),
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: colorScheme.primary,
                      size: 20,
                    ),
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
        ),
        const SizedBox(height: 16),

        // Grid of generated images or skeleton
        state.isGenerating
            ? _AnimatedGeneratingGrid(colorScheme: colorScheme)
            : GridView.builder(
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

        // Share/Save buttons (disabled during generation)
        if (!state.isGenerating)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (state.generatedImageUrls.isNotEmpty) {
                      _saveAllImages(state.generatedImageUrls);
                    }
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
                    if (state.generatedImageUrls.isNotEmpty) {
                      _shareAllImages(state.generatedImageUrls);
                    }
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
          )
        else
          // Disabled skeleton buttons during generation
          _DisabledButtonSkeleton(colorScheme: colorScheme),
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

    return GestureDetector(
      onTap: imageUrl != null && !state.isGenerating
          ? () {
              setState(() {
                _fullScreenImageUrl = imageUrl;
              });
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: state.isGenerating
              ? _AnimatedLoadingTile(colorScheme: colorScheme)
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
                            color: colorScheme.primaryContainer.withOpacity(
                              0.3,
                            ),
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
                    // Tap indicator (only when not generating)
                    if (imageUrl != null && !state.isGenerating)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.fullscreen,
                            size: 16,
                            color: Colors.white,
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
      ),
    );
  }

  Future<void> _saveImageToGallery(String imageUrl) async {
    if (!mounted) return;

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Downloading image...'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Download image from URL
      final response = await http.get(Uri.parse(imageUrl));

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Save to temporary file first
        final directory = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'FrameScape_$timestamp.jpg'; // Using jpg extension
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        // Save to Gallery using Gal
        await Gal.putImage(file.path, album: 'FrameScape');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image saved to Gallery!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        // Clean up temp file
        if (await file.exists()) {
          await file.delete();
        }
      } else {
        throw Exception('Failed to download image: ${response.statusCode}');
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save image: $error'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _shareImage(String imageUrl) async {
    if (!mounted) return;

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preparing to share...'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Download image from URL to share the file
      final response = await http.get(Uri.parse(imageUrl));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'FrameScape_$timestamp.jpg';
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        // Share the file
        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'Check out this image I created with FrameScape AI!');
      } else {
        throw Exception('Failed to download image for sharing');
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing: $error'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveAllImages(List<String> imageUrls) async {
    if (!mounted) return;

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saving ${imageUrls.length} images to Gallery...'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      int successCount = 0;
      int failCount = 0;

      for (int i = 0; i < imageUrls.length; i++) {
        try {
          final response = await http.get(Uri.parse(imageUrls[i]));
          if (response.statusCode == 200) {
            final directory = await getTemporaryDirectory();
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final fileName = 'FrameScape_${timestamp}_$i.jpg';
            final file = File('${directory.path}/$fileName');
            await file.writeAsBytes(response.bodyBytes);

            // Save to Gallery
            await Gal.putImage(file.path, album: 'FrameScape');
            successCount++;

            // Clean up
            if (await file.exists()) {
              await file.delete();
            }
          } else {
            failCount++;
          }
        } catch (error) {
          failCount++;
        }
      }

      if (!mounted) return;

      if (successCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Saved $successCount images to Gallery!${failCount > 0 ? ' ($failCount failed)' : ''}',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception('Failed to download any images');
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save images: $error'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _shareAllImages(List<String> imageUrls) async {
    if (!mounted) return;

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Preparing ${imageUrls.length} images...'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      List<XFile> xFiles = [];

      for (int i = 0; i < imageUrls.length; i++) {
        try {
          final response = await http.get(Uri.parse(imageUrls[i]));
          if (response.statusCode == 200) {
            final directory = await getTemporaryDirectory();
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final fileName = 'FrameScape_Share_${timestamp}_$i.jpg';
            final file = File('${directory.path}/$fileName');
            await file.writeAsBytes(response.bodyBytes);

            xFiles.add(XFile(file.path));
          }
        } catch (e) {
          // Skip failed images
        }
      }

      if (xFiles.isNotEmpty) {
        await Share.shareXFiles(
          xFiles,
          text: 'Check out these images created with FrameScape AI!',
        );
      } else {
        throw Exception('No images could be downloaded for sharing');
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildImageSourceButton({
    required IconData icon,
    required String label,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// Animated loading tile with shimmer effect and progress dots
class _AnimatedLoadingTile extends StatefulWidget {
  final ColorScheme colorScheme;

  const _AnimatedLoadingTile({required this.colorScheme});

  @override
  State<_AnimatedLoadingTile> createState() => _AnimatedLoadingTileState();
}

class _AnimatedLoadingTileState extends State<_AnimatedLoadingTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shimmerAnimation;
  int _dotCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _fadeAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _shimmerAnimation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.repeat(reverse: true);

    // Animate dots count
    _startDotAnimation();
  }

  void _startDotAnimation() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _dotCount = (_dotCount + 1) % 4;
        });
        _startDotAnimation();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = widget.colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primaryContainer.withOpacity(0.3),
                colorScheme.secondaryContainer.withOpacity(0.3),
              ],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Multi-layer spectacular shimmer effects
              // Spotlight beam effects - Layer 1: Bright White
              AnimatedBuilder(
                animation: _shimmerAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      _shimmerAnimation.value * 300,
                      _shimmerAnimation.value * 300,
                    ),
                    child: Transform.scale(
                      scale: 1.0 + (_shimmerAnimation.value.abs() * 0.5),
                      child: Center(
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.8),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withOpacity(0.9),
                                  Colors.white.withOpacity(0.6),
                                  Colors.white.withOpacity(0.3),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.4, 0.7, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Spotlight beam effects - Layer 2: Colorful Rainbow
              AnimatedBuilder(
                animation: _shimmerAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      _shimmerAnimation.value * -200,
                      _shimmerAnimation.value * -200,
                    ),
                    child: Transform.scale(
                      scale: 0.8 + (_shimmerAnimation.value.abs() * 0.3),
                      child: Center(
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withOpacity(0.6),
                                blurRadius: 25,
                                spreadRadius: 8,
                              ),
                              BoxShadow(
                                color: colorScheme.secondary.withOpacity(0.6),
                                blurRadius: 25,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  colorScheme.primary.withOpacity(0.7),
                                  colorScheme.secondary.withOpacity(0.7),
                                  colorScheme.primary.withOpacity(0.5),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.5, 0.8, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Spotlight beam effects - Layer 3: Golden Glow
              AnimatedBuilder(
                animation: _shimmerAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      _shimmerAnimation.value * 150,
                      _shimmerAnimation.value * 150,
                    ),
                    child: Transform.scale(
                      scale: 0.6 + (_shimmerAnimation.value.abs() * 0.4),
                      child: Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.8),
                                blurRadius: 20,
                                spreadRadius: 6,
                              ),
                              BoxShadow(
                                color: Colors.yellow.withOpacity(0.6),
                                blurRadius: 20,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.amber.withOpacity(0.8),
                                  Colors.yellow.withOpacity(0.6),
                                  Colors.amber.withOpacity(0.4),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.5, 0.8, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Magic wand icon with rotation
                    AnimatedBuilder(
                      animation: _scaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.auto_awesome,
                              size: 32,
                              color: colorScheme.primary,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Animated dots
                    AnimatedBuilder(
                      animation: _fadeAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeAnimation.value,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(3, (index) {
                              final isActive = index < _dotCount;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                width: isActive ? 12 : 8,
                                height: isActive ? 12 : 8,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? colorScheme.primary
                                      : colorScheme.outline.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                              );
                            }),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // Progress text
                    AnimatedBuilder(
                      animation: _fadeAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeAnimation.value,
                          child: Text(
                            _getProgressText(),
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getProgressText() {
    switch (_dotCount) {
      case 1:
        return 'Generating magic';
      case 2:
        return 'Creating variants';
      case 3:
        return 'Almost ready';
      default:
        return 'Preparing...';
    }
  }
}

/// Animated generating grid with skeleton placeholders
class _AnimatedGeneratingGrid extends StatefulWidget {
  final ColorScheme colorScheme;

  const _AnimatedGeneratingGrid({required this.colorScheme});

  @override
  State<_AnimatedGeneratingGrid> createState() =>
      _AnimatedGeneratingGridState();
}

class _AnimatedGeneratingGridState extends State<_AnimatedGeneratingGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = widget.colorScheme;

    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: 3, // Show 3 skeleton tiles
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Multi-layer spectacular shimmer gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.primaryContainer.withOpacity(0.4),
                            colorScheme.secondaryContainer.withOpacity(0.5),
                            colorScheme.primaryContainer.withOpacity(0.4),
                          ],
                          stops: [0.0, _shimmerAnimation.value, 1.0],
                        ),
                      ),
                    ),

                    // Bright sparkle overlay
                    AnimatedBuilder(
                      animation: _shimmerAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(
                            _shimmerAnimation.value * 200,
                            _shimmerAnimation.value * 200,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.transparent,
                                  Colors.white.withOpacity(0.8),
                                  Colors.white.withOpacity(0.4),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.3, 0.7, 1.0],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Magic icon
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          size: 28,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),

                    // Progress indicator at bottom
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: colorScheme.outline.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Stack(
                          children: [
                            AnimatedBuilder(
                              animation: _shimmerAnimation,
                              builder: (context, child) {
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        colorScheme.primary,
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Disabled button skeleton for loading state (no shimmer)
class _DisabledButtonSkeleton extends StatelessWidget {
  final ColorScheme colorScheme;

  const _DisabledButtonSkeleton({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.download,
                    size: 20,
                    color: colorScheme.outline.withOpacity(0.5),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Save All',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.outline.withOpacity(0.5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.share,
                    size: 20,
                    color: colorScheme.outline.withOpacity(0.5),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Share',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.outline.withOpacity(0.5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Full-screen image viewer widget
class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onClose;
  final Future<void> Function(String) onSave;
  final Future<void> Function(String) onShare;

  const _FullScreenImageViewer({
    required this.imageUrl,
    required this.onClose,
    required this.onSave,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withOpacity(0.95),
        child: SafeArea(
          child: Stack(
            children: [
              // Full-screen image
              Center(
                child: Hero(
                  tag: imageUrl,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.white,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            size: 64,
                            color: Colors.white54,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load image',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // Close button
              Positioned(
                top: 20,
                right: 20,
                child: Material(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                  child: IconButton(
                    onPressed: onClose,
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),

              // Bottom action buttons
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Save button
                    GestureDetector(
                      onTap: () async {
                        await onSave(imageUrl);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.download,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Save',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Share button
                    GestureDetector(
                      onTap: () async {
                        await onShare(imageUrl);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.share,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Share',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Category option model
class CategoryOption {
  final String id;
  final String name;
  final IconData icon;

  CategoryOption({required this.id, required this.name, required this.icon});
}
