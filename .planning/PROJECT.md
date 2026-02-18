# BittyBot

## What This Is

A fully offline-capable multilingual chat and translation app for travelers, powered by Cohere's Tiny Aya Global 3.35B model running entirely on-device. Built with Flutter for iOS and Android. Think ChatGPT's interface but with a tiny model that actually works without internet — for reading signs, talking to locals, translating websites, and summarizing foreign-language content.

## Core Value

Translation and conversation must work with zero connectivity. A traveler in a remote area with no data should be able to type or paste foreign text and get a useful response.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] On-device inference of Tiny Aya Global 3.35B with model bundled in app
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
- **Inference:** Need on-device runtime for Flutter — user has ONNX experience but open to best option (llama.cpp/GGUF also viable)
- **Model size:** ~1.5-2GB quantized to Q4, bundled with app binary
- **Primary user:** The developer themselves, traveling internationally
- **Design reference:** Tiny Aya demo screenshot — dark bg, green border, lime accents, leaf motif

## Constraints

- **Platform:** Flutter/Dart — must target both iOS and Android from single codebase
- **Offline:** Core translation/chat must work with absolutely zero network connectivity
- **Model size:** 3.35B params, need aggressive quantization for mobile RAM/storage budgets
- **License:** CC-BY-NC 4.0 — no commercial use without Cohere agreement
- **Storage:** Model bundled means large app size (~2GB+), acceptable tradeoff for offline-first

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Bundle model with app (not download on first launch) | Guarantees offline from first use, critical for traveler use case | — Pending |
| Flutter/Dart | Cross-platform iOS + Android from single codebase | — Pending |
| Tiny Aya Global (not base or regional variants) | Best balanced multilingual performance across all 70+ languages | — Pending |
| Dark theme with Cohere green palette | User preference, inspired by Tiny Aya demo aesthetic | — Pending |
| Text-only v1, camera OCR in v2 | Reduce scope, nail the core translation chat experience first | — Pending |

---
*Last updated: 2026-02-19 after initialization*
