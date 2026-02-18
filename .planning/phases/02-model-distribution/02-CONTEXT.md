# Phase 2: Model Distribution - Context

**Gathered:** 2026-02-19
**Status:** Ready for planning

<domain>
## Phase Boundary

First-launch download flow that gets the Cohere Tiny Aya Global Q4_K_M GGUF (~2.14 GB) onto the device with progress, resume, Wi-Fi gate, and SHA-256 integrity check. After download, the model loads in background and the app transitions to ready state. This phase covers the download infrastructure and UX — not the inference pipeline (Phase 4) or the app shell/design system (Phase 3).

</domain>

<decisions>
## Implementation Decisions

### Download screen experience
- Minimal, clean download screen — not an onboarding carousel
- BittyBot logo (graphic only, not app name text) centered above download area
- Small explanatory text below logo describing what's being downloaded (e.g., "Downloading language model for offline use")
- Progress bar in forest green theme (NOTE: exact color values are a TODO — Phase 3 defines the design system in parallel; use a placeholder that's easy to swap)
- Below progress bar in small font, centered: transfer speed (bits/sec) and estimated time remaining (ETA)
- File size shown (total and downloaded amount)
- No cancel button — user can background or kill the app to stop
- Normal screen sleep behavior — don't keep screen awake during download
- Brief "Preparing download..." state with spinner while connectivity and storage are checked before download begins

### Cellular data handling
- On cellular connection: show dialog warning with file size ("This download is ~2.14 GB. Continue on cellular?") with proceed/wait options
- On Wi-Fi: start automatically after pre-flight checks

### Interruption & resume UX
- On reopen after interrupted download: show resume confirmation prompt, not auto-resume
- Resume prompt includes a short sentence explaining the app needs this download to function ("BittyBot needs this language model to translate and chat offline")
- Progress bar on resume shows full journey (starts at e.g. 60% where it left off, not reset to 0%)
- Pre-flight storage check before starting download — if insufficient space, show clear error with exact amount needed (e.g., "Need X GB free, you have Y GB")
- Persistent system notification with progress bar when app is backgrounded during download
- Notify on completion so user knows to come back
- After download completes, show brief "Verifying download..." state before transitioning

### Post-download transition
- After verification, transition to main app screen (don't stay on download screen)
- Main app shows with text input disabled and loading indicator + text while model loads into memory
- Same loading state used on every subsequent app launch (model already downloaded but needs to load)
- On subsequent launches: straight to main screen, no splash — greyscale logo + disabled input + loading text while model loads
- When model finishes loading: text input enables, BittyBot logo transitions from greyscale/dimmed version to full color version (user will supply both asset versions)
- RAM check before model load: if device may not have enough memory, warn honestly ("Performance may be poor or the app may not function at all on this device") but allow the user to proceed

### Repeated failure handling
- Claude's discretion on error escalation after repeated download failures (e.g., troubleshooting hints after 3+ failures)

### Claude's Discretion
- Exact error escalation strategy for repeated download failures
- Progress notification styling on Android vs iOS
- "Preparing download..." spinner implementation
- Verification progress indicator timing

</decisions>

<specifics>
## Specific Ideas

- The greyscale-to-color logo transition is the "ready" signal — no toast or banner needed
- User will supply two versions of the BittyBot logo (greyscale/dimmed and full color)
- The loading state (greyscale logo + disabled input + loading text) must work for both first-launch-after-download AND every subsequent app launch — it's the universal "model not ready yet" state
- Forest green color values are a TODO pending Phase 3's design system — use an easily swappable placeholder

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 02-model-distribution*
*Context gathered: 2026-02-19*
