# BittyBot

Fully offline multilingual chat and translation app for travelers, powered by Cohere Tiny Aya Global 3.35B on-device via llama.cpp. Built with Flutter.

## GSD Commands

This project uses GSD for structured development. Key commands:

- `/gsd:progress` — Check project status and next action
- `/gsd:discuss-phase N` — Gather context before planning a phase
- `/gsd:plan-phase N` — Create detailed execution plan for a phase
- `/gsd:execute-phase N` — Execute all plans in a phase
- `/gsd:resume-work` — Resume from previous session
- `/gsd:help` — Full command reference

## Parallel Phase Execution

Independent phases run simultaneously via git worktrees. See `.planning/PARALLEL-EXECUTION.md` for the full workflow. Scripts: `scripts/wt-phase.fish`, `scripts/wt-merge.fish`.

**Worktree rules** (when working in a worktree):

1. **Stay on your branch.** Do not checkout, merge, or rebase. GSD commits to whatever branch is checked out — that's your phase branch.
2. **Own your phase directory only.** Only modify files under your phase's `.planning/phases/NN-*/` directory. Do not edit other phases' planning files.
3. **Shared state files are read-only.** Do not manually edit `.planning/STATE.md` or `.planning/ROADMAP.md` — these get reconciled during merge.
4. **Source code is yours to write.** Create and modify `lib/`, `test/`, `pubspec.yaml`, etc. as needed. Conflicts with parallel phases are resolved at merge time.

## Phase Dependency Graph

```
Phase 1: Inference Spike
  ├── Phase 2: Model Distribution        ← can run parallel with Phase 3
  ├── Phase 3: App Foundation             ← can run parallel with Phase 2
  └── Phase 4: Core Inference Arch        ← requires Phase 2 AND Phase 3
        ├── Phase 5: Translation UI       ← can run parallel with Phase 6
        ├── Phase 6: Chat UI              ← can run parallel with Phase 5
        │     ├── Phase 7: Chat History   ← can run parallel with Phase 9
        │     └── Phase 9: Web Search     ← can run parallel with Phase 7
        └── Phase 8: Chat Settings        ← requires Phase 7
```

Parallel windows:
- **After Phase 1:** Phase 2 || Phase 3
- **After Phase 4:** Phase 5 || Phase 6
- **After Phase 6:** Phase 7 || Phase 9

## Code Conventions

- **Language:** Dart / Flutter
- **State management:** Riverpod
- **Local DB:** Drift (SQLite)
- **Inference:** llama.cpp via llama_cpp_dart ^0.2.2
- **Testing:** TDD — write tests before implementation
- **Commits:** Atomic, one logical change per commit
- **Flutter binary:** `/home/max/Android/flutter/bin/flutter` (not in PATH in Claude Code)

## Dart Patterns

- Import `dart:io` as `io` prefix when `googleai_dart` is also imported (File class collision)
- Import `googleai_dart` as `gai` prefix to avoid type ambiguity
- Use `Model.modelId('model-name')` string form when `anthropic_sdk_dart` enum doesn't include newer models
- Anthropic `MessageContent` is a sealed class — use Dart pattern matching, not `.whereType<>()`
- Aya chat template: `<|START_OF_TURN_TOKEN|><|USER_TOKEN|>...<|END_OF_TURN_TOKEN|><|START_OF_TURN_TOKEN|><|CHATBOT_TOKEN|>`

## Learned Patterns (Phase 1)

- **llama_cpp_dart is NOT a Flutter plugin**: It does not bundle native libs automatically. `libmtmd.so` must be pre-built and placed in `android/app/src/main/jniLibs/arm64-v8a/` (or packaged as AAR) before integration tests or APK builds.
- **Integration tests use `Timeout.none`**: Model loading takes ~85s on Galaxy A25; default test timeout would fail.
- **Language corpus structure**: 4 `mustHave` languages with 18 prompts each, 66 standard languages with 3 reference sentences each. 70 total languages (66 canonical from model card + 4 must-have).
- **Judge tooling** lives in `tool/` package: 2-tier evaluation -- Claude Sonnet for quick pass/fail, Gemini Flash for full scoring. Not a Flutter package; separate Dart CLI.
- **ANR risk**: Main-thread inference blocks the UI. All inference MUST run in a dedicated isolate (enforced in Phase 4's architecture).
- **`use_mmap=true`** is now enabled for model files in app data directories (`/data/user/0/.../files/models/`) with correct SELinux context. # NOTE: mmap now enabled — model lives in app data dir with correct SELinux context.

## Build Configuration

- **Android NDK:** pinned to 29.0.14033849 (16KB page alignment, Play Store mandatory May 2026)
- **iOS:** platform 14.0, Extended Virtual Addressing entitlement, Metal framework, no simulator builds
- **Model params (spike):** nCtx=512, nBatch=256, nPredict=128 -- minimal footprint for Phase 1 spike only
- **Model params (production):** nPredict varies by mode: chat=512, translation=128. nCtx and nBatch to be tuned with real device testing.
- **Native lib deployment:** `libmtmd.so` goes to `android/app/src/main/jniLibs/arm64-v8a/`. NOT auto-bundled -- see Phase 1 patterns.

## Learned Patterns (Phase 2)

- **Do NOT use `ColorFiltered` with `BlendMode.saturation`** for greyscale effects — Flutter bug #179606 greyscales the entire screen. Use two separate image assets with `AnimatedCrossFade` instead.
- **`background_downloader`**: Use `registerCallbacks()+enqueue()` not `download()` — `download()` only provides `void Function(double)` for progress, not full `TaskProgressUpdate` with speed/ETA.
- **Riverpod dialog pattern**: Use `ConsumerStatefulWidget` with a `_dialogVisible` bool to prevent dialogs from double-showing on state rebuild.
- **Chunked SHA-256**: Use `AccumulatorSink` from `package:convert` (not `dart:convert`) with 64KB `RandomAccessFile` chunks in a `compute()` isolate — never load the full file into RAM.
- **Feature structure**: Model distribution code lives under `lib/features/model_distribution/` with `widgets/` subdirectory for UI components.

## Learned Patterns (Phase 3)

- **flutter_riverpod pinned to 3.1.0** (not 3.2.1): `riverpod_generator 4.0.1+` requires `analyzer ^9.0.0` which conflicts with `flutter_test`'s `test_api` pin in Flutter 3.38.5. Use `riverpod_generator: ^4.0.0` (resolves to 4.0.0+1).
- **`AsyncValue.value` not `.valueOrNull`**: `.valueOrNull` does not exist on `AsyncValue` in Riverpod 3.1.0. Use `.value` which returns `T?`.
- **`synthetic-package` removed from l10n.yaml**: Deprecated in Flutter 3.38.5; always generates to source now.
- **`ColorScheme.fromSeed` NOT used**: `fromSeed` generates a tonal palette that overrides exact brand hex values. Use the manual `ColorScheme()` constructor to lock in specific colours.
- **`GoogleFonts.config.allowRuntimeFetching = false`** in `main()`: Offline-first — fonts must be bundled in `assets/google_fonts/`, never fetched from network.
- **`TestWidgetsFlutterBinding.ensureInitialized()`** required in `setUpAll` for non-widget tests that call `GoogleFonts` (touches `ServicesBinding`).
- **`EdgeInsetsDirectional` everywhere** (not `EdgeInsets`): RTL-ready pattern for Arabic and other RTL locales. Established in all widget files.
- **`appStartupProvider`** is a `@Riverpod(keepAlive: true) Future<void>` function-provider that awaits **settings only** (`settingsProvider`). The model is NOT awaited here — it loads independently via `modelReadyProvider` (partial-access pattern). Users can browse history and settings while the model loads; only the input field is disabled until `modelReadyProvider` resolves.
- **Error messages flow through `resolveErrorMessage()`**: Exhaustive Dart 3 record pattern switch on `(AppError, ErrorTone)` — compiler catches missing combinations.
- **Locale persisted as `languageCode` string only** (e.g., `'ar'`): Sufficient for the 10 supported locales.
- **Theme files:** `lib/core/theme/app_colors.dart` (palette), `app_text_theme.dart` (Lato 16sp), `app_theme.dart` (buildDarkTheme).
- **Localization:** 10 ARB files in `lib/core/l10n/`, 22 keys each. `AppLocalizations.of(context).key` for all user-visible strings.
- **Settings:** `lib/features/settings/application/settings_provider.dart` — `SharedPreferencesWithCache`, `keepAlive: true`.
- **`AppStartupWidget`** is the async gate at the root: shows `ModelLoadingScreen` (loading), `AppStartupErrorScreen` (error), or `onLoaded` widget (data). Lives in `lib/widgets/app_startup_widget.dart`.
- **`ModelLoadingScreen`**: Uses `AppColors.surface` background, `colorScheme.secondary` accent, localized title/message via `l10n.modelLoadingTitle` / `l10n.modelLoadingMessage`.
- **`AppStartupErrorScreen`**: Shows retry button, calls `ref.invalidate(appStartupProvider)`. Error tone from settings determines message styling.
- **`MainShell`** is a Phase 3 placeholder showing `l10n.loading`. Phase 5 replaces content with `TranslationScreen` in the first `NavigationBar` tab.
- **Theme file organization**: 3 files in `lib/core/theme/` -- `app_colors.dart` (palette constants), `app_text_theme.dart` (Lato 16sp base), `app_theme.dart` (`buildDarkTheme()` function).
- **Settings provider**: `SharedPreferencesWithCache` in `lib/features/settings/application/settings_provider.dart`, `keepAlive: true`. Phase 5 extended from 2 fields to 4 fields.
- **l10n architecture**: 10 ARB files in `lib/core/l10n/`, started at 22 keys (Phase 3), extended to 87 keys (Phase 5). Device locale + user override. `AppLocalizations.of(context).key` for all user-visible strings.

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
