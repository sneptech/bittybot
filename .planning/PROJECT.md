# BittyBot

## What This Is

A fully offline-capable multilingual chat and translation app for travelers, powered by Cohere's Tiny Aya Global 3.35B model running entirely on-device. Built with Flutter for iOS and Android. Think ChatGPT's interface but with a tiny model that actually works without internet — for reading signs, talking to locals, translating websites, and summarizing foreign-language content.

## Core Value

Translation and conversation must work with zero connectivity. A traveler in a remote area with no data should be able to type or paste foreign text and get a useful response.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] On-device inference of Tiny Aya Global 3.35B with model downloaded on first launch
- [ ] Chat interface with text entry and message history (ChatGPT/Claude-style)
- [ ] Multilingual translation and summarization via the model
- [ ] Slide-out drawer with previous chat sessions
- [ ] Chat history persistence (keep everything locally)
- [ ] Auto-clear chat history toggle (configurable time period)
- [ ] Clear all history button with confirmation dialog
- [ ] Settings button on text entry bar with web search toggle
- [ ] Web search mode: paste a URL, get the page translated/summarized (online only)
- [ ] App UI language matches device locale
- [ ] Dark theme with Cohere-inspired green palette (forest green borders, lime/yellow-green accents)
- [ ] Clean, minimal visual style inspired by Tiny Aya demo aesthetic

### Out of Scope

- Camera OCR for translating signs/menus — v2 feature, get text chat working first
- Commercial distribution — personal/open-source project, CC-BY-NC model license
- OAuth/accounts/cloud sync — fully local, no backend
- Voice input/output — text-only for v1
- Multiple model support — Tiny Aya Global only

## Context

- **Model:** Cohere Tiny Aya Global 3.35B (CohereLabs/tiny-aya-global on HuggingFace)
  - Architecture: Auto-regressive transformer, 3 layers sliding window attention (4096) + 1 global attention layer
  - Context: 8K input / 8K output
  - Format: Safetensors (BF16), quantized variants available
  - Languages: 70+ (European, Middle Eastern, South Asian, Southeast Asian, East Asian, African)
  - License: CC-BY-NC 4.0
  - Strengths: Open-ended generation, low-resource languages, cross-lingual tasks
  - Weaknesses: Chain-of-thought reasoning, factual knowledge gaps
- **Inference:** llama.cpp via GGUF format, using llama_cpp_dart or fllama Flutter bindings
- **Model size:** ~2.14GB quantized to Q4_K_M, downloaded on first launch (not bundled — app store limits)
- **Primary user:** The developer themselves, traveling internationally
- **Design reference:** Tiny Aya demo screenshot — dark bg, green border, lime accents, leaf motif

## Constraints

- **Platform:** Flutter/Dart — must target both iOS and Android from single codebase
- **Offline:** Core translation/chat must work with absolutely zero network connectivity
- **Model size:** 3.35B params, need aggressive quantization for mobile RAM/storage budgets
- **License:** CC-BY-NC 4.0 — no commercial use without Cohere agreement
- **Storage:** Model downloaded on first launch (~2.14GB), stored in app documents directory

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Download model on first launch (not bundled) | App store limits (200MB iOS cellular, 150MB Android AAB) make bundling infeasible; offline after first download | ⚠️ Revisit |
| Flutter/Dart | Cross-platform iOS + Android from single codebase | — Pending |
| Tiny Aya Global (not base or regional variants) | Best balanced multilingual performance across all 70+ languages | — Pending |
| Dark theme with Cohere green palette | User preference, inspired by Tiny Aya demo aesthetic | — Pending |
| Text-only v1, camera OCR in v2 | Reduce scope, nail the core translation chat experience first | — Pending |
| llama_cpp_dart ^0.2.2 as inference binding | Most recently updated, tracks llama.cpp master, FFI bindings match | Validated |
| Native lib pre-built as AAR (not plugin auto-bundle) | llama_cpp_dart is not a Flutter plugin; must manually compile and deploy libmtmd.so | Validated |
| 70-language evaluation corpus (4 mustHave + 66 standard) | Covers model card languages; mustHave languages get deeper evaluation | Validated |
| 11-state sealed class for download flow | Exhaustive switch covers all download lifecycle states; compiler catches missing handlers | Validated |
| Chunked SHA-256 in compute() isolate | 2.14 GB model cannot be loaded into RAM for hashing; 64KB RandomAccessFile chunks in background isolate | Validated |
| background_downloader with registerCallbacks()+enqueue() | Full TaskProgressUpdate with speed/ETA (not download() which gives void Function(double) only) | Validated |
| Completer<TaskStatusUpdate> bridge pattern | Bridges registerCallbacks async API into clean await pattern | Validated |
| Dark theme only (no light variant) | User preference; Cohere-inspired green palette; ThemeMode.dark forced | Validated |
| Offline fonts via GoogleFonts.config.allowRuntimeFetching = false | App must work with zero connectivity; fonts bundled in assets/google_fonts/ | Validated |
| 10 supported UI locales (not all 66 model languages) | UI strings need manual translation; 10 covers primary user needs. Model handles 66 for inference. | Validated |
| Manual ColorScheme() constructor (not fromSeed) | fromSeed generates tonal palette that overrides exact brand hex values | Validated |
| Error tone feature (resolveErrorMessage with Dart 3 record pattern switch) | Exhaustive (AppError, ErrorTone) switch; compiler catches missing combinations | Validated |
| Partial-access pattern: appStartupProvider awaits settings only | Users can browse history while model loads; only input disabled until model ready | Validated |
| Dedicated inference isolate (never main thread) | Prevents ANR; FFI llama.cpp instance owned entirely by isolate | Validated |
| DriftChatRepository with constructor injection (not DatabaseAccessor) | Simpler Riverpod integration; avoids tight coupling to Drift internals | Validated |
| Model loaded with nPredict=-1, counted manually per request | ContextParams.nPredict is construction-time only; per-request counting allows chat=512, translation=128 | Validated |
| Cooperative stop via closure-scope flag (not isolate kill) | Preserves KV cache and model state; avoids expensive reload | Validated |
| TranslationNotifier keepAlive vs ChatNotifier auto-dispose | Translation language pair persists across navigation; chat reloads from DB each screen entry | Validated |
| targetLanguage as englishName string (not language code) | Matches model prompt format; no mapping layer needed in notifier | Validated |
| Word-level vs token-level streaming by script family | Space-delimited scripts get word-boundary batching; CJK/Thai/etc. use token-by-token (no word boundaries) | Validated |
| 66 canonical languages with country-variant flag map | Matches model card exactly; kLanguageCountryVariants maps language to flag for display | Validated |

---
*Last updated: 2026-02-25 after cross-phase context audit*
