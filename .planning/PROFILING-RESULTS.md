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

### Cold Start — First Launch After APK Update

SHA-256 verification runs (expected — first launch sets the verified flag):

| Time (relative) | Event |
|-----------------|-------|
| +0.0s | Flutter engine started (Impeller/Vulkan) |
| +2.1s | 192 frames skipped (SHA-256 begins, blocks main thread) |
| +61.4s | llama.cpp model load begins (SHA-256 done) |
| +68.9s | Model loaded (8,104 ms load time) |
| **Total: ~69s** | First launch only — subsequent launches skip SHA-256 |

### Cold Start — Second Launch (SHA-256 Skipped)

| Time (relative) | Event |
|-----------------|-------|
| +0.0s | Flutter engine started (Impeller/Vulkan) |
| +2.1s | 175 frames skipped (app initialization) |
| +3.4s | llama.cpp model load begins (no SHA-256!) |
| +10.1s | Model loaded (7,478 ms load time) |
| **Total: ~10s** | **Down from ~78s (Sprint 2)** |

### Model Load
- First launch load time: **8,104 ms** (after SHA-256)
- Second launch load time: **7,478 ms** (no SHA-256 overhead)
- Both **well under** the 15s target
- CPU: NEON=1, ARM_FMA=1, LLAMAFILE=1, REPACK=1
- Model path: `/data/user/0/com.bittybot.bittybot/files/models/tiny-aya-global-q4_k_m.gguf`

### Memory (No OOM!)
- App total RSS: **1,189 MB** (vs 2,617 MB in Sprint 2)
- Model mmap region: **2,082 MB mapped**, variable residency (1.0–2.0 GB)
- Native Heap (KV cache + scratch): **519 MB allocated**
- SwapPss: **268 MB** (acceptable, not thrashing)
- No lmkd kills, no OOM events

### Chat Performance

| Request | TTFT (ms) | Tokens | tok/s | Condition |
|---------|-----------|--------|-------|-----------|
| #0 | 10,032 | 6 | 0.50 | Model partially paged (~1.0 GB of 2.0 GB resident) |
| #1 | 10,469 | 7 | 0.52 | Still page-faulting from flash |
| #2 | 11,431 | 9 | 0.60 | Growing context |
| #3 | 6,770 | 6 | 0.65 | After `am kill-all` freed 600 MB |
| **#4** | **2,572** | **15** | **2.05** | **Model 100% resident (2,082 MB RSS)** |
| #5 | 9,596 | 7 | 0.56 | Pages evicted by background services |
| #6 | 9,384 | 72 | 2.06 | New session, long response |

**Key finding**: Performance is directly correlated with model page residency:
- **Model 100% resident**: TTFT ~2.5s, generation ~2.8 tok/s (near targets)
- **Model ~50% resident**: TTFT ~10s, effective ~0.5 tok/s (5x over target)

### Translation Performance

| Request | TTFT (ms) | Tokens | tok/s | Input | Output |
|---------|-----------|--------|-------|-------|--------|
| #7 | 9,618 | 7 | 0.57 | "Good morning everyone" | "¡Buenos días a todos!" |

Translation speed comparable to chat when model pages are partially evicted. Translation uses nPredict=128 vs chat nPredict=512, but the bottleneck is TTFT (page faults), not generation.

### Token Filtering
- **PASS** — no raw tokens (`<|START_OF_TURN_TOKEN|>`, etc.) visible in any chat or translation response
- Observed responses: "Saludos, ¿cómo estás?", "Saludos, Alex. ¿Cómo estás?", "Greetings, Alex.", "Why did the chicken cross the road? To get to the other side!", "¡Buenos días a todos!"

### Multi-Turn Context
- **PASS** — "My name is Alex" → later "What is my name" → "Greetings, Alex." (correct recall)

### Functional Observations
- Chat responds in the language of the user's input (English → English, mixed → Spanish context carried over)
- Translation correctly uses selected target language (Spanish)
- "New session" button clears context
- Both tabs navigable, no crashes

---

## Performance vs Targets

| Metric | Target | Best Case | Typical | Status |
|--------|--------|-----------|---------|--------|
| Model load time | < 15s | 7.5s | 8.1s | **PASS** |
| Cold start (2nd+) | — | 10s | 10s | Acceptable |
| TTFT | < 2s | 2.6s | 9.6s | **FAIL** (memory-dependent) |
| Token generation | > 5 tok/s | 2.8 tok/s | 0.6 tok/s | **FAIL** (memory-dependent) |
| Progress regressions | 0 | N/A | N/A | Not tested (no download) |
| Frame time | < 16ms | — | — | 175 frames skipped at startup |

## Root Cause Analysis: Inference Speed

The 2.14 GB Q4_K_M model cannot stay fully resident on a 5.5 GB device:
- Total device RAM: 5,518 MB
- System + services: ~2,500 MB
- Available for app: ~2,100 MB
- Model mmap: 2,082 MB
- KV cache + scratch: ~519 MB
- **Deficit: ~500 MB** → kernel constantly evicts model pages

When background services restart or system processes allocate, model pages get evicted. Each inference pass walks the entire model (all layers), causing page faults from eMMC flash (~30-40 MB/s random read). This adds 5-10 seconds to every prompt evaluation.

**Evidence**: When `am kill-all` freed 600 MB and model reached 100% residency, TTFT dropped from 10s to 2.6s and tok/s jumped from 0.5 to 2.05.

## Recommendations (Priority Order)

### 1. CRITICAL: Reduce Model Size
The Q4_K_M quantization (2.14 GB) is too large for 5.5 GB devices. Options:
- **Q3_K_S**: ~1.4 GB — would fit comfortably with ~700 MB headroom
- **IQ4_XS**: ~1.5 GB — better quality than Q3_K_S, similar size
- **Q2_K**: ~1.0 GB — significant quality loss but guaranteed fast

Target: model + KV cache < 1.8 GB to ensure full residency on 4-6 GB devices.

### 2. HIGH: Model Page Warmup
After model load, sequentially read through the mmap'd region to pre-fault all pages into RAM:
```dart
// In inference isolate, after Llama() constructor
final bytes = File(modelPath).readAsBytesSync(); // pre-fault pages
// Or: madvise(MADV_WILLNEED) via FFI
```
This won't help if there isn't enough RAM, but when pages CAN fit, it ensures they're loaded before first inference instead of during.

### 3. HIGH: Investigate nThreads Tuning
Currently nThreads=4. The device has 8 cores. Testing with nThreads=6 or nThreads=8 might improve generation speed (currently ~2.8 tok/s on the best run, still under 5 tok/s target).

### 4. MEDIUM: Main Thread Blocking at Startup
175 frames skipped even with SHA-256 skip. The SharedPreferences read, file existence check, and model initialization setup should be fully async to eliminate startup jank.

### 5. LOW: Download Progress Regression Test
Not tested — model was already downloaded. Needs fresh install to verify T-P3 monotonic progress fix.

## Raw Logs

### Model Load Events
```
06:17:52 [PERF] {"perf":"model_load","ts":"2026-02-28T06:17:52.427686","duration_ms":8104}
06:32:40 [PERF] {"perf":"model_load","ts":"2026-02-28T06:32:40.629271","duration_ms":7478}
```

### All Inference Events
```
06:18:56 [PERF] {"perf":"inference_request","request_id":0,"total_ms":11968,"ttft_ms":10032,"token_count":6,"tokens_per_sec":"0.50"}
06:20:39 [PERF] {"perf":"inference_request","request_id":1,"total_ms":13512,"ttft_ms":10469,"token_count":7,"tokens_per_sec":"0.52"}
06:23:29 [PERF] {"perf":"inference_request","request_id":2,"total_ms":15018,"ttft_ms":11431,"token_count":9,"tokens_per_sec":"0.60"}
06:24:50 [PERF] {"perf":"inference_request","request_id":3,"total_ms":9186,"ttft_ms":6770,"token_count":6,"tokens_per_sec":"0.65"}
06:25:26 [PERF] {"perf":"inference_request","request_id":4,"total_ms":7303,"ttft_ms":2572,"token_count":15,"tokens_per_sec":"2.05"}
06:26:17 [PERF] {"perf":"inference_request","request_id":5,"total_ms":12552,"ttft_ms":9596,"token_count":7,"tokens_per_sec":"0.56"}
06:28:00 [PERF] {"perf":"inference_request","request_id":6,"total_ms":34998,"ttft_ms":9384,"token_count":72,"tokens_per_sec":"2.06"}
06:31:39 [PERF] {"perf":"inference_request","request_id":7,"total_ms":12387,"ttft_ms":9618,"token_count":7,"tokens_per_sec":"0.57"}
```

### Memory Snapshot (During Testing)
```
TOTAL PSS: 1,421,622 KB  |  TOTAL RSS: 1,188,691 KB  |  TOTAL SWAP PSS: 267,418 KB
Model mmap: 2,082,132 KB mapped, 1,855,120 KB resident (89%)
Native Heap: 519,532 KB size, 478,216 KB alloc
```

### Cold Start #2 Timeline
```
06:32:30.523 Flutter engine started (Impeller/Vulkan)
06:32:32.646 Choreographer: Skipped 175 frames
06:32:33.936 llama.cpp model load begins (no SHA-256!)
06:32:40.632 [PERF] model_load duration_ms=7478
```

### Frame Skips
```
06:16:45 Choreographer(18050): Skipped 192 frames (first launch, SHA-256)
06:18:39 Choreographer(18050): Skipped 39 frames
06:32:32 Choreographer(21382): Skipped 175 frames (second launch, no SHA-256)
```
