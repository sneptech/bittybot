# T-P0: Profiling & Monitoring Infrastructure — Execution Plan

**Author:** SwiftSpring (Planner)
**Implementer:** SageHill (Worker, Pane 5)
**Reviewer:** SwiftSpring (Pane 2)
**Priority:** FIRST — all performance work (T-P4) depends on this

---

## Overview

Create a lightweight profiling/monitoring layer that instruments the inference pipeline (model load, token generation) with measurable metrics. Output must be machine-parseable (structured JSON log lines) and integrate with Flutter DevTools via `dart:developer` Timeline events.

---

## File Plan

| Action | File | Purpose |
|--------|------|---------|
| NEW | `lib/core/diagnostics/performance_monitor.dart` | Singleton metric tracker |
| NEW | `lib/core/diagnostics/inference_profiler.dart` | `dart:developer` Timeline wrapper |
| MODIFY | `lib/features/inference/application/inference_isolate.dart` | Add timing hooks in generate loop |
| MODIFY | `lib/features/inference/application/llm_service.dart` | Add timing hooks around model load and isolate spawn |
| NEW | `test/core/diagnostics/performance_monitor_test.dart` | Unit tests (write FIRST) |

---

## File 1: `lib/core/diagnostics/performance_monitor.dart`

### Purpose
Singleton that collects, stores, and reports performance metrics. Must work from both the main isolate and be fed data from the inference isolate (via message passing — the monitor itself lives on the main isolate only).

### API Design

```dart
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Singleton performance monitor for inference pipeline metrics.
///
/// Collects timing data for model load, per-request inference, and
/// download progress. Outputs structured JSON log lines via [debugPrint]
/// and exposes a [metrics] getter for programmatic access (debug overlay,
/// test assertions).
///
/// Lives on the main isolate only. Inference isolate timing data is
/// transmitted via new response message fields (see inference_isolate changes).
class PerformanceMonitor {
  // Private constructor — singleton
  PerformanceMonitor._();
  static final PerformanceMonitor instance = PerformanceMonitor._();

  // ---- Model Load Metrics ----

  DateTime? _modelLoadStartTime;
  Duration? _lastModelLoadDuration;

  /// Call when model load begins (in LlmService.start(), before sending LoadModelCommand).
  void markModelLoadStart() {
    _modelLoadStartTime = DateTime.now();
  }

  /// Call when ModelReadyResponse is received.
  void markModelLoadEnd() {
    if (_modelLoadStartTime != null) {
      _lastModelLoadDuration = DateTime.now().difference(_modelLoadStartTime!);
      _modelLoadStartTime = null;
      _emitMetric('model_load', {
        'duration_ms': _lastModelLoadDuration!.inMilliseconds,
      });
    }
  }

  Duration? get lastModelLoadDuration => _lastModelLoadDuration;

  // ---- Per-Request Inference Metrics ----

  final Map<int, _RequestMetrics> _activeRequests = {};

  /// Call when GenerateCommand is sent (in LlmService.generate()).
  void markRequestStart(int requestId) {
    _activeRequests[requestId] = _RequestMetrics(
      startTime: DateTime.now(),
    );
  }

  /// Call when the first TokenResponse arrives for a request.
  void markFirstToken(int requestId) {
    final m = _activeRequests[requestId];
    if (m != null && m.firstTokenTime == null) {
      m.firstTokenTime = DateTime.now();
      m.timeToFirstToken = m.firstTokenTime!.difference(m.startTime);
    }
  }

  /// Call on each TokenResponse to increment token count.
  void markToken(int requestId) {
    final m = _activeRequests[requestId];
    if (m != null) {
      m.tokenCount++;
    }
  }

  /// Call when DoneResponse or ErrorResponse arrives.
  /// Returns the completed metrics snapshot, or null if requestId unknown.
  InferenceMetrics? markRequestEnd(int requestId) {
    final m = _activeRequests.remove(requestId);
    if (m == null) return null;

    final endTime = DateTime.now();
    final totalDuration = endTime.difference(m.startTime);
    final tokensPerSecond = m.tokenCount > 0 && totalDuration.inMilliseconds > 0
        ? m.tokenCount / (totalDuration.inMilliseconds / 1000.0)
        : 0.0;

    final metrics = InferenceMetrics(
      requestId: requestId,
      totalDuration: totalDuration,
      timeToFirstToken: m.timeToFirstToken ?? Duration.zero,
      tokenCount: m.tokenCount,
      tokensPerSecond: tokensPerSecond,
    );

    _lastInferenceMetrics = metrics;

    _emitMetric('inference_request', {
      'request_id': requestId,
      'total_ms': totalDuration.inMilliseconds,
      'ttft_ms': (m.timeToFirstToken ?? Duration.zero).inMilliseconds,
      'token_count': m.tokenCount,
      'tokens_per_sec': tokensPerSecond.toStringAsFixed(2),
    });

    return metrics;
  }

  InferenceMetrics? _lastInferenceMetrics;
  InferenceMetrics? get lastInferenceMetrics => _lastInferenceMetrics;

  // ---- Download Progress Metrics ----

  DateTime? _lastProgressCallbackTime;
  int _progressCallbackCount = 0;
  double _lastProgressValue = 0.0;
  int _progressRegressionCount = 0;

  /// Call on each download progress callback.
  void recordProgressCallback(double progress) {
    final now = DateTime.now();
    _progressCallbackCount++;

    if (progress < _lastProgressValue) {
      _progressRegressionCount++;
      _emitMetric('progress_regression', {
        'callback_num': _progressCallbackCount,
        'old_value': _lastProgressValue.toStringAsFixed(4),
        'new_value': progress.toStringAsFixed(4),
      });
    }

    _lastProgressValue = progress;
    _lastProgressCallbackTime = now;
  }

  int get progressCallbackCount => _progressCallbackCount;
  int get progressRegressionCount => _progressRegressionCount;

  /// Reset download progress tracking (call at download start).
  void resetProgressMetrics() {
    _lastProgressCallbackTime = null;
    _progressCallbackCount = 0;
    _lastProgressValue = 0.0;
    _progressRegressionCount = 0;
  }

  // ---- Output ----

  /// Emits a structured JSON log line via debugPrint.
  /// Format: {"perf":"<category>","ts":"<iso8601>", ...data}
  void _emitMetric(String category, Map<String, Object> data) {
    final payload = <String, Object>{
      'perf': category,
      'ts': DateTime.now().toIso8601String(),
      ...data,
    };
    debugPrint('[PERF] $payload');
  }

  /// Reset all metrics (useful for tests).
  void reset() {
    _modelLoadStartTime = null;
    _lastModelLoadDuration = null;
    _activeRequests.clear();
    _lastInferenceMetrics = null;
    resetProgressMetrics();
  }
}

// ---- Internal tracking class ----

class _RequestMetrics {
  final DateTime startTime;
  DateTime? firstTokenTime;
  Duration? timeToFirstToken;
  int tokenCount = 0;

  _RequestMetrics({required this.startTime});
}

// ---- Public metrics snapshot ----

/// Immutable snapshot of a completed inference request's performance data.
@immutable
class InferenceMetrics {
  final int requestId;
  final Duration totalDuration;
  final Duration timeToFirstToken;
  final int tokenCount;
  final double tokensPerSecond;

  const InferenceMetrics({
    required this.requestId,
    required this.totalDuration,
    required this.timeToFirstToken,
    required this.tokenCount,
    required this.tokensPerSecond,
  });

  @override
  String toString() =>
      'InferenceMetrics(req=$requestId, total=${totalDuration.inMilliseconds}ms, '
      'ttft=${timeToFirstToken.inMilliseconds}ms, tokens=$tokenCount, '
      'tok/s=${tokensPerSecond.toStringAsFixed(2)})';
}
```

### Key Design Decisions
- **Singleton pattern** — matches Flutter convention for shared diagnostic services
- **Main isolate only** — the inference isolate cannot import Flutter; timing data comes via existing SendPort messages
- **`debugPrint` for output** — shows in `flutter logs` / `adb logcat`, can be parsed by external tools
- **Structured format** — `[PERF] {json}` prefix makes it greppable
- **`InferenceMetrics` snapshot** — immutable, testable, available via `lastInferenceMetrics` getter

---

## File 2: `lib/core/diagnostics/inference_profiler.dart`

### Purpose
Thin wrapper around `dart:developer` Timeline events for DevTools integration. Provides named profiling spans that appear in the Flutter DevTools Performance tab.

### API Design

```dart
import 'dart:developer' as developer;

/// Provides named profiling spans for Flutter DevTools Timeline integration.
///
/// Usage:
///   final span = InferenceProfiler.startSpan('model_load');
///   // ... do work ...
///   span.finish();
///
/// Spans appear in DevTools Performance tab under "inference" task.
class InferenceProfiler {
  InferenceProfiler._();

  /// Start a named profiling span. Returns a [ProfileSpan] that must be finished.
  static ProfileSpan startSpan(String name) {
    developer.Timeline.startSync(name, flow: developer.Flow.begin(_flowId));
    return ProfileSpan._(name);
  }

  static int _flowId = 0;

  /// Increment flow ID to correlate spans within a single request.
  static int newFlow() => ++_flowId;
}

/// A running profiling span. Call [finish] to close it.
class ProfileSpan {
  final String name;
  final Stopwatch _stopwatch = Stopwatch()..start();

  ProfileSpan._(this.name);

  /// End this profiling span. Records elapsed time in the Timeline.
  void finish() {
    _stopwatch.stop();
    developer.Timeline.finishSync();
  }

  /// Elapsed time since span started.
  Duration get elapsed => _stopwatch.elapsed;
}
```

### Key Design Decisions
- **Static factory** — no instance needed; just `InferenceProfiler.startSpan('name')`
- **Flow IDs** — correlate multiple spans in a single request (e.g., model_load → first_token → done)
- **`Stopwatch`** — more precise than `DateTime.now()` for elapsed time within a single span
- **DevTools visible** — `Timeline.startSync/finishSync` integrates directly with the Performance tab

---

## File 3: Modifications to `inference_isolate.dart`

### Changes Required

The inference isolate runs in a separate Dart isolate that **cannot import Flutter**. Therefore, we CANNOT use `PerformanceMonitor` or `debugPrint` inside the isolate. Instead, we add timing data to the existing response messages so the main isolate can record metrics.

#### Change 1: Add timing fields to `DoneResponse` in `inference_message.dart`

```dart
// In inference_message.dart, modify DoneResponse:
final class DoneResponse extends InferenceResponse {
  final int requestId;
  final bool stopped;

  /// Total generation wall-clock time in milliseconds (measured on isolate).
  final int generationTimeMs;

  /// Number of tokens generated (for cross-checking with main-isolate count).
  final int tokenCount;

  const DoneResponse({
    required this.requestId,
    required this.stopped,
    this.generationTimeMs = 0,
    this.tokenCount = 0,
  });
}
```

#### Change 2: Add timing in the generate handler (`inference_isolate.dart`)

In the `GenerateCommand` handler (lines 63-99), add a `Stopwatch`:

```dart
} else if (message is GenerateCommand) {
  if (llama == null) {
    mainSendPort.send(ErrorResponse(
      requestId: message.requestId,
      message: 'Model not loaded. Send LoadModelCommand first.',
    ));
    return;
  }

  stopped = false;
  int tokenCount = 0;
  final stopwatch = Stopwatch()..start();  // <-- ADD

  try {
    llama!.setPrompt(message.prompt);

    await for (final token in llama!.generateText()) {
      if (stopped) break;

      mainSendPort.send(TokenResponse(
        requestId: message.requestId,
        token: token,
      ));

      tokenCount++;
      if (tokenCount >= message.nPredict) break;
    }

    stopwatch.stop();  // <-- ADD
    mainSendPort.send(DoneResponse(
      requestId: message.requestId,
      stopped: stopped,
      generationTimeMs: stopwatch.elapsedMilliseconds,  // <-- ADD
      tokenCount: tokenCount,                            // <-- ADD
    ));
  } catch (e) {
    mainSendPort.send(ErrorResponse(
      requestId: message.requestId,
      message: e.toString(),
    ));
  }
}
```

**IMPORTANT:** Do NOT import `dart:developer` or any Flutter package in this file. The isolate is a plain Dart isolate.

---

## File 4: Modifications to `llm_service.dart`

### Changes Required

Instrument the main-isolate side with `PerformanceMonitor` and `InferenceProfiler` calls.

#### Change 1: Import diagnostics at top of file

```dart
import '../../../core/diagnostics/performance_monitor.dart';
import '../../../core/diagnostics/inference_profiler.dart';
```

#### Change 2: Instrument `start()` method (lines 75-135)

```dart
Future<void> start() async {
  final monitor = PerformanceMonitor.instance;
  monitor.markModelLoadStart();                          // <-- ADD
  final loadSpan = InferenceProfiler.startSpan('model_load');  // <-- ADD

  // ... existing code up to the firstWhere ...

  await responseStream.firstWhere(
    (msg) => msg is ModelReadyResponse || msg is ErrorResponse,
  ).then((msg) {
    loadSpan.finish();                                    // <-- ADD
    if (msg is ErrorResponse) {
      throw Exception('Model load failed: ${msg.message}');
    }
    monitor.markModelLoadEnd();                           // <-- ADD
    _consecutiveCrashCount = 0;
  });
}
```

#### Change 3: Instrument `generate()` method (lines 144-153)

```dart
int generate({required String prompt, required int nPredict}) {
  final requestId = _nextRequestId++;
  _isGenerating = true;

  PerformanceMonitor.instance.markRequestStart(requestId);  // <-- ADD

  _commandPort!.send(GenerateCommand(
    requestId: requestId,
    prompt: prompt,
    nPredict: nPredict,
  ));
  return requestId;
}
```

#### Change 4: Instrument response listener (lines 90-108)

In the `_responsePort!.listen` callback, add metric tracking for token responses and done responses:

```dart
} else if (message is InferenceResponse) {
  // Track generation state locally before forwarding.
  if (message is TokenResponse) {                              // <-- ADD block
    final monitor = PerformanceMonitor.instance;
    monitor.markFirstToken(message.requestId);  // no-op after first call
    monitor.markToken(message.requestId);
  }                                                            // <-- END

  if (message is DoneResponse) {
    _isGenerating = false;
    _consecutiveCrashCount = 0;
    PerformanceMonitor.instance.markRequestEnd(message.requestId);  // <-- ADD
  } else if (message is ErrorResponse) {
    _isGenerating = false;
    PerformanceMonitor.instance.markRequestEnd(message.requestId);  // <-- ADD
  }

  if (!(_responseController?.isClosed ?? true)) {
    _responseController!.add(message);
  }
}
```

---

## File 5: `test/core/diagnostics/performance_monitor_test.dart`

### TDD — Write These Tests FIRST

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bittybot/core/diagnostics/performance_monitor.dart';

void main() {
  late PerformanceMonitor monitor;

  setUp(() {
    monitor = PerformanceMonitor.instance;
    monitor.reset();
  });

  group('Model Load Metrics', () {
    test('markModelLoadStart and markModelLoadEnd records duration', () {
      monitor.markModelLoadStart();
      // Simulate some load time
      monitor.markModelLoadEnd();

      expect(monitor.lastModelLoadDuration, isNotNull);
      expect(monitor.lastModelLoadDuration!.inMilliseconds, greaterThanOrEqualTo(0));
    });

    test('markModelLoadEnd without start is a no-op', () {
      monitor.markModelLoadEnd();
      expect(monitor.lastModelLoadDuration, isNull);
    });

    test('reset clears model load metrics', () {
      monitor.markModelLoadStart();
      monitor.markModelLoadEnd();
      expect(monitor.lastModelLoadDuration, isNotNull);

      monitor.reset();
      expect(monitor.lastModelLoadDuration, isNull);
    });
  });

  group('Inference Request Metrics', () {
    test('tracks full request lifecycle', () {
      monitor.markRequestStart(42);
      monitor.markFirstToken(42);
      monitor.markToken(42);
      monitor.markToken(42);
      monitor.markToken(42);

      final metrics = monitor.markRequestEnd(42);

      expect(metrics, isNotNull);
      expect(metrics!.requestId, 42);
      expect(metrics.tokenCount, 3);
      expect(metrics.totalDuration.inMilliseconds, greaterThanOrEqualTo(0));
      expect(metrics.timeToFirstToken.inMilliseconds, greaterThanOrEqualTo(0));
      expect(metrics.tokensPerSecond, greaterThanOrEqualTo(0));
    });

    test('markFirstToken only records once', () {
      monitor.markRequestStart(1);
      monitor.markFirstToken(1);
      // Simulate delay
      monitor.markFirstToken(1); // should be ignored
      monitor.markToken(1);

      final metrics = monitor.markRequestEnd(1);
      expect(metrics, isNotNull);
      expect(metrics!.timeToFirstToken.inMilliseconds, greaterThanOrEqualTo(0));
    });

    test('markRequestEnd for unknown requestId returns null', () {
      final metrics = monitor.markRequestEnd(999);
      expect(metrics, isNull);
    });

    test('markToken increments count correctly', () {
      monitor.markRequestStart(10);
      for (int i = 0; i < 50; i++) {
        monitor.markToken(10);
      }
      monitor.markFirstToken(10); // late first token mark

      final metrics = monitor.markRequestEnd(10);
      expect(metrics!.tokenCount, 50);
    });

    test('lastInferenceMetrics returns most recent completed request', () {
      expect(monitor.lastInferenceMetrics, isNull);

      monitor.markRequestStart(1);
      monitor.markToken(1);
      monitor.markRequestEnd(1);

      expect(monitor.lastInferenceMetrics, isNotNull);
      expect(monitor.lastInferenceMetrics!.requestId, 1);

      monitor.markRequestStart(2);
      monitor.markToken(2);
      monitor.markToken(2);
      monitor.markRequestEnd(2);

      expect(monitor.lastInferenceMetrics!.requestId, 2);
      expect(monitor.lastInferenceMetrics!.tokenCount, 2);
    });

    test('reset clears active requests and last metrics', () {
      monitor.markRequestStart(1);
      monitor.markToken(1);
      monitor.markRequestEnd(1);

      monitor.reset();
      expect(monitor.lastInferenceMetrics, isNull);
    });
  });

  group('Download Progress Metrics', () {
    test('tracks callback count', () {
      expect(monitor.progressCallbackCount, 0);

      monitor.recordProgressCallback(0.1);
      monitor.recordProgressCallback(0.2);
      monitor.recordProgressCallback(0.3);

      expect(monitor.progressCallbackCount, 3);
    });

    test('detects progress regressions', () {
      monitor.recordProgressCallback(0.5);
      monitor.recordProgressCallback(0.3); // regression!
      monitor.recordProgressCallback(0.6);
      monitor.recordProgressCallback(0.2); // regression!

      expect(monitor.progressRegressionCount, 2);
    });

    test('monotonic progress has zero regressions', () {
      monitor.recordProgressCallback(0.1);
      monitor.recordProgressCallback(0.2);
      monitor.recordProgressCallback(0.5);
      monitor.recordProgressCallback(1.0);

      expect(monitor.progressRegressionCount, 0);
    });

    test('resetProgressMetrics clears all download tracking', () {
      monitor.recordProgressCallback(0.5);
      monitor.recordProgressCallback(0.3);

      monitor.resetProgressMetrics();
      expect(monitor.progressCallbackCount, 0);
      expect(monitor.progressRegressionCount, 0);
    });
  });

  group('InferenceMetrics snapshot', () {
    test('toString produces readable output', () {
      const m = InferenceMetrics(
        requestId: 7,
        totalDuration: Duration(milliseconds: 1500),
        timeToFirstToken: Duration(milliseconds: 200),
        tokenCount: 25,
        tokensPerSecond: 16.67,
      );

      final s = m.toString();
      expect(s, contains('req=7'));
      expect(s, contains('total=1500ms'));
      expect(s, contains('ttft=200ms'));
      expect(s, contains('tokens=25'));
      expect(s, contains('16.67'));
    });
  });
}
```

---

## Implementation Order (TDD)

SageHill MUST follow this exact order:

### Step 1: Write tests
Create `test/core/diagnostics/performance_monitor_test.dart` with all tests above. Run them — they should all FAIL (class doesn't exist yet).

### Step 2: Create `performance_monitor.dart`
Implement the singleton. Run tests — they should all PASS.

### Step 3: Create `inference_profiler.dart`
Implement the DevTools Timeline wrapper. No unit tests needed for this (it's a thin `dart:developer` wrapper — testable only in integration).

### Step 4: Modify `inference_message.dart`
Add `generationTimeMs` and `tokenCount` fields to `DoneResponse`. Ensure the new fields have default values so existing code doesn't break.

### Step 5: Modify `inference_isolate.dart`
Add `Stopwatch` timing and pass metrics through `DoneResponse`. Do NOT import any Flutter packages in this file.

### Step 6: Modify `llm_service.dart`
Add import of diagnostics files. Instrument `start()`, `generate()`, and the response listener.

### Step 7: Validate
```bash
cd /home/agent/git/bittybot && export PATH="/home/agent/flutter/bin:$PATH"
dart analyze lib/core/diagnostics/
dart analyze lib/features/inference/
dart test test/core/diagnostics/
```

---

## File Reservations

Before starting, SageHill must reserve:
```
file_reservation_paths(
  project_key="/home/agent/git/bittybot",
  agent_name="SageHill",
  paths=[
    "lib/core/diagnostics/**",
    "lib/features/inference/application/inference_isolate.dart",
    "lib/features/inference/application/llm_service.dart",
    "lib/features/inference/domain/inference_message.dart",
    "test/core/diagnostics/**"
  ],
  ttl_seconds=3600,
  exclusive=true,
  reason="T-P0 profiling infrastructure"
)
```

**Note:** `inference_isolate.dart` may conflict with PearlBadger's T-P1 reservation. Check current reservations first — if conflicting, coordinate with RoseFinch/BlueMountain. T-P1 (token filter) modifies the same file but a different section (the TokenResponse send line). Both changes should be merge-safe if done carefully.

---

## Acceptance Criteria

- [ ] `dart analyze lib/` — zero issues
- [ ] All unit tests pass (`dart test test/core/diagnostics/`)
- [ ] Model load duration measurable via `PerformanceMonitor.instance.lastModelLoadDuration`
- [ ] Per-request TTFT, tokens/sec, total time measurable via `lastInferenceMetrics`
- [ ] Download progress regressions detectable via `progressRegressionCount`
- [ ] Structured log lines visible in `flutter logs` output with `[PERF]` prefix
- [ ] DevTools Timeline spans visible for `model_load` (via `InferenceProfiler`)
- [ ] No Flutter imports in `inference_isolate.dart`
- [ ] `DoneResponse` has `generationTimeMs` and `tokenCount` fields with backwards-compatible defaults
