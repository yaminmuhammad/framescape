import 'dart:io';
import 'package:flutter/material.dart';
import 'package:framescape/bloc/image/image_bloc.dart';
import '../models/category_option.dart';

class EmptyStateScreen extends StatelessWidget {
  final VoidCallback onPickImage;
  final VoidCallback onGenerate;
  final VoidCallback onClearImage;
  final ImageState state;
  final List<CategoryOption> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const EmptyStateScreen({
    super.key,
    required this.onPickImage,
    required this.onGenerate,
    required this.onClearImage,
    required this.state,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode =
        Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = const Color(0xFF2BEE79);
    final Color backgroundColor =
        isDarkMode ? const Color(0xFF102217) : const Color(0xFFF6F8F7);
    final Color surfaceColor =
        isDarkMode ? const Color(0xFF152A1F) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF1E293B);
    final Color subtleTextColor =
        isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: backgroundColor.withOpacity(0.8),
                title: Text(
                  'AI Scene Gen',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: Icon(Icons.settings, color: textColor),
                    onPressed: () {},
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      Text(
                        'Transform your photos.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload a selfie to generate 10+ social media scenes instantly.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: subtleTextColor,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildUploadZone(
                          context, primaryColor, surfaceColor, textColor),
                      const SizedBox(height: 32),
                      _buildVibeSelector(context, primaryColor, surfaceColor,
                          textColor, subtleTextColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
          _buildFloatingGenerateButton(
              context, primaryColor, backgroundColor, state.hasImage),
        ],
      ),
    );
  }

  Widget _buildUploadZone(BuildContext context, Color primaryColor,
      Color surfaceColor, Color textColor) {
    return GestureDetector(
      onTap: state.hasImage ? null : onPickImage,
      child: Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: primaryColor.withOpacity(0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: state.hasImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      state.selectedImage!,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: onClearImage,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withOpacity(0.5),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withOpacity(0.1),
                    ),
                    child: Icon(Icons.add_a_photo,
                        color: primaryColor, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tap to Upload',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Supported formats: JPG, PNG',
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: onPickImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: textColor,
                      foregroundColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.black
                              : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Select Photo',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildVibeSelector(BuildContext context, Color primaryColor,
      Color surfaceColor, Color textColor, Color subtleTextColor) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Choose Vibe',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'See All',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: primaryColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: categories.map((vibe) {
              final isSelected = selectedCategory == vibe.id;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(vibe.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      onCategorySelected(vibe.id);
                    }
                  },
                  avatar: CircleAvatar(
                    backgroundColor: isSelected
                        ? Colors.black.withOpacity(0.1)
                        : (Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey.shade100),
                    child:
                        Icon(vibe.icon, size: 18, color: isSelected ? Colors.black : textColor),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(
                      color: isSelected
                          ? primaryColor
                          : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade800
                              : Colors.grey.shade300),
                    ),
                  ),
                  backgroundColor: surfaceColor,
                  selectedColor: primaryColor,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.black : textColor,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingGenerateButton(
      BuildContext context, Color primaryColor, Color backgroundColor, bool isEnabled) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              backgroundColor.withOpacity(0),
              backgroundColor,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ElevatedButton.icon(
          onPressed: isEnabled ? onGenerate : null,
          icon: const Icon(Icons.auto_awesome, color: Colors.black),
          label: const Text(
            'Generate Scenes',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            shadowColor: primaryColor.withOpacity(0.5),
            elevation: 8,
          ),
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path();
    const dashWidth = 10.0;
    const dashSpace = 5.0;
    double startX = 0;
    while (startX < size.width) {
      path.moveTo(startX, 0);
      path.lineTo(startX + dashWidth, 0);
      startX += dashWidth + dashSpace;
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
