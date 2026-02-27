# Sprint 4: Inference Performance

## Context
Sprint 3 fixed OOM and cold start. On-device retest (`.planning/PROFILING-RESULTS.md`) shows:
- Model load: 7.5s PASS
- Cold start 2nd+: 10s PASS (down from 78s)
- Token filtering: PASS
- Multi-turn context: PASS
- **TTFT: 2.6s best, 9.6s typical — FAIL (target <2s)**
- **tok/s: 2.8 best, 0.6 typical — FAIL (target >5)**

Root cause: 2.14 GB Q4_K_M model can't stay fully resident on 5.5 GB device.
When fully resident: TTFT 2.6s, 2.8 tok/s. When pages evicted: TTFT 10s, 0.5 tok/s.

## Available Quantizations (HuggingFace)
Only 5 variants available from CohereLabs — no Q3_K_S or IQ4_XS:
- Q4_0: 2.03 GB (only 110 MB smaller — not enough)
- Q4_K_M: 2.14 GB (current)
- Q8_0: 3.57 GB, BF16: 6.71 GB, F16: 6.71 GB

**Must self-quantize** from F16 to Q3_K_S (~1.3-1.4 GB estimated).

## Tasks

### T-S1: Self-quantize to Q3_K_S [CRITICAL — BlueMountain infra]
- Build llama.cpp from source (cmake)
- Download F16 GGUF (6.71 GB) from HuggingFace
- Run `llama-quantize tiny-aya-global-f16.gguf tiny-aya-global-q3_k_s.gguf Q3_K_S`
- Compute SHA-256 of output
- Upload to GitHub release on sneptech/bittybot
- Report: new filename, URL, size, SHA-256

### T-S2: Update ModelConstants [CRITICAL — after T-S1]
- Owner: SwiftSpring → SageHill
- Update `model_constants.dart`: downloadUrl, filename, fileSizeBytes, sha256Hash, fileSizeDisplayGB, requiredFreeSpaceMB
- Clear `model_verified` flag logic should handle file size mismatch (already does from T-C2)
- Update download UI size text

### T-S3: nThreads tuning [HIGH]
- Owner: RoseFinch → PearlBadger
- Current: nThreads=4, best tok/s=2.8 with full residency
- Device has 6 big + 2 little cores
- Make nThreads configurable via LoadModelCommand (already is, default=4)
- Try values: 2, 6, 8 — need on-device testing to determine optimal
- For now: change default to 6 (use all big cores)

### T-S4: Startup jank fix [MEDIUM]
- Owner: RoseFinch → TopazPond
- 175 frames skipped even on 2nd launch (no SHA-256)
- SharedPreferences read, file existence check, and model init setup should be fully async
- Investigate what's blocking main thread during initialization

### T-S5: Model page warmup [MEDIUM]
- Owner: SwiftSpring → SageHill (after T-S2)
- After model load in inference isolate, sequentially read mmap'd region to pre-fault pages
- Won't help if RAM insufficient, but with smaller model (post T-S1) it ensures pages are loaded before first inference
- Implementation: `madvise(MADV_SEQUENTIAL)` via FFI or manual read-through

## Priority / Dependency
```
T-S1 (quantize, infra) ──→ T-S2 (update constants) ──→ T-S5 (page warmup)
T-S3 (nThreads) ─── independent, parallel
T-S4 (startup jank) ─── independent, parallel
```

## Expected Impact
- Q3_K_S (~1.4 GB) + KV cache (~200 MB with nCtx=512) = ~1.6 GB total
- Device available: ~2.1 GB → ~500 MB headroom for full residency
- Should achieve consistent TTFT <2s, tok/s 3-5+
- nThreads=6 may boost tok/s another 20-30%
