# Sprint 6 Report — Handoff to Implementation Team

**Date:** 2026-02-28
**Author:** Claude Opus (profiling/analysis agent)
**Branch:** `mowismtest` @ `792555f`
**Device:** Samsung Galaxy A25 (SM-A256E), Android 14, 5.5 GB RAM, eMMC, Exynos 1280

---

## Executive Summary

Sprint 5 shipped `posix_fadvise(POSIX_FADV_WILLNEED)` which massively improved short-idle TTFT (30s idle: 8-10s → 2.1s). Warm tok/s improved ~15% to 2.3-2.6. However, three user-facing issues were discovered during on-device testing, and a codebase audit uncovered additional bugs. This report documents all findings and provides implementation specs for the next sprint.

---

## Section 1: Performance Profile (Sprint 5 Baseline)

### Current Numbers

| Metric | Value | Target | Status |
|--------|-------|--------|--------|
| Model load | 4.0-8.8s | < 15s | **PASS** |
| TTFT (warm, back-to-back) | 2.1-3.0s | < 5s | **PASS** |
| TTFT (30s idle) | 2.1s | < 5s | **PASS** |
| TTFT (2min idle) | 5.6s | < 5s | **FAIL (borderline)** |
| TTFT (3+ min idle) | 8-11s | < 5s | **FAIL** |
| tok/s (warm) | 2.3-2.6 | ~2 (hw ceiling) | **PASS** |
| Frame skips (cold restart) | 175-192 | < 50 | **FAIL** |
| Translation quality | 3/3 direct | Direct only | **PASS** |
| Multi-turn name recall | FAIL | Pass | **FAIL** |
| Token filtering | Clean | Clean | **PASS** |
| Swap PSS | 206 MB | — | Improved from 226 MB |

### Hardware Ceiling

tok/s of ~2-2.6 is the **hardware ceiling** for Cortex-A78 + 3.35B Q3_K_S. GPU (Mali-G68) is 3-16x slower — ruled out. No path to >3 tok/s on this device without a smaller model.

### Model Configuration (Hardcoded)

| Param | Value | Location |
|-------|-------|----------|
| nCtx | 512 | `inference_message.dart:28` (default) |
| nBatch | 256 | `inference_message.dart:29` (default) |
| nThreads | 6 | `inference_message.dart:30` (default) |
| nPredict (chat) | 512 | `chat_notifier.dart:348` |
| nPredict (translation) | 128 | `translation_notifier.dart` (keepAlive) |
| nGpuLayers | 0 | `inference_isolate.dart:92` |
| useMemorymap | true | `inference_isolate.dart:94` |

All params are hardcoded — no runtime configuration mechanism exists.

---

## Section 2: Bugs Found During On-Device Testing

### BUG-1: Chat Bubbles Show Raw Markdown (P1 — User-Facing)

**Observed:** Chat assistant responses display literal `**bold**` asterisks, `-` list markers, and other markdown syntax as plain text.

**Root cause:** `_buildAssistantBubble()` uses a plain `Text()` widget.

**File:** `lib/features/chat/presentation/widgets/chat_bubble_list.dart:187-192`
```dart
child: Text(
  content,
  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppColors.onSurface,
      ),
),
```

**Translation bubbles are NOT affected** — the model outputs clean translated text in translation mode (verified: 3/3 tests produced plain text). Only chat bubbles need markdown rendering.

**Fix specification:**
1. Add `flutter_markdown` to `pubspec.yaml` dependencies
2. Replace `Text(content, ...)` in `_buildAssistantBubble()` with `MarkdownBody(data: content, ...)`
3. Style the `MarkdownStyleSheet` to match existing `bodyMedium` + `AppColors.onSurface` text style
4. Ensure `selectable: false` (copy is handled by long-press, not text selection)
5. Link taps should be no-ops (offline app — no browser)
6. **Do NOT change translation bubbles** — they are clean

**Copy behavior note:** The long-press copy in `_showBubbleMenu()` copies `content` (raw markdown source). This is fine — the user wants the copyable text, and most downstream paste targets don't render markdown anyway.

---

### BUG-2: Model Identifies as "Aya" Instead of "Bittybot" (P1 — User-Facing)

**Observed:** When asked "What is your name?", the model responds: *"My name is Aya, a language model trained to help with translations."*

**Root cause:** Chat system prompt doesn't establish model identity.

**File:** `lib/features/inference/domain/prompt_builder.dart:31-34`
```dart
static const chatSystemPrompt =
    'You are a translator and language assistant. Help people translate '
    'text and understand languages. If asked about other topics, mention '
    'that translation is your strength.';
```

**Fix specification:**
Replace `chatSystemPrompt` with identity-aware version:
```dart
static const chatSystemPrompt =
    'You are Bittybot, a friendly translator and language assistant. '
    'Your name is Bittybot. Help people translate text and understand '
    'languages. Remember what the user tells you during the conversation. '
    'If asked about other topics, mention that translation is your strength.';
```

**Design constraints for the prompt:**
- Must be short — the 3.35B Q3_K_S model ignores complex instructions
- "Your name is Bittybot" must be explicit (model defaults to "Aya" from training)
- "Remember what the user tells you" is a soft nudge for multi-turn name recall
- Do NOT over-engineer with elaborate personality descriptions — the model can't follow them
- Do NOT change `translationSystemPrompt` — it's working perfectly (3/3 direct translations)

---

### BUG-3: Frame Skips on Cold Restart — 175-192 frames (P1 — UX)

**Observed:** Every cold start produces 175-192 skipped frames (6-8 seconds of frozen UI). Sprint 5 cooperative yields (`Future.delayed(Duration.zero)` every 64 MB) had **zero measurable effect**.

**Root cause analysis:**

The warmup (`_warmupModelPages()`) reads 1.55 GB sequentially through the eMMC bus (~30-40 MB/s random, ~200 MB/s sequential). This saturates the storage I/O bus for ~8-10 seconds. The Flutter rendering thread needs I/O bandwidth for asset loading, font loading, and texture upload during cold start — but the bus is monopolized by the warmup read.

**Why yields didn't help:** The yields occur on the *inference isolate's* event loop, not the main isolate. The main thread isn't blocked by Dart code — it's blocked by the kernel I/O scheduler giving priority to the sequential read over the scattered small reads the UI needs.

**The critical timing problem (inference_isolate.dart:111-121):**
```dart
// Current order — WRONG for UI responsiveness:
llama = Llama(modelPath, ...);           // ~200ms — fast, OK
await _warmupModelPages(modelPath);      // ~8-10s — BLOCKS ModelReadyResponse
advisoryFd = adviseWillNeed(path, len);  // ~1ms — fast
mainSendPort.send(const ModelReadyResponse());  // UI unblocked HERE
```

`ModelReadyResponse` is sent **after** the 8-10s warmup. This means `LlmService.start()` (which awaits `ModelReadyResponse`) is blocked for the full warmup duration. The `modelReadyProvider.build()` in turn awaits `start()`, keeping the UI in "loading" state during the entire warmup.

**Fix specification:**

Reorder to send `ModelReadyResponse` immediately after model construction, then run warmup in the background:

```dart
// inference_isolate.dart LoadModelCommand handler:
llama = Llama(modelPath, modelParams: modelParams, contextParams: contextParams, verbose: false);

// Signal model is ready BEFORE warmup — unblocks the UI
mainSendPort.send(const ModelReadyResponse());

// Warmup runs in background — first inference may page-fault if warmup
// hasn't finished, but the UI renders immediately
await _warmupModelPages(message.modelPath);
try {
  final fileLength = File(message.modelPath).lengthSync();
  advisoryFd = adviseWillNeed(message.modelPath, fileLength);
} catch (_) {
  advisoryFd = -1;
}
```

**Trade-off:** First inference after cold start may have higher TTFT if warmup hasn't completed. But the UI renders immediately (eliminating 175+ frame skips), and the user typically takes 2-5 seconds to type — which is enough time for warmup to finish.

**Risk mitigation:** The `posix_fadvise(POSIX_FADV_WILLNEED)` call happens after warmup anyway. Even if warmup is split off, fadvise alone provides significant page retention (Sprint 5 proved this). The warmup sequential read is a belt-and-suspenders approach.

---

## Section 3: Bugs Found During Code Audit

### BUG-4: Dead Code — `..take(3)` No-Op (P3 — Cosmetic)

**File:** `lib/features/settings/application/settings_provider.dart:156`
```dart
].where((l) => l.isNotEmpty).toSet().toList()..take(3);
```

The cascade operator `..` calls `take(3)` but **discards the return value** and returns the original list. This is a no-op. The actual truncation happens correctly on line 157: `updated.length > 3 ? updated.sublist(0, 3) : updated`.

**Not a crash bug**, but confusing dead code. Remove `..take(3)` for clarity.

---

### BUG-5: Crash Recovery Skips FD Cleanup (P2 — Resource Leak)

**File:** `lib/features/inference/application/llm_service.dart:234-254`

When `_handleCrash()` fires (isolate OOM or unhandled exception), it kills the old isolate immediately (line 243) without sending `ShutdownCommand`. This means:
- The `Llama` FFI instance never calls `dispose()`
- The native fd from `adviseWillNeed()` is never closed by isolate-level cleanup
- FDs accumulate on repeated crash-recovery cycles

**Fix:** Send `ShutdownCommand` before killing the isolate:
```dart
// In _handleCrash(), before _isolate?.kill():
try {
  _commandPort?.send(const ShutdownCommand());
} catch (_) {
  // Command port may already be dead — that's fine
}
_isolate?.kill(priority: Isolate.immediate);
```

---

### BUG-6: Stale TODO Comment (P3 — Hygiene)

**File:** `lib/features/model_distribution/model_distribution_notifier.dart:545-551`
```dart
/// TODO(phase-4): Wire actual llama_cpp inference load here.
```

Phase 4 is complete. Model loading now lives in `llm_service_provider.dart`. The `_loadModel()` method (line 548-551) is a stub that just sets `state = const ModelReadyState()` — this is correct behavior (signals distribution is done), but the TODO comment is misleading.

**Fix:** Remove the TODO comment. Optionally rename `_loadModel()` to `_signalModelReady()` for clarity.

---

### BUG-7: Print Statement Not Guarded for Release Builds (P2 — Production Hygiene)

**File:** `lib/core/diagnostics/performance_monitor.dart:140`
```dart
print(line); // Also print to logcat (developer.log only goes to DevTools)
```

This `print()` is intentional for profiling (marked with `// ignore: avoid_print`) and useful during development. However, it should be guarded with `kDebugMode` for production builds.

**Fix:**
```dart
if (kDebugMode) print(line);
```

Requires `import 'package:flutter/foundation.dart';` (may already be imported).

---

## Section 4: Architectural Notes for Implementers

### File Map (Key Files)

```
lib/
├── main.dart                                          # Entry — GoogleFonts config, runApp
├── app.dart                                           # MaterialApp, theme, localization, routes to ModelGateWidget
├── core/
│   ├── diagnostics/
│   │   ├── inference_profiler.dart                    # Span-based profiling
│   │   └── performance_monitor.dart                   # [PERF] logcat logger (BUG-7: unguarded print)
│   ├── l10n/                                          # 10 ARB files, 87 keys
│   └── theme/
│       ├── app_colors.dart                            # AppColors palette constants
│       ├── app_text_theme.dart                        # Lato 16sp base
│       └── app_theme.dart                             # buildDarkTheme()
├── features/
│   ├── chat/
│   │   ├── application/
│   │   │   ├── chat_notifier.dart                     # Auto-dispose, nPredict=512, system prompt injection
│   │   │   └── chat_session_messages_provider.dart    # StreamProvider.family for session messages
│   │   ├── domain/
│   │   │   ├── chat_message.dart                      # Domain model
│   │   │   └── chat_session.dart                      # Domain model
│   │   └── presentation/widgets/
│   │       └── chat_bubble_list.dart                  # BUG-1: plain Text() for assistant bubbles
│   ├── inference/
│   │   ├── application/
│   │   │   ├── inference_isolate.dart                 # BUG-3: warmup blocks ModelReadyResponse
│   │   │   ├── llm_service.dart                       # BUG-5: crash recovery skips ShutdownCommand
│   │   │   └── llm_service_provider.dart              # ModelReady AsyncNotifier + WidgetsBindingObserver
│   │   ├── data/
│   │   │   ├── inference_repository_impl.dart         # Wraps LlmService for Riverpod
│   │   │   └── native_memory_advisor.dart             # FFI: open(), posix_fadvise(), close()
│   │   └── domain/
│   │       ├── inference_message.dart                 # Sealed command/response classes
│   │       └── prompt_builder.dart                    # BUG-2: chatSystemPrompt lacks "Bittybot" identity
│   ├── model_distribution/
│   │   └── model_distribution_notifier.dart           # BUG-6: stale TODO at line 545
│   ├── settings/
│   │   └── application/settings_provider.dart         # BUG-4: dead ..take(3) on line 156
│   └── translation/
│       └── presentation/widgets/
│           └── translation_bubble_list.dart           # Clean — no markdown issue
└── widgets/
    └── app_startup_widget.dart                        # Async gate: loading → error → onLoaded
```

### Aya Chat Template

The model uses Cohere's Aya chat template. Implementers must NOT change the token format:
```
<|START_OF_TURN_TOKEN|><|USER_TOKEN|>{system_prompt}\n\n{user_message}<|END_OF_TURN_TOKEN|><|START_OF_TURN_TOKEN|><|CHATBOT_TOKEN|>
```

System prompt is injected in the FIRST user turn only. Follow-up turns use `buildFollowUpPrompt()` which omits the system prompt (KV cache retains it).

### Riverpod Provider Graph (Relevant)

```
appStartupProvider (keepAlive, settings only)
    └── settingsProvider (keepAlive, SharedPreferencesWithCache)

modelReadyProvider (keepAlive, AsyncNotifier + WidgetsBindingObserver)
    ├── modelDistributionProvider → modelFilePath
    └── LlmService.start() → inference isolate spawn + model load

chatProvider (auto-dispose)
    ├── modelReadyProvider (watches — isModelReady flag)
    ├── inferenceRepositoryProvider (reads — generate/stop/clear)
    └── chatRepositoryProvider (reads — DB persistence)

translationProvider (keepAlive)
    ├── modelReadyProvider
    ├── inferenceRepositoryProvider
    └── chatRepositoryProvider
```

### State Management Pattern

- `appStartupProvider` does NOT await `modelReadyProvider` — partial-access pattern
- UI is fully usable while model loads; only input field is disabled
- `ChatNotifier` is auto-dispose (fresh state per screen entry, DB is source of truth)
- `TranslationNotifier` is keepAlive (language pair persists across navigation)

### Build & Deploy

```bash
# Build
/home/max/Android/flutter/bin/flutter build apk --debug

# Install
adb install -r build/app/outputs/flutter-apk/app-debug.apk

# Monitor perf
adb logcat -s flutter | grep '\[PERF\]'

# Monitor frame skips
adb logcat -s Choreographer | grep 'Skipped'
```

---

## Section 5: Sprint 6 Task Specifications

### Task Priority Order

| Priority | Task | Bug | Files Changed | Estimated Complexity |
|----------|------|-----|---------------|---------------------|
| 1 | System prompt identity | BUG-2 | 1 file, 4 lines | Trivial |
| 2 | Markdown in chat bubbles | BUG-1 | 2 files (pubspec + bubble widget) | Low |
| 3 | Defer warmup after ModelReadyResponse | BUG-3 | 1 file, ~10 lines moved | Low (but test carefully) |
| 4 | Crash recovery FD cleanup | BUG-5 | 1 file, 3 lines added | Trivial |
| 5 | Print guard for release | BUG-7 | 1 file, 1 line | Trivial |
| 6 | Dead code cleanup | BUG-4, BUG-6 | 2 files, remove lines | Trivial |

### Task 1: System Prompt Identity (BUG-2)

**File:** `lib/features/inference/domain/prompt_builder.dart`
**Lines:** 31-34
**Change:** Replace `chatSystemPrompt` string constant

**Before:**
```dart
static const chatSystemPrompt =
    'You are a translator and language assistant. Help people translate '
    'text and understand languages. If asked about other topics, mention '
    'that translation is your strength.';
```

**After:**
```dart
static const chatSystemPrompt =
    'You are Bittybot, a friendly translator and language assistant. '
    'Your name is Bittybot. Help people translate text and understand '
    'languages. Remember what the user tells you during the conversation. '
    'If asked about other topics, mention that translation is your strength.';
```

**Do NOT touch:** `translationSystemPrompt` (working perfectly).

**Test:** On device, ask "What is your name?" — model should respond "Bittybot" not "Aya". Then "My name is Alex" → follow-up "What is my name?" — should recall "Alex".

---

### Task 2: Markdown Rendering in Chat Bubbles (BUG-1)

**Step 1:** Add dependency to `pubspec.yaml`:
```yaml
  # Sprint 6: Markdown rendering
  flutter_markdown_plus: ^1.0.7
```

Note: `flutter_markdown` (Google's original) was discontinued May 2025. `flutter_markdown_plus` is the maintained fork with 140k+ weekly downloads and identical API.

Then run: `/home/max/Android/flutter/bin/flutter pub get`

**Step 2:** Edit `lib/features/chat/presentation/widgets/chat_bubble_list.dart`

Add import:
```dart
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
```

Replace lines 187-192 in `_buildAssistantBubble()`:

**Before:**
```dart
child: Text(
  content,
  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppColors.onSurface,
      ),
),
```

**After:**
```dart
child: MarkdownBody(
  data: content,
  styleSheet: MarkdownStyleSheet(
    p: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.onSurface,
        ),
    strong: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.onSurface,
          fontWeight: FontWeight.bold,
        ),
    listBullet: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.onSurface,
        ),
  ),
  onTapLink: (_, __, ___) {}, // No-op — offline app
  selectable: false,
),
```

**Do NOT change:**
- `translation_bubble_list.dart` — translation output is clean text
- User bubble widget (`_buildUserBubble`) — user input is plain text
- The copy behavior in `_showBubbleMenu` — copying raw markdown source is fine

**Verify:** `flutter_markdown` version compatibility with Flutter 3.38.5. If `^0.7.6` has conflicts, check pub.dev for the latest compatible version.

---

### Task 3: Defer Warmup After ModelReadyResponse (BUG-3)

**File:** `lib/features/inference/application/inference_isolate.dart`
**Lines:** 111-121 (inside `LoadModelCommand` handler)

**Before (lines 104-121):**
```dart
llama = Llama(
  message.modelPath,
  modelParams: modelParams,
  contextParams: contextParams,
  verbose: false,
);

// Pre-fault mmap'd pages so first inference doesn't page-fault
await _warmupModelPages(message.modelPath);
// Advise OS to keep model pages resident for lower TTFT variance.
try {
  final fileLength = File(message.modelPath).lengthSync();
  advisoryFd = adviseWillNeed(message.modelPath, fileLength);
} catch (_) {
  advisoryFd = -1;
}

mainSendPort.send(const ModelReadyResponse());
```

**After:**
```dart
llama = Llama(
  message.modelPath,
  modelParams: modelParams,
  contextParams: contextParams,
  verbose: false,
);

// Unblock the UI immediately — warmup runs in background
mainSendPort.send(const ModelReadyResponse());

// Pre-fault mmap'd pages and advise OS to keep them resident.
// Runs after ModelReadyResponse so the UI can render while pages load.
// If the user sends a message before warmup finishes, TTFT will be
// higher on that first request (page faults during inference).
await _warmupModelPages(message.modelPath);
try {
  final fileLength = File(message.modelPath).lengthSync();
  advisoryFd = adviseWillNeed(message.modelPath, fileLength);
} catch (_) {
  advisoryFd = -1;
}
```

**Critical constraint:** The `receivePort.listen()` callback is `async`. After `mainSendPort.send(ModelReadyResponse())`, the isolate continues executing the warmup. But if a `GenerateCommand` arrives while warmup is still running, both the warmup read and the inference will compete for I/O bandwidth. This is acceptable — the inference will be slower but won't crash. The alternative (queuing GenerateCommands until warmup finishes) would require a `_warmupComplete` flag and adds complexity that isn't justified.

**Test plan:**
1. Cold start → measure frame skips (target: < 50, was 175-192)
2. Cold start → immediately send message → measure TTFT (may be higher than warm steady-state, but UI should not freeze)
3. Cold start → wait 10s → send message → measure TTFT (should be similar to Sprint 5 warm numbers)

---

### Task 4: Crash Recovery FD Cleanup (BUG-5)

**File:** `lib/features/inference/application/llm_service.dart`
**Method:** `_handleCrash()` (line 234)

Add before line 243 (`_isolate?.kill(...)`):
```dart
// Best-effort cleanup: ask the worker to dispose FFI resources.
// The command port may already be dead if the isolate crashed hard.
try {
  _commandPort?.send(const ShutdownCommand());
} catch (_) {
  // Ignore — port may be closed
}
```

---

### Task 5: Guard Print for Release (BUG-7)

**File:** `lib/core/diagnostics/performance_monitor.dart`
**Line:** 140

**Before:**
```dart
print(line);
```

**After:**
```dart
if (kDebugMode) print(line);
```

Ensure `package:flutter/foundation.dart` is imported (for `kDebugMode`).

---

### Task 6: Dead Code Cleanup (BUG-4 + BUG-6)

**File 1:** `lib/features/settings/application/settings_provider.dart:156`
Remove `..take(3)` from the chain:
```dart
// Before:
].where((l) => l.isNotEmpty).toSet().toList()..take(3);
// After:
].where((l) => l.isNotEmpty).toSet().toList();
```

**File 2:** `lib/features/model_distribution/model_distribution_notifier.dart:545`
Remove the stale TODO comment (lines 545-547). Keep the method and its doc comment — just remove the TODO line.

---

## Section 6: Test Matrix for Sprint 6 Verification

### On-Device Tests (Galaxy A25)

| # | Test | Expected Result | Sprint 5 Baseline |
|---|------|----------------|--------------------|
| 1 | Cold start frame skips | < 50 frames | 175-192 |
| 2 | Cold start → immediate message TTFT | < 10s (warmup may not be done) | N/A (new test) |
| 3 | Cold start → 10s wait → message TTFT | < 3s | 2.1-3.0s |
| 4 | "What is your name?" | "Bittybot" (not "Aya") | "Aya" |
| 5 | "My name is Alex" → "What is my name?" | "Alex" | FAIL (said "Aya") |
| 6 | Chat with `**bold**` in response | Rendered bold, not asterisks | Raw asterisks |
| 7 | Translation "Where is the nearest hospital" → Spanish | Direct translation, no markdown | Already passing |
| 8 | Warm TTFT (back-to-back) | < 3s | 2.1-3.0s |
| 9 | 30s idle → message TTFT | < 3s | 2.1s |
| 10 | Model load time | < 15s | 4.0-8.8s |
| 11 | No OOM on tab switching | Stable | Stable |
| 12 | Token filtering | No raw tokens | Clean |

### Unit Tests

All 61 existing tests must continue to pass:
```bash
/home/max/Android/flutter/bin/flutter test
```

---

## Section 7: Known Limitations (Not Addressed in Sprint 6)

1. **2+ min idle TTFT degradation** (5-10s) — `posix_fadvise` is advisory, kernel evicts pages under memory pressure. Periodic re-fadvise or partial `mlock` needed. Deferred to Sprint 7.

2. **tok/s ~2-2.6** — hardware ceiling. No software fix possible on Cortex-A78 + 3.35B model.

3. **Multi-turn context dilution** — long conversations (8+ messages) may dilute name recall. System prompt update (Task 1) helps but doesn't guarantee recall after many turns. Deferred: consider context window management or explicit memory instructions.

4. **No runtime model parameter configuration** — nCtx, nBatch, nThreads are all hardcoded. Fine for now but limits future tuning without code changes.

5. **Deprecated Color API in tests** — `test/core/theme/app_theme_test.dart` uses `.red/.green/.blue` accessors. Cosmetic warning only.
