import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bittybot/core/theme/app_theme.dart';
import 'package:bittybot/core/theme/app_colors.dart';

void main() {
  // Required: google_fonts needs the Flutter services binding to be
  // initialized before it can load font assets during tests.
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  late ThemeData theme;

  setUp(() {
    theme = buildDarkTheme();
  });

  group('ColorScheme', () {
    test('uses dark brightness', () {
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.brightness, Brightness.dark);
    });

    test('surface is near-black green', () {
      // Surface should be very dark (luminance < 0.05)
      expect(theme.colorScheme.surface.computeLuminance(), lessThan(0.05));
    });

    test('primary is forest green', () {
      // Primary should be in the green range (green channel dominant)
      // Uses .g/.r/.b (double 0.0-1.0) — the non-deprecated Color API.
      final color = theme.colorScheme.primary;
      expect(color.g, greaterThan(color.r));
      expect(color.g, greaterThan(color.b));
    });

    test('onSurface is white', () {
      expect(theme.colorScheme.onSurface, equals(const Color(0xFFFFFFFF)));
    });

    test('does not use fromSeed tonal palette', () {
      // Verify surface and primary are distinct specific colors, not tonal variants
      expect(theme.colorScheme.surface, isNot(equals(theme.colorScheme.primary)));
      // Surface should match our specific near-black green value
      expect(theme.colorScheme.surface, equals(AppColors.surface));
      // Primary should match our specific forest green value
      expect(theme.colorScheme.primary, equals(AppColors.primary));
    });
  });

  group('WCAG Contrast', () {
    test('white on primary meets AA (4.5:1)', () {
      // AppColors docs: white on primary (#1B5E20) = 7.87:1 [PASS AAA]
      final ratio = _contrastRatio(
        theme.colorScheme.onPrimary,
        theme.colorScheme.primary,
      );
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('white on surface meets AA (4.5:1)', () {
      // AppColors docs: white on surface (#0A1A0A) = 18.03:1 [PASS AAA]
      final ratio = _contrastRatio(
        theme.colorScheme.onSurface,
        theme.colorScheme.surface,
      );
      expect(ratio, greaterThanOrEqualTo(4.5));
    });
  });

  group('Typography', () {
    test('bodyMedium is at least 16sp', () {
      expect(theme.textTheme.bodyMedium?.fontSize, greaterThanOrEqualTo(16));
    });

    test('bodyLarge is at least 18sp', () {
      expect(theme.textTheme.bodyLarge?.fontSize, greaterThanOrEqualTo(18));
    });
  });

  group('Accessibility', () {
    test('materialTapTargetSize is padded', () {
      expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
    });
  });
}

/// WCAG contrast ratio computed from relative luminances.
///
/// Returns a value >= 1.0; WCAG AA normal text requires >= 4.5:1.
double _contrastRatio(Color foreground, Color background) {
  final fgLuminance = foreground.computeLuminance();
  final bgLuminance = background.computeLuminance();
  final lighter = fgLuminance > bgLuminance ? fgLuminance : bgLuminance;
  final darker = fgLuminance > bgLuminance ? bgLuminance : fgLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
