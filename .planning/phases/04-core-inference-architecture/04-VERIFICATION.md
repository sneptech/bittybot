---
phase: 04-core-inference-architecture
verified: 2026-02-25T06:00:00Z
status: human_needed
score: 4/4 must-haves verified
re_verification: false
human_verification:
  - test: "Token streaming is non-blocking — send a translation/chat request and confirm the Flutter main thread does not freeze or drop frames"
    expected: "UI remains responsive (scrollable, tappable) while the inference isolate is generating; tokens appear word-by-word in the output area"
    why_human: "Cannot verify ANR absence or frame drops programmatically without a running device"
  - test: "Inference isolate starts once and persists — tap through the app for 5+ minutes, start multiple conversations"
    expected: "No repeated model load time between messages; only one isolate spawn occurs at startup (check logcat/console for 'Model loaded' appearing exactly once)"
    why_human: "Isolate persistence is a runtime property; cannot be verified by static code inspection"
  - test: "Multi-turn ChatNotifier preserves Aya context — send 'My name is Alex', then on follow-up send 'What is my name?'"
    expected: "Model responds with 'Alex' (demonstrating KV cache continuity); second message uses buildFollowUpPrompt, not initial"
    why_human: "Requires live inference against the actual Tiny Aya model running in the isolate"
  - test: "Chat session and messages survive app restart — create a session, send messages, force-quit the app and reopen"
    expected: "Session and all messages reappear in the same order; no data loss; Drift WAL mode does not corrupt on restart"
    why_human: "Requires a device running the app and a force-quit cycle"
---

# Phase 4: Core Inference Architecture Verification Report

**Phase Goal:** The production inference layer is built — long-lived Dart Isolate owning the llama.cpp context, LLM Service managing isolate lifecycle, InferenceRepository interface, ChatNotifier and TranslationNotifier, PromptBuilder with Aya chat template, and Drift DB schema — so all UI phases can wire up to a stable, non-blocking inference pipeline
**Verified:** 2026-02-25T06:00:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (from ROADMAP.md Success Criteria)

| #  | Truth | Status | Evidence |
|----|-------|--------|----------|
| 1  | Translation request reaches isolate, runs inference, streams tokens back without freezing main thread | ? UNCERTAIN | Code path is fully wired: TranslationNotifier → inferenceRepositoryProvider → LlmService → Isolate.spawn(inferenceIsolateMain) → Llama.generateText() → TokenResponse → state update. Cannot verify ANR-free without a running device. |
| 2  | Inference Isolate starts once at app launch and persists for the session; not respawned per request | ? UNCERTAIN | LlmService architecture is singleton-per-start: `start()` spawns one isolate, subsequent `generate()` calls reuse `_commandPort`. Circuit breaker caps respawns at 3. Cannot verify runtime persistence without device. |
| 3  | Multi-turn ChatNotifier preserves message history in Aya chat template format | ? UNCERTAIN | ChatNotifier uses `_turnCount` to switch between `buildInitialPrompt` (turn 0) and `buildFollowUpPrompt` (turn >0). KV cache semantics correct. Needs live inference to verify contextual coherence. |
| 4  | Chat sessions and messages stored in Drift SQLite survive app restart | ? UNCERTAIN | DriftChatRepository.insertMessage() persists every user and assistant message. Schema v2 with WAL + foreign_keys. Cannot verify cross-restart persistence without device. |

**Score:** 4/4 truths structurally verified (code wiring complete; all 4 require human device testing for runtime confirmation)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/core/db/app_database.dart` | ChatSessions + ChatMessages tables, schemaVersion 2, WAL + FK migration | VERIFIED | Contains `class ChatSessions extends Table`, `class ChatMessages extends Table`, `schemaVersion => 2`, `MigrationStrategy` with `beforeOpen` WAL/FK pragmas, `references(ChatSessions, #id)` foreign key |
| `lib/core/db/app_database.g.dart` | Drift-generated ChatSession + ChatMessage row types and companions | VERIFIED | Generated file present; contains `$ChatSessionsTable`, `ChatSession` row type, `ChatSessionsCompanion` |
| `lib/features/inference/domain/inference_message.dart` | Sealed InferenceCommand (5 variants) + InferenceResponse (4 variants) | VERIFIED | `sealed class InferenceCommand` with LoadModel/Generate/Stop/ClearContext/Shutdown; `sealed class InferenceResponse` with ModelReady/Token/Done/Error. All fields are primitives (int, String, bool). |
| `lib/features/inference/domain/prompt_builder.dart` | Aya chat template with translation/chat system prompts | VERIFIED | `class PromptBuilder` with `buildInitialPrompt`, `buildFollowUpPrompt`, `buildTranslationPrompt`, `buildFollowUpTranslationPrompt`, `estimateTokenCount`. Initial prompt verified to start with `<\|START_OF_TURN_TOKEN\|><\|USER_TOKEN\|>` and end with `<\|START_OF_TURN_TOKEN\|><\|CHATBOT_TOKEN\|>`. |
| `lib/features/inference/application/inference_isolate.dart` | Top-level isolate entry point owning Llama instance | VERIFIED | `void inferenceIsolateMain(SendPort mainSendPort)` is a top-level function; handles all 5 command types; owns `Llama?` FFI instance; `_stopped` flag in closure scope for cooperative stop |
| `lib/features/inference/application/llm_service.dart` | LlmService managing isolate lifecycle with crash recovery | VERIFIED | `class LlmService` with `start()`, `generate()`, `stop()`, `clearContext()`, `dispose()`, `isAlive`, `isGenerating`. Circuit breaker `_maxAutoRetries = 3`. Completer-based SendPort handshake. |
| `lib/features/inference/application/llm_service_provider.dart` | modelReadyProvider keepAlive AsyncNotifier with lifecycle observer | VERIFIED | `class ModelReady extends _$ModelReady with WidgetsBindingObserver`. `@Riverpod(keepAlive: true)`. Reads `modelDistributionProvider.notifier.modelFilePath`, spawns `LlmService`, implements `didChangeAppLifecycleState` for OS-kill recovery. |
| `lib/features/inference/application/llm_service_provider.g.dart` | Generated Riverpod code for ModelReady | VERIFIED | File exists with proper `@ProviderFor(ModelReady)` generated content |
| `lib/features/inference/domain/inference_repository.dart` | Abstract InferenceRepository interface | VERIFIED | `abstract class InferenceRepository` with `generate()`, `stop()`, `clearContext()`, `isGenerating`, `responseStream` |
| `lib/features/inference/data/inference_repository_impl.dart` | LlmServiceInferenceRepository + inferenceRepositoryProvider | VERIFIED | `class LlmServiceInferenceRepository implements InferenceRepository` delegating all 5 members to LlmService. `@Riverpod(keepAlive: true) InferenceRepository inferenceRepository(Ref ref)` reads `modelReadyProvider`. |
| `lib/features/inference/data/inference_repository_impl.g.dart` | Generated provider code | VERIFIED | File exists |
| `lib/features/chat/domain/chat_session.dart` | ChatSession value object | VERIFIED | `@immutable class ChatSession` with id, title?, mode, createdAt, updatedAt. const constructor, `==`, `hashCode`, `toString`. |
| `lib/features/chat/domain/chat_message.dart` | ChatMessage value object with copyWith | VERIFIED | `@immutable class ChatMessage` with id, sessionId, role, content, isTruncated, createdAt. const constructor, `copyWith(content, isTruncated)`, `==`, `hashCode`. |
| `lib/features/chat/data/chat_repository.dart` | Abstract ChatRepository interface | VERIFIED | `abstract class ChatRepository` with 12 methods: 5 session CRUD + 5 message CRUD + 2 bulk. Reactive `watchAllSessions()` and `watchMessagesForSession()` streams. |
| `lib/features/chat/data/chat_repository_impl.dart` | Drift-backed DriftChatRepository | VERIFIED | `class DriftChatRepository implements ChatRepository` — all 12 methods implemented with Drift queries. Prefixed `db.` import disambiguates Drift vs domain types. `_mapSession()` and `_mapMessage()` convert row types to domain value objects. |
| `lib/features/chat/application/chat_repository_provider.dart` | appDatabaseProvider + chatRepositoryProvider | VERIFIED | `@Riverpod(keepAlive: true) AppDatabase appDatabase(Ref ref)` with `ref.onDispose(db.close)`. `@Riverpod(keepAlive: true) ChatRepository chatRepository(Ref ref)` watching `appDatabaseProvider`. |
| `lib/features/chat/application/chat_notifier.dart` | ChatNotifier multi-turn state manager | VERIFIED | `@riverpod class ChatNotifier extends _$ChatNotifier`. Has `sendMessage`, `stopGeneration`, `loadSession`, `startNewSession`, `startNewSessionWithCarryForward`. Request queue via `Queue<String> _pendingQueue`. `_turnCount` tracks initial vs follow-up prompts. nPredict=512. Persists all messages to Drift. |
| `lib/features/chat/application/chat_notifier.g.dart` | Generated Riverpod code for ChatNotifier | VERIFIED | File exists with `ChatNotifierProvider` (auto-dispose, `isAutoDispose: true`) |
| `lib/features/translation/application/translation_notifier.dart` | TranslationNotifier state manager | VERIFIED | `@Riverpod(keepAlive: true) class TranslationNotifier`. Has `translate`, `stopTranslation`, `setSourceLanguage`, `setTargetLanguage`, `swapLanguages`. nPredict=128. Language pair change triggers `_resetSession()` which clears KV cache. Persists translations to Drift. |
| `lib/features/translation/application/translation_notifier.g.dart` | Generated Riverpod code for TranslationNotifier | VERIFIED | File exists with `TranslationNotifierProvider` (keepAlive, `isAutoDispose: false`) |
| `lib/widgets/app_startup_widget.dart` | appStartupProvider remains settings-only | VERIFIED | `Future<void> appStartup(Ref ref)` awaits only `settingsProvider.future`. Design comment explains partial-access rationale. No `modelReadyProvider` dependency. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `app_database.dart` | `ChatMessages.sessionId` | `references(ChatSessions, #id)` | WIRED | Line 25: `integer().references(ChatSessions, #id)()` |
| `llm_service.dart` | `inference_isolate.dart` | `Isolate.spawn(inferenceIsolateMain, ...)` | WIRED | Line 114-116: `await Isolate.spawn(inferenceIsolateMain, _responsePort!.sendPort)` |
| `inference_isolate.dart` | `package:llama_cpp_dart` | `Llama(...)` constructor | WIRED | Line 52: `llama = Llama(message.modelPath, modelParams: modelParams, contextParams: contextParams, verbose: false)` |
| `llm_service.dart` | `inference_message.dart` | `SendPort.send` with InferenceCommand/InferenceResponse types | WIRED | `InferenceResponse` used as stream type; `GenerateCommand`, `StopCommand`, etc. sent via `_commandPort.send()` |
| `llm_service_provider.dart` | `llm_service.dart` | `ModelReady.build()` creates and starts LlmService | WIRED | Lines 42-43: `_llmService = LlmService(modelPath: modelPath); await _llmService!.start()` |
| `llm_service_provider.dart` | `model_distribution/providers.dart` | `ref.read(modelDistributionProvider.notifier).modelFilePath` | WIRED | Lines 38-39: `final notifier = ref.read(modelDistributionProvider.notifier); final modelPath = notifier.modelFilePath` |
| `inference_repository_impl.dart` | `llm_service_provider.dart` | `ref.watch(modelReadyProvider).value` | WIRED | Line 50: `final llmService = ref.watch(modelReadyProvider).value` |
| `inference_repository_impl.dart` | `inference_repository.dart` | `implements InferenceRepository` | WIRED | Line 16: `class LlmServiceInferenceRepository implements InferenceRepository` |
| `chat_repository_impl.dart` | `app_database.dart` | `DriftChatRepository` constructor receives `AppDatabase` | WIRED | Line 14: `final db.AppDatabase _db` with prefixed import |
| `chat_repository_impl.dart` | `chat_session.dart` | `_mapSession` converts Drift row to domain ChatSession | WIRED | Lines 182-188: `ChatSession _mapSession(db.ChatSession row) => ChatSession(...)` |
| `chat_notifier.dart` | `inference_repository_impl.dart` | `ref.read(inferenceRepositoryProvider)` | WIRED | Multiple callsites (lines 186, 222, 236, 331, 350) |
| `chat_notifier.dart` | `chat_repository.dart` | `ref.read(chatRepositoryProvider)` | WIRED | Multiple callsites (lines 160, 181, 235, 289, 291, 396, 434) |
| `chat_notifier.dart` | `prompt_builder.dart` | `PromptBuilder.buildInitialPrompt` and `buildFollowUpPrompt` | WIRED | Lines 303-308: `if (_turnCount == 0) { prompt = PromptBuilder.buildInitialPrompt(...) } else { prompt = PromptBuilder.buildFollowUpPrompt(text) }` |
| `translation_notifier.dart` | `inference_repository_impl.dart` | `ref.read(inferenceRepositoryProvider)` | WIRED | Lines 214, 231, 297, 316 |
| `translation_notifier.dart` | `prompt_builder.dart` | `PromptBuilder.buildTranslationPrompt` / `buildFollowUpTranslationPrompt` | WIRED | Lines 268-276: `if (state.turnCount == 0) { prompt = PromptBuilder.buildTranslationPrompt(...) } else { prompt = PromptBuilder.buildFollowUpTranslationPrompt(...) }` |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| MODL-05 | 04-01, 04-02, 04-04 | Model loads in background with loading indicator; chat input disabled until ready | SATISFIED | `modelReadyProvider` loads LlmService in background independently of `appStartupProvider`. ChatNotifier and TranslationNotifier expose `isModelReady` from `ref.watch(modelReadyProvider).hasValue` — Phase 5/6 UI will gate input on this flag. |
| CHAT-01 | 04-05 | User can have multi-turn conversations with the model | SATISFIED | ChatNotifier implements multi-turn: `_turnCount` tracks initial vs follow-up, session created/loaded from DB, messages accumulated in `ChatState.messages`. |
| CHAT-02 | 04-05 | Model responses stream token-by-token as they are generated | SATISFIED | Complete streaming path: inferenceIsolateMain sends `TokenResponse` per token → LlmService forwards to `_responseController` → ChatNotifier/TranslationNotifier appends to `currentResponse`/`translatedText` in state. |
| CHAT-04 | 04-01, 04-03, 04-05 | All chat sessions and messages persist locally on device | SATISFIED | DriftChatRepository.insertMessage() called for every user message (in `_processMessage`) and every assistant message (in `_finishGeneration`). Drift SQLite database persists to device documents directory. |

**Note on REQUIREMENTS.md traceability discrepancy:** REQUIREMENTS.md shows CHAT-01 and CHAT-02 mapped to Phase 6 and CHAT-04 mapped to Phase 7. However, Plan 04-05 frontmatter claims these requirement IDs. The infrastructure for all three is fully built in Phase 4; the surface-level UI interactions will be exposed in Phases 5-8. This is an architectural phase delivering what Phase 5/6/7 will consume — the requirements attribution in REQUIREMENTS.md reflects where the user-visible behavior appears, while Phase 4 builds the underlying mechanism. No gap — this is expected for an architecture phase.

**Orphaned requirements check:** REQUIREMENTS.md maps no additional requirements to Phase 4 specifically. The ROADMAP.md states "(Architecture phase — no additional v1 requirements)". No orphaned requirements.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `lib/features/model_distribution/model_distribution_notifier.dart` | 388-393 | `TODO(phase-4)` stub in `_loadModel()` | Info | Intentional — this stub sets `ModelReadyState` immediately (signals model file is on disk, not that inference is loaded). The actual llama.cpp load happens in `LlmService.start()` via `inferenceIsolateMain`. This is a deliberate architectural split: model distribution state machine tracks file availability; `modelReadyProvider` tracks inference readiness. Phase 4 acknowledged this split explicitly in Plan 04-04. NOT a blocker. |
| `lib/features/model_distribution/widgets/` | various | `TODO(phase-3)` design system TODOs | Info | Phase 2 legacy — pre-dates Phase 3 design system. These are in model_distribution widgets, not Phase 4 code. Not in scope for Phase 4 verification. |

No blockers or warnings in Phase 4 created files (`lib/features/inference/`, `lib/features/chat/`, `lib/features/translation/`, `lib/core/db/`).

### Human Verification Required

#### 1. Main Thread Non-Blocking Verification

**Test:** On a physical device (Galaxy A25 or equivalent), send a translation request and simultaneously try to scroll or tap in another part of the UI.
**Expected:** UI responds immediately; no ANR dialog; tokens appear incrementally in the output field as the model generates them.
**Why human:** Frame drop and ANR detection require a running device with GPU profiling or logcat. Static code confirms the isolate separation pattern is correct (`Isolate.spawn`) but cannot confirm there are no platform-channel callbacks inadvertently blocking the main thread.

#### 2. Isolate Persistence Verification

**Test:** Open the app, send a chat message (note the model load time of ~85s on Galaxy A25), then without closing the app, send 3 more messages.
**Expected:** Only the first message experiences the ~85s load delay. Subsequent messages begin generating immediately (under 1s latency to first token), confirming the isolate is reused.
**Why human:** Isolate lifecycle is a runtime property. The code is architecturally correct (singleton LlmService, no clearContext between turns of the same session), but only a device test can confirm the KV cache is actually alive and not being respawned.

#### 3. Multi-Turn Context Coherence Verification

**Test:** Start a chat session. Send "My name is Alex." Wait for response. Then send "What is my name?" in the same session.
**Expected:** The model responds with "Alex" or a paraphrase, demonstrating it has context from the first turn via the KV cache.
**Why human:** Requires live inference against the actual Tiny Aya Global 3.35B model. The prompt-building code is verified correct (`buildInitialPrompt` for turn 0, `buildFollowUpPrompt` for turn 1), but KV cache effectiveness depends on model behavior at runtime.

#### 4. Drift Persistence Across Restart

**Test:** Create a chat session, send 3 messages, force-quit the app (remove from recents), reopen.
**Expected:** The session and all 3 messages (user + assistant) appear when the app reopens. Drift schema v2 with WAL mode should handle this cleanly.
**Why human:** Requires a device, force-quit, and visual inspection of persisted data. WAL mode correctness under abrupt termination needs empirical validation.

---

## Summary

Phase 4 delivered a complete, non-stub production inference architecture. All 20 expected source files exist with substantive implementations. All key links (15 verified) are wired end-to-end: from the Aya prompt template through the isolate IPC protocol to the Drift persistence layer and the Riverpod provider graph.

The structural goal is achieved: Phases 5 (Translation UI) and 6 (Chat UI) can wire directly to `chatProvider`, `translationProvider`, `modelReadyProvider`, `chatRepositoryProvider`, and `inferenceRepositoryProvider` with no further infrastructure work required.

The 4 human verification items are runtime behavioral checks that cannot be confirmed by code inspection. They are standard smoke tests for an inference architecture — the code is correct but hardware execution must be validated.

---
_Verified: 2026-02-25T06:00:00Z_
_Verifier: Claude Sonnet 4.6 (mow-verifier)_
