---
phase: 02-model-distribution
verified: 2026-02-19T22:30:00Z
status: gaps_found
score: 4/5 must-haves verified
gaps:
  - truth: "On first launch the app shows a download screen with a progress indicator and the file size (~2.14 GB) before any download begins"
    status: partial
    reason: "The download screen shows a spinner for CheckingModelState and PreflightState but does NOT display the file size (~2.14 GB) until the DownloadingState is entered. The file size only appears as bytes/total once download is in progress, and in the CellularWarningDialog. The static text reads 'Downloading language model for offline use' without mentioning size."
    artifacts:
      - path: "lib/features/model_distribution/widgets/download_screen.dart"
        issue: "No file size shown in pre-download states (CheckingModel, Preflight). The explanatory text at line 84 says 'Downloading language model for offline use' but omits '(~2.14 GB)'. ModelConstants.fileSizeDisplayGB exists but is never referenced by download_screen.dart."
    missing:
      - "Add file size to the explanatory text: 'Downloading language model for offline use (~2.14 GB)' or display it separately below the text during pre-download states"
      - "Reference ModelConstants.fileSizeDisplayGB in the download screen"
---

# Phase 2: Model Distribution Verification Report

**Phase Goal:** Users get through first launch with a clear, resumable download flow that installs the model and verifies its integrity, so the app is ready for offline use after one connected session
**Verified:** 2026-02-19T22:30:00Z
**Status:** gaps_found
**Re-verification:** No -- initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | On first launch the app shows a download screen with a progress indicator and the file size (~2.14 GB) before any download begins | PARTIAL | Download screen exists and shows progress indicator during DownloadingState. However, file size is NOT visible before download begins -- only appears once download is active (as bytes/total) and in CellularWarningDialog. `ModelConstants.fileSizeDisplayGB` exists but is unused by download_screen.dart. |
| 2 | If the app is backgrounded or the download is interrupted, progress resumes from where it stopped on next launch without restarting the full download | VERIFIED | Notifier persists progress to shared_preferences at 5% intervals (line 286-291 of notifier). On next launch, saved progress > 0.0 triggers ResumePromptState (line 108-110). ResumePromptDialog shows saved percentage and offers Resume/Start over. background_downloader configured with `allowPause: true` (line 213). |
| 3 | If the device is on cellular, the app presents an explicit warning with the file size before offering to proceed | VERIFIED | `_runPreflight()` checks connectivity via `checkConnectionType()` (line 164). If cellular, sets `CellularWarningState` (line 173). CellularWarningDialog shows "This download is ~2.14 GB. Continue on cellular?" with "Wait for Wi-Fi" and "Download now" buttons. Dialog is `barrierDismissible: false`. |
| 4 | On every subsequent launch the app verifies the model file via SHA-256 before loading; a corrupted or missing file triggers re-download | VERIFIED | `initialize()` checks if model file exists (line 91). If present, sets VerifyingState and calls `verifyModelFile()` (line 94). If valid, proceeds to load. If invalid, deletes file and runs preflight for re-download (line 99-100). SHA-256 verifier uses chunked 64KB reads in compute() isolate -- never loads full file into memory. Hash compared against `ModelConstants.sha256Hash`. |
| 5 | After download completes, the model loads in the background and the chat input is disabled with a visible loading indicator until inference is ready | VERIFIED | After download+verify, notifier transitions to LoadingModelState (line 382). `_AppRouter` routes to `_MainAppScreen` for LoadingModelState/ModelReadyState (app.dart line 71). `ModelLoadingOverlay` shows greyscale icon + "Loading language model..." text during loading (line 98-108). TextField `enabled: isReady` where `isReady = ref.watch(modelDistributionProvider) is ModelReadyState` (app.dart line 95, 122). AnimatedCrossFade transitions icon from grey to green on ready (line 78-92). Note: actual model load is a Phase 4 stub (`_loadModel()` immediately sets ModelReadyState), but the UI contract for loading indicator and disabled input is fully implemented. |

**Score:** 4/5 truths verified (1 partial)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/main.dart` | App entry point with ProviderScope | VERIFIED | 9 lines. WidgetsFlutterBinding.ensureInitialized(), ProviderScope wraps BittyBotApp. |
| `lib/app.dart` | Root app with routing between download and main screen | VERIFIED | 147 lines. BittyBotApp ConsumerWidget, _AppRouter ConsumerStatefulWidget watches modelDistributionProvider, _MainAppScreen with ModelLoadingOverlay and disabled TextField. |
| `lib/features/model_distribution/model_constants.dart` | Hard-coded model URL, SHA-256, filename, size | VERIFIED | 48 lines. downloadUrl, filename, fileSizeBytes (2299396096), sha256Hash, modelSubdirectory, requiredFreeSpaceMB (2560), lowMemoryThresholdMB (4096), fileSizeDisplayGB ('~2.14 GB'), helper methods for paths. |
| `lib/features/model_distribution/model_distribution_state.dart` | Sealed class with all state variants | VERIFIED | 154 lines. `@immutable sealed class ModelDistributionState` with 11 variants: CheckingModel, Preflight, ResumePrompt, CellularWarning, InsufficientStorage, Downloading, Verifying, LowMemoryWarning, LoadingModel, ModelReady, Error. All const constructors. |
| `lib/features/model_distribution/model_distribution_notifier.dart` | Notifier orchestrating download lifecycle | VERIFIED | 395 lines. Full lifecycle: initialize -> check existing model -> verify SHA-256 / check resume / preflight -> storage check -> connectivity gate -> download via background_downloader -> verify -> RAM check -> load. FileDownloader with enqueue/registerCallbacks, progress persistence, error escalation. |
| `lib/features/model_distribution/providers.dart` | Riverpod provider declaration | VERIFIED | 23 lines. `NotifierProvider<ModelDistributionNotifier, ModelDistributionState>` manual declaration. |
| `lib/features/model_distribution/sha256_verifier.dart` | Chunked SHA-256 verification | VERIFIED | 52 lines. `verifyModelFile()` uses `compute()` isolate. `_computeSha256Match()` uses `openSync`, `readSync` with 64KB chunks, `sha256.startChunkedConversion(AccumulatorSink<Digest>())`. Compares against `ModelConstants.sha256Hash`. Never uses readAsBytes. |
| `lib/features/model_distribution/storage_preflight.dart` | Disk space, RAM, connectivity checks | VERIFIED | 114 lines. `checkConnectionType()` using connectivity_plus. `checkStorageSpace()` using disk_space_plus with sealed `StorageCheckResult`. `isLowMemoryDevice()` using system_info_plus with try/catch defaulting to false. |
| `lib/features/model_distribution/widgets/download_screen.dart` | Full download screen UI | VERIFIED | 354 lines. ConsumerStatefulWidget. Exhaustive switch on all 11 state variants. Forest green progress bar, bytes/speed/ETA display, spinner states, error card with retry, storage error, low memory warning. Dialog triggers via postFrameCallback. Helper formatters for bytes, duration, speed. |
| `lib/features/model_distribution/widgets/cellular_warning_dialog.dart` | Cellular data warning dialog | VERIFIED | 79 lines. ConsumerWidget. Title "Download on cellular data?", body "This download is ~2.14 GB. Continue on cellular?". "Wait for Wi-Fi" and "Download now" buttons. barrierDismissible: false. |
| `lib/features/model_distribution/widgets/resume_prompt_dialog.dart` | Resume confirmation dialog | VERIFIED | 129 lines. ConsumerWidget. Shows saved progress percentage and progress bar. "BittyBot needs this language model..." explanation. "Start over" clears prefs and calls retryDownload(). "Resume" calls confirmResume(). barrierDismissible: false. |
| `lib/features/model_distribution/widgets/model_loading_overlay.dart` | Loading overlay with greyscale-to-color transition | VERIFIED | 118 lines. ConsumerWidget. Stack with child + overlay. AnimatedCrossFade between grey and green icons (placeholder for logo assets). AnimatedOpacity fades overlay out on ready. IgnorePointer when ready so invisible overlay does not block input. |
| `pubspec.yaml` | All Phase 2 dependencies | VERIFIED | Contains background_downloader ^9.5.2, connectivity_plus ^7.0.0, convert ^3.1.2, crypto ^3.0.7, disk_space_plus ^0.2.6, flutter_riverpod ^3.2.1, path_provider ^2.1.5, shared_preferences ^2.5.4, system_info_plus ^0.0.6. |
| `android/app/src/main/AndroidManifest.xml` | Android permissions and services | VERIFIED | POST_NOTIFICATIONS, FOREGROUND_SERVICE, FOREGROUND_SERVICE_DATA_SYNC, RUN_USER_INITIATED_JOBS permissions. SystemForegroundService and UIDTJobService declarations. tools namespace present. |
| `ios/Runner/AppDelegate.swift` | iOS notification delegate | VERIFIED | UNUserNotificationCenter.current().delegate set. UserNotifications imported. |
| `ios/Runner/Info.plist` | Background Fetch | VERIFIED | UIBackgroundModes array contains "fetch". |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| sha256_verifier.dart | model_constants.dart | `ModelConstants.sha256Hash` comparison | WIRED | Line 51: `digest.toString() == ModelConstants.sha256Hash` |
| model_distribution_notifier.dart | sha256_verifier.dart | `verifyModelFile()` calls | WIRED | Called at lines 94 (on launch) and 322 (after download). Both paths use the result to determine next state. |
| model_distribution_notifier.dart | storage_preflight.dart | `checkStorageSpace`, `checkConnectionType`, `isLowMemoryDevice` | WIRED | Line 154, 164, 372. All three functions called with results driving state transitions. |
| model_distribution_notifier.dart | background_downloader | FileDownloader, DownloadTask | WIRED | Lines 187-246. FileDownloader configured, DownloadTask created with correct constants, enqueue + registerCallbacks + completer pattern. Progress and status callbacks implemented. |
| model_distribution_notifier.dart | model_constants.dart | URL, filename, size, paths | WIRED | Lines 84-85, 207-223, 273, 377. All constants consumed. |
| download_screen.dart | providers.dart | `ref.watch(modelDistributionProvider)` | WIRED | Line 48. Exhaustive switch on state drives all UI rendering. |
| cellular_warning_dialog.dart | providers.dart | `ref.read(modelDistributionProvider.notifier).confirmCellularDownload()` | WIRED | Line 71. |
| resume_prompt_dialog.dart | providers.dart | `ref.read(modelDistributionProvider.notifier).confirmResume()` and `.retryDownload()` | WIRED | Lines 104, 122. |
| app.dart (router) | providers.dart | `ref.watch(modelDistributionProvider)` + `initialize()` | WIRED | Line 60 (initialize), line 66 (watch state for routing). |
| app.dart (main screen) | providers.dart | `ref.watch(modelDistributionProvider) is ModelReadyState` | WIRED | Line 95. TextField enabled only when model is ready. |
| model_loading_overlay.dart | providers.dart | `ref.watch(modelDistributionProvider)` for ready/loading detection | WIRED | Line 43. isReady and isLoading drive overlay visibility and logo crossfade. |
| main.dart | app.dart | `ProviderScope(child: BittyBotApp())` | WIRED | Line 8. |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| MODL-01 | 02-01, 02-02 | App downloads model on first launch with progress indicator | SATISFIED | Download flow fully implemented: background_downloader with DownloadTask, progress callbacks update DownloadingState, download_screen.dart renders progress bar with bytes/speed/ETA. |
| MODL-02 | 02-01, 02-02 | Download resumes if interrupted | SATISFIED | Progress persisted to shared_preferences at 5% intervals. On relaunch, saved progress > 0.0 triggers ResumePromptState. background_downloader handles OS-level resume with allowPause: true. |
| MODL-03 | 02-02 | Cellular warning with file size | SATISFIED | checkConnectionType() detects cellular. CellularWarningDialog shows "This download is ~2.14 GB. Continue on cellular?" with proceed/wait options. |
| MODL-04 | 02-03 | SHA-256 verification on every launch | SATISFIED | initialize() always verifies existing model file via verifyModelFile() before loading. Uses chunked compute() isolate. Corrupted/missing file triggers re-download. |
| MODL-05 | 02-03 | Model loads in background with loading indicator; chat input disabled until ready | SATISFIED (UI contract) | ModelLoadingOverlay shows greyscale icon + "Loading language model..." during LoadingModelState. TextField disabled until ModelReadyState. AnimatedCrossFade transitions icon on ready. Note: actual model load is a documented Phase 4 stub, but the UI loading indicator and disabled input contract are fully implemented. |

No orphaned requirements found. All Phase 2 requirements (MODL-01 through MODL-05) appear in plan `requirements:` fields and are covered.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `lib/features/model_distribution/model_distribution_notifier.dart` | 388 | `TODO(phase-4): Wire actual llama_cpp inference load here` | Info | Expected stub -- Phase 4 responsibility. `_loadModel()` immediately sets ModelReadyState. Documented and intentional. |
| `lib/features/model_distribution/model_distribution_notifier.dart` | 301 | `print()` debug statement for paused status | Info | Single print for download pause logging. Should be removed or replaced with proper logging before production. Not a blocker. |
| `lib/features/model_distribution/widgets/download_screen.dart` | 13-22 | 4 placeholder colour constants with TODO(phase-3) | Info | Expected -- Phase 3 provides the design system. Colors are reasonable dark-theme defaults, not broken placeholders. |
| `lib/features/model_distribution/widgets/model_loading_overlay.dart` | 70-77 | Logo asset TODO -- using Icon placeholders | Info | Expected -- user will supply logo PNGs. Placeholder icons (smart_toy grey/green) are functional and correctly wired with AnimatedCrossFade. |
| `lib/features/model_distribution/widgets/download_screen.dart` | 104-110 | Logo asset TODO -- using Icon placeholder | Info | Same as above. |
| `lib/app.dart` | 114 | `TODO(phase-6): Replace with real chat message list` | Info | Expected -- placeholder main screen text. Phase 6 builds the real chat UI. |
| `lib/features/model_distribution/widgets/resume_prompt_dialog.dart` | 104 | "Start over" calls `retryDownload()` which increments `_failureCount` | Warning | Starting over is a user choice, not a failure. Incrementing the failure counter may show troubleshooting hints prematurely after 3 "start over" actions. Minor behavioral issue, not a blocker. |

### Human Verification Required

### 1. First Launch Download Flow

**Test:** Run `flutter run` on a device/emulator. On first launch, verify the download screen appears with the BittyBot icon, explanatory text, and a "Checking for language model..." spinner followed by "Preparing download..." spinner, then download starts with a forest green progress bar showing bytes, speed, and ETA.
**Expected:** Smooth transition from checking to preflight to downloading. Progress bar updates in real time. No cancel button visible.
**Why human:** Visual rendering, animation smoothness, and real-time progress updates cannot be verified by code inspection.

### 2. Background/Resume Flow

**Test:** While downloading, press the home button. Check the notification shade for download progress. Reopen the app.
**Expected:** A "Resume download?" dialog appears (NOT auto-resume) showing the saved progress percentage and a progress bar. Tapping "Resume" continues the download from where it stopped.
**Why human:** Background download behavior and OS notification integration require real device testing.

### 3. Cellular Warning

**Test:** Disconnect from Wi-Fi, enable cellular data, and launch the app for the first time.
**Expected:** After checking/preflight states, a dialog appears saying "Download on cellular data?" with "This download is ~2.14 GB. Continue on cellular?" and two buttons: "Wait for Wi-Fi" and "Download now".
**Why human:** Connectivity detection behavior varies by device and requires real hardware.

### 4. Post-Download Transition

**Test:** After the download completes, verify the "Verifying download..." spinner appears, then the app transitions to the main screen.
**Expected:** Main screen shows greyscale icon + "Loading language model..." text + disabled text field. Then the icon crossfades to green and the text field enables (currently instant since Phase 4 is not wired).
**Why human:** AnimatedCrossFade and AnimatedOpacity transitions need visual confirmation for smoothness and timing.

### 5. Subsequent Launch

**Test:** Kill and reopen the app after the model has been downloaded and verified.
**Expected:** Goes directly to the main screen (no download screen). Brief verification/loading overlay visible, then icon transitions to ready state.
**Why human:** App lifecycle and SharedPreferences persistence require real device verification.

### Gaps Summary

One gap was identified:

**Truth 1 (file size before download):** The download screen does not display the file size (~2.14 GB) before the download begins. The static text reads "Downloading language model for offline use" without mentioning the size. `ModelConstants.fileSizeDisplayGB` (`'~2.14 GB'`) exists as a constant but is never imported or referenced by `download_screen.dart`. The file size only appears once the download is active (as bytes/total in the progress display) and in the CellularWarningDialog. This is a partial failure of Success Criterion 1, which explicitly requires the file size to be visible "before any download begins."

The fix is straightforward: change the explanatory text to include the file size (e.g., "Downloading language model for offline use (~2.14 GB)") or add a separate line showing the file size in the pre-download states. The `fileSizeDisplayGB` constant already exists and just needs to be referenced.

All other truths are fully verified with strong evidence. The codebase is well-structured with proper wiring between all components. The Phase 4 model-loading stub is appropriately documented and does not block Phase 2's goal.

---

_Verified: 2026-02-19T22:30:00Z_
_Verifier: Claude (gsd-verifier)_
