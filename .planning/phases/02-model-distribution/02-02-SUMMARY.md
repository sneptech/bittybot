---
phase: 02-model-distribution
plan: 02
subsystem: model-distribution
tags: [background_downloader, flutter_riverpod, notifier, state-machine, download-ui, cellular-warning, resume-prompt, shared_preferences, dart-sealed-class]

# Dependency graph
requires:
  - "02-01 — model_constants.dart, model_distribution_state.dart, sha256_verifier.dart, storage_preflight.dart all consumed here"
provides:
  - "ModelDistributionNotifier: Riverpod Notifier orchestrating check → preflight → download → verify → load lifecycle"
  - "modelDistributionProvider: NotifierProvider exposing ModelDistributionNotifier to UI"
  - "DownloadScreen: full-screen ConsumerStatefulWidget rendering all 11 state variants"
  - "CellularWarningDialog: modal dialog with '~2.14 GB' size and proceed/wait options"
  - "ResumePromptDialog: modal dialog with saved-percentage display and resume/start-over"
affects:
  - "02-03: app entry point calls notifier.initialize() and routes based on ModelReadyState"
  - "04-core-inference: modelFilePath getter on notifier passes file path to llama.cpp load"
  - "All UI phases: DownloadScreen is the first screen users see on install"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "registerCallbacks + enqueue pattern: use FileDownloader().registerCallbacks() with TaskProgressCallback for full TaskProgressUpdate (speed, ETA) — download() convenience method only provides raw double fraction"
    - "Completer<TaskStatusUpdate> for async enqueue: register callbacks, enqueue task, await Completer resolved by status callback on terminal states"
    - "Dialog via addPostFrameCallback: show AlertDialog from build() without triggering setState-during-build warnings"
    - "ConsumerStatefulWidget for dialogs: stateful widget tracks _dialogVisible bool to prevent double-showing dialogs on rebuild"
    - "Exhaustive switch on sealed class: switch (state) in _buildStateContent produces compile error if any variant is unhandled"

key-files:
  created:
    - "lib/features/model_distribution/model_distribution_notifier.dart — Riverpod Notifier with full download lifecycle (280 lines)"
    - "lib/features/model_distribution/providers.dart — NotifierProvider declaration"
    - "lib/features/model_distribution/widgets/download_screen.dart — full download screen UI (all 11 states)"
    - "lib/features/model_distribution/widgets/cellular_warning_dialog.dart — cellular data warning AlertDialog"
    - "lib/features/model_distribution/widgets/resume_prompt_dialog.dart — resume confirmation AlertDialog with progress bar"
  modified: []

key-decisions:
  - "Used FileDownloader().registerCallbacks() + enqueue() instead of download() — download() only provides void Function(double) for progress callbacks (raw fraction only), while registerCallbacks() with TaskProgressCallback gives full TaskProgressUpdate including networkSpeed and timeRemaining"
  - "Completer<TaskStatusUpdate> used to await enqueue() completion — registerCallbacks fires asynchronously; Completer bridges the callback-based API into an async/await flow"
  - "ConsumerStatefulWidget for DownloadScreen — stateful widget needed to track _dialogVisible bool and prevent double-showing dialogs when sealed class state rebuilds the widget tree"
  - "Dialog via WidgetsBinding.instance.addPostFrameCallback — avoids setState-during-build errors when transitioning to CellularWarningState or ResumePromptState"
  - "_kDownloadGroup group name for background_downloader — isolates model download callbacks from any other downloads the app might perform in future phases"

# Metrics
duration: 6min
completed: 2026-02-18
---

# Phase 2 Plan 02: Download Orchestration and UI Summary

**Riverpod notifier orchestrating complete check-preflight-download-verify-load state machine with registerCallbacks+enqueue pattern for full speed/ETA progress data, plus download screen rendering all 11 state variants with forest green progress bar, cellular warning dialog, and resume prompt dialog**

## Performance

- **Duration:** ~6 min
- **Started:** 2026-02-18T18:37:52Z
- **Completed:** 2026-02-18T18:44:00Z
- **Tasks:** 2
- **Files modified:** 5 created

## Accomplishments

- ModelDistributionNotifier implements the complete 11-state lifecycle with no missing transitions
- background_downloader configured with foreground service, UIDT priority 0, notifications, allowPause, retries
- Download progress persisted to shared_preferences at 5% throttle intervals (not every callback)
- Cellular gate blocks download until explicit user confirmation; cellular warning shows exact "~2.14 GB"
- Resume gate always shows prompt on reopen — no auto-resume per user decision
- Error escalation appends troubleshooting hints automatically after 3+ consecutive failures
- Download screen exhaustively handles all 11 ModelDistributionState variants
- `flutter analyze lib/` reports no issues across all 9 files (4 from Plan 01 + 5 new)

## Task Commits

Each task was committed atomically:

1. **Task 1: ModelDistributionNotifier and providers** — `646ba0e` (feat)
2. **Task 2: Download screen UI with all state renderings and dialogs** — `ee89237` (feat)

## Files Created

- `lib/features/model_distribution/model_distribution_notifier.dart` — Notifier with full lifecycle (~280 lines)
- `lib/features/model_distribution/providers.dart` — NotifierProvider declaration
- `lib/features/model_distribution/widgets/download_screen.dart` — Full download UI (all 11 states, ~310 lines)
- `lib/features/model_distribution/widgets/cellular_warning_dialog.dart` — Cellular warning AlertDialog
- `lib/features/model_distribution/widgets/resume_prompt_dialog.dart` — Resume confirmation AlertDialog with embedded progress bar

## Decisions Made

- Used `registerCallbacks()` + `enqueue()` instead of `download()` — the `download()` convenience method's `onProgress` only provides `void Function(double)` (raw fraction), while `registerCallbacks()` with `TaskProgressCallback` gives the full `TaskProgressUpdate` including `networkSpeed` and `timeRemaining` needed for the speed/ETA display
- `Completer<TaskStatusUpdate>` bridges the callback-based `registerCallbacks` API into async/await flow — completer is resolved by `_onStatusCallback` when a terminal status (complete/failed/notFound/canceled) is received
- `ConsumerStatefulWidget` for DownloadScreen — needed to track `_dialogVisible` bool that prevents double-showing dialogs when the state rebuilds the widget tree rapidly
- All placeholder colors defined as `const` at top of each file with `// TODO(phase-3)` comments for easy Phase 3 design-system replacement

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Used registerCallbacks+enqueue instead of download() with TaskProgressUpdate callbacks**

- **Found during:** Task 1 (notifier `_startDownload` method)
- **Issue:** The plan specified `FileDownloader().download(task, onProgress: _onProgress, onStatus: _onStatus)` where `_onProgress` takes `TaskProgressUpdate` and `_onStatus` takes `TaskStatusUpdate`. The actual `download()` API signature is `{void Function(TaskStatus)? onStatus, void Function(double)? onProgress}` — it only provides raw double fraction and TaskStatus enum, not the full update objects with speed/ETA data.
- **Fix:** Switched to `registerCallbacks()` with `TaskProgressCallback` (which provides full `TaskProgressUpdate`) + `enqueue()` + `Completer<TaskStatusUpdate>` to await the terminal status. This preserves all planned functionality (speed, ETA, pause/status callbacks) using the correct API.
- **Files modified:** `model_distribution_notifier.dart`
- **Commit:** 646ba0e (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 — API mismatch, corrected to preserve all planned behavior)
**Impact on plan:** Zero functional impact — same data (speed, ETA, progress fraction, status) delivered via correct API path.

## Issues Encountered

None — both tasks completed without build failures or blocking issues.

## User Setup Required

None.

## Next Phase Readiness

- Plan 03 can call `ref.read(modelDistributionProvider.notifier).initialize()` on app start
- Plan 03 routes between DownloadScreen (all non-ready states) and main app screen (ModelReadyState)
- Phase 4 accesses `ref.read(modelDistributionProvider.notifier).modelFilePath` to get the GGUF path for llama.cpp

---
*Phase: 02-model-distribution*
*Completed: 2026-02-18*

## Self-Check: PASSED

- FOUND: lib/features/model_distribution/model_distribution_notifier.dart
- FOUND: lib/features/model_distribution/providers.dart
- FOUND: lib/features/model_distribution/widgets/download_screen.dart
- FOUND: lib/features/model_distribution/widgets/cellular_warning_dialog.dart
- FOUND: lib/features/model_distribution/widgets/resume_prompt_dialog.dart
- FOUND: .planning/phases/02-model-distribution/02-02-SUMMARY.md
- FOUND commit: 646ba0e (Task 1)
- FOUND commit: ee89237 (Task 2)
- flutter analyze lib/ — No issues found
