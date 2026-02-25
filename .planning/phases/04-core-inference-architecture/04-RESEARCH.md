# Phase 4: Core Inference Architecture - Research

**Researched:** 2026-02-25
**Domain:** Dart Isolate inference pipeline, llama_cpp_dart managed isolate, Drift DB schema, Riverpod provider graph
**Confidence:** HIGH (stack is confirmed from Phase 1 spike; architecture patterns verified against Dart official docs and library source)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**System prompt & model persona:**
- Translation screen: "translate and reply with only the translation, plus a brief note about formality/context when relevant." Concise, copy-pasteable.
- Chat screen: Translator-first persona. System prompt anchors on translation/language help.
- Soft guardrails: Gently steers toward translation; never refuses outright.
- System prompt language: English only for now.
- Two system prompts total — one translation mode, one chat mode.
- Keep prompts very short and directive (3.35B models ignore complex instructions).

**Request lifecycle:**
- Queueing: New requests queue behind active generation. Complete current response first, then auto-start next.
- Stop button: Keeps partial output with truncation indicator ("..." or subtle "stopped" badge).
- Processing indicator: Pulsing BittyBot avatar while model processes prompt (pre-first-token). Disappears when first token arrives.

**Context window management:**
- nCtx: 2048 tokens. Fixed, not user-configurable.
- nPredict: Translation = 128 tokens. Chat = 512 tokens.
- nBatch: 256 default. Internal toggle for 512 (dev/testing only, not exposed).
- Context full behavior: Prompt user to start new session. Offer carry-forward of last 3 exchanges.
- Translation context: Accumulates within session (not independent one-shots). Enables terminology consistency.
- RAM awareness: Profile memory usage; conservative context limit. BittyBot must not monopolize device RAM.

**Startup & recovery:**
- First launch: Full Phase 2 download + load overlay (greyscale-to-color). Blocked until ready.
- Subsequent launches: Partial access — chat history and settings browsable. Input field disabled until model ready.
- Crash recovery: Toast/snackbar ("Inference interrupted") + user input preserved for retry. Model auto-reloads in background.
- Crash circuit breaker: Auto-restart after crash. Track consecutive failure count. After repeated failures, stop retrying, surface error, log, wait for user action.
- Background kill recovery: "Reloading model..." banner. Input disabled. Chat history intact from Drift DB.

### Claude's Discretion

- Isolate communication protocol (SendPort/ReceivePort vs stream-based)
- Riverpod provider structure and dependency graph
- Drift schema design (tables, indices, migration strategy)
- PromptBuilder implementation details
- Exact crash counter threshold for circuit breaker
- Loading state animations and transitions

### Deferred Ideas (OUT OF SCOPE)

- Educational mode toggle (translation + pronunciation guide) — Phase 5 or settings
- Localized system prompts — revisit if English causes quality issues
- User-configurable nCtx — hidden advanced setting only if power users request it
</user_constraints>

---

## Summary

Phase 4 builds the production inference pipeline that all UI phases (5-9) wire into. The critical architectural decision is how Dart isolates communicate with the Flutter main thread. The Phase 1 spike proved the `Llama` class from `llama_cpp_dart` works on-device, but used it synchronously on the main thread — causing ANR kills during extended multilingual tests. Phase 4 must move inference to a long-lived background isolate.

The `llama_cpp_dart` package already provides a managed isolate abstraction (`LlamaParent`/`LlamaChild`) via its `typed_isolate` dependency. However, this built-in abstraction uses `ChatMLFormat` templates and may not accommodate the Aya-specific chat template natively. The safer, fully-controlled approach is to use the raw `Llama` class directly inside a hand-rolled long-lived isolate, which the spike already demonstrated working. The Phase 1 `ModelLoader` helper provides a verified pattern: `ContextParams`, `ModelParams` with `nGpuLayers=0`, `mainGpu=-1`, `useMemorymap=false`.

The Riverpod provider graph has a clear shape: `modelReadyProvider` (keepAlive AsyncNotifier) owns the isolate lifecycle and `modelFilePath` from Phase 2's `ModelDistributionNotifier`. `ChatNotifier` and `TranslationNotifier` send requests through the LLM service abstraction and stream tokens back to UI providers. Drift provides the SQLite persistence layer with `ChatSessions` and `ChatMessages` tables; Phase 3 already has the empty `AppDatabase` stub ready to receive table definitions.

**Primary recommendation:** Use the raw `Llama` class inside a hand-rolled long-lived isolate (not `LlamaParent`) for full control over the Aya prompt format, stop sequences, and context management. The isolate communication protocol should use `SendPort`/`ReceivePort` with a tagged message protocol to distinguish token chunks, completion signals, errors, and control commands.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `llama_cpp_dart` | ^0.2.2 | Dart FFI binding for llama.cpp. `Llama` class with `setPrompt()` + `generateText()` stream | Confirmed working on Galaxy A25 (Phase 1 spike). Cohere2 + Aya tokenizer verified. |
| `drift` | ^2.31.0 | Reactive SQLite ORM for chat session/message persistence | Already in pubspec.yaml; Phase 3 stub `AppDatabase` awaits table definitions. Reactive `.watch()` streams for UI. |
| `drift_flutter` | ^0.2.8 | Platform-specific SQLite connection for drift | Already in pubspec.yaml. `driftDatabase(name: 'bittybot')` already configured. |
| `flutter_riverpod` | 3.1.0 (pinned) | State management — provider graph, `AsyncNotifier`, `keepAlive` | Pinned to 3.1.0 (riverpod_generator compatibility constraint from Phase 3). |
| `riverpod_annotation` | ^4.0.0 | Code generation for `@Riverpod` annotations | Already in pubspec.yaml; `build_runner` also present. |
| `dart:isolate` | SDK built-in | `SendPort`/`ReceivePort` for main↔isolate communication | The only safe IPC between Dart isolates. |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `path_provider` | ^2.1.5 | Resolve model file path for the isolate | Already in pubspec.yaml. Isolate needs absolute path string — resolve before spawning. |
| `drift_dev` | ^2.31.0 | Code generation for Drift table classes | Dev dependency, already present. Run `build_runner build` after schema changes. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Raw `Llama` in custom isolate | `LlamaParent`/`LlamaChild` (built-in managed isolate) | `LlamaParent` uses `ChatMLFormat` templates and wraps prompt building internally. Aya needs a specific non-ChatML template. Raw `Llama` gives full control — preferred. |
| `SendPort`/`ReceivePort` protocol | `flutter_isolate` package | `flutter_isolate` allows platform channel access from isolates (needed for plugins). llama_cpp_dart uses FFI directly, not platform channels — `flutter_isolate` not needed. |

**Installation:** No new packages needed for Phase 4. All dependencies are already in `pubspec.yaml`.

---

## Architecture Patterns

### Recommended Project Structure

```
lib/
├── core/
│   ├── db/
│   │   ├── app_database.dart        # EXTEND: add ChatSessions + ChatMessages tables
│   │   └── app_database.g.dart      # REGENERATE after schema changes
│   └── error/
│       └── error_messages.dart      # EXTEND: add inference-specific AppError variants
├── features/
│   ├── inference/
│   │   ├── application/
│   │   │   ├── llm_service.dart         # LlmService: owns isolate lifecycle
│   │   │   ├── llm_service_provider.dart # @Riverpod(keepAlive: true) modelReadyProvider
│   │   │   ├── inference_isolate.dart    # Top-level isolate entry point + message loop
│   │   │   └── inference_message.dart    # Sealed InferenceRequest / InferenceResponse types
│   │   └── domain/
│   │       ├── inference_repository.dart # Abstract interface consumed by notifiers
│   │       └── prompt_builder.dart       # Aya chat template construction
│   ├── chat/
│   │   ├── application/
│   │   │   ├── chat_notifier.dart         # @Riverpod ChatNotifier (AsyncNotifier)
│   │   │   └── chat_notifier.g.dart
│   │   ├── domain/
│   │   │   ├── chat_session.dart          # Value object (mirrors DB row)
│   │   │   └── chat_message.dart          # Value object (mirrors DB row)
│   │   └── data/
│   │       └── chat_repository_impl.dart  # Drift queries for sessions/messages
│   └── translation/
│       └── application/
│           ├── translation_notifier.dart  # @Riverpod TranslationNotifier
│           └── translation_notifier.g.dart
```

### Pattern 1: Long-Lived Inference Isolate

**What:** A single Dart isolate is spawned at startup, loads the `Llama` model, and persists for the entire app session. The main isolate sends `InferenceRequest` messages; the worker isolate streams back token chunks and a completion signal.

**When to use:** Any inference operation (translation or chat). Isolate is never respawned per-request — it's a persistent worker.

**Key insight from Phase 1:** `Llama.generateText()` is a synchronous-ish stream — it blocks the current isolate's event loop thread during generation. This is why the spike got ANR kills. In the background isolate, this blocking is acceptable because it doesn't affect the Flutter UI thread.

**Yield trick:** The Phase 1 fix commit `0c9bd49` added `await Future.delayed(Duration.zero)` between prompts to yield the event loop. The background isolate approach eliminates the need for this workaround — `generateText()` can block the isolate thread freely.

**Protocol (recommended):**

```dart
// inference_message.dart
// Source: Dart official isolate docs (dart.dev/language/isolates)

sealed class InferenceCommand {}

final class InferenceGenerate extends InferenceCommand {
  final int requestId;
  final String prompt;
  final int nPredict; // 128 for translation, 512 for chat
  InferenceGenerate({required this.requestId, required this.prompt, required this.nPredict});
}

final class InferenceStop extends InferenceCommand {
  final int requestId;
  const InferenceStop({required this.requestId});
}

final class InferenceShutdown extends InferenceCommand {
  const InferenceShutdown();
}

// Responses flow from isolate → main
sealed class InferenceResponse {}

final class InferenceToken extends InferenceResponse {
  final int requestId;
  final String token;
  const InferenceToken({required this.requestId, required this.token});
}

final class InferenceDone extends InferenceResponse {
  final int requestId;
  final bool stopped; // true = user stopped; false = natural completion
  const InferenceDone({required this.requestId, required this.stopped});
}

final class InferenceError extends InferenceResponse {
  final int requestId;
  final String message;
  const InferenceError({required this.requestId, required this.message});
}

final class InferenceReady extends InferenceResponse {
  const InferenceReady();
}
```

**Isolate entry point:**

```dart
// inference_isolate.dart
// Source: Dart official long-lived isolate pattern (dart.dev/language/isolates)

void inferenceIsolateMain(SendPort mainSendPort) {
  final receivePort = ReceivePort();
  // Send our command port back to the main isolate
  mainSendPort.send(receivePort.sendPort);

  Llama? llama;
  bool stopped = false;

  receivePort.listen((dynamic message) async {
    if (message is _LoadCommand) {
      try {
        final modelParams = ModelParams()
          ..nGpuLayers = 0
          ..mainGpu = -1
          ..useMemorymap = false;
        final contextParams = ContextParams()
          ..nCtx = 2048
          ..nBatch = 256
          ..nUbatch = 256;
        llama = Llama(message.modelPath, modelParams: modelParams, contextParams: contextParams);
        mainSendPort.send(const InferenceReady());
      } catch (e) {
        mainSendPort.send(InferenceError(requestId: -1, message: e.toString()));
      }
    } else if (message is InferenceGenerate) {
      stopped = false;
      try {
        llama!.setPrompt(message.prompt);
        await for (final token in llama!.generateText()) {
          if (stopped) break;
          mainSendPort.send(InferenceToken(requestId: message.requestId, token: token));
        }
        mainSendPort.send(InferenceDone(requestId: message.requestId, stopped: stopped));
      } catch (e) {
        mainSendPort.send(InferenceError(requestId: message.requestId, message: e.toString()));
      }
    } else if (message is InferenceStop) {
      stopped = true; // checked on next token iteration
    } else if (message is InferenceShutdown) {
      llama?.dispose();
      receivePort.close();
    }
  });
}
```

### Pattern 2: `modelReadyProvider` — Riverpod Isolate Lifecycle

**What:** A `keepAlive: true` `AsyncNotifier` that spawns the isolate, loads the model, and exposes the `SendPort` for sending requests.

**When to use:** Every provider that needs to send inference requests watches `modelReadyProvider`.

```dart
// llm_service_provider.dart
@Riverpod(keepAlive: true)
class ModelReady extends _$ModelReady {
  Isolate? _isolate;
  SendPort? _sendPort;
  ReceivePort? _responsePort;
  StreamController<InferenceResponse>? _responseStream;

  @override
  Future<void> build() async {
    // 1. Get model path from Phase 2's distribution notifier
    final modelState = ref.read(modelDistributionProvider);
    final modelPath = (ref.read(modelDistributionProvider.notifier)).modelFilePath;

    // 2. Spawn isolate
    _responsePort = ReceivePort();
    _responseStream = StreamController<InferenceResponse>.broadcast();

    _responsePort!.listen((msg) {
      if (msg is SendPort) {
        _sendPort = msg;
        // Now send the load command
        _sendPort!.send(_LoadCommand(modelPath: modelPath));
      } else if (msg is InferenceResponse) {
        _responseStream!.add(msg);
      }
    });

    _isolate = await Isolate.spawn(inferenceIsolateMain, _responsePort!.sendPort);

    // 3. Wait for InferenceReady signal
    await _responseStream!.stream.firstWhere((r) => r is InferenceReady);

    // 4. Wire up appStartupProvider extension point
    // (appStartupWidget.dart already has the comment: Phase 4 will add this)

    ref.onDispose(() {
      _sendPort?.send(const InferenceShutdown());
      _isolate?.kill(priority: Isolate.immediate);
      _responsePort?.close();
      _responseStream?.close();
    });
  }

  Stream<InferenceResponse> get responseStream =>
      _responseStream?.stream ?? const Stream.empty();

  void generate(InferenceGenerate command) => _sendPort?.send(command);
  void stop(InferenceStop command) => _sendPort?.send(command);
}
```

### Pattern 3: `appStartupProvider` Extension

Phase 3 left this hook:
```dart
// In app_startup_widget.dart — Phase 3 stub:
@Riverpod(keepAlive: true)
Future<void> appStartup(Ref ref) async {
  await ref.watch(settingsProvider.future);
  // Phase 4 will add: await ref.watch(modelReadyProvider.future);
}
```

Phase 4 must add `await ref.watch(modelReadyProvider.future)`. This gates `AppStartupWidget` (and thus all UI) behind inference readiness. The second-launch partial-access requirement means `ModelLoadingScreen` needs a state that shows partial UI (history/settings accessible) while model loads — requiring a separate `modelLoadingState` provider that's NOT part of `appStartupProvider`.

**Recommendation:** Do NOT add model loading to `appStartupProvider` for second launches. Instead:
- First launch: `appStartupProvider` awaits model download + load (full-screen gate, Phase 2 flow)
- Subsequent launches: `appStartupProvider` completes after settings load; model loads in background via `modelReadyProvider`; UI checks `modelReadyProvider` state to disable input

This requires the `ModelDistributionNotifier._loadModel()` stub in Phase 2 to be replaced with real `llama_cpp_dart` initialization that feeds into `modelReadyProvider`.

### Pattern 4: Request Queue

**What:** A `Queue<InferenceGenerate>` in the `LlmService` or in the notifiers. When a new request arrives while `isGenerating == true`, enqueue it. When `InferenceDone` arrives, dequeue and auto-send the next.

**Implementation:** The `ChatNotifier` / `TranslationNotifier` maintain an `AsyncQueue` (use Dart's `Queue` from `dart:collection`). This keeps the queue logic co-located with UI state.

```dart
// In ChatNotifier:
final _pendingQueue = Queue<String>(); // raw user input strings
bool _isGenerating = false;

Future<void> submitInput(String userText) async {
  if (_isGenerating) {
    _pendingQueue.add(userText);
    return;
  }
  await _sendRequest(userText);
}

void _onDone(InferenceDone done) {
  _isGenerating = false;
  if (_pendingQueue.isNotEmpty) {
    final next = _pendingQueue.removeFirst();
    _sendRequest(next);
  }
}
```

### Pattern 5: Drift Schema for Chat History

**What:** Two tables — `ChatSessions` and `ChatMessages`. Sessions group messages. Each message has a role (user/assistant), content, and timestamps.

**Schema design (recommended):**

```dart
// In app_database.dart — Phase 4 extends the Phase 3 stub

class ChatSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().nullable()(); // null = auto-derived from first message
  TextColumn get mode => text()(); // 'chat' | 'translation'
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class ChatMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer().references(ChatSessions, #id)();
  TextColumn get role => text()(); // 'user' | 'assistant'
  TextColumn get content => text()();
  BoolColumn get isTruncated => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
}

@DriftDatabase(tables: [ChatSessions, ChatMessages])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2; // Phase 3 was 1, Phase 4 adds tables → bump to 2

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from == 1) {
        await m.createTable(chatSessions);
        await m.createTable(chatMessages);
      }
    },
  );
}
```

**Key index:** Add index on `ChatMessages.sessionId` for fast message retrieval per session:
```dart
// In AppDatabase class:
Set<Index> get indices => {
  Index('chat_messages_session_idx', [chatMessages.sessionId]),
};
```

**Reactive queries (for UI):**
```dart
// Watch all messages for a session — auto-updates when new messages inserted
Stream<List<ChatMessage>> watchMessages(int sessionId) =>
    (select(chatMessages)
      ..where((m) => m.sessionId.equals(sessionId))
      ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]))
    .watch();
```

### Pattern 6: PromptBuilder — Aya Chat Template

The Aya chat template (confirmed from Phase 1 spike code):
```
<|START_OF_TURN_TOKEN|><|USER_TOKEN|>{user_message}<|END_OF_TURN_TOKEN|><|START_OF_TURN_TOKEN|><|CHATBOT_TOKEN|>
```

For multi-turn, each exchange adds one turn:
```
<|START_OF_TURN_TOKEN|><|USER_TOKEN|>msg1<|END_OF_TURN_TOKEN|>
<|START_OF_TURN_TOKEN|><|CHATBOT_TOKEN|>response1<|END_OF_TURN_TOKEN|>
<|START_OF_TURN_TOKEN|><|USER_TOKEN|>msg2<|END_OF_TURN_TOKEN|>
<|START_OF_TURN_TOKEN|><|CHATBOT_TOKEN|>
```

The `Llama.setPrompt()` appends to the context — do NOT reconstruct the full prompt history every turn. Instead, only pass the NEW user turn. The KV-cache preserves prior context.

**Critical:** `Llama.clear()` wipes context (amnesia). Only call this when starting a new session or when context is explicitly reset.

```dart
// prompt_builder.dart
class PromptBuilder {
  static const _userStart = '<|START_OF_TURN_TOKEN|><|USER_TOKEN|>';
  static const _userEnd = '<|END_OF_TURN_TOKEN|>';
  static const _chatbotStart = '<|START_OF_TURN_TOKEN|><|CHATBOT_TOKEN|>';

  /// System prompt for translation mode.
  static const translationSystemPrompt =
      'You are a translator. Translate the given text and reply with only '
      'the translation. Add a brief note about formality or context when relevant.';

  /// System prompt for chat mode.
  static const chatSystemPrompt =
      'You are a translator and language assistant. Help people translate '
      'text and understand languages. If asked about other topics, mention '
      'that translation is your strength.';

  /// Builds the initial prompt for a new session (first message only).
  /// Includes system prompt prepended to user message.
  static String buildInitialPrompt({
    required String systemPrompt,
    required String userMessage,
  }) {
    return '$_userStart$systemPrompt\n\n$userMessage$_userEnd$_chatbotStart';
  }

  /// Builds a follow-up prompt (incremental — appended to existing context).
  /// Do NOT include system prompt; do NOT repeat prior history.
  static String buildFollowUpPrompt(String userMessage) {
    return '$_userStart$userMessage$_userEnd$_chatbotStart';
  }

  /// Wraps an assistant response for context building (history reconstruction).
  static String wrapAssistantResponse(String response) {
    return '$_chatbotStart$response$_userEnd';
  }
}
```

### Pattern 7: Crash Circuit Breaker

Track consecutive failure count in `LlmService` or the `ModelReady` notifier:

```dart
int _consecutiveCrashCount = 0;
static const _maxAutoRetries = 3; // crash circuit breaker threshold

void _handleIsolateError() {
  _consecutiveCrashCount++;
  if (_consecutiveCrashCount <= _maxAutoRetries) {
    // Auto-restart: respawn isolate, reload model
    _restartIsolate();
  } else {
    // Surface error to user, wait for manual retry
    state = AsyncError(InferenceException('Model crashed repeatedly'), StackTrace.current);
  }
}

// On successful generation — reset counter
void _handleGenerationSuccess() {
  _consecutiveCrashCount = 0;
}
```

**Threshold recommendation:** 3 consecutive crashes before circuit break. This covers transient OOM kills without trapping the user in infinite crash loops.

### Anti-Patterns to Avoid

- **Calling `Llama.generateText()` on the main isolate:** Blocks the Flutter UI thread → ANR (confirmed in Phase 1 spike). Always use a background isolate.
- **Respawning the isolate per-request:** Load time on Galaxy A25 is ~85 seconds. The isolate must be long-lived for the session.
- **Passing `Llama` object across isolate boundary:** Dart isolates do not share memory — the `Llama` FFI object cannot be sent via `SendPort`. The object must live and die inside the worker isolate. Only primitive types and `SendPort` can cross isolate boundaries.
- **Using `mmap` for model file in app documents dir:** `useMemorymap = false` required on Android (SELinux `shell_data_file` context blocks mmap). Confirmed working in Phase 1.
- **Reconstructing full prompt history on every turn:** `setPrompt()` appends to the KV cache. Pass only the new user turn on follow-ups, not the full accumulated conversation.
- **Calling `Llama.clear()` between turns of the same session:** This wipes context (amnesia). Only call on session reset or context full.
- **`AsyncValue.valueOrNull`:** Does not exist in Riverpod 3.1.0. Use `.value` which returns `T?`. (Phase 3 lesson).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| SQLite persistence with reactive queries | Custom SQLite wrapper | Drift 2.31.0 | Reactive `.watch()` streams, type-safe columns, codegen entities, migration strategy — all present already |
| Isolate communication boilerplate | Custom port setup | Dart `dart:isolate` with simple tagged protocol | Well-documented, low overhead; `ReceivePort` IS a `Stream` |
| Chat message formatting / history | Custom string concatenation | `PromptBuilder` class + Drift messages table | Ensures Aya template consistency; history comes from DB, not in-memory accumulation |
| Token stream from model | Custom FFI calls | `llama_cpp_dart Llama.generateText()` | Confirmed working on-device; handles UTF-8 multi-byte correctly |
| UI state for async inference | `StatefulWidget` with manual streams | Riverpod `AsyncNotifier` + `StreamProvider` | Proven pattern from Phases 2-3; integrates with existing provider graph |

**Key insight:** The heavy lifting (FFI, SQLite, isolate communication) is handled by existing packages. Phase 4's engineering effort is the coordination layer — the protocol design, provider graph, and state machine — not the primitives.

---

## Common Pitfalls

### Pitfall 1: Isolate Cannot Access Flutter Platform Channels

**What goes wrong:** Attempting to use `path_provider` or other Flutter plugins inside the inference isolate.
**Why it happens:** Flutter platform channels are bound to the main isolate. Worker isolates cannot use them.
**How to avoid:** Resolve ALL file paths BEFORE spawning the isolate. Pass the resolved absolute model path string in the `_LoadCommand`. Phase 2's `ModelDistributionNotifier.modelFilePath` is already available before isolate spawn.
**Warning signs:** `MissingPluginException` or `PlatformException` inside the isolate.

### Pitfall 2: `SendPort.send()` Only Accepts Primitives and Specific Types

**What goes wrong:** Trying to send Dart objects (class instances) across the isolate boundary fails with a `TypeError` if the object contains non-transferable types.
**Why it happens:** Dart isolates do NOT share heap. `SendPort.send()` accepts: `null`, `bool`, `int`, `double`, `String`, `List`, `Map`, `Set`, `Uint8List`, `Int32List`, `Float64List`, `SendPort`, `Capability`, and `TransferableTypedData`. Custom class instances are serialized by value (deep copy).
**How to avoid:** The `InferenceCommand` / `InferenceResponse` sealed classes must only contain primitive fields (`int`, `String`, `bool`). The `Llama` object itself CANNOT be sent — it lives only in the worker isolate.
**Warning signs:** `Cannot send object of type ... across isolates` at runtime.

### Pitfall 3: `nCtx=2048` Requires ~1-2 GB Additional RAM

**What goes wrong:** Increasing `nCtx` from the spike's 512 to the production 2048 quadruples the KV cache size. On a 4 GB phone already running the OS + app + model, this can cause OOM kills.
**Why it happens:** KV cache scales O(nCtx × nLayers × headDim). For Tiny Aya at Q4_K_M, the math puts KV cache at ~400-800 MB at nCtx=2048.
**How to avoid:** After initial implementation, profile memory on Galaxy A25 specifically. The `modelReadyProvider` should log memory before and after model load. If OOM kills occur, lower nCtx to 1024 and document the decision.
**Warning signs:** `SIGKILL` in logcat with no Dart exception (OS-level OOM kill), or `LlamaCppException` with "failed to allocate context" message.

### Pitfall 4: Drift `schemaVersion` Must Be Bumped

**What goes wrong:** Adding tables without incrementing `schemaVersion` means Drift won't run `onUpgrade` for existing installations.
**Why it happens:** Drift only calls `onUpgrade` when the stored schema version differs from `schemaVersion`.
**How to avoid:** Phase 3 set `schemaVersion => 1` with empty tables. Phase 4 MUST change to `schemaVersion => 2` and add `onUpgrade` to create `ChatSessions` and `ChatMessages`. Run `build_runner build` to regenerate `app_database.g.dart`.
**Warning signs:** Tables don't exist on existing installs → `no such table: chat_sessions` Drift exception.

### Pitfall 5: `setPrompt()` Appends, `clear()` Resets — Context Full Is Permanent Until Reset

**What goes wrong:** Not tracking KV cache usage → context overflows silently, and model generates garbage (repetitive tokens, hallucinations).
**Why it happens:** `Llama.setPrompt()` tokenizes the prompt and fills the KV cache. When full, llama.cpp truncates or wraps, producing degraded output.
**How to avoid:** Track token count. `ContextParams.nCtx = 2048`. Before each `setPrompt()`, estimate token count from string length (rough: ~4 chars/token for English, ~2-3 for CJK). When approaching ~90% of nCtx, trigger the "start new session" UI flow.
**Warning signs:** Repetitive output, sudden response quality drop, or llama.cpp `context is full` log line.

### Pitfall 6: `generateText()` Blocks the Isolate — Stop Must Be Cooperative

**What goes wrong:** Calling `isolate.kill()` during active generation leaves llama.cpp in an inconsistent state. On the next `Llama` construction in the same process memory space, state may be corrupt.
**Why it happens:** llama.cpp maintains global/static state internally.
**How to avoid:** Use a `bool stopped` flag inside the isolate. Check it between tokens in the `await for` loop. Send `InferenceStop` command → isolate sets `stopped = true` → loop breaks cleanly → `InferenceDone(stopped: true)` is sent → THEN the isolate is safe to respawn if needed.
**Warning signs:** Crashes after stop, or `llama_context` assertion failures on reload.

### Pitfall 7: Riverpod 3.1.0 — `ref.watch()` in `AsyncNotifier.build()` vs Side Effects

**What goes wrong:** Calling `ref.watch()` outside of `build()` (e.g., in a method called from `build()` or from an event handler) causes lifecycle issues.
**Why it happens:** In Riverpod 3.1.0, `ref.watch()` is only valid during the synchronous execution of `build()`. For reading from event handlers, use `ref.read()`.
**How to avoid:** In `modelReadyProvider.build()`, use `ref.watch(modelDistributionProvider)` to establish the dependency. In methods like `generate()`, use `ref.read()`.

---

## Code Examples

Verified patterns from Phase 1 spike (`integration_test/helpers/model_loader.dart`):

### Model Initialization (Confirmed Working on Galaxy A25)

```dart
// Source: integration_test/helpers/model_loader.dart (Phase 1 spike — confirmed)
final modelParams = ModelParams()
  ..nGpuLayers = 0      // CPU-only — GGML_OPENCL=OFF in build
  ..mainGpu = -1        // No GPU devices — required for CPU-only validation
  ..useMemorymap = false; // SELinux blocks mmap on /data paths

final contextParams = ContextParams()
  ..nCtx = 2048         // Production value (was 512 in spike)
  ..nBatch = 256
  ..nUbatch = 256
  ..nPredict = 512;     // Max tokens; overridden per-request via SamplerParams or manual stop

_llama = Llama(
  modelPath,
  modelParams: modelParams,
  contextParams: contextParams,
  verbose: false, // true only for debugging
);
```

### Token Streaming (Confirmed Working)

```dart
// Source: integration_test/helpers/model_loader.dart (Phase 1 spike — confirmed)
_llama!.setPrompt(prompt); // Appends to KV cache — DO NOT call on first message of new session without clear()
await for (final token in _llama!.generateText()) {
  if (stopped) break;
  // token is a String fragment (may be partial UTF-8 character — package handles this)
  yield token;
}
```

### Long-Lived Isolate Spawn (Official Dart Pattern)

```dart
// Source: dart.dev/language/isolates — robust worker pattern
class Worker {
  late final SendPort _commands;
  final ReceivePort _responses = ReceivePort();

  static Future<Worker> spawn() async {
    final worker = Worker._();
    await Isolate.spawn(_workerMain, worker._responses.sendPort);
    worker._commands = await worker._responses.first as SendPort;
    return worker;
  }

  Worker._();

  // Worker entry point (top-level function — required for Isolate.spawn)
  static void _workerMain(SendPort mainSendPort) {
    final receivePort = ReceivePort();
    mainSendPort.send(receivePort.sendPort);
    receivePort.listen((message) { /* handle commands */ });
  }
}
```

### Drift Schema With Migration

```dart
// Source: drift.simonbinder.eu/migrations (verified)
@DriftDatabase(tables: [ChatSessions, ChatMessages])
class AppDatabase extends _$AppDatabase {
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => await m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from == 1) {
        // Phase 3 had no tables; Phase 4 adds sessions + messages
        await m.createTable(chatSessions);
        await m.createTable(chatMessages);
      }
    },
    beforeOpen: (details) async {
      // Enable WAL mode for concurrent reads during inference
      await customStatement('PRAGMA journal_mode=WAL');
      await customStatement('PRAGMA foreign_keys=ON');
    },
  );
}
```

### Reactive Message Watch (Drift)

```dart
// Source: drift.simonbinder.eu (verified API)
Stream<List<ChatMessageData>> watchMessagesForSession(int sessionId) {
  return (select(chatMessages)
    ..where((m) => m.sessionId.equals(sessionId))
    ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]))
    .watch();
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `compute()` for one-shot isolate | Long-lived isolate via `Isolate.spawn()` + `ReceivePort` | Always been supported; compute() is one-shot only | `compute()` cannot handle streaming; use spawn for persistent worker |
| `llama_cpp_dart` `LlamaParent` (built-in managed isolate) | Raw `Llama` in custom isolate | Package has offered both since 0.1.x | `LlamaParent` forces ChatML template; Aya needs custom template. Raw `Llama` gives full control. |
| Riverpod `autoDispose` everywhere | `keepAlive: true` for long-lived services | Riverpod 3.0+ (Sept 2025) | Inference isolate must never be auto-disposed mid-session. `keepAlive` is explicit and correct. |
| `AsyncValue.valueOrNull` | `AsyncValue.value` | Riverpod 3.1.0 (pinned) | `.valueOrNull` does not exist in 3.1.0. Use `.value` which returns `T?`. Lesson from Phase 3. |
| Drift schema version 1 (empty) | Schema version 2 (+ ChatSessions, ChatMessages) | Phase 4 | Must increment on every schema change for `onUpgrade` to fire |

**Deprecated/outdated:**
- `LlamaParent.messages` chat history: The managed isolate's internal history list uses ChatML format, not Aya format. Do not use for Aya models.
- `StateProvider`, `ChangeNotifierProvider` in Riverpod 3.0: Moved to legacy import. Not used in this project.

---

## Open Questions

1. **Does `nCtx=2048` cause OOM on Galaxy A25 (4 GB RAM)?**
   - What we know: Spike used nCtx=512. Model load = 2033 MB CPU buffer (~85s load). nCtx=2048 = 4× KV cache.
   - What's unclear: Exact KV cache size for Tiny Aya (3.35B, Q4_K_M) at nCtx=2048. Could be 200-800 MB.
   - Recommendation: Implement with nCtx=2048, add memory logging at load time. If OOM occurs during testing, step down to nCtx=1024.

2. **How does the `ModelDistributionNotifier._loadModel()` stub wire into `modelReadyProvider`?**
   - What we know: Phase 2's `_loadModel()` is a stub that goes directly to `ModelReadyState`. Phase 4 needs to intercept this to spawn the inference isolate.
   - What's unclear: Whether `modelReadyProvider` should watch `modelDistributionProvider` or whether `ModelDistributionNotifier._loadModel()` should directly call a service.
   - Recommendation: `modelReadyProvider` watches `modelDistributionProvider` for `ModelReadyState`. When `ModelReadyState` is emitted, `modelReadyProvider` grabs `modelFilePath` from the notifier and spawns the isolate. This keeps Phase 2 and Phase 4 cleanly separated. Phase 2's stub `_loadModel()` can remain as-is (it already emits `ModelReadyState`).

3. **What is the exact token count of the system prompts?**
   - What we know: Aya tokenizer is a custom BPE. English sentences tokenize ~4 chars/token.
   - What's unclear: Exact token overhead for Aya special tokens (`START_OF_TURN_TOKEN`, etc.).
   - Recommendation: In `PromptBuilder`, add a debug mode that logs estimated vs actual token usage. Profile during Phase 4 testing.

4. **Does `LlamaParent` handle Aya format via custom `ChatFormat` implementation?**
   - What we know: `LlamaParent` accepts a `PromptFormat` parameter. The `ChatFormat` interface can be implemented.
   - What's unclear: Whether `LlamaParent`'s internal message management would conflict with our manual context tracking.
   - Recommendation: Do not use `LlamaParent`. The raw `Llama` approach gives full control and is confirmed working from Phase 1.

---

## Sources

### Primary (HIGH confidence)

- `integration_test/helpers/model_loader.dart` — Phase 1 spike, confirmed working on Galaxy A25. Provides exact `ModelParams`, `ContextParams`, streaming pattern.
- `lib/core/db/app_database.dart` — Phase 3 stub. Confirms Drift setup, `driftDatabase()`, `schemaVersion: 1`.
- `lib/widgets/app_startup_widget.dart` — Phase 3 implementation. Confirms `appStartupProvider` hook and extension point comment.
- `lib/features/model_distribution/model_distribution_notifier.dart` — Phase 2 implementation. Confirms `modelFilePath` getter and `_loadModel()` stub.
- [dart.dev/language/isolates](https://dart.dev/language/isolates) — Official long-lived isolate pattern with `Worker` class example.
- [drift.simonbinder.eu/migrations](https://drift.simonbinder.eu/migrations/) — Migration strategy, `MigrationStrategy`, `createTable`, `onUpgrade`.

### Secondary (MEDIUM confidence)

- [pub.dev/packages/llama_cpp_dart](https://pub.dev/packages/llama_cpp_dart) — `LlamaParent` API overview, `SamplerParams`, managed isolate description. Version 0.2.2 published 53 days ago (as of research date).
- [pub.dev/documentation/llama_cpp_dart/latest/llama_cpp_dart/LlamaParent-class.html](https://pub.dev/documentation/llama_cpp_dart/latest/llama_cpp_dart/LlamaParent-class.html) — Full `LlamaParent` method list including `stop()`, `waitForCompletion()`, `stream`, `isGenerating`.
- [riverpod.dev/docs/whats_new](https://riverpod.dev/docs/whats_new) — Riverpod 3.0 lifecycle changes, `Ref.mounted`, `pause/resume` behavior.
- `.planning/phases/01-inference-spike/.continue-here.md` — ANR blocker documented. Confirms: "Inference blocks main thread. May need shorter nPredict or periodic yielding." Phase 4 background isolate solves this.
- [github.com/netdur/llama_cpp_dart CHANGELOG.md](https://github.com/netdur/llama_cpp_dart/blob/main/CHANGELOG.md) — Confirms v0.2.2 changes: slot management, auto-trim with sliding window, isolate child reply fix.

### Tertiary (LOW confidence — needs validation)

- KV cache memory estimate for nCtx=2048 on Tiny Aya: Based on general llama.cpp architecture knowledge, not measured on device.
- Token count of Aya special tokens: Estimated, not measured.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — All packages confirmed in pubspec.yaml and Phase 1 spike
- Architecture (isolate protocol): HIGH — Based on official Dart docs + confirmed working spike patterns
- Drift schema: HIGH — Drift API well-documented; migration pattern from official docs
- Riverpod provider graph: HIGH — Phase 3 established patterns; Riverpod 3.1.0 confirmed
- Memory impact of nCtx=2048: LOW — Requires on-device measurement, not available pre-implementation

**Research date:** 2026-02-25
**Valid until:** 2026-03-25 (stable stack; llama_cpp_dart and Drift are not fast-moving for our use case)
