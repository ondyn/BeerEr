import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// BeerEr colour palette — warm amber/dark beer style.
abstract final class BeerColors {
  static const Color primaryAmber = Color(0xFFF5A623);
  static const Color primaryDark = Color(0xFFC47D0E);
  static const Color background = Color(0xFF1A1208);
  static const Color surface = Color(0xFF2C1F0E);
  static const Color surfaceVariant = Color(0xFF3D2B14);
  static const Color onSurface = Color(0xFFF5ECD7);
  static const Color onSurfaceSecondary = Color(0xFFA89880);
  static const Color success = Color(0xFF9DC88D);
  static const Color warning = Color(0xFFE07B39);
  static const Color error = Color(0xFFC0392B);
  static const Color scrim = Color(0x99000000);
}

/// Creates the full Beerer [ThemeData].
ThemeData buildBeerTheme() {
  final nunito = GoogleFonts.nunitoTextTheme();
  final inter = GoogleFonts.interTextTheme();

  final textTheme = TextTheme(
    // Display / Headings — Nunito
    displayLarge: nunito.displayLarge!.copyWith(
      color: BeerColors.onSurface,
      fontWeight: FontWeight.w700,
    ),
    displayMedium: nunito.displayMedium!.copyWith(
      color: BeerColors.onSurface,
      fontWeight: FontWeight.w700,
    ),
    displaySmall: nunito.displaySmall!.copyWith(
      color: BeerColors.onSurface,
      fontWeight: FontWeight.w700,
    ),
    headlineLarge: nunito.headlineLarge!.copyWith(
      color: BeerColors.onSurface,
      fontWeight: FontWeight.w700,
    ),
    headlineMedium: nunito.headlineMedium!.copyWith(
      color: BeerColors.onSurface,
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: nunito.headlineSmall!.copyWith(
      color: BeerColors.onSurface,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: nunito.titleLarge!.copyWith(
      color: BeerColors.onSurface,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: nunito.titleMedium!.copyWith(
      color: BeerColors.onSurface,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: nunito.titleSmall!.copyWith(
      color: BeerColors.onSurface,
      fontWeight: FontWeight.w500,
    ),
    // Body — Inter
    bodyLarge: inter.bodyLarge!.copyWith(
      color: BeerColors.onSurface,
    ),
    bodyMedium: inter.bodyMedium!.copyWith(
      color: BeerColors.onSurface,
    ),
    bodySmall: inter.bodySmall!.copyWith(
      color: BeerColors.onSurfaceSecondary,
    ),
    labelLarge: inter.labelLarge!.copyWith(
      color: BeerColors.onSurface,
      fontWeight: FontWeight.w600,
    ),
    labelMedium: inter.labelMedium!.copyWith(
      color: BeerColors.onSurfaceSecondary,
    ),
    labelSmall: inter.labelSmall!.copyWith(
      color: BeerColors.onSurfaceSecondary,
    ),
  );

  const colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: BeerColors.primaryAmber,
    onPrimary: BeerColors.background,
    primaryContainer: BeerColors.primaryDark,
    onPrimaryContainer: BeerColors.onSurface,
    secondary: BeerColors.primaryDark,
    onSecondary: BeerColors.onSurface,
    error: BeerColors.error,
    onError: Colors.white,
    surface: BeerColors.surface,
    onSurface: BeerColors.onSurface,
    surfaceContainerHighest: BeerColors.surfaceVariant,
    outline: BeerColors.onSurfaceSecondary,
    scrim: BeerColors.scrim,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    textTheme: textTheme,
    scaffoldBackgroundColor: BeerColors.background,
    appBarTheme: AppBarTheme(
      backgroundColor: BeerColors.surface,
      foregroundColor: BeerColors.onSurface,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: nunito.titleLarge!.copyWith(
        color: BeerColors.onSurface,
        fontWeight: FontWeight.w700,
        fontSize: 20,
      ),
    ),
    cardTheme: CardThemeData(
      color: BeerColors.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: BeerColors.primaryAmber,
        foregroundColor: BeerColors.background,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: inter.labelLarge!.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: BeerColors.primaryAmber,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: BeerColors.primaryAmber),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: inter.labelLarge!.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: BeerColors.primaryAmber,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: BeerColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: BeerColors.primaryAmber,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BeerColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      hintStyle: inter.bodyMedium!.copyWith(
        color: BeerColors.onSurfaceSecondary,
      ),
      labelStyle: inter.bodyMedium!.copyWith(
        color: BeerColors.onSurfaceSecondary,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: BeerColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: BeerColors.primaryDark,
      contentTextStyle: inter.bodyMedium!.copyWith(
        color: BeerColors.onSurface,
      ),
      actionTextColor: BeerColors.onSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: BeerColors.surfaceVariant,
      selectedColor: BeerColors.primaryAmber,
      labelStyle: inter.labelLarge!.copyWith(
        color: BeerColors.onSurface,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: BeerColors.primaryAmber,
      foregroundColor: BeerColors.background,
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: BeerColors.surface,
    ),
    dividerTheme: const DividerThemeData(
      color: BeerColors.surfaceVariant,
      thickness: 1,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return BeerColors.primaryAmber;
        }
        return BeerColors.onSurfaceSecondary;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return BeerColors.primaryDark;
        }
        return BeerColors.surfaceVariant;
      }),
    ),
  );
}
