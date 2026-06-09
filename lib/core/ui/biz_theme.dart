// lib/core/ui/biz_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BizTheme {
  // Spacing System (4px base)
  static const double spacingBase = 4;
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;
  static const double spacing2xl = 48;
  static const double spacing3xl = 64;

  // Border Radius
  static const double radiusSm = 4;
  static const double radiusMd = 8;
  static const double radiusLg = 12;
  static const double radiusXl = 16;
  static const double radius2xl = 28;
  static const double inputRadius = 10;
  
  // Elevation
  static const double elevation = 1;
  
  // Legacy padding constant
  static const double pad = 16;

  // 1. COLOR SYSTEM - SLOVENSKÁ VLAJKA THEME (LIGHT)
  // Primary
  static const Color slovakBlue = Color(0xFF0B4EA2); // Primary Blue
  static const Color nationalRed = Color(0xFFEE1C25); // Primary Red
  static const Color tatraWhite = Color(0xFFFFFFFF); // Primary White
  
  // Secondary
  static const Color blueDark = Color(0xFF083A7A); // Secondary Blue Dark
  static const Color blueLight = Color(0xFF4A90E2); // Secondary Blue Light
  static const Color accentRed = Color(0xFFC41E3A); // Accent Red (CTA)
  static const Color accentRedLight = Color(0xFFFFE5E8); // Accent Red Light
  
  // Supporting
  static const Color successGreen = Color(0xFF52B788);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color errorRed = nationalRed;
  
  // Legacy color aliases for backward compatibility
  static const Color richCrimson = nationalRed;
  static const Color fusionAzure = blueLight;
  static const Color silverMist = gray100;
  static const Color slate = gray700;
  
  // Gray Scale
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  // 2. DARK MODE COLOR SYSTEM
  // Surface
  static const Color darkSurface = Color(0xFF121212);
  static const Color darkSurfaceVariant = Color(0xFF1E1E1E); // Cards/Elevated
  static const Color darkSurfaceContainerLow = Color(0xFF1A1A1A);
  static const Color darkOutline = Color(0xFF3D3D3D);
  static const Color darkOutlineVariant = Color(0xFF2C2C2C);
  
  // Brand Dark Variants
  static const Color darkPrimaryBlue = Color(0xFF5AA3F0); // Lighter blue for visibility
  static const Color darkPrimaryContainer = Color(0xFF0D3A6B); // Darker blue bg
  static const Color darkSecondaryRed = Color(0xFFFF6B6B); // Lighter red
  static const Color darkSecondaryContainer = Color(0xFF8B0A14); // Darker red bg
  
  // Text Dark
  static const Color darkOnSurface = Color(0xFFE8E8E8); // High emphasis
  static const Color darkOnSurfaceVariant = Color(0xFFC4C4C4); // Medium emphasis
  static const Color darkDisabled = Color(0xFF6B6B6B);


  static ThemeData light() {
    final colorScheme = ColorScheme.light(
      primary: slovakBlue,
      onPrimary: Colors.white,
      primaryContainer: slovakBlue.withValues(alpha: 0.08),
      onPrimaryContainer: blueDark,
      secondary: nationalRed,
      onSecondary: Colors.white,
      secondaryContainer: nationalRed.withValues(alpha: 0.08),
      onSecondaryContainer: accentRed,
      surface: tatraWhite,
      onSurface: gray900,
      surfaceContainerHighest: gray50, 
      outline: gray200, // Thinner, lighter outlines
      outlineVariant: gray100,
      error: errorRed,
      onError: Colors.white,
    );

    return _buildTheme(colorScheme);
  }

  static ThemeData dark() {
    final colorScheme = const ColorScheme.dark(
      primary: darkPrimaryBlue,
      onPrimary: Color(0xFF001D3D), // high contrast on light blue
      primaryContainer: darkPrimaryContainer,
      onPrimaryContainer: Color(0xFFD6E4FF),
      
      secondary: darkSecondaryRed,
      onSecondary: Color(0xFF3D0000),
      secondaryContainer: darkSecondaryContainer,
      onSecondaryContainer: Color(0xFFFFDAD9),
      
      surface: darkSurface,
      onSurface: darkOnSurface,
      surfaceContainerHighest: darkSurfaceVariant,
      outline: darkOutline,
      outlineVariant: darkOutlineVariant,
      
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
    );

    return _buildTheme(colorScheme);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    
    final baseTextColor = isDark ? darkOnSurface : gray900;
    final secondaryTextColor = isDark ? darkOnSurfaceVariant : gray600;
    final disabledTextColor = isDark ? darkDisabled : gray500;

    // Use Material 3 baseline typography, then apply Inter consistently.
    final materialTextTheme = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: colorScheme.brightness,
    ).textTheme;

    final interTextTheme = GoogleFonts.interTextTheme(materialTextTheme).apply(
      bodyColor: baseTextColor,
      displayColor: baseTextColor,
    );

    final textTheme = interTextTheme.copyWith(
      bodyMedium: interTextTheme.bodyMedium?.copyWith(color: secondaryTextColor),
      bodySmall: interTextTheme.bodySmall?.copyWith(color: disabledTextColor),
      labelSmall: interTextTheme.labelSmall?.copyWith(color: disabledTextColor),
    );
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? darkSurface : Colors.white,
      
      // Typography (Inter) – use Material 3 baseline sizes for readability.
      textTheme: textTheme,

      // AppBar s liquid glass efektom pre sticky state
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent, // Transparent pre glass efekt
        foregroundColor: isDark ? darkOnSurface : slovakBlue,
        elevation: 0,
        scrolledUnderElevation: 4, // Zvýšená elevation keď je sticky
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: isDark ? darkOnSurface : slovakBlue,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: isDark ? darkOnSurface : slovakBlue),
        // Shape sa nastaví cez flexibleSpace v custom AppBar
      ),

      // Card Decoration — premium form sections
      cardTheme: CardThemeData(
        color: isDark ? darkSurfaceVariant : tatraWhite,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: BorderSide(color: isDark ? darkOutline : gray200, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // Buttons - SumUp Style (compact, smaller padding, Inter font)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? darkPrimaryBlue : slovakBlue,
          foregroundColor: isDark ? darkSurface : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          minimumSize: const Size(88, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
           backgroundColor: isDark ? darkPrimaryBlue : slovakBlue,
           foregroundColor: isDark ? darkSurface : Colors.white,
           elevation: 0,
           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
           minimumSize: const Size(88, 40),
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
           textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        )
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? darkPrimaryBlue : slovakBlue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          minimumSize: const Size(64, 36),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? darkPrimaryBlue : slovakBlue,
          side: BorderSide(color: isDark ? darkPrimaryBlue : slovakBlue, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          minimumSize: const Size(88, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isDark ? darkSecondaryRed : nationalRed,
        foregroundColor: Colors.white,
        elevation: 4,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusXl)),
      ),

      // Inputs — premium kancelársky (viditeľný border, biele pozadie)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? darkSurfaceVariant : tatraWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        labelStyle: textTheme.bodySmall?.copyWith(
          color: secondaryTextColor,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: isDark ? darkDisabled : gray400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: isDark ? darkOutline : gray200, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: isDark ? darkOutline : gray200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: isDark ? darkPrimaryBlue : slovakBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: isDark ? const Color(0xFFFFB4AB) : errorRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: isDark ? const Color(0xFFFFB4AB) : errorRed, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: isDark ? darkOutlineVariant : gray300, width: 1),
        ),
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? darkSurface : Colors.white,
        selectedItemColor: isDark ? darkPrimaryBlue : slovakBlue,
        unselectedItemColor: isDark ? darkDisabled : gray500,
        selectedLabelStyle: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      
      dividerTheme: DividerThemeData(
        color: isDark ? darkOutlineVariant : gray100,
        thickness: 0.5,
        space: 1,
      ),
      
      iconTheme: IconThemeData(
        color: isDark ? darkOnSurface : slovakBlue,
        size: 24,
      )
    );
  }

  /// Jemný tieň pre formulárové sekcie (faktúry, výdavky).
  static BoxDecoration formSectionDecoration({required bool isDark}) {
    return BoxDecoration(
      color: isDark ? darkSurfaceVariant : tatraWhite,
      borderRadius: BorderRadius.circular(radiusLg),
      border: Border.all(color: isDark ? darkOutline : gray200),
      boxShadow: [
        BoxShadow(
          color: slovakBlue.withValues(alpha: isDark ? 0.08 : 0.04),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }
}
