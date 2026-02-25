---
phase: 04-core-inference-architecture
plan: "05"
subsystem: chat, translation, inference
tags: [riverpod, chat-notifier, translation-notifier, streaming, kv-cache, request-queue, drift, prompt-builder]

# Dependency graph
requires:
  - phase: 04-core-inference-architecture
    plan: "04"
    provides: chatRepositoryProvider, inferenceRepositoryProvider, modelReadyProvider
  - phase: 04-core-inference-architecture
    plan: "03"
    provides: ChatRepository interface, DriftChatRepository, ChatSession, ChatMessage domain types
  - phase: 04-core-inference-architecture
    plan: "02"
    provides: LlmService, PromptBuilder, InferenceRepository interface, InferenceMessage types

provides:
  - chatNotifierProvider (auto-dispose Notifier<ChatState>): multi-turn chat orchestration
  - translationNotifierProvider (keepAlive Notifier<TranslationState>): translation orchestration

affects:
  - 05-translation-ui (TranslationNotifier — consume translationNotifierProvider)
  - 06-chat-ui (ChatNotifier — consume chatNotifierProvider; watchAllSessions for drawer)

# Tech tracking
tech-stack:
  added: []  # No new packages — dart:collection Queue used from SDK
  patterns:
    - Auto-dispose ChatNotifier: DB is source of truth; state reloaded from DB per screen entry
    - keepAlive TranslationNotifier: language pair persists across navigation (TRNS-05)
    - Request queue via Queue<String>: messages/translations queued behind active generation; auto-dequeued on DoneResponse
    - Lazy stream subscription: _setupResponseListenerIfNeeded() registers once; persists for notifier lifetime
    - Incremental KV cache prompting: _turnCount gate — buildInitialPrompt for turn 0, buildFollowUpPrompt for turns 1+
    - Context-full detection: estimateTokenCount >= 90% of nCtx=2048 signals isContextFull; UI handles user action
    - Cooperative stop: inferenceRepo.stop(requestId) -> DoneResponse(stopped:true) -> isTruncated persisted to DB
    - Session title auto-derived from first user message (substring 0..50) on DoneResponse

key-files:
  created:
    - lib/features/chat/application/chat_notifier.dart
    - lib/features/chat/application/chat_notifier.g.dart
    - lib/features/translation/application/translation_notifier.dart
    - lib/features/translation/application/translation_notifier.g.dart

key-decisions:
  - "ChatNotifier is auto-dispose (@riverpod): DB is source of truth; state reloads fresh per screen entry; no keepAlive needed"
  - "TranslationNotifier is keepAlive: language pair selection (sourceLanguage/targetLanguage) persists across navigation per TRNS-05"
  - "Queue<String> for request pending: simplest FIFO that matches locked decision — messages queue behind active generation"
  - "Language pair change resets session + clearContext: terminology consistency requires fresh KV cache per pair"
  - "startNewSessionWithCarryForward copies last 3 exchanges (up to 6 messages) to new DB session and fresh KV cache"
  - "Session title auto-derived on first DoneResponse if session.title == null (avoids extra DB write on every token)"

# Metrics
duration: ~5min
completed: 2026-02-25
---

# Phase 4 Plan 05: ChatNotifier and TranslationNotifier Summary

**ChatNotifier (auto-dispose) and TranslationNotifier (keepAlive) Riverpod state managers with request queuing, KV-cache-aware incremental prompting, cooperative stop, and Drift DB persistence — the complete UI-to-inference bridge for Phases 5 and 6.**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-02-25T04:59:01Z
- **Completed:** 2026-02-25T05:03:26Z
- **Tasks:** 2
- **Files created:** 4 (2 hand-written, 2 codegen)

## Accomplishments

- Created `ChatNotifier` with `ChatState` (8 fields), managing multi-turn conversation: `loadSession`, `startNewSession`, `sendMessage` (with FIFO queue), `stopGeneration`, `startNewSessionWithCarryForward` (last 3 exchanges carried to new session). First message uses `buildInitialPrompt` with chat system prompt; follow-ups use `buildFollowUpPrompt` (KV cache incremental). nPredict=512. All messages persisted to Drift via `chatRepositoryProvider`.
- Created `TranslationNotifier` with `TranslationState` (10 fields), managing translation requests: `translate` (with FIFO queue), `stopTranslation`, `setSourceLanguage`, `setTargetLanguage`, `swapLanguages` (each resets session + clears KV cache). First translation uses `buildTranslationPrompt`; subsequent ones use `buildFollowUpTranslationPrompt` for terminology consistency within the same language pair. nPredict=128. keepAlive preserves language pair across navigation.
- Both notifiers: stream tokens to state on `TokenResponse`, persist assistant message on `DoneResponse`, persist partial output as `isTruncated=true` on stop or error, detect context-full at 90% of nCtx=2048.

## Task Commits

1. **Task 1: ChatNotifier** — `52c53a7` (feat)
2. **Task 2: TranslationNotifier** — `4cbfe6a` (feat)

## Files Created

- `lib/features/chat/application/chat_notifier.dart` — ChatState + ChatNotifier (@riverpod auto-dispose); 460 lines
- `lib/features/chat/application/chat_notifier.g.dart` — Riverpod codegen output for ChatNotifier
- `lib/features/translation/application/translation_notifier.dart` — TranslationState + TranslationNotifier (@Riverpod keepAlive); 400 lines
- `lib/features/translation/application/translation_notifier.g.dart` — Riverpod codegen output for TranslationNotifier

## Decisions Made

- **ChatNotifier is auto-dispose:** The DB is the source of truth for chat history. Each screen entry reloads the session and messages from DB via `loadSession()`. No in-memory keepAlive is needed — reconstructing state from DB is fast and avoids stale state bugs.
- **TranslationNotifier is keepAlive:** The language pair (sourceLanguage/targetLanguage) must survive navigation so users don't have to re-select it each time they visit the translation screen. This satisfies the TRNS-05 requirement.
- **Queue<String> for request queueing:** `dart:collection Queue` is a simple FIFO that directly implements the "queue behind active generation" locked decision without additional dependencies.
- **Language pair change resets session + clearContext:** Changing the language pair after translations have accumulated context would produce nonsensical follow-ups. Resetting ensures the next translation gets a clean `buildTranslationPrompt` with the correct target language.
- **startNewSessionWithCarryForward copies ≤6 messages:** The last 3 user-assistant exchange pairs are preserved in the new DB session and will be displayed in the UI as context. The KV cache starts fresh — the model doesn't have the carried-forward context in its cache (seeding all prior messages would overflow nCtx=2048 for long conversations).
- **Session title auto-derived from first user message:** Title derivation is deferred to the first `DoneResponse` to avoid a redundant DB write during setup. The substring `(0, min(50, length))` gives a readable drawer label without requiring explicit user input.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Unused import in translation_notifier.dart**
- **Found during:** Task 2 dart analyze
- **Issue:** `import '../../chat/domain/chat_message.dart'` was included in the initial draft but `ChatMessage` is not directly referenced in `TranslationNotifier` (messages are persisted and not held in `TranslationState`)
- **Fix:** Removed the unused import
- **Files modified:** `lib/features/translation/application/translation_notifier.dart`
- **Commit:** Fixed inline before Task 2 commit (4cbfe6a)

## Self-Check: PASSED

- FOUND: lib/features/chat/application/chat_notifier.dart
- FOUND: lib/features/chat/application/chat_notifier.g.dart
- FOUND: lib/features/translation/application/translation_notifier.dart
- FOUND: lib/features/translation/application/translation_notifier.g.dart
- FOUND commit: 52c53a7 (Task 1)
- FOUND commit: 4cbfe6a (Task 2)

---
*Phase: 04-core-inference-architecture*
*Completed: 2026-02-25*
