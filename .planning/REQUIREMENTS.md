# Requirements: BittyBot

**Defined:** 2026-02-19
**Core Value:** Translation and conversation must work with zero connectivity

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Model Infrastructure

- [ ] **MODL-01**: App downloads Tiny Aya Global Q4_K_M GGUF (~2.14GB) on first launch with progress indicator
- [ ] **MODL-02**: Download resumes automatically if interrupted or app is backgrounded
- [ ] **MODL-03**: If user is not on Wi-Fi, app offers option to download on cellular with explicit file size warning (~2.14GB)
- [ ] **MODL-04**: App verifies model integrity via SHA-256 hash on each launch before loading
- [ ] **MODL-05**: Model loads in background with loading indicator; chat input disabled until ready
- [ ] **MODL-06**: All inference runs on-device via llama.cpp with zero network dependency after model download

### Translation

- [ ] **TRNS-01**: User can type or paste text and get a translation to their selected target language
- [ ] **TRNS-02**: User can select source and target languages from all 70+ supported languages
- [ ] **TRNS-03**: User can swap source and target languages with a single tap
- [ ] **TRNS-04**: User can copy translated text to clipboard with a single tap
- [ ] **TRNS-05**: App remembers last-used language pair across sessions

### Chat

- [ ] **CHAT-01**: User can have multi-turn conversations with the model (ChatGPT/Claude-style interface)
- [ ] **CHAT-02**: Model responses stream token-by-token as they are generated (not buffered)
- [ ] **CHAT-03**: User can access previous chat sessions via slide-out drawer
- [ ] **CHAT-04**: All chat sessions and messages persist locally on device
- [ ] **CHAT-05**: User can toggle auto-clear chat history with configurable time period in settings
- [ ] **CHAT-06**: User can clear all chat history via button with confirmation dialog ("Are you sure?")

### Online Features

- [ ] **WEBS-01**: Settings button on text entry bar toggles web search mode on/off
- [ ] **WEBS-02**: In web search mode, user can paste a URL and get the page content translated/summarized by the model

### UI/UX

- [x] **UIUX-01**: Dark theme with Cohere-inspired green palette (forest green borders, lime/yellow-green accents on dark background)
- [x] **UIUX-02**: Clean, minimal visual style inspired by Tiny Aya demo aesthetic
- [x] **UIUX-03**: App UI language matches device locale
- [x] **UIUX-04**: Tap targets are minimum 48x48dp (Android) / 44pt (iOS)
- [x] **UIUX-05**: Body text is minimum 16sp for legibility in travel scenarios
- [x] **UIUX-06**: Clear error messages when model is not loaded, input is too long, or inference fails

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Camera

- **CAMR-01**: User can snap a photo and get OCR text extracted and translated
- **CAMR-02**: Camera viewfinder shows live translation overlay

### Voice

- **VOIC-01**: User can tap microphone to dictate input via platform speech-to-text
- **VOIC-02**: User can listen to translated text via platform text-to-speech

### Enhanced Features

- **ENHC-01**: User can star/save translations to a phrasebook for quick access
- **ENHC-02**: User can see transliteration (romanization) for non-Latin script translations
- **ENHC-03**: Two-person conversation mode with split-screen interface

## Out of Scope

| Feature | Reason |
|---------|--------|
| Bundling model in app binary | App store size limits (200MB iOS cellular, 150MB Android AAB base) make this infeasible |
| User accounts / cloud sync | Contradicts offline-first and privacy positioning; no backend needed |
| Commercial distribution | CC-BY-NC model license; personal/open-source project |
| Multiple model support | Single model (Tiny Aya Global) keeps scope manageable |
| In-app ads or subscription | Privacy-focused, open-source; no monetization |
| Language learning features | Travelers need communication, not courses |
| Real-time voice translation | High complexity; text-only for v1 |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| MODL-01 | Phase 2 | Pending |
| MODL-02 | Phase 2 | Pending |
| MODL-03 | Phase 2 | Pending |
| MODL-04 | Phase 2 | Pending |
| MODL-05 | Phase 2 | Pending |
| MODL-06 | Phase 1 | Pending |
| TRNS-01 | Phase 5 | Pending |
| TRNS-02 | Phase 5 | Pending |
| TRNS-03 | Phase 5 | Pending |
| TRNS-04 | Phase 5 | Pending |
| TRNS-05 | Phase 5 | Pending |
| CHAT-01 | Phase 6 | Pending |
| CHAT-02 | Phase 6 | Pending |
| CHAT-03 | Phase 7 | Pending |
| CHAT-04 | Phase 7 | Pending |
| CHAT-05 | Phase 8 | Pending |
| CHAT-06 | Phase 8 | Pending |
| WEBS-01 | Phase 9 | Pending |
| WEBS-02 | Phase 9 | Pending |
| UIUX-01 | Phase 3 | Complete |
| UIUX-02 | Phase 3 | Complete |
| UIUX-03 | Phase 3 | Complete |
| UIUX-04 | Phase 3 | Complete |
| UIUX-05 | Phase 3 | Complete |
| UIUX-06 | Phase 3 | Complete |

**Coverage:**
- v1 requirements: 25 total
- Mapped to phases: 25
- Unmapped: 0

---
*Requirements defined: 2026-02-19*
*Last updated: 2026-02-19 — phase mappings added during roadmap creation*
