# Roadmap: BittyBot

## Overview

BittyBot delivers a fully offline multilingual translation and chat app for travelers, powered by Cohere Tiny Aya Global (3.35B) running on-device via llama.cpp. The build sequence is non-negotiable: first validate that the Cohere2 architecture is recognized by the Flutter inference binding (Phase 1, spike), then establish model distribution and the production infrastructure (Phases 2-4), then build the user-facing surfaces in order of increasing complexity (Phases 5-8), then add the optional online feature (Phase 9). Every phase delivers a verifiable capability. Nothing requires internet after the first model download.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Inference Spike** - Validate Cohere2/llama.cpp on real hardware; confirm the stack before writing production code
- [ ] **Phase 2: Model Distribution** - First-launch download flow with progress, resume, Wi-Fi gate, and SHA-256 integrity check
- [ ] **Phase 3: App Foundation and Design System** - Flutter project scaffold, dark theme, Cohere green palette, accessibility baseline, localization
- [ ] **Phase 4: Core Inference Architecture** - Long-lived Inference Isolate, LLM Service, repository layer, Riverpod notifiers, Drift schema
- [ ] **Phase 5: Translation UI** - Translation screen with language selector (70+ languages), swap, copy, streaming output, language persistence
- [ ] **Phase 6: Chat UI** - Multi-turn chat screen with token streaming, optimistic display, stop button, typing indicator
- [ ] **Phase 7: Chat History and Sessions** - Session drawer, session persistence, session management
- [ ] **Phase 8: Chat Settings and Maintenance** - Auto-clear toggle, clear all history with confirmation, settings persistence
- [ ] **Phase 9: Web Search** - Settings toggle for web mode, URL paste and translate/summarize via live fetch

## Phase Details

### Phase 1: Inference Spike
**Goal**: Cohere2 architecture compatibility with the chosen Flutter llama.cpp binding is confirmed on real hardware, producing a working proof-of-concept that streams multilingual tokens, and the Flutter project environment is bootstrapped with correct platform toolchain settings
**Depends on**: Nothing (first phase)
**Requirements**: MODL-06
**Success Criteria** (what must be TRUE):
  1. Loading the Tiny Aya Global Q4_K_M GGUF into the chosen Flutter plugin produces no architecture error and generates coherent text output
  2. A translation prompt in at least three language families (Latin, Arabic, Thai) returns plausible translated output in the target language
  3. Tokens stream back to Dart one at a time during generation (not buffered until completion)
  4. The spike runs successfully on a physical iOS device (not Simulator) with static library linking confirmed
  5. Android build uses NDK r28+ and the resulting `.so` files pass 16 KB page-alignment check
**Plans**: 5 plans

Plans:
- [ ] 01-01-PLAN.md -- Flutter project scaffold, platform toolchain (NDK r28+, iOS physical device), and 70+ language test corpus
- [ ] 01-02-PLAN.md -- LLM-as-judge tooling (Claude Sonnet 4.6 quick check, Gemini Flash full suite, report generator)
- [ ] 01-03-PLAN.md -- Model loading and token streaming integration tests (TDD)
- [ ] 01-04-PLAN.md -- Multilingual translation integration tests for 70+ languages (TDD)
- [ ] 01-05-PLAN.md -- On-device hardware verification (Android + iOS) and final spike report

### Phase 2: Model Distribution
**Goal**: Users get through first launch with a clear, resumable download flow that installs the model and verifies its integrity, so the app is ready for offline use after one connected session
**Depends on**: Phase 1
**Requirements**: MODL-01, MODL-02, MODL-03, MODL-04, MODL-05
**Success Criteria** (what must be TRUE):
  1. On first launch the app shows a download screen with a progress indicator and the file size (~2.14 GB) before any download begins
  2. If the app is backgrounded or the download is interrupted, progress resumes from where it stopped on next launch without restarting the full download
  3. If the device is on cellular, the app presents an explicit warning with the file size before offering to proceed
  4. On every subsequent launch the app verifies the model file via SHA-256 before loading; a corrupted or missing file triggers re-download
  5. After download completes, the model loads in the background and the chat input is disabled with a visible loading indicator until inference is ready
**Plans**: TBD

### Phase 3: App Foundation and Design System
**Goal**: The app shell exists with correct dark theme, Cohere-inspired green palette, localized UI strings, accessible tap targets, legible typography, and error message patterns that all subsequent screens will inherit
**Depends on**: Phase 1
**Requirements**: UIUX-01, UIUX-02, UIUX-03, UIUX-04, UIUX-05, UIUX-06
**Success Criteria** (what must be TRUE):
  1. The app displays a dark background with forest green borders and lime/yellow-green accent colors matching the Tiny Aya demo aesthetic, on both iOS and Android
  2. When the device locale is set to a supported language, all app UI labels, buttons, and messages appear in that language
  3. Every interactive element (button, tap target) measures at least 48x48dp on Android and 44pt on iOS when inspected with the accessibility inspector
  4. Body text renders at minimum 16sp and remains legible on both a bright outdoor screen and a dark environment
  5. When the model is not loaded, the input is too long, or inference fails, a clear human-readable error message appears (not a stack trace or empty state)
**Plans**: 5 plans

Plans:
- [ ] 03-01-PLAN.md -- Flutter project bootstrap, dependencies, Lato fonts, Drift DB stub
- [ ] 03-02-PLAN.md -- Dark theme system (WCAG-validated palette, Lato typography, tap targets)
- [ ] 03-03-PLAN.md -- Localization (10 language ARB files, codegen)
- [ ] 03-04-PLAN.md -- Settings persistence (locale override, error tone) and error message resolver
- [ ] 03-05-PLAN.md -- App shell wiring, startup widget, unit tests, visual verification

### Phase 4: Core Inference Architecture
**Goal**: The production inference layer is built — long-lived Dart Isolate owning the llama.cpp context, LLM Service managing isolate lifecycle, InferenceRepository interface, ChatNotifier and TranslationNotifier, PromptBuilder with Aya chat template, and Drift DB schema — so all UI phases can wire up to a stable, non-blocking inference pipeline
**Depends on**: Phase 2, Phase 3
**Requirements**: (Architecture phase — no additional v1 requirements; delivers the infrastructure that makes Phases 5-8 possible)
**Success Criteria** (what must be TRUE):
  1. A translation request sent from the UI reaches the Isolate, runs inference, and streams tokens back to the UI without the Flutter main thread freezing or dropping frames
  2. The Inference Isolate starts once at app launch and persists for the session; it is not respawned per request
  3. Sending a multi-turn conversation through ChatNotifier preserves message history in the Aya chat template format and produces contextually coherent follow-up responses
  4. Chat sessions and messages are stored in Drift SQLite and survive app restart
**Plans**: TBD

### Phase 5: Translation UI
**Goal**: Users can translate text into any of the 70+ supported languages using a clean, fast interface that remembers their language pair and lets them copy the result with a single tap
**Depends on**: Phase 4
**Requirements**: TRNS-01, TRNS-02, TRNS-03, TRNS-04, TRNS-05
**Success Criteria** (what must be TRUE):
  1. A user can type or paste text into the source field and receive a streaming translation in the target language field without leaving the translation screen
  2. The language selector lists all 70+ Tiny Aya supported languages (including low-resource languages such as Swahili, Amharic, and Malay) and the user can select source and target independently
  3. Tapping the swap button exchanges source and target languages and re-runs translation on the current input
  4. Tapping the copy icon on the translated output writes it to the clipboard; the icon gives visible feedback (brief check mark or color change)
  5. After the app is closed and reopened, the language pair from the previous session is pre-selected
**Plans**: TBD

### Phase 6: Chat UI
**Goal**: Users can have a fluid multi-turn conversation with the model in a chat interface that streams tokens as they are generated and lets them stop generation mid-response
**Depends on**: Phase 4
**Requirements**: CHAT-01, CHAT-02
**Success Criteria** (what must be TRUE):
  1. A user can type a message, send it, and see their message appear immediately in the chat thread while the model begins generating a reply
  2. The model's response text appears word-by-word (token-by-token) as it is generated, not as a single block at the end
  3. A stop button is visible during generation; tapping it halts token generation and displays however much text was produced
  4. The chat interface handles a conversation of at least 10 turns without UI slowdown or input being disabled
**Plans**: TBD

### Phase 7: Chat History and Sessions
**Goal**: Users can access all previous chat sessions from a slide-out drawer and all messages persist locally so nothing is lost between app launches
**Depends on**: Phase 6
**Requirements**: CHAT-03, CHAT-04
**Success Criteria** (what must be TRUE):
  1. Swiping from the left edge (or tapping a menu icon) opens a drawer listing all previous chat sessions by title or creation date
  2. Tapping a session in the drawer loads that session's full message history into the chat view
  3. All messages from all sessions are present after the app is force-quit and reopened
  4. A user can start a new chat session from the drawer and the previous session remains accessible
**Plans**: TBD

### Phase 8: Chat Settings and Maintenance
**Goal**: Users can configure automatic chat history expiry and clear all history manually, giving them control over local storage without losing access to recent conversations by accident
**Depends on**: Phase 7
**Requirements**: CHAT-05, CHAT-06
**Success Criteria** (what must be TRUE):
  1. In settings, the user can toggle auto-clear on or off and select a time period (e.g., 7 days, 30 days); sessions older than the configured period are automatically deleted on next launch
  2. Tapping "Clear all history" shows a confirmation dialog with the text "Are you sure?" before deleting any data
  3. After confirming the clear, all sessions and messages are removed and the chat drawer shows an empty state
  4. The auto-clear setting persists across app restarts
**Plans**: TBD

### Phase 9: Web Search
**Goal**: Users who are online can paste a URL into the chat and get the page content translated or summarized by the model, making the app useful for reading foreign-language websites while traveling with connectivity
**Depends on**: Phase 6
**Requirements**: WEBS-01, WEBS-02
**Success Criteria** (what must be TRUE):
  1. A settings toggle on the text entry bar switches between normal chat mode and web search mode, with a visible mode indicator
  2. In web search mode, pasting a URL and sending fetches the page content and passes it to the model, which returns a translated or summarized version
  3. In web search mode, if the device has no network connection, the app shows a clear "No internet connection" message rather than silently failing
  4. Switching off web search mode returns the interface to normal chat behavior without requiring an app restart
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9

Note: Phases 2 and 3 can be parallelized (no dependency between them). Phase 4 requires both Phases 2 and 3 to be complete.

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Inference Spike | 0/5 | Planned | - |
| 2. Model Distribution | 0/TBD | Not started | - |
| 3. App Foundation and Design System | 0/5 | Planned | - |
| 4. Core Inference Architecture | 0/TBD | Not started | - |
| 5. Translation UI | 0/TBD | Not started | - |
| 6. Chat UI | 0/TBD | Not started | - |
| 7. Chat History and Sessions | 0/TBD | Not started | - |
| 8. Chat Settings and Maintenance | 0/TBD | Not started | - |
| 9. Web Search | 0/TBD | Not started | - |
