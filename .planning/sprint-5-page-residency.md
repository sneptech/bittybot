# Sprint 5: Page Residency + Cold Start Polish

## Context

Sprint 4 profiling (`.planning/PROFILING-RESULTS.md`) confirmed:
- **Model download, OOM, cold start, token filtering, multi-turn** — all PASS
- **TTFT fails target** (<2s target, actual 3.1-10.7s depending on page residency)
- **tok/s ~2.0** — hardware ceiling for Cortex-A78 + 3.35B model, cannot improve
- **Frame skips regressed** on 2nd cold start (184 vs 65 on 1st launch)
- **Translation quality** fixed (920cb49 prompt tightening)

Root cause: mmap'd model pages (1.55 GB) get evicted from RAM during idle time.
When resident: TTFT ~3.1s. When evicted: TTFT ~10s. We need to keep them resident.

## Sprint 5 Tasks

### S5-T1: posix_fadvise(POSIX_FADV_WILLNEED) via Dart FFI [CRITICAL]

**Goal:** After model loads and warmup reads pages in, call `posix_fadvise` on the model file to advise the kernel to keep pages in cache.

**Why posix_fadvise, not madvise:**
- `madvise()` requires the mmap'd address, which llama.cpp owns internally — we can't get it from the Dart binding
- `posix_fadvise(fd, 0, length, POSIX_FADV_WILLNEED)` works on any open file descriptor
- Tells kernel to initiate readahead for the specified range, keeping pages in cache longer
- Simpler FFI: just need the fd from an open `RandomAccessFile`

**Implementation:**

1. **New file:** `lib/features/inference/data/native_memory_advisor.dart`
   ```dart
   import 'dart:ffi';
   import 'dart:io';

   // POSIX_FADV_WILLNEED = 3 on Linux/Android
   const int _POSIX_FADV_WILLNEED = 3;

   // int posix_fadvise(int fd, off_t offset, off_t len, int advice);
   typedef PosixFadviseNative = Int32 Function(Int32 fd, Int64 offset, Int64 len, Int32 advice);
   typedef PosixFadviseDart = int Function(int fd, int offset, int len, int advice);

   /// Advises the OS to keep the model file's pages in RAM.
   ///
   /// Returns 0 on success, errno on failure. Non-fatal — inference still works
   /// without this, just with higher TTFT variance from page faults.
   int adviseWillNeed(int fd, int fileLength) {
     try {
       final dylib = DynamicLibrary.open('libc.so');
       final posixFadvise = dylib.lookupFunction<PosixFadviseNative, PosixFadviseDart>('posix_fadvise');
       return posixFadvise(fd, 0, fileLength, _POSIX_FADV_WILLNEED);
     } catch (_) {
       return -1; // FFI not available — silently degrade
     }
   }
   ```

2. **Modify:** `lib/features/inference/application/inference_isolate.dart`
   - After `_warmupModelPages(message.modelPath)` call:
   ```dart
   // Advise OS to keep model pages in cache (reduces TTFT variance)
   try {
     final raf = File(message.modelPath).openSync();
     final fileLength = raf.lengthSync();
     final fd = _getFd(raf); // Need to get native fd — see note below
     adviseWillNeed(fd, fileLength);
     // Keep file open — closing may release the advisory
   } catch (_) {
     // Non-fatal
   }
   ```

**Note on getting the file descriptor:**
- `RandomAccessFile` doesn't expose its fd directly in Dart
- Options:
  a. Use `dart:ffi` to call `open()` directly (preferred — full control)
  b. Use `Process.run('cat', ['/proc/self/fd/...'])` (hacky, avoid)
  c. Use a separate `open()` call via libc FFI and keep that fd open

**Recommended approach (option a):** Add `openNative()` to the FFI helper:
```dart
typedef OpenNative = Int32 Function(Pointer<Utf8> path, Int32 flags);
typedef OpenDart = int Function(Pointer<Utf8> path, int flags);

// O_RDONLY = 0
int openReadOnly(String path) {
  final dylib = DynamicLibrary.open('libc.so');
  final open = dylib.lookupFunction<OpenNative, OpenDart>('open');
  final pathPtr = path.toNativeUtf8();
  try {
    return open(pathPtr, 0); // O_RDONLY
  } finally {
    calloc.free(pathPtr);
  }
}
```

Then call `posix_fadvise` on the returned fd. Keep fd open for the duration of the model's lifetime. Close on `ShutdownCommand`.

**Files touched:**
- NEW: `lib/features/inference/data/native_memory_advisor.dart`
- EDIT: `lib/features/inference/application/inference_isolate.dart`

**Validation:**
- `dart analyze lib/features/inference/` — no issues
- `flutter test test/features/inference/` — all pass
- On-device: compare TTFT after 30s idle with and without advisory

---

### S5-T2: Fix 2nd Cold Start Frame Skips [HIGH]

**Problem:** 1st launch: 65 frames skipped (improved from 175). 2nd launch: 184 frames (worse than Sprint 3).

**Root cause hypothesis:** On 2nd launch, the model file exists and SharedPreferences are cached, so `initialize()` runs synchronously through the fast path. The single `Future<void>.delayed(Duration.zero)` yield (T-S4 fix) doesn't provide enough breathing room. The page warmup (reading 1.55 GB) may also be creating I/O contention.

**Fix approach:**

1. **In `model_distribution_notifier.dart`:** Add multiple yield points in `initialize()`:
   ```dart
   // Yield to let Flutter render first frame before any I/O
   await Future<void>.delayed(const Duration(milliseconds: 16)); // One frame

   // ... SharedPreferences + file existence check ...

   await Future<void>.delayed(const Duration(milliseconds: 16)); // Another frame

   // ... proceed to load ...
   ```

2. **In `inference_isolate.dart`:** Make page warmup less aggressive:
   - Add yield points every 64 MB of reading (not every 64 KB)
   - OR: reduce buffer size and add short pauses every N iterations
   - The isolate runs on a separate thread, but heavy I/O on eMMC can still starve the main thread's I/O

3. **Consider deferring warmup:**
   - Don't warmup during model load
   - Instead, warmup in the background AFTER the first frame renders
   - Users see the model as "ready" faster, warmup happens behind the scenes

**Files touched:**
- EDIT: `lib/features/model_distribution/model_distribution_notifier.dart`
- EDIT: `lib/features/inference/application/inference_isolate.dart`

**Validation:**
- `dart analyze lib/` — no issues
- `flutter test test/features/` — all pass
- On-device: measure frame skips on 2nd cold start (target < 50)

---

### S5-T3: Verify Known Bugs Fixed [MEDIUM]

**AGENTS.md lists two P1 bugs:**
1. Wrong screen displayed (shows "Phase 1 Inference Spike" instead of Translation UI)
2. App icon reset to default Flutter icon

**Sprint 4 profiling evidence suggests both are fixed:**
- "Translation screen with enabled input" after cold start
- "BittyBot logo: visible (green/gold robot dog on download screen)"

**Task:** Trace through the code to CONFIRM these are fixed, update AGENTS.md to mark them resolved, and clean up any dead code.

1. Trace: `main.dart` → `app.dart` → `ModelGateWidget` → `AppStartupWidget` → `MainShell` — verify no "Phase 1" text remains
2. Check `android/app/src/main/res/mipmap-*/` for bittybot icon assets
3. Check `lib/widgets/model_loading_screen.dart` for any "Phase 1" references

**Files touched:**
- READ-ONLY verification of startup path
- EDIT: AGENTS.md (mark bugs as resolved)
- EDIT: any files with dead "Phase 1" text if found

---

## Assignment

| Task | Priority | Assigned Manager | Worker Pane | Est. Complexity |
|------|----------|-----------------|-------------|-----------------|
| S5-T1 | CRITICAL | Manager pane 1 | Pane 3 | High (Dart FFI) |
| S5-T2 | HIGH | Manager pane 1 | Pane 4 | Medium |
| S5-T3 | MEDIUM | Manager pane 0 | Pane 5 | Low |

## Process

1. Managers: Register with Agent Mail, pull latest `mowismtest`, read this file + `AGENTS.md`
2. Managers: Send detailed task specs to Codex workers via Agent Mail, then `ntm send bittybot --pane=N` to wake them
3. Workers: Register with Agent Mail (re-use old names if returning), reserve files, implement, commit
4. Managers: Review worker output, request fixes if needed, report completion via Agent Mail
5. All commits on `mowismtest` branch with prefix `perf(inference): [S5-TX]`

## Success Criteria

After Sprint 5:
- TTFT consistently < 5s (even after 30s idle) — down from 10s currently
- Frame skips < 50 on both 1st and 2nd cold start
- Known bugs verified resolved in AGENTS.md
- All tests pass, flutter analyze clean
