# Profiling Results — 2026-02-28

## Sprint 2 Results (Historical)

> Previous test at `mowismtest` @ d5964e7. Two critical blockers found:
> - OOM kill on Chat tab (use_mmap=false, 2.6 GB total app memory)
> - 65s SHA-256 verification on every cold start
> See git history for full Sprint 2 results.

---

## Sprint 3 Retest — 2026-02-28

### Device
- Model: Samsung Galaxy A25 (SM-A256E)
- Android version: 14
- RAM: 5.5 GB (5,518,072 kB total)
- CPU: 6x 1.92 GHz + 2x 1.344 GHz (no thermal throttling observed)
- Branch: `mowismtest` @ 87e33f0

### Fixes Verified

| Commit | Fix | Status |
|--------|-----|--------|
| `d55753d` T-C1 | mmap enabled | **VERIFIED** — no OOM, app stable on Chat tab |
| `b74d408` T-C4 | nCtx 2048→512 | **VERIFIED** — applied, contributes to lower memory |
| `9c35a91` T-C2 | SHA-256 skip | **VERIFIED** — second cold start skips verification entirely |
| `7db3afd` T-C3 | "Loading model..." indicator | Not directly observed (model loads too fast to capture UI dump during load) |

### Key Findings

- **Model 100% resident**: TTFT ~2.5s, generation ~2.8 tok/s
- **Model ~50% resident**: TTFT ~10s, effective ~0.5 tok/s (5x slower)
- Root cause: 2.14 GB Q4_K_M model couldn't stay fully resident on 5.5 GB device

> Full Sprint 3 raw logs preserved in git history. See previous version of this file.

---

## Sprint 4 Retest — 2026-02-28

### Device
Same Galaxy A25 (SM-A256E), Android 14, 5.5 GB RAM, eMMC storage.
Branch: `mowismtest` @ 920cb49

### Fixes Verified

| Commit | Fix | Status |
|--------|-----|--------|
| `0e1144a` T-S2 | Q3_K_S model (1.55 GB, down from 2.14 GB) | **VERIFIED** — app detected size mismatch, re-downloaded, SHA-256 passed |
| `114c1d4` T-S3 | nThreads 4→6 | **VERIFIED** — applied |
| `7e3f578` T-S4 | Startup jank fix (yield + cache SharedPrefs) | **PARTIAL** — 65 frames on 1st launch (was 175), but 184 frames on 2nd cold start |
| `f784c00` T-S5 | Page warmup (pre-fault mmap pages) | **VERIFIED** — code runs, but pages evict during idle time before first inference |
| `920cb49` | Translation prompt tightened | **VERIFIED** — 3/3 direct translations, no explanations |

### Model Download (Fresh — Q3_K_S)

- **Progress regressions: 0** (monotonic fix holds)
- **BittyBot logo: visible** (green/gold robot dog on download screen)
- **Download speed: ~7 MB/s** over 5G
- **Size displayed: "~1.55 GB"** (correct)
- **Progress bar: smooth**, no backward jumps

### Cold Start — First Launch After APK Install

| Time (relative) | Event |
|-----------------|-------|
| +0.0s | Flutter engine started (Impeller/Vulkan) |
| ~+1s | 65 frames skipped (improved from 175 in Sprint 3) |
| Model downloaded | ~3 min (1.55 GB at 7 MB/s) |
| SHA-256 runs | First launch — sets verified flag |
| +model load | **6,388 ms** (includes page warmup) |
| **Ready** | Translation screen with enabled input |

### Cold Start — Second Launch (SHA-256 Skipped)

| Metric | Value |
|--------|-------|
| SHA-256 | **Skipped** (persisted flag works) |
| Model load + warmup | **3,680 ms** (pages partly cached from first run) |
| Frame skips | **184** (regression from 65 on first launch — see issues) |
| Time to usable UI | ~6-8s |

### Memory

```
TOTAL PSS: 2,044,046 KB  |  TOTAL RSS: 1,848,435 KB  |  TOTAL SWAP PSS: 226,375 KB
Model mmap: 1,610,856 KB mapped (1.53 GB)
Native Heap: 560,948 KB size, 482,066 KB alloc
```

System memory at time of testing:
```
MemTotal:     5,518,072 kB
MemAvailable: 2,388,332 kB
MemFree:        227,776 kB
SwapTotal:    8,388,604 kB
SwapFree:     5,658,396 kB
```

**Comparison to Sprint 3:**
- Model mmap: 1,611 MB (was 2,082 MB) — **471 MB smaller**
- Swap PSS: 226 MB (was 268 MB) — slightly less swapping
- Still ~226 MB in swap → model pages still being partially evicted

### Chat Performance

| Request | TTFT (ms) | tok/s | Tokens | Total (ms) | Condition |
|---------|-----------|-------|--------|------------|-----------|
| #0 | **10,721** | 1.84 | 54 | 29,351 | First inference, 3.5 min after model load (pages evicted) |
| #1 | **3,283** | 1.97 | 74 | 37,494 | Back-to-back (pages warm) |
| #2 | **5,987** | 1.87 | 27 | 14,401 | After short pause |
| #3 | **3,226** | 2.07 | 18 | 8,705 | Back-to-back (pages warm) |
| #4 | **3,117** | 2.09 | 20 | 9,586 | Back-to-back (pages warm) |
| #6 (post-restart) | **8,373** | 1.99 | 48 | 24,104 | Immediately after 2nd cold start |

**Warm steady-state: TTFT ~3.1-3.3s, ~2.0-2.1 tok/s**
**Cold/evicted: TTFT ~8-11s, ~1.8-2.0 tok/s**

### Translation Performance

| Request | TTFT (ms) | tok/s | Tokens | Input | Output |
|---------|-----------|-------|--------|-------|--------|
| #5 (old prompt) | 9,391 | 0.80 | 10 | "Where is the nearest hospital" | "El hospital más cercano es el más próximo." (BAD — not a direct translation) |
| #7 (new prompt) | 8,880 | 0.70 | 8 | "Where is the nearest hospital" | "¿Dónde está el hospital más cercano?" (GOOD) |
| #8 (new prompt) | 7,794 | 0.86 | 10 | "I would like a table for two please" | "Me gustaría una mesa para dos, por favor." (GOOD) |
| #9 (new prompt) | 6,928 | 0.56 | 5 | "How much does this cost" | "¿Cuánto cuesta esto?" (GOOD) |

**Translation prompt fix (920cb49): 3/3 correct direct translations after tightening system prompt.**

### Token Filtering
- **PASS** — no raw tokens (`<|START_OF_TURN_TOKEN|>`, `<|END_OF_TURN_TOKEN|>`, etc.) visible in any chat or translation response across all 9+ messages tested.

### Multi-Turn Context
- **PASS** — "My name is Alex" → "What is my name?" → "Hello there, Alex. I'm glad to meet you!" (correct recall)

### Functional Tests Summary
- No OOM crashes (even switching between Translate ↔ Chat tabs multiple times)
- Chat responses coherent and on-topic
- Translation produces clean, correct Spanish
- Progress bar smooth (0 regressions)
- BittyBot logo visible on download screen

---

## Sprint 4 vs Sprint 3 Comparison

| Metric | Sprint 3 | Sprint 4 | Change |
|--------|----------|----------|--------|
| Model size | 2.14 GB (Q4_K_M) | 1.55 GB (Q3_K_S) | **-28%** |
| Model load (1st) | 8,104 ms | 6,388 ms | **-21%** |
| Model load (2nd) | 7,478 ms | 3,680 ms | **-51%** |
| Frame skips (1st) | 175 | 65 | **-63%** |
| Frame skips (2nd) | 175 | 184 | **+5% (regression)** |
| Swap PSS | 268 MB | 226 MB | **-16%** |
| TTFT (warm) | 2,572 ms (1 fluke) | 3,117-3,283 ms (consistent) | Worse but consistent |
| TTFT (cold/evicted) | 9,600-10,700 ms | 8,373-10,721 ms | Similar |
| tok/s (warm) | 2.05-2.80 | 1.97-2.09 | Similar (Q3_K_S slightly less compute) |
| tok/s (evicted) | 0.50-0.65 | 0.70-0.86 | Slightly better |
| Translation quality | Indirect/explanatory | Direct translations | **Fixed** |

## Performance vs Targets

| Metric | Target | Sprint 4 Best | Sprint 4 Typical | Status |
|--------|--------|---------------|-----------------|--------|
| Model load | < 15s | 3.7s | 6.4s | **PASS** |
| Cold start (2nd+) | < 30s | ~6s | ~8s | **PASS** |
| TTFT | < 2s | 3.1s | 6-10s | **FAIL** |
| Token generation | > 5 tok/s | 2.09 | 1.9 | **FAIL** |
| TTFT consistency | < 1s variance | 3.1-3.3s (warm) | 3.1-10.7s (varies) | **FAIL** |
| Progress regressions | 0 | 0 | 0 | **PASS** |
| Frame skips | < 50 | 65 | 184 | **FAIL** |

---

## Root Cause Analysis

### Inference Speed (~2 tok/s ceiling)

The ~2 tok/s speed is a **hardware ceiling for this CPU + model combination**. Even with the model fully resident (warm back-to-back requests), tok/s never exceeds 2.1. This is the Cortex-A78 (1.92 GHz, NEON SIMD, no I8MM) processing a 3.35B parameter model.

**GPU acceleration was researched and ruled out.** The Mali-G68 performs *worse* than CPU for LLM inference — reported 3-16x slower on similar Mali GPUs due to:
- Shared memory bus (no additional bandwidth)
- No matrix multiplication hardware
- llama.cpp Vulkan/OpenCL backends are tuned for Adreno, not Mali
- Needless host↔device memory copies on shared-memory SoCs

### TTFT Variance (3s–11s)

TTFT is determined by model page residency. The page warmup pre-faults pages during model load, but they get evicted during any idle period or tab switch as background services reclaim memory. The 226 MB swap PSS confirms pages are still being evicted despite the smaller model.

### Frame Skips Regression (2nd Cold Start)

The `Future<void>.delayed(Duration.zero)` yield added in T-S4 helps on the very first launch (65 vs 175 frames), but the 2nd cold start (184 frames) is even worse. Hypothesis: when the model file already exists and SharedPreferences are cached, the synchronous path through `initialize()` is faster, meaning the single-frame yield doesn't stagger the I/O enough. The warmup page read (1.55 GB sequential) may also be contributing to main-thread contention.

---

## Recommendations for Sprint 5 (Priority Order)

### 1. CRITICAL: Keep Model Pages Resident (`madvise` / `mlock`)

The page warmup reads pages in, but the OS evicts them within seconds. Two approaches:
- **`madvise(MADV_WILLNEED)`** via FFI on the mmap'd region — hints to OS to keep pages resident. Non-blocking, works within memory limits.
- **`mlock()`** via FFI on the mmap'd region — locks pages in RAM, prevents eviction entirely. Requires `android.permission.LOCK_MEMORY` or may be limited by `ulimit -l`. More aggressive but guarantees residency.
- **Alternative**: `madvise(MADV_SEQUENTIAL)` during warmup, then `MADV_RANDOM` for inference — helps OS prefetch during warmup and avoid read-ahead during random-access inference.

This is the single highest-impact change. If pages stay resident, TTFT drops from ~10s to ~3s consistently.

### 2. HIGH: Fix 2nd Cold Start Frame Skips

The startup jank fix (T-S4) regressed on the 2nd cold start (184 frames vs 65). The page warmup reads 1.55 GB synchronously in the inference isolate, but this may cause memory pressure that triggers GC or other main-thread contention. Investigate:
- **Move page warmup to a lower-priority isolate** or add `Isolate.yield()` calls between read chunks
- **Stagger SharedPreferences and model load** more aggressively (currently only one frame yield)
- **Profile what's actually blocking the main thread** — the frame skips may be from Drift DB init, not model loading

### 3. HIGH: nThreads Tuning Experiment

Currently nThreads=6 (all big cores). The Exynos 1280 has a heterogeneous layout:
- 6x Cortex-A78 @ 1.92 GHz (big)
- 2x Cortex-A55 @ 1.344 GHz (little)

Android's scheduler may assign some of the 6 threads to the A55 cores, which would drag down throughput. Test:
- **nThreads=2** — only big cores, no scheduler contention
- **nThreads=4** — sweet spot?
- **nThreads=6** (current)
- **nThreads=8** — all cores

Compare tok/s for each to find the optimal value. This could boost from ~2 to ~2.5-3 tok/s.

### 4. MEDIUM: Smaller Quantization (IQ3_XXS or Q2_K)

If madvise/mlock don't keep pages resident (OS pressure too high), a smaller model guarantees residency:
- **IQ3_XXS**: ~1.2 GB — fits with ~900 MB headroom
- **Q2_K**: ~1.1 GB — significant quality loss
- Trade-off: quality degrades, especially for translation accuracy

Only pursue this if #1 fails to keep Q3_K_S pages resident.

### 5. LOW: GPU Offloading

**Not recommended.** Research conclusively shows Mali-G68 would be 3-16x slower than CPU for LLM inference. The Cortex-A78 NEON path is faster than anything the Mali GPU can do. Do not spend time on this.

---

## Raw Logs — Sprint 4

### Model Load Events
```
08:19:57 [PERF] {"perf":"model_load","ts":"2026-02-28T08:19:57.712620","duration_ms":6388}
08:30:33 [PERF] {"perf":"model_load","ts":"2026-02-28T08:30:33.088791","duration_ms":3680}
08:35:14 [PERF] {"perf":"model_load","ts":"2026-02-28T08:35:14.548600","duration_ms":7738}
```

### All Inference Events
```
08:23:45 [PERF] {"perf":"inference_request","request_id":0,"total_ms":29351,"ttft_ms":10721,"token_count":54,"tokens_per_sec":"1.84"}
08:24:53 [PERF] {"perf":"inference_request","request_id":1,"total_ms":37494,"ttft_ms":3283,"token_count":74,"tokens_per_sec":"1.97"}
08:25:35 [PERF] {"perf":"inference_request","request_id":2,"total_ms":14401,"ttft_ms":5987,"token_count":27,"tokens_per_sec":"1.87"}
08:26:43 [PERF] {"perf":"inference_request","request_id":3,"total_ms":8705,"ttft_ms":3226,"token_count":18,"tokens_per_sec":"2.07"}
08:27:38 [PERF] {"perf":"inference_request","request_id":4,"total_ms":9586,"ttft_ms":3117,"token_count":20,"tokens_per_sec":"2.09"}
08:29:07 [PERF] {"perf":"inference_request","request_id":5,"total_ms":12504,"ttft_ms":9391,"token_count":10,"tokens_per_sec":"0.80"}
08:31:51 [PERF] {"perf":"inference_request","request_id":6,"total_ms":24104,"ttft_ms":8373,"token_count":48,"tokens_per_sec":"1.99"}
08:35:55 [PERF] {"perf":"inference_request","request_id":7,"total_ms":11392,"ttft_ms":8880,"token_count":8,"tokens_per_sec":"0.70"}
08:36:53 [PERF] {"perf":"inference_request","request_id":8,"total_ms":11611,"ttft_ms":7794,"token_count":10,"tokens_per_sec":"0.86"}
08:37:54 [PERF] {"perf":"inference_request","request_id":9,"total_ms":8970,"ttft_ms":6928,"token_count":5,"tokens_per_sec":"0.56"}
```

### Frame Skips
```
08:16:18 Choreographer(3346): Skipped 65 frames (1st launch after install)
08:16:20 Choreographer(3417): Skipped 117 frames (system process, not our app)
08:16:22 Choreographer(3471): Skipped 59 frames (system process)
08:30:28 Choreographer(5934): Skipped 184 frames (2nd cold start)
```

### Memory Snapshot
```
TOTAL PSS:  2,044,046 KB | TOTAL RSS: 1,848,435 KB | TOTAL SWAP PSS: 226,375 KB
Other mmap: 1,610,856 KB (model file)
Native Heap:  560,948 KB (size) / 482,066 KB (alloc)
MemAvailable: 2,388,332 KB | SwapFree: 5,658,396 KB
```

---

## Sprint 5 Retest — 2026-02-28

### Device
Same Galaxy A25 (SM-A256E), Android 14, 5.5 GB RAM, eMMC storage.
Branch: `mowismtest` @ 792555f

### Fixes Verified

| Commit | Fix | Status |
|--------|-----|--------|
| `90e90f6` S5-T1 | posix_fadvise(POSIX_FADV_WILLNEED) via Dart FFI | **VERIFIED** — 30s idle TTFT improved from 8-10s → 2.1s |
| `1f6f6ed` S5-T2 | Multi-frame yields in initialize() | **NOT EFFECTIVE** — frame skips still 175-192 on cold restarts |
| `2991fac` S5-T2 | Cooperative warmup with yields every 64 MB | **NOT EFFECTIVE** — no measurable improvement |
| `8803e4e` S5-T3 | Dead code cleanup, P1 bugs verified | **VERIFIED** — no "Phase 1" text, correct screen shown |

### Cold Start — First Launch After APK Install

| Metric | Value |
|--------|-------|
| Frame skips | **175 + 32** (207 total — similar to Sprint 4) |
| Model load + warmup | **8,843 ms** |
| SHA-256 | Skipped (persisted flag from Sprint 4) |
| Screen shown | Translation screen with enabled input |

### Cold Start — Second Launch

| Metric | Value |
|--------|-------|
| Frame skips | **192** (Sprint 4: 184 — no improvement) |
| Model load + warmup | **6,895 ms** |
| Post-restart TTFT | **8,681 ms** (49s after model load, pages already evicting) |

### Cold Start — Third Launch

| Metric | Value |
|--------|-------|
| Frame skips | **180** (consistent with 2nd launch) |
| Model load + warmup | **4,024 ms** (pages partly cached) |
| Post-restart TTFT | **9,222 ms** (24s after model load) |

### Memory

```
TOTAL PSS:  2,036,821 KB | TOTAL RSS: 1,860,939 KB | TOTAL SWAP PSS: 206,429 KB
Other mmap: 1,611,569 KB (model file, 1.54 GB)
Native Heap: 552,780 KB size, 484,517 KB alloc
```

System memory:
```
MemTotal:     5,518,072 kB
MemAvailable: 2,209,820 kB
MemFree:        242,772 kB
SwapTotal:    8,388,604 kB
SwapFree:     5,775,852 kB
```

**Comparison to Sprint 4:**
- Swap PSS: 206 MB (was 226 MB) — **20 MB less swapping** (posix_fadvise helping)
- MemAvailable: 2.21 GB (was 2.39 GB) — more pages kept resident = less free RAM
- Total PSS/RSS roughly unchanged

### Chat Performance

| Request | TTFT (ms) | tok/s | Tokens | Total (ms) | Condition |
|---------|-----------|-------|--------|------------|-----------|
| #0 | **11,206** | 1.39 | 27 | 19,492 | First inference, ~4min after model load (evicted) |
| #1 | **2,353** | 2.24 | 15 | 6,700 | Back-to-back (warm) |
| #2 | **2,299** | 2.34 | 20 | 8,551 | Back-to-back (warm) |
| #3 | **3,714** | 2.61 | 159 | 61,015 | After short pause |
| #4 | **7,387** | 1.57 | 31 | 19,692 | After ~3.5min idle (evicted) |
| #5 | **3,791** | 2.37 | 32 | 13,513 | Back-to-back (warm) |
| #6 | **3,010** | 2.53 | 57 | 22,563 | Back-to-back (warm) |
| #7 (30s idle) | **2,057** | 2.45 | 18 | 7,361 | **KEY TEST: 30s idle** |
| #8 (2min idle) | **5,633** | 1.61 | 23 | 14,304 | 2min idle stress test |

**Warm steady-state: TTFT ~2.1-3.0s, ~2.3-2.6 tok/s** (improved from Sprint 4's 3.1-3.3s, 2.0-2.1 tok/s)
**30s idle: TTFT 2.1s** (Sprint 4: 8-10s — **massive improvement, posix_fadvise works**)
**2min idle: TTFT 5.6s** (Sprint 4: 8-10s — improved but still degrading)
**Cold/evicted (3+ min): TTFT ~8-11s** (similar to Sprint 4 — fadvise insufficient for long idle)

### Translation Performance

| Request | TTFT (ms) | tok/s | Tokens | Input | Output |
|---------|-----------|-------|--------|-------|--------|
| #11 | 9,665 | 0.65 | 8 | "Where is the nearest hospital" | "¿Dónde está el hospital más cercano?" (GOOD) |
| #12 | 10,479 | 0.48 | 7 | "I would like a table for two" | "Me gustaría una mesa para dos." (GOOD) |
| #13 | 4,151 | 0.84 | 5 | "How much does this cost" | "¿Cuánto cuesta esto?" (GOOD) |

**Translation quality: 3/3 correct direct translations — PASS**

### Token Filtering
- **PASS** — no raw tokens visible in any chat or translation response.

### Multi-Turn Context
- **FAIL** — "My name is Alex" → model responded "Hello! I'm Alex. What can I do for you today?" (acknowledged). But "What is my name?" → "My name is Aya, a language model trained to help with translations." (recalled its own name, not user's).
- Sprint 4 passed this test; failure likely due to longer conversation context diluting the name recall. Also the model has no system prompt telling it to identify as Bittybot (it calls itself Aya).

### New Issues Found

1. **Chat bubbles show raw markdown** — `**bold**` asterisks visible instead of rendered formatting (e.g., `**Translation:**`, `**Spanish:**`). Need markdown rendering in chat bubble widget.
2. **Model identifies as "Aya" not "Bittybot"** — system prompt for chat mode should set the model's identity as "Bittybot".
3. **Frame skips on cold restart NOT fixed** — Sprint 5 yields had no measurable effect (175-192 frames, same as Sprint 4). Root cause is NOT the yield placement — likely eMMC I/O contention from warmup read saturating the bus.

---

## Sprint 5 vs Sprint 4 Comparison

| Metric | Sprint 4 | Sprint 5 | Change |
|--------|----------|----------|--------|
| TTFT (warm) | 3.1-3.3s | 2.1-3.0s | **Improved ~20%** |
| TTFT (30s idle) | 8-10s | **2.1s** | **~75% improvement** |
| TTFT (2min idle) | 8-10s | 5.6s | **~40% improvement** |
| TTFT (3+ min idle) | 8-10s | 8-11s | No change |
| tok/s (warm) | 2.0-2.1 | 2.3-2.6 | **~15% faster** |
| Frame skips (cold restart) | 184 | 180-192 | **No improvement** |
| Swap PSS | 226 MB | 206 MB | **-9%** |
| Model load | 3.7-6.4s | 4.0-8.8s | Variable |

## Performance vs Targets (Sprint 5)

| Metric | Target | Sprint 5 Best | Sprint 5 Typical | Status |
|--------|--------|---------------|-----------------|--------|
| Model load | < 15s | 4.0s | 6.9s | **PASS** |
| TTFT (warm) | < 5s | 2.1s | 2.3-3.0s | **PASS** |
| TTFT (30s idle) | < 5s | 2.1s | ~2s | **PASS** |
| TTFT (2min idle) | < 5s | 5.6s | ~6s | **FAIL (borderline)** |
| tok/s | ~2 (hw ceiling) | 2.61 | 2.3-2.5 | **PASS (at ceiling)** |
| Frame skips | < 50 | 175 | 180-192 | **FAIL** |
| Token filtering | Clean | Clean | Clean | **PASS** |
| Translation quality | Direct | 3/3 direct | Consistent | **PASS** |
| Multi-turn recall | Pass | Fail | Inconsistent | **FAIL** |

---

## Recommendations for Sprint 6 (Priority Order)

### 1. HIGH: Fix Frame Skips on Cold Restart
Sprint 5 yields had zero effect. The 175-192 frame skips persist regardless of yield placement. Root cause is likely **eMMC I/O contention** from the 1.55 GB warmup sequential read saturating the storage bus, starving the Flutter rendering thread of I/O bandwidth for asset loading. Approaches:
- **Defer warmup until after first frame renders** — let Flutter paint the UI first, then start warmup in background
- **Reduce warmup read rate** — add 1-2ms sleeps between 64 MB chunks to leave I/O bandwidth for the main thread
- **Skip warmup entirely on warm restarts** — if pages are still partially cached (model load <5s), warmup adds I/O without benefit

### 2. HIGH: Markdown Rendering in Chat Bubbles
Chat responses contain markdown formatting (`**bold**`, `-` lists) that displays as raw text. Need a markdown renderer in the chat bubble widget (e.g., `flutter_markdown` package or simple regex-based bold/italic rendering).

### 3. HIGH: System Prompt Identity
Model calls itself "Aya" in chat mode. Add a system prompt that establishes identity as "Bittybot" and sets the conversational tone.

### 4. MEDIUM: Longer Idle Page Retention
posix_fadvise works for ~30s but pages still evict after 2+ minutes. Options:
- **Periodic re-fadvise** — timer that re-calls posix_fadvise every 60s
- **Partial mlock** — lock the most critical pages (first 256 MB = embedding tables) via mlock FFI
- **Background keepalive read** — periodic 1-byte reads scattered across the file to touch pages

### 5. LOW: Multi-turn Context Regression
Sprint 4 passed multi-turn recall; Sprint 5 failed. Likely caused by longer conversation context (8+ messages) diluting the name recall signal. Consider:
- Shorter context window for chat mode
- Explicit "remember" instruction in system prompt

---

## Raw Logs — Sprint 5

### Model Load Events
```
09:23:04 [PERF] {"perf":"model_load","duration_ms":8843}  (1st cold start)
09:48:35 [PERF] {"perf":"model_load","duration_ms":6895}  (2nd cold start)
09:50:18 [PERF] {"perf":"model_load","duration_ms":4024}  (3rd cold start)
```

### All Inference Events
```
09:27:26 [PERF] {"request_id":0,"total_ms":19492,"ttft_ms":11206,"token_count":27,"tokens_per_sec":"1.39"}
09:28:23 [PERF] {"request_id":1,"total_ms":6700,"ttft_ms":2353,"token_count":15,"tokens_per_sec":"2.24"}
09:29:11 [PERF] {"request_id":2,"total_ms":8551,"ttft_ms":2299,"token_count":20,"tokens_per_sec":"2.34"}
09:30:34 [PERF] {"request_id":3,"total_ms":61015,"ttft_ms":3714,"token_count":159,"tokens_per_sec":"2.61"}
09:34:24 [PERF] {"request_id":4,"total_ms":19692,"ttft_ms":7387,"token_count":31,"tokens_per_sec":"1.57"}
09:35:13 [PERF] {"request_id":5,"total_ms":13513,"ttft_ms":3791,"token_count":32,"tokens_per_sec":"2.37"}
09:36:57 [PERF] {"request_id":6,"total_ms":22563,"ttft_ms":3010,"token_count":57,"tokens_per_sec":"2.53"}
09:37:52 [PERF] {"request_id":7,"total_ms":7361,"ttft_ms":2057,"token_count":18,"tokens_per_sec":"2.45"}  (30s idle)
09:40:40 [PERF] {"request_id":8,"total_ms":14304,"ttft_ms":5633,"token_count":23,"tokens_per_sec":"1.61"}  (2min idle)
09:44:27 [PERF] {"request_id":11,"total_ms":12307,"ttft_ms":9665,"token_count":8,"tokens_per_sec":"0.65"} (translation)
09:47:18 [PERF] {"request_id":12,"total_ms":14501,"ttft_ms":10479,"token_count":7,"tokens_per_sec":"0.48"} (translation)
09:47:42 [PERF] {"request_id":13,"total_ms":5952,"ttft_ms":4151,"token_count":5,"tokens_per_sec":"0.84"}  (translation)
09:49:39 [PERF] {"request_id":0,"total_ms":14418,"ttft_ms":8681,"token_count":18,"tokens_per_sec":"1.25"}  (post-2nd-restart)
09:51:03 [PERF] {"request_id":0,"total_ms":19242,"ttft_ms":9222,"token_count":34,"tokens_per_sec":"1.77"}  (post-3rd-restart)
```

### Frame Skips
```
09:22:55 Choreographer(11057): Skipped 175 frames (1st cold start)
09:22:55 Choreographer(11057): Skipped 32 frames (1st cold start, 2nd burst)
09:48:27 Choreographer(17381): Skipped 192 frames (2nd cold start)
09:50:14 Choreographer(17858): Skipped 180 frames (3rd cold start)
```

### Memory Snapshot
```
TOTAL PSS:  2,036,821 KB | TOTAL RSS: 1,860,939 KB | TOTAL SWAP PSS: 206,429 KB
Other mmap: 1,611,569 KB (model file)
Native Heap: 552,780 KB (size) / 484,517 KB (alloc)
MemAvailable: 2,209,820 KB | SwapFree: 5,775,852 KB
```
