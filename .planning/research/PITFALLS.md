# Domain Pitfalls

**Domain:** On-device LLM mobile app (Flutter, offline multilingual translation/chat)
**Project:** BittyBot — Tiny Aya Global 3.35B, iOS + Android
**Researched:** 2026-02-19

---

## Critical Pitfalls

Mistakes that cause rewrites, store rejections, or make the app fundamentally unusable.

---

### Pitfall 1: Cohere2 Architecture Not Recognized by Inference Runtime

**What goes wrong:** The Tiny Aya Global model uses the `cohere2` architecture (3 sliding window attention layers + 1 global attention layer — an interleaved hybrid that is not a standard transformer). Older or unpinned versions of llama.cpp do not recognize the `cohere2` architecture enum and throw a load error at runtime. A GitHub issue on `llama-cpp-python` (#1893) specifically documents this: "cohere2 architecture is not recognized." The model file loads fine but inference silently fails or hard-crashes.

**Why it happens:** llama.cpp added Cohere Command-R support incrementally (PR #6491 added Command R Plus; cohere2/Command-R7B support came later). The interleaved sliding window + global attention pattern also required a separate feature flag (`sliding window attention`, tracked in llama.cpp issue #3377 and #12637 for Gemma 2's similar layout). Flutter plugins that vendor a pinned llama.cpp build may be months behind.

**Consequences:** App compiles and ships. On first inference attempt, model fails to load or crashes the process. Complete loss of core functionality with zero graceful fallback path.

**Prevention:**
1. Verify cohere2 architecture works with the specific llama.cpp version vendored by your chosen Flutter plugin *before* writing any application code. Run a standalone llama.cpp CLI test against `tiny-aya-global-Q4_K_M.gguf` on both iOS and Android.
2. Pin llama.cpp to a version confirmed to work with cohere2. Do not accept "latest" from a plugin.
3. If using `fllama` or `llama_cpp_dart`, open the vendored `llama.cpp` submodule and check the `llm_arch` enum for `COHERE2` or equivalent.

**Detection (warning signs):**
- Inference returns immediately with empty output
- Native crash log contains "unknown model architecture" or similar
- llama.cpp log shows `error: unknown arch` at model load time

**Phase:** Address in Phase 1 (Proof of Concept / Inference Spike) — *do this first, before any UI work*
**Severity:** CRITICAL — if this fails and cannot be resolved, the entire project's approach must change

---

### Pitfall 2: iOS Memory Limit Kills App With 2GB Model in RAM

**What goes wrong:** iOS has no swap space and uses a priority-based jetsam process to kill apps under memory pressure. A Q4_K_M quantized Tiny Aya Global weighs ~2.14 GB on disk, but loading it into memory for inference requires the full weight tensor resident in RAM plus KV-cache overhead. On iPhones with 6 GB RAM (iPhone 14/15 base), the OS + system services + Flutter engine consume 1-2 GB before your app starts. The model alone may exhaust available headroom, triggering jetsam.

**Why it happens:** iOS reports no hard per-app memory limit — the actual ceiling depends on device model, OS version, and concurrent memory pressure. The `com.apple.developer.kernel.increased-memory-limit` entitlement exists but: (a) only works on supported devices, (b) may not take effect in App Store distribution environments, and (c) even with it, KV-cache for an 8K context window adds hundreds of MB on top of model weights.

**Consequences:** App crashes mid-conversation with no user-visible error. iOS jetsam kills it silently. The user sees the app disappear or reset to a blank state. Particularly bad if it happens after 30+ seconds of inference on a long prompt.

**Prevention:**
1. Default context window to 2048 tokens maximum, not the model's theoretical 8K limit. Each token in the KV cache costs memory at runtime.
2. Request the `com.apple.developer.kernel.extended-virtual-addressing` entitlement (expands virtual address space, helps with large models even if physical memory is unchanged).
3. Register `didReceiveMemoryWarning` and unload model weights proactively when the app enters background.
4. Test on the lowest-spec target device (iPhone 12, 4 GB RAM) with a memory pressure simulation.
5. Q4_0 (2.03 GB) is slightly smaller than Q4_K_M (2.14 GB); consider if the 110 MB saving matters for marginal devices.

**Detection (warning signs):**
- App crashes reproducibly on lower-RAM devices but not on newer ones
- iOS device console shows `Jetsam: Termination reason: memory limit exceeded`
- Model loads fine but crashes appear after the first full-length inference pass

**Phase:** Phase 1 (Spike), validated again in Phase 2 (iOS integration)
**Severity:** CRITICAL for older/budget devices, HIGH for modern flagships

---

### Pitfall 3: Google Play / App Store App Size Distribution Problem

**What goes wrong:** Bundling the model directly in the app produces a 2+ GB download. Google Play's compressed download limit for an app bundle is 200 MB; total uncompressed install size can reach 4 GB but the *download* barrier is the user-facing problem. Apple's App Store allows apps up to 4 GB (increased with iOS 18 from 2 GB), but a 2 GB over-the-air download will trigger App Store warnings and many users simply cannot or will not download it on a metered connection.

**Why it happens:** GGUF model files are already compressed binary data — they do not compress further in a ZIP or APK. Google Play's dynamic delivery cannot split a file that is treated as a raw asset. Apple's "On-Demand Resources" is legacy technology (the recommended replacement is "Background Assets," which requires network connectivity — contradicting the offline-first requirement).

**Consequences:**
- Android: Play Store may reject the APK/AAB if the model asset causes the base module to exceed limits.
- iOS: 2 GB cellular download warning dialog appears; users with limited data plans abandon the download.
- Both: Users who do download may immediately uninstall if they don't understand why 2 GB was consumed.

**Prevention:**
1. For Android, use APK Expansion Files (OBB format) or Play Asset Delivery to deliver the model as an install-time asset pack separate from the base APK. This keeps the base APK small while the model delivers post-install.
2. For iOS, bundle the model directly in the IPA (acceptable under 4 GB App Store limit) but add clear pre-download messaging about storage requirements.
3. Add in-app storage check on first launch: if available storage < 3 GB, show a warning before attempting to load the model.
4. Build clear onboarding copy: "This app includes an AI model (2 GB). Make sure you're on Wi-Fi before downloading."

**Detection (warning signs):**
- Play Console upload rejects AAB with asset size error
- TestFlight install size appears as 2+ GB in App Store Connect
- Android: `adb install` fails with "INSTALL_FAILED_INSUFFICIENT_STORAGE" on test devices

**Phase:** Phase 2 (Platform integration) — research Play Asset Delivery early; it changes project structure
**Severity:** HIGH — affects every user before they even open the app

---

### Pitfall 4: Flutter Plugin Linking Failures (Static vs. Dynamic Libraries on iOS)

**What goes wrong:** A documented failure log from May 2025 describes the core problem: building llama.cpp for iOS produces multiple interdependent `.dylib` files (`ggml.dylib`, `ggml-base.dylib`, `ggml-cpu.dylib`, `libllama.dylib`, `libcommon.dylib`). You cannot extract just `libllama.dylib` — the dependency chain causes duplicate symbols. Adding all five `.dylib` files to a Flutter plugin causes symbol conflicts and link failures. The only reliable option is static linking, which has its own constraints: it increases binary size and complicates build reproducibility.

**Why it happens:** Flutter's Dart FFI layer expects a specific linking model. iOS's Metal GPU backend for llama.cpp requires additional framework linkages. iOS Simulator does not support Metal's SIMD-scoped operations, so the plugin crashes on Simulator — meaning you cannot test on Simulator at all, only on physical devices.

**Consequences:**
- iOS build fails at link time with cryptic duplicate symbol errors
- Simulator testing is completely blocked; all testing requires physical device
- Build time increases significantly due to static linking of ONNX/llama.cpp C++ code

**Prevention:**
1. Choose one of the pre-built Flutter packages (`fllama` by Telosnex, `llama_cpp_dart` by netdur, or `flutter_llama`) and test it immediately on a physical iOS device as the Phase 1 spike. Do not assume it works.
2. Pin to static library builds on iOS (`use_frameworks! :linkage => :static` in Podfile may be needed).
3. Set up a physical device CI/testing workflow from day one — do not plan on Simulator for any inference testing.
4. Confirm the package requires Apple A7 GPU minimum (A7 is iPhone 5s era; any currently shipping device is well beyond this, but simulator is excluded).

**Detection (warning signs):**
- `pod install` produces warnings about conflicting dynamic libraries
- Build fails with `duplicate symbol _ggml_*` linker errors
- App runs on Simulator but crashes immediately on device (or vice versa)

**Phase:** Phase 1 (Spike), specifically the iOS side of the proof-of-concept
**Severity:** HIGH — can block entire iOS track if not discovered early

---

### Pitfall 5: Android 16KB Page Size Compliance Blocking Play Store

**What goes wrong:** Starting May 31, 2026, all apps on Google Play must support Android's 16 KB memory page size (required for Android 15+ devices). The issue is not Flutter itself — Flutter 3.24+ is already compliant. The issue is any native `.so` library inside a dependency (including llama.cpp FFI bindings) that was compiled without 16 KB page alignment. A non-compliant `.so` causes crashes on Android 15+ devices and will fail Play Console validation before the deadline.

**Why it happens:** 16 KB alignment must be baked into `.so` files at compile time using NDK R27+. llama.cpp Flutter plugin packages that vendor pre-compiled `.so` files compiled against older NDKs will be non-compliant. The check `abiFilters` in Gradle will not catch this.

**Consequences:** App crashes on all Android 15+ devices with modern chips (Snapdragon 8 Gen 3+). Play Store starts rejecting uploads after May 31, 2026.

**Prevention:**
1. When selecting a Flutter llama.cpp plugin, verify it specifies NDK R27+ (28+ preferred) and was built with 16 KB alignment.
2. In `build.gradle`: ensure `android.ndkVersion` is at least `28.0.12433566`.
3. Use the Android Studio APK Analyzer or `readelf -l` to check `.so` file alignment before shipping.
4. Test on an Android 15 emulator configured for 16 KB page size.

**Detection (warning signs):**
- Play Console upload shows "native libraries not compatible with 16KB page size" warning
- App crashes on Pixel 9 / Snapdragon 8 Gen 3 devices but runs on older hardware
- `readelf -l libllamacpp.so | grep LOAD` shows alignment less than `0x4000`

**Phase:** Phase 2 (Android integration), verify before any Play Store submission
**Severity:** HIGH — hard deadline blocks distribution entirely after May 2026

---

## Moderate Pitfalls

---

### Pitfall 6: Inference Blocks Flutter UI Thread (Jank / Frozen UI)

**What goes wrong:** llama.cpp inference is a synchronous CPU-intensive operation. If called from the main Dart isolate, it blocks the Flutter rendering thread, causing the UI to freeze for the entire duration of inference — which can be 30-120 seconds for a long response on a mid-range device. The user sees a completely frozen app with no progress indicator.

**Why it happens:** Flutter runs all Dart code in the main isolate by default. Even with `async`/`await`, pure Dart async does not move CPU work off the main thread. The FFI call into llama.cpp is synchronous from Dart's perspective. As of Flutter 3.32 (May 2025), iOS and Android merge the platform and UI threads by default, which actually makes this worse — blocking in a plugin callback now blocks the renderer too.

**Prevention:**
1. Run all llama.cpp inference inside a `dart:isolate` spawned worker, communicating results back via `SendPort`/`ReceivePort`.
2. Use token streaming: llama.cpp generates one token at a time. Send each token back to the UI isolate via a `Stream` so the UI updates progressively.
3. `fllama` and `llama_cpp_dart` both claim to handle isolate management — verify this in the selected package before building the chat UI.

**Detection (warning signs):**
- App appears frozen during inference; "ANR" warning on Android
- Flutter DevTools shows main isolate spending 100% of time in a single long frame

**Phase:** Phase 1 (Spike) and Phase 3 (Chat UI)
**Severity:** MEDIUM-HIGH — severely damages UX but does not break core functionality

---

### Pitfall 7: Quantization Quality Loss Destroys Multilingual Performance

**What goes wrong:** Q4_0 (the smallest Tiny Aya Global GGUF at 2.03 GB) uses a simpler quantization scheme than Q4_K_M (2.14 GB). The quality difference is model-dependent. For Tiny Aya Global specifically, this matters more than for typical English-only models because: (a) low-resource languages (African scripts, Southeast Asian scripts) are more sensitive to precision loss than English, and (b) the tokenizer inefficiency for non-Latin scripts (2-3x tokens per word) means any quality degradation per-token compounds faster.

**The "copy of a copy" risk:** If the model is quantized from a lossy intermediate format (F16 quantized from BF16, then GGUF Q4 from F16), rounding errors compound and the Q4 result is meaningfully worse than if quantized from BF16 directly. The official CohereLabs GGUF on HuggingFace (CohereLabs/tiny-aya-global-GGUF) should be the direct BF16 → Q4 conversion — use the official GGUF, not third-party re-quantizations.

**Prevention:**
1. Use only `CohereLabs/tiny-aya-global-GGUF` from HuggingFace — not re-quantizations by third parties.
2. Use `Q4_K_M` (2.14 GB) not `Q4_0` (2.03 GB) — the K-quant variant is more stable for multilingual and less sensitive to imatrix quality.
3. Test translation quality across at least 5 language families (Latin, Arabic/RTL, CJK, South Asian, African) before declaring the quantization acceptable.
4. Keep `Q8_0` (3.57 GB) as a fallback for devices with ≥6 GB RAM and adequate storage headroom.

**Detection (warning signs):**
- Thai, Arabic, or Amharic translations are noticeably worse than BF16 baseline
- The model "forgets" the target language mid-response
- Instruction following degrades (e.g., ignores "translate to Spanish" instruction)

**Phase:** Phase 1 (Spike) — test quantization quality before building anything else
**Severity:** MEDIUM — likely acceptable with Q4_K_M, but must be empirically verified

---

### Pitfall 8: Cold Start / Model Load Time Creates a Terrible First Impression

**What goes wrong:** Loading a 2 GB GGUF from device storage into RAM takes 10-40+ seconds depending on device storage speed. On slower Android devices with eMMC storage (not UFS), or on Huawei devices with Kirin SoCs, worst-case loading exceeds 40 seconds. If the app shows nothing (black screen or splash screen) for 40 seconds, users will force-quit before inference ever begins.

**Why it happens:** The model file must be read from flash storage and copied into RAM. Flash storage read bandwidth on mobile ranges from 200 MB/s (older eMMC) to 3 GB/s (NVMe-class UFS 4.0). A 2 GB model on slow storage = 10 seconds minimum, with overhead pushing it to 20-40s on budget devices.

**Prevention:**
1. Show a dedicated "Loading AI model..." screen with a progress bar or animation immediately on app launch. Do not attempt to show the chat interface until the model is ready.
2. Load the model on a background isolate so the UI remains responsive during loading.
3. Consider lazy loading: show the chat input immediately but disable it with a "Model loading..." overlay; complete the load in the background.
4. Measure cold start time on the lowest-spec target device (4 GB RAM, eMMC storage).

**Detection (warning signs):**
- App launch to first-ready state exceeds 10 seconds in testing
- Users report the app "does nothing" for the first 30 seconds

**Phase:** Phase 1 (Spike) to measure, Phase 3 (UI) to implement loading UX
**Severity:** MEDIUM — makes first experience very poor but does not break the app

---

### Pitfall 9: Token-per-Second Expectations vs. Reality on Older Devices

**What goes wrong:** High-end 2025-2026 phones (iPhone 17 Pro: ~136 tok/s, Galaxy S25 Ultra: ~91 tok/s) make on-device inference feel fast. But mid-range and older devices are dramatically slower: Armv8-A Android CPUs without specialized instructions achieve 2-4 tok/s with a 3B model. At 3 tok/s, a 150-token response (a short paragraph) takes 50 seconds. This is objectively unusable if the UI implies ChatGPT-like speed.

**Why it happens:** The model's matrix-multiplication operations are bandwidth-bound on mobile DRAM. Modern Apple chips have unified memory with very high bandwidth; Android varies wildly. CPU frequency throttling also kicks in after sustained inference, further reducing speed over time.

**Prevention:**
1. Implement token streaming from day one — display each token as it arrives rather than waiting for the full response. Even at 3 tok/s, users see immediate progress.
2. Set explicit device requirements: minimum iPhone XS (A12 Bionic) for iOS; Android with 6 GB RAM and Armv9-A CPU for acceptable performance.
3. Add a one-time "speed benchmark" on first launch that measures tok/s and shows a realistic expectation: "Your device can generate approximately X words per minute."
4. Design response length defaults conservatively: translation of a sentence should be 20-50 tokens, not 200.

**Detection (warning signs):**
- Testing on a 3-year-old mid-range Android device shows inference speed under 5 tok/s
- Continuous inference (20+ seconds) triggers thermal throttling, reducing speed by 30-50%

**Phase:** Phase 1 (Spike) — measure actual tok/s across device classes; Phase 3 (UI) — implement streaming
**Severity:** MEDIUM — manageable with streaming UX, catastrophic without it

---

### Pitfall 10: Chat History Context Window Exhaustion With Silent Truncation

**What goes wrong:** Tiny Aya Global supports 8K context. Including full conversation history in every inference call is natural for a chat app, but after a long session, the context fills up. Naive truncation (drop the oldest messages) breaks translation context: if message 1 established "we're translating from Japanese to English" and that message is dropped, subsequent messages lose their framing. The model may silently switch languages, refuse to answer, or produce garbage output.

**Why it happens:** Every token in the chat history consumes context window space AND adds to KV cache memory usage (RAM). An 8K context with Q4 quantization adds hundreds of MB of KV cache on top of model weights.

**Prevention:**
1. Default context window to 2048-4096 tokens, not 8192. This limits KV cache memory and forces a discipline of concise prompts.
2. Implement a sliding window: always include the system prompt + last N turns + the current message; drop middle turns first.
3. Alternatively, summarize old turns into a "session summary" that stays in context.
4. Never silently truncate — if history must be pruned, show the user a subtle indicator ("Earlier messages not included").

**Detection (warning signs):**
- Model "forgets" the target language after a long session
- llama.cpp returns an error about context length exceeded
- Response quality degrades after 10+ message exchanges

**Phase:** Phase 3 (Chat UI) and Phase 4 (Chat persistence)
**Severity:** MEDIUM — degrades UX gradually, not immediately obvious

---

### Pitfall 11: Battery Drain and Thermal Throttling During Sustained Use

**What goes wrong:** Sustained LLM inference on mobile runs the CPU/GPU at near-maximum utilization, consuming 8-10 W continuously. A typical smartphone battery is 15-20 Wh. Running inference continuously drains the battery in 1.5-2.5 hours and causes the device to heat significantly. Thermal throttling reduces inference speed by 30-50% after 5-10 minutes of sustained use. The device may also warn the user about heat.

**Prevention:**
1. Do not run inference in a tight loop — only run when the user submits a message.
2. Cancel/interrupt inference immediately when the app enters background (do not continue generating when the screen is off).
3. Implement inference cancellation (a "stop" button) so users can halt a runaway long response.
4. Test a "travel session" scenario: 30 minutes of continuous use, check device temperature and inference speed degradation.

**Detection (warning signs):**
- Device becomes noticeably warm after 5-10 minutes of use
- Inference speed drops from initial measurement after sustained use
- Battery percentage drops 10%+ per 15 minutes of active inference

**Phase:** Phase 3 (Chat UI) — add cancellation; Phase 5 (Polish) — thermal testing
**Severity:** MEDIUM — worsens with sustained use; acceptable for typical short translation queries

---

## Minor Pitfalls

---

### Pitfall 12: Flutter Impeller Rendering Breaks Arabic/RTL Text Display

**What goes wrong:** Flutter's Impeller rendering backend (default on iOS since Flutter 3.10, Android since 3.16) has known issues with Arabic text rendering (Flutter issue #119805). Arabic characters may fail to render or appear incorrectly when Impeller is active. Since Tiny Aya serves Arabic, Hebrew, and other RTL languages, this directly affects output display.

**Prevention:**
1. Test Arabic output rendering on both Impeller and Skia backends.
2. If Impeller has rendering issues with Arabic text, add `--no-enable-impeller` as a fallback option (available in AndroidManifest.xml and Info.plist).
3. Use `Directionality` widgets correctly for all model output: detect RTL languages in output and wrap accordingly.
4. Check Flutter issue tracker before filing a new bug — this is a known issue with ongoing fixes.

**Phase:** Phase 3 (Chat UI)
**Severity:** LOW-MEDIUM — affects Arabic/Hebrew users specifically; not a crash but visibly broken output

---

### Pitfall 13: Prompt Formatting Mismatch Produces Garbage Output

**What goes wrong:** Tiny Aya Global is an instruction-tuned model with a specific prompt template (likely Cohere's chat template format). If the Flutter app constructs raw prompts without proper `<BOS>`, user/assistant role tokens, and system prompt formatting, the model receives malformed input and produces incoherent, repetitive, or off-topic output. This is not a quantization problem — it looks like quantization quality loss but is actually a prompt format bug.

**Prevention:**
1. Read the Cohere Tiny Aya documentation for exact prompt format. Verify using the HuggingFace model card.
2. Implement the tokenizer's chat template exactly — including special tokens (BOS, EOS), role markers, and system prompt placement.
3. Test with a known-good prompt and verify the output matches what the HuggingFace inference demo produces.

**Phase:** Phase 1 (Spike)
**Severity:** LOW — easy to fix once identified, but confusing to debug if mistaken for quantization issues

---

### Pitfall 14: Model File Corruption During App Update

**What goes wrong:** If the model is bundled in the app binary and the OS performs a partial update (killed mid-install), the model file on disk may be corrupted. Loading a corrupted GGUF causes llama.cpp to either crash or produce nonsense output. There is no built-in integrity check in most Flutter plugin wrappers.

**Prevention:**
1. Compute and store a SHA-256 hash of the bundled model at build time. On each app launch, verify the hash matches before attempting to load.
2. If verification fails, show an error prompting the user to reinstall the app (or re-download the model if using deferred delivery).
3. This is especially important for Android where OBB/Play Asset Delivery files can be delivered separately.

**Phase:** Phase 2 (Platform integration)
**Severity:** LOW — rare event but catastrophic when it occurs; trivial to prevent

---

### Pitfall 15: Non-Latin Script Token Overhead Slows Inference Disproportionately

**What goes wrong:** Tiny Aya's tokenizer, like most BPE tokenizers, allocates tokens unevenly across scripts. Thai can produce 2-3x more tokens per word than English. This means a "short" Thai translation query may actually be 2-3x as long in tokens as it appears, consuming more context window and taking proportionally longer to process. Users of Thai, Arabic, or Tibetan may experience noticeably slower responses than English users for equivalent text lengths.

**Prevention:**
1. When displaying a token count or context usage indicator, compute actual token count rather than estimating from character count.
2. Adjust maximum-response-length defaults based on the script being used if token budget becomes a concern.
3. This is an inherent model limitation — document it honestly rather than trying to paper over it.

**Phase:** Phase 3 (Chat UI)
**Severity:** LOW — performance difference is real but not actionable beyond documentation

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|----------------|------------|
| Runtime selection / first inference spike | Cohere2 arch not recognized (Pitfall 1) | Test llama.cpp CLI against actual GGUF before writing any app code |
| iOS integration | Memory exhaustion / jetsam (Pitfall 2) | Test on iPhone 12 (4 GB RAM) with memory pressure simulation |
| iOS integration | Static linking failures (Pitfall 4) | Verify chosen Flutter plugin on physical device, not Simulator |
| Android integration | 16 KB page size compliance (Pitfall 5) | Verify NDK R28+, test on Android 15 emulator |
| App distribution / packaging | App store size limits (Pitfall 3) | Research Play Asset Delivery early; it affects project structure |
| Chat UI | UI thread blocking (Pitfall 6) | All inference must run in a Dart isolate with token streaming |
| Chat UI | RTL text rendering (Pitfall 12) | Test Arabic output on physical iOS device with Impeller enabled |
| Chat UX | Inference speed expectations (Pitfall 9) | Implement streaming immediately; benchmark on mid-range Android |
| Chat session persistence | Context window exhaustion (Pitfall 10) | Design truncation/sliding window strategy before implementing history |
| Quality testing | Quantization quality for low-resource languages (Pitfall 7) | Test against Arabic, Thai, Amharic before accepting Q4_K_M |
| App updates | Model file corruption (Pitfall 14) | SHA-256 integrity check on every launch |

---

## Sources

**Architecture / Runtime Compatibility:**
- [cohere2 architecture issue — llama-cpp-python #1893](https://github.com/abetlen/llama-cpp-python/issues/1893)
- [llama.cpp sliding window attention issue #3377](https://github.com/ggml-org/llama.cpp/issues/3377)
- [Interleaved sliding window attention feature request #12637](https://github.com/ggml-org/llama.cpp/issues/12637)
- [CohereLabs/tiny-aya-global-GGUF on HuggingFace](https://huggingface.co/CohereLabs/tiny-aya-global-GGUF)

**iOS Memory:**
- [iOS Increased Memory Limit Entitlement — Apple Developer Docs](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.kernel.increased-memory-limit)
- [App Crashes Due to Memory Limits — Apple Developer Forums](https://developer.apple.com/forums/thread/770868)
- [Increased Memory Limit, Extended Virtual Addressing — Apple Developer Forums](https://developer.apple.com/forums/thread/777370)

**App Size / Distribution:**
- [Maximum build file sizes — App Store Connect](https://developer.apple.com/help/app-store-connect/reference/app-uploads/maximum-build-file-sizes/)
- [Optimize app size — Google Play Console](https://support.google.com/googleplay/android-developer/answer/9859372)
- [Developers can create larger apps with iOS 18 — 9to5Mac](https://9to5mac.com/2024/06/24/larger-apps-games-ios-18-tvos-18/)

**Flutter / FFI Integration:**
- [Fail Log: Flutter llama.cpp on iOS — Medium, May 2025](https://medium.com/@developerha0013/fail-log-flutter-llama-cpp-on-ios-82b06c442cba)
- [fllama — Telosnex, GitHub](https://github.com/Telosnex/fllama)
- [llama_cpp_dart — pub.dev](https://pub.dev/packages/llama_cpp_dart)
- [Flutter Isolates documentation](https://docs.flutter.dev/perf/isolates)
- [Blocking the platform thread causes UI freeze — flutter/flutter #22024](https://github.com/flutter/flutter/issues/22024)

**Android 16KB Page Size:**
- [Preparing Flutter Apps for Android 15's 16 KB page size — Medium](https://faheem-riaz.medium.com/preparing-your-flutter-app-for-android-15s-16-kb-page-size-requirement-b07b3dbfbdd1)
- [Android 16KB page size support — flutter/flutter #174640](https://github.com/flutter/flutter/issues/174640)
- [Google Play 16 KB deadline — Android Developers Blog](https://android-developers.googleblog.com/2025/05/prepare-play-apps-for-devices-with-16kb-page-size.html)

**Inference Performance:**
- [Are Local LLMs on Mobile a Gimmick? — Callstack, 2025](https://www.callstack.com/blog/local-llms-on-mobile-are-a-gimmick)
- [On-Device LLMs: State of the Union, 2026](https://v-chandra.github.io/on-device-llms/)
- [Cactus v1: Cross-Platform LLM Inference on Mobile — InfoQ, Dec 2025](https://www.infoq.com/news/2025/12/cactus-on-device-inference/)
- [LLM Performance on Mobile Devices — arXiv 2410.03613](https://arxiv.org/html/2410.03613v3)

**Quantization:**
- [Practical GGUF Quantization Guide for iPhone — Enclave AI, Nov 2025](https://enclaveai.app/blog/2025/11/12/practical-quantization-guide-iphone-mac-gguf/)
- [Optimizing LLMs Using Quantization for Mobile — arXiv 2512.06490](https://arxiv.org/html/2512.06490v1)
- [Blind testing different quants — llama.cpp Discussion #5962](https://github.com/ggml-org/llama.cpp/discussions/5962)

**Flutter RTL:**
- [Impeller Arabic text rendering issue — flutter/flutter #119805](https://github.com/flutter/flutter/issues/119805)
- [Right to Left in Flutter Apps — LeanCode](https://leancode.co/blog/right-to-left-in-flutter-app)

**Battery / Thermal:**
- [On-Device or Remote? Energy Efficiency — CAIN 2025](http://www.ivanomalavolta.com/files/papers/CAIN_2025.pdf)
- [Understanding LLMs in Your Pocket — arXiv 2410.03613v3](https://arxiv.org/html/2410.03613v3)
