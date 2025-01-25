import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'id_login_page.dart';
import 'session_data.dart';
import 'homepage.dart';

// Theme constants and provider
class AppTheme {
  static const Color primaryColor = Color(0xFF1976D2);   // Professional blue
  static const Color accentColor = Color(0xFF03A9F4);    // Light blue
  static const Color successColor = Color(0xFF4CAF50);   // Green for positive status
  static const Color warningColor = Color(0xFFFFA726);   // Orange for warnings
  static const Color errorColor = Color(0xFFE53935);     // Red for errors
  static const Color surfaceColor = Color(0xFFF5F5F5);   // Light grey for backgrounds

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
      background: Colors.white,
      surface: surfaceColor,
      onBackground: Colors.black87,
      onSurface: Colors.black87,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    // Updated card theme for medical records
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
    ),
    // Updated button theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      // Primary colors - using medical blues that work well in dark mode
      primary: Color(0xFF2196F3),      // Slightly lighter blue for better visibility
      secondary: Color(0xFF03A9F4),    // Light blue accent
      tertiary: Color(0xFF4CAF50),     // Success green for status indicators

      // Background colors - using deeper blues for medical feel
      background: Color(0xFF121212),    // Darker background
      surface: Color(0xFF1E1E1E),      // Slightly lighter surface
      surfaceVariant: Color(0xFF262626),// Card and elevated surface color

      // Foreground colors - **Updated Colors Here for Consistency**
      onBackground: Color(0xFFE0E0E0),  // Lighter grey, same as onSurface now
      onSurface: Color(0xFFE0E0E0),    // Main text color - Lighter grey for better consistency
      onSurfaceVariant: Color(0xFFE0E0E0), // Secondary text color -  Lighter grey for consistency

      // Error and warning colors
      error: Color(0xFFCF6679),        // Muted red for errors
      // Border and outline colors
      outline: Color(0xFF404040),      // Subtle borders
      outlineVariant: Color(0xFF303030),// Secondary borders
    ),

    // Background color for the scaffold
    scaffoldBackgroundColor: const Color(0xFF121212),

    // AppBar theme
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Color(0xFFE0E0E0), // Updated to be consistent with text colors
      elevation: 2,
      shadowColor: Color(0xFF000000),
      centerTitle: true,
      titleTextStyle: const TextStyle( // Keep TextStyle as before, color will be inherited from foregroundColor
        fontSize: 20,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
      ),
    ),

    // Card theme
    cardTheme: CardTheme(
      color: const Color(0xFF1E1E1E),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Color(0xFF303030),
          width: 1,
        ),
      ),
    ),

    // Elevated button theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF262626),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Color(0xFF404040),
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Color(0xFF404040),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Color(0xFF2196F3),
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Color(0xFFCF6679),
          width: 1,
        ),
      ),
      labelStyle: const TextStyle(
        color: Color(0xFFB0B0B0),
        fontSize: 16,
      ),
      hintStyle: const TextStyle(
        color: Color(0xFF808080),
        fontSize: 16,
      ),
    ),

    // Text theme - Keep TextTheme as is, as these styles refer to specific semantic styles
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: Color(0xFFECECEC), // Slightly off-white - keep for headlines
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: Color(0xFFECECEC), // Slightly off-white - keep for headlines
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        color: Color(0xFFECECEC), // Slightly off-white - keep for titleLarge
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: Color(0xFFE0E0E0), // Lighter grey - Consistent with onSurface/onSurfaceVariant
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: TextStyle(
        color: Color(0xFFE0E0E0), // Lighter grey - Consistent with onSurface/onSurfaceVariant
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: Color(0xFFB0B0B0), // Medium grey - Keep bodyMedium slightly darker for hierarchy if needed
        fontSize: 14,
      ),
    ),

    // Icon theme
    iconTheme: const IconThemeData(
      color: Color(0xFF2196F3),
      size: 24,
    ),

    // Divider theme
    dividerTheme: const DividerThemeData(
      color: Color(0xFF404040),
      thickness: 1,
      space: 24,
    ),
  );
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode =
    _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  bool get isDarkMode => _themeMode == ThemeMode.dark;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Flutter Demo',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          debugShowCheckedModeBanner: false,
          initialRoute: '/',
          routes: {
            '/': (context) => const LoginPage(),
            '/id_login': (context) => const IDLoginPage(),
            '/home': (context) =>
            const MyHomePage(title: 'Flutter Demo Home Page'),
          },
        );
      },
    );
  }
}
