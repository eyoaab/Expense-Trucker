import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color _primaryLightColor = Color(0xFF4A6572);
  static const Color _primaryDarkColor = Color(0xFF1E1E1E);
  static const Color _accentColor = Color(0xFFF9AA33);

  static const Color _lightBackgroundColor = Color(0xFFF5F5F5);
  static const Color _darkBackgroundColor = Color(0xFF121212);

  static const Color _lightTextColor = Color(0xFF232F34);
  static const Color _darkTextColor = Color(0xFFF5F5F5);

  static const Color _errorColor = Color(0xFFD32F2F);
  static const Color _successColor = Color(0xFF388E3C);
  static const Color _warningColor = Color(0xFFFFA000);
  static const Color _infoColor = Color(0xFF1976D2);

  // Category colors
  static const Color foodColor = Color(0xFFF44336); // Red
  static const Color transportColor = Color(0xFF2196F3); // Blue
  static const Color shoppingColor = Color(0xFF9C27B0); // Purple
  static const Color housingColor = Color(0xFF4CAF50); // Green
  static const Color entertainmentColor = Color(0xFFFF9800); // Orange
  static const Color healthcareColor = Color(0xFF009688); // Teal
  static const Color educationColor = Color(0xFF3F51B5); // Indigo
  static const Color travelColor = Color(0xFF795548); // Brown
  static const Color utilitiesColor = Color(0xFF607D8B); // Blue Grey
  static const Color otherColor = Color(0xFF9E9E9E); // Grey

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: _primaryLightColor,
        secondary: _accentColor,
        surface: _lightBackgroundColor,
        error: _errorColor,
        onPrimary: Colors.white,
        onSecondary: _lightTextColor,
        onSurface: _lightTextColor,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: _lightBackgroundColor,
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData.light().textTheme,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
      cardTheme: const CardTheme(
        color: Colors.white,
        elevation: 2,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentColor,
          foregroundColor: _lightTextColor,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryLightColor,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryLightColor.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryLightColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryLightColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: _accentColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: _primaryDarkColor,
        secondary: _accentColor,
        surface: _darkBackgroundColor,
        error: _errorColor,
        onPrimary: Colors.white,
        onSecondary: _darkTextColor,
        onSurface: _darkTextColor,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: _darkBackgroundColor,
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData.dark().textTheme,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.grey,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
      cardTheme: const CardTheme(
        color: Color(0xFF1E1E1E),
        elevation: 2,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentColor,
          foregroundColor: _darkTextColor,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _accentColor,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _accentColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        selectedItemColor: _accentColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  // Helper methods to get colors
  static Color getSuccessColor(BuildContext context) => _successColor;
  static Color getErrorColor(BuildContext context) => _errorColor;
  static Color getWarningColor(BuildContext context) => _warningColor;
  static Color getInfoColor(BuildContext context) => _infoColor;

  // Category color mapping
  static Map<String, Color> categoryColors = {
    'Food': foodColor,
    'Transport': transportColor,
    'Shopping': shoppingColor,
    'Housing': housingColor,
    'Entertainment': entertainmentColor,
    'Healthcare': healthcareColor,
    'Education': educationColor,
    'Travel': travelColor,
    'Utilities': utilitiesColor,
    'Other': otherColor,
  };

  static Color getCategoryColor(String category) {
    return categoryColors[category] ?? otherColor;
  }
}
