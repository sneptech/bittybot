import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Script-specific font fallbacks for non-Latin writing systems.
///
/// These are advisory — Noto fonts ship on most Android devices. On iOS,
/// Flutter automatically falls through to the system font for unsupported
/// characters, so the fallback list primarily benefits Android users.
const List<String> _scriptFallbacks = [
  'Noto Sans Arabic',
  'Noto Sans Thai',
  'Noto Sans CJK SC',
  'Noto Sans CJK TC',
  'Noto Sans JP',
  'Noto Sans KR',
];

/// Applies [_scriptFallbacks] and [color] to every [TextStyle] in [theme].
TextTheme _applyFallbacksAndColor(TextTheme theme, Color color) {
  // Helper: copy a style with fallbacks + colour, preserving all other props.
  TextStyle patch(TextStyle? style) {
    style ??= const TextStyle();
    return style.copyWith(
      fontFamilyFallback: _scriptFallbacks,
      color: color,
    );
  }

  return theme.copyWith(
    displayLarge: patch(theme.displayLarge),
    displayMedium: patch(theme.displayMedium),
    displaySmall: patch(theme.displaySmall),
    headlineLarge: patch(theme.headlineLarge),
    headlineMedium: patch(theme.headlineMedium),
    headlineSmall: patch(theme.headlineSmall),
    titleLarge: patch(theme.titleLarge),
    titleMedium: patch(theme.titleMedium),
    titleSmall: patch(theme.titleSmall),
    bodyLarge: patch(theme.bodyLarge),
    bodyMedium: patch(theme.bodyMedium),
    bodySmall: patch(theme.bodySmall),
    labelLarge: patch(theme.labelLarge),
    labelMedium: patch(theme.labelMedium),
    labelSmall: patch(theme.labelSmall),
  );
}

/// Builds the Lato-based [TextTheme] for BittyBot.
///
/// Sizing decisions (UIUX-05):
/// - [bodyMedium] is raised to 16sp (Flutter default is 14sp) — minimum
///   comfortable body text size for a multilingual reading app.
/// - [bodyLarge] is raised to 18sp.
/// - [bodySmall] stays at 14sp (acceptable for captions and metadata).
///
/// All styles include [_scriptFallbacks] for Arabic, Thai, CJK, and Korean
/// characters. The base font is Lato (loaded from bundled assets via the
/// google_fonts package; runtime network fetching is disabled in main.dart).
TextTheme buildTextTheme() {
  // Start with Google Fonts Lato as the base. google_fonts reads from the
  // bundled assets/google_fonts/ directory when network fetching is off.
  TextTheme base = GoogleFonts.latoTextTheme();

  // Override body sizes to meet UIUX-05 (16sp minimum for body text).
  base = base.copyWith(
    bodyLarge: base.bodyLarge?.copyWith(fontSize: 18),
    bodyMedium: base.bodyMedium?.copyWith(fontSize: 16),
    // bodySmall stays at 14sp — used only for captions and timestamps.
  );

  // Apply script fallbacks and white colour to all styles.
  return _applyFallbacksAndColor(base, Colors.white);
}
