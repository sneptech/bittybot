# Profiling Results — 2026-02-28

## Device
- Model: Samsung Galaxy A25 (SM-A256E)
- Android version: 14
- RAM: 5.5 GB (5,518,072 kB total)
- Branch: `mowismtest` @ d5964e7

## Model Download (Tests #1)
- Download time: N/A (model already downloaded from prior session)
- Progress regressions: N/A (no download occurred — needs fresh install to test T-P3 fix)
- BittyBot logo visible: **YES** — green/gold robot dog shows correctly on download screen (T-P2 fix confirmed)

## SHA-256 Verification (CRITICAL — NEW ISSUE)
- **"Verifying download..." screen appears on EVERY cold start**, not just after first download
- Duration: **~65 seconds** (reads 2.14 GB from flash storage at ~35 MB/s)
- **190 frames skipped** during verification — main thread is blocked
- This is the root cause of the perceived "10s unresponsive" delay (it's actually 65s)
- **Fix needed**: Only verify SHA-256 once after download. Persist a `verified: true` flag in SharedPreferences or the database. On subsequent cold starts, skip verification if the flag is set and the file exists.

## Model Load
- Load time: **11,735 ms** (~12s) — from `[PERF] model_load` event
- **WITHIN** the 15s target
- llama.cpp CPU features: NEON=1, ARM_FMA=1, LLAMAFILE=1, REPACK=1
- Model path: `/data/user/0/com.bittybot.bittybot/files/models/tiny-aya-global-q4_k_m.gguf`
- UI shows "Verifying download..." during this phase (no separate model-loading indicator)

## Total Cold Start Timeline
| Time (relative) | Event |
|-----------------|-------|
| +0.0s | Flutter engine loaded |
| +0.5s | Impeller/Vulkan rendering init |
| +2.7s | 190 frames skipped (SHA-256 verification begins, blocks main thread) |
| +3.0s | 38 more frames skipped |
| +67s | llama.cpp starts loading model (SHA-256 done) |
| +78s | Model loaded (11.7s load time) |
| Total: ~78s from launch to usable UI |

With SHA-256 skip fix, this would be ~12-13s (model load only).

## Chat Performance
- **NOT TESTED** — app was OOM-killed when navigating to Chat tab (see below)

## Translation Performance
- **NOT TESTED** — Translation UI appeared and input was tappable (keyboard eventually showed after ~113s from launch, which was during SHA-256 + model load). App was killed before a message could be sent.

## Token Filtering
- **NOT TESTED** — no inference occurred before OOM kill

## Multi-Turn Context
- **NOT TESTED** — no inference occurred before OOM kill

## OOM Kill (CRITICAL — NEW ISSUE)
- **Tapping the Chat tab crashed the app** — killed by Android Low Memory Killer (lmkd)
- Signal: SIGKILL (9) from Zygote
- Memory at kill: **1,080 MB RSS + 1,537 MB swap** (2.6 GB total app memory)
- Device was **thrashing at 304%** (swap I/O dramatically exceeded useful work)
- Reason: `device is low on swap (4781268kB < 5620364kB)`
- Root cause: `use_mmap=false` forces the entire 2.14 GB model into resident memory. With Flutter engine, Dart VM, Impeller GPU buffers, and the app's own widgets, total exceeds what the 5.5 GB device can sustain.

### OOM Mitigation Options
1. **Enable mmap** (`use_mmap=true`): Would let the OS page model data in/out of RAM on demand. This failed before due to SELinux `shell_data_file` context on `/data/local/tmp/`, but the model is now stored at `/data/user/0/.../files/models/` which should have the correct `app_data_file` context. **MUST test if mmap works from app data directory.**
2. **Quantize to smaller model**: Q2_K or IQ2_XXS would be ~1 GB instead of 2.14 GB.
3. **Aggressive memory management**: Dispose model between tab switches (bad UX — long reload).
4. **Reduce nCtx**: Lower context window reduces KV cache memory.

## Issues Found

### CRITICAL
1. **OOM kill on Chat tab navigation** — app uses ~2.6 GB total, Galaxy A25 can't sustain this. Must either enable mmap (test from app data dir) or use smaller quantization.
2. **SHA-256 verification runs every cold start** — 65s wasted reading 2.14 GB on every launch. Should only run once after download; persist verification flag.

### HIGH
3. **Main thread blocked during SHA-256** — 190 frames skipped. Verification should run in a `compute()` isolate (it may already, but something is still blocking the main thread — possibly the state updates or the file existence check before verification).

### MEDIUM
4. **No separate model-loading indicator** — after verification, the "Verifying download..." screen stays up during model load. Should show "Loading model..." or similar.
5. **Inference metrics not captured** — couldn't test TTFT, tokens/sec, or token filtering due to OOM kill.

### LOW
6. **`developer.log()` doesn't appear in `adb logcat`** — added `print()` alongside it for debugging. Should keep both for production (developer.log for DevTools, print for logcat).

## Raw Logs

### Model Load PERF Event
```
02-28 05:43:37.074 I/flutter ( 7635): [PERF] {"perf":"model_load","ts":"2026-02-28T05:43:37.062806","duration_ms":11735}
```

### Frame Skips (our app PID 7635 only)
```
02-28 05:42:21.793 I/Choreographer( 7635): Skipped 190 frames!
02-28 05:42:22.146 I/Choreographer( 7635): Skipped 38 frames!
02-28 05:44:50.533 I/Choreographer( 7635): Skipped 33 frames!
02-28 05:44:50.933 I/Choreographer( 7635): Skipped 46 frames!
```

### OOM Kill
```
02-28 05:45:09.517 I/lmkd(594): Reclaim 'com.bittybot.bittybot' (7635), uid 10382, oom_score_adj 0, state 2 to free 1080844kB rss, 1537496kB swap; reason: device is low on swap (4781268kB < 5620364kB) and thrashing (304%)
02-28 05:45:09.521 E/lowmemorykiller(594): process_mrelease 7635 failed: No such process
02-28 05:45:11.231 I/Zygote(26978): Process 7635 exited due to signal 9 (Killed)
```

## Recommendations for VPS Claude / Codex Team

1. **First priority**: Test `use_mmap=true` from app data directory (`/data/user/0/.../files/models/`). The SELinux restriction that forced `use_mmap=false` was for `/data/local/tmp/` — app data dir should allow mmap. If it works, this eliminates the OOM issue.
2. **Second priority**: Move SHA-256 verification to one-time-only after download. Persist a `model_verified` flag in SharedPreferences.
3. **Third priority**: After mmap fix, re-run profiling to capture inference metrics (TTFT, tokens/sec, token filtering, multi-turn context).
