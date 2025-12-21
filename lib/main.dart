import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'bloc/auth/auth_bloc.dart';
import 'bloc/image/image_bloc.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const PhotoAIApp());
}

class PhotoAIApp extends StatelessWidget {
  const PhotoAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc()..add(AuthSignInAnonymously())),
        BlocProvider(create: (_) => ImageBloc()),
      ],
      child: MaterialApp(
        title: 'Photo AI',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final baseColor = const Color(0xFF2bee79); // Primary logic from design

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: baseColor,
            brightness: brightness,
            primary: baseColor,
            surface: isDark ? const Color(0xFF152a1f) : const Color(0xFFffffff),

            // Custom background colors from design
            surfaceContainerHighest: isDark
                ? const Color(0xFF152a1f)
                : const Color(0xFFf6f8f7),
          ).copyWith(
            surface: isDark ? const Color(0xFF152a1f) : const Color(0xFFffffff),
            shadow: isDark
                ? Colors.black.withOpacity(0.5)
                : Colors.grey.withOpacity(0.1),
          ),
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF102217)
          : const Color(0xFFf6f8f7),
      fontFamily: GoogleFonts.beVietnamPro().fontFamily,
      textTheme: GoogleFonts.beVietnamProTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ),
    );
  }
}
