# Technology Stack

**Project:** BittyBot — Offline-first multilingual Flutter chat/translation app
**Researched:** 2026-02-19
**Confidence:** MEDIUM-HIGH (inference engine choice has critical caveats below)

---

## Critical Pre-Decision: Model Deployment Strategy

The PROJECT.md states the model will be bundled with the app binary. This is technically and store-policy problematic at the 2GB scale. **Verdict: Use first-launch download, not bundle.**

**Why bundling fails:**
- Apple App Store: 200MB cellular download limit. App with 2GB+ asset won't be installable over cellular. Even with a ~2.14GB IPA, users on Wi-Fi can install it, but this is a poor UX. The total IPA limit is 4GB.
- Google Play: AAB (mandatory since 2021) has a 150MB base module limit. There is no OBB support for AABs. Play Asset Delivery could theoretically host a 2GB pack, but Flutter has no native Play Asset Delivery integration — requires custom native code.
- iOS On-Demand Resources: Flutter has no native support (open issue #49901, open since 2020, still unresolved as of 2026).
- The "bundle with app" decision in PROJECT.md should be revisited to "download on first launch over Wi-Fi with progress indicator." This preserves the offline guarantee after first use while making the app actually publishable.

**Recommended model file strategy:** Download on first launch (Wi-Fi gated), store in `getApplicationDocumentsDirectory()`, skip download if file already present. Show progress UI during download.

---

## Recommended Stack

### Inference Engine (Critical Technical Decision)

**Recommended: llama.cpp via `llama_cpp_dart`**

| Attribute | Detail |
|-----------|--------|
| Package | `llama_cpp_dart` (pub.dev, GitHub: netdur/llama_cpp_dart) |
| Underlying Engine | llama.cpp (ggml-org/llama.cpp) |
| Model Format | GGUF |
| iOS Acceleration | Metal (Apple GPU, minimum Apple7 GPU) |
| Android Acceleration | OpenCL / CPU (NEON SIMD) |
| Platform Support | Android, iOS, macOS, Windows, Linux |
| Confidence | MEDIUM — see caveats below |

**Why llama.cpp over alternatives:**
- llama.cpp is the de facto standard for running quantized LLMs on CPU/mobile hardware. It has broad GGUF model support, active development, Metal GPU acceleration on iOS, and multiple Flutter FFI bindings.
- The Cohere2 architecture (used by tiny-aya-global) was added to llama.cpp in PR #10900 and native tiny-aya support was merged via PR #19611. The official `CohereLabs/tiny-aya-global-GGUF` repo on HuggingFace confirms GGUF quantizations are available and tested.
- GGUF Q4_K_M at 2.14GB is the right quantization for mobile. Q4_0 at 2.03GB saves 110MB but uses an older quantization method with worse quality. Q5_K_M would be 2.5-2.7GB and likely too large.

**Critical caveat — Flutter binding version lag:**
`llama_cpp_dart` wraps llama.cpp but ships a pinned version of it. The PR adding tiny-aya support (#19611) was merged in February 2025. You must verify that the version of llama.cpp vendored by your chosen Flutter binding is recent enough to include this PR. If not, you will need to either: (a) vendor llama.cpp yourself via FFI, (b) use `fllama` (Telosnex/fllama) which appears to track llama.cpp more closely, or (c) pin to a newer build of llama.cpp and compile via the CMake path.

**iOS-specific warning:**
- Metal GPU backend is NOT supported in the iOS Simulator — test on device.
- When the app is backgrounded during inference, the Metal backend loses access and will crash (llama.cpp issue #16998). You must pause/cancel inference when the app goes to background.
- Apple7 GPU (iPhone 6s and later) is the minimum for Metal. CPU fallback works but will be slow for 3B models.

**Alternative 1: `fllama` (Telosnex/fllama)**
- Also wraps llama.cpp, designed specifically for Flutter production use.
- Supports Metal on iOS and benchmarks at above reading speed on iPhones.
- Requires Android NDK 28, CMake 3.31.0, Android SDK 35 — more setup friction.
- Not recommended as primary only because `llama_cpp_dart` has better pub.dev presence; evaluate both and pick whichever has newer llama.cpp pinning.

**Alternative 2: MediaPipe / `flutter_gemma`**
- Rejected: Only supports Gemma, Phi-2, Falcon, Stable LM natively. Cohere2 architecture is not supported. LiteRT-LM (the next-gen path) does not support iOS yet as of early 2026.

**Alternative 3: ONNX Runtime / `fonnx`**
- User has ONNX experience. However: ONNX Runtime Mobile does not natively support generative LLM token streaming without ORT GenAI, which is a separate stack. ORT GenAI for Flutter has limited examples and no first-class pub.dev package. ONNX is better suited for smaller classification/embedding models than 3B generative LLMs. The Cohere Aya model in safetensors would need export to ONNX format, and 3B+ models in ONNX with GenAI extensions add complexity that does not justify the choice when GGUF + llama.cpp already works for the exact model. Not recommended.

**Alternative 4: MLC-LLM / ExecuTorch**
- Both support mobile inference but have no production-grade Flutter FFI bindings. Would require writing native plugin from scratch. Not recommended for this project.

### Core Framework

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Flutter | 3.41.x (stable, Feb 2026) | Cross-platform mobile framework | Single codebase for iOS + Android. 3.41 is current stable as of Feb 2026. |
| Dart | 3.8+ | Language | Bundled with Flutter 3.41 |

### Inference

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| llama_cpp_dart | Latest (verify pin date) | FFI binding to llama.cpp | GGUF inference, Metal/CPU acceleration |
| GGUF Q4_K_M | — | Model format | 2.14GB, best mobile quality/size tradeoff for 3B models |
| tiny-aya-global-GGUF | Q4_K_M | The actual model | Multilingual 3.35B, Cohere2 arch, 70+ languages |

### Database

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| drift | ^2.31.0 | Chat history persistence | Type-safe SQLite ORM for Dart. Reactive streams, schema migrations, excellent documentation. Best choice for structured chat session data that needs querying, ordering, and potential future features (search, export). |

**Why drift over Isar:** Isar is faster for bulk operations but drift is better for chat history's access patterns (time-ordered queries, session grouping, soft delete, potential full-text search later). Drift's SQL foundation also means you can write raw queries when needed. Isar's future is also uncertain after its v4 restructuring.

**Why drift over sqflite:** Drift is built on sqflite but adds type safety, code generation, and reactive streams. No reason to use raw sqflite.

### State Management

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| flutter_riverpod | ^3.0.0 | App-wide state | Riverpod 3.0 (released Sept 2025) adds offline caching, automatic retry, and mutation support — all relevant for a model-loading app. Better DX than BLoC for a single-developer project. |
| riverpod_annotation | ^3.0.0 | Code generation | Reduces boilerplate |
| riverpod_generator | ^3.0.0 | Build runner codegen | Required for annotations |

### Chat UI

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| flutter_chat_ui | ^2.0.0 | Chat message list and input | Flyer Chat v2 was fully rebuilt in 2025. Backend-agnostic, high-performance, LLM-streaming-ready. Includes `flyer_chat_text_stream_message` for token-streaming display with fade-in animation. |
| flyer_chat_text_stream_message | ^2.0.0 | Streaming token display | First-class streaming support matching the LLM generation pattern |

**Why flutter_chat_ui over dash_chat_2:** flutter_chat_ui v2 has explicit first-class streaming/generative AI support with the `flyer_chat_text_stream_message` companion package. This is purpose-built for the LLM use case. dash_chat_2 would require custom message builders for streaming.

### File Download (First-Launch Model Acquisition)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| background_downloader | ^8.0.0 | Download 2.14GB GGUF on first launch | Uses NSURLSessionDownloadTask on iOS and DownloadWorker on Android — survives app backgrounding, supports resume on failure, progress callbacks. Critical for a 2GB download. |
| path_provider | ^2.1.0 | Resolve model file path | Standard Flutter file path resolution, stores model in `getApplicationDocumentsDirectory()` |

**Why background_downloader over dio:** dio does not survive app backgrounding. A 2GB download over a slow connection could take 10-30 minutes. background_downloader uses platform-native download mechanisms that continue if the user backgrounds the app.

### Connectivity

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| connectivity_plus | ^6.0.0 | Detect online/offline state | Gates the web search toggle feature; gates model download to Wi-Fi; standard Flutter package |

### Settings / Light Persistence

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| shared_preferences | ^2.3.0 | App settings (auto-clear toggle, web search toggle, etc.) | Standard for key-value settings. Not for chat history — that's drift. |

### HTTP (Web URL Translation Feature)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| dio | ^5.7.0 | Fetch URL content for web translation feature | Mature, feature-rich HTTP client. Used only for the online web-page-fetch feature, not for model download. |
| html | ^0.15.0 | Parse HTML to extract text | Strip markup from fetched web pages before feeding to model |

### Internationalization

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| flutter_localizations | bundled | App UI in device locale | Flutter's built-in l10n system is sufficient. App UI language matches device locale per requirements. |
| intl | ^0.20.0 | Date/time formatting for chat timestamps | Standard Dart i18n library |

---

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Inference engine | llama.cpp (GGUF) | ONNX Runtime + ORT GenAI | No first-class Flutter package, complex setup, no streaming out of box |
| Inference engine | llama.cpp (GGUF) | MediaPipe LLM Inference | Cohere2 architecture not supported; LiteRT-LM iOS not ready |
| Inference engine | llama.cpp (GGUF) | MLC-LLM | No Flutter FFI binding |
| Flutter binding | llama_cpp_dart | fllama (Telosnex) | Both valid; fllama has more setup friction but may track llama.cpp closer |
| Database | drift | isar | Drift better for chat's query patterns; Isar future uncertain |
| Database | drift | objectbox | Commercial considerations, drift simpler for open-source project |
| State mgmt | Riverpod 3 | BLoC | Riverpod simpler for solo developer; BLoC overkill |
| Chat UI | flutter_chat_ui v2 | dash_chat_2 | Flyer Chat has first-class streaming support |
| Download | background_downloader | dio | dio doesn't survive backgrounding for 2GB file |

---

## Installation

```yaml
# pubspec.yaml dependencies
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # Inference
  llama_cpp_dart: ^0.4.0   # VERIFY: check llama.cpp pin date includes PR #19611

  # Database
  drift: ^2.31.0
  sqlite3_flutter_libs: ^0.5.0   # Bundles SQLite native libs
  path: ^1.9.0

  # State management
  flutter_riverpod: ^3.0.0
  riverpod_annotation: ^3.0.0

  # Chat UI
  flutter_chat_ui: ^2.0.0
  flyer_chat_text_stream_message: ^2.0.0

  # File management
  background_downloader: ^8.0.0
  path_provider: ^2.1.0

  # Connectivity
  connectivity_plus: ^6.0.0

  # Settings
  shared_preferences: ^2.3.0

  # Online web translation feature
  dio: ^5.7.0
  html: ^0.15.0

  # Utilities
  intl: ^0.20.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  drift_dev: ^2.31.0
  riverpod_generator: ^3.0.0
  custom_lint: ^0.7.0
  riverpod_lint: ^3.0.0
```

```bash
# Android: NDK r28+ required (for 16KB page compliance with llama.cpp native libs)
# In android/local.properties or android/app/build.gradle:
# ndkVersion "28.0.12433566"

# iOS: Extended Virtual Addressing recommended in Xcode capabilities
# pod install or pod update after adding llama_cpp_dart

# Code generation
dart run build_runner build --delete-conflicting-outputs
```

---

## Platform Requirements

### Android
- Minimum SDK: 24 (Android 7.0) — required by llama.cpp Flutter bindings
- Target SDK: 35 (Android 15) — required by Google Play as of Aug 2025
- NDK: r28 or newer — required for 16KB memory page compliance (Google Play mandatory from Nov 1, 2025)
- CMake: 3.31.0 — required by some llama.cpp Flutter bindings
- RAM: 4GB device RAM minimum for 3B Q4 model; 6GB recommended

### iOS
- Minimum: iOS 16.0 (Metal GPU support for llama.cpp; Apple7 GPU minimum)
- Xcode: 16+
- Extended Virtual Addressing: Enable in Xcode project capabilities (helps large model fit in memory)
- Do NOT test inference in iOS Simulator — Metal backend is unavailable there
- App must handle background interrupt: cancel/pause inference when UIApplicationWillResignActive fires

---

## Model Quantization Reference

| Format | Size | Quality | Recommendation |
|--------|------|---------|----------------|
| Q4_K_M | 2.14 GB | Good — "safe default" for mobile | **USE THIS** |
| Q4_0 | 2.03 GB | Lower quality than Q4_K_M | Avoid unless storage critical |
| Q5_K_M | ~2.6 GB | Better quality, near-imperceptible improvement | Too large for bundling; marginal gain |
| Q8_0 | 3.57 GB | Near-lossless | Too large for mobile |
| BF16/F16 | 6.71 GB | Full precision | Desktop only |

Source: CohereLabs/tiny-aya-global-GGUF on HuggingFace

---

## Key Verification Tasks Before Coding

1. **CRITICAL:** Confirm that the version of llama.cpp vendored by `llama_cpp_dart` includes commit for PR #19611 (tiny-aya support, merged Feb 2025). Check the package's `CHANGELOG.md` or the vendored llama.cpp version in its `src/` directory. If it does not, use `fllama` or vendor llama.cpp directly.

2. **CRITICAL:** Validate that `llama_cpp_dart` can actually load and run inference on `tiny-aya-global-Q4_K_M.gguf` on a real Android and iOS device before building the full app. Do this in a minimal test project first.

3. **IMPORTANT:** Decide on model deployment (bundle vs. first-launch download) before committing to any architecture. The current PROJECT.md decision (bundle) conflicts with app store size constraints. Bundling a 2.14GB file in an IPA means the app cannot be installed over cellular (200MB limit). Recommend changing to first-launch download.

4. **IMPORTANT:** Test inference speed on target devices (mid-range Android, recent iPhone). A 3.35B Q4_K_M model should produce 5-15 tokens/second on iPhone 14+ with Metal. Android varies widely by device. Set user expectations in the UI accordingly.

---

## Sources

- [CohereLabs/tiny-aya-global-GGUF — HuggingFace](https://huggingface.co/CohereLabs/tiny-aya-global-GGUF) — GGUF quantization sizes confirmed (HIGH confidence)
- [llama.cpp PR #19611 — Add support for Tiny Aya Models](https://github.com/ggml-org/llama.cpp/pull/19611) — Merged Feb 17, 2025 (HIGH confidence)
- [llama.cpp PR #10900 — Cohere2 architecture support](https://app.semanticdiff.com/gh/ngxson/llama.cpp/commit/46be942214e295cd34660bbbd6b846155d1c36a0) — Base architecture support (HIGH confidence)
- [llama_cpp_dart — pub.dev](https://pub.dev/packages/llama_cpp_dart) — Flutter binding (MEDIUM confidence — version lag unverified)
- [fllama — GitHub (Telosnex)](https://github.com/Telosnex/fllama) — Alternative Flutter binding (MEDIUM confidence)
- [flutter_chat_ui — pub.dev](https://pub.dev/packages/flutter_chat_ui) — Chat UI package v2 (HIGH confidence)
- [flyer_chat_text_stream_message — pub.dev](https://pub.dev/packages/flyer_chat_text_stream_message) — Streaming messages (HIGH confidence)
- [drift — pub.dev](https://pub.dev/packages/drift) — SQLite ORM (HIGH confidence)
- [background_downloader — pub.dev](https://pub.dev/packages/background_downloader) — Resume-capable downloads (HIGH confidence)
- [Flutter Riverpod 3.0 release — riverpod.dev](https://riverpod.dev/docs/whats_new) — Released Sept 2025 (HIGH confidence)
- [What's new in Flutter 3.41 — Flutter blog](https://blog.flutter.dev/whats-new-in-flutter-3-41-302ec140e632) — Current stable (HIGH confidence)
- [Google Play 16KB page requirement — Android Developers](https://developer.android.com/guide/practices/page-sizes) — NDK r28 requirement (HIGH confidence)
- [iOS App Store size limits — Apple Developer](https://developer.apple.com/help/app-store-connect/reference/app-uploads/maximum-build-file-sizes/) — 4GB IPA limit, 200MB cellular limit (HIGH confidence)
- [MediaPipe LLM Inference — Google AI Edge](https://ai.google.dev/edge/mediapipe/solutions/genai/llm_inference/android) — Model support limitations (HIGH confidence)
- [flutter_gemma — GitHub (DenisovAV)](https://github.com/DenisovAV/flutter_gemma) — LiteRT-LM iOS not ready (MEDIUM confidence)
- [llama.cpp Metal backgrounding crash — Issue #16998](https://github.com/ggml-org/llama.cpp/issues/16998) — iOS background pitfall (HIGH confidence)
- [Callstack: Local LLMs on Mobile 2025](https://www.callstack.com/blog/local-llms-on-mobile-are-a-gimmick) — Performance expectations (MEDIUM confidence)
- [Riverpod 3.0 new features — DhiWise](https://www.dhiwise.com/post/riverpod-3-new-features-for-flutter-developers) — Feature summary (MEDIUM confidence)
