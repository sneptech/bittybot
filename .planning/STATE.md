# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-19)

**Core value:** Translation and conversation must work with zero connectivity
**Current focus:** All feature phases (6-9) code-complete. Pending on-device testing.

## Current Position

Phase: 9 of 9
Status: All feature phases complete (~95%)
Last activity: 2026-02-25 — Phase 5 Plan 03 executed (language picker sheet, grid item, wired to translation screen, long-press copy on bubbles)

Progress: [█████████░] ~95% (Phases 1-9 code-complete, pending on-device testing)

### Phase Status

| Phase | Status | Plans | Notes |
|-------|--------|-------|-------|
| 1: Inference Spike | 4/5 complete, 01-05 at hardware checkpoint | 5 | libmtmd.so AAR build needed before Android integration tests |
| 2: Model Distribution | Complete | 3/3 | Verification chain passed, all success criteria met |
| 3: App Foundation | Complete | 5/5 | Verification chain passed |
| 4: Core Inference Arch | Complete | 5/5 | Automated verification passed; human verification deferred to Phase 6 |
| 5: Translation UI | In progress | 3/4 | Plan 03 complete: language picker sheet, grid item, wired to translation screen, long-press copy |
| 6: Chat UI | Complete | 1/1 | Chat screen, bubble list, input bar, session messages provider |
| 7: Chat History | Complete | 1/1 | Chat history drawer, session management, swipe-to-delete |
| 8: Chat Settings | Complete | 1/1 | Settings screen, auto-clear toggle, clear all history |
| 9: Web Search | Complete | 1/1 | Web fetch service, URL paste mode, mode indicator |

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
| Phase 04-core-inference-architecture P04 | 3 | 2 tasks | 7 files |
| Phase 04-core-inference-architecture P05 | 5min | 2 tasks | 4 files |
| Phase 05-translation-ui P02 | 4 | 2 tasks | 6 files |
| Phase 05-translation-ui P03 | 4 | 2 tasks | 4 files |

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
- Android NDK pinned to 29.0.14033849, compileSdk=36
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
- [Phase 04-core-inference-architecture]: Domain ChatSession/ChatMessage use same names as Drift row types — resolved via import alias 'as db' in DriftChatRepository
- [Phase 04-core-inference-architecture]: DriftChatRepository uses constructor injection (not DatabaseAccessor subclass) for simpler Riverpod integration
- [Phase 04-core-inference-architecture]: insertMessage touches parent session updatedAt to bubble session to top of drawer list without explicit caller coordination
- [Phase 04-core-inference-architecture]: appStartupProvider remains settings-only: model loads independently via modelReadyProvider (partial-access pattern)
- [Phase 04-core-inference-architecture]: ModelReady uses WidgetsBindingObserver mixin on AsyncNotifier for OS-kill recovery
- [Phase 04-core-inference-architecture]: inferenceRepositoryProvider throws StateError if accessed before modelReadyProvider resolves
- [Phase 04-core-inference-architecture]: ChatNotifier is auto-dispose: DB is source of truth; state reloads fresh per screen entry
- [Phase 04-core-inference-architecture]: TranslationNotifier is keepAlive: language pair persists across navigation per TRNS-05
- [Phase 04-core-inference-architecture]: Queue<String> for request pending: FIFO queue matches locked decision — messages queue behind active generation
- [Phase 04-core-inference-architecture]: Language pair change resets session + clearContext: terminology consistency requires fresh KV cache per pair
- [Phase 05-translation-ui P01]: targetLanguage stored as englishName string ('Spanish') — matches existing TranslationState.targetLanguage field; no code-to-name mapping needed at notifier level
- [Phase 05-translation-ui P01]: recentTargetLanguages uses prepend + toSet() + sublist(0, 3) — simple dedup; avoids duplicates after re-selecting same language
- [Phase 05-translation-ui P01]: startNewSession() is a new public method on TranslationNotifier (not alias for setTargetLanguage) — calling setTargetLanguage with same language was a no-op
- [Phase 05-translation-ui P01]: sessionMessagesProvider is auto-dispose StreamProvider.family — TranslationNotifier is keepAlive but stream should recreate per sessionId change
- [Phase 05-translation-ui P01]: 66 languages as canonical kSupportedLanguages count — model card names exactly 66; country variants handled via kLanguageCountryVariants flag map
- [Phase 05-translation-ui]: Generated provider name is 'translationProvider' (not 'translationNotifierProvider') — riverpod_generator strips 'Notifier' suffix from class name
- [Phase 05-translation-ui]: Word-level batching: space-delimited scripts show last complete word boundary during streaming; CJK/Thai/Lao/Khmer/Burmese use token-by-token display
- [Phase 05-translation-ui]: CountryFlag v4.1.2: ImageTheme wrapper required for width/height/shape params in fromCountryCode()
- [Phase 05-translation-ui]: LocaleNames cache in didChangeDependencies: avoids per-build recompute; triggers on locale change
- [Phase 05-translation-ui]: allowCopy: false on streaming bubble: copy disabled during active streaming to avoid partial text

### Pending Todos

- Minor (Phase 2): `retryDownload()` increments failure counter on "Start over" (user choice, not failure)
- Minor (Phase 2): Single `print()` debug statement in notifier line 301 — remove before production
- Minor (Phase 3): Deprecated Color API in test/core/theme/app_theme_test.dart (.red/.green/.blue → new API)
- Enhancement (Testing): Add live test output overlay to integration test runner — show progress on-device
- **Deferred (Phase 4):** Human verification of 4 success criteria — test when Chat UI (Phase 6) is built:
  1. Main thread non-blocking (no ANR during inference)
  2. Isolate persists for session (no per-request respawn)
  3. Multi-turn context coherence ("My name is Alex" → "What is my name?")
  4. Drift persistence across app restart

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

- **2026-02-25:** Verification — Phase 4 (structural pass, human deferred)
  - Automated: 4/4 must-haves structurally verified, all 20 source files substantive, all 15 key links wired
  - Report: `.planning/phases/04-core-inference-architecture/04-VERIFICATION.md`
  - Verdict: Code PASS — human verification deferred to Phase 6 (needs chat UI to exercise pipeline)

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
| /home/max/git/bittybot | mowismtest | 05 | 05-04 | executing | 2026-02-25T06:05:18.335Z | unknown |
## Session Continuity

Last session: 2026-02-25
Stopped at: Phase 5 execution paused at Plan 04 checkpoint (human verification). Plans 01-03 complete, code compiles, APK builds.
Next action: **INVESTIGATE BEFORE CONTINUING Phase 5 verification**

### Next Session: Required Investigation

**Problem observed during Phase 5 human verification:**
1. **App logo reset to default Flutter icon** — the custom bittybot-logo.png set in quick task #1 (commit 8eaec61) appears to have been overwritten or lost
2. **App shows wrong screen** — instead of the Translation UI (Phase 5), the app displays a blank white window with "BittyBot - Phase 1 Inference Spike" text in a bluish header bar. The `AppStartupWidget` → `ModelLoadingScreen` gate may be blocking access to `MainShell`/`TranslationScreen`
3. **Phase routing/wiring may be broken** — the app entry point (`AppStartupWidget`) gates on `appStartupProvider` (settings only) then shows `MainShell`. But what the user sees suggests the model loading screen or an older phase's UI is showing instead

**Suspected root cause:** The GSD → Mowism migration may have introduced a bug where completed phase context is not properly propagated into central/overarching planning documentation. The executor agents may be writing code that doesn't properly integrate with earlier phases' code because the planning context is incomplete or stale.

**Investigation steps:**
1. Explore `.planning/phases/` directory — read SUMMARY.md files from each completed phase to understand what was actually built vs what STATE.md/ROADMAP.md says
2. Compare the actual `lib/` source tree against what each phase claims to have produced — check for overwrites, missing files, or broken imports
3. Check `lib/widgets/model_loading_screen.dart` — what does it show? Is it the "Phase 1 Inference Spike" text the user saw?
4. Check Android launcher icon resources (`android/app/src/main/res/mipmap-*/`) — verify bittybot logo is still there
5. Trace the app startup path: `main.dart` → `app.dart` → `AppStartupWidget` → `ModelLoadingScreen` (loading) vs `MainShell` (loaded) — what state is `appStartupProvider` in?
6. Verify that Phase 4's `modelReadyProvider` and Phase 2's download flow are properly integrated — the app may be stuck at a gate that was never wired correctly after the parallel phase merges

**Broader concern:** Mowism executor agents may not be getting sufficient context about what earlier phases built. Each agent gets fresh 200k context but only reads specific @-referenced files. If the planning docs don't accurately reflect what's in the codebase (e.g., after merge conflicts, file overwrites, or migration gaps), agents may produce code that doesn't integrate correctly.

### Context Window Handoff (2026-02-25)
Session approaching context limit (~8% remaining). Work committed. Run /clear and resume.

### Context Window Handoff (2026-02-25)
Session approaching context limit (~7% remaining). Work committed. Run /clear and resume.

### Context Window Handoff (2026-02-25)
Session approaching context limit (~2% remaining). Work committed. Run /clear and resume.

### Context Window Handoff (2026-02-27)
Session approaching context limit (~4% remaining). Work committed. Run /clear and resume.

### Context Window Handoff (2026-02-27)
Session approaching context limit. Work committed. Run /clear and resume.

### Context Window Handoff (2026-02-28) — Sprint 5 Profiling Complete
Sprint 5 on-device profiling complete. Results written to `.planning/PROFILING-RESULTS.md`.

**Key findings:**
- posix_fadvise WORKS — 30s idle TTFT dropped from 8-10s to 2.1s
- Warm TTFT improved to 2.1-3.0s (from 3.1-3.3s), tok/s improved to 2.3-2.6 (from 2.0-2.1)
- Frame skip yields had ZERO effect — still 175-192 frames on cold restarts
- 2min+ idle still degrades to 5-10s TTFT — advisory not strong enough for long idle
- Translation quality: 3/3 correct, token filtering: PASS, no OOM

**New issues found during testing:**
1. Chat bubbles show raw markdown (`**bold**` asterisks visible) — needs markdown rendering
2. Model identifies as "Aya" not "Bittybot" — chat system prompt needs identity
3. Multi-turn name recall failed (passed in Sprint 4) — context dilution from long conversation

**Next steps (Sprint 6):**
1. Fix frame skips — defer warmup until after first frame, or reduce warmup I/O rate
2. Add markdown rendering to chat bubbles (flutter_markdown or similar)
3. Add system prompt for chat mode: identity="Bittybot", personality, instructions
4. Periodic re-fadvise or partial mlock for longer idle retention
5. Consider system prompt instructions for better multi-turn recall

### Context Window Handoff (2026-02-27)
Session approaching context limit (~0% remaining). Work committed. Run /clear and resume.

### Context Window Handoff (2026-02-27)
Session approaching context limit (~0% remaining). Work committed. Run /clear and resume.

### Context Window Handoff (2026-02-28)
Session approaching context limit (~0% remaining). Work committed. Run /clear and resume.

### Context Window Handoff (2026-02-28)
Session approaching context limit (~0% remaining). Work committed. Run /clear and resume.

### Context Window Handoff (2026-02-28)
Session approaching context limit (~0% remaining). Work committed. Run /clear and resume.

### Context Window Handoff (2026-02-28)
Session approaching context limit (~0% remaining). Work committed. Run /clear and resume.

### Context Window Handoff (2026-02-28)
Session approaching context limit (~0% remaining). Work committed. Run /clear and resume.

### Context Window Handoff (2026-02-28)
Session approaching context limit (~0% remaining). Work committed. Run /clear and resume.

### Context Window Handoff (2026-02-28)
Session approaching context limit (~0% remaining). Work committed. Run /clear and resume.

### Context Window Handoff (2026-02-28)
Session approaching context limit (~0% remaining). Work committed. Run /clear and resume.
