import 'package:flutter/material.dart';

class ErrorScreen extends StatelessWidget {
  final VoidCallback onRetry;

  const ErrorScreen({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode =
        Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = const Color(0xFF2BEE79);
    final Color errorColor =
        isDarkMode ? const Color(0xFFF77272) : Colors.red.shade400;
    final Color backgroundColor =
        isDarkMode ? const Color(0xFF102217) : const Color(0xFFF6F8F7);
    final Color surfaceColor =
        isDarkMode ? const Color(0xFF152A1F) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF1E293B);

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
                        'Generation Failed',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "We couldn't create your scene. Please give it another try.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildErrorContent(
                          context, errorColor, surfaceColor, textColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
          _buildFloatingRetryButton(context, primaryColor, backgroundColor),
        ],
      ),
    );
  }

  Widget _buildErrorContent(BuildContext context, Color errorColor,
      Color surfaceColor, Color textColor) {
    final bool isDarkMode =
        Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode
              ? Colors.red.shade900.withOpacity(0.3)
              : Colors.grey.shade200,
        ),
        image: DecorationImage(
          image: RadialGradient(
            colors: [
              errorColor.withOpacity(isDarkMode ? 0.05 : 0.1),
              Colors.transparent,
            ],
            stops: const [0, 0.7],
          ).createShader(Rect.fromCircle(
              center: const Offset(150, 150), radius: 150)),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: errorColor.withOpacity(0.1),
              border: Border.all(
                color: errorColor.withOpacity(0.2),
                width: 8,
              ),
            ),
            child: Icon(Icons.error_outline, color: errorColor, size: 40),
          ),
          const SizedBox(height: 24),
          Text(
            'Something went wrong',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Our AI encountered a temporary glitch. Please check your connection and retry.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).hintColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text('Retry Generation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white,
              foregroundColor: textColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: BorderSide(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.shade300,
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingRetryButton(
      BuildContext context, Color primaryColor, Color backgroundColor) {
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
          onPressed: onRetry,
          icon: const Icon(Icons.replay, color: Colors.black),
          label: const Text(
            'Try Again',
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
