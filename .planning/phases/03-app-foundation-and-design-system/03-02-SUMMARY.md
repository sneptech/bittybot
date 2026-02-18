---
phase: 03-app-foundation-and-design-system
plan: 02
subsystem: ui
tags: [flutter, material3, theme, wcag, accessibility, typography, google_fonts, lato, colorscheme]

requires:
  - phase: "03-01"
    provides: "Flutter project scaffold with google_fonts 8.0.2 dependency, bundled Lato font assets in assets/google_fonts/"
provides:
  - "AppColors — brand color palette with WCAG-validated hex values and documented contrast ratios"
  - "buildDarkTheme() — Material 3 dark ThemeData with manual ColorScheme (not fromSeed)"
  - "buildTextTheme() — Lato-based TextTheme with 16sp bodyMedium and non-Latin script fallbacks"
affects: [03-03, 03-04, 03-05, phase-04-core-inference-arch, phase-05-translation-ui, phase-06-chat-ui]

tech-stack:
  added: []
  patterns:
    - "AppColors as abstract final class with const Color values; all WCAG ratios documented inline"
    - "ColorScheme constructed via full manual constructor — never ColorScheme.fromSeed — to preserve exact brand palette"
    - "TextTheme: GoogleFonts.latoTextTheme() base, copyWith per-style for fontSize overrides, then _applyFallbacksAndColor for script fallbacks + white colour"
    - "Script fallbacks advisory list: Noto Sans Arabic, Thai, CJK SC/TC, JP, KR — benefits Android; iOS falls through to system fonts automatically"
    - "materialTapTargetSize: MaterialTapTargetSize.padded set explicitly even though it is Flutter's mobile default — documents UIUX-04 intent"

key-files:
  created:
    - lib/core/theme/app_colors.dart (AppColors brand palette with documented WCAG ratios)
    - lib/core/theme/app_text_theme.dart (buildTextTheme with 16sp body minimum and script fallbacks)
    - lib/core/theme/app_theme.dart (buildDarkTheme with manual ColorScheme and component themes)
  modified: []

key-decisions:
  - "ColorScheme.fromSeed deliberately NOT used: fromSeed would generate a Material tonal palette from a seed colour, overriding the specific Cohere-inspired hex values. Manual ColorScheme() constructor used instead."
  - "bodyMedium raised to 16sp (plan specified 14sp Flutter default is too small for multilingual reading app per UIUX-05)"
  - "No textScaleFactor cap: locked decision is to fully respect user's system accessibility settings — no MediaQuery.withClampedTextScaling"
  - "Error colour (#CF6679) passes WCAG AA only for large text (3.60:1) — acceptable because errors appear in banners and 18sp+ text, not in inline body copy"

patterns-established:
  - "AppColors import pattern: import 'package:bittybot/core/theme/app_colors.dart' then AppColors.surface etc."
  - "Theme wiring: buildDarkTheme() returns ThemeData for direct use in MaterialApp.theme — no Provider wrapping needed at this stage"

requirements-completed: [UIUX-01, UIUX-02, UIUX-04, UIUX-05]

duration: 3min
completed: 2026-02-18
---

# Phase 3 Plan 02: Dark Theme System Summary

**Cohere-inspired dark theme with WCAG AAA green palette, Lato 16sp body text, non-Latin script fallbacks, and manual Material 3 ColorScheme — all three theme files deliver the brand foundation every subsequent screen inherits**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-18T18:44:00Z
- **Completed:** 2026-02-18T18:46:58Z
- **Tasks:** 2
- **Files modified:** 3 created

## Accomplishments

- `AppColors` abstract final class with 14 `const Color` fields; every surface/text pair has WCAG contrast ratio documented in a code comment (all pass AAA except error which passes AA for large text)
- `buildDarkTheme()` returns a `ThemeData` with `brightness: Brightness.dark`, manual `ColorScheme(...)` (not `fromSeed`), explicit `MaterialTapTargetSize.padded`, and five component theme overrides (AppBar, ElevatedButton, InputDecoration, SnackBar, Card)
- `buildTextTheme()` starts from `GoogleFonts.latoTextTheme()`, raises `bodyMedium` to 16sp and `bodyLarge` to 18sp, then injects six Noto Sans script fallbacks and white colour into every text style
- `flutter analyze` reports 0 issues across all three new files; the sole pre-existing warning is in Drift-generated code (out of scope)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create color palette with WCAG-validated hex values** - `712a97f` (feat)
2. **Task 2: Build dark ThemeData and Lato text theme** - `bb6dfde` (feat)

**Plan metadata:** (docs commit added after summary)

## Files Created/Modified

- `lib/core/theme/app_colors.dart` — Brand color palette with 14 const Color values and inline WCAG AAA contrast ratio documentation
- `lib/core/theme/app_text_theme.dart` — buildTextTheme(): Lato base, 16sp/18sp body overrides, script fallbacks, white colour applied to all 15 TextStyle slots
- `lib/core/theme/app_theme.dart` — buildDarkTheme(): Material 3 ThemeData with manual ColorScheme, five component themes; _buildColorScheme() private helper

## Decisions Made

1. **ColorScheme.fromSeed not used**: `fromSeed` generates an automatic tonal palette from a seed colour, overriding the specific `#1B5E20` forest green and `#8BC34A` lime values. The `ColorScheme(...)` full constructor used instead to lock in the exact brand hex values.

2. **All WCAG ratios documented inline**: Every field in `AppColors` has a doc comment with the computed ratio and pass/fail verdict. Ratios verified via the relative luminance formula (L = 0.2126R + 0.7152G + 0.0722B) before writing code.

3. **Error colour footnoted**: `#CF6679` gives 3.60:1 with white — passes AA only for large text (18sp+). Acceptable because errors in BittyBot appear in banners and icon-labels at 18sp+, never in body copy. This is documented in both `AppColors` and this summary.

## Deviations from Plan

None - plan executed exactly as written. All palette values and architecture matched the plan specification. WCAG ratios were computed pre-implementation to confirm hex values were correct before writing any code.

## Issues Encountered

None - WCAG ratio pre-computation confirmed the proposed hex values before any code was written. No iteration needed on colour choices.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Theme system is complete and immediately usable by all subsequent plans
- `buildDarkTheme()` is a plain function — wire it to `MaterialApp.theme:` in Plan 05 (app entry point)
- Plans 03-05 can import `AppColors` directly for any colour reference
- The Lato font is already bundled in `assets/google_fonts/` (Plan 01), so `GoogleFonts.latoTextTheme()` reads from disk — no network required

---
*Phase: 03-app-foundation-and-design-system*
*Completed: 2026-02-18*

## Self-Check: PASSED

All claimed files verified present on disk. Both task commits confirmed in git log.
- lib/core/theme/app_colors.dart: FOUND
- lib/core/theme/app_text_theme.dart: FOUND
- lib/core/theme/app_theme.dart: FOUND
- 712a97f (Task 1): FOUND
- bb6dfde (Task 2): FOUND
