import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_theme.dart';

/// Builds the BittyBot dark [ThemeData].
///
/// Design decisions:
/// - Dark-only (no light theme). Brightness.dark throughout.
/// - [ColorScheme] constructed manually — NOT via [ColorScheme.fromSeed].
///   fromSeed generates tonal palettes from a seed, overriding the specific
///   Cohere-inspired greens required by the brand.
/// - [MaterialTapTargetSize.padded] set explicitly (UIUX-04). This is the
///   Flutter mobile default, but setting it explicitly documents intent and
///   guards against accidental shrinking.
/// - No textScaleFactor cap or MediaQuery.withClampedTextScaling — the locked
///   decision is to fully respect the user's system accessibility settings.
/// - useMaterial3 is NOT set — it defaults to true in Flutter 3.16+, which is
///   what we want. Setting it would be redundant.
ThemeData buildDarkTheme() {
  final colorScheme = _buildColorScheme();
  final textTheme = buildTextTheme();

  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    textTheme: textTheme,

    // Explicit scaffold background keeps dark green even if ColorScheme
    // surface assignment were to change during a future refactor.
    scaffoldBackgroundColor: AppColors.surface,

    // UIUX-04: minimum 48×48 dp tap targets on all Material widgets.
    materialTapTargetSize: MaterialTapTargetSize.padded,

    // -------------------------------------------------------------------------
    // Component themes
    // -------------------------------------------------------------------------
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.onSurface,
      // Zero elevation for a clean, minimal look (UIUX-02).
      elevation: 0,
      centerTitle: false,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        // Minimum 48 dp height to satisfy UIUX-04 on button tap targets.
        minimumSize: const Size(0, 48),
        textStyle: textTheme.labelLarge,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.primaryContainer,
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.secondary),
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.secondary),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.secondary, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      labelStyle: textTheme.bodyMedium?.copyWith(
        color: AppColors.onSurfaceVariant,
      ),
      hintStyle: textTheme.bodyMedium?.copyWith(
        color: AppColors.onSurfaceVariant,
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceContainer,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: AppColors.onSurface,
      ),
      behavior: SnackBarBehavior.floating,
    ),

    cardTheme: const CardThemeData(
      color: AppColors.surfaceContainer,
      // Flat, minimal card style (UIUX-02 — no unnecessary depth).
      elevation: 0,
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
  );
}

/// Constructs the [ColorScheme] from [AppColors].
///
/// All roles are mapped manually so the Cohere-inspired palette is preserved
/// exactly. Do NOT replace this with [ColorScheme.fromSeed].
ColorScheme _buildColorScheme() {
  return const ColorScheme(
    brightness: Brightness.dark,

    // Surface roles
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    surfaceContainerHighest: AppColors.surfaceContainer,
    onSurfaceVariant: AppColors.onSurfaceVariant,

    // Primary roles (forest green)
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,

    // Secondary roles (lime / yellow-green accents)
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onSecondaryContainer,

    // Tertiary — reuse secondary tones (no third accent in this palette)
    tertiary: AppColors.secondary,
    onTertiary: AppColors.onSecondary,
    tertiaryContainer: AppColors.secondaryContainer,
    onTertiaryContainer: AppColors.onSecondaryContainer,

    // Outline (lime for borders/dividers)
    outline: AppColors.secondary,
    outlineVariant: AppColors.primary,

    // Error roles
    error: AppColors.error,
    onError: AppColors.onError,
    errorContainer: AppColors.primaryContainer,
    onErrorContainer: AppColors.onSurface,

    // Inverse (required by ColorScheme constructor — minimal mapping)
    inverseSurface: AppColors.onSurface,
    onInverseSurface: AppColors.surface,
    inversePrimary: AppColors.secondary,

    // Scrim and shadow (standard dark-theme values)
    scrim: Color(0xFF000000),
    shadow: Color(0xFF000000),
  );
}
