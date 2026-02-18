# Project Research Summary

**Project:** BittyBot
**Domain:** Offline-first on-device LLM translation and chat mobile app (Flutter, iOS + Android)
**Researched:** 2026-02-19
**Confidence:** MEDIUM-HIGH (stack selection solid; inference binding validation is the highest remaining risk)

## Executive Summary

BittyBot is a privacy-first, offline multilingual translation and chat app powered by Cohere Tiny Aya Global (3.35B parameters, 70+ languages) running entirely on-device via llama.cpp. The app targets travelers who need reliable translation without internet connectivity. Building this class of product in 2026 means navigating three simultaneous engineering domains: on-device LLM inference on mobile hardware (a relatively immature and rapidly evolving space), cross-platform Flutter development, and app store distribution constraints that actively conflict with shipping a 2+ GB AI model. The research establishes a clear recommended approach for all three, but the foundation must be a working proof-of-concept that validates llama.cpp's Cohere2 architecture support before any production code is written.

The recommended stack centers on Flutter 3.41 + Riverpod 3 + Drift for the application layer, with llama.cpp (via `llama_cpp_dart` or `fllama`) as the inference engine using GGUF Q4_K_M quantization. The most consequential architecture decision not in the original project spec is model distribution: bundling a 2.14 GB model in the app binary is incompatible with both app stores' over-the-air download limits. The app must use a first-launch download flow (background-capable, Wi-Fi gated) rather than static bundling. After this change, the architecture is well-understood: a long-lived Dart Isolate owns the llama.cpp context, communicates via SendPort/ReceivePort, and streams tokens back to the UI through Riverpod stream providers. Drift provides reactive SQLite queries that auto-update the chat history UI.

The highest technical risk is Pitfall 1: the Cohere2 model architecture is new (merged into llama.cpp February 2025) and any Flutter plugin vendoring an older pinned llama.cpp version will silently fail at inference time. This must be validated on real hardware before writing any application code. Secondary risks are iOS memory pressure from a 2 GB model on 4 GB devices, and Android 16 KB page size compliance (mandatory Google Play deadline: May 31, 2026). Both are solvable with known mitigations but must be addressed early. Performance expectations must also be managed: mid-range Android devices will produce 2-8 tokens/second, which is usable only with token streaming — not tolerable as batch output.

## Key Findings

### Recommended Stack

The inference layer uses llama.cpp as the underlying engine, accessed via either `llama_cpp_dart` or `fllama` (evaluate which has a newer llama.cpp pin that includes Cohere2 support). The model is Cohere Tiny Aya Global Q4_K_M (2.14 GB GGUF), downloaded on first launch to app documents directory via `background_downloader`, which is the only Flutter package that survives app backgrounding for a 2 GB transfer. On the application side, Riverpod 3.0 handles state management (AsyncNotifier pattern is well-suited to the async inference lifecycle), Drift provides type-safe reactive SQLite for chat history, and `flutter_chat_ui` v2 (Flyer Chat) provides the chat UI with first-class token streaming support via `flyer_chat_text_stream_message`.

**Core technologies:**
- `llama_cpp_dart` or `fllama`: FFI binding to llama.cpp for on-device inference — only mature Flutter packages for GGUF on iOS + Android
- GGUF Q4_K_M (2.14 GB): optimal quantization for the 3.35B Tiny Aya model — better quality than Q4_0 with only 110 MB more storage
- Flutter 3.41 + Dart 3.8: current stable; cross-platform for iOS + Android from one codebase
- Riverpod 3.0: state management — offline caching and mutation support added in Sept 2025 release matches app needs
- Drift 2.31: SQLite ORM — reactive streams auto-notify UI on history changes; better query patterns than Isar for chat data
- `flutter_chat_ui` v2: chat UI — rebuilt in 2025 with explicit first-class LLM streaming support
- `background_downloader`: model download — uses NSURLSessionDownloadTask (iOS) and DownloadWorker (Android), survives backgrounding for 2 GB transfers
- `connectivity_plus`: gate model download to Wi-Fi; gate optional web search feature
- `shared_preferences`: lightweight settings persistence; `drift` for chat history

**Critical version requirements:**
- Android NDK r28+ (16 KB page compliance, mandatory Play Store from May 31, 2026)
- Android min SDK 24, target SDK 35
- iOS minimum 16.0 (Metal GPU)
- llama.cpp version must include PR #19611 (Cohere2 / Tiny Aya support, merged Feb 2025) — verify before committing to any plugin

### Expected Features

The feature landscape is clear: the core loop (download model once, translate text offline, chat with the model) must be rock-solid, and the differentiators (70+ language coverage including low-resource languages, privacy, conversational AI that goes beyond lookup-table translation) should be surfaced prominently. The anti-feature list is equally important: no accounts, no cloud sync, no subscriptions, no ads — any of these would contradict the product's positioning.

**Must have (table stakes):**
- Model onboarding + offline readiness indicator — everything else is gated on this
- Text translation with language selector (swap, persist last pair, copy to clipboard)
- Chat interface (multi-turn) — the LLM is a chat model; translation-only wastes its capabilities
- Chat history drawer with session management
- Translation history (recent translations, reverse-chronological)
- Dark theme with green accents (project requirement; genuinely better for low-light travel)
- Large tap targets (48dp Android / 44pt iOS) and legible typography (16sp minimum body)
- Basic error messaging (model not loaded, input too long)

**Should have (competitive differentiators):**
- Privacy-first positioning made explicit in onboarding ("translations never leave your phone")
- 70+ language coverage surfaced visibly in language picker (include low-resource languages Google Translate offline doesn't cover)
- Conversational AI framing ("chat with a travel assistant") not just translation widget
- Phrasebook / starred translations (v1.1 — history covers 80% of need for launch)
- Text-to-speech for translations (platform TTS APIs; no additional model needed)

**Defer to v2+:**
- Camera OCR (menu scanning) — requires ML Kit + separate pipeline, high complexity
- Web URL / page translation — network + storage coordination, high complexity
- Conversation / dialogue mode (split-screen two-person) — significant design work
- Voice input (STT via platform APIs) — addable post-launch without architecture changes
- Transliteration (romanization) — secondary; add once core translation is solid

### Architecture Approach

The architecture is a clean layered design: UI widgets watch Riverpod notifiers, notifiers orchestrate calls to repository interfaces, and repositories delegate to either the Drift SQLite database (for history) or the LLM Service (for inference). The critical architectural decision is the Dart Isolate boundary: all llama.cpp FFI calls must run in a single long-lived Inference Isolate that owns the llama.cpp context for its lifetime. This isolate communicates via SendPort/ReceivePort and streams tokens back to the main isolate as a `Stream<String>`. The isolate must never be respawned per message — model reload is 10-30 seconds on mobile.

**Major components:**
1. **Inference Isolate** — owns llama.cpp context, KV cache, runs token generation loop; spawned once at startup
2. **LLM Service** — manages isolate lifecycle, routes messages, converts port messages to `Stream<String>`; never shares context across isolate boundary
3. **InferenceRepository** (abstract interface) — decouples notifiers from LLM Service implementation; enables future cloud fallback
4. **ChatNotifier / TranslationNotifier** (Riverpod AsyncNotifier) — orchestrate user turn → inference → persist flow; expose `Stream<String>` token stream to UI
5. **Drift DB** — SQLite via Drift ORM; reactive `watch()` queries auto-notify History and Chat UIs; single source of truth
6. **Model File Manager** — checks GGUF path at startup, reports model load status, handles download vs. bundled path
7. **PromptBuilder** — pure Dart; constructs Aya chat template format from message history; manages context window budget with sliding window eviction
8. **UI Layer** — ChatScreen, TranslationScreen, HistoryScreen, Settings; uses StreamBuilder for token streaming display

**Key patterns:**
- Long-lived Inference Isolate (never respawn per message)
- Repository abstraction over inference (InferenceRepository interface)
- Drift reactive queries for chat history (no manual refresh)
- Optimistic UI on message send (user message displayed before inference starts)
- Aya prompt template encapsulation in PromptBuilder (format: `<BOS><|START_OF_TURN|>...<|CHATBOT_TURN|>`)

### Critical Pitfalls

1. **Cohere2 architecture not recognized by inference plugin** — If the vendored llama.cpp in the chosen Flutter plugin predates PR #19611 (Feb 2025), the model loads but inference crashes or returns empty. Prevention: run a standalone CLI test against the actual GGUF *before writing any app code*. This is the highest-risk item.

2. **iOS memory pressure kills app with 2 GB model** — iOS kills apps under memory pressure with no user warning. The 2.14 GB model plus Flutter runtime plus KV cache approaches the 4 GB RAM limit on iPhone 12/13 base models. Prevention: cap context window at 2048 tokens (not 8K), enable Extended Virtual Addressing entitlement, handle `didReceiveMemoryWarning` by releasing model.

3. **App store distribution blocked by model size** — A 2+ GB model cannot be bundled in the app binary. Android Play requires the base APK to be under 200 MB; iOS allows up to 4 GB IPA but cellular download warning appears and many users abandon. Prevention: use first-launch download via `background_downloader` (Wi-Fi gated, with clear size disclosure). This decision affects the entire project structure and must be made before architecture work begins.

4. **Android 16 KB page size compliance** — Play Store rejects apps with `.so` files compiled against NDK < r27 starting May 31, 2026. Prevention: verify chosen llama.cpp plugin specifies NDK r28+; check alignment with `readelf` before any Play Store submission.

5. **iOS static library linking failures** — Building llama.cpp for iOS produces interdependent dylibs; only static linking works reliably. iOS Simulator is blocked (Metal GPU unavailable). Prevention: test chosen Flutter plugin on a physical iOS device in Phase 1, not Simulator; pin to static library builds.

6. **Inference blocking Flutter UI thread** — Direct FFI calls to llama.cpp from the main isolate freeze the UI. Prevention: all inference runs in Dart Isolate (covered in architecture above); verify the chosen plugin actually isolates inference rather than claiming to.

## Implications for Roadmap

Based on the component dependency graph from ARCHITECTURE.md and the phase warnings from PITFALLS.md, the following phase structure is recommended. The dependency order is non-negotiable: the inference layer must be validated before any UI is built, and the model download flow must be decided before platform work begins.

### Phase 1: Inference Spike and Model Validation

**Rationale:** The single highest technical risk — Cohere2 architecture compatibility with the Flutter llama.cpp binding — must be resolved before anything else. Building the app on an unvalidated inference assumption is a project-ending mistake. This phase is pure technical validation, no production code.

**Delivers:** Working proof-of-concept that loads `tiny-aya-global-Q4_K_M.gguf`, runs a translation prompt, streams tokens back to Dart, and produces correct multilingual output. Performance benchmarks (tok/s) on target device classes. Confirmed platform build setup (NDK r28, iOS static linking).

**Validates:**
- Cohere2 architecture recognized by chosen plugin (Pitfall 1)
- iOS static linking / physical device test (Pitfall 4)
- Baseline token-per-second on mid-range Android and recent iPhone (Pitfall 9)
- Quantization quality for key language families: Arabic, Thai, Amharic (Pitfall 7)
- Prompt template format confirmed from model card

**Research flag:** Needs `/gsd:research-phase` — llama.cpp plugin version lag for Cohere2 is unverified; specific linking approach on iOS depends on chosen plugin.

### Phase 2: Model Distribution and Platform Foundation

**Rationale:** The decision not to bundle the model affects the entire project structure. Play Asset Delivery for Android requires changes to the Gradle build configuration that are much harder to retrofit. This must be settled before platform integration work begins.

**Delivers:** First-launch model download flow (background-capable, Wi-Fi gated, with progress UI and retry); model file integrity check (SHA-256); storage availability check; offline readiness indicator; Android 16 KB page compliance verified; iOS Extended Virtual Addressing entitlement configured.

**Addresses:** Model onboarding (table stakes feature), offline readiness indicator (MVP requirement 1 from FEATURES.md)

**Avoids:** App store distribution rejection (Pitfall 3), 16 KB page size compliance failure (Pitfall 5), model corruption on update (Pitfall 14)

**Stack elements:** `background_downloader`, `path_provider`, `connectivity_plus`, `shared_preferences`

**Research flag:** Android Play Asset Delivery integration with Flutter — may need custom native code; evaluate early.

### Phase 3: Core Inference Layer and State Management

**Rationale:** With inference validated and model distribution solved, build the production inference architecture. This phase constructs the long-lived Isolate pattern, repository abstractions, and Riverpod notifiers. All subsequent UI phases depend on this layer.

**Delivers:** Production LLM Service with Inference Isolate lifecycle management; `InferenceRepository` abstract interface; `ChatNotifier` and `TranslationNotifier` (Riverpod AsyncNotifier); `PromptBuilder` with Aya chat template and sliding window context management; Drift DB schema (messages, sessions, settings tables); `HistoryRepository`.

**Implements:** Inference Isolate, LLM Service, ChatNotifier, TranslationNotifier, PromptBuilder, Drift DB (from ARCHITECTURE.md component build order steps 1-5)

**Avoids:** UI thread blocking (Pitfall 6), KV cache mismanagement (Pitfall 2 memory), context window exhaustion (Pitfall 10)

**Research flag:** Standard patterns (well-documented Isolate + Riverpod AsyncNotifier + Drift patterns); no additional research phase needed.

### Phase 4: Translation UI

**Rationale:** Build the simpler of the two primary surfaces first. Translation is single-turn (no history management in-session), making it a lower-complexity test of the inference pipeline before tackling multi-turn chat.

**Delivers:** Translation screen with language selector (70+ languages), swap button, copy to clipboard, source text input with clear button, streaming translation result display, language preference persistence, dark theme with green accents.

**Addresses:** Table stakes features: text translation, language selector, swap, copy, clear, persistent language preference, legible typography, large tap targets (from FEATURES.md table stakes)

**Avoids:** Prompt formatting mismatch (Pitfall 13 — test translation output format before chat), RTL text display for Arabic/Hebrew (Pitfall 12 — test Impeller with Arabic output)

**Research flag:** RTL text rendering with Impeller on iOS — test on physical device; may require fallback to Skia.

### Phase 5: Chat UI and History

**Rationale:** Multi-turn chat is the LLM differentiator for BittyBot. Builds on the inference layer from Phase 3 and the UI patterns from Phase 4. Chat history persistence via Drift reactive queries integrates naturally here.

**Delivers:** Chat screen with streaming token display (`flutter_chat_ui` v2 + `flyer_chat_text_stream_message`), optimistic user message display, typing indicator during inference, inference cancellation (stop button), chat session drawer (history navigation), translation history (recent translations list), session management (new session, delete session).

**Addresses:** Chat interface (MVP requirement 3), chat history drawer (MVP requirement 4), translation history (MVP requirement 5) — from FEATURES.md

**Avoids:** Frozen UI during inference (Pitfall 6 — streaming display), context window exhaustion (Pitfall 10 — PromptBuilder sliding window), battery/thermal drain (Pitfall 11 — cancellation button, background inference pause)

**Research flag:** Standard patterns for `flutter_chat_ui` v2 streaming integration; no additional research needed.

### Phase 6: Settings, Polish, and Release Preparation

**Rationale:** Non-blocking polish work that should not gate core functionality. Includes device-specific tuning (context window size based on available RAM), thermal testing, and release build validation.

**Delivers:** Settings screen (context size, model params, auto-clear toggle), device RAM detection for adaptive context window sizing, thermal performance testing (30-minute session), memory pressure handling on iOS (`didReceiveMemoryWarning`), RTL text display verification for all supported scripts, Play Store and App Store submission builds.

**Addresses:** Dark mode requirement (MVP requirement 6), settings persistence, release readiness

**Avoids:** iOS memory kills on low-RAM devices (Pitfall 2 — adaptive context sizing), thermal throttling UX degradation (Pitfall 11 — tested and documented), token overhead for non-Latin scripts (Pitfall 15 — documented in settings)

**Research flag:** Standard release process for both stores; no additional research needed.

### Phase Ordering Rationale

- Phase 1 before everything: Cohere2 compatibility is binary — if it fails, the project approach must change. No point building UI on broken inference.
- Phase 2 before platform work: Model distribution strategy (download vs. bundle) changes the Android Gradle project structure fundamentally. Retrofit is expensive.
- Phase 3 before UI: All UI phases require the Riverpod notifiers and repository interfaces. Skipping this layer means untestable, tightly-coupled UI code.
- Phase 4 (Translation) before Phase 5 (Chat): Translation is simpler single-turn inference; it validates the pipeline with less state complexity before introducing multi-turn KV cache management.
- Phase 6 last: Polish and release prep depends on stable core functionality.
- Drift schema (part of Phase 3) can begin in parallel with Phase 2 since it has no inference dependency.

### Research Flags

Phases needing `/gsd:research-phase` during planning:
- **Phase 1:** llama.cpp plugin Cohere2 compatibility — specific version of llama.cpp vendored by each candidate plugin is unverified; must inspect package source or run CLI test
- **Phase 2:** Android Play Asset Delivery integration — Flutter has no native PAD support; may require writing custom native plugin code; complexity unknown
- **Phase 4:** Impeller RTL rendering — Flutter issue #119805 status for Arabic text in the current Impeller version needs verification before committing to the rendering path

Phases with standard patterns (skip research-phase):
- **Phase 3:** Dart Isolate + Riverpod AsyncNotifier + Drift — all well-documented with Flutter official docs and multiple production examples
- **Phase 5:** `flutter_chat_ui` v2 streaming integration — package has explicit documentation and examples for LLM streaming
- **Phase 6:** App store release process — standard; no novel elements

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | MEDIUM-HIGH | Most packages verified with HIGH confidence; the critical exception is llama.cpp Flutter binding version lag for Cohere2 support, which is MEDIUM confidence until verified on device |
| Features | HIGH | Table stakes confirmed against Google Translate, Apple Translate, DeepL official docs and user reviews; 70+ language Aya coverage confirmed from Cohere official announcement (Feb 2026) |
| Architecture | MEDIUM-HIGH | Dart Isolate + FFI pattern verified from multiple sources including Flutter official docs; KV cache lifecycle confirmed from llama.cpp upstream; streaming token pattern inferred from package design (not directly benchmarked) |
| Pitfalls | HIGH | Most critical pitfalls have primary source documentation (GitHub issues, Apple Developer docs, Android Developers blog); Cohere2 incompatibility documented in llama-cpp-python issue #1893 |

**Overall confidence:** MEDIUM-HIGH

### Gaps to Address

- **Cohere2 inference compatibility:** Must be validated empirically before Phase 2 begins. If `llama_cpp_dart` does not include PR #19611, fall back to `fllama` or vendor llama.cpp directly. Resolution: Phase 1 spike.

- **Actual token-per-second on target devices:** Research estimates 2-8 tok/s on mid-range Android, 20+ on recent iPhones. Actual numbers determine whether the app is usable on the minimum supported device class. Resolution: Phase 1 benchmarks.

- **iOS memory ceiling on 4 GB devices:** The 2.14 GB model plus overhead may not fit. No definitive measurement exists for Tiny Aya specifically. Resolution: Phase 1 spike on iPhone 12 (4 GB RAM).

- **Android Play Asset Delivery:** Whether this is needed (vs. simple first-launch download) depends on Google Play upload validation results. Play may reject an AAB with a 2 GB asset in the base module. Resolution: Phase 2, test upload to Play Console internal track early.

- **Prompt template validation:** The Aya chat template format is documented in the HuggingFace model card, but multilingual instruction-following quality under Q4_K_M needs empirical validation across language families. Resolution: Phase 1 quality testing.

## Sources

### Primary (HIGH confidence)
- [CohereLabs/tiny-aya-global-GGUF — HuggingFace](https://huggingface.co/CohereLabs/tiny-aya-global-GGUF) — GGUF quantization sizes, model architecture
- [llama.cpp PR #19611](https://github.com/ggml-org/llama.cpp/pull/19611) — Tiny Aya / Cohere2 support merged Feb 17, 2025
- [llama.cpp Metal backgrounding crash — Issue #16998](https://github.com/ggml-org/llama.cpp/issues/16998) — iOS background pitfall
- [flutter_chat_ui — pub.dev](https://pub.dev/packages/flutter_chat_ui) — Chat UI v2 with streaming
- [flyer_chat_text_stream_message — pub.dev](https://pub.dev/packages/flyer_chat_text_stream_message) — LLM streaming support
- [drift — pub.dev](https://pub.dev/packages/drift) — SQLite ORM, reactive queries
- [background_downloader — pub.dev](https://pub.dev/packages/background_downloader) — Resume-capable platform-native downloads
- [Flutter Riverpod 3.0 release — riverpod.dev](https://riverpod.dev/docs/whats_new) — Released Sept 2025
- [Flutter Concurrency and Isolates — official docs](https://docs.flutter.dev/perf/isolates) — Isolate communication patterns
- [Google Play 16KB page requirement — Android Developers](https://developer.android.com/guide/practices/page-sizes) — NDK r28 requirement, May 2026 deadline
- [iOS App Store size limits — Apple Developer](https://developer.apple.com/help/app-store-connect/reference/app-uploads/maximum-build-file-sizes/) — 4 GB IPA, 200 MB cellular limit
- [iOS Increased Memory Limit Entitlement — Apple Developer Docs](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.kernel.increased-memory-limit)
- [Impeller Arabic text rendering issue — flutter/flutter #119805](https://github.com/flutter/flutter/issues/119805)
- [What's new in Flutter 3.41 — Flutter blog](https://blog.flutter.dev/whats-new-in-flutter-3-41-302ec140e632)

### Secondary (MEDIUM confidence)
- [llama_cpp_dart — pub.dev](https://pub.dev/packages/llama_cpp_dart) — Primary candidate Flutter binding; version lag unverified
- [fllama — GitHub (Telosnex)](https://github.com/Telosnex/fllama) — Alternative Flutter binding; may track llama.cpp more closely
- [cohere2 architecture issue — llama-cpp-python #1893](https://github.com/abetlen/llama-cpp-python/issues/1893) — Documented compatibility risk
- [Fail Log: Flutter llama.cpp on iOS — Medium, May 2025](https://medium.com/@developerha0013/fail-log-flutter-llama-cpp-on-ios-82b06c442cba) — iOS static linking pitfall
- [Are Local LLMs on Mobile a Gimmick? — Callstack, 2025](https://www.callstack.com/blog/local-llms-on-mobile-are-a-gimmick) — Performance expectations
- [Cohere Tiny Aya launch — TechCrunch](https://techcrunch.com/2026/02/17/cohere-launches-a-family-of-open-multilingual-models/) — Model capabilities overview
- [KV cache reuse llama.cpp discussion](https://github.com/ggml-org/llama.cpp/discussions/7698) — KV cache session persistence
- [Preparing Flutter Apps for Android 15's 16 KB page size — Medium](https://faheem-riaz.medium.com/preparing-your-flutter-app-for-android-15s-16-kb-page-size-requirement-b07b3dbfbdd1)
- [Riverpod 3.0 new features — DhiWise](https://www.dhiwise.com/post/riverpod-3-new-features-for-flutter-developers)
- [On-Device AI on Android — Towards AI](https://pub.towardsai.net/on-device-ai-chat-translate-on-android-qualcomm-genie-mlc-webllm-your-phone-your-llm-49594aff3b9f)

### Tertiary (LOW confidence — needs validation)
- [LLM Performance on Mobile Devices — arXiv 2410.03613](https://arxiv.org/html/2410.03613v3) — tok/s estimates for 3B models; device coverage may not include Tiny Aya specifically
- [Practical GGUF Quantization Guide for iPhone — Enclave AI, Nov 2025](https://enclaveai.app/blog/2025/11/12/practical-quantization-guide-iphone-mac-gguf/) — Quantization quality comparison for mobile; Tiny Aya not specifically tested

---
*Research completed: 2026-02-19*
*Ready for roadmap: yes*
