# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-19)

**Core value:** Translation and conversation must work with zero connectivity
**Current focus:** Phase 1 - Inference Spike

## Current Position

Phase: 1 of 9 (Inference Spike)
Plan: 1 of 5 in current phase
Status: Executing plans
Last activity: 2026-02-18 — Completed Plan 01: Flutter project bootstrap and 70-language corpus

Progress: [█░░░░░░░░░] 10%

## Performance Metrics

**Velocity:**
- Total plans completed: 1
- Average duration: 8 min
- Total execution time: 0.13 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| Phase 1 | 1 | 8 min | 8 min |

**Recent Trend:**
- Last 5 plans: 01-01 (8 min)
- Trend: —

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Pre-Phase 1]: Model cannot be bundled in app binary (app store size limits); first-launch download via `background_downloader` required
- [Pre-Phase 1]: Inference binding choice (llama_cpp_dart vs fllama) is unresolved — Phase 1 spike resolves this by checking which has Cohere2-compatible llama.cpp version
- [Pre-Phase 1]: Android NDK r28+ required for 16 KB page compliance (Play Store mandatory by May 31, 2026)
- [Pre-Phase 1]: iOS Simulator blocked (Metal GPU unavailable); Phase 1 must run on physical iOS device
- [01-01]: llama_cpp_dart ^0.2.2 selected as primary binding (most recently updated, tracks llama.cpp master)
- [01-01]: Android NDK pinned to 28.0.12674087 (not flutter.ndkVersion variable) for guaranteed r28+ compliance
- [01-01]: iOS minimum deployment target set to 14.0 (upgraded from flutter create default of 13.0)
- [01-01]: Cantonese has explicit Cantonese-forcing instruction and particle validation — separate from Mandarin
- [01-01]: 70-language corpus: 4 mustHave with 18 prompts each, 66 standard with 3 reference sentences each

### Pending Todos

None yet.

### Blockers/Concerns

- **CRITICAL**: Cohere2 architecture support in Flutter llama.cpp plugins is unverified. If neither `llama_cpp_dart` nor `fllama` includes llama.cpp PR #19611, the project approach must change before any production code is written. Phase 1 resolves this.
- **RISK**: iOS memory pressure on 4 GB devices (iPhone 12/13 base) with a 2.14 GB model. Phase 1 spike on physical iPhone 12 will surface this.
- **RISK**: Android Play Asset Delivery — whether Google Play will accept a first-launch download of 2 GB vs. requiring PAD integration. Phase 2 addresses this.

## Session Continuity

Last session: 2026-02-18
Stopped at: Completed 01-01-PLAN.md (Plan 1 of 5, Phase 1)
Resume file: .planning/phases/01-inference-spike/01-02-PLAN.md
