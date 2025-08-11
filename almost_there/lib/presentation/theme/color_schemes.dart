import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color terracotta = Color(0xFFC8664F);
  static const Color sage = Color(0xFF6F8E6B);
  static const Color river = Color(0xFF4C768D);
  
  // Background Colors
  static const Color sand = Color(0xFFF6F1E6);
  static const Color parchment = Color(0xFFFFF9F0);
  static const Color mapPaper = Color(0xFFEFE6D7);
  
  // Neutral Colors
  static const Color outline = Color(0xFFBDAA95);
  
  // System Colors
  static const Color error = Color(0xFFB3261E);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
}

// Light Theme Color Scheme
const ColorScheme lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: AppColors.terracotta,
  onPrimary: AppColors.white,
  secondary: AppColors.sage,
  onSecondary: Color(0xFF0D1A10),
  tertiary: AppColors.river,
  onTertiary: AppColors.white,
  error: AppColors.error,
  onError: AppColors.white,
  surface: AppColors.parchment,
  onSurface: Color(0xFF1C1B1F),
  surfaceContainerHighest: AppColors.mapPaper,
  outline: AppColors.outline,
  background: AppColors.sand,
  onBackground: Color(0xFF1C1B1F),
);

// Dark Theme Color Scheme
const ColorScheme darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFE08D7C), // Lighter terracotta for dark mode
  onPrimary: Color(0xFF2D0F0A),
  secondary: Color(0xFF8FB28A), // Lighter sage for dark mode
  onSecondary: Color(0xFF112016),
  tertiary: Color(0xFF7BA3C2), // Lighter river for dark mode
  onTertiary: Color(0xFF0F2433),
  error: Color(0xFFFFB4AB),
  onError: Color(0xFF690005),
  surface: Color(0xFF201C17),
  onSurface: Color(0xFFE6E1E5),
  surfaceContainerHighest: Color(0xFF2A241D),
  outline: Color(0xFF8C7A66),
  background: Color(0xFF191612),
  onBackground: Color(0xFFE6E1E5),
);

// Extended color palette for specific use cases
class AppColorExtension extends ThemeExtension<AppColorExtension> {
  final Color geofenceStroke;
  final Color geofenceFill;
  final Color distanceText;
  final Color cardBackground;
  final Color divider;
  final Color success;
  final Color warning;
  
  const AppColorExtension({
    required this.geofenceStroke,
    required this.geofenceFill,
    required this.distanceText,
    required this.cardBackground,
    required this.divider,
    required this.success,
    required this.warning,
  });

  @override
  AppColorExtension copyWith({
    Color? geofenceStroke,
    Color? geofenceFill,
    Color? distanceText,
    Color? cardBackground,
    Color? divider,
    Color? success,
    Color? warning,
  }) {
    return AppColorExtension(
      geofenceStroke: geofenceStroke ?? this.geofenceStroke,
      geofenceFill: geofenceFill ?? this.geofenceFill,
      distanceText: distanceText ?? this.distanceText,
      cardBackground: cardBackground ?? this.cardBackground,
      divider: divider ?? this.divider,
      success: success ?? this.success,
      warning: warning ?? this.warning,
    );
  }

  @override
  AppColorExtension lerp(ThemeExtension<AppColorExtension>? other, double t) {
    if (other is! AppColorExtension) {
      return this;
    }
    return AppColorExtension(
      geofenceStroke: Color.lerp(geofenceStroke, other.geofenceStroke, t) ?? geofenceStroke,
      geofenceFill: Color.lerp(geofenceFill, other.geofenceFill, t) ?? geofenceFill,
      distanceText: Color.lerp(distanceText, other.distanceText, t) ?? distanceText,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t) ?? cardBackground,
      divider: Color.lerp(divider, other.divider, t) ?? divider,
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
    );
  }
}

// Light theme extension
const AppColorExtension lightColorExtension = AppColorExtension(
  geofenceStroke: AppColors.sage,
  geofenceFill: Color(0x7A6F8E6B), // 48% opacity sage
  distanceText: AppColors.river,
  cardBackground: AppColors.parchment,
  divider: AppColors.outline,
  success: Color(0xFF4CAF50),
  warning: Color(0xFFFF9800),
);

// Dark theme extension
const AppColorExtension darkColorExtension = AppColorExtension(
  geofenceStroke: Color(0xFF8FB28A),
  geofenceFill: Color(0x7A8FB28A), // 48% opacity lighter sage
  distanceText: Color(0xFF7BA3C2),
  cardBackground: Color(0xFF201C17),
  divider: Color(0xFF8C7A66),
  success: Color(0xFF81C784),
  warning: Color(0xFFFFB74D),
);