---
phase: 05-translation-ui
plan: "01"
subsystem: ui
tags: [flutter, dart, riverpod, i18n, l10n, language-picker, country-flags, shared-preferences]

# Dependency graph
requires:
  - phase: 04-core-inference-architecture
    provides: TranslationNotifier with translate/setTargetLanguage/stopTranslation, ChatRepository.watchMessagesForSession, settingsProvider
  - phase: 03-app-foundation
    provides: AppSettings with SharedPreferencesWithCache pattern, ARB l10n infrastructure

provides:
  - SupportedLanguage value object (englishName, code, primaryCountryCode)
  - kSupportedLanguages: 66 Tiny Aya languages sorted alphabetically with ISO codes and country flags
  - kPopularLanguages: top 10 by global usage for picker pinning
  - kLanguageCountryVariants: device locale country code override map (es_MX -> Mexico flag)
  - resolveCountryCode() helper for dynamic flag variant selection
  - AppSettings.targetLanguage field with SharedPreferences persistence (TRNS-05)
  - AppSettings.recentTargetLanguages rolling list (max 3, deduped)
  - Settings.setTargetLanguage() persisting to SharedPreferences
  - TranslationNotifier reads persisted targetLanguage from settingsProvider on build()
  - TranslationNotifier.setTargetLanguage() persists to settings
  - TranslationNotifier.startNewSession() public method for UI new-session button
  - sessionMessagesProvider: StreamProvider.family for reactive message watching
  - 13 translation UI l10n keys in all 10 ARB files

affects:
  - 05-02 (language picker sheet — consumes SupportedLanguage, kSupportedLanguages, kPopularLanguages)
  - 05-03 (translation screen — consumes sessionMessagesProvider, startNewSession, l10n keys)
  - 05-04 (navigation shell — consumes l10n translate/chat keys)

# Tech tracking
tech-stack:
  added:
    - country_flags ^4.1.2 (SVG flag icons from ISO 3166-1 alpha-2 country codes)
    - flutter_localized_locales ^2.0.5 (language names in device OS locale)
  patterns:
    - SupportedLanguage value object: immutable with ==, hashCode, toString
    - Language variant resolver: device locale country code overrides primary flag
    - Rolling recent list: prepend + toSet + cap at 3 pattern for SharedPreferences lists
    - settingsProvider extension: add field + key constant + build() read + setter method
    - StreamProvider.family wrapping repository stream for reactive UI

key-files:
  created:
    - lib/features/translation/domain/supported_language.dart
    - lib/features/translation/data/language_data.dart
    - lib/features/translation/application/session_messages_provider.dart
    - lib/features/translation/application/session_messages_provider.g.dart
  modified:
    - pubspec.yaml (added country_flags, flutter_localized_locales)
    - lib/features/settings/application/settings_provider.dart (targetLanguage, recentTargetLanguages)
    - lib/features/settings/application/settings_provider.g.dart (regenerated)
    - lib/features/translation/application/translation_notifier.dart (settings integration, startNewSession)
    - lib/features/translation/application/translation_notifier.g.dart (regenerated)
    - lib/core/l10n/app_en.arb through app_hi.arb (13 new keys each, all 10 locales)

key-decisions:
  - "targetLanguage stored as englishName string ('Spanish') for TranslationNotifier compatibility — matches existing state field"
  - "recentTargetLanguages: rolling prepend + dedup via toSet() + sublist cap at 3 — simple, no extra state machine"
  - "startNewSession() is separate from _resetSession(): public method clears KV cache; language change still calls _resetSession() internally"
  - "sessionMessagesProvider is auto-dispose StreamProvider.family — recreates per sessionId, no keepAlive needed since TranslationNotifier is keepAlive"
  - "66 languages, not 70+: model card canonical count; regional variants covered by kLanguageCountryVariants flag mapping only"

patterns-established:
  - "SupportedLanguage: const value object with ISO 639-1 code, ISO 3166-1 country code, English name"
  - "Language flag variants: kLanguageCountryVariants map checked against device Locale.countryCode at render time"
  - "settingsProvider extension: 1 new static key constant + 1 build() read + 1 setter method per new field"
  - "StreamProvider.family for reactive DB streams: @riverpod Stream<List<T>> fn(Ref ref, int id) pattern"

requirements-completed: [TRNS-02, TRNS-03, TRNS-05]

# Metrics
duration: 5min
completed: 2026-02-25
---

# Phase 05 Plan 01: Translation UI Foundation Summary

**Language data model (66 Tiny Aya languages with country flags), target language SharedPreferences persistence, TranslationNotifier settings integration + startNewSession(), sessionMessagesProvider StreamProvider.family, and 13 translation UI l10n keys across 10 locales**

## Performance

- **Duration:** 5 min
- **Started:** 2026-02-25T06:06:16Z
- **Completed:** 2026-02-25T06:11:39Z
- **Tasks:** 2
- **Files modified:** 16

## Accomplishments

- Created `SupportedLanguage` value object and `kSupportedLanguages` list with all 66 Tiny Aya model languages, sorted alphabetically with correct ISO 639-1 language codes and ISO 3166-1 country codes for flag display
- Extended `AppSettings` with `targetLanguage` (default 'Spanish', persisted via SharedPreferences) and `recentTargetLanguages` rolling list (max 3, deduped), satisfying TRNS-05
- Added `TranslationNotifier.startNewSession()` public method and wired `setTargetLanguage()` to persist to `settingsProvider`; `build()` now reads persisted language on startup
- Created `sessionMessagesProvider` as `StreamProvider.family` that wraps `ChatRepository.watchMessagesForSession()` for reactive bubble list display
- Added 13 translation UI l10n keys to all 10 ARB files with natural translations per locale

## Task Commits

Each task was committed atomically:

1. **Task 1: Language data model, country mappings, and new dependencies** - `14bfee8` (feat)
2. **Task 2: Target language persistence, TranslationNotifier extensions, session messages provider, and l10n strings** - `1ca28c6` (feat)

**Plan metadata:** _(docs commit follows)_

## Files Created/Modified

- `lib/features/translation/domain/supported_language.dart` - Immutable SupportedLanguage value object with englishName, code, primaryCountryCode
- `lib/features/translation/data/language_data.dart` - 66 kSupportedLanguages, kPopularLanguages (10), kLanguageCountryVariants, resolveCountryCode() helper
- `lib/features/translation/application/session_messages_provider.dart` - @riverpod StreamProvider.family for reactive message watching by sessionId
- `lib/features/translation/application/session_messages_provider.g.dart` - Generated SessionMessagesFamily provider
- `pubspec.yaml` - Added country_flags ^4.1.2 and flutter_localized_locales ^2.0.5
- `lib/features/settings/application/settings_provider.dart` - AppSettings.targetLanguage/recentTargetLanguages fields; Settings.setTargetLanguage() method
- `lib/features/settings/application/settings_provider.g.dart` - Regenerated after AppSettings changes
- `lib/features/translation/application/translation_notifier.dart` - Settings integration in build(), setTargetLanguage() persistence, startNewSession()
- `lib/features/translation/application/translation_notifier.g.dart` - Regenerated after notifier changes
- `lib/core/l10n/app_en.arb` through `app_hi.arb` - 13 new keys each: translate, chat, translationInputHint, translationEmptyState, newSession, targetLanguage, searchLanguages, popularLanguages, recentLanguages, copied, copyTranslation, contextFullBanner, characterLimitWarning

## Decisions Made

- **targetLanguage stored as englishName string** ('Spanish') — matches existing `TranslationState.targetLanguage` field type; no translation from code to name needed at notifier level
- **recentTargetLanguages uses prepend + toSet() + sublist(0, 3)** — simple dedup pattern; avoids duplicate 'Spanish' after selecting Spanish twice
- **startNewSession() is new public method, not alias for setTargetLanguage()** — calling setTargetLanguage with same value was a no-op; public method is the clean solution (as planned in RESEARCH.md Pitfall 6)
- **sessionMessagesProvider is auto-dispose** — TranslationNotifier is keepAlive (holds session), but the messages stream should recreate when sessionId changes; auto-dispose is correct here
- **66 languages as canonical count** — model card states 70+ but names exactly 66; kSupportedLanguages uses the 66 named languages; country variant map covers display variants without adding pseudo-languages

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None - all verification checks passed cleanly. The 27 `flutter analyze` warnings are all pre-existing issues in integration test files and tool scripts, unrelated to Phase 5 work.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- All data structures ready: `SupportedLanguage`, `kSupportedLanguages`, `kPopularLanguages`, `kLanguageCountryVariants`, `resolveCountryCode()`
- Provider wiring ready: `sessionMessagesProvider(sessionId)`, `translationNotifierProvider.notifier.startNewSession()`
- Settings persistence wired: language changes in TranslationNotifier automatically persist to SharedPreferences
- L10n strings ready: all 13 keys available via `AppLocalizations.of(context).translate`, `.chat`, `.newSession`, etc.
- Phase 5 Plans 02-04 can proceed: language picker sheet (02), translation screen (03), navigation shell (04)

## Self-Check: PASSED

| Item | Status |
|------|--------|
| lib/features/translation/domain/supported_language.dart | FOUND |
| lib/features/translation/data/language_data.dart | FOUND |
| lib/features/translation/application/session_messages_provider.dart | FOUND |
| lib/features/translation/application/session_messages_provider.g.dart | FOUND |
| .planning/phases/05-translation-ui/05-01-SUMMARY.md | FOUND |
| Commit 14bfee8 (Task 1) | FOUND |
| Commit 1ca28c6 (Task 2) | FOUND |

---
*Phase: 05-translation-ui*
*Completed: 2026-02-25*
