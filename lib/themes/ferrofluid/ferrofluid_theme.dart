import 'package:flutter/material.dart';
import '../broker_intel_theme.dart';

class FerrofluidTheme {
  static const Duration ambientAnimationDuration = Duration(seconds: 20);
  static const Duration interactionAnimationDuration = Duration(milliseconds: 300);
  static const Duration shimmerDuration = Duration(milliseconds: 2000);
  
  static const double subtleGrain = 0.08;
  static const double mediumGrain = 0.15;
  static const double meshAmplitude = 12.0;
  static const double meshFrequency = 3.0;
  static const double meshSpeed = 0.25;

  static const List<Color> meshGradientColors = [
    Color(0xFF1A1D2E),
    Color(0xFF2B2D42),
    Color(0xFF118AB2),
    Color(0xFF3D5A80),
  ];

  static const List<Color> meshGradientColorsAccent = [
    Color(0xFF2B2D42),
    Color(0xFF118AB2),
    Color(0xFF3D5A80),
    Color(0xFFEF476F),
  ];

  static List<Color> profitMeshColors = const [
    Color(0xFF1A1D2E),
    Color(0xFF06D6A0),
    Color(0xFF118AB2),
    Color(0xFF2B2D42),
  ];

  static List<Color> lossMeshColors = const [
    Color(0xFF1A1D2E),
    Color(0xFFEF476F),
    Color(0xFF2B2D42),
    Color(0xFF3D5A80),
  ];

  static List<Color> getMeshColorsForValue(double value) {
    if (value > 0) return profitMeshColors;
    if (value < 0) return lossMeshColors;
    return meshGradientColors;
  }

  static Color getShimmerBaseColor(double value, {bool isDark = true}) {
    final baseColor = isDark 
        ? BrokerIntelTheme.darkSurface 
        : BrokerIntelTheme.bgWhite;
    
    if (value > 0) {
      return Color.lerp(baseColor, BrokerIntelTheme.successGreen, 0.05)!;
    } else if (value < 0) {
      return Color.lerp(baseColor, BrokerIntelTheme.dangerRed, 0.05)!;
    }
    return baseColor;
  }

  static Color getShimmerHighlightColor(double value, {bool isDark = true}) {
    if (value > 0) {
      return BrokerIntelTheme.successGreen.withOpacity(0.3);
    } else if (value < 0) {
      return BrokerIntelTheme.dangerRed.withOpacity(0.3);
    }
    return isDark 
        ? BrokerIntelTheme.lowIntensity.withOpacity(0.2)
        : BrokerIntelTheme.midIntensity.withOpacity(0.15);
  }

  static LinearGradient cardGradient({bool isDark = true}) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              BrokerIntelTheme.darkSurface,
              BrokerIntelTheme.darkSurface.withOpacity(0.95),
            ]
          : [
              BrokerIntelTheme.bgWhite,
              BrokerIntelTheme.bgWhite.withOpacity(0.98),
            ],
    );
  }

  static LinearGradient headerGradient({bool isDark = true}) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        BrokerIntelTheme.highIntensity,
        BrokerIntelTheme.highIntensity.withOpacity(0.95),
        isDark ? BrokerIntelTheme.darkBgPrimary : BrokerIntelTheme.bgWhite,
      ],
      stops: const [0.0, 0.7, 1.0],
    );
  }

  static BoxDecoration glowDecoration({
    required Color glowColor,
    double intensity = 0.3,
    double blur = 20,
    double spread = 0,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: glowColor.withOpacity(intensity),
          blurRadius: blur,
          spreadRadius: spread,
        ),
      ],
    );
  }

  static LinearGradient borderGradient({double? animationValue}) {
    final rotation = (animationValue ?? 0) * 2 * 3.14159;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: const [
        BrokerIntelTheme.midIntensity,
        BrokerIntelTheme.titlePink,
        BrokerIntelTheme.lowIntensity,
        BrokerIntelTheme.midIntensity,
      ],
      stops: const [0.0, 0.33, 0.66, 1.0],
      transform: GradientRotation(rotation),
    );
  }
}
