import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppColors {
  // Primary Forest Green palette
  static const Color forestGreen = Color(0xFF2D5A27);
  static const Color forestGreenLight = Color(0xFF4CAF50);
  static const Color forestGreenDark = Color(0xFF1B3A17);

  // Technical Orange accent
  static const Color techOrange = Color(0xFFE8530A);
  static const Color techOrangeLight = Color(0xFFFF7043);

  // Neutral surfaces
  static const Color surface = Color(0xFFF8FAF8);
  static const Color surfaceDark = Color(0xFF1C2B1A);
  static const Color onSurface = Color(0xFF1A1C1A);

  // Status colors
  static const Color pending = Color(0xFFF59E0B);
  static const Color onTheWay = Color(0xFF3B82F6);
  static const Color completed = Color(0xFF22C55E);

  // Material type colors
  static const Map<String, Color> materialColors = {
    'Cartón': Color(0xFF92400E),
    'Vidrio': Color(0xFF0E7490),
    'Plástico': Color(0xFF7C3AED),
    'Metal': Color(0xFF374151),
    'Orgánico': Color(0xFF15803D),
    'Electrónico': Color(0xFF1D4ED8),
    'Textil': Color(0xFFBE185D),
  };
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = FlexColorScheme.light(
      scheme: FlexScheme.green,
      primary: AppColors.forestGreen,
      primaryContainer: const Color(0xFFB7F0B1),
      secondary: AppColors.techOrange,
      secondaryContainer: const Color(0xFFFFDBCF),
      surface: AppColors.surface,
      appBarStyle: FlexAppBarStyle.background,
      tabBarStyle: FlexTabBarStyle.forBackground,
      subThemesData: const FlexSubThemesData(
        interactionEffects: true,
        tintedDisabledControls: true,
        blendOnLevel: 10,
        blendOnColors: false,
        useM2StyleDividerInM3: true,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputDecoratorUnfocusedBorderIsColored: false,
        fabUseShape: true,
        fabAlwaysCircular: true,
        chipSchemeColor: SchemeColor.primary,
        navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
        navigationBarSelectedIconSchemeColor: SchemeColor.primary,
        navigationBarIndicatorSchemeColor: SchemeColor.primaryContainer,
        navigationBarBackgroundSchemeColor: SchemeColor.surface,
        navigationBarElevation: 0,
        navigationRailSelectedLabelSchemeColor: SchemeColor.primary,
        navigationRailSelectedIconSchemeColor: SchemeColor.primary,
        navigationRailIndicatorSchemeColor: SchemeColor.primaryContainer,
        navigationRailBackgroundSchemeColor: SchemeColor.surface,
        navigationRailElevation: 0,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
    ).toTheme;

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
    );
  }

  static ThemeData get dark {
    final base = FlexColorScheme.dark(
      scheme: FlexScheme.green,
      primary: AppColors.forestGreenLight,
      primaryContainer: AppColors.forestGreenDark,
      secondary: AppColors.techOrangeLight,
      surface: AppColors.surfaceDark,
      appBarStyle: FlexAppBarStyle.background,
      subThemesData: const FlexSubThemesData(
        interactionEffects: true,
        tintedDisabledControls: true,
        blendOnLevel: 20,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        fabUseShape: true,
        fabAlwaysCircular: true,
        navigationBarBackgroundSchemeColor: SchemeColor.surface,
        navigationBarElevation: 0,
        navigationRailBackgroundSchemeColor: SchemeColor.surface,
        navigationRailElevation: 0,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
    ).toTheme;

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
    );
  }
}
