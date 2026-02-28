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

## Sprint 4 Retest (2026-02-27)

Five fixes targeting inference speed. The Sprint 3 retest showed TTFT 2.6–10s and 0.5–2.8 tok/s — both FAIL — because the 2.14 GB Q4_K_M model couldn't stay fully resident on a 5.5 GB device. Sprint 4 addresses this with a smaller model, more threads, startup jank fix, and page warmup.

### What Changed

| Commit | Fix | What to Verify |
|--------|-----|----------------|
| (release `v0.1.0-q3ks`) | **Q3_K_S model** (1.55 GB, down from 2.14 GB Q4_K_M) | App detects size mismatch → re-downloads new model from GitHub release. Download completes, SHA-256 verifies. |
| `0e1144a` | **ModelConstants updated** for Q3_K_S | New URL, hash, size all correct. Download screen shows "~1.55 GB". |
| `114c1d4` | **nThreads 4→6** | Uses all 6 big cores. Check `adb logcat \| grep nThreads` if logged. |
| `7e3f578` | **Startup jank fix** | Fewer frames skipped on cold start (was 175, should be much less). Check Choreographer logs. |
| `f784c00` | **Page warmup** | After model load, all mmap pages are pre-faulted. Model load time will be LONGER (includes sequential read of 1.55 GB), but first inference TTFT should be fast since all pages are already in RAM. |

### Retest Checklist

**IMPORTANT:** The app MUST re-download the model since it switched from Q4_K_M (2.14 GB) to Q3_K_S (1.55 GB). The existing model file will fail the size check and be deleted. You need a working internet connection for the first launch.

1. **Build + install:** `flutter build apk --debug && adb install -r build/app/outputs/flutter-apk/app-debug.apk`
2. **First launch — model re-download:**
   - App should detect existing Q4_K_M file has wrong size → delete → re-download Q3_K_S (~1.55 GB)
   - Progress bar should be smooth (monotonic, no oscillation)
   - BittyBot logo should be visible on download screen
   - After download: SHA-256 verification runs (one-time, ~35-40s for 1.55 GB)
   - After verification: "Loading model..." indicator → model loads
   - **Expected model load time:** longer than before (~15-25s) because page warmup reads the entire file after load. This is intentional — it pre-faults mmap pages so first inference is fast.
3. **Memory check:** `adb shell dumpsys meminfo com.bittybot.bittybot`
   - Model mmap should be ~1,550 MB mapped (vs 2,082 MB before)
   - RSS should be ~700-900 MB (vs 1,189 MB before)
   - Swap should be minimal (<100 MB, vs 268 MB before)
   - Key: model + KV cache + app should fit in ~2.1 GB available with ~400 MB headroom
4. **Chat inference (THE KEY TEST):**
   - Send 5+ messages, capture `[PERF] inference_request` events
   - **Expected TTFT: <2s consistently** (not just once — model should stay resident)
   - **Expected tok/s: 3-5+** with nThreads=6 and full residency
   - Compare request #0 vs #4 — should be similar (no page eviction between requests)
5. **Startup jank:** Check Choreographer frame skips on launch
   - Was 175 frames in Sprint 3 → should be significantly fewer with the jank fix
   - `adb logcat | grep -E 'Skipped.*frames'`
6. **Second cold start:** Force-stop, relaunch
   - SHA-256 should be SKIPPED (flag persisted from first launch)
   - Model loads → page warmup → ready
   - Total time to usable UI should be model load + warmup (~15-25s)
7. **Inference after second cold start:**
   - First message should have TTFT <2s (pages pre-faulted by warmup)
   - If TTFT is >5s, page warmup may not be working — check logs for errors
8. **All Sprint 3 tests still pass:**
   - Token filtering: no `<|...|>` tokens visible
   - Multi-turn: "My name is Alex" → recall works
   - Translation: switch tabs, send message, capture metrics
   - No OOM kill (should be even better now with smaller model)

### Performance Targets (Updated)

| Metric | Target | Sprint 3 Best | Expected Sprint 4 |
|--------|--------|---------------|-------------------|
| Model load + warmup | < 30s | 7.5s (no warmup) | 15-25s (with warmup) |
| Cold start (2nd+) | < 30s | 10s | 15-25s (with warmup) |
| TTFT | < 2s | 2.6s (100% resident) | < 2s (consistent) |
| Token generation | > 5 tok/s | 2.8 tok/s (100% resident) | 3-5+ tok/s (nThreads=6) |
| TTFT consistency | < 1s variance | 2.6s–10.5s (7.9s variance!) | < 1s variance |
| Startup frame skips | < 50 | 175 | < 50 |

### Key Difference from Sprint 3 Test
Sprint 3's fundamental problem: 2.14 GB model on 5.5 GB device left NO headroom. Model pages were constantly evicted, causing 5-10x slowdowns. Sprint 4's Q3_K_S at 1.55 GB leaves ~400 MB headroom after model + KV cache + app overhead. Combined with page warmup, the model should stay fully resident and inference should be consistently fast.

**If TTFT is still >5s:** Check `adb shell cat /proc/meminfo | grep -E 'MemAvailable|SwapFree'` — if available memory is very low, background services may still be evicting pages. Report exact numbers.

**If download fails:** The model URL is a GitHub release asset: `https://github.com/sneptech/bittybot/releases/download/v0.1.0-q3ks/tiny-aya-global-q3_k_s.gguf`. Verify it's accessible from the device's browser first.

## Sprint 5 Retest (2026-02-27)

Three fixes targeting TTFT consistency and cold start frame skips. Sprint 4 showed TTFT 3-10s (fails <2s target) because mmap pages got evicted during idle, and 184 frame skips on 2nd cold start (regression from 65).

### What Changed

| Commit | Fix | What to Verify |
|--------|-----|----------------|
| `90e90f6` S5-T1 | **posix_fadvise(POSIX_FADV_WILLNEED)** via Dart FFI | After model loads + warmup, kernel is advised to keep pages resident. TTFT after 30s idle should be ~3s (was ~10s). |
| `1f6f6ed` S5-T2 | **Multi-frame yields in initialize()** | Two 16ms yields before I/O, one yield before `_proceedToLoad()` on fast path. |
| `2991fac` S5-T2 | **Cooperative warmup with yields every 64 MB** | `_warmupModelPages` now async, yields to reduce main-thread I/O contention. |
| `8803e4e` S5-T3 | **Dead code cleanup** | Removed legacy "Phase 1 spike" comment from prompt_builder.dart. Verified startup path + icons correct. |

### Retest Checklist

**No model re-download needed.** Q3_K_S model from Sprint 4 should still be on device.

1. **Build + install:** `flutter build apk --debug && adb install -r build/app/outputs/flutter-apk/app-debug.apk`

2. **First cold start (app was already installed):**
   - SHA-256 should be SKIPPED (flag from Sprint 4)
   - Model loads + warmup runs (warmup now cooperative with yields)
   - `adb logcat | grep -E 'Skipped.*frames'` — target < 50 frame skips (was 65/184)
   - `adb logcat -s flutter | grep '\[PERF\]' | grep model_load` — note duration

3. **Chat inference — WARM (THE KEY TEST):**
   - Send 5+ messages back-to-back
   - `adb logcat -s flutter | grep inference_request`
   - **Expected: TTFT ~3s, tok/s ~2** (tok/s is hardware ceiling, won't change)

4. **Chat inference — AFTER 30s IDLE (posix_fadvise test):**
   - Send 3 messages, then WAIT 30 seconds (lock phone or switch to another app)
   - Come back, send another message
   - **KEY METRIC: TTFT on first message after idle**
   - Sprint 4 without fadvise: ~8-10s
   - Sprint 5 with fadvise: **expected ~3-5s** (pages should stay resident)
   - If still ~8-10s, posix_fadvise isn't effective enough → may need mlock or smaller quant

5. **Longer idle test (2+ minutes):**
   - Same as above but wait 2 minutes
   - If TTFT degrades to ~8s+, the advisory isn't strong enough against Android's LMK
   - Report exact TTFT + `adb shell cat /proc/meminfo | grep -E 'MemAvailable|SwapFree'`

6. **Second cold start:**
   - Force-stop app, relaunch
   - `adb logcat | grep -E 'Skipped.*frames'` — target < 50 (was 184)
   - SHA-256 skipped, model loads, warmup runs
   - Send first message — note TTFT

7. **Third cold start (repeat for consistency):**
   - Force-stop, relaunch, measure frame skips again
   - Is 2nd vs 3rd launch consistent?

8. **Memory check:** `adb shell dumpsys meminfo com.bittybot.bittybot`
   - Note: mmap size, Native Heap, Swap PSS
   - Compare to Sprint 4: mmap ~1,611 MB, Swap 226 MB

9. **All prior tests still pass:**
   - Token filtering: no `<|...|>` tokens visible
   - Multi-turn: "My name is Alex" → recall
   - Translation: switch tabs, 3 translations, all direct (no explanations)
   - No OOM kill

### Performance Targets (Updated for Sprint 5)

| Metric | Target | Sprint 4 Best | Sprint 4 Typical | Sprint 5 Expected |
|--------|--------|---------------|-----------------|-------------------|
| TTFT (warm) | < 5s | 3.1s | 3.1-3.3s | ~3s (same) |
| TTFT (after 30s idle) | < 5s | N/A | 8-10s | **< 5s** (fadvise) |
| TTFT consistency | < 2s variance | 3.1-3.3s warm | 3.1-10.7s (7.6s!) | **< 2s variance** |
| tok/s | ~2 (hw ceiling) | 2.09 | 1.9 | ~2 (unchanged) |
| Frame skips (1st launch) | < 50 | 65 | 65 | **< 50** |
| Frame skips (2nd launch) | < 50 | 184 | 184 | **< 50** (key fix) |
| Model load + warmup | < 15s | 3.7-6.4s | 6.4s | Similar |

### Key Difference from Sprint 4 Test

Sprint 4's warmup read pages in but they got evicted within seconds. Sprint 5 adds `posix_fadvise(POSIX_FADV_WILLNEED)` which tells the kernel to keep those pages in page cache. The native fd stays open for the model's lifetime. This is an advisory — the kernel CAN still evict pages under extreme memory pressure, but should strongly prefer keeping them.

The frame skip fix adds proper multi-frame yields (16ms each = one Flutter frame) at multiple points in `initialize()`, plus cooperative warmup yields every 64 MB. This should fix the 2nd cold start regression where 184 frames were skipped.

**If TTFT after idle is still >5s:** `posix_fadvise` alone isn't sufficient. Next options:
1. `mlock()` via FFI (requires checking ulimit -l on Android)
2. Periodic background re-read (keep-alive timer)
3. Drop to IQ3_XXS (~1.2 GB) for more headroom

**Report findings to `.planning/PROFILING-RESULTS.md`** — append a Sprint 5 section.

## Sprint 6 Retest (2026-02-28)

Six bug fixes shipped. The key changes to verify on device are: deferred warmup (frame skips), Bittybot identity, and markdown rendering. The other fixes (crash FD cleanup, print guard, dead code) are code-only with no observable on-device behavior change.

### What Changed

| Commit | Fix | What to Verify |
|--------|-----|----------------|
| `3e9373b` S6-T1 | **System prompt identity** — chatSystemPrompt now says "You are Bittybot" | Ask "What is your name?" — model should say "Bittybot" not "Aya" |
| `708e24f` S6-T2 | **Markdown rendering in chat bubbles** — `MarkdownBody` replaces `Text` | Chat responses with `**bold**` or `-` lists should render formatted, not raw asterisks |
| `6266757` S6-T3 | **Defer warmup after ModelReadyResponse** — UI unblocked before warmup | Frame skips on cold start should drop dramatically (was 175-192) |
| `78e5c5a` S6-T4 | **Crash recovery FD cleanup** — ShutdownCommand sent before isolate kill | No direct test — prevents FD leak on crash-recovery cycles |
| `3960a3b` S6-T5 | **Print guard** — `if (kDebugMode) print(line)` | No `[PERF]` lines in logcat on release builds (debug still shows them) |
| `3960a3b` S6-T6 | **Dead code cleanup** — removed `..take(3)` no-op + stale TODO | No behavioral change |

### Retest Checklist

**No model re-download needed.** Q3_K_S model from Sprint 4/5 should still be on device.

1. **Build + install:** `flutter build apk --debug && adb install -r build/app/outputs/flutter-apk/app-debug.apk`

2. **Cold start #1 — FRAME SKIPS (THE KEY TEST for S6-T3):**
   - Force-stop app, launch fresh
   - `adb logcat | grep -E 'Skipped.*frames'`
   - **Target: < 50 frame skips** (was 175-192 in Sprint 5)
   - ModelReadyResponse is now sent before warmup, so UI should render almost immediately after model construction (~200ms), not after the full 8-10s warmup
   - Note: first inference may be slower if warmup hasn't finished yet

3. **Cold start #2 (consistency check):**
   - Force-stop, relaunch, measure frame skips again
   - Should be consistently < 50

4. **Cold start → immediate message (warmup race test):**
   - Force-stop, relaunch
   - Send a message AS SOON AS the input is enabled (before warmup finishes)
   - **Expected:** Higher TTFT than normal (page faults during inference) but no crash
   - This tests the trade-off of S6-T3

5. **Identity test (S6-T1):**
   - Open Chat tab
   - Ask: "What is your name?"
   - **Expected:** Model says "Bittybot" (not "Aya")
   - Ask: "My name is Alex"
   - Then: "What is my name?"
   - **Expected:** "Alex" (multi-turn recall with new system prompt nudge)

6. **Markdown rendering test (S6-T2):**
   - Send messages that elicit markdown responses (e.g., "Give me a list of 3 fruits" or "What are the benefits of exercise?")
   - **Expected:** Bold text rendered bold, bullet lists rendered as lists, no raw `**asterisks**` or `- dashes` visible
   - Translation bubbles should be UNCHANGED (plain text, no markdown widget)

7. **Warm TTFT baseline:**
   - Send 5+ messages back-to-back
   - `adb logcat -s flutter | grep inference_request`
   - **Expected: TTFT ~2.1-3.0s, tok/s ~2.3-2.6** (same as Sprint 5 warm)

8. **30s idle test (fadvise still working after S6-T3 reorder):**
   - Send messages, wait 30s, send another
   - **Expected: TTFT ~2-3s** (fadvise still runs after warmup, just deferred)
   - If TTFT regresses to 8-10s, the reordering may have broken fadvise timing

9. **All prior tests still pass:**
   - Token filtering: no `<|...|>` tokens visible
   - Translation: 3 translations, all direct (no explanations, no markdown issues)
   - No OOM kill on tab switching
   - Model load < 15s

### Performance Targets (Updated for Sprint 6)

| Metric | Target | Sprint 5 Best | Sprint 5 Typical | Sprint 6 Expected |
|--------|--------|---------------|-----------------|-------------------|
| Frame skips (cold start) | < 50 | 175 | 175-192 | **< 50** (key fix) |
| TTFT (warm) | < 5s | 2.1s | 2.1-3.0s | ~2.1-3.0s (same) |
| TTFT (30s idle) | < 5s | 2.1s | ~2s | ~2-3s (same) |
| TTFT (immediate after cold start) | < 10s | N/A | N/A | **< 10s** (new test) |
| tok/s | ~2 (hw ceiling) | 2.61 | 2.3-2.6 | ~2.3-2.6 (same) |
| Identity | "Bittybot" | "Aya" | "Aya" | **"Bittybot"** |
| Markdown rendering | Formatted | Raw asterisks | Raw asterisks | **Formatted** |
| Model load | < 15s | 4.0s | 4.0-8.8s | Similar or faster |

### Key Difference from Sprint 5 Test

Sprint 5's frame skips (175-192) persisted because `ModelReadyResponse` was sent AFTER the 8-10s warmup, keeping the UI in "loading" state during the entire sequential read. Sprint 6 sends `ModelReadyResponse` immediately after `Llama()` construction (~200ms), then runs warmup in the background. The UI should render in under 1s instead of 8-10s.

The trade-off: if the user sends a message before warmup completes, TTFT will be higher (page faults during inference). But users typically take 2-5s to start typing, which is enough for warmup to make significant progress.

**If frame skips are still > 100:** The bottleneck may not be ModelReadyResponse timing — could be Flutter asset loading, Drift DB init, or other startup work. Check which lifecycle events happen before and after the frame skips in logcat.

**Report findings to `.planning/PROFILING-RESULTS.md`** — append a Sprint 6 section.

## Architecture Reference

- **PerformanceMonitor**: Singleton at `lib/core/diagnostics/performance_monitor.dart` — tracks all metrics
- **InferenceProfiler**: Static helper at `lib/core/diagnostics/inference_profiler.dart` — DevTools Timeline spans
- **Token batching**: `ChatNotifier` buffers tokens for 50ms before UI rebuild (T-P4 fix)
- **nThreads=6**: Inference isolate uses 6 threads (all big cores on Galaxy A25)
- **Token filter**: Regex in `inference_isolate.dart` strips `<|UPPER_CASE_TOKEN|>` patterns
- **Monotonic progress**: `resolveMonotonicProgress()` in notifier prevents backward progress jumps
- **Page warmup**: `_warmupModelPages()` in `inference_isolate.dart` reads entire model file after load to pre-fault mmap pages (now async with yields every 64 MB)
- **posix_fadvise FFI**: `native_memory_advisor.dart` — opens model file via libc, calls `posix_fadvise(POSIX_FADV_WILLNEED)`, keeps fd open for model lifetime, closes on shutdown
- **Frame skip yields**: 3x 16ms yields in `model_distribution_notifier.dart initialize()` — two before I/O, one before `_proceedToLoad()` on fast path
- **Model**: Q3_K_S quantization (~1.55 GB), hosted on GitHub release `v0.1.0-q3ks`
