---
phase: 05-translation-ui
plan: "03"
subsystem: ui
tags: [flutter, language-picker, country_flags, flutter_localized_locales, clipboard, riverpod]

# Dependency graph
requires:
  - phase: 05-translation-ui
    provides: Plan 01 (language data, TranslationNotifier extensions, settings persistence) and Plan 02 (TranslationScreen, bubble list, input bar)
provides:
  - LanguagePickerSheet: DraggableScrollableSheet with search, recent chips, popular grid, and full 66-language 3-column grid
  - LanguageGridItem: flag icon + localized name tile with isSelected highlight
  - Language picker wired into TranslationScreen target language button
  - Long-press copy context menu on all translation bubbles (user and assistant)
affects: [05-translation-ui, 06-chat-ui]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - CountryFlag.fromCountryCode uses `theme: ImageTheme(width, height, shape)` not direct width/height/shape params (v4.1.2 API)
    - LocaleNames cache computed in didChangeDependencies (once per locale change) — not per build
    - DraggableScrollableSheet scroll controller passed directly to CustomScrollView with ClampingScrollPhysics to avoid scroll conflict
    - StreamingBubble gets allowCopy: false while isTranslating=true to prevent copy during generation
    - _showBubbleMenu uses SafeArea + mainAxisSize.min for minimal-height modal bottom sheet

key-files:
  created:
    - lib/features/translation/presentation/widgets/language_grid_item.dart
    - lib/features/translation/presentation/widgets/language_picker_sheet.dart
  modified:
    - lib/features/translation/presentation/translation_screen.dart
    - lib/features/translation/presentation/widgets/translation_bubble_list.dart

key-decisions:
  - "CountryFlag v4.1.2 API: ImageTheme wrapper required — CountryFlag.fromCountryCode(code, theme: ImageTheme(width: 32, height: 24, shape: RoundedRectangle(4))) not direct named params"
  - "LocaleNames cache in didChangeDependencies: avoids rebuilding Map<String,String> on every widget rebuild; triggers correctly on locale change"
  - "allowCopy: false on streaming bubble: copy disabled during active streaming to avoid copying partial text; becomes copyable once isTranslating=false and message persists to DB"
  - "GestureDetector wraps both user and assistant bubbles for long-press copy — not just assistant"
  - "Section label during search is empty string (no 'All Languages' label shown when filtering)"

patterns-established:
  - "Pattern: CountryFlag ImageTheme — use theme: ImageTheme(...) not direct named params on CountryFlag"
  - "Pattern: Localized name cache — didChangeDependencies for context-dependent expensive lookups"
  - "Pattern: DraggableScrollableSheet + CustomScrollView — pass scrollController from builder, ClampingScrollPhysics"

requirements-completed: [TRNS-02, TRNS-04]

# Metrics
duration: 4min
completed: 2026-02-25
---

# Phase 5 Plan 03: Language Picker and Clipboard Copy Summary

**DraggableScrollableSheet language picker with 3-column flag grid, search (English + localized names), popular/recent sections, and long-press clipboard copy on all translation bubbles**

## Performance

- **Duration:** 4 min
- **Started:** 2026-02-25T06:21:13Z
- **Completed:** 2026-02-25T06:25:14Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- LanguagePickerSheet fully implemented: drag handle, search bar, recent language chips (up to 3), popular section (10 pinned), full 3-column SliverGrid of 66 languages sorted alphabetically
- Search filters by both localized name (device locale via LocaleNames) and English name — case-insensitive contains match
- Country code resolution uses `resolveCountryCode(lang, deviceLocale)` for locale-appropriate flag variants (e.g., es_CO shows Colombia flag)
- TranslationScreen target language button now opens picker, calls setTargetLanguage on selection
- Long-press on any bubble (user or assistant) shows copy menu — writes to clipboard, shows "Copied" SnackBar for 1s

## Task Commits

1. **Task 1: Language picker bottom sheet with search, grid, flags, popular, and recent sections** - `656a050` (feat)
2. **Task 2: Wire language picker into TranslationScreen and add long-press copy to bubbles** - `898f65f` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `lib/features/translation/presentation/widgets/language_grid_item.dart` - StatelessWidget rendering flag (CountryFlag.fromCountryCode + ImageTheme) + localized name, isSelected highlight with AppColors.primaryContainer background
- `lib/features/translation/presentation/widgets/language_picker_sheet.dart` - ConsumerStatefulWidget; DraggableScrollableSheet content: search TextField, recent chips (from settingsProvider.recentTargetLanguages), popular SliverGrid (kPopularLanguages), full SliverGrid (kSupportedLanguages filtered by search); LocaleNames cache in didChangeDependencies
- `lib/features/translation/presentation/translation_screen.dart` - Added _showLanguagePicker, wired target language TextButton.icon to open DraggableScrollableSheet + LanguagePickerSheet; imports SupportedLanguage and language_picker_sheet
- `lib/features/translation/presentation/widgets/translation_bubble_list.dart` - Added _showBubbleMenu (showModalBottomSheet + ListTile + Clipboard.setData + SnackBar), wrapped user and assistant bubbles in GestureDetector; streaming bubble gets allowCopy: false

## Decisions Made

- **CountryFlag v4.1.2 API deviation:** Plan documentation showed `CountryFlag.fromCountryCode(code, height: 24, width: 32, shape: RoundedRectangle(4))` as named params. The actual API wraps these in `theme: ImageTheme(height: 24, width: 32, shape: RoundedRectangle(4))`. Fixed inline per Rule 1 (auto-fix bug — wrong API call would fail to compile).
- **Empty section header during search:** When searching, the "All Languages" section label is rendered as an empty string rather than hidden entirely — avoids layout shift while keeping the SliverToBoxAdapter in the sliver list.
- **GestureDetector on user bubbles:** Plan specified "also support long-press copy for user bubbles" — implemented consistently for both roles.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] CountryFlag.fromCountryCode wrong parameter API**
- **Found during:** Task 1 (LanguageGridItem creation)
- **Issue:** Plan examples used `height:`, `width:`, `shape:` as direct named parameters on `CountryFlag.fromCountryCode()`. The actual country_flags ^4.1.2 API passes these through a `theme: ImageTheme(...)` wrapper object.
- **Fix:** Changed `CountryFlag.fromCountryCode(code, height: 24, width: 32, shape: RoundedRectangle(4))` to `CountryFlag.fromCountryCode(code, theme: ImageTheme(height: 24, width: 32, shape: RoundedRectangle(4)))` in both language_grid_item.dart and language_picker_sheet.dart
- **Files modified:** language_grid_item.dart, language_picker_sheet.dart
- **Verification:** `flutter analyze lib/` passes with no issues
- **Committed in:** 656a050 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 — wrong API params)
**Impact on plan:** Critical fix — incorrect params would not compile. No scope creep.

## Issues Encountered

None beyond the CountryFlag API mismatch documented above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 5 Plan 03 complete. TRNS-02 and TRNS-04 fully satisfied.
- Remaining: Phase 5 Plan 04 (if any) or Phase 5 complete.
- Language picker is ready for Phase 6 (Chat UI) to reuse LanguagePickerSheet if needed.
- Long-press copy pattern established for translation bubbles; same pattern applicable to chat bubbles in Phase 6.

---
*Phase: 05-translation-ui*
*Completed: 2026-02-25*

## Self-Check: PASSED

- language_grid_item.dart: FOUND
- language_picker_sheet.dart: FOUND
- 05-03-SUMMARY.md: FOUND
- Commit 656a050: FOUND
- Commit 898f65f: FOUND
