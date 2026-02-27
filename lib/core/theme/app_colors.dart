import 'package:flutter/material.dart';

/// BittyBot brand color palette — Cohere Tiny Aya inspired.
///
/// All surface/text pairs are WCAG AA compliant (>= 4.5:1 for normal text,
/// >= 3:1 for large text 18sp+ or 14sp+ bold).
///
/// WCAG contrast ratios (computed via relative luminance formula):
///   white (#FFFFFF) on surface (#0A1A0A):           18.03:1  [PASS AAA]
///   white (#FFFFFF) on surfaceContainer (#0F2B0F):  15.30:1  [PASS AAA]
///   white (#FFFFFF) on primary (#1B5E20):            7.87:1  [PASS AAA]
///   white (#FFFFFF) on primaryContainer (#0F3D0F):  12.39:1  [PASS AAA]
///   black (#000000) on secondary/lime (#8BC34A):    10.00:1  [PASS AAA]
///   lime  (#8BC34A) on surface (#0A1A0A):            8.59:1  [PASS AAA] (decorative borders)
///   muted (#B0D0B0) on surface (#0A1A0A):           10.73:1  [PASS AAA]
///   white (#FFFFFF) on error (#CF6679):              3.60:1  [PASS AA large text]
abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // Backgrounds
  // ---------------------------------------------------------------------------

  /// Near-black green — scaffold and screen backgrounds.
  /// Contrast with white: 18.03:1 (WCAG AAA).
  static const Color surface = Color(0xFF0A1A0A);

  /// Slightly lighter dark green — cards and elevated surfaces.
  /// Contrast with white: 15.30:1 (WCAG AAA).
  static const Color surfaceContainer = Color(0xFF0F2B0F);

  // ---------------------------------------------------------------------------
  // Primary (forest green)
  // ---------------------------------------------------------------------------

  /// Forest green — buttons and interactive accents.
  /// Contrast with white: 7.87:1 (WCAG AAA — safe for normal-size button labels).
  static const Color primary = Color(0xFF1B5E20);

  /// Deep forest green — input fields and user message bubbles.
  /// Contrast with white: 12.39:1 (WCAG AAA).
  static const Color primaryContainer = Color(0xFF0F3D0F);

  /// White text on forest green surfaces.
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// White text on deep-forest-green containers.
  static const Color onPrimaryContainer = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------------
  // Secondary (lime / yellow-green)
  // ---------------------------------------------------------------------------

  /// Lime / yellow-green — borders, highlights, logo accents.
  /// Contrast of lime on surface: 8.59:1 (WCAG AAA — suitable for decorative use).
  static const Color secondary = Color(0xFF8BC34A);

  /// Black text on lime background.
  /// Contrast: 10.00:1 (WCAG AAA).
  static const Color onSecondary = Color(0xFF000000);

  /// Dark green secondary container (less prominent than primary container).
  static const Color secondaryContainer = Color(0xFF1A3010);

  /// White text on secondary container.
  static const Color onSecondaryContainer = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------------
  // Text / on-surface colours
  // ---------------------------------------------------------------------------

  /// Primary text — white on all dark surfaces.
  /// Contrast on surface: 18.03:1 (WCAG AAA).
  static const Color onSurface = Color(0xFFFFFFFF);

  /// Muted text and secondary icons — soft green-tinted.
  /// Contrast on surface: 10.73:1 (WCAG AAA).
  static const Color onSurfaceVariant = Color(0xFFB0D0B0);

  // ---------------------------------------------------------------------------
  // Semantic
  // ---------------------------------------------------------------------------

  /// Error state — Material dark-theme pink-red.
  /// Contrast with white: 3.60:1 (WCAG AA for large text; intended for error
  /// icons / banners where text is 18sp+).
  static const Color error = Color(0xFFCF6679);

  /// White text on error surfaces.
  static const Color onError = Color(0xFFFFFFFF);

  /// Warning state — amber used for cautionary indicators and banners.
  static const Color warning = Color(0xFFFFC107);
}
