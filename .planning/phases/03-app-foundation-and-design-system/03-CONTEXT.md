# Phase 3: App Foundation and Design System - Context

**Gathered:** 2026-02-19
**Status:** Ready for planning

<domain>
## Phase Boundary

The app shell exists with correct dark theme, Cohere-inspired green palette, localized UI strings, accessible tap targets, legible typography, and error message patterns that all subsequent screens will inherit. No functional screens (chat, translation) — just the foundation they plug into.

</domain>

<decisions>
## Implementation Decisions

### Visual identity & palette
- Background: very dark green (faded, near-black green) — inspired by Aya demo, not an exact replica
- Input fields and user message bubbles: regular forest green
- Primary buttons and interactive accents: forest green
- Small highlights, borders, logo accents: lime/yellow-green
- Text: white throughout
- Surfaces must respect WCAG accessibility contrast ratios (white text on forest green inputs needs careful checking)
- Reference: Aya demo screenshot — dark green background, lime border, forest green input field, white text

### Typography & script support
- Primary font: Lato (Google Fonts)
- Fallback: system fonts for scripts Lato doesn't cover (Arabic, Thai, CJK, etc.)
- Full RTL layout mirroring for Arabic, Hebrew, and other RTL locales (navigation, buttons, layout all flip)
- Type scale: understated and clean — content-first, minimal headings (ChatGPT/Claude mobile style)
- Respect system font size preferences fully (dynamic type on iOS, font scale on Android) — no cap
- Body text minimum 16sp baseline

### Localization scope
- Device locale auto-detection as default, with in-app language override in settings
- Fully localized date/time, number formatting following user's locale conventions
- Error message tone toggle: friendly & casual by default ("Hmm, something went wrong"), clear & direct as a setting option ("Translation failed. Check your input.")

### Error message design
- Dedicated loading/onboarding screen when model is not yet loaded (not the main UI with disabled inputs)
- Error message tone: friendly & casual by default, with a settings toggle for clear & direct mode

### Claude's Discretion
- Number of UI languages to translate into (practical subset vs. all 70+)
- Fallback strategy for partially translated languages
- Error presentation style (inline banners vs. snackbars vs. context-dependent)
- Partial output handling on inference failure (show vs. discard)
- Exact color hex values within the described palette
- Loading skeleton and animation design
- Exact spacing and layout metrics

</decisions>

<specifics>
## Specific Ideas

- "I want the background to be a faded very very dark green, lighter forest green/lighter yellow-green accents, but white text"
- General chat app interface pattern (ChatGPT/Claude/Gemini/DeepSeek mobile) as the structural reference — not replicating Aya UI, just the palette
- Aya demo screenshot provided as the palette reference (dark green bg, lime green border, forest green input, white text)
- Error tone toggle is a deliberate personalization feature — the user wants it as a setting, not just a design choice

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 03-app-foundation-and-design-system*
*Context gathered: 2026-02-19*
