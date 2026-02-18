# Architecture Patterns

**Domain:** Offline-first on-device LLM chat/translation app (Flutter, iOS + Android)
**Project:** BittyBot
**Model:** Cohere Tiny Aya Global 3.35B (GGUF, Q4_K_M ~2.14 GB)
**Researched:** 2026-02-19
**Confidence:** MEDIUM-HIGH (FFI+Isolate pattern verified via multiple sources; streaming pattern inferred from package design; KV cache behavior verified from llama.cpp upstream)

---

## Recommended Architecture

### Layer Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        UI Layer                              │
│  ChatScreen / TranslationScreen / HistoryScreen / Settings  │
│  (Flutter Widgets + StreamBuilder for token streaming)       │
└───────────────────────────┬─────────────────────────────────┘
                            │ watches providers (Riverpod)
┌───────────────────────────▼─────────────────────────────────┐
│                   State / Domain Layer                        │
│  ChatNotifier  │  TranslationNotifier  │  SettingsNotifier  │
│  (Riverpod AsyncNotifier / Notifier)                         │
│  Exposes: Stream<String> tokenStream, ChatSession, History   │
└────────────┬──────────────────────────┬──────────────────────┘
             │                          │
┌────────────▼──────────┐  ┌────────────▼──────────────────────┐
│   Inference Repository│  │    History Repository              │
│   (abstract interface)│  │    (abstract interface)            │
└────────────┬──────────┘  └────────────┬──────────────────────┘
             │                          │
┌────────────▼──────────┐  ┌────────────▼──────────────────────┐
│   LLM Service         │  │    Drift DB (SQLite ORM)           │
│   (Inference Worker)  │  │    Messages, Sessions, Settings    │
└────────────┬──────────┘  └───────────────────────────────────┘
             │ Dart Isolate boundary
┌────────────▼──────────────────────────────────────────────────┐
│                   Inference Isolate                            │
│  Spawned once at startup; lives for app lifetime              │
│  Owns: llama_cpp_dart managed context, KV cache               │
│  Communicates via: ReceivePort / SendPort + Stream<String>    │
└────────────┬──────────────────────────────────────────────────┘
             │ dart:ffi calls (synchronous from isolate's thread)
┌────────────▼──────────────────────────────────────────────────┐
│                   Native Layer (C/C++)                         │
│  llama.cpp compiled as:                                        │
│  - iOS: static framework (XCFramework via CocoaPods/CMake)    │
│  - Android: .so via CMake + NDK                               │
│  llama_context, llama_model, llama_batch, llama_sampler       │
└───────────────────────────────────────────────────────────────┘
```

---

## Component Boundaries

| Component | Responsibility | Communicates With | Notes |
|-----------|---------------|-------------------|-------|
| **UI Widgets** | Render chat bubbles, streaming text, input bar | State notifiers via Riverpod watch/listen | Never calls inference directly |
| **ChatNotifier** | Orchestrate user turn → inference → persist flow | LLM Service, History Repository | AsyncNotifier; exposes Stream<String> |
| **TranslationNotifier** | Wrap single-turn translation requests; source/target language state | LLM Service | Thin wrapper; reuses same inference path |
| **SettingsNotifier** | Persist user prefs (language, model params, web search toggle) | Drift DB settings table | |
| **LLM Service** | Manage Inference Isolate lifecycle; route messages; convert port messages to Dart Stream | Inference Isolate via SendPort/ReceivePort | Owns isolate spawn/kill |
| **Inference Isolate** | Run llama.cpp token generation loop; emit tokens via port | LLM Service (parent isolate) | Blocking C calls are safe here; no UI blocked |
| **Inference Repository** | Abstract interface hiding LLM Service impl | ChatNotifier, TranslationNotifier | Allows future swap to cloud backend |
| **History Repository** | Abstract interface for message/session CRUD | ChatNotifier, HistoryScreen | |
| **Drift DB** | SQLite ORM; type-safe queries; reactive streams | History Repository impl, Settings Repository | Single source of truth for persisted data |
| **Model File Manager** | Locate GGUF asset at startup; report model load status | LLM Service | Handles both bundled and post-install-download paths |

---

## Data Flow

### User Message → Streaming Token → Display

```
1. User types message and taps Send
   UI → ChatNotifier.sendMessage(text)

2. ChatNotifier saves user message to DB immediately (optimistic)
   ChatNotifier → HistoryRepository.insertMessage(userMsg)

3. ChatNotifier builds prompt from conversation history
   (system prompt + prior turns + new user message)
   ChatNotifier → LLM Service.generate(prompt, params)

4. LLM Service sends prompt over SendPort to Inference Isolate
   [Dart Isolate boundary crossed via message passing]

5. Inference Isolate calls llama.cpp:
   a. llama_tokenize(prompt)
   b. llama_kv_cache_seq_rm() if starting new session
   c. Loop: llama_decode(batch) → llama_sampler_sample() → emit token
   d. Each token sent back via SendPort to parent isolate

6. LLM Service receives port messages, adds to StreamController<String>
   ChatNotifier listens to this stream, appends to in-progress assistant message

7. UI widget uses StreamBuilder (or Riverpod stream provider) to rebuild
   on each token — displays partial response growing character by character

8. On [EOS] token or stop sequence:
   a. Inference Isolate signals completion
   b. ChatNotifier assembles full response text
   c. History Repository saves assistant message to DB

9. Drift reactive query notifies HistoryScreen automatically
   (no manual refresh needed)
```

### Translation Flow (single-turn, no history)

```
User picks source/target language → types text → taps Translate
TranslationNotifier.translate(text, src, tgt)
→ LLM Service.generate(translationPrompt)
→ Same isolate pipeline as above
→ Result rendered in TranslationScreen (no DB write required unless user saves)
```

### Model Initialization Flow

```
App launch
→ Model File Manager checks for GGUF at known path
  [Bundled: Flutter asset extracted to app documents dir at first launch]
  [Download path: user-initiated download, stored in documents dir]
→ LLM Service.initialize(modelPath, contextSize, nThreads)
→ Spawns Inference Isolate
→ Inference Isolate calls llama_model_load(), llama_new_context_with_model()
→ Reports ready via port
→ ChatNotifier.isModelReady = true
→ UI unlocks input
```

---

## Threading Model (Critical for UX)

### The Core Problem

llama.cpp inference is synchronous and CPU-bound. A 3.35B model at Q4_K_M generates ~4-8 tokens/second on mid-range mobile hardware. Each `llama_decode()` call blocks the calling thread for ~100-250ms. If this runs on the Flutter main thread (or main isolate), the UI freezes.

### Solution: Dedicated Inference Isolate

**Architecture:** Spawn one long-lived Dart Isolate at app startup that owns the llama.cpp context for its entire lifetime.

```dart
// Conceptual structure (not runnable — illustrates pattern)

// In LLM Service (main isolate):
final receivePort = ReceivePort();
final isolate = await Isolate.spawn(_inferenceWorker, receivePort.sendPort);
final workerSendPort = await receivePort.first as SendPort;

// Send inference request:
workerSendPort.send(InferenceRequest(prompt: prompt, replyPort: tokenReceivePort.sendPort));

// Stream tokens back to UI:
tokenReceivePort.listen((token) {
  if (token is String) streamController.add(token);
  if (token == null) streamController.close(); // EOS
});

// In Inference Isolate (_inferenceWorker):
// - Owns llama_context (never shared across isolate boundary)
// - Loops calling llama_decode() synchronously — fine because this isolate has no UI
// - Sends each sampled token string back via SendPort
// - Native C library uses its own internal pthreads for matrix ops (independent of Dart)
```

### Why Isolate (not Platform Channel)

| Approach | Latency | Streaming | Complexity | Recommendation |
|----------|---------|-----------|------------|----------------|
| **Dart Isolate + FFI** | Lowest (no serialization) | Native Dart streams | Medium | **Use this** |
| Platform Channel (MethodChannel) | Higher (JNI/ObjC overhead per token) | Requires EventChannel per stream | High | Avoid for token streaming |
| Compute (isolate.run) | Isolate respawned each call | None — single return | Low | Only for one-shot tasks |

Platform channels are appropriate for capability queries (e.g., "does device support Metal?") and one-shot calls. They are not appropriate for streaming 500-1000 tokens at 4-8 tok/s — the serialization overhead across the channel boundary per token is prohibitive.

### Native Thread Behavior

llama.cpp internally spawns its own pthreads (configurable via `n_threads`). These are OS-level threads entirely outside Dart's knowledge. On Android/iOS, setting `n_threads` to `(physicalCores / 2)` is a safe starting point — using all cores causes thermal throttling on mobile. The Inference Isolate's Dart thread is blocked during `llama_decode()` but that is expected and correct.

### KV Cache Lifecycle

- KV cache lives in the Inference Isolate, inside the llama_context
- It persists across multiple turns in the same conversation session (no reprocessing of history)
- It is lost if the app is backgrounded and iOS/Android kills the process, or if the user explicitly clears conversation
- At context window overflow (Tiny Aya Global has a 4096-token context), use `llama_kv_cache_seq_rm()` to evict old tokens (sliding window) — the first N tokens (system prompt) should be protected from eviction

---

## Patterns to Follow

### Pattern 1: Long-Lived Inference Isolate

**What:** Spawn isolate once, keep alive for app session, reuse llama_context across turns.

**When:** Always — respawning the isolate and reloading the model per message is 10-30 seconds on mobile; unacceptable.

**Key implementation detail:** The isolate sends a "ready" signal via port before accepting inference requests. LLM Service queues requests if isolate is busy (no concurrent inference — llama.cpp context is single-threaded).

```dart
// Isolate lifecycle states:
enum IsolateState { loading, ready, inferring, error }
```

### Pattern 2: Repository Abstraction Over Inference

**What:** `InferenceRepository` interface with `LLamaCppInferenceRepository` implementation.

**When:** Always — allows mocking in tests, and future addition of a cloud fallback (e.g., Cohere API when online).

```dart
abstract interface class InferenceRepository {
  Stream<String> generateStream(String prompt, InferenceParams params);
  Future<void> initialize(String modelPath);
  void dispose();
}
```

### Pattern 3: Drift Reactive Queries for Chat History

**What:** Drift watch() queries return `Stream<List<Message>>` that auto-update on DB writes.

**When:** HistoryScreen and ChatScreen — no manual refresh, no setState polling.

```dart
// Drift watch query auto-notifies UI
Stream<List<Message>> watchSession(String sessionId) =>
    (select(messages)..where((m) => m.sessionId.equals(sessionId)))
        .watch();
```

### Pattern 4: Optimistic UI for Message Send

**What:** Insert user message to DB and display immediately before inference begins. Show typing indicator during inference. Replace with streamed response as tokens arrive.

**When:** Every send — eliminates perceived latency on user turn.

### Pattern 5: Prompt Template Encapsulation

**What:** A `PromptBuilder` class (pure Dart) constructs Aya-format chat prompts from message history, managing context window budget.

**When:** Before every inference call — keeps formatting logic out of UI and out of the isolate.

```
Aya Global chat template (verified from HuggingFace model card):
<BOS_TOKEN><|START_OF_TURN_TOKEN|><|SYSTEM_TURN_TOKEN|>{system}<|END_OF_TURN_TOKEN|>
<|START_OF_TURN_TOKEN|><|USER_TURN_TOKEN|>{user}<|END_OF_TURN_TOKEN|>
<|START_OF_TURN_TOKEN|><|CHATBOT_TURN_TOKEN|>
```

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Calling llama.cpp from Main Isolate

**What:** Invoking `dart:ffi` FFI calls to llama.cpp directly from the main Dart isolate.

**Why bad:** Blocks the UI thread during `llama_decode()`. 100-250ms per decode step = frozen UI, dropped frames, OS watchdog kills.

**Instead:** All FFI calls to llama.cpp must happen inside the dedicated Inference Isolate.

### Anti-Pattern 2: Spawning a New Isolate Per Message

**What:** Using `Isolate.run()` (or `compute()`) for inference — these create a fresh isolate per call.

**Why bad:** Model reload is 10-30 seconds. Isolate creation overhead. KV cache is lost between turns.

**Instead:** One long-lived isolate, one persistent `llama_context`.

### Anti-Pattern 3: Bundling the 2+ GB GGUF in Flutter Assets

**What:** Adding the GGUF file to `pubspec.yaml` assets and shipping it in the app binary.

**Why bad:** iOS App Store enforces 200 MB over-the-air download limit (Wi-Fi required for larger). Android Play Store has a 200 MB APK limit (OBB expansion files are deprecated). App install failures/rejections.

**Instead:** On first launch, download model to app documents directory, or use iOS Background Assets / Android Play Asset Delivery for post-install download. Show a one-time download prompt with size warning.

### Anti-Pattern 4: Storing Full Conversation as Raw Text in llama_context

**What:** Re-encoding entire conversation history as a single string on every message, relying on llama.cpp to process all tokens from scratch.

**Why bad:** At 3.35B parameters, re-encoding 50 previous messages takes seconds per turn. Context window fills quickly.

**Instead:** Keep the llama_context alive across turns (KV cache reuse). Only encode the new user message tokens each turn. Use sliding window eviction when approaching context limit.

### Anti-Pattern 5: Platform Channel for Token Streaming

**What:** Using `EventChannel` to stream tokens from native code to Dart.

**Why bad:** Each token crosses JNI (Android) or ObjC (iOS) bridge with serialization overhead. At 8 tok/s that is 8 bridge crossings/second — tolerable but unnecessary complexity compared to Isolate+FFI.

**Instead:** Use Isolate with SendPort/ReceivePort for token streaming — pure Dart, zero serialization.

### Anti-Pattern 6: Blocking UI on Model Load

**What:** Loading the model synchronously before showing any UI.

**Why bad:** Model load takes 3-10 seconds on mobile. User sees a blank screen.

**Instead:** Show splash/onboarding UI immediately. Load model in background (Inference Isolate). Show progress indicator. Disable input until ready.

---

## Component Build Order (Phase Dependencies)

The dependency graph dictates this build sequence:

```
1. Native Inference Layer (llama.cpp FFI + Isolate)
   └── No Dart dependencies. Must validate tokens/sec on target hardware first.
       Required before: everything else

2. Model File Manager
   └── Requires: understanding of native layer path requirements
       Builds: model bundling strategy, download flow
       Required before: LLM Service initialization

3. LLM Service + Inference Repository Interface
   └── Requires: Native layer (1), Model File Manager (2)
       Builds: Isolate lifecycle, SendPort/ReceivePort wiring, Stream<String> API
       Required before: State layer

4. Drift DB Schema (Messages, Sessions, Settings)
   └── No inference dependency. Can build in parallel with (1-3).
       Required before: History Repository, ChatNotifier

5. ChatNotifier + TranslationNotifier (State Layer)
   └── Requires: LLM Service (3), History Repository (4)
       Builds: full user turn → inference → persist flow
       Required before: UI screens

6. Chat UI + Translation UI
   └── Requires: ChatNotifier (5)
       Builds: streaming chat bubbles, input, language picker

7. History Screen + Settings Screen
   └── Requires: Drift DB (4), SettingsNotifier
       Relatively independent; can build after core chat works

8. Model Download Flow (if not bundled)
   └── Requires: Model File Manager (2)
       Builds: download UI, progress, retry
       Can be deferred if validating with sideloaded model first
```

---

## Scalability Considerations

| Concern | On device (current scope) | If cloud fallback added | Notes |
|---------|--------------------------|------------------------|-------|
| Inference latency | 4-8 tok/s on mid-range hardware; streaming hides perceived latency | Sub-second TTFT from Cohere API | Design `InferenceRepository` interface to swap impl |
| Context window | 4096 tokens (Tiny Aya Global); use sliding window | Cloud models have 128K+ context | PromptBuilder must handle overflow gracefully |
| Model memory | Q4_K_M: ~2.5 GB RAM on device; iOS kills at memory pressure | N/A | Monitor memory; handle `didReceiveMemoryWarning` |
| Concurrent requests | Not applicable (single user, mobile) | Need queue/lock | Single inference queue in LLM Service is sufficient |
| Chat history growth | SQLite scales to millions of rows easily | N/A | Index on session_id and created_at |
| Multi-language support | Tiny Aya Global covers 70 languages natively | Same | No separate translation model needed |

---

## Key Technical Constraints for BittyBot

1. **Model not in app bundle.** Tiny Aya Global Q4_K_M is 2.14 GB. Cannot ship in APK or IPA. Must download post-install to device storage. Plan for a first-launch model download flow with progress UI.

2. **iOS memory pressure.** iOS will kill apps exceeding ~3 GB RAM. With 2.5 GB for model + Flutter runtime + UI, the app is close to the limit on 4 GB devices. Use `n_ctx` = 2048 (not 4096) on low-memory devices. Detect device RAM at runtime.

3. **Inference is single-threaded across turns.** The Inference Isolate processes one request at a time. The LLM Service must queue simultaneous requests (chat and translation cannot run concurrently). This is fine for single-user mobile.

4. **KV cache is session-scoped.** When the app is backgrounded and killed, KV cache is gone. On next session, prior conversation messages must be re-encoded from DB. This is a UX-visible delay (3-10 seconds for long histories). Design the session/context management to minimize this.

5. **Cohere Tiny Aya Global is very new (February 2026).** GGUF compatibility with existing Flutter packages (llama_cpp_dart, fllama, flutter_llama) needs validation — the model's architecture must be supported by the llama.cpp version those packages pin to. This is the highest technical risk item.

---

## Recommended Package Selection

| Package | Role | Recommendation | Confidence |
|---------|------|----------------|------------|
| `llama_cpp_dart` | Primary inference bridge | Recommended: three-level abstraction, Managed Isolate pattern aligns with architecture | MEDIUM |
| `fllama` | Alternative inference bridge | Backup option: GPL licensed, good iOS/macOS support, active maintenance | MEDIUM |
| `flutter_llama` | Alternative inference bridge | Fallback: simpler API, less control over threading | LOW |
| `drift` | SQLite ORM | Recommended: reactive streams, type-safe, active 2025 maintenance | HIGH |
| `riverpod` (v3) | State management | Recommended: AsyncNotifier pattern ideal for async inference state | HIGH |
| `path_provider` | Model file location | Required: get documents directory for model storage | HIGH |
| `dio` or `http` | Model download | For first-launch model download flow | HIGH |

---

## Sources

- [llama_cpp_dart pub.dev](https://pub.dev/packages/llama_cpp_dart) — package architecture, three abstraction levels, Managed Isolate
- [fllama GitHub (Telosnex)](https://github.com/Telosnex/fllama) — iOS/Android FFI integration approach
- [Flutter Concurrency and Isolates (official docs)](https://docs.flutter.dev/perf/isolates) — isolate communication patterns, SendPort/ReceivePort
- [Async messaging Flutter/C++ via NativePort (GitHub Gist)](https://gist.github.com/espresso3389/be5674ab4e3154f0b7c43715dcef3d8d) — FFI NativePort callback pattern
- [Flutter Platform Channels (official docs)](https://docs.flutter.dev/platform-integration/platform-channels) — method channel vs FFI tradeoffs
- [CohereLabs/tiny-aya-global-GGUF (Hugging Face)](https://huggingface.co/CohereLabs/tiny-aya-global-GGUF) — model sizes per quantization (Q4_K_M = 2.14 GB)
- [Cohere Tiny Aya launch (TechCrunch, Feb 2026)](https://techcrunch.com/2026/02/17/cohere-launches-a-family-of-open-multilingual-models/) — model family overview
- [MarkTechPost Tiny Aya (Feb 2026)](https://www.marktechpost.com/2026/02/17/cohere-releases-tiny-aya-a-3b-parameter-small-language-model-that-supports-70-languages-and-runs-locally-even-on-a-phone/) — on-device suitability
- [Flutter Drift complete guide (AndroidCoding, Sep 2025)](https://androidcoding.in/2025/09/29/flutter-drift-database/) — Drift reactive query patterns
- [Offline-first Flutter with Drift (Medium, Nov 2025)](https://777genius.medium.com/building-offline-first-flutter-apps-a-complete-sync-solution-with-drift-d287da021ab0) — offline-first architecture
- [Flutter offline-first design pattern (official docs)](https://docs.flutter.dev/app-architecture/design-patterns/offline-first) — repository pattern for offline
- [Building AI-powered mobile apps 2025 (Medium)](https://medium.com/@stepan_plotytsia/building-ai-powered-mobile-apps-running-on-device-llms-in-android-and-flutter-2025-guide-0b440c0ae08b) — end-to-end on-device LLM guide
- [KV cache reuse llama.cpp discussion](https://github.com/ggml-org/llama.cpp/discussions/7698) — KV cache session persistence behavior
- [llama.cpp: Harnessing via Dart FFI Gen (Medium, Feb 2025)](https://medium.com/@WBB2500/unleashing-llama-cpp-harnessing-llama-cpp-through-dart-ffi-gen-c7b1606cf0a7) — FFI binding generation approach
- [iOS App Store size limits (Apple Developer)](https://developer.apple.com/help/app-store-connect/reference/app-uploads/maximum-build-file-sizes/) — 200 MB cellular download limit
