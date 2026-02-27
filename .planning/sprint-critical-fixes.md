# Sprint 3: Critical OOM + Cold Start Fixes

## Context
On-device profiling (Galaxy A25, 5.5 GB RAM) revealed two critical blockers:
- **OOM kill** when navigating to Chat tab (~2.6 GB total app memory, device can't sustain)
- **65s SHA-256 verification on every cold start** (190 frames skipped, blocks main thread)

Full results: `.planning/PROFILING-RESULTS.md`

## Tasks

### T-C1: Enable mmap from app data directory [CRITICAL]
**Owner:** RoseFinch → Worker (PearlBadger or TopazPond)
**File:** `lib/features/inference/application/inference_isolate.dart` line 58
**Change:** `..useMemorymap = false` → `..useMemorymap = true`
**Rationale:** The original `use_mmap=false` was needed when model lived at `/data/local/tmp/` (SELinux `shell_data_file` context blocks mmap). Model now lives at `/data/user/0/.../files/models/` which has correct `app_data_file` context. With mmap, OS pages model data in/out of RAM on demand — eliminates the 2.14 GB resident memory requirement.
**Also:** Update CLAUDE.md line 71 — remove or annotate the `use_mmap=false` pattern as outdated (model moved to app data dir).
**Risk:** If mmap still fails on some devices, we need a runtime fallback. For now, just enable it.

### T-C2: One-time SHA-256 verification [CRITICAL]
**Owner:** SwiftSpring → Worker (SageHill)
**File:** `lib/features/model_distribution/model_distribution_notifier.dart` — `initialize()` method (lines 110-134)
**Current behavior:** Every cold start → `VerifyingState` → `verifyModelFile()` → 65 seconds reading 2.14 GB from flash
**New behavior:**
1. After first successful verification (in `_onDownloadComplete` or in `initialize` when model exists), persist to SharedPreferences:
   - `model_verified` = `true`
   - `model_verified_size` = file length in bytes (for tampering detection)
2. In `initialize()`, when model file exists:
   - Read `model_verified` flag from SharedPreferences
   - If `true` AND file size matches `model_verified_size` → skip SHA-256, go straight to `_proceedToLoad()`
   - If flag missing or size mismatch → run full SHA-256 verification (existing flow)
3. Keep full verification in `_onDownloadComplete()` — always verify after fresh download
4. Clear the `model_verified` flag if SHA-256 ever fails (corrupt file path)
**SharedPreferences is already imported** — see line 7 and usage throughout the file.

### T-C3: Show "Loading model..." indicator [MEDIUM]
**Owner:** RoseFinch → Worker
**Context:** After SHA-256 verification, `_proceedToLoad()` sets `LoadingModelState()` but the UI still shows "Verifying download..." text during the 12s model load phase. Need to ensure the download_screen (or whatever widget maps `LoadingModelState`) shows distinct "Loading model..." text.
**Investigation needed:** Find the widget that renders `ModelDistributionState` variants and ensure `LoadingModelState` has its own distinct UI (not falling through to verifying).

### T-C4: Reduce nCtx to save KV cache memory [MEDIUM]
**Owner:** SwiftSpring → Worker (SageHill)
**File:** `lib/features/inference/domain/inference_message.dart` line 22
**Change:** `this.nCtx = 2048` → `this.nCtx = 512`
**Rationale:** KV cache scales linearly with nCtx. 2048 context is overkill for a 3.35B model on a phone — translations need ~128 tokens, chat rarely exceeds 512. Reduces memory footprint significantly. Can revisit if users need longer context.

## Priority Order
1. T-C1 (mmap) — eliminates OOM, unblocks all inference testing
2. T-C2 (SHA-256 skip) — eliminates 65s cold start penalty
3. T-C4 (nCtx reduce) — additional memory savings
4. T-C3 (loading indicator) — polish

## After Fixes
User re-tests on device. We expect:
- Cold start: ~12-13s (model load only, no SHA-256)
- No OOM kill on Chat tab navigation
- Can finally measure inference metrics (TTFT, tokens/sec, token filtering)
