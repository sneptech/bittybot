# T-S5: Model Page Warmup Plan

## Goal
Pre-fault all mmap'd model pages into RAM after model load, before first inference request. Ensures consistent TTFT ~2.5s instead of 10s when pages have been evicted.

## File
`lib/features/inference/application/inference_isolate.dart`

## Implementation

### 1. Add imports (top of file)
```dart
import 'dart:io';
import 'dart:typed_data';
```

### 2. Add warmup helper (after `shouldSendFilteredToken`, before `inferenceIsolateMain`)
```dart
/// Pre-fault mmap'd model pages into RAM by reading the file sequentially.
///
/// With mmap enabled, the OS lazily loads model pages on first access.
/// Reading through the entire file forces all pages into RAM upfront,
/// trading ~10-20s of load time for consistent TTFT on the first inference.
/// Non-fatal: if the read fails, the model still works but may page-fault
/// during inference.
void _warmupModelPages(String modelPath) {
  try {
    final raf = File(modelPath).openSync(mode: FileMode.read);
    final buffer = Uint8List(65536); // 64 KB read buffer
    try {
      while (raf.readIntoSync(buffer) > 0) {
        // Reading triggers page faults — no processing needed
      }
    } finally {
      raf.closeSync();
    }
  } catch (_) {
    // Non-fatal — model is still usable, just may page-fault during inference
  }
}
```

### 3. Call warmup in LoadModelCommand handler (after Llama constructor, before ModelReadyResponse)
In the `LoadModelCommand` handler, after line 73 (`llama = Llama(...)` block closes), before `mainSendPort.send(const ModelReadyResponse())`:

```dart
        llama = Llama(
          message.modelPath,
          modelParams: modelParams,
          contextParams: contextParams,
          verbose: false,
        );

        // Pre-fault mmap'd pages so first inference doesn't page-fault
        _warmupModelPages(message.modelPath);

        mainSendPort.send(const ModelReadyResponse());
```

## What NOT to change
- No changes to GenerateCommand, StopCommand, ClearContextCommand, or ShutdownCommand handlers
- No changes to token filtering logic
- No changes to inference_message.dart or any other file
- No new test file — this is pure I/O in an isolate, tested on-device via profiling

## Validation
- `dart analyze lib/features/inference/application/inference_isolate.dart` — must be clean
- `dart analyze lib/` — must be clean
- Existing tests must still pass: `flutter test test/features/inference/`

## Notes
- `dart:io` is a Dart core library, NOT a Flutter plugin — safe to import in isolates
- The 64KB buffer size balances syscall overhead vs memory usage
- With Q3_K_S (~1.4 GB) at ~80 MB/s flash read speed, warmup takes ~17s
- Users see "Loading model..." UI during this time (already handled by T-C3)
- Total model load: ~7s (Llama constructor) + ~17s (warmup) = ~24s — but TTFT drops from 10s to ~2.5s on first message
