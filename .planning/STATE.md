# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-19)

**Core value:** Translation and conversation must work with zero connectivity
**Current focus:** Phase 3 - App Foundation and Design System

## Current Position

Phase: 3 of 9 (App Foundation and Design System)
Plan: 4 of 5 completed in current phase
Status: In progress — Plans 01-04 complete, Plan 05 pending
Last activity: 2026-02-18 — Phase 3 Plan 04 complete (SettingsProvider, ErrorTone, error message resolver)

Progress: [░░░░░░░░░░] ~10%

## Performance Metrics

**Velocity:**
- Total plans completed: 2
- Average duration: 6 min
- Total execution time: 0.20 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| Phase 03 | 2/5 | 12min | 6min |

**Recent Trend:**
- Last 5 plans: 9min, 3min
- Trend: accelerating

*Updated after each plan completion*
| Phase 03 P03 | 24 | 2 tasks | 21 files |
| Phase 03 P04 | 4 | 2 tasks | 4 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Pre-Phase 1]: Model cannot be bundled in app binary (app store size limits); first-launch download via `background_downloader` required
- [Pre-Phase 1]: Inference binding choice (llama_cpp_dart vs fllama) is unresolved — Phase 1 spike resolves this by checking which has Cohere2-compatible llama.cpp version
- [Pre-Phase 1]: Android NDK r28+ required for 16 KB page compliance (Play Store mandatory by May 31, 2026)
- [Pre-Phase 1]: iOS Simulator blocked (Metal GPU unavailable); Phase 1 must run on physical iOS device
- [Phase 03]: flutter_riverpod pinned to 3.1.0 (not 3.2.1): riverpod_generator 4.0.1+ conflicts with flutter_test test_api pin in Flutter 3.38.5 SDK
- [Phase 03]: synthetic-package removed from l10n.yaml: Flutter 3.38.5 deprecated this option; always generates to source now
- [Phase 03]: ColorScheme.fromSeed deliberately NOT used in buildDarkTheme: fromSeed generates tonal palette overriding exact brand hex values; manual ColorScheme() constructor used instead
- [Phase 03]: Error colour (#CF6679) passes WCAG AA only for large text (3.60:1) — acceptable for banners and icon-labels at 18sp+, not used in body copy
- [Phase 03]: English ARB expanded from 8-key stub (Plan 01) to 22-key template with full @ metadata for all settings UI labels and model loading strings
- [Phase 03]: Flutter installed at /home/max/Android/flutter/bin/flutter (not on PATH); use absolute path for all flutter commands in this worktree
- [Phase 03]: AsyncValue.value not .valueOrNull for Riverpod 3.1.0 — valueOrNull does not exist on AsyncValue in this version
- [Phase 03]: resolveErrorMessage uses Dart 3 record pattern switch (AppError, ErrorTone) — compiler catches missing combinations at analysis time
- [Phase 03]: Locale persisted as languageCode string only (e.g., 'ar') — sufficient for 10 supported locales

### Pending Todos

None yet.

### Blockers/Concerns

- **CRITICAL**: Cohere2 architecture support in Flutter llama.cpp plugins is unverified. If neither `llama_cpp_dart` nor `fllama` includes llama.cpp PR #19611, the project approach must change before any production code is written. Phase 1 resolves this.
- **RISK**: iOS memory pressure on 4 GB devices (iPhone 12/13 base) with a 2.14 GB model. Phase 1 spike on physical iPhone 12 will surface this.
- **RISK**: Android Play Asset Delivery — whether Google Play will accept a first-launch download of 2 GB vs. requiring PAD integration. Phase 2 addresses this.

## Session Continuity

Last session: 2026-02-18
Stopped at: Completed 03-04-PLAN.md (SettingsProvider with SharedPreferencesWithCache, error message resolver)
Resume file: .planning/phases/03-app-foundation-and-design-system/03-04-SUMMARY.md
