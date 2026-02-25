# Phase 5: Translation UI - Context

**Gathered:** 2026-02-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Translation screen where users type/paste text and receive streaming translation into a selected target language. Chat-style bubble interface with language persistence, session management, and copy support. The model auto-detects the source language — only a target language selector is needed.

Note: Phase success criteria originally specified a swap button (source/target exchange). Per user decision, there is no source language selector, so the swap button does not apply. The model auto-detects input language.

</domain>

<decisions>
## Implementation Decisions

### Screen Layout
- **Chat-style interface**, not traditional two-panel Google Translate layout
- Input bar at the bottom of the screen (accounting for system controls/safe area)
- User taps input bar → keyboard appears
- User message appears as a right-aligned chat bubble
- Model translation appears as a left-aligned chat bubble below user's message
- Follow-up messages continue the thread downward (like ChatGPT)
- Separate screen from Chat UI (Phase 6) — not a mode toggle
- Send button (visible icon to right of input field) — enter/return inserts newlines
- Multi-line expandable input field — grows as user types paragraphs
- Soft character limit with warning when approaching model context limit
- User bubbles show text only (no language tag)
- Model response bubbles show translated text + small target language tag (useful when target changes mid-history)
- New session button in top bar, right side (+ or new-page icon) — starts fresh translation session, saves old to history
- Centered prompt text for empty state ("Type something to translate") — disappears on first message

### Language Selector
- **Target language only** — no source language selector (model auto-detects input language)
- Target language button in the top bar
- Tapping opens a **scrollable bottom sheet** with:
  - Search bar at top with text filtering
  - **3-column grid layout** — each entry is a button with flag icon + language name
  - All 70+ supported languages shown
  - Popular languages (top ~10 most spoken) pinned at top
  - Last-used language is default on app reopen
  - Rolling history of last 3 used languages (for quick access)
- Flag icons: most prominent country per language, but detect device locale for variant (e.g., device set to `es_CO` → Colombia flag for Spanish; fallback to Spain)
- Language names displayed in user's OS language (fallback to English)
- Search matches both localized name AND English name (e.g., typing "esp" or "span" both find Spanish/Español)

### Translation Trigger
- **Send button only** — no auto-translate while typing
- New messages queue behind active translation (FIFO) — no cancel-and-replace
- Changing target language starts a **fresh session** (old session saved to history) — aligns with Phase 4 TranslationNotifier's clearContext behavior

### Streaming & Feedback
- Animated pulsing dots (iMessage-style typing indicator) until first word arrives
- **Word-level batching** for space-delimited scripts (Latin, Cyrillic, Arabic, etc.) — buffer until space/word boundary, then display complete word
- **Token-by-token** for non-space-delimited scripts (CJK, Thai) — display each token immediately
- Stop button: send button transforms into stop icon during streaming — tapping halts generation, keeps partial output
- Errors displayed in the response bubble using Phase 3's error resolver (not toast/snackbar)

### Copy & Actions
- **Long-press menu** on translation bubbles for copy (and future share options) — no persistent copy icon on bubbles

### Persistence
- Translation bubbles persist in DB and reload on app launch (like chat sessions)
- Language pair (target language) persists across app restarts

### Claude's Discretion
- Navigation pattern between Translation and Chat screens (bottom nav, top tabs, etc.) — based on existing Phase 3 app shell
- Exact input bar styling and spacing
- Loading skeleton or transition animations
- Exact grid item sizing in language picker
- Error bubble styling details

</decisions>

<specifics>
## Specific Ideas

- "Much like ChatGPT chat interfaces" — the translation screen should feel like a messaging app, not a form
- Flag detection from device locale is best-effort — use most prominent country as fallback
- Input field should account for system controls (safe area insets) at the bottom

</specifics>

<deferred>
## Deferred Ideas

- Translation sessions in history drawer should have a distinct icon/theme to differentiate from chat sessions — Phase 7 (Chat History and Sessions)
- Auto-retranslate on language swap as a toggle in app settings — Phase 8 (Chat Settings and Maintenance)

</deferred>

---

*Phase: 05-translation-ui*
*Context gathered: 2026-02-25*
