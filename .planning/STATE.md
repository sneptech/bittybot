# Project State

## Project Reference

See: .planning/PROJECT.md
See: .planning/MVP-HANDOFF.md (comprehensive handoff for next milestone)

**Core value:** Translation and conversation must work with zero connectivity
**Current status:** MVP COMPLETE. All 9 feature phases built, all 9 bugs fixed, verified on device.

## Current Position

Phase: 9 of 9 — ALL COMPLETE
Status: MVP complete, merged to master
Last activity: 2026-02-28 — Sprint 9 retest PASS, mowismtest merged to master

Progress: [██████████] 100% (Phases 1-9 complete, Sprints 6-9 verified)

### Phase Status

| Phase | Status | Notes |
|-------|--------|-------|
| 1: Inference Spike | Complete | llama.cpp FFI, static linking, Q3_K_S model confirmed |
| 2: Model Distribution | Complete | Download, resume, SHA-256, size check |
| 3: App Foundation | Complete | Dark theme, 10 locales, RTL, accessibility |
| 4: Core Inference Arch | Complete | Isolate, LLM service, Drift DB, notifiers |
| 5: Translation UI | Complete | 66 languages, picker, streaming, word batching |
| 6: Chat UI | Complete | Multi-turn, markdown, streaming, stop |
| 7: Chat History | Complete | Drawer, persistence, swipe-to-delete |
| 8: Chat Settings | Complete | Auto-clear, clear all, settings screen |
| 9: Web Search | Complete | URL paste mode, fetch, mode indicator |

### Bug Status (All Fixed)

| Bug | Fix | Sprint |
|-----|-----|--------|
| BUG-1: Raw markdown in chat | MarkdownBody widget | S6 |
| BUG-2: "Aya" identity | System prompt | S6 |
| BUG-3: Frame skips | Native splash | S7 |
| BUG-4: Dead code | Removed | S6 |
| BUG-5: FD leak | Shutdown before kill | S6 |
| BUG-6: Stale TODO | Removed | S6 |
| BUG-7: Unguarded print | kDebugMode guard | S6 |
| BUG-8: Context limit stuck | ErrorResponse handler + auto-reset | S7/S8 |
| BUG-9: Translation indicator stuck | isTranslating reset in startNewSession | S9 |

### Performance (Sprint 9 — Galaxy A25)

| Metric | Value |
|--------|-------|
| Model load | 5.9-7.6s |
| Warm TTFT (chat) | 3.2-4.7s avg 3.8s |
| tok/s (chat) | 2.42-2.61 avg 2.50 |
| Post-clear TTFT | 9-13s (accepted) |
| Memory PSS | 1.85 GB |

## Known Limitations (Not Bugs)

1. **nCtx=512** — chat exhausts after ~7-8 messages, translation after ~17-20. Web mode non-functional. See MVP-HANDOFF.md for expansion recommendation.
2. **~200 frame skips on cold start** — Flutter/Impeller Vulkan init, covered by native splash
3. **Post-clear TTFT 9-13s** — mmap page re-fault after context clear, rare event
4. **GPU ruled out** — Mali-G68 is 3-16x slower than CPU for LLM inference

## Next Milestone

**Focus:** UI refinements + context length expansion (nCtx 512 → 2048+)

See `.planning/MVP-HANDOFF.md` for full context, architecture summary, and recommendations.

## Merge Log

- **2026-02-19:** Merged `phase/02-model-distribution` into master
- **2026-02-19:** Merged `phase/03-app-foundation` into master
- **2026-02-28:** Fast-forward merged `mowismtest` into master (all Sprints 6-9 + Phases 4-9 code)

### Context Window Handoff (2026-02-28)
Session approaching context limit (~0% remaining). Work committed. Run /clear and resume.

### Context Window Handoff (2026-02-28)
Session approaching context limit (~0% remaining). Work committed. Run /clear and resume.

### Context Window Handoff (2026-02-28)
Session approaching context limit (~0% remaining). Work committed. Run /clear and resume.

### Context Window Handoff (2026-02-28)
Session approaching context limit (~0% remaining). Work committed. Run /clear and resume.
