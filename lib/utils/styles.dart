import 'package:flutter/material.dart';
import 'package:delivery_now_app/utils/colors.dart';

class AppDecorations {
  static BoxDecoration containerDecoration({
    Color? color,
    double borderRadius = 16,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.cardColor,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: boxShadow ??
          [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
    );
  }

  static BoxDecoration containerWhiteDecoration({
    Color? color,
    double borderRadius = 16,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.surfaceColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: AppColors.borderColor,
        width: 1,
      ),
      boxShadow: boxShadow ??
          [
            BoxShadow(
              color: AppColors.lightShadowColor,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
    );
  }

  static BoxDecoration containerGoldGradientDecoration({
    double borderRadius = 16,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFB800), // Primary gold
          Color(0xFFF57F17), // Deeper gold
          Color(0xFFE65100), // Rich amber
        ],
        stops: [0.0, 0.5, 1.0],
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: boxShadow ??
          [
            BoxShadow(
              color: const Color(0xFFFFB800).withOpacity(0.3),
              spreadRadius: 0,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
    );
  }

  static BoxDecoration containerTealGradientDecoration({
    double borderRadius = 16,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF4DD0E1), // Light cyan
          Color(0xFF26A69A), // Teal
          Color(0xFF00695C), // Dark teal
        ],
        stops: [0.0, 0.5, 1.0],
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: boxShadow ??
          [
            BoxShadow(
              color: const Color(0xFF26A69A).withOpacity(0.3),
              spreadRadius: 0,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
    );
  }

  static BoxDecoration containerVioletGradientDecoration({
    double borderRadius = 16,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF9C27B0), // Purple
          Color(0xFF7B1FA2), // Deep purple
          Color(0xFF4A148C), // Very deep purple
        ],
        stops: [0.0, 0.5, 1.0],
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: boxShadow ??
          [
            BoxShadow(
              color: const Color(0xFF7B1FA2).withOpacity(0.3),
              spreadRadius: 0,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
    );
  }

  static BoxDecoration containerEmeraldGradientDecoration({
    double borderRadius = 16,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF00E676), // Bright green
          Color(0xFF00C853), // Emerald green
          Color(0xFF00A152), // Deep green
        ],
        stops: [0.0, 0.5, 1.0],
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: boxShadow ??
          [
            BoxShadow(
              color: const Color(0xFF00C853).withOpacity(0.3),
              spreadRadius: 0,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
    );
  }

  static BoxDecoration containerPinkGradientDecoration({
    double borderRadius = 16,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFF6B6B), // Coral pink
          Color(0xFFFF5722), // Deep orange
          Color(0xFFE64A19), // Darker orange
        ],
        stops: [0.0, 0.5, 1.0],
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: boxShadow ??
          [
            BoxShadow(
              color: const Color(0xFFFF5722).withOpacity(0.3),
              spreadRadius: 0,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
    );
  }

  static BoxDecoration containerProfessionalDarkDecoration({
    double borderRadius = 16,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF37474F), // Blue grey 800
          Color(0xFF263238), // Blue grey 900
          Color(0xFF1C1C1C), // Almost black
        ],
        stops: [0.0, 0.5, 1.0],
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: boxShadow ??
          [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              spreadRadius: 0,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 0,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
      border: Border.all(
        color: Colors.white.withOpacity(0.1),
        width: 1,
      ),
    );
  }

  static BoxDecoration containerProfessionalMediumDecoration({
    double borderRadius = 16,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF616161), // Grey 700
          Color(0xFF424242), // Grey 800
          Color(0xFF212121), // Grey 900
        ],
        stops: [0.0, 0.5, 1.0],
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: boxShadow ??
          [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 0,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              spreadRadius: 0,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
      border: Border.all(
        color: Colors.white.withOpacity(0.08),
        width: 1,
      ),
    );
  }

  static BoxDecoration containerMidnightDecoration({
    double borderRadius = 16,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF1E40AF), // Blue 800
          Color(0xFF1E3A8A), // Blue 900
          Color(0xFF0F172A), // Dark blue-slate
        ],
        stops: [0.0, 0.4, 1.0],
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: boxShadow ??
          [
            BoxShadow(
              color: const Color(0xFF1E3A8A).withOpacity(0.4),
              spreadRadius: 0,
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 0,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
      border: Border.all(
        color: const Color(0xFF3B82F6).withOpacity(0.2), // Blue 500
        width: 1,
      ),
    );
  }

// Modern Professional Decorations for Dark Purple Theme

  static BoxDecoration containerDeepPurpleGlassDecoration({
    double borderRadius = 16,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF4C3B72)
              .withOpacity(0.9), // Lighter purple with transparency
          Color(0xFF372C5A).withOpacity(0.95), // Your card color
          Color(0xFF2A1B47).withOpacity(0.98), // Your surface color
        ],
        stops: [0.0, 0.5, 1.0],
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Color(0xFF6B5B95).withOpacity(0.3), // Subtle border
        width: 1.5,
      ),
      boxShadow: boxShadow ??
          [
            BoxShadow(
              color: Color(0xFF1A0B2E).withOpacity(0.8),
              spreadRadius: 0,
              blurRadius: 32,
              offset: Offset(0, 16),
            ),
            BoxShadow(
              color: Color(0xFF6B5B95).withOpacity(0.2),
              spreadRadius: 0,
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
    );
  }

  static BoxDecoration containerLuxuryPurpleDecoration({
    double borderRadius = 20,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF6B46C1), // Rich purple
          Color(0xFF553C9A), // Medium purple
          Color(0xFF372C5A), // Your card color
          Color(0xFF2A1B47), // Your surface color
        ],
        stops: [0.0, 0.3, 0.7, 1.0],
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: boxShadow ??
          [
            BoxShadow(
              color: Color(0xFF6B46C1).withOpacity(0.4),
              spreadRadius: 0,
              blurRadius: 40,
              offset: Offset(0, 20),
            ),
            BoxShadow(
              color: Color(0xFF1A0B2E).withOpacity(0.6),
              spreadRadius: 2,
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
    );
  }

  static BoxDecoration containerNeonPurpleDecoration({
    double borderRadius = 16,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF8B5CF6), // Bright purple
          Color(0xFF7C3AED), // Vivid purple
          Color(0xFF5B21B6), // Deep purple
          Color(0xFF372C5A), // Your card color
        ],
        stops: [0.0, 0.4, 0.8, 1.0],
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Color(0xFF8B5CF6).withOpacity(0.5),
        width: 1,
      ),
      boxShadow: boxShadow ??
          [
            BoxShadow(
              color: Color(0xFF8B5CF6).withOpacity(0.6),
              spreadRadius: 0,
              blurRadius: 28,
              offset: Offset(0, 12),
            ),
            BoxShadow(
              color: Color(0xFF5B21B6).withOpacity(0.4),
              spreadRadius: 0,
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 0,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
    );
  }

static BoxDecoration containerDarkForestDecoration({
  double borderRadius = 16,
  List<BoxShadow>? boxShadow,
}) {
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF059669), // Emerald 600
        Color(0xFF047857), // Emerald 700
        Color(0xFF065F46), // Emerald 800
        Color(0xFF064E3B), // Emerald 900
        Color(0xFF022C22), // Emerald 950
      ],
      stops: [0.0, 0.25, 0.5, 0.75, 1.0],
    ),
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(
      color: Color(0xFF10B981).withOpacity(0.5),
      width: 1.5,
    ),
    boxShadow: boxShadow ??
        [
          BoxShadow(
            color: Color(0xFF059669).withOpacity(0.4),
            spreadRadius: 0,
            blurRadius: 32,
            offset: Offset(0, 16),
          ),
          BoxShadow(
            color: Color(0xFF022C22).withOpacity(0.8),
            spreadRadius: 2,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            spreadRadius: 0,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
  );
}

  static BoxDecoration containerDarkEleganceDecoration({
  double borderRadius = 16,
  List<BoxShadow>? boxShadow,
}) {
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF4B5563), // Gray 600
        Color(0xFF374151), // Gray 700
        Color(0xFF1F2937), // Gray 800
        Color(0xFF111827), // Gray 900
        Color(0xFF030712), // Gray 950
      ],
      stops: [0.0, 0.25, 0.5, 0.75, 1.0],
    ),
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(
      color: Color(0xFF6B7280).withOpacity(0.5),
      width: 1.5,
    ),
    boxShadow: boxShadow ??
        [
          BoxShadow(
            color: Color(0xFF000000).withOpacity(0.6),
            spreadRadius: 0,
            blurRadius: 32,
            offset: Offset(0, 16),
          ),
          BoxShadow(
            color: Color(0xFF111827).withOpacity(0.8),
            spreadRadius: 2,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 0,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
  );
}

  static BoxDecoration containerMidnightEleganceDecoration({
    double borderRadius = 18,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: RadialGradient(
        center: Alignment.topLeft,
        radius: 1.5,
        colors: [
          Color(0xFF4A3B6B), // Lighter accent
          Color(0xFF372C5A), // Your card color
          Color(0xFF2A1B47), // Your surface color
          Color(0xFF1A0B2E), // Your background color
        ],
        stops: [0.0, 0.3, 0.7, 1.0],
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Color(0xFF5A4A7A).withOpacity(0.6),
        width: 2,
      ),
      boxShadow: boxShadow ??
          [
            BoxShadow(
              color: Color(0xFF1A0B2E).withOpacity(0.9),
              spreadRadius: 4,
              blurRadius: 36,
              offset: Offset(0, 18),
            ),
            BoxShadow(
              color: Color(0xFF4A3B6B).withOpacity(0.3),
              spreadRadius: 0,
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
    );
  }

  static BoxDecoration containerCrimsonLuxuryDecoration({
    double borderRadius = 16,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFDC2626), // Red 600
          Color(0xFFB91C1C), // Red 700
          Color(0xFF991B1B), // Red 800
          Color(0xFF7F1D1D), // Red 900
          Color(0xFF450A0A), // Red 950
        ],
        stops: [0.0, 0.25, 0.5, 0.75, 1.0],
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Color(0xFFDC2626).withOpacity(0.6),
        width: 1.5,
      ),
      boxShadow: boxShadow ??
          [
            BoxShadow(
              color: Color(0xFFDC2626).withOpacity(0.5),
              spreadRadius: 0,
              blurRadius: 32,
              offset: Offset(0, 16),
            ),
            BoxShadow(
              color: Color(0xFF450A0A).withOpacity(0.8),
              spreadRadius: 2,
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              spreadRadius: 0,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
    );
  }

  static BoxDecoration containerRoyalPurpleDecoration({
    double borderRadius = 16,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment(-0.5, -1.0),
        end: Alignment(0.5, 1.0),
        colors: [
          Color(0xFF9333EA), // Purple 600
          Color(0xFF7E22CE), // Purple 700
          Color(0xFF6B21B6), // Purple 800
          Color(0xFF553C9A), // Custom purple
          Color(0xFF372C5A), // Your card color
        ],
        stops: [0.0, 0.25, 0.5, 0.75, 1.0],
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Color(0xFF9333EA).withOpacity(0.4),
        width: 1.5,
      ),
      boxShadow: boxShadow ??
          [
            BoxShadow(
              color: Color(0xFF9333EA).withOpacity(0.5),
              spreadRadius: 0,
              blurRadius: 32,
              offset: Offset(0, 16),
            ),
            BoxShadow(
              color: Color(0xFF1A0B2E).withOpacity(0.8),
              spreadRadius: 2,
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              spreadRadius: 0,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
    );
  }

  static BoxDecoration containerSoftPurpleMistDecoration({
    double borderRadius = 24,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF5A4A7A).withOpacity(0.8), // Soft purple mist
          Color(0xFF453B6B).withOpacity(0.9), // Your modal color
          Color(0xFF372C5A).withOpacity(0.95), // Your card color
          Color(0xFF2A1B47), // Your surface color
        ],
        stops: [0.0, 0.3, 0.7, 1.0],
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Color(0xFF6B5B95).withOpacity(0.4),
        width: 1,
      ),
      boxShadow: boxShadow ??
          [
            BoxShadow(
              color: Color(0xFF1A0B2E).withOpacity(0.6),
              spreadRadius: 8,
              blurRadius: 48,
              offset: Offset(0, 24),
            ),
            BoxShadow(
              color: Color(0xFF5A4A7A).withOpacity(0.3),
              spreadRadius: 0,
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 0,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
    );
  }

  // Special decoration for user type cards
  static BoxDecoration userTypeDecoration({
    required String userType,
    double borderRadius = 16,
    List<BoxShadow>? boxShadow,
  }) {
    Color baseColor;
    switch (userType.toLowerCase()) {
      case 'rider':
        baseColor = AppColors.riderColor;
        break;
      case 'staff':
        baseColor = AppColors.staffColor;
        break;
      case 'customer':
        baseColor = AppColors.customerColor;
        break;
      default:
        baseColor = AppColors.primaryColor;
    }

    return BoxDecoration(
      gradient: LinearGradient(
        colors: [baseColor, baseColor.withOpacity(0.8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: boxShadow ??
          [
            BoxShadow(
              color: baseColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
    );
  }

  // Card decoration with border
  static BoxDecoration cardDecorationWithBorder({
    Color? color,
    Color? borderColor,
    double borderRadius = 16,
    double borderWidth = 1,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.cardColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? AppColors.borderColor,
        width: borderWidth,
      ),
      boxShadow: boxShadow ??
          [
            BoxShadow(
              color: AppColors.lightShadowColor,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
    );
  }

  // Modal decoration
  static BoxDecoration modalDecoration({
    double borderRadius = 20,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      color: AppColors.modalColor,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(borderRadius),
        topRight: Radius.circular(borderRadius),
      ),
      border: Border.all(
        color: AppColors.borderColor,
        width: 1,
      ),
      boxShadow: boxShadow ??
          [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
    );
  }
}
