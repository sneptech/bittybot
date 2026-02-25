---
phase: 05-translation-ui
plan: "02"
subsystem: ui
tags: [flutter, dart, riverpod, translation, chat-bubbles, animation, navigation]

# Dependency graph
requires:
  - phase: 05-translation-ui
    plan: "01"
    provides: translationProvider (generated as 'translationProvider' not 'translationNotifierProvider'), sessionMessagesProvider, l10n keys (translate, chat, translationEmptyState, translationInputHint, newSession, contextFullBanner, characterLimitWarning)
  - phase: 04-core-inference-architecture
    provides: TranslationNotifier with translate/stopTranslation/startNewSession, TranslationState with isTranslating/translatedText/isContextFull/isModelReady/activeSession/targetLanguage

provides:
  - MainShell: ConsumerStatefulWidget NavigationBar shell with IndexedStack (TranslationScreen at index 0, Chat placeholder at index 1)
  - TranslationScreen: Full scaffold with AppBar (target language TextButton placeholder + new session button), context-full banner, bubble list, input bar
  - TranslationBubbleList: Chat-style bubble list with DB messages + streaming bubble, word-level batching, typing indicator integration, auto-scroll
  - TranslationInputBar: Multi-line TextField (1-6 lines), send/stop AnimatedSwitcher toggle, soft character limit warning (400+/500+)
  - TypingIndicator: iMessage-style 3 pulsing dots with staggered AnimationController (1200ms repeat)
  - LocaleNamesLocalizationsDelegate wired in app.dart

affects:
  - 05-03 (language picker bottom sheet — plugs into TranslationScreen AppBar target language button)
  - 06-01 (chat UI — MainShell IndexedStack index 1 placeholder becomes ChatScreen)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - TypingIndicator: StatefulWidget with single AnimationController, 3 staggered Interval tweens, sin(pi*t) color pulse
    - Word-level batching: _isSpaceDelimited() regex check for CJK/Thai/Lao/Khmer/Burmese; lastIndexOf whitespace boundary
    - Auto-scroll: addPostFrameCallback + 100px proximity guard to not interrupt user scroll-up
    - Send/Stop toggle: ValueListenableBuilder on TextEditingController + AnimatedSwitcher with ValueKey for smooth transition
    - ConsumerStatefulWidget NavigationBar shell with IndexedStack keeps screens alive across tab switches

key-files:
  created:
    - lib/features/translation/presentation/translation_screen.dart
    - lib/features/translation/presentation/widgets/translation_bubble_list.dart
    - lib/features/translation/presentation/widgets/translation_input_bar.dart
    - lib/features/translation/presentation/widgets/typing_indicator.dart
  modified:
    - lib/widgets/main_shell.dart (replaced placeholder with NavigationBar ConsumerStatefulWidget)
    - lib/app.dart (added LocaleNamesLocalizationsDelegate)

key-decisions:
  - "Generated provider name is 'translationProvider' (not 'translationNotifierProvider') — riverpod_generator strips 'Notifier' suffix from class name 'TranslationNotifier'"
  - "Target language button is TextButton placeholder (onPressed: null) — Plan 03 will wire the language picker"
  - "TranslationScreen is ConsumerWidget (not ConsumerStatefulWidget) — no local state needed; scrollController lives in TranslationBubbleList"
  - "Word-level batching: show up to last whitespace during streaming for space-delimited scripts; token-by-token for CJK/Thai"
  - "Auto-scroll uses 100px proximity guard: respects user scroll-up, resumes auto-scroll when user scrolls back to bottom"

patterns-established:
  - "Riverpod naming: @Riverpod class TranslationNotifier generates 'translationProvider' (class name minus 'Notifier' + 'Provider')"
  - "TypingIndicator: isVisible prop controls animate/stop; parent derives from state.isTranslating && state.translatedText.isEmpty"
  - "Input bar: SafeArea(bottom: true) inside widget, not wrapping from outside — self-contained keyboard avoidance"
  - "NavigationBar shell: ConsumerStatefulWidget for _selectedIndex; IndexedStack keeps screens alive across tabs"

requirements-completed: [TRNS-01, TRNS-03]

# Metrics
duration: 4min
completed: 2026-02-25
---

# Phase 05 Plan 02: Translation UI Core Summary

**NavigationBar shell with IndexedStack, chat-style TranslationScreen with streaming bubble list (word-level batching, auto-scroll), iMessage typing indicator, and multi-line send/stop input bar**

## Performance

- **Duration:** 4 min
- **Started:** 2026-02-25T06:14:41Z
- **Completed:** 2026-02-25T06:18:11Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Replaced `MainShell` placeholder with `ConsumerStatefulWidget` `NavigationBar` shell using `IndexedStack` — keeps `TranslationScreen` alive when switching to the Chat placeholder tab
- Created `TranslationScreen` with `AppBar` (target language `TextButton` placeholder for Plan 03 language picker, `startNewSession` button), context-full banner from `AppColors.secondaryContainer`, and `resizeToAvoidBottomInset` keyboard avoidance
- Created `TranslationBubbleList` with: reactive DB messages from `sessionMessagesProvider`, streaming assistant bubble with word-level batching (CJK/Thai/Lao/Khmer/Burmese = token-by-token, Latin/Arabic/etc. = last complete word boundary), `TypingIndicator` when `isTranslating && translatedText.isEmpty`, auto-scroll with 100px proximity guard
- Created `TranslationInputBar` with: `minLines: 1 / maxLines: 6` expandable `TextField`, `TextInputAction.newline` (send is button-only), `AnimatedSwitcher` send/stop toggle, soft character limit counter at 400+ / error color at 500+
- Created `TypingIndicator` — iMessage-style 3 pulsing dots with staggered `Interval` curves (0.0-0.5, 0.2-0.7, 0.4-0.9), `sin(pi*t)` color lerp between dim and bright `AppColors.onSurfaceVariant`
- Added `LocaleNamesLocalizationsDelegate()` to `app.dart` for `flutter_localized_locales` support

## Task Commits

Each task was committed atomically:

1. **Task 1: Navigation shell and typing indicator** - `30e6a62` (feat)
2. **Task 2: Translation screen, bubble list, and input bar** - `0c76536` (feat)

**Plan metadata:** _(docs commit follows)_

## Files Created/Modified

- `lib/widgets/main_shell.dart` — Replaced StatelessWidget placeholder with ConsumerStatefulWidget NavigationBar shell (IndexedStack, Translate + Chat tabs)
- `lib/app.dart` — Added LocaleNamesLocalizationsDelegate to localizationsDelegates list
- `lib/features/translation/presentation/typing_indicator.dart` — iMessage-style 3-dot pulsing animated indicator, staggered Interval AnimationController
- `lib/features/translation/presentation/translation_screen.dart` — Full scaffold: AppBar (language placeholder + new session), context-full banner, TranslationBubbleList, TranslationInputBar
- `lib/features/translation/presentation/widgets/translation_bubble_list.dart` — ListView.builder with DB messages + streaming bubble + typing indicator; word-level batching; auto-scroll
- `lib/features/translation/presentation/widgets/translation_input_bar.dart` — Multi-line TextField, send/stop AnimatedSwitcher, soft character limit counter

## Decisions Made

- **`translationProvider` not `translationNotifierProvider`** — riverpod_generator derives provider name from class: `TranslationNotifier` → `translationProvider` (strips 'Notifier', lowercases first char). Plan had the conventional name wrong; fixed as Rule 1 auto-fix.
- **Target language button is `onPressed: null` placeholder** — Plan explicitly says wire in Plan 03; using null disables the button and shows visual affordance without crashing.
- **`TranslationScreen` is `ConsumerWidget`** — all local state (ScrollController, TextEditingController) lives in its child widgets; no local state needed at screen level.
- **`SafeArea` inside `TranslationInputBar`** — self-contained keyboard avoidance; screen doesn't need to know about it.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Wrong provider name: 'translationNotifierProvider' → 'translationProvider'**
- **Found during:** Task 2 (flutter analyze after creating translation_screen.dart)
- **Issue:** Plan spec used `translationNotifierProvider` but riverpod_generator generates `translationProvider` for class `TranslationNotifier`. The generated file at `translation_notifier.g.dart` line 29 defines `final translationProvider = TranslationNotifierProvider._()`.
- **Fix:** Replaced all 7 occurrences of `translationNotifierProvider` with `translationProvider` across translation_screen.dart, translation_bubble_list.dart, and translation_input_bar.dart.
- **Files modified:** All 3 new presentation files
- **Verification:** `flutter analyze` passed with 0 errors after fix
- **Committed in:** `0c76536` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 Rule 1 — bug)
**Impact on plan:** Auto-fix was essential for compilation. No scope creep — provider name correction only.

## Issues Encountered

None beyond the provider name auto-fix above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `TranslationScreen` AppBar target language `TextButton` has `onPressed: null` — Plan 03 (language picker bottom sheet) wires this to open the picker
- `MainShell` IndexedStack index 1 is a centered `Text(l10n.chat)` placeholder — Phase 6 (Chat UI) replaces this with `ChatScreen`
- All `EdgeInsetsDirectional` throughout — RTL-ready
- All user-visible strings use `AppLocalizations` — fully localised

## Self-Check: PASSED

| Item | Status |
|------|--------|
| lib/widgets/main_shell.dart | FOUND |
| lib/app.dart | FOUND |
| lib/features/translation/presentation/translation_screen.dart | FOUND |
| lib/features/translation/presentation/widgets/translation_bubble_list.dart | FOUND |
| lib/features/translation/presentation/widgets/translation_input_bar.dart | FOUND |
| lib/features/translation/presentation/widgets/typing_indicator.dart | FOUND |
| .planning/phases/05-translation-ui/05-02-SUMMARY.md | FOUND |
| Commit 30e6a62 (Task 1) | FOUND |
| Commit 0c76536 (Task 2) | FOUND |

---
*Phase: 05-translation-ui*
*Completed: 2026-02-25*
