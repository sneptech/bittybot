---
phase: 03-app-foundation-and-design-system
plan: 01
subsystem: infra
tags: [flutter, riverpod, drift, google_fonts, l10n, sqlite]

requires: []
provides:
  - Flutter project scaffold (android + ios targets, com.bittybot org)
  - All Phase 3 dependencies resolved (flutter_riverpod 3.1.0, drift 2.31.0, google_fonts 8.0.2, shared_preferences 2.5.4)
  - Bundled Lato font assets (6 weights) for offline use in assets/google_fonts/
  - l10n.yaml config with ARB code-gen for AppLocalizations
  - Empty Drift AppDatabase stub ready for Phase 4 tables
affects: [03-02, 03-03, 03-04, 03-05, phase-04-core-inference-arch]

tech-stack:
  added:
    - flutter_riverpod 3.1.0 (pinned; 3.2.1 conflicts with riverpod_generator 4.x on Flutter 3.38.5)
    - riverpod_annotation 4.0.0
    - riverpod_generator 4.0.0+1 (uses analyzer >=7.0.0 <9.0.0, compatible with Flutter SDK test pinning)
    - google_fonts 8.0.2 (with allowRuntimeFetching = false pattern)
    - shared_preferences 2.5.4
    - drift 2.31.0
    - drift_flutter 0.2.8
    - path_provider 2.1.5
    - build_runner 2.10.5
    - drift_dev 2.31.0
  patterns:
    - AppDatabase with driftDatabase(name: 'bittybot') for platform-aware SQLite connection
    - ARB-based localization with l10n.yaml (generate: true in pubspec, synthetic-package removed)
    - Lato font files in assets/google_fonts/ with exact API filename convention (Lato-{WeightName}[Italic].ttf)

key-files:
  created:
    - pubspec.yaml (full Phase 3 dependency manifest)
    - l10n.yaml (ARB code-gen configuration)
    - lib/main.dart (minimal placeholder - real entry point in Plan 05)
    - lib/core/l10n/app_en.arb (English string templates with dual-tone error messages)
    - lib/core/l10n/app_localizations.dart (generated - do not edit)
    - lib/core/l10n/app_localizations_en.dart (generated - do not edit)
    - lib/core/db/app_database.dart (empty Drift database definition)
    - lib/core/db/app_database.g.dart (generated - do not edit)
    - assets/google_fonts/Lato-Regular.ttf
    - assets/google_fonts/Lato-Bold.ttf
    - assets/google_fonts/Lato-Italic.ttf
    - assets/google_fonts/Lato-BoldItalic.ttf
    - assets/google_fonts/Lato-Light.ttf
    - assets/google_fonts/Lato-Thin.ttf
  modified: []

key-decisions:
  - "Pinned flutter_riverpod to 3.1.0 (not 3.2.1 as planned): riverpod_generator 4.0.1+ requires analyzer ^9.0.0 which conflicts with test 1.26.3 (pinned by flutter_test in Flutter 3.38.5 SDK). Using riverpod_generator 4.0.0+1 with analyzer >=7.0.0 <9.0.0 resolves all version conflicts."
  - "Removed synthetic-package from l10n.yaml: Flutter 3.38.5 deprecated this option (always generates to source). The option caused a fatal warning that prevented pub get from completing cleanly."
  - "Lato Thin and Light downloaded from fonts.gstatic.com CDN using known SHA-256 hashes from google_fonts package source (bdeed32... and f8b8bb4...). Regular, Bold, Italic, BoldItalic sourced from google_fonts 8.0.2 package example cache."

patterns-established:
  - "google_fonts asset naming: files must be named {Family}-{WeightName}[Italic].ttf where WeightName maps as Thin/Light/Regular/Medium/SemiBold/Bold/ExtraBold/Black"
  - "Drift database: driftDatabase(name: 'bittybot') creates bittybot.sqlite in platform documents directory"
  - "ARB dual-tone pattern: each user-visible error has _Friendly and _Direct variants for settings toggle"

requirements-completed: [UIUX-02]

duration: 8min
completed: 2026-02-19
---

# Phase 3 Plan 01: Flutter Project Bootstrap and Foundation Summary

**Flutter 3.38.5 project scaffolded with Riverpod 3.1.0, Drift 2.31.0, bundled Lato font (6 weights), ARB localization config, and empty Drift database ready for Phase 4 tables**

## Performance

- **Duration:** 8 min
- **Started:** 2026-02-19T18:32:35Z
- **Completed:** 2026-02-19T18:40:44Z
- **Tasks:** 3
- **Files modified:** 14 source + 6 font assets

## Accomplishments

- Flutter project created with `--org com.bittybot --project-name bittybot --platforms=android,ios`
- All Phase 3 dependencies resolved (flutter pub get exits 0, no version conflicts)
- 6 Lato font files bundled in `assets/google_fonts/` for offline-safe rendering
- `l10n.yaml` configured for ARB code-gen; `app_en.arb` template with dual-tone error messages
- `AppDatabase` stub with `@DriftDatabase(tables: [])` and generated `.g.dart` via build_runner
- `flutter analyze` reports 0 errors (1 warning in generated Drift code — acceptable)

## Task Commits

Each task was committed atomically:

1. **Task 1: Bootstrap Flutter project and configure dependencies** - `997b907` (feat)
2. **Task 2: Bundle Lato font assets for offline use** - `c607548` (feat)
3. **Task 3: Create empty Drift database stub** - `2a03d8d` (feat)

**Plan metadata:** (docs commit added after summary)

## Files Created/Modified

- `pubspec.yaml` - Full Phase 3 dependency manifest with generate: true and assets: [assets/google_fonts/]
- `l10n.yaml` - ARB code-gen config (arb-dir: lib/core/l10n, output-class: AppLocalizations)
- `lib/main.dart` - Minimal placeholder MaterialApp (real entry point in Plan 05)
- `lib/core/l10n/app_en.arb` - English string template with dual-tone error messages
- `lib/core/l10n/app_localizations.dart` - Generated localization class
- `lib/core/l10n/app_localizations_en.dart` - Generated English implementation
- `lib/core/db/app_database.dart` - Empty Drift database with driftDatabase connection
- `lib/core/db/app_database.g.dart` - Generated Drift database code
- `assets/google_fonts/Lato-{Regular,Bold,Italic,BoldItalic,Light,Thin}.ttf` - Bundled fonts
- `test/widget_test.dart` - Updated smoke test (removed stale MyApp reference)

## Decisions Made

1. **flutter_riverpod pinned to 3.1.0** (not 3.2.1 as planned): `riverpod_generator ^4.0.1+` requires `analyzer ^9.0.0` but `flutter_test` in Flutter 3.38.5 pins `test_api 0.7.7` which requires `test 1.26.3` which requires `analyzer <9.0.0`. Using `riverpod_generator 4.0.0+1` (analyzer >=7.0.0 <9.0.0) resolves all version conflicts. All Riverpod 3.x APIs remain available.

2. **synthetic-package removed from l10n.yaml**: Flutter 3.38.5 deprecated `synthetic-package` entirely — attempting to set it caused a fatal error during `flutter pub get`. Localization generation now always targets source (lib/core/l10n/) which is the correct behavior.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Riverpod version conflict resolution**
- **Found during:** Task 1 (flutter pub get)
- **Issue:** `flutter_riverpod ^3.2.1` + `riverpod_generator ^4.0.3` are incompatible on Flutter 3.38.5 due to `test_api` version pinning by `flutter_test` SDK package
- **Fix:** Downgraded to `flutter_riverpod: ^3.1.0`, `riverpod_annotation: ^4.0.0`, `riverpod_generator: ^4.0.0` (resolves to 4.0.0+1). All Riverpod 3.x APIs remain available; no functional impact.
- **Files modified:** `pubspec.yaml`
- **Verification:** `flutter pub get` exits 0, no version conflicts
- **Committed in:** 997b907 (Task 1 commit)

**2. [Rule 3 - Blocking] Removed deprecated synthetic-package from l10n.yaml**
- **Found during:** Task 1 (flutter pub get output)
- **Issue:** `synthetic-package` argument deprecated in Flutter 3.38.5; caused fatal warning that prevented localization generation from completing
- **Fix:** Removed `synthetic-package: false` from `l10n.yaml`. Flutter 3.38.5 always generates to source by default.
- **Files modified:** `l10n.yaml`
- **Verification:** `flutter pub get` completes without l10n errors
- **Committed in:** 997b907 (Task 1 commit)

**3. [Rule 2 - Missing] Created lib/core/l10n/ directory and app_en.arb**
- **Found during:** Task 1 (flutter pub get - l10n generation failed: arb-dir doesn't exist)
- **Issue:** l10n.yaml references `lib/core/l10n/` but directory and template ARB file didn't exist
- **Fix:** Created directory and initial `app_en.arb` with dual-tone error message strings
- **Files modified:** `lib/core/l10n/app_en.arb`
- **Verification:** `flutter pub get` completes; `app_localizations.dart` generated
- **Committed in:** 997b907 (Task 1 commit)

**4. [Rule 1 - Bug] Fixed stale widget_test.dart referencing removed MyApp class**
- **Found during:** Task 1 (flutter analyze)
- **Issue:** Default `flutter create` test references `MyApp` counter widget which was replaced by minimal placeholder main.dart
- **Fix:** Updated test to use plain `MaterialApp` widget smoke test
- **Files modified:** `test/widget_test.dart`
- **Verification:** `flutter analyze` reports 0 errors
- **Committed in:** 997b907 (Task 1 commit)

---

**Total deviations:** 4 auto-fixed (2 blocking, 1 missing critical, 1 bug)
**Impact on plan:** All auto-fixes were necessary for the plan to proceed. Version pinning to 3.1.0 is a minor downgrade with no functional API changes. No scope creep.

## Issues Encountered

- Google Fonts download zip (`https://fonts.google.com/download?family=Lato`) returned HTML instead of a zip file. Worked around by sourcing Regular/Bold/Italic/BoldItalic from the google_fonts 8.0.2 package's example directory (already on disk) and downloading Thin/Light directly from `fonts.gstatic.com/s/a/{hash}.ttf` using the known SHA-256 hashes embedded in the google_fonts package source.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Flutter project compiles cleanly with all Phase 3 dependencies
- Plans 02-05 can all build on this foundation immediately
- Riverpod code-gen infrastructure ready (riverpod_generator + build_runner)
- Drift infrastructure ready (drift_dev + build_runner); Phase 4 adds tables
- Localization infrastructure ready; Plans 03/04 add more ARB strings and languages
- **Note for Plans 02+:** `flutter_riverpod` is 3.1.0 not 3.2.1 — all `@riverpod` code-gen patterns work identically

---
*Phase: 03-app-foundation-and-design-system*
*Completed: 2026-02-19*

## Self-Check: PASSED

All claimed files verified present on disk. All 3 task commits confirmed in git log.
- pubspec.yaml: FOUND
- l10n.yaml: FOUND
- lib/main.dart: FOUND
- lib/core/l10n/app_en.arb: FOUND
- lib/core/db/app_database.dart: FOUND
- lib/core/db/app_database.g.dart: FOUND
- assets/google_fonts/Lato-{Regular,Bold,Italic,BoldItalic,Light,Thin}.ttf: FOUND (all 6)
- 997b907 (Task 1): FOUND
- c607548 (Task 2): FOUND
- 2a03d8d (Task 3): FOUND
