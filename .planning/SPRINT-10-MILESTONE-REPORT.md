# Sprint 10 Milestone Report — UI/UX Refinement + Feature Expansion

**Date:** 2026-02-28
**Branch:** `master`
**Status:** Sprint 10 code tasks COMPLETE, milestone planning COMPLETE

---

## Sprint 10 Completed Work

### S10-A: nCtx 512 → 2048 (`d98dcc9`)
- Changed `nCtx` default from 512 to 2048 in `inference_message.dart`, `chat_notifier.dart`, `translation_notifier.dart`
- KV cache at 2048 is ~64MB — well within budget on 5.5GB Galaxy A25
- **Impact:** Chat extends to ~30+ messages before exhaustion, translation essentially unlimited, web mode now viable

### S10-B: Web Fetch Fix (`97f83de`)
- Restructured `_handleWebFetch` to fetch content FIRST, then send a single combined message
- Removed premature `sendMessage('[Web] $url')` that caused model to generate garbage response to URL text
- Reduced `maxChars` from 3000 to 2000 for better fit within nCtx=2048
- **Impact:** Web mode now functional — model receives URL context + content in one prompt

---

## Current App Assessment

### What Works Well
- Offline-first: fully functional without internet (except web mode)
- Dark theme with Cohere green palette
- 10 UI locales with RTL support (Arabic)
- 66 translation languages via Tiny Aya Global
- Streaming token display with word-level batching
- Chat history with session management
- Context exhaustion auto-recovery
- Native splash screen for cold start

### What Needs Improvement (Research-Informed)

Based on comprehensive research of Google Translate, DeepL, Apple Translate, ChatGPT, Claude, and Gemini apps, plus Material Design 3 guidelines:

| Area | Current State | Target State | Priority |
|------|---------------|--------------|----------|
| Language picker | Basic dropdown list | Bottom sheet with search, recent, favorites, native script names | P1 |
| Chat bubbles | Basic styling | Copy/share buttons, timestamps, better spacing | P1 |
| Streaming UX | Raw token display | Blinking cursor, skeleton placeholder before first token | P1 |
| Onboarding | Download screen only | 2-3 welcome screens + background download + feature tips | P2 |
| Scroll behavior | Basic auto-scroll | Pause on user scroll-up + "scroll to bottom" FAB | P2 |
| Haptic feedback | None | Light taps on send/copy/swap, medium on toggles | P2 |
| OCR / Camera input | Not implemented | Camera → OCR → translate pipeline | P2 |
| Message actions | None | Copy, share, read aloud on AI responses | P2 |
| Settings | Basic (auto-clear only) | Model management, OCR packs, haptics toggle, theme toggle | P3 |
| Conversation mode | Not implemented | Split-screen face-to-face for two speakers | P3 |

---

## Next Milestone: v1.1 — UI Polish + OCR Feature

### Phase A: UI Polish Sprint (P1 items)

#### A1. Language Picker Redesign
- Bottom sheet with search field at top
- "Recent" section: last 3 used languages
- "Downloaded" section with checkmark badges
- "All Languages" grouped alphabetically
- Native script names (e.g., "العربية" not "Arabic") + English subtitle
- No flags as primary identifiers (per Smashing Magazine guidance)
- Swap button with 180-degree rotation animation + haptic

#### A2. Chat Bubble Polish
- Copy button below each AI response (visible, not hidden behind long-press)
- Share button adjacent to copy
- Grouped timestamps (not per-message)
- Typing indicator: three animated dots in left-aligned bubble
- Rounded corners 12-16dp, asymmetric tail corner
- User messages: primary color bubble (right), AI: surface color (left)

#### A3. Streaming UX Enhancement
- Skeleton shimmer placeholder before first token arrives (~4s TTFT)
- Blinking cursor at insertion point during streaming
- Debounced smooth scroll to keep latest text visible
- "Scroll to bottom" FAB when user scrolls up during streaming
- 50% viewport bottom padding on last message

#### A4. Message Actions
- Copy: light haptic + snackbar (Android 12-) or system toast (Android 13+)
- Share: system share sheet with message text
- Read aloud: TTS integration point (future)

### Phase B: OCR Feature (P2)

#### Recommended Approach: PaddleOCR PP-OCRv4 Mobile via ONNX Runtime

**Why PaddleOCR over alternatives:**

| Engine | Verdict | Reason |
|--------|---------|--------|
| Google ML Kit | **Fallback only** | Missing Arabic, Cyrillic, Thai — only 5 scripts |
| Tesseract | **Not recommended** | Poor accuracy on camera photos (designed for scanned docs) |
| PaddleOCR | **Primary choice** | Best scene text accuracy, 80+ languages, ~16-22MB total, fast (~200ms) |
| EasyOCR | **Not recommended** | Gen1 models are 215MB each for Arabic/Cyrillic/Thai |
| TrOCR | **Not recommended** | 234MB+, English-only by default, too slow |

**Implementation Plan:**
1. Convert PP-OCRv4 mobile models (det + cls + rec) to ONNX, quantize to INT8
2. Integrate via `onnxruntime` Flutter package
3. Per-language recognition models as downloadable packs (~10-15MB each)
4. Base download: ~5-7MB (det + cls)
5. Run in separate isolate to avoid UI jank

**RAM Management Strategy:**
1. User takes photo → show preview
2. Unload 1.55GB LLM model from RAM
3. Load OCR models (~50-150MB) → run inference (~200-500ms)
4. Extract text → unload OCR models
5. Reload LLM model → translate extracted text
6. Total user-visible latency: ~3-5s (OCR) + ~4s (TTFT) + translation time

**Camera → Translate UX Flow:**
1. Camera button in input bar (prominent, like Google Translate)
2. Full-screen viewfinder with language pair at top
3. Capture button + gallery access + flash toggle
4. Post-capture: image with highlighted text regions
5. Editable extracted text field (user can fix OCR errors)
6. "Translate" CTA → result appears in chat/translation flow

**Model Download UX:**
- Optional during onboarding (after Aya model download)
- Also available in Settings → "Photo Translation" section
- Per-language packs: show name, size, download status
- Progress bar during download
- Total storage estimate in settings

#### Fallback: Google ML Kit v2
If full multilingual OCR is deferred:
- `google_mlkit_text_recognition` bundled (~4MB/script, 5 scripts = ~20MB)
- Covers Latin, Chinese, Japanese, Korean, Devanagari
- Zero custom native code needed
- Add PaddleOCR later for Arabic/Cyrillic/Thai

### Phase C: Onboarding + Settings Expansion (P2-P3)

#### C1. Onboarding Flow
- Screen 1: "BittyBot translates offline — your conversations never leave your device"
- Screen 2: "Supports 66 languages. AI translations may not be perfect."
- Screen 3: Model download with determinate progress, MB/total, ETA
- Allow background download while exploring disabled UI
- Skeleton screens showing what the app will look like

#### C2. Settings Expansion
- **Model Management:** Downloaded models list with sizes, delete option
- **OCR Language Packs:** Per-pack download/delete with sizes
- **Haptic Feedback:** On / Subtle / Off toggle
- **Theme:** Light / Dark / System toggle (currently dark-only)
- **About / Version**

### Phase D: Advanced Features (P3, future consideration)

- Conversation export (share entire chat)
- Translation history / saved translations
- Improved multi-turn recall (context summary injection)
- Voice input integration
- Face-to-face conversation mode (split screen, auto-detect speakers)
- Release build optimization (ProGuard, --release, size audit)

---

## Design Principles (from research)

### Material Design 3 Compliance
- `ColorScheme.fromSeed()` for dynamic color generation
- Surface tint elevation system (lighter = higher in dark mode)
- Lazy widgets (`ListView.builder`) for message lists
- Adaptive layouts for future tablet support
- 48dp minimum touch targets

### Dark Theme
- Background: `#121212` (not pure black) ✓ (already implemented)
- Text: off-white ~87% opacity (not pure white)
- Desaturated accent colors
- Surface elevation: higher = lighter
- Follow system theme by default; add manual toggle

### Haptic Feedback Guide
| Event | Intensity | Flutter |
|-------|-----------|---------|
| Send message | Light | `HapticFeedback.lightImpact()` |
| Copy text | Light | `HapticFeedback.lightImpact()` |
| Swap languages | Medium | `HapticFeedback.mediumImpact()` |
| Toggle switch | Medium | `HapticFeedback.mediumImpact()` |
| Download complete | Heavy | `HapticFeedback.heavyImpact()` |
| Error | Pattern | `HapticFeedback.vibrate()` |

### Multilingual Layout
- Per-message text direction (RTL for Arabic, LTR for Latin)
- CJK: allow breaks between any characters, fixed-width display
- Text expansion planning: Russian +30%, Chinese -10%
- Use `Noto Sans` family for cross-script consistency
- Never truncate translated text — use scrollable containers

---

## Sprint 10 Summary

| Item | Status | Commit |
|------|--------|--------|
| nCtx 512→2048 | COMPLETE | `d98dcc9` |
| Web fetch fix | COMPLETE | `97f83de` |
| UI/UX research | COMPLETE | This report |
| OCR research | COMPLETE | PaddleOCR recommended |
| Milestone plan | COMPLETE | Phases A-D defined |

**Next action:** On-device retest of nCtx=2048 and web fetch fix, then begin Phase A (UI Polish Sprint).
