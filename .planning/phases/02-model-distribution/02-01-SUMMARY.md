---
phase: 02-model-distribution
plan: 01
subsystem: infra
tags: [background_downloader, flutter_riverpod, connectivity_plus, crypto, disk_space_plus, system_info_plus, sha256, state-machine, sealed-class, android, ios]

# Dependency graph
requires: []
provides:
  - "All Phase 2 dependencies resolved in pubspec.yaml (8 production packages)"
  - "Android manifest with POST_NOTIFICATIONS, FOREGROUND_SERVICE, FOREGROUND_SERVICE_DATA_SYNC, RUN_USER_INITIATED_JOBS permissions and SystemForegroundService + UIDTJobService service declarations"
  - "iOS AppDelegate.swift with UNUserNotificationCenter delegate for background_downloader notification support"
  - "iOS Info.plist with UIBackgroundModes fetch for background URL session transfers"
  - "ModelConstants class with hard-coded download URL, SHA-256 hash, filename, file size, and path helpers"
  - "ModelDistributionState sealed class with 11 exhaustive lifecycle state variants"
  - "verifyModelFile() function using chunked SHA-256 in a compute() isolate — never loads 2.14 GB into RAM"
  - "checkStorageSpace(), isLowMemoryDevice(), checkConnectionType() preflight helpers"
affects:
  - "02-02: notifier and download screen UI consume these types directly"
  - "02-03: app entry point and routing branch on ModelDistributionState variants"
  - "04-core-inference: LoadingModelState and ModelReadyState are the interface contract between Phase 2 and Phase 4"

# Tech tracking
tech-stack:
  added:
    - "background_downloader ^9.5.2 — already present from Phase 1, now configured with manifest declarations"
    - "connectivity_plus ^7.0.0 — Wi-Fi vs cellular detection"
    - "convert ^3.1.2 — AccumulatorSink for chunked SHA-256"
    - "crypto ^3.0.7 — SHA-256 hash computation"
    - "disk_space_plus ^0.2.6 — pre-flight free disk space check"
    - "flutter_riverpod ^3.2.1 — state management (Notifier pattern)"
    - "path_provider ^2.1.5 — already present from Phase 1"
    - "shared_preferences ^2.5.4 — download progress persistence across launches"
    - "system_info_plus ^0.0.6 — device RAM check"
  patterns:
    - "Sealed class with exhaustive state variants for lifecycle state machines (ModelDistributionState)"
    - "compute() isolate for CPU-intensive file operations (SHA-256 on 2.14 GB)"
    - "StorageCheckResult sealed class pattern for explicit success/failure return types"
    - "abstract final class for namespace-scoped constants (ModelConstants)"

key-files:
  created:
    - "android/app/src/main/AndroidManifest.xml — full manifest with UIDT + foreground service permissions"
    - "ios/Runner/AppDelegate.swift — UNUserNotificationCenter delegate setup"
    - "ios/Runner/Info.plist — UIBackgroundModes fetch for iOS background downloads"
    - "lib/features/model_distribution/model_constants.dart — download URL, SHA-256, filename, size, path helpers"
    - "lib/features/model_distribution/model_distribution_state.dart — 11-state sealed class lifecycle"
    - "lib/features/model_distribution/sha256_verifier.dart — chunked compute()-isolated integrity check"
    - "lib/features/model_distribution/storage_preflight.dart — disk space, RAM, connectivity helpers"
  modified:
    - "pubspec.yaml — added 7 new production dependencies (connectivity_plus, convert, crypto, disk_space_plus, flutter_riverpod, shared_preferences, system_info_plus)"
    - "pubspec.lock — resolved all dependency versions"

key-decisions:
  - "Used convert package AccumulatorSink for SHA-256 chunked conversion (not dart:convert — AccumulatorSink comes from package:convert/convert.dart)"
  - "Replaced package:meta import with package:flutter/foundation.dart for @immutable on sealed class (avoids direct meta dependency)"
  - "Set requiredFreeSpaceMB to 2560 (2.14 GB + ~400 MB buffer) to ensure GGUF mmap overhead doesn't fail after download"
  - "Defaulted isLowMemoryDevice() to false on failure so unavailable platform info doesn't block users"
  - "Used abstract final class for ModelConstants rather than abstract class to prevent instantiation and subclassing"

patterns-established:
  - "Sealed class for state machines: use final class subclasses with const constructors and @immutable on the sealed base"
  - "compute() for file I/O: all operations on 2.14 GB file run via compute(_syncFunction, path) to avoid UI jank"
  - "AccumulatorSink pattern: sha256.startChunkedConversion(AccumulatorSink()) with RandomAccessFile.readSync in 64 KB chunks"
  - "StorageCheckResult: sealed return type communicates both success and structured failure without exceptions"
  - "Feature directory: lib/features/model_distribution/ is the canonical location for all Phase 2 Dart code"

requirements-completed: [MODL-01, MODL-02, MODL-04]

# Metrics
duration: 6min
completed: 2026-02-19
---

# Phase 2 Plan 01: Dependencies, Platform Manifests, and Foundation Types Summary

**8 Phase 2 dependencies resolved, Android/iOS platform manifests fully configured for background download, and 4 foundation Dart files (ModelConstants, 11-state sealed class, chunked SHA-256 compute() verifier, storage/connectivity preflight helpers) created with no analyzer errors**

## Performance

- **Duration:** ~6 min
- **Started:** 2026-02-18T18:28:14Z
- **Completed:** 2026-02-18T18:34:00Z
- **Tasks:** 2
- **Files modified:** 9 created, 2 modified

## Accomplishments

- All 8 production dependencies resolve cleanly (`flutter pub get` succeeds, no conflicts)
- Android manifest fully configured for UIDT + foreground service download on Android 10–14+ (4 permissions + 2 service declarations)
- iOS AppDelegate sets UNUserNotificationCenter delegate for background_downloader completion notifications; Info.plist enables Background Fetch
- Four foundation Dart files compile with `dart analyze` reporting no issues — ready for Plan 02 notifier to import directly

## Task Commits

Each task was committed atomically:

1. **Task 1: Add dependencies and configure Android/iOS platform manifests** - `aadef2c` (feat)
2. **Task 2: Create model constants, state machine, SHA-256 verifier, preflight helpers** - `8c2f955` (feat)

## Files Created/Modified

- `pubspec.yaml` — added connectivity_plus, convert, crypto, disk_space_plus, flutter_riverpod, shared_preferences, system_info_plus
- `pubspec.lock` — resolved dependency tree
- `android/app/src/main/AndroidManifest.xml` — full manifest with POST_NOTIFICATIONS, FOREGROUND_SERVICE, FOREGROUND_SERVICE_DATA_SYNC, RUN_USER_INITIATED_JOBS permissions; SystemForegroundService and UIDTJobService service declarations; tools namespace on manifest root
- `ios/Runner/AppDelegate.swift` — @main class with UNUserNotificationCenter delegate line
- `ios/Runner/Info.plist` — full Info.plist with UIBackgroundModes containing "fetch"
- `lib/features/model_distribution/model_constants.dart` — abstract final class with URL, SHA-256, filename, file size, path helpers
- `lib/features/model_distribution/model_distribution_state.dart` — sealed class with 11 state variants (CheckingModel → ModelReady/Error)
- `lib/features/model_distribution/sha256_verifier.dart` — verifyModelFile() via compute() using 64 KB RandomAccessFile chunks
- `lib/features/model_distribution/storage_preflight.dart` — checkStorageSpace(), isLowMemoryDevice(), checkConnectionType() with ConnectionType enum and StorageCheckResult sealed class

## Decisions Made

- Used `package:convert/convert.dart` for `AccumulatorSink` (not `dart:convert`) — AccumulatorSink is defined in the `convert` package
- Used `package:flutter/foundation.dart` for `@immutable` instead of importing `package:meta` directly — Flutter re-exports meta annotations, avoids adding a direct meta dependency
- All state subclasses declared as `final class` (not just `class`) to enforce exhaustive sealing and prevent external extension

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added convert package for AccumulatorSink**
- **Found during:** Task 2 (SHA-256 verifier)
- **Issue:** `dart:convert` does not export `AccumulatorSink` — it comes from `package:convert/convert.dart`. `dart analyze` reported `AccumulatorSink` as undefined.
- **Fix:** Added `convert: ^3.1.2` to pubspec.yaml and updated import in sha256_verifier.dart
- **Files modified:** pubspec.yaml, pubspec.lock, lib/features/model_distribution/sha256_verifier.dart
- **Verification:** `dart analyze lib/features/model_distribution/` reports no issues
- **Committed in:** 8c2f955 (Task 2 commit)

**2. [Rule 3 - Blocking] Replaced meta import with flutter/foundation.dart**
- **Found during:** Task 2 (state machine sealed class)
- **Issue:** `package:meta` is a transitive dependency, not a direct dependency. `dart analyze` warned that importing it directly requires adding it to pubspec.yaml.
- **Fix:** Replaced `import 'package:meta/meta.dart'` with `import 'package:flutter/foundation.dart'` which re-exports `@immutable`
- **Files modified:** lib/features/model_distribution/model_distribution_state.dart
- **Verification:** `dart analyze` reports no issues, `@immutable` annotation works correctly
- **Committed in:** 8c2f955 (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (both Rule 3 — blocking import issues)
**Impact on plan:** Both fixes were necessary for compilation. No scope creep — same outcome as specified, different import path.

## Issues Encountered

- The phase/02-model-distribution worktree branch didn't have Flutter project files (only .planning/ was on the branch). Resolved by checking out Flutter project files from master before starting plan tasks. These files are now on the phase/02 branch for merge at integration time.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Plan 02 can import all four files directly: model_constants.dart, model_distribution_state.dart, sha256_verifier.dart, storage_preflight.dart
- All state variants are defined — notifier in Plan 02 drives state transitions
- Android/iOS platform manifests are configured — background download will work when background_downloader is initialized in Plan 02
- SHA-256 constant matches the verified HuggingFace file (verify again before shipping if file is re-uploaded)

---
*Phase: 02-model-distribution*
*Completed: 2026-02-19*
