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
      gradient: AppColors.primaryGradient,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: boxShadow ??
          [
            BoxShadow(
              color: AppColors.primaryColor.withOpacity(0.3),
              blurRadius: 15,
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
      gradient: LinearGradient(
        colors: [AppColors.tealColor, AppColors.cyanColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: boxShadow ??
          [
            BoxShadow(
              color: AppColors.tealColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
    );
  }

  static BoxDecoration containerVioletGradientDecoration({
    double borderRadius = 16,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [AppColors.violetColor, AppColors.purpleColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: boxShadow ??
          [
            BoxShadow(
              color: AppColors.violetColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
    );
  }

  static BoxDecoration containerEmeraldGradientDecoration({
    double borderRadius = 16,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [AppColors.emeraldColor, AppColors.limeColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: boxShadow ??
          [
            BoxShadow(
              color: AppColors.emeraldColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
    );
  }

  static BoxDecoration containerPinkGradientDecoration({
    double borderRadius = 16,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [AppColors.pinkColor, AppColors.deepOrangeColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: boxShadow ??
          [
            BoxShadow(
              color: AppColors.pinkColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 3),
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