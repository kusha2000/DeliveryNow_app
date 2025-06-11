import 'package:flutter/material.dart';

final class AppColors {
  // Primary Colors - Beautiful Gold/Amber Theme
  static const Color primaryColor = Color(0xFFFFB800);
  static const Color primaryDarkColor = Color(0xFFE6A500);
  static const Color primaryLightColor = Color(0xFFFFCA28);
  static const Color accentColor = Color(0xFF64FFDA);
  static const Color orangeColor = Colors.orange;
  static const Color redColor = Colors.red;
  static const Color brownColor = Colors.brown;
  static const Color purpleColor = Colors.purple;
  static const Color greenColor = Colors.green;
  static const Color greyColor = Colors.grey;
  static const Color amberColor = Colors.amber;

  // Background Colors - Dark Purple Theme
  static const Color backgroundColor = Color(0xFF1A0B2E);
  static const Color surfaceColor = Color(0xFF2A1B47);
  static const Color cardColor = Color(0xFF372C5A);
  static const Color modalColor = Color(0xFF453B6B);

  // Text Colors
  static const Color textPrimaryColor = Color(0xFFF8F4FF);
  static const Color textSecondaryColor = Color(0xFFB8A9D9);
  static const Color textMutedColor = Color(0xFF8B7AA8);

  // Border Colors
  static const Color borderColor = Color(0xFF4A3F6B);
  static const Color borderLightColor = Color(0xFF372C5A);
  static const Color dividerColor = Color(0xFF372C5A);

  // Status Colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFFF5722);
  static const Color infoColor = Color(0xFF2196F3);

  // Utility Colors
  static const Color whiteColor = Colors.white;
  static const Color blackColor = Colors.black;
  static const Color transparentColor = Colors.transparent;

  // Grey Scale for Dark Purple Theme
  static const Color grey50 = Color(0xFFF9F7FF);
  static const Color grey100 = Color(0xFFE8E1F5);
  static const Color grey200 = Color(0xFFD6CCEB);
  static const Color grey300 = Color(0xFFBFB0D9);
  static const Color grey400 = Color(0xFFB8A9D9);
  static const Color grey500 = Color(0xFF9A8BC4);
  static const Color grey600 = Color(0xFF8B7AA8);
  static const Color grey700 = Color(0xFF6D5B87);
  static const Color grey800 = Color(0xFF4A3F6B);
  static const Color grey900 = Color(0xFF2A1B47);

  // NEW: Additional Beautiful Colors for Cards
  static const Color tealColor = Color(0xFF26A69A); // Beautiful Teal
  static const Color indigoColor = Color(0xFF3F51B5); // Deep Indigo
  static const Color pinkColor = Color(0xFFE91E63); // Vibrant Pink
  static const Color cyanColor = Color(0xFF00BCD4); // Bright Cyan
  static const Color limeColor = Color(0xFF8BC34A); // Fresh Lime
  static const Color deepOrangeColor = Color(0xFFFF5722); // Deep Orange
  static const Color blueGreyColor = Color(0xFF607D8B); // Blue Grey
  static const Color emeraldColor = Color(0xFF00C853); // Emerald Green
  static const Color violetColor = Color(0xFF7C4DFF);

  // Shadow Colors
  static Color shadowColor = Colors.black.withOpacity(0.35);
  static Color lightShadowColor = Colors.black.withOpacity(0.15);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, primaryDarkColor],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundColor, surfaceColor],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cardColor, surfaceColor],
  );

  // User Type Colors - Beautiful Distinct Colors
  static const Color riderColor =
      Color(0xFF1565C0); // Deep Blue (complements gold)
  static const Color staffColor =
      Color(0xFF2E7D32); // Forest Green (harmonious with gold)
  static const Color customerColor =
      Color(0xFF6A1B9A); // Royal Purple (rich contrast)
}
