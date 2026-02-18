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

## Build Configuration

- **Android NDK:** pinned to 29.0.14033849 (16KB page alignment, Play Store mandatory May 2026)
- **iOS:** platform 14.0, Extended Virtual Addressing entitlement, Metal framework, no simulator builds
- **Model params (spike):** nCtx=512, nBatch=256, nPredict=128 — production will need higher values

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
- **`appStartupProvider`** is a `@Riverpod(keepAlive: true) Future<void>` function-provider. Phase 4 extends it by adding `await ref.watch(modelReadyProvider.future)`.
- **Error messages flow through `resolveErrorMessage()`**: Exhaustive Dart 3 record pattern switch on `(AppError, ErrorTone)` — compiler catches missing combinations.
- **Locale persisted as `languageCode` string only** (e.g., `'ar'`): Sufficient for the 10 supported locales.
- **Theme files:** `lib/core/theme/app_colors.dart` (palette), `app_text_theme.dart` (Lato 16sp), `app_theme.dart` (buildDarkTheme).
- **Localization:** 10 ARB files in `lib/core/l10n/`, 22 keys each. `AppLocalizations.of(context).key` for all user-visible strings.
- **Settings:** `lib/features/settings/application/settings_provider.dart` — `SharedPreferencesWithCache`, `keepAlive: true`.
