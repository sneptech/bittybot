# Cross-Phase Context Repair Plan

## 1. Overview

This document is the output of a cross-phase audit conducted on 2026-02-25 across all six active phases (1--5 plus file-ownership analysis) of the BittyBot project. Six independent audit agents examined the codebase, planning documents, and runtime behavior, then reported findings.

**The core problem:** documentation drift. The actual codebase is architecturally healthy (zero merge conflicts, zero reverts, zero deleted files), but the planning documents that guide future agents have fallen behind the code. CLAUDE.md, PROJECT.md, and STATE.md contain contradictions, missing patterns, and gaps that cause new executor agents to write code based on stale assumptions.

**This plan is ordered by priority.** An executing agent should work top-to-bottom. Priorities 1--3 are documentation-only changes. Priorities 4--6 require architectural decisions or code changes. Priority 7 is a runtime investigation on a separate track.

---

## 2. Priority 1: CLAUDE.md Repairs (Critical -- Before Phase 6)

Target file: `/home/max/git/bittybot/CLAUDE.md`

### 2a. Fix Contradiction (Line 87)

**Current text (line 87):**
```
- **`appStartupProvider`** is a `@Riverpod(keepAlive: true) Future<void>` function-provider. Phase 4 extends it by adding `await ref.watch(modelReadyProvider.future)`.
```

**Problem:** Phase 4 explicitly decided NOT to await modelReadyProvider inside appStartupProvider. Instead, it implemented a "partial-access pattern" where appStartupProvider remains settings-only and the model loads independently via modelReadyProvider. This is documented in `lib/widgets/app_startup_widget.dart` lines 15--20 and in STATE.md line 96.

**Replace with:**
```
- **`appStartupProvider`** is a `@Riverpod(keepAlive: true) Future<void>` function-provider that awaits **settings only** (`settingsProvider`). The model is NOT awaited here — it loads independently via `modelReadyProvider` (partial-access pattern). Users can browse history and settings while the model loads; only the input field is disabled until `modelReadyProvider` resolves.
```

### 2b. Add "Learned Patterns (Phase 4)" Section

Insert the following section immediately after the "Learned Patterns (Phase 3)" section (after line 92). All 16 items below are documented in STATE.md lines 87--102 but are missing from CLAUDE.md entirely.

```markdown
## Learned Patterns (Phase 4)

- **Drift row types**: `ChatSession`/`ChatMessage` (not `ChatSessionData`/`ChatMessageData`). Domain types share the same names -- use `import 'app_database.dart' as db` alias in `DriftChatRepository` to disambiguate.
- **Sealed base classes need `const` constructors** for subclass `const` support -- added `const InferenceCommand()` and `const InferenceResponse()`.
- **`estimateTokenCount`**: 2 chars/token (CJK worst-case over-estimate) rather than 4 chars/token (Latin) -- catches context-full earlier.
- **Separate `_errorPort` for `Isolate.addErrorListener`**: Isolate crash sends `List<dynamic>` not `InferenceResponse` -- dedicated port keeps the listener clean.
- **Manual `nPredict` counting in `await for` loop**: `ContextParams.nPredict` is construction-time only. Model loaded once with `nPredict=-1`, counted per-request.
- **Cooperative stop via closure-scope `_stopped` flag**: Accessible from both `GenerateCommand` async handler and `StopCommand` handler on the same isolate event loop.
- **`DriftChatRepository` uses constructor injection** (not `DatabaseAccessor` subclass) for simpler Riverpod integration.
- **`insertMessage` touches parent session `updatedAt`** to bubble the session to the top of the drawer list without explicit caller coordination.
- **`appStartupProvider` remains settings-only**: Model loads independently via `modelReadyProvider` (partial-access pattern). See Phase 3 pattern above.
- **`modelReadyProvider`**: keepAlive `AsyncNotifier` with `WidgetsBindingObserver` mixin for OS-kill recovery. NOT awaited by `appStartupProvider`.
- **`inferenceRepositoryProvider`**: Throws `StateError` if accessed before `modelReadyProvider` resolves.
- **`ChatNotifier` is auto-dispose** (`@riverpod`): DB is source of truth; state reloads fresh per screen entry.
- **`TranslationNotifier` is keepAlive** (`@Riverpod(keepAlive: true)`): Language pair persists across navigation. `nPredict=128` for translation.
- **`ChatNotifier` uses `nPredict=512`** for chat mode (longer responses than translation).
- **`Queue<String>` FIFO for request queueing**: Messages queue behind active generation.
- **Language pair change resets session + `clearContext`**: Terminology consistency requires fresh KV cache per language pair.
```

### 2c. Backfill Missing Phase 3 Patterns

Seven patterns from Phase 3 are documented in STATE.md but missing from the "Learned Patterns (Phase 3)" section in CLAUDE.md. Add the following bullets to the existing section (after the current last bullet on line 92, before the new Phase 4 section):

```markdown
- **`AppStartupWidget`** is the async gate at the root: shows `ModelLoadingScreen` (loading), `AppStartupErrorScreen` (error), or `onLoaded` widget (data). Lives in `lib/widgets/app_startup_widget.dart`.
- **`ModelLoadingScreen`**: Uses `AppColors.surface` background, `colorScheme.secondary` accent, localized title/message via `l10n.modelLoadingTitle` / `l10n.modelLoadingMessage`.
- **`AppStartupErrorScreen`**: Shows retry button, calls `ref.invalidate(appStartupProvider)`. Error tone from settings determines message styling.
- **`MainShell`** is a Phase 3 placeholder showing `l10n.loading`. Phase 5 replaces content with `TranslationScreen` in the first `NavigationBar` tab.
- **Theme file organization**: 3 files in `lib/core/theme/` -- `app_colors.dart` (palette constants), `app_text_theme.dart` (Lato 16sp base), `app_theme.dart` (`buildDarkTheme()` function).
- **Settings provider**: `SharedPreferencesWithCache` in `lib/features/settings/application/settings_provider.dart`, `keepAlive: true`. Phase 5 extended from 2 fields to 4 fields.
- **l10n architecture**: 10 ARB files in `lib/core/l10n/`, started at 22 keys (Phase 3), extended to 87 keys (Phase 5). Device locale + user override. `AppLocalizations.of(context).key` for all user-visible strings.
```

### 2d. Backfill Phase 1 Key Patterns

Add only the HIGH-risk missing items to keep CLAUDE.md focused. Insert a new section after "Dart Patterns" and before "Build Configuration":

```markdown
## Learned Patterns (Phase 1)

- **llama_cpp_dart is NOT a Flutter plugin**: It does not bundle native libs automatically. `libmtmd.so` must be pre-built and placed in `android/app/src/main/jniLibs/arm64-v8a/` (or packaged as AAR) before integration tests or APK builds.
- **Integration tests use `Timeout.none`**: Model loading takes ~85s on Galaxy A25; default test timeout would fail.
- **Language corpus structure**: 4 `mustHave` languages with 18 prompts each, 66 standard languages with 3 reference sentences each. 70 total languages (66 canonical from model card + 4 must-have).
- **Judge tooling** lives in `tool/` package: 2-tier evaluation -- Claude Sonnet for quick pass/fail, Gemini Flash for full scoring. Not a Flutter package; separate Dart CLI.
- **ANR risk**: Main-thread inference blocks the UI. All inference MUST run in a dedicated isolate (enforced in Phase 4's architecture).
- **`use_mmap=false`** required for model files in Android app directories: SELinux `shell_data_file` context blocks mmap.
```

### 2e. Add Phase 5 Patterns

Insert after the new Phase 4 section:

```markdown
## Learned Patterns (Phase 5)

- **Generated provider name is `translationProvider`** (not `translationNotifierProvider`): `riverpod_generator` strips the `Notifier` suffix from the class name.
- **Word-level batching**: Space-delimited scripts (Latin, Cyrillic, Arabic, etc.) show the last complete word boundary during streaming. CJK / Thai / Lao / Khmer / Burmese use token-by-token display (no word boundaries).
- **`CountryFlag` v4.1.2**: `ImageTheme` wrapper required for `width` / `height` / `shape` params in `fromCountryCode()`.
- **`LocaleNames` cache in `didChangeDependencies`**: Avoids per-build recompute; triggers on locale change.
- **`allowCopy: false` on streaming bubble**: Copy disabled during active streaming to avoid partial text in clipboard.
- **66 languages canonical count**: Model card names exactly 66; country variants handled via `kLanguageCountryVariants` flag map.
- **`startNewSession()`** is a separate public method on `TranslationNotifier` (not an alias for `setTargetLanguage` with the same language, which was a no-op).
- **`sessionMessagesProvider`**: Auto-dispose `StreamProvider.family` -- `TranslationNotifier` is keepAlive but the stream should recreate per `sessionId` change.
- **`targetLanguage` stored as `englishName` string** (e.g., `'Spanish'`): Matches existing `TranslationState.targetLanguage` field; no code-to-name mapping needed at notifier level.
```

### 2f. Update Build Configuration

Replace the current Build Configuration section (lines 64--68) with:

```markdown
## Build Configuration

- **Android NDK:** pinned to 29.0.14033849 (16KB page alignment, Play Store mandatory May 2026)
- **iOS:** platform 14.0, Extended Virtual Addressing entitlement, Metal framework, no simulator builds
- **Model params (spike):** nCtx=512, nBatch=256, nPredict=128 -- minimal footprint for Phase 1 spike only
- **Model params (production):** nPredict varies by mode: chat=512, translation=128. nCtx and nBatch to be tuned with real device testing.
- **Native lib deployment:** `libmtmd.so` goes to `android/app/src/main/jniLibs/arm64-v8a/`. NOT auto-bundled -- see Phase 1 patterns.
```

---

## 3. Priority 2: PROJECT.md Key Decisions Table (High -- Before Phase 6)

Target file: `/home/max/git/bittybot/.planning/PROJECT.md`

The Key Decisions table currently has only 5 pre-project entries. Each completed phase made significant architectural decisions that are not recorded. Add the following rows to the table.

### Phase 1 Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| llama_cpp_dart ^0.2.2 as inference binding | Most recently updated, tracks llama.cpp master, FFI bindings match | Validated |
| Native lib pre-built as AAR (not plugin auto-bundle) | llama_cpp_dart is not a Flutter plugin; must manually compile and deploy libmtmd.so | Validated |
| 70-language evaluation corpus (4 mustHave + 66 standard) | Covers model card languages; mustHave languages get deeper evaluation | Validated |

### Phase 2 Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| 11-state sealed class for download flow | Exhaustive switch covers all download lifecycle states; compiler catches missing handlers | Validated |
| Chunked SHA-256 in compute() isolate | 2.14 GB model cannot be loaded into RAM for hashing; 64KB RandomAccessFile chunks in background isolate | Validated |
| background_downloader with registerCallbacks()+enqueue() | Full TaskProgressUpdate with speed/ETA (not download() which gives void Function(double) only) | Validated |
| Completer<TaskStatusUpdate> bridge pattern | Bridges registerCallbacks async API into clean await pattern | Validated |

### Phase 3 Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Dark theme only (no light variant) | User preference; Cohere-inspired green palette; ThemeMode.dark forced | Validated |
| Offline fonts via GoogleFonts.config.allowRuntimeFetching = false | App must work with zero connectivity; fonts bundled in assets/google_fonts/ | Validated |
| 10 supported UI locales (not all 66 model languages) | UI strings need manual translation; 10 covers primary user needs. Model handles 66 for inference. | Validated |
| Manual ColorScheme() constructor (not fromSeed) | fromSeed generates tonal palette that overrides exact brand hex values | Validated |
| Error tone feature (resolveErrorMessage with Dart 3 record pattern switch) | Exhaustive (AppError, ErrorTone) switch; compiler catches missing combinations | Validated |

### Phase 4 Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Partial-access pattern: appStartupProvider awaits settings only | Users can browse history while model loads; only input disabled until model ready | Validated |
| Dedicated inference isolate (never main thread) | Prevents ANR; FFI llama.cpp instance owned entirely by isolate | Validated |
| DriftChatRepository with constructor injection (not DatabaseAccessor) | Simpler Riverpod integration; avoids tight coupling to Drift internals | Validated |
| Model loaded with nPredict=-1, counted manually per request | ContextParams.nPredict is construction-time only; per-request counting allows chat=512, translation=128 | Validated |
| Cooperative stop via closure-scope flag (not isolate kill) | Preserves KV cache and model state; avoids expensive reload | Validated |
| TranslationNotifier keepAlive vs ChatNotifier auto-dispose | Translation language pair persists across navigation; chat reloads from DB each screen entry | Validated |

### Phase 5 Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| targetLanguage as englishName string (not language code) | Matches model prompt format; no mapping layer needed in notifier | Validated |
| Word-level vs token-level streaming by script family | Space-delimited scripts get word-boundary batching; CJK/Thai/etc. use token-by-token (no word boundaries) | Validated |
| 66 canonical languages with country-variant flag map | Matches model card exactly; kLanguageCountryVariants maps language to flag for display | Validated |

Also update the "Last updated" line at the bottom of PROJECT.md to reflect the current date.

---

## 4. Priority 3: STATE.md Corrections (Medium)

Target file: `/home/max/git/bittybot/.planning/STATE.md`

### 4a. NDK Version Transcription Error

**Line 64 currently reads:**
```
- Android NDK pinned to 28.0.12674087, compileSdk=36, ndkVersion=29.0.14033849
```

This contains two NDK version numbers. The actual NDK version is `29.0.14033849` (confirmed in CLAUDE.md line 66 and the Android build config). The `28.0.12674087` reference is incorrect.

**Replace with:**
```
- Android NDK pinned to 29.0.14033849, compileSdk=36
```

### 4b. Phase 5 Status Update

Line 13 says "1/4 plans complete" but lines 26 and 14 say "Plans 01-03 complete" and "Plan 03 complete" respectively. Update line 13 to:
```
Status: Phase 5 in progress (3/4 plans complete, Plan 04 paused at human verification)
```

### 4c. GSD Reference Cleanup

The document still references "GSD" in some places (line 5: "See: .planning/PROJECT.md (updated 2026-02-19)"). This is not a critical fix but should be noted for a future pass. The project migrated from GSD to MOW (Mowism) on 2026-02-25.

---

## 5. Priority 4: Download Flow Integration (Architectural Decision Required)

**This section requires a decision from the user. The executing agent should NOT make this change unilaterally.**

### Current State

Phase 2 built a complete first-launch download flow:
- `ModelDistributionNotifier` with 11-state sealed class (`CheckingModelState`, `PreflightState`, `ResumePromptState`, `CellularWarningState`, `InsufficientStorageState`, `DownloadingState`, `VerifyingState`, `LowMemoryWarningState`, `LoadingModelState`, `ModelReadyState`, `ErrorState`)
- `DownloadScreen` widget in `lib/features/model_distribution/widgets/download_screen.dart`
- `CellularWarningDialog` and `ResumePromptDialog`
- SHA-256 verification, storage preflight, resume support

Phase 3 replaced Phase 2's app.dart routing with `AppStartupWidget`, which gates on `appStartupProvider` (settings only) then shows `MainShell`. The merge log (STATE.md line 168) explicitly notes: "Phase 2's model distribution routing deferred to Phase 4 wiring."

**Phase 4 did NOT wire the download flow.** It implemented `modelReadyProvider` and `inferenceRepositoryProvider` but these assume the model file already exists on disk. There is no code path that calls `ModelDistributionNotifier.initialize()`.

### Result

- `DownloadScreen` is orphaned (never imported outside its own package)
- `ModelDistributionNotifier.initialize()` is never called
- First-launch download is completely non-functional
- The app will fail on a fresh install (no model file)

### Options for the User

**Option A: Wire Phase 2 into AppStartupWidget (recommended)**
- Add a model-existence check to `appStartupProvider` or add a separate gate before `AppStartupWidget`
- If model not present: show `DownloadScreen` (with design system colors updated)
- If model present: proceed to `AppStartupWidget` -> `MainShell`
- `ModelDistributionNotifier.initialize()` called from the download gate
- Estimated effort: 1 plan, medium complexity

**Option B: Build a new download gate in AppStartupWidget**
- Extend `appStartupProvider` to also check for model file existence
- Add a third state (downloading) to the `AppStartupWidget` loading/error/data switch
- Reuse `ModelDistributionNotifier` but replace `DownloadScreen` widget with a new one using the design system
- Estimated effort: 1 plan, medium complexity

**Option C: Defer to a later phase**
- Document that first-launch download is broken and will be fixed before release
- Continue Phase 6 (Chat UI) and Phase 7+ assuming model is sideloaded via adb for development
- Fix before any user-facing testing
- Risk: compounds technical debt; every future tester must sideload the model

### Note on DownloadScreen Colors

Regardless of which option is chosen, `DownloadScreen` uses hardcoded placeholder colors (`Color(0xFF2D6A4F)`, `Color(0xFF121212)`, etc.) with `// TODO(phase-3)` comments. If Option A or B reuses `DownloadScreen`, these must be replaced with `AppColors` constants from the Phase 3 design system.

---

## 6. Priority 5: Orphaned Code Cleanup (Low)

These are minor code quality issues found by the audit. They do not affect functionality but should be cleaned up before release.

### 6a. DownloadScreen Placeholder Colors

**File:** `lib/features/model_distribution/widgets/download_screen.dart`
**Lines 14--23:** Four hardcoded color constants with `// TODO(phase-3)` comments.

Replace:
```dart
const _kBackground = Color(0xFF121212); // TODO(phase-3): Replace with design system color
const _kForestGreen = Color(0xFF2D6A4F); // TODO(phase-3): Replace with design system color
const _kTextPrimary = Colors.white; // TODO(phase-3): Replace with design system color
const _kTextSecondary = Color(0xFFB0B0B0); // TODO(phase-3): Replace with design system color
```

With imports from the design system:
```dart
import '../../core/theme/app_colors.dart';
```

And replace usages:
- `_kBackground` -> `AppColors.surface`
- `_kForestGreen` -> `AppColors.primaryGreen` (or whichever matches the design system's primary action color)
- `_kTextPrimary` -> `AppColors.onSurface`
- `_kTextSecondary` -> `AppColors.onSurfaceVariant`

The executing agent should read `lib/core/theme/app_colors.dart` to find the exact constant names.

### 6b. Phase 2 Debug Print Statement

**File:** `lib/features/model_distribution/model_distribution_notifier.dart`
**Line ~301:** A `print()` call left in for debugging.

Remove the print statement. If logging is needed, use a proper logger or leave a comment explaining why it was removed.

### 6c. Deprecated Color API in Tests

**File:** `test/core/theme/app_theme_test.dart`
**Issue:** Uses deprecated `.red` / `.green` / `.blue` getters on `Color`.

Replace with the non-deprecated API. In modern Flutter, use `.r`, `.g`, `.b` (which return `double` 0.0--1.0) or the appropriate replacement per the deprecation notice in the Flutter SDK.

### 6d. DownloadScreen Logo Placeholder

**File:** `lib/features/model_distribution/widgets/download_screen.dart`
**Lines 104--112:** `_buildLogo()` returns a grey `Icons.smart_toy` placeholder with a TODO comment referencing Phase 3.

If the bittybot logo asset exists in the project, replace the placeholder with the actual `Image.asset()` call. If it does not exist (the audit noted the logo may have been lost), this should be deferred until the logo is confirmed present.

---

## 7. Priority 6: "Wrong Screen" Bug Investigation (Separate Track)

This is a runtime bug observed during Phase 5 human verification. It is independent of the documentation repairs above and should be investigated on a separate track.

### Observed Behavior

The app displays a blank white window with "BittyBot - Phase 1 Inference Spike" text in a bluish header bar, instead of the Translation UI (Phase 5).

### What the Code Says Should Happen

1. `main.dart` -> `ProviderScope(child: BittyBotApp())`
2. `app.dart` -> `MaterialApp(home: AppStartupWidget(onLoaded: (_) => const MainShell()))`
3. `AppStartupWidget` watches `appStartupProvider` (settings only)
4. On `loading`: shows `ModelLoadingScreen` (dark green background with "BittyBot" in lime accent, localized loading message, circular progress indicator)
5. On `data`: shows `MainShell` (Translation UI as of Phase 5)
6. On `error`: shows `AppStartupErrorScreen`

### The "Phase 1 Inference Spike" Text Does Not Exist in Current Code

The `ModelLoadingScreen` shows "BittyBot" as static text and `l10n.modelLoadingTitle` / `l10n.modelLoadingMessage` from localizations. There is no "Phase 1 Inference Spike" string anywhere in the current `lib/` code. This suggests one of:

### Investigation Steps (Ranked by Probability)

**1. Cached old APK on device (MOST LIKELY)**
- The device may be running an old build from Phase 1 that was not replaced
- Fix: `flutter clean && flutter build apk --debug` then reinstall
- Check: `adb shell pm dump com.sneptech.bittybot | grep versionCode`

**2. SharedPreferences corruption**
- `settingsProvider` uses `SharedPreferencesWithCache`; if the cache is corrupt, `appStartupProvider` may hang in loading state forever
- Fix: Clear app data on device (`adb shell pm clear com.sneptech.bittybot`)
- Check: Add debug logging to `appStartupProvider` to trace resolution

**3. appStartupProvider stuck in loading state**
- If `settingsProvider.future` never completes (e.g., `SharedPreferencesWithCache.create()` throws), the app will stay on `ModelLoadingScreen` indefinitely
- But `ModelLoadingScreen` uses the dark green theme, not a white background with blue header -- so this would not explain the observed screen
- Check: Read `lib/features/settings/application/settings_provider.dart` and trace the initialization path

**4. A different Activity or build variant**
- The Android manifest may have a different launcher activity from Phase 1 that was never removed
- Check: `android/app/src/main/AndroidManifest.xml` for the LAUNCHER intent filter

**5. Flutter hot-reload artifact**
- If the device was running a hot-reloaded session from an earlier phase, the widget tree may be stale
- Fix: Full stop and cold start (`flutter run` not `flutter attach`)

### Recommended First Step

Run a clean build and fresh install:
```bash
cd /home/max/git/bittybot
/home/max/Android/flutter/bin/flutter clean
/home/max/Android/flutter/bin/flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

If the problem persists after a clean install, proceed to investigation step 2 (clear app data) and step 4 (check AndroidManifest).

---

## 8. Verification Checklist

The executing agent should check off each item after completing the repair. Items are grouped by priority.

### Priority 1: CLAUDE.md Repairs

- [ ] Line 87 contradiction fixed: `appStartupProvider` documented as settings-only with partial-access pattern explanation
- [ ] "Learned Patterns (Phase 4)" section added with all 16 bullet points
- [ ] 7 missing Phase 3 patterns backfilled into "Learned Patterns (Phase 3)" section
- [ ] "Learned Patterns (Phase 1)" section added with 6 key patterns
- [ ] "Learned Patterns (Phase 5)" section added with 9 patterns
- [ ] "Build Configuration" section updated with production model params and native lib deployment note
- [ ] All new sections are in correct order: Phase 1, Phase 2, Phase 3, Phase 4, Phase 5

### Priority 2: PROJECT.md Key Decisions

- [ ] Phase 1 decisions added (3 rows)
- [ ] Phase 2 decisions added (4 rows)
- [ ] Phase 3 decisions added (5 rows)
- [ ] Phase 4 decisions added (6 rows)
- [ ] Phase 5 decisions added (3 rows)
- [ ] "Last updated" date changed to current date

### Priority 3: STATE.md Corrections

- [ ] Line 64 NDK version fixed (removed `28.0.12674087` reference)
- [ ] Line 13 Phase 5 status updated to "3/4 plans complete"

### Priority 4: Download Flow Integration

- [ ] User has been presented with Options A/B/C and made a decision
- [ ] Decision is documented in PROJECT.md Key Decisions table
- [ ] If Option A or B: implementation plan created
- [ ] If Option C: documented as known technical debt in STATE.md Pending Todos

### Priority 5: Orphaned Code Cleanup

- [ ] DownloadScreen placeholder colors replaced with AppColors constants
- [ ] Debug print() removed from model_distribution_notifier.dart
- [ ] Deprecated Color API updated in app_theme_test.dart
- [ ] DownloadScreen logo placeholder addressed (replaced or documented)

### Priority 6: "Wrong Screen" Bug

- [ ] Clean build + fresh install tested on device
- [ ] If still broken: app data cleared and retested
- [ ] If still broken: AndroidManifest checked for stale launcher activity
- [ ] Root cause documented in STATE.md

---

*Generated 2026-02-25 from cross-phase audit findings. This document is consumed by future Claude Code agents and should be kept until all items are resolved, then archived.*
