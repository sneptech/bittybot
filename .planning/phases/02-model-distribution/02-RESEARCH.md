# Phase 2: Model Distribution - Research

**Researched:** 2026-02-19
**Domain:** Flutter background download, SHA-256 integrity, storage pre-flight, Riverpod state machine, greyscale-to-color logo transition
**Confidence:** HIGH (all core libraries verified via official sources)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Download screen experience:**
- Minimal, clean download screen — not an onboarding carousel
- BittyBot logo (graphic only, not app name text) centered above download area
- Small explanatory text below logo describing what's being downloaded
- Progress bar in forest green theme (exact color values TODO — Phase 3 defines design system; use a placeholder that's easy to swap)
- Below progress bar in small font, centered: transfer speed (bits/sec) and estimated time remaining (ETA)
- File size shown (total and downloaded amount)
- No cancel button — user can background or kill the app to stop
- Normal screen sleep behavior — don't keep screen awake during download
- Brief "Preparing download..." state with spinner while connectivity and storage are checked before download begins

**Cellular data handling:**
- On cellular connection: show dialog warning with file size ("This download is ~2.14 GB. Continue on cellular?") with proceed/wait options
- On Wi-Fi: start automatically after pre-flight checks

**Interruption and resume UX:**
- On reopen after interrupted download: show resume confirmation prompt, not auto-resume
- Resume prompt includes a short sentence explaining the app needs this download to function
- Progress bar on resume shows full journey (starts at e.g. 60% where it left off, not reset to 0%)
- Pre-flight storage check before starting download — if insufficient space, show clear error with exact amount needed
- Persistent system notification with progress bar when app is backgrounded during download
- Notify on completion so user knows to come back
- After download completes, show brief "Verifying download..." state before transitioning

**Post-download transition:**
- After verification, transition to main app screen
- Main app shows with text input disabled and loading indicator + text while model loads into memory
- Same loading state used on every subsequent app launch
- On subsequent launches: straight to main screen, no splash — greyscale logo + disabled input + loading text while model loads
- When model finishes loading: text input enables, BittyBot logo transitions from greyscale/dimmed to full color
- RAM check before model load: warn honestly if device may not have enough memory but allow user to proceed

**Repeated failure handling:**
- Claude's discretion on error escalation after repeated download failures

### Claude's Discretion
- Exact error escalation strategy for repeated download failures
- Progress notification styling on Android vs iOS
- "Preparing download..." spinner implementation
- Verification progress indicator timing

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| MODL-01 | App downloads Tiny Aya Global Q4_K_M GGUF (~2.14 GB) on first launch with progress indicator | `background_downloader` 9.5.2 provides `DownloadTask` with `onProgress` callback; `TaskProgressUpdate` supplies `progress`, `expectedFileSize`, `networkSpeed`, `timeRemaining` |
| MODL-02 | Download resumes automatically if interrupted or app is backgrounded | `allowPause: true` on `DownloadTask` enables Android auto-resume past 9-min limit; iOS URLSessions handle backgrounding natively; resume confirmation dialog shown on reopen per user decision |
| MODL-03 | If user is not on Wi-Fi, app offers option to download on cellular with explicit file size warning (~2.14 GB) | `connectivity_plus` 7.0.0 detects `ConnectivityResult.mobile` vs `ConnectivityResult.wifi`; cellular warning dialog implemented in pre-flight logic before calling `FileDownloader().download()` |
| MODL-04 | App verifies model integrity via SHA-256 hash on each launch before loading | `crypto` 3.0.7 provides chunked SHA-256 for large files; known hash `d01d995272af305b2b843efcff8a10cf9869cf53e764cb72b0e91b777484570a`; verify after download and on every subsequent launch |
| MODL-05 | Model loads in background with loading indicator; chat input disabled until ready | Riverpod 3.2.1 `Notifier` with `ModelReadyState` enum manages UI state; Phase 4 wires actual inference loading; this phase establishes the state contract and UI shell |
</phase_requirements>

---

## Summary

Phase 2 is a well-defined download-and-verify pipeline with a clear stack. The locked library from Phase 1 planning is `background_downloader` 9.5.2, which handles the heavy lifting: iOS URLSession background transfers, Android WorkManager with `allowPause` for resuming past the 9-minute limit, and Android 14+ UIDT mode (triggered by `priority: 0`) for large files without time limits. Notifications are built into the package with a single `configureNotification` call. The cellular gate is handled by `connectivity_plus` 7.0.0 detecting `ConnectivityResult.mobile`. SHA-256 post-download verification uses Dart's `crypto` 3.0.7 package with chunked streaming for the 2.14 GB file. Storage pre-flight uses `disk_space_plus` 0.2.6. RAM pre-check uses `system_info_plus` 0.0.6.

The greyscale-to-color logo transition is the app's "model ready" signal. Flutter's built-in `ColorFiltered` widget combined with `TweenAnimationBuilder` (using a `double` tween from 0.0 to 1.0 to control saturation via `ColorMatrix`) produces this effect without any external animation library. The two logo assets (greyscale PNG, full-color PNG) are user-supplied; the transition is a crossfade using `AnimatedSwitcher` or `AnimatedCrossFade` between them.

State management uses Riverpod 3.2.1 `Notifier` with a custom `ModelDistributionState` sealed class (or enum). The state machine covers: `idle`, `preflight`, `cellularWarning`, `downloading`, `verifying`, `loadingModel`, `ready`, and `error` states. `shared_preferences` 2.5.4 persists download progress across launches so the resume prompt can show correct percentage. The download URL and SHA-256 are hard-coded constants in the app (not fetched at runtime).

**Primary recommendation:** Use `background_downloader` with `allowPause: true` and `priority: 0` for Android, configure `Config.runInForegroundIfFileLargerThan(500)` to activate foreground mode for this 2.14 GB file, and implement SHA-256 verification via the `crypto` package's chunked API.

---

## Model Constants (Hard-code These)

| Constant | Value |
|----------|-------|
| **Filename** | `tiny-aya-global-q4_k_m.gguf` |
| **Download URL** | `https://huggingface.co/CohereLabs/tiny-aya-global-GGUF/resolve/main/tiny-aya-global-q4_k_m.gguf?download=true` |
| **File size** | 2,299,396,096 bytes (~2.14 GB) |
| **SHA-256** | `d01d995272af305b2b843efcff8a10cf9869cf53e764cb72b0e91b777484570a` |
| **Storage location** | `getApplicationSupportDirectory()` + `models/tiny-aya-global-q4_k_m.gguf` |

**Source:** Verified directly from HuggingFace file page (HIGH confidence).

**Note on Xet hash:** HuggingFace shows a "Xet hash" (`c1a7a2f36dca...`) separate from SHA-256. SHA-256 is `d01d99...` — use SHA-256 for application integrity checks.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `background_downloader` | 9.5.2 | Background file download with resume, notifications, progress | Established in Phase 1; iOS URLSessions + Android WorkManager/UIDT; handles all mobile background constraints |
| `connectivity_plus` | 7.0.0 | Detect Wi-Fi vs cellular before download | Official Flutter ecosystem package; `ConnectivityResult` enum; stream-based monitoring |
| `crypto` | 3.0.7 | SHA-256 file integrity verification | Dart.dev official; chunked streaming API for large files; no native bridging needed |
| `path_provider` | 2.1.5 | Resolve on-device model storage path | Standard for Flutter file path resolution; already a dependency in Phase 1 |
| `flutter_riverpod` | 3.2.1 | State management for download/load state machine | Project-wide standard per CLAUDE.md; `Notifier` class replaces `StateNotifier` in Riverpod 3 |
| `shared_preferences` | 2.5.4 | Persist download progress % across app launches | Needed for resume prompt to show correct starting percentage |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `disk_space_plus` | 0.2.6 | Pre-flight storage check | Use `getFreeDiskSpaceForPath()` before starting download; show exact "Need X GB free" error |
| `system_info_plus` | 0.0.6 | RAM pre-check before model load | Use `SystemInfoPlus.physicalMemory` (returns MB); warn if < 4096 MB |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `crypto` (dart.dev) | `cryptography` | `cryptography` is ~2x faster for small hashes but `crypto` is simpler API, dart.dev verified, and adequate for one-time file verification |
| `disk_space_plus` | `path_provider` + `dart:io StatFs` | `StatFs` is Android-only; `disk_space_plus` abstracts both platforms in 3 lines of code |
| `system_info_plus` | `device_info_plus` | `device_info_plus` gives device model but not RAM; `system_info_plus` gives `physicalMemory` in MB |
| `connectivity_plus` | Custom network check via `http` | `connectivity_plus` correctly identifies the connection type; custom HTTP probes detect reachability but not connection type |
| `AnimatedSwitcher` | Lottie animation | Lottie adds dependency and asset; built-in Flutter widgets sufficient for crossfade |

**Installation:**

```bash
flutter pub add background_downloader
flutter pub add connectivity_plus
flutter pub add crypto
flutter pub add path_provider
flutter pub add flutter_riverpod
flutter pub add shared_preferences
flutter pub add disk_space_plus
flutter pub add system_info_plus
```

---

## Architecture Patterns

### Recommended Project Structure

```
lib/
├── features/
│   └── model_distribution/
│       ├── model_distribution_state.dart    # Sealed class for state machine states
│       ├── model_distribution_notifier.dart # Riverpod Notifier, orchestrates all steps
│       ├── model_constants.dart             # Hard-coded URL, SHA-256, filename, size
│       ├── sha256_verifier.dart             # Chunked SHA-256 computation
│       ├── storage_preflight.dart           # Space check + RAM check helpers
│       ├── widgets/
│       │   ├── download_screen.dart         # First-launch download UI
│       │   ├── model_loading_overlay.dart   # Greyscale logo + disabled input state
│       │   ├── cellular_warning_dialog.dart # "~2.14 GB on cellular" dialog
│       │   └── resume_prompt_dialog.dart    # Resume confirmation prompt
│       └── providers.dart                   # All riverpod provider declarations
└── main.dart
```

### Pattern 1: State Machine with Sealed Class

**What:** Model the entire download-and-load lifecycle as a sealed class so the UI can exhaustively switch on states.

**When to use:** Anywhere the UI renders download/load status.

```dart
// lib/features/model_distribution/model_distribution_state.dart

sealed class ModelDistributionState {
  const ModelDistributionState();
}

/// App just launched; checking if model already exists and is valid
class CheckingModelState extends ModelDistributionState {
  const CheckingModelState();
}

/// Pre-flight: checking storage space and connectivity
class PreflightState extends ModelDistributionState {
  const PreflightState();
}

/// Paused mid-download; waiting for user to confirm resume
class ResumePromptState extends ModelDistributionState {
  const ResumePromptState({required this.progressFraction});
  final double progressFraction; // e.g. 0.60 means 60% done
}

/// Cellular detected; waiting for user to confirm
class CellularWarningState extends ModelDistributionState {
  const CellularWarningState();
}

/// Insufficient storage before starting
class InsufficientStorageState extends ModelDistributionState {
  const InsufficientStorageState({
    required this.neededBytes,
    required this.availableBytes,
  });
  final int neededBytes;
  final int availableBytes;
}

/// Active download in progress
class DownloadingState extends ModelDistributionState {
  const DownloadingState({
    required this.progressFraction,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.networkSpeedMBps,
    required this.timeRemaining,
  });
  final double progressFraction;
  final int downloadedBytes;
  final int totalBytes;
  final double networkSpeedMBps;
  final Duration? timeRemaining;
}

/// Download complete; running SHA-256 verification
class VerifyingState extends ModelDistributionState {
  const VerifyingState();
}

/// Model downloaded and verified; now loading into memory (inference ready)
class LoadingModelState extends ModelDistributionState {
  const LoadingModelState();
}

/// RAM warning before load — user can still proceed
class LowMemoryWarningState extends ModelDistributionState {
  const LowMemoryWarningState({required this.availableMB});
  final int availableMB;
}

/// Model fully loaded; app is ready
class ModelReadyState extends ModelDistributionState {
  const ModelReadyState();
}

/// Terminal error with retry support
class ErrorState extends ModelDistributionState {
  const ErrorState({
    required this.message,
    required this.failureCount,
  });
  final String message;
  final int failureCount; // drives error escalation UX after 3+
}
```

### Pattern 2: DownloadTask Configuration for 2.14 GB File

**What:** Configure `DownloadTask` correctly for a large file with resume support, notifications, and UIDT on Android 14+.

**When to use:** In `ModelDistributionNotifier` when initiating download.

```dart
// Source: https://pub.dev/packages/background_downloader (v9.5.2)

import 'package:background_downloader/background_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'model_constants.dart';

final task = DownloadTask(
  url: ModelConstants.downloadUrl,
  filename: ModelConstants.filename,
  directory: 'models',
  baseDirectory: BaseDirectory.applicationSupport, // persistent, not temp
  updates: Updates.statusAndProgress,              // both status and progress callbacks
  allowPause: true,                                // Android: auto-resume past 9-min limit
  priority: 0,                                     // Android 14+: UIDT mode (no time limit)
  retries: 3,                                      // automatic retry on transient failures
  metaData: 'tiny-aya-q4km',                       // used in notification body
  displayName: 'Tiny Aya language model',
);

// Notifications must be configured before download starts
FileDownloader().configureNotification(
  running: const TaskNotification(
    'Downloading language model',
    '{progress}% — {displayName}',
  ),
  paused: const TaskNotification(
    'Download paused',
    '{displayName}',
  ),
  complete: const TaskNotification(
    'Download complete',
    'Language model ready — tap to open BittyBot',
  ),
  error: const TaskNotification(
    'Download failed',
    '{displayName}',
  ),
  progressBar: true,  // Android only; iOS ignores this
);

// Execute download with inline callbacks
final result = await FileDownloader().download(
  task,
  onProgress: (update) {
    // update.progress: 0.0–1.0
    // update.expectedFileSize: bytes (-1 if unknown)
    // update.networkSpeed: MB/s (check update.hasNetworkSpeed first)
    // update.timeRemaining: Duration? (check update.hasTimeRemaining first)
    ref.read(modelDistributionProvider.notifier).onProgressUpdate(update);
  },
  onStatus: (update) {
    ref.read(modelDistributionProvider.notifier).onStatusUpdate(update);
  },
);
```

### Pattern 3: Chunked SHA-256 Verification

**What:** Compute SHA-256 of the 2.14 GB file without loading the whole file into memory.

**When to use:** After download completes and on every subsequent app launch before model load.

```dart
// Source: https://pub.dev/packages/crypto (v3.0.7)
// Pattern from: https://djangocas.dev/blog/flutter/calculate-file-crypto-hash-sha1-sha256-sha512/

import 'dart:io';
import 'package:crypto/crypto.dart';
import 'model_constants.dart';

Future<bool> verifySha256(File modelFile) async {
  final sink = sha256.startChunkedConversion(
    ChunkedConversionSink.withCallback((digest) {
      // handled in completer below
    }),
  );

  // Use openRead() so we don't load 2.14 GB into memory at once
  final stream = modelFile.openRead();
  await for (final chunk in stream) {
    sink.add(chunk);
  }
  sink.close();

  // Alternative, cleaner approach using stream directly:
  final bytes = await modelFile.openRead().expand((chunk) => chunk).toList();
  final digest = sha256.convert(bytes); // CAUTION: this loads all bytes
  return digest.toString() == ModelConstants.sha256Hash;
}

// PREFERRED: streaming approach for 2.14 GB file
Future<String> computeSha256Stream(File file) async {
  final output = AccumulatorSink<Digest>();
  final input = sha256.startChunkedConversion(output);
  final stream = file.openRead();
  await for (final chunk in stream) {
    input.add(chunk);
  }
  input.close();
  return output.events.single.toString();
}

Future<bool> verifyModelIntegrity(File modelFile) async {
  if (!await modelFile.exists()) return false;
  final hash = await computeSha256Stream(modelFile);
  return hash == ModelConstants.sha256Hash;
}
```

**Important:** Do NOT use `File.readAsBytes()` for a 2.14 GB file — it loads the entire file into RAM and will OOM on mobile. Always use `openRead()` with chunked conversion.

### Pattern 4: Connectivity Check Before Download

**What:** Detect Wi-Fi vs cellular before starting download; show warning dialog if cellular.

**When to use:** In pre-flight check, before showing download screen or starting download.

```dart
// Source: https://pub.dev/packages/connectivity_plus (v7.0.0)

import 'package:connectivity_plus/connectivity_plus.dart';

Future<ConnectionType> checkConnectionType() async {
  final results = await Connectivity().checkConnectivity();
  if (results.contains(ConnectivityResult.wifi)) return ConnectionType.wifi;
  if (results.contains(ConnectivityResult.ethernet)) return ConnectionType.wifi;
  if (results.contains(ConnectivityResult.mobile)) return ConnectionType.cellular;
  return ConnectionType.none;
}

enum ConnectionType { wifi, cellular, none }

// Note: ConnectivityResult.none means no connection at all.
// ConnectivityResult.other covers VPN etc — treat as cellular (worst case).
```

### Pattern 5: Storage Pre-flight Check

**What:** Check that at least 2.5 GB is free (model is 2.14 GB; 2.5 GB gives buffer for GGUF loading overhead) before starting download.

**When to use:** During "Preparing download..." pre-flight state.

```dart
// Source: https://pub.dev/packages/disk_space_plus (v0.2.6)

import 'package:disk_space_plus/disk_space_plus.dart';
import 'package:path_provider/path_provider.dart';

/// Returns null if space is sufficient, or a StorageError with details.
Future<StorageError?> checkStorageSpace() async {
  final dir = await getApplicationSupportDirectory();
  final diskSpacePlus = DiskSpacePlus();
  final freeMB = await diskSpacePlus.getFreeDiskSpaceForPath(dir.path) ?? 0;
  const neededMB = 2500; // 2.14 GB + buffer for OS overhead

  if (freeMB < neededMB) {
    return StorageError(
      availableMB: freeMB.toInt(),
      neededMB: neededMB,
    );
  }
  return null;
}
```

### Pattern 6: RAM Check Before Model Load

**What:** Check device RAM before loading the 2.14 GB model; warn if < 4 GB physical RAM.

**When to use:** In `ModelDistributionNotifier` after SHA-256 verification passes, before triggering inference load.

```dart
// Source: https://pub.dev/packages/system_info_plus (v0.0.6)

import 'package:system_info_plus/system_info_plus.dart';

Future<bool> isLowMemoryDevice() async {
  final memoryMB = await SystemInfoPlus.physicalMemory;
  // Q4_K_M is 2.14 GB on disk; peaks higher in RAM during KV cache allocation.
  // Devices with < 4 GB physical RAM are high-risk for OOM.
  return (memoryMB ?? 9999) < 4096;
}
```

### Pattern 7: Greyscale-to-Color Logo Transition

**What:** Animate the BittyBot logo from greyscale to full color using `ColorFiltered` + `TweenAnimationBuilder`.

**When to use:** When `ModelReadyState` is reached — the animation is the "ready" signal.

```dart
// Source: Flutter API docs - ColorFiltered, TweenAnimationBuilder

import 'package:flutter/widgets.dart';

class LogoWithLoadingState extends StatelessWidget {
  const LogoWithLoadingState({
    super.key,
    required this.isReady,
    required this.logoAsset,         // 'assets/logo_color.png'
    required this.logoGreyscaleAsset, // 'assets/logo_greyscale.png'
  });

  final bool isReady;
  final String logoAsset;
  final String logoGreyscaleAsset;

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 600),
      crossFadeState: isReady
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      firstChild: Image.asset(logoGreyscaleAsset, width: 120),
      secondChild: Image.asset(logoAsset, width: 120),
    );
  }
}

// Alternative: use ColorFiltered on a single asset (no second asset needed).
// Requires a Matrix4-based ColorFilter for saturation control.
// Using two assets (greyscale + color) is simpler and avoids ColorFilter issues
// reported in Flutter #179606 (BlendMode.saturation applied to full screen).
```

**Recommendation:** Use two separate asset files (greyscale PNG and full-color PNG) as `AnimatedCrossFade` children. This avoids the known Flutter bug where `ColorFilter.mode(Colors.grey, BlendMode.saturation)` on `ColorFiltered` can affect the entire screen (issue #179606, reported December 2025).

### Pattern 8: Persist Download Progress for Resume Prompt

**What:** Save download progress fraction to `shared_preferences` so resume prompt shows correct percentage on next launch.

**When to use:** On every `onProgress` callback during download; read on app launch to detect interrupted download.

```dart
// Source: https://pub.dev/packages/shared_preferences (v2.5.4)

import 'package:shared_preferences/shared_preferences.dart';

const _kDownloadProgressKey = 'model_download_progress';
const _kDownloadTaskIdKey = 'model_download_task_id';

// Save on each progress update (throttle to every 5% to avoid disk hammering)
Future<void> saveDownloadProgress(double fraction) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble(_kDownloadProgressKey, fraction);
}

// On launch: check if interrupted download exists
Future<double?> getSavedDownloadProgress() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getDouble(_kDownloadProgressKey);
}

// Clear after successful completion or user starts fresh
Future<void> clearDownloadProgress() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_kDownloadProgressKey);
  await prefs.remove(_kDownloadTaskIdKey);
}
```

### Pattern 9: Error Escalation After Repeated Failures (Claude's Discretion)

**Recommended strategy:** Progressive detail on failure messages, with troubleshooting hints after 3+ failures.

```
Failure 1-2: Simple error + "Try again" button
  Message: "Download failed. Check your connection and try again."

Failure 3+: Troubleshooting hints shown below the retry button:
  • Make sure you have at least 2.5 GB of free storage
  • Try switching from cellular to Wi-Fi
  • Force-close the app and reopen it to resume
  • If the problem persists, try again in a few minutes — the server may be temporarily busy
```

This mirrors the Hugging Face download server's known occasional rate-limiting behavior for large files.

### Anti-Patterns to Avoid

- **Loading 2.14 GB into RAM for SHA-256:** Use `file.openRead()` with `sha256.startChunkedConversion()` — never `file.readAsBytes()` for files this large.
- **Not setting `allowPause: true`:** On Android, without this, any download over 9 minutes silently fails with `TaskStatus.failed` — the user sees a broken download with no explanation.
- **Not setting `priority: 0` on Android 14+:** Without UIDT, a 2.14 GB download will almost certainly be interrupted by the 9-minute WorkManager limit. Set `priority: 0` to get UIDT execution context.
- **Using `BaseDirectory.temporary` for model storage:** The OS clears the temp directory at any time. Use `BaseDirectory.applicationSupport` so the model persists across launches.
- **Using `requiresWiFi: true` on the task and not the global config:** The `requiresWiFi` task parameter gates the download at the OS scheduler level — once a task with `requiresWiFi: true` is enqueued, it will not start over cellular. This is correct for the default Wi-Fi-only path. For the cellular override (user accepts the warning), enqueue a separate task with `requiresWiFi: false`.
- **Trusting `ConnectivityResult.wifi` as proof of internet access:** Wi-Fi result means the device is connected to a Wi-Fi network, not that the network has internet (captive portals). The download will fail and trigger the retry path — this is acceptable behavior.
- **ColorFiltered with BlendMode.saturation on a full-screen parent:** Known Flutter bug (issue #179606, Dec 2025) greyscales the entire screen. Use two separate image assets instead.
- **Running SHA-256 on the UI thread:** The 2.14 GB SHA-256 check takes 5–15 seconds on mobile. Run it in an isolate or use `compute()` to avoid UI jank.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Background file download with resume | Custom `http` package + file write loop | `background_downloader` 9.5.2 | iOS 4-hour URLSession constraint, Android 9-min WorkManager timeout with auto-resume, notification integration — weeks of platform work already done |
| Download progress notifications | `flutter_local_notifications` + custom logic | `background_downloader` built-in `configureNotification` | Package handles notification channel setup, progress bar updates, pause/resume actions from notification, foreground/background behavior per platform |
| Connectivity type detection | `dart:io` socket probe | `connectivity_plus` 7.0.0 | `checkConnectivity()` returns `List<ConnectivityResult>` with Wi-Fi/cellular distinction; socket probe only tests reachability, not connection type |
| SHA-256 of a large file | Custom byte-by-byte hash | `crypto` 3.0.7 `startChunkedConversion` | Verified implementation, chunked streaming API already handles buffer management; hand-rolling SHA-256 is error-prone and unnecessary |
| Free disk space check | `dart:io` `FileStat` | `disk_space_plus` 0.2.6 | `FileStat` gives file metadata, not available disk space; platform-specific queries are encapsulated in `disk_space_plus` |
| RAM check | Device info heuristics | `system_info_plus` 0.0.6 | `SystemInfoPlus.physicalMemory` gives actual device RAM in MB; heuristics based on device model are unreliable |

**Key insight:** The download infrastructure (iOS URLSession + Android WorkManager + UIDT + notifications) is the hardest part of this phase. `background_downloader` encapsulates 18+ months of platform-specific work. The app's job is to configure it correctly, not replace it.

---

## Common Pitfalls

### Pitfall 1: Android 9-Minute Download Timeout

**What goes wrong:** The 2.14 GB download fails silently after 9 minutes with `TaskStatus.failed` on Android. User sees an error with no explanation.

**Why it happens:** Android WorkManager tasks (the default `background_downloader` mode) have a hard 9-minute execution window in the background. A 2.14 GB file on a typical mobile connection (10–50 Mbps) takes 5–30 minutes.

**How to avoid:** Always set `allowPause: true` AND `priority: 0` on the `DownloadTask`. `allowPause: true` causes the package to auto-pause and re-enqueue when approaching the limit. `priority: 0` on Android 14+ triggers UIDT mode with no time limit. For Android 10–13, combine `allowPause: true` with `Config.runInForegroundIfFileLargerThan(500)` to use foreground service mode.

**Warning signs:** Download progresses to 40–60% then fails; Android logcat shows `JobScheduler` timeout; no retry attempt follows the failure.

### Pitfall 2: SHA-256 OOM on 2.14 GB File

**What goes wrong:** App crashes during integrity check with OOM error when trying to load the full GGUF into RAM.

**Why it happens:** `File.readAsBytes()` on a 2.14 GB file attempts to allocate a 2.14 GB byte array, exhausting heap. Android and iOS mobile heaps cannot accommodate this.

**How to avoid:** Use `file.openRead()` with `sha256.startChunkedConversion()`. The stream processes 64 KB chunks at a time. Total memory usage stays under 1 MB during verification. Additionally, run the hash computation via `compute()` or an `Isolate` to avoid blocking the UI thread.

**Warning signs:** App crashes 2–5 seconds after "Verifying download..." appears; Android logcat shows `OutOfMemoryError`; iOS shows `EXC_RESOURCE RESOURCE_TYPE_MEMORY`.

### Pitfall 3: Model File in Temp Directory Gets Deleted

**What goes wrong:** Model downloads successfully, app opens, works. User opens app two days later and gets the download screen again because the model file is gone.

**Why it happens:** `BaseDirectory.temporary` maps to the OS temp directory, which the OS clears aggressively (especially on iOS during low storage). The 2.14 GB file is an obvious target.

**How to avoid:** Always use `BaseDirectory.applicationSupport`. On iOS this maps to `Application Support/` (excluded from iCloud backup by default, preserved across launches). On Android this maps to `/data/data/com.package/files/`.

**Warning signs:** Reports of "had to download again"; SHA-256 check on launch fails because file doesn't exist.

### Pitfall 4: iOS Background URLSession Not Completing

**What goes wrong:** Download starts on iOS, user backgrounds the app, download stops and never resumes. Or: download completes in background but app doesn't get notified.

**Why it happens:** iOS Background Fetch capability must be enabled in Xcode; without it, URLSessions are not allowed to continue when the app is in the background. Additionally, without the UNUserNotificationCenter delegate set in AppDelegate.swift, completion notifications don't fire.

**How to avoid:**
- Enable "Background Fetch" mode in Xcode: Runner target → Signing & Capabilities → Background Modes → Background Fetch.
- Add to `AppDelegate.swift`: `UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate`
- iOS limits background downloads to 4 hours total. The 2.14 GB file is well within this limit on any reasonable connection.

**Warning signs:** iOS Simulator shows download completing but physical device downloads freeze after backgrounding; `background_downloader` status never transitions from `running` to `complete` after backgrounding.

### Pitfall 5: Resume Prompt Showing 0% (State Not Persisted)

**What goes wrong:** User downloads 70%, backgrounds the app, reopens it. Resume prompt shows 0% or no saved state, so user sees a fresh download instead of the expected 60% starting point.

**Why it happens:** `background_downloader` task progress exists in the package's internal database while the task is active, but the UI-layer progress fraction (for the progress bar) must be explicitly persisted by the app.

**How to avoid:** Throttle `onProgress` saves to `shared_preferences` at every 5% increment (avoid writing on every callback — that's too frequent for disk I/O). On app launch, read saved fraction from `shared_preferences` to populate the `ResumePromptState`. Also query `FileDownloader().taskRecord(taskId)` to get the `background_downloader` task's own saved state — these should agree.

**Warning signs:** Resume prompt shows correct text but progress bar starts at 0; saved progress is 0.0 in `shared_preferences` even though download was mid-way.

### Pitfall 6: Foreground Service Not Activated for Android API 28–33

**What goes wrong:** Download on Android 12/13 device times out at 9 minutes because UIDT (Android 14+) doesn't apply, and WorkManager hasn't been promoted to foreground service.

**Why it happens:** UIDT (`priority: 0`) only activates on Android 14+. On Android 10–13, the 9-minute limit applies unless a foreground service is explicitly activated.

**How to avoid:** Add `Config.runInForegroundIfFileLargerThan(500)` configuration. This promotes the download to foreground service when the file exceeds 500 MB. Requires `FOREGROUND_SERVICE_DATA_SYNC` permission in `AndroidManifest.xml` (API 34+) and `FOREGROUND_SERVICE` permission generally.

**Warning signs:** Works on Android 14 test device but fails on Android 12/13 devices.

### Pitfall 7: Missing Android Manifest Declarations

**What goes wrong:** App crashes or throws a `PlatformException` when trying to start a foreground download or show notifications.

**Why it happens:** Android 13+ (API 33) requires `POST_NOTIFICATIONS` permission. Android 14+ (API 34) requires `FOREGROUND_SERVICE_DATA_SYNC` and a service declaration for `SystemForegroundService` with `foregroundServiceType="dataSync"`. UIDT requires `RUN_USER_INITIATED_JOBS` and the `.UIDTJobService` declaration.

**How to avoid:** See AndroidManifest.xml snippet in Code Examples below.

**Warning signs:** `SecurityException: Permission Denial` in logcat; notifications never appear; UIDT download silently falls back to WorkManager.

---

## Android Platform Setup

### Required AndroidManifest.xml Additions

```xml
<!-- android/app/src/main/AndroidManifest.xml -->

<!-- Notifications (Android 13+) -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- Foreground Service (for runInForegroundIfFileLargerThan) -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />

<!-- Foreground Service type for data sync (Android 14+) -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC" />

<!-- UIDT mode (Android 14+) -->
<uses-permission android:name="android.permission.RUN_USER_INITIATED_JOBS" />

<application ...>
  <!-- Foreground service declaration (for runInForeground) -->
  <service
    android:name="androidx.work.impl.foreground.SystemForegroundService"
    android:foregroundServiceType="dataSync"
    tools:node="merge" />

  <!-- UIDT service declaration -->
  <service
    android:name="com.bbfltchimney.background_downloader.UIDTJobService"
    android:exported="false"
    android:permission="android.permission.BIND_JOB_SERVICE" />
</application>
```

### Kotlin Version Requirement

```gradle
// android/settings.gradle
plugins {
    id "org.jetbrains.kotlin.android" version "2.1.0" apply false
}
```

### NDK Version (from Phase 1 decisions)

```groovy
// android/app/build.gradle
android {
  ndkVersion "28.0.12674087"
}
```

---

## iOS Platform Setup

### Xcode: Background Fetch Capability

1. Select Runner target in Xcode
2. Signing & Capabilities tab
3. Add "Background Modes" capability
4. Enable "Background Fetch"

### AppDelegate.swift

```swift
// ios/Runner/AppDelegate.swift
import UIKit
import Flutter
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Required for background_downloader notifications
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

---

## Code Examples

### Complete DownloadTask Setup

```dart
// Source: https://pub.dev/packages/background_downloader (v9.5.2 docs)

// Call once during app initialization (in main.dart or a provider init)
await FileDownloader().configure(
  globalConfig: [
    // Activate foreground service for files > 500 MB (covers Android 10–13)
    (Config.runInForegroundIfFileLargerThan, 500),
    // Fail download if less than 2.5 GB free (2560 MB)
    (Config.checkAvailableSpace, 2560),
  ],
  androidConfig: [],
  iOSConfig: [],
);

FileDownloader().configureNotification(
  running: const TaskNotification(
    'Downloading language model',
    '{progress}',
  ),
  paused: const TaskNotification('Download paused', '{displayName}'),
  complete: const TaskNotification('Download complete', 'Open BittyBot to continue'),
  error: const TaskNotification('Download failed', 'Tap to retry'),
  progressBar: true,
);

final task = DownloadTask(
  url: 'https://huggingface.co/CohereLabs/tiny-aya-global-GGUF/resolve/main/tiny-aya-global-q4_k_m.gguf?download=true',
  filename: 'tiny-aya-global-q4_k_m.gguf',
  directory: 'models',
  baseDirectory: BaseDirectory.applicationSupport,
  updates: Updates.statusAndProgress,
  allowPause: true,
  priority: 0,
  retries: 3,
  displayName: 'Tiny Aya language model',
);
```

### SHA-256 Verification (Chunked, Isolate-safe)

```dart
// Source: https://pub.dev/packages/crypto (v3.0.7)

import 'dart:io';
import 'dart:isolate';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

// Run in compute() to avoid blocking UI thread
Future<bool> verifyModelFile(File modelFile) async {
  return compute(_computeSha256Match, modelFile.path);
}

bool _computeSha256Match(String filePath) {
  final file = File(filePath);
  if (!file.existsSync()) return false;

  final output = AccumulatorSink<Digest>();
  final input = sha256.startChunkedConversion(output);

  final raf = file.openSync(mode: FileMode.read);
  const chunkSize = 65536; // 64 KB
  try {
    while (true) {
      final chunk = raf.readSync(chunkSize);
      if (chunk.isEmpty) break;
      input.add(chunk);
    }
  } finally {
    raf.closeSync();
  }

  input.close();
  final digest = output.events.single;
  return digest.toString() == 'd01d995272af305b2b843efcff8a10cf9869cf53e764cb72b0e91b777484570a';
}
```

### Riverpod Notifier Skeleton

```dart
// Source: https://riverpod.dev/docs/whats_new (Riverpod 3.2.1)

import 'package:flutter_riverpod/flutter_riverpod.dart';

@riverpod
class ModelDistribution extends _$ModelDistribution {
  @override
  ModelDistributionState build() => const CheckingModelState();

  Future<void> initialize() async {
    // 1. Check if model already exists and is valid
    state = const CheckingModelState();
    final modelFile = await _resolveModelFile();

    if (await modelFile.exists()) {
      state = const VerifyingState();
      final isValid = await verifyModelFile(modelFile);
      if (isValid) {
        await _proceedToLoad();
        return;
      }
      // Corrupted — delete and re-download
      await modelFile.delete();
    }

    // Check for interrupted download
    final savedProgress = await getSavedDownloadProgress();
    if (savedProgress != null && savedProgress > 0.0) {
      state = ResumePromptState(progressFraction: savedProgress);
      return; // Wait for user action
    }

    // Fresh download — run pre-flight
    await _runPreflight();
  }

  Future<void> _runPreflight() async {
    state = const PreflightState();

    // Storage check
    final storageError = await checkStorageSpace();
    if (storageError != null) {
      state = InsufficientStorageState(
        neededBytes: storageError.neededMB * 1024 * 1024,
        availableBytes: storageError.availableMB * 1024 * 1024,
      );
      return;
    }

    // Connectivity check
    final connection = await checkConnectionType();
    if (connection == ConnectionType.none) {
      state = const ErrorState(message: 'No internet connection', failureCount: 0);
      return;
    }
    if (connection == ConnectionType.cellular) {
      state = const CellularWarningState();
      return; // Wait for user action
    }

    await _startDownload();
  }

  Future<void> confirmCellularDownload() => _startDownload();

  Future<void> confirmResume() => _startDownload();

  Future<void> _startDownload() async {
    // ... configure task and start FileDownloader().download(...)
  }

  Future<void> _proceedToLoad() async {
    // RAM check
    if (await isLowMemoryDevice()) {
      state = LowMemoryWarningState(
        availableMB: (await SystemInfoPlus.physicalMemory) ?? 0,
      );
      return; // Wait for user to acknowledge
    }
    state = const LoadingModelState();
    // Phase 4 wires actual inference load; this phase establishes the state
    // The notifier should expose a method that Phase 4 calls to signal readiness
  }

  Future<void> acknowledgeMemoryWarning() => _proceedToLoad();
}
```

### Connectivity Check with Riverpod

```dart
// Source: https://pub.dev/packages/connectivity_plus (v7.0.0)

@riverpod
Stream<List<ConnectivityResult>> connectivityStream(Ref ref) {
  return Connectivity().onConnectivityChanged;
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `flutter_downloader` (isolate-based) | `background_downloader` | 2022 onward | `background_downloader` uses native OS APIs (URLSession/WorkManager), not isolates; more robust background behavior |
| `StateNotifier` + `StateNotifierProvider` | `Notifier` + `NotifierProvider` (Riverpod 3.x) | Riverpod 2.0 (2022), 3.0 (Sept 2025) | `StateNotifier` is now in `package:riverpod/legacy.dart`; use `Notifier` class |
| WorkManager only for Android downloads | WorkManager + UIDT mode (Android 14+) | Android 14, background_downloader v9.5.0 | UIDT provides unlimited runtime for large user-initiated transfers; triggered by `priority: 0` |
| `google_generative_ai` package | Deprecated | 2025 | Not applicable to this phase, but noted from Phase 1 research |
| `AsyncValue` with `.valueOrNull` | `AsyncValue.value` (sealed, with `progress`) | Riverpod 3.0 | `valueOrNull` renamed to `value`; `AsyncLoading` accepts optional `progress` property |

**Deprecated/outdated:**
- `flutter_downloader`: Older approach using isolates; less robust on iOS background; use `background_downloader` instead
- `StateNotifier` from Riverpod: Now in legacy import; use `Notifier`
- `connectivity` (old package): Replaced by `connectivity_plus`

---

## Open Questions

1. **Does the HuggingFace CDN support HTTP Range requests for resume?**
   - What we know: HuggingFace uses Cloudfront CDN for large files. Cloudfront supports Range requests. `background_downloader` uses OS-level resume which requires the server to support `Accept-Ranges: bytes`.
   - What's unclear: Whether the HuggingFace resolve URL with `?download=true` preserves Range headers through its redirect chain.
   - Recommendation: During Phase 1 spike (or early in Phase 2 implementation), test a manual HTTP Range request against the URL. If Range is not supported, `allowPause: true` will still result in a restart-from-0 on Android timeout — which is better than failure, but not a true resume.
   - Confidence: MEDIUM — CDN Range support is standard but should be verified empirically.

2. **What is the correct SHA-256 for the model file after the "last updated 2 days ago" change?**
   - What we know: The HuggingFace file page shows SHA-256 `d01d995272af305b2b843efcff8a10cf9869cf53e764cb72b0e91b777484570a` for `tiny-aya-global-q4_k_m.gguf`. The file was updated 2 days ago (relative to 2026-02-19, meaning around 2026-02-17).
   - What's unclear: Whether the SHA-256 shown on the page is current and stable, or whether an ongoing quantization re-upload could change it.
   - Recommendation: Verify the hash one more time just before shipping Phase 2. The model just launched (TechCrunch 2026-02-17), so the GGUF files may still be settling. Store the hash as a constant but make it easy to update via a single-line config change.
   - Confidence: HIGH for current value; MEDIUM for long-term stability.

3. **Phase 4 interface: how does Phase 2 signal model readiness to the inference layer?**
   - What we know: Phase 4 builds the inference pipeline. Phase 2 delivers the model file and establishes `ModelReadyState`. The interface between them needs a contract.
   - What's unclear: Whether Phase 4 will use the same Riverpod notifier (extending it) or a separate notifier that watches Phase 2's state.
   - Recommendation: Phase 2 should expose a `modelFilePath` getter on the notifier and a `ModelReadyState` that Phase 4's notifier can watch. Phase 2 should NOT actually load the model — it should only confirm the file is present and valid, then transition to `LoadingModelState`. Phase 4 wires the actual `llama_cpp_dart` load call. The `LoadingModelState` and `ModelReadyState` can be shared states or Phase 4 can replace them with its own states that extend the concept.

4. **`disk_space_plus` maintenance status**
   - What we know: v0.2.6 published 8 months ago; unverified publisher on pub.dev.
   - What's unclear: Whether this package is actively maintained. The pub points are not listed in search results (suggesting lower score).
   - Recommendation: If `disk_space_plus` shows reliability issues, fall back to `dart:io`'s `Directory.statSync()` on Android (which includes file system info) or call a platform channel. Alternatively, `flutter_file_manager` or `df` system call via `Process.run` on Android. This is LOW priority to resolve — the package is simple and the feature is not on a hot path.

---

## Sources

### Primary (HIGH confidence)
- [background_downloader pub.dev](https://pub.dev/packages/background_downloader) — v9.5.2, feature list, platform requirements, Kotlin 2.1.0 requirement
- [background_downloader changelog](https://pub.dev/packages/background_downloader/changelog) — UIDT in v9.5.0 (priority: 0 on Android 14+), networkSpeed/timeRemaining added v7.9.0, skipExistingFiles v9.4.0
- [background_downloader notifications.md](https://github.com/781flyingdutchman/background_downloader/blob/main/doc/notifications.md) — configureNotification API, TaskNotification fields, iOS AppDelegate requirement, platform behavior differences
- [connectivity_plus pub.dev](https://pub.dev/packages/connectivity_plus) — v7.0.0, ConnectivityResult enum values, checkConnectivity() API
- [crypto pub.dev](https://pub.dev/packages/crypto) — v3.0.7, SHA-256, chunked conversion API
- [flutter_riverpod pub.dev](https://pub.dev/packages/flutter_riverpod) — v3.2.1 (published 14 days ago)
- [Riverpod 3.0 What's New](https://riverpod.dev/docs/whats_new) — breaking changes, Notifier class, AsyncValue sealed, Ref.mounted
- [shared_preferences pub.dev](https://pub.dev/packages/shared_preferences) — v2.5.4
- [system_info_plus pub.dev](https://pub.dev/packages/system_info_plus) — v0.0.6, SystemInfoPlus.physicalMemory returns MB
- [disk_space_plus pub.dev](https://pub.dev/packages/disk_space_plus) — v0.2.6, getFreeDiskSpaceForPath API
- [HuggingFace tiny-aya-global-GGUF file page](https://huggingface.co/CohereLabs/tiny-aya-global-GGUF/blob/main/tiny-aya-global-q4_k_m.gguf) — SHA-256 hash, download URL, exact filename
- [Flutter ColorFiltered API docs](https://api.flutter.dev/flutter/widgets/ColorFiltered-class.html) — ColorFiltered widget usage
- [Flutter AnimatedCrossFade API docs](https://api.flutter.dev/flutter/widgets/AnimatedCrossFade-class.html) — crossfade between two children

### Secondary (MEDIUM confidence)
- [background_downloader CONFIG.md](https://github.com/781flyingdutchman/background_downloader/blob/main/doc/CONFIG.md) — runInForegroundIfFileLargerThan, checkAvailableSpace
- [Flutter issue #179606](https://github.com/flutter/flutter/issues/179606) — ColorFilter BlendMode.saturation affects full screen (reported Dec 2025) — drives recommendation to use two-asset crossfade instead
- WebSearch aggregation: Android manifest requirements for FOREGROUND_SERVICE_DATA_SYNC, RUN_USER_INITIATED_JOBS, UIDTJobService

### Tertiary (LOW confidence — verify before use)
- `disk_space_plus` maintenance status (unverified publisher, 8 months since last update)
- HuggingFace CDN Range request support for resume (standard CDN behavior, not empirically tested)
- SHA-256 hash stability (file updated 2 days ago; could change if CohereLabs re-uploads)

---

## Metadata

**Confidence breakdown:**
- Standard stack (libraries and versions): HIGH — all verified from official pub.dev pages
- background_downloader API: HIGH — verified from official GitHub README and changelog
- Model constants (URL, SHA-256, filename): HIGH for filename/URL; MEDIUM for SHA-256 stability (recently uploaded file)
- Android manifest requirements: MEDIUM — inferred from changelog + web search; verify against background_downloader permissions.md before implementation
- Architecture patterns and state machine: HIGH — standard Riverpod 3.x patterns from official docs
- Greyscale transition: HIGH — using Flutter built-in widgets; ColorFiltered bug documented in official Flutter issue tracker

**Research date:** 2026-02-19
**Valid until:** 2026-03-05 (14 days — `background_downloader` and Riverpod update frequently; model file hash may change if CohereLabs re-quantizes)
