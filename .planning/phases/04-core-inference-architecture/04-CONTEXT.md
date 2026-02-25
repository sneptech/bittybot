# Phase 4: Core Inference Architecture - Context

**Gathered:** 2026-02-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Build the production inference pipeline: long-lived Dart Isolate owning the llama.cpp context, LLM Service managing isolate lifecycle, InferenceRepository interface, ChatNotifier and TranslationNotifier, PromptBuilder with Aya chat template, and Drift DB schema. All downstream UI phases (5-9) wire into this layer.

</domain>

<decisions>
## Implementation Decisions

### System prompt & model persona
- **Translation screen:** System prompt instructs "translate and reply with only the translation, plus a brief note about formality/context when relevant." Concise output the user can copy-paste, with occasional one-liner like "(formal)" or "(colloquial)."
- **Chat screen:** Translator-first persona. System prompt anchors on translation and language help. Chat is for follow-up questions about translations, "how do I say X", etc.
- **Soft guardrails:** System prompt gently steers toward translation/language. If asked about other topics, model should mention translation is its strength — not refuse outright. Prompt should be short enough for 3.35B to follow reliably.
- **System prompt language:** Always English for now. Aya handles multilingual output well from English instructions. Revisit if users in non-English locales get accidental English responses.
- **Two system prompts total:** One for translation mode, one for chat mode. Both share the translator-first persona, differ in output style (translation-only vs conversational).

### Request lifecycle
- **Queueing:** New requests queue behind active generation. Finish current response, then auto-start next. User sees both complete.
- **Stop button:** Keeps partial output with a truncation indicator (e.g., "..." or subtle "stopped" badge) so user knows it's incomplete.
- **Processing indicator:** Pulsing BittyBot avatar while the model processes the prompt (1-3s on Galaxy A25). Disappears when first token arrives.

### Context window management
- **nCtx:** Start at 2048 tokens. Fixed value, not user-configurable. Tune via device memory profiling.
- **nPredict:** Different per mode. Translation: 128 tokens (concise). Chat: 512 tokens (room for longer replies).
- **nBatch:** 256 default. Internal toggle for 512 during development/testing — not exposed to users.
- **Context full behavior:** When context approaches the limit, prompt user to start a new session. Offer to carry forward the last 3 exchanges to the new session. Same behavior for both translation and chat screens.
- **Translation context:** Translations accumulate in context within a session (not independent one-shots). This enables terminology consistency across related translations within a session.
- **RAM awareness:** Profile memory usage per response on target devices. Set context limit conservatively — BittyBot must not monopolize device RAM.

### Startup & recovery
- **First launch:** Full Phase 2 download + load overlay (greyscale-to-color transition). Blocked until ready.
- **Subsequent launches:** Partial access — user can browse chat history and settings while model loads in background. Only input field is disabled until inference ready.
- **Crash recovery:** Toast/snackbar ("Inference interrupted") + user's input preserved for retry. Model auto-reloads in background.
- **Crash circuit breaker:** Auto-restart after crash, BUT track consecutive failure count. After repeated failures, stop retrying, surface error to user, and log the error. Wait for explicit user action.
- **Background kill recovery:** "Reloading model..." banner at top when foregrounded after OS killed the isolate. Input disabled until ready. Chat history intact from Drift DB.

### Claude's Discretion
- Isolate communication protocol (SendPort/ReceivePort vs stream-based)
- Riverpod provider structure and dependency graph
- Drift schema design (tables, indices, migration strategy)
- PromptBuilder implementation details
- Exact crash counter threshold for circuit breaker
- Loading state animations and transitions

</decisions>

<specifics>
## Specific Ideas

- System prompt should be very short and directive — 3.35B models ignore complex instructions. Something like: "You are a translator. You help people translate text and understand languages. If asked about other topics, mention that translation is your strength."
- Context management UX should feel like ChatGPT/DeepSeek — when context fills, offer new chat with optional carry-forward of recent exchanges.
- The `appStartupProvider` from Phase 3 already expects Phase 4 to add `await ref.watch(modelReadyProvider.future)`.
- Phase 3's `resolveErrorMessage()` pattern (exhaustive record switch) should be extended for inference errors.

</specifics>

<deferred>
## Deferred Ideas

- **Educational mode toggle** (translation + pronunciation guide) — Phase 5 Translation UI or settings. System prompt variant exists in todo: `.planning/todos/pending/2026-02-25-two-system-prompt-modes-translation-and-educational.md`
- **Localized system prompts** — Revisit if English system prompt causes quality issues for non-English locale users.
- **User-configurable nCtx** — Only if power users request it. Hidden advanced setting at most.

</deferred>

---

*Phase: 04-core-inference-architecture*
*Context gathered: 2026-02-25*
