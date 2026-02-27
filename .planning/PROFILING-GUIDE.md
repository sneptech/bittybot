# BittyBot On-Device Profiling Guide

**For:** Local Claude Code monitoring during on-device testing
**Date:** 2026-02-27
**Branch:** `mowismtest`

## Quick Start

```bash
# 1. Build and install debug APK
cd /home/agent/git/bittybot
flutter build apk --debug
adb install build/app/outputs/flutter-apk/app-debug.apk

# 2. Start log capture (filter to profiling events only)
adb logcat -s flutter | grep '\[PERF\]' > profiling-output.jsonl &

# 3. Use the app: download model → open chat → send messages

# 4. Stop capture
kill %1
```

## What Gets Logged

All profiling events are emitted as `[PERF] {json}` lines via `developer.log()`. They appear in `flutter logs` and `adb logcat`.

### Event Types

**1. Model Load** — emitted once when model finishes loading
```json
[PERF] {"perf":"model_load","ts":"2026-02-27T14:30:45.123Z","duration_ms":8500}
```
- `duration_ms`: Total wall-clock time from load start to ModelReadyResponse

**2. Inference Request** — emitted after each chat/translation response completes
```json
[PERF] {"perf":"inference_request","ts":"2026-02-27T14:30:48.456Z","request_id":1,"total_ms":3200,"ttft_ms":180,"token_count":42,"tokens_per_sec":"13.12"}
```
- `ttft_ms`: Time-to-first-token (user presses send → first token appears)
- `tokens_per_sec`: Generation throughput
- `total_ms`: Wall-clock time for entire generation
- `token_count`: Total tokens generated

**3. Progress Regression** — emitted when download progress goes backward (the oscillation bug)
```json
[PERF] {"perf":"progress_regression","ts":"2026-02-27T14:30:50.789Z","callback_num":5,"old_value":"0.7500","new_value":"0.6200"}
```
- If you see these, the monotonic fix (T-P3) isn't catching all cases

## Performance Targets

| Metric | Target | Concern If |
|--------|--------|-----------|
| Model load time | < 15s | > 20s on mid-range phone |
| Time-to-first-token (TTFT) | < 2s | > 3s feels sluggish |
| Token generation rate | > 5 tok/s | < 3 tok/s feels glacially slow |
| Main thread frame time | < 16ms | > 32ms causes visible jank |
| Progress regressions | 0 | Any = T-P3 fix incomplete |

## How to Parse the Output

```bash
# Extract all perf events into clean JSON lines
adb logcat -s flutter | grep '\[PERF\]' | sed 's/.*\[PERF\] //'

# Get just inference metrics
adb logcat -s flutter | grep 'inference_request' | sed 's/.*\[PERF\] //'

# Get model load time
adb logcat -s flutter | grep 'model_load' | sed 's/.*\[PERF\] //'

# Count progress regressions
adb logcat -s flutter | grep 'progress_regression' | wc -l
```

## What to Test — Step by Step

### Test 1: Model Download (Issues #1 and #6)
1. Fresh install (or clear app data)
2. Launch app → download screen appears
3. **Verify:** BittyBot logo (green/gold robot dog) shows above progress bar — NOT a generic robot icon
4. **Watch:** Progress bar should move smoothly forward, never jumping backward
5. **Check logs:** Zero `progress_regression` events
6. **Capture:** `adb logcat -s flutter | grep progress_regression`

### Test 2: Model Load & Input Responsiveness (Issue #2)
1. After download completes, the model loads (~8-15s)
2. **Verify:** UI shows a loading state during model load (not frozen)
3. **Verify:** Once model ready, tapping the chat input opens keyboard within 1-2s
4. **Check logs:** `model_load` event, note `duration_ms`
5. **Note:** The 10s delay IS expected model load time (2GB into RAM). It's not main thread blocking. Input is correctly disabled until model ready.

### Test 3: Chat Response Speed (Issue #3)
1. Send a short message: "Hello, how are you?"
2. **Verify:** First token appears within 2s
3. **Verify:** Tokens stream smoothly (50ms batching reduces jank)
4. **Check logs:** `inference_request` event
5. **Key metrics:** `ttft_ms` and `tokens_per_sec`
6. Send 3-5 more messages to get a baseline

### Test 4: Token Filtering (Issue #4)
1. Send messages and read responses
2. **Verify:** NO raw tokens like `<|START_RESPONSE|>`, `<|END_OF_TURN_TOKEN|>`, or any `<|...|>` patterns visible in chat bubbles
3. If you see raw tokens, note the exact text — the regex filter may need expanding

### Test 5: Multi-Turn Context
1. Say: "My name is Alex"
2. Then ask: "What is my name?"
3. **Verify:** Model responds with "Alex" — context is maintained across turns

### Test 6: Translation Mode Comparison
1. Switch to Translation tab
2. Translate a sentence
3. **Compare:** `tokens_per_sec` in translation vs chat mode
4. Translation uses `nPredict=128`, chat uses `nPredict=512` — speed per token should be similar

## Flutter DevTools (Optional, More Detailed)

For frame timing analysis:

```bash
# Launch app in profile mode for accurate frame timing
flutter run --profile

# Open DevTools URL printed in console
# Go to Performance tab → record → interact with app → stop
# Look for 'model_load' and 'inference' spans in timeline
```

Profile mode gives accurate frame rendering times. Look for:
- Frames > 16ms during token streaming = jank
- Long gaps between frames during model load = main thread blocking

## Writing Results

After testing, create a file at `.planning/PROFILING-RESULTS.md` with:

```markdown
# Profiling Results — [date]

## Device
- Model: [e.g., Galaxy A25]
- Android version: [e.g., 14]
- RAM: [e.g., 6GB]

## Model Download
- Download time: ___
- Progress regressions: ___ (should be 0)
- BittyBot logo visible: yes/no

## Model Load
- Load time: ___ ms (from [PERF] model_load event)
- UI responsive during load: yes/no
- Input available after load: within ___s

## Chat Performance (average of 5+ messages)
- TTFT: ___ ms
- Tokens/sec: ___
- Total generation time: ___ ms per response
- Visible jank during streaming: yes/no

## Token Filtering
- Raw tokens visible: yes/no
- If yes, exact text seen: ___

## Translation Performance
- TTFT: ___ ms
- Tokens/sec: ___

## Multi-Turn Context
- Name recall test: pass/fail

## Issues Found
1. [description]
2. [description]

## Raw Logs
[Paste relevant [PERF] lines here]
```

## Sprint 3 Retest (2026-02-27)

Four critical fixes were pushed. The previous test (`.planning/PROFILING-RESULTS.md`) was OOM-killed before inference could be tested. This retest should verify the fixes AND capture the inference metrics that were missed.

### What Changed

| Commit | Fix | What to Verify |
|--------|-----|----------------|
| `d55753d` | **mmap enabled** (`useMemorymap=true`) | App does NOT get OOM-killed when navigating to Chat tab. Check `adb logcat \| grep lmkd` for kills. |
| `b74d408` | **nCtx 2048→512** | Reduced KV cache memory. No direct UI change — helps prevent OOM. |
| `9c35a91` | **SHA-256 skip on 2nd+ launch** | First launch after fresh install: SHA-256 runs (~65s). Second cold start: NO "Verifying download..." phase, goes straight to model load. |
| `7db3afd` | **"Loading model..." indicator** | After verification (or skip), UI shows "Loading model..." text, NOT "Verifying download..." |

### Retest Checklist

1. **Build + install:** `flutter build apk --debug && adb install -r build/app/outputs/flutter-apk/app-debug.apk`
2. **First launch:** Model already downloaded from prior test. Should see either brief SHA-256 verification (first launch after update) or skip straight to "Loading model..."
3. **Verify no OOM:** Navigate to Chat tab. App should NOT crash. Monitor: `adb logcat | grep -E 'lmkd|lowmemory|Zygote.*signal'`
4. **Chat inference (CRITICAL — never tested):** Send 5+ messages, capture `[PERF] inference_request` events for TTFT and tokens/sec
5. **Token filtering:** No `<|...|>` tokens visible in chat bubbles
6. **Multi-turn:** "My name is Alex" → "What is my name?" → should recall
7. **Translation:** Switch to Translation tab, send a sentence, capture metrics
8. **Second cold start:** Force-stop app, relaunch. Should skip SHA-256 entirely (no "Verifying download..." screen). Time from launch to usable UI should be ~12-13s (model load only).
9. **Loading indicator:** During model load phase, UI should show "Loading model..." not "Verifying download..."

### Key Difference from Last Test
Last test hit OOM at step 3 (Chat tab navigation) due to `use_mmap=false` forcing 2.14 GB into resident RAM. With mmap enabled, the OS will page model data in/out — RSS should stay well under the device's 5.5 GB limit. If OOM still occurs, check `adb logcat | grep -i mmap` for SELinux denials — the app data directory SHOULD have correct `app_data_file` context, but if not, that's the next issue to fix.

## Architecture Reference

- **PerformanceMonitor**: Singleton at `lib/core/diagnostics/performance_monitor.dart` — tracks all metrics
- **InferenceProfiler**: Static helper at `lib/core/diagnostics/inference_profiler.dart` — DevTools Timeline spans
- **Token batching**: `ChatNotifier` buffers tokens for 50ms before UI rebuild (T-P4 fix)
- **nThreads=4**: Inference isolate uses 4 threads (prevents big.LITTLE over-subscription)
- **Token filter**: Regex in `inference_isolate.dart` strips `<|UPPER_CASE_TOKEN|>` patterns
- **Monotonic progress**: `resolveMonotonicProgress()` in notifier prevents backward progress jumps
