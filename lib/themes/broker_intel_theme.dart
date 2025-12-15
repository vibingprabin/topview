import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Broker Intelligence Theme
/// 
/// A professional, high-contrast theme for financial applications.
/// Inspired by Bloomberg Terminal aesthetics with modern polish.
/// 
/// Core intensity gradient:
/// - High: Dark Navy (#2B2D42) - for high values, emphasis, headers
/// - Mid: Rich Blue (#118AB2) - medium values, primary actions
/// - Low: Pale Blue (#A8DADC) - low values, backgrounds, subtle elements
class BrokerIntelTheme {
  // Core Intensity Gradient
  static const Color highIntensity = Color(0xFF2B2D42);
  static const Color midIntensity = Color(0xFF118AB2);
  static const Color lowIntensity = Color(0xFFA8DADC);

  // Accent Colors
  static const Color titlePink = Color(0xFFEF476F);
  static const Color successGreen = Color(0xFF06D6A0);
  static const Color warningOrange = Color(0xFFFFA500);
  static const Color dangerRed = Color(0xFFFF6B6B);
  static const Color neutralGray = Color(0xFF95A5A6);

  // UI Foundation - Light Mode
  static const Color bgWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2B2D42);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textCaption = Color(0xFFAAAAAA);
  static const Color gridLight = Color(0xFFF0F0F0);
  static const Color borderLight = Color(0xFFE0E0E0);

  // UI Foundation - Dark Mode
  static const Color darkBgPrimary = Color(0xFF1A1D2E);
  static const Color darkBgSecondary = Color(0xFF2B2D42);
  static const Color darkSurface = Color(0xFF353749);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFA8DADC);
  static const Color darkGrid = Color(0xFF353749);

  // Profit/Loss Colors
  static Color get profitColor => successGreen;
  static Color get lossColor => dangerRed;
  static Color get neutralColor => neutralGray;

  /// Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: midIntensity,
      scaffoldBackgroundColor: bgWhite,
      colorScheme: const ColorScheme.light(
        primary: midIntensity,
        secondary: titlePink,
        surface: bgWhite,
        background: bgWhite,
        error: dangerRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onBackground: textPrimary,
        onError: Colors.white,
      ),
      textTheme: _buildLightTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: highIntensity,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardTheme(
        color: bgWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderLight, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: midIntensity,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: midIntensity,
          side: const BorderSide(color: midIntensity, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: midIntensity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: midIntensity, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: dangerRed, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: textCaption,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgWhite,
        selectedItemColor: midIntensity,
        unselectedItemColor: textCaption,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      dividerTheme: const DividerThemeData(
        color: borderLight,
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: lowIntensity,
      scaffoldBackgroundColor: darkBgPrimary,
      colorScheme: const ColorScheme.dark(
        primary: lowIntensity,
        secondary: titlePink,
        surface: darkSurface,
        background: darkBgPrimary,
        error: dangerRed,
        onPrimary: highIntensity,
        onSecondary: Colors.white,
        onSurface: darkTextPrimary,
        onBackground: darkTextPrimary,
        onError: Colors.white,
      ),
      textTheme: _buildDarkTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBgSecondary,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardTheme(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: darkGrid, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lowIntensity,
          foregroundColor: highIntensity,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lowIntensity,
          side: const BorderSide(color: lowIntensity, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lowIntensity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkGrid),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkGrid),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lowIntensity, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: dangerRed, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: darkTextSecondary,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkBgSecondary,
        selectedItemColor: lowIntensity,
        unselectedItemColor: darkTextSecondary,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      dividerTheme: const DividerThemeData(
        color: darkGrid,
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Build light mode text theme
  static TextTheme _buildLightTextTheme() {
    final baseTextTheme = GoogleFonts.interTextTheme();
    
    return baseTextTheme.copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: -0.3,
        height: 1.3,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: -0.2,
        height: 1.3,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: -0.2,
        height: 1.4,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: -0.1,
        height: 1.4,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        height: 1.4,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        height: 1.4,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        height: 1.4,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: textSecondary,
        height: 1.4,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: textPrimary,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: textCaption,
        height: 1.5,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0.3,
        height: 1.4,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textSecondary,
        letterSpacing: 0.3,
        height: 1.4,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: textCaption,
        letterSpacing: 0.4,
        height: 1.4,
      ),
    );
  }

  /// Build dark mode text theme
  static TextTheme _buildDarkTextTheme() {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
    
    return baseTextTheme.copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: darkTextPrimary,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: darkTextPrimary,
        letterSpacing: -0.3,
        height: 1.3,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: darkTextPrimary,
        letterSpacing: -0.2,
        height: 1.3,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: darkTextPrimary,
        letterSpacing: -0.2,
        height: 1.4,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: darkTextPrimary,
        letterSpacing: -0.1,
        height: 1.4,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: darkTextPrimary,
        height: 1.4,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: darkTextPrimary,
        height: 1.4,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: darkTextPrimary,
        height: 1.4,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: darkTextSecondary,
        height: 1.4,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: darkTextPrimary,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: darkTextSecondary,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: darkTextSecondary,
        height: 1.5,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: darkTextPrimary,
        letterSpacing: 0.3,
        height: 1.4,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: darkTextSecondary,
        letterSpacing: 0.3,
        height: 1.4,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: darkTextSecondary,
        letterSpacing: 0.4,
        height: 1.4,
      ),
    );
  }

  /// Get profit/loss color based on value
  static Color getValueColor(double value, {bool isDark = false}) {
    if (value > 0) return profitColor;
    if (value < 0) return lossColor;
    return isDark ? darkTextSecondary : textCaption;
  }

  /// Get profit/loss color with background brightness awareness
  static Color getProfitColor(bool isDark) => profitColor;
  static Color getLossColor(bool isDark) => lossColor;
  static Color getNeutralColor(bool isDark) => 
      isDark ? darkTextSecondary : textCaption;

  /// Gradient for ferrofluid animation
  static LinearGradient get ferrofluidGradient => const LinearGradient(
    colors: [midIntensity, titlePink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Intensity-based gradient for data visualization
  static LinearGradient get intensityGradient => const LinearGradient(
    colors: [highIntensity, midIntensity, lowIntensity],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Success/error gradient
  static LinearGradient get performanceGradient => const LinearGradient(
    colors: [successGreen, warningOrange, dangerRed],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

/// Extension for easy theme access
extension BrokerIntelThemeExtension on BuildContext {
  /// Get the Broker Intel theme colors
  BrokerIntelThemeColors get biColors {
    final brightness = Theme.of(this).brightness;
    return BrokerIntelThemeColors(brightness == Brightness.dark);
  }
}

/// Helper class for theme-aware color access
class BrokerIntelThemeColors {
  final bool isDark;

  const BrokerIntelThemeColors(this.isDark);

  Color get highIntensity => BrokerIntelTheme.highIntensity;
  Color get midIntensity => BrokerIntelTheme.midIntensity;
  Color get lowIntensity => BrokerIntelTheme.lowIntensity;
  Color get titlePink => BrokerIntelTheme.titlePink;
  Color get successGreen => BrokerIntelTheme.successGreen;
  Color get warningOrange => BrokerIntelTheme.warningOrange;
  Color get dangerRed => BrokerIntelTheme.dangerRed;
  Color get neutralGray => BrokerIntelTheme.neutralGray;

  Color get background => isDark 
      ? BrokerIntelTheme.darkBgPrimary 
      : BrokerIntelTheme.bgWhite;
  Color get surface => isDark 
      ? BrokerIntelTheme.darkSurface 
      : BrokerIntelTheme.bgWhite;
  Color get textPrimary => isDark 
      ? BrokerIntelTheme.darkTextPrimary 
      : BrokerIntelTheme.textPrimary;
  Color get textSecondary => isDark 
      ? BrokerIntelTheme.darkTextSecondary 
      : BrokerIntelTheme.textSecondary;
  Color get textCaption => isDark 
      ? BrokerIntelTheme.darkTextSecondary 
      : BrokerIntelTheme.textCaption;
  Color get grid => isDark 
      ? BrokerIntelTheme.darkGrid 
      : BrokerIntelTheme.gridLight;
  Color get border => isDark 
      ? BrokerIntelTheme.darkGrid 
      : BrokerIntelTheme.borderLight;

  Color get profit => BrokerIntelTheme.profitColor;
  Color get loss => BrokerIntelTheme.lossColor;
  Color get neutral => isDark 
      ? BrokerIntelTheme.darkTextSecondary 
      : BrokerIntelTheme.neutralGray;

  Color getValueColor(double value) => BrokerIntelTheme.getValueColor(value, isDark: isDark);
}
