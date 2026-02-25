# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-19)

**Core value:** Translation and conversation must work with zero connectivity
**Current focus:** Phases 1-3 merged — Phase 1 hardware checkpoint pending, then Phase 4

## Current Position

Phase: 1-3 of 9 (parallel execution complete, merging done)
Status: Phase 2 complete, Phase 3 complete, Phase 1 at plan 5/5 checkpoint (hardware testing)
Last activity: 2026-02-19 — Published to GitHub, cleaned .so from history, rewrote README

Progress: [███░░░░░░░] ~33% (3 phases complete or near-complete)

### Phase Status

| Phase | Status | Plans | Notes |
|-------|--------|-------|-------|
| 1: Inference Spike | 4/5 complete, 01-05 at hardware checkpoint | 5 | libmtmd.so AAR build needed before Android integration tests |
| 2: Model Distribution | Complete | 3/3 | Verification chain passed, all success criteria met |
| 3: App Foundation | Complete | 5/5 | Verification chain in progress (scope-check + change-summary done) |
| 4: Core Inference Arch | Not started | TBD | Depends on Phase 2 + Phase 3 (both now complete) |

## Performance Metrics

**Velocity:**
- Total plans completed: 12 (Phase 1: 4, Phase 2: 3, Phase 3: 5)
- Total execution time: ~1.6 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| Phase 1 | 4/5 | ~28min | ~7min |
| Phase 2 | 3/3 | ~18min | ~6min |
| Phase 3 | 5/5 | ~40min | ~8min |
| Phase 04-core-inference-architecture P01 | 4 | 3 tasks | 4 files |
| Phase 04-core-inference-architecture P02 | 3 | 2 tasks | 2 files |
| Phase 04-core-inference-architecture P03 | 3 | 2 tasks | 5 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

**Pre-Phase 1:**
- Model cannot be bundled in app binary (app store size limits); first-launch download via `background_downloader` required
- Inference binding choice (llama_cpp_dart vs fllama) is unresolved — Phase 1 spike resolves this
- Android NDK r28+ required for 16 KB page compliance (Play Store mandatory by May 31, 2026)
- iOS Simulator blocked (Metal GPU unavailable); Phase 1 must run on physical iOS device

**Phase 1 (Inference Spike):**
- llama_cpp_dart ^0.2.2 selected as primary binding (most recently updated, tracks llama.cpp master)
- Android NDK pinned to 28.0.12674087, compileSdk=36, ndkVersion=29.0.14033849
- iOS minimum deployment target set to 14.0
- 70-language corpus: 4 mustHave with 18 prompts each, 66 standard with 3 reference sentences each
- ModelLoader.loadModel() catches LlamaException broadly — any llama.cpp load failure treated as go/no-go
- nCtx=512, nBatch=256, nPredict=128 for spike — minimal footprint
- llama_cpp_dart is NOT a Flutter plugin — libmtmd.so must be pre-built as AAR

**Phase 2 (Model Distribution):**
- Used package:convert AccumulatorSink for chunked SHA-256 — never loads 2.14 GB into RAM
- SHA-256 verification runs in compute() isolate using 64 KB RandomAccessFile chunks
- registerCallbacks()+enqueue() for background_downloader (not download()) — full TaskProgressUpdate with speed/ETA
- Completer<TaskStatusUpdate> bridges registerCallbacks async API into await pattern

**Phase 3 (App Foundation):**
- flutter_riverpod pinned to 3.1.0 (not 3.2.1): riverpod_generator 4.0.1+ conflicts with flutter_test test_api pin
- synthetic-package removed from l10n.yaml: deprecated in Flutter 3.38.5
- ColorScheme.fromSeed NOT used: fromSeed overrides exact brand hex values; manual ColorScheme() constructor
- Error colour (#CF6679) passes WCAG AA only for large text (3.60:1) — acceptable for 18sp+ banners/icons
- AsyncValue.value not .valueOrNull for Riverpod 3.1.0
- resolveErrorMessage uses Dart 3 record pattern switch (AppError, ErrorTone)
- Locale persisted as languageCode string only
- All widget padding uses EdgeInsetsDirectional (not EdgeInsets) — RTL-ready
- appStartupProvider is @Riverpod(keepAlive: true) Future<void> — Phase 4 extends with modelReadyProvider
- [Phase 04-core-inference-architecture]: Drift row types are ChatSession/ChatMessage (not ChatSessionData/ChatMessageData) — corrected return type on watchMessagesForSession()
- [Phase 04-core-inference-architecture]: Sealed base classes need const constructors for subclass const support — added const InferenceCommand() and const InferenceResponse()
- [Phase 04-core-inference-architecture]: estimateTokenCount uses 2 chars/token (CJK worst-case over-estimate) rather than 4 chars/token (Latin) for earlier context-full detection
- [Phase 04-core-inference-architecture]: Separate _errorPort for addErrorListener: Isolate crash sends List not InferenceResponse — dedicated port keeps listener clean
- [Phase 04-core-inference-architecture]: Manual nPredict counting in await-for loop: ContextParams.nPredict is construction-time only, model loaded once with nPredict=-1
- [Phase 04-core-inference-architecture]: Cooperative stop via closure-scope _stopped flag: accessible from both GenerateCommand async handler and StopCommand handler on same isolate event loop

### Pending Todos

- Minor (Phase 2): `retryDownload()` increments failure counter on "Start over" (user choice, not failure)
- Minor (Phase 2): Single `print()` debug statement in notifier line 301 — remove before production
- Minor (Phase 3): Deprecated Color API in test/core/theme/app_theme_test.dart (.red/.green/.blue → new API)
- Enhancement (Testing): Add live test output overlay to integration test runner — show progress on-device

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 1 | Set app logo from bittybot-logo.png and app name to Bittybot | 2026-02-18 | 8eaec61 | [1-set-app-logo-from-bittybot-logo-png-and-](./quick/1-set-app-logo-from-bittybot-logo-png-and-/) |

### Blockers/Concerns

- **CRITICAL**: Cohere2 architecture support in Flutter llama.cpp plugins is unverified. Phase 1 resolves this.
- **BLOCKER (01-05)**: libmtmd.so (llama_cpp_dart native library for Android) is NOT auto-bundled in the APK. Must be pre-built as AAR before Android integration tests can run.
- **RISK**: iOS memory pressure on 4 GB devices with 2.14 GB model. Phase 1 spike on physical iPhone 12 will surface this.
- **RISK**: Android Play Asset Delivery for 2 GB first-launch download. Phase 2 addresses this.

## Verification

- **2026-02-19:** Verification chain — Phase 1 (plans 01-04)
  - Scope check: PASS, Change summary: documented, UAT: 8/8 pass
  - Report: `.planning/phases/01-inference-spike/VERIFICATION-CHAIN-P01.md`
  - Verdict: Code work PASS — awaiting Plan 05 (on-device hardware)

- **2026-02-19:** Verification chain — Phase 2 (all plans)
  - Scope check: PASS, Change summary: documented, verify-work: PASS
  - Report: `.planning/phases/VERIFICATION-CHAIN-P02.md`
  - Verdict: All success criteria met

- **2026-02-19:** Verification chain — Phase 3 (in progress)
  - Scope check: PASS, Change summary: documented
  - Report: `.planning/phases/VERIFICATION-CHAIN-P03.md`
  - Verdict: Code work PASS — visual verification on device pending

## Merge Log

- **2026-02-19:** Merged `phase/02-model-distribution` into master (fa168f2)
  - Conflicts resolved: pubspec.yaml (combined deps), main.dart (Phase 2 entry), build.gradle.kts (master SDK/NDK), pubspec.lock
- **2026-02-19:** Merged `phase/03-app-foundation` into master (cc8f794)
  - Conflicts resolved: pubspec.yaml (all 3 phases combined, riverpod pinned to 3.1.0), main.dart (Phase 3 GoogleFonts config), app.dart (Phase 3 canonical shell), build.gradle.kts (master SDK/NDK), platform files (iOS/Android), STATE.md (reconciled)
  - flutter_riverpod pinned to ^3.1.0 in merged pubspec.yaml (Phase 3's pin takes priority over Phase 2's ^3.2.1)
  - app.dart: Phase 3's version used as canonical shell; Phase 2's model distribution routing deferred to Phase 4 wiring


## Worktree Assignments

| Worktree | Branch | Phase | Plan | Status | Started | Agent |
|----------|--------|-------|------|--------|---------|-------|
| /home/max/git/bittybot | mowismtest | 04 | 04-02 | executing | 2026-02-25T04:40:07.115Z | unknown |
## Session Continuity

Last session: 2026-02-19
Stopped at: Repo published to GitHub, housekeeping done.
Resume file: .planning/PARALLEL-RESUME.md
Next action: Finish Phase 1 hardware testing (static-linked libmtmd.so rebuild) or start Phase 4 planning

### Context Window Handoff (2026-02-25)
Session approaching context limit (~0% remaining). Work committed. Run /clear and resume.
