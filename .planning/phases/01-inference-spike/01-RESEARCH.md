# Phase 1: Inference Spike - Research

**Researched:** 2026-02-19
**Domain:** Flutter llama.cpp binding selection + Cohere2/Tiny Aya GGUF compatibility + multilingual test harness design
**Confidence:** MEDIUM (binding version parity is the critical unknown; all other domains are HIGH)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Test languages and coverage:**
- Must-have languages: Chinese Mandarin, Cantonese (tested separately from Chinese Traditional), Latin American Spanish, English
- Test ALL 70+ Aya-supported languages, not just a handful
- Cantonese gets its own explicit test — prompt specifically for Cantonese translation, don't conflate with Chinese (Traditional)
- Cover diverse script families: CJK, Latin, Arabic (RTL), Thai (no-space complex script), Cyrillic, Devanagari, etc.

**Test prompts:**
- Must-have languages: travel phrases (directions, food ordering, emergencies, greetings, prices) PLUS basic sentences, questions, requests, and responses
- Broader 70+ language coverage: simple reference sentences for verifiable correctness
- Mix of both styles to stress-test translation quality across use cases

**Test-first approach:**
- Write test suites BEFORE writing implementation code — TDD style
- Be thorough with tests; comprehensive coverage is explicitly desired

**Coherence validation (LLM-as-judge):**
- Two-tier automated validation:
  1. Quick check: Sonnet 4.6 for basic coherence verification (script correctness + grammatical plausibility)
  2. Full suite: Gemini 3.0 Flash for comprehensive automated coherence checking across all 70+ languages
- Both API keys (Anthropic, Google) read from env vars, gracefully skip if not set with clear instructions
- Build the automation tooling as part of the spike

**Test report format:**
- Structured report with two sections:
  1. Summary scorecard: At-a-glance pass/fail scores per language at the top — scannable
  2. Expanded details: Full per-language results with sample translations, coherence scores, and failure details underneath

### Claude's Discretion
- Test file location (Flutter test/ vs separate spike/ directory) — choose what makes sense for reuse
- Exact test framework and assertion patterns
- Coherence scoring rubric design
- Which simple reference sentences to use for the 70+ language coverage

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| MODL-06 | All inference runs on-device via llama.cpp with zero network dependency after model download | Research confirms llama_cpp_dart and fllama both run fully offline. The GGUF file is loaded from local storage. Background downloader handles initial fetch (MODL-06 permits one-time download). Both bindings compile llama.cpp statically into the app binary. |
</phase_requirements>

---

## Summary

The core technical challenge of this spike is a version alignment problem: Cohere2 architecture support landed in llama.cpp on January 4, 2025 (PR #10900), and Tiny Aya's custom BPE tokenizer support landed February 16, 2026 (PR #19611). Every Flutter llama.cpp binding must bundle a llama.cpp version equal to or newer than that second date to correctly tokenize Tiny Aya models. The two candidate bindings — `llama_cpp_dart` (v0.2.2, tracks master) and `fllama` (llama.cpp frozen at July 5, 2025 commit fd1234cb) — have critically different version currency. `fllama`'s bundled llama.cpp predates the Tiny Aya tokenizer PR by seven months, making it the likely failure candidate. `llama_cpp_dart` updated its submodule in v0.2.1 (approximately January 2026) and v0.2.2 (approximately January 2026), which may or may not include the February 16 Tiny Aya tokenizer commit. The spike must empirically test both.

The Flutter testing approach is straightforward: use the `integration_test` package for on-device tests with `Timeout.none` for long inference runs. The LLM-as-judge layer uses `anthropic_sdk_dart` (v0.3.1) for Claude Sonnet 4.6 quick checks and `googleai_dart` (v3.0.0) for Gemini Flash comprehensive evaluation, both reading API keys from environment variables and gracefully skipping when absent. The spike should live in `integration_test/` at the Flutter project root so it runs with `flutter test integration_test/` on a connected device, and a companion `tool/` directory holds the standalone Dart judge scripts.

Android's 16KB page alignment is satisfied automatically by NDK r28+, which is already required by the `fllama`/`fcllama` ecosystem (NDK 28.0.12433566). iOS requires a physical device because Metal GPU is unavailable in Simulator. The app cannot use dynamic libraries on iOS App Store distribution; llama.cpp must be linked as a static XCFramework.

**Primary recommendation:** Start with `llama_cpp_dart` as the primary candidate (actively maintained, recent submodule updates, explicit streaming API). Test `fllama` as the fallback. The spike's go/no-go gate is loading the Tiny Aya Global Q4_K_M GGUF without architecture/tokenizer errors on both iOS physical device and Android with NDK r28+.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `llama_cpp_dart` | 0.2.2 (pub.dev) | Primary Flutter llama.cpp binding — loads GGUF, streams tokens via Dart isolate | Most recently updated (Jan 2026), tracks llama.cpp master, explicit streaming API, three abstraction levels including managed isolate |
| `fllama` | 0.0.1 (pub.dev), Jan 2026 commits | Fallback Flutter llama.cpp binding | Published by Telosnex, callback-based streaming via `onTokenStream`, but llama.cpp frozen at July 2025 (pre-Tiny-Aya tokenizer) |
| `integration_test` | SDK-bundled | On-device test runner for Flutter | Official Flutter package; runs tests on physical iOS/Android via `flutter test integration_test/` |
| `flutter_test` | SDK-bundled | Test assertions and widget test APIs | Standard — used within integration_test context |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `anthropic_sdk_dart` | 0.3.1 | Tier-1 LLM-as-judge via Claude Sonnet 4.6 | Quick coherence checks; env var `ANTHROPIC_API_KEY`; pure Dart, no Flutter dependency |
| `googleai_dart` | 3.0.0 | Tier-2 LLM-as-judge via Gemini Flash | Full 70+ language coherence sweep; env var `GOOGLE_GENAI_API_KEY`; pure Dart, no Firebase required |
| `background_downloader` | 9.5.2 | Download Tiny Aya GGUF from Hugging Face | Required because GGUF (2.14 GB) cannot be bundled in app binary; handles iOS 4-hour and Android 9-minute limits via `allowPause: true` |
| `path_provider` | Latest stable | Resolve on-device model storage path | Standard for Flutter file path resolution across iOS/Android |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `llama_cpp_dart` | `fllama` | fllama's llama.cpp is frozen at July 2025, predating Tiny Aya tokenizer support (Feb 16, 2026). Lower maintenance on pub.dev (v0.0.1). Use only if llama_cpp_dart fails to compile. |
| `anthropic_sdk_dart` | `claude_dart_flutter` | `claude_dart_flutter` is v1.0.0+1, 22 months old, no streaming, unverified publisher. Do not use. |
| `googleai_dart` | `google_generative_ai` | Officially deprecated by Google as of 2025; no further updates. `firebase_ai` is the new preferred SDK but requires Firebase setup. `googleai_dart` is the correct pure-Dart alternative for CLI/script use without Firebase. |
| `googleai_dart` | `firebase_ai` | `firebase_ai` requires Firebase project setup and ties evaluation tooling to production infrastructure. Spike tooling should stay simple; use `googleai_dart` directly. |
| Custom HTTP judge script | `anthropic_sdk_dart` + `googleai_dart` | Hand-rolling HTTP+SSE parsing for Anthropic/Google APIs is high effort with no benefit; both packages are pure Dart, well-maintained, and work in Dart CLI scripts. |

**Installation:**
```bash
flutter pub add llama_cpp_dart
flutter pub add integration_test --dev
flutter pub add flutter_test --dev
flutter pub add background_downloader
flutter pub add path_provider

# For the judge tool scripts (in tool/pubspec.yaml or as dev deps):
dart pub add anthropic_sdk_dart
dart pub add googleai_dart
```

---

## Architecture Patterns

### Recommended Project Structure

```
bittybot/
├── integration_test/                  # On-device spike tests (flutter test integration_test/)
│   ├── spike_binding_load_test.dart   # Test 1: model loads without architecture error
│   ├── spike_streaming_test.dart      # Test 2: tokens arrive one-at-a-time (not buffered)
│   ├── spike_multilingual_test.dart   # Test 3: 70+ language translation correctness
│   └── helpers/
│       ├── model_loader.dart          # Shared: path resolution + download trigger
│       ├── language_corpus.dart       # All 70+ languages with prompts and reference data
│       └── report_writer.dart         # Writes JSON result files to device storage
├── tool/
│   ├── judge_quick.dart               # Dart script: Claude Sonnet 4.6 quick check
│   ├── judge_full.dart                # Dart script: Gemini Flash full 70+ language sweep
│   └── generate_report.dart           # Dart script: reads JSON results, produces final report
└── lib/
    └── main.dart                      # Minimal app scaffold (required for integration_test)
```

**Rationale for `integration_test/` over `test/`:** Integration tests that run on a physical device with a real native library (llama.cpp FFI) must use `integration_test/` — Flutter's `test/` directory does not launch the full app and cannot exercise native FFI code on-device. Placing spike tests in `integration_test/` also allows direct reuse of the same test harness in production phases without restructuring.

**Rationale for `tool/` judge scripts:** The LLM-as-judge evaluation runs on the developer's machine (needs API keys from env vars), not on the phone. Dart CLI scripts in `tool/` are the natural home. They read the JSON output written by the on-device tests and call Anthropic/Google APIs.

### Pattern 1: On-Device Model Loading + Streaming

**What:** Load GGUF from local file path, stream tokens via async generator, verify each token arrives before generation completes.

**When to use:** All three integration tests — binding load, streaming proof, and multilingual correctness.

**Example (llama_cpp_dart):**
```dart
// Source: https://github.com/netdur/llama_cpp_dart/blob/main/doc/llama.md

import 'package:llama_cpp_dart/llama_cpp_dart.dart';

final llama = Llama(
  modelPath,  // absolute path to downloaded GGUF
  contextParams: ContextParams()..nCtx = 2048,
  verbose: true,
);

final tokens = <String>[];
final timestamps = <DateTime>[];

try {
  llama.setPrompt(prompt);
  await for (final text in llama.generateText()) {
    tokens.add(text);
    timestamps.add(DateTime.now());
    // Streaming verified: timestamps should be spread over generation time,
    // not all arriving at once when done.
  }
} finally {
  llama.dispose();
}

// Verify streaming: at least 3 tokens arrived before the 3rd timestamp,
// and timestamps span > 500ms total (not all in one batch).
expect(timestamps.last.difference(timestamps.first).inMilliseconds, greaterThan(500));
expect(tokens.length, greaterThan(3));
```

### Pattern 2: Integration Test with Timeout Disabled

**What:** Override Flutter's 10-minute default timeout for long inference runs.

**When to use:** Any test that runs model inference (can take 30s–5min on mobile).

```dart
// Source: https://api.flutter.dev/flutter/package-integration_test_integration_test/IntegrationTestWidgetsFlutterBinding/defaultTestTimeout.html

import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.defaultTestTimeout = Timeout.none;

  testWidgets('model loads and generates', (tester) async {
    // ... inference calls here
  }, timeout: Timeout.none);
}
```

### Pattern 3: LLM-as-Judge Quick Check (anthropic_sdk_dart)

**What:** Send generated translation to Claude Sonnet 4.6 for script correctness and grammatical plausibility check.

**When to use:** Tier-1 coherence validation for priority languages (Chinese Mandarin, Cantonese, Latin American Spanish, English) and script-family spot checks.

```dart
// Source: https://pub.dev/packages/anthropic_sdk_dart

import 'dart:io';
import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart';

Future<Map<String, dynamic>> judgeCoherence({
  required String language,
  required String prompt,
  required String translation,
}) async {
  final apiKey = Platform.environment['ANTHROPIC_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('ANTHROPIC_API_KEY not set — skipping quick coherence check');
    return {'skipped': true};
  }

  final client = AnthropicClient(apiKey: apiKey);
  final judgePrompt = '''
You are evaluating a translation output from a small on-device LLM.
Language: $language
Original prompt: $prompt
Translation output: $translation

Score 1-5 on each criterion:
1. Script correctness: Is the correct writing system used (not Latin for Arabic/Thai/CJK)?
2. Grammatical plausibility: Does it look like valid text in the target language?

Respond in JSON: {"script_score": N, "grammar_score": N, "notes": "..."}
''';

  final response = await client.createMessage(
    request: CreateMessageRequest(
      model: const Model.model(Models.claudeSonnet4_6),
      maxTokens: 256,
      messages: [MessageParam(role: MessageRole.user, content: MessageContent.text(judgePrompt))],
    ),
  );
  // parse response...
}
```

### Pattern 4: LLM-as-Judge Full Suite (googleai_dart)

**What:** Send batches of translation results to Gemini Flash for comprehensive evaluation across all 70+ languages.

**When to use:** Tier-2 full-suite evaluation after on-device tests complete.

```dart
// Source: https://pub.dev/packages/googleai_dart

import 'package:googleai_dart/googleai_dart.dart';

final client = GoogleAIClient.fromEnvironment();
// reads GOOGLE_GENAI_API_KEY env var; gracefully use:
// if (Platform.environment['GOOGLE_GENAI_API_KEY'] == null) { print('...'); return; }

final response = await client.generateContent(
  modelId: 'gemini-3-flash-preview',
  request: GenerateContentRequest(
    contents: [Content(parts: [Part(text: batchJudgePrompt)])],
  ),
);
```

### Pattern 5: Cantonese-Specific Test Prompt

**What:** Explicitly request Cantonese (Yue), not Chinese (Traditional), to validate the model distinguishes them.

**When to use:** Cantonese test case only — this is a distinct success criterion.

```dart
const cantonesePrompt = '''
Translate the following phrase into Cantonese (廣東話/粵語, Yue Chinese —
NOT Mandarin Chinese and NOT Chinese Traditional script alone).
Include Cantonese-specific vocabulary and particles (e.g., 㗎, 囉, 喇).
Phrase: "Excuse me, where is the nearest MTR station?"
''';

// Verification: output should contain Cantonese-specific particles
// (㗎, 囉, 喇, 咁, 咋) and NOT be pure Mandarin (which would use 吧, 呢, etc.)
final hasCantoneseParticles = RegExp(r'[㗎囉喇嘅咁咋]').hasMatch(output);
```

### Anti-Patterns to Avoid

- **Conflating Cantonese with Chinese Traditional:** Never use `zh-TW` or "Traditional Chinese" as the Cantonese test. These are different. Cantonese has distinct vocabulary, particles (㗎, 囉), and phonology.
- **Buffered token check:** Do not just check if output is non-empty at the end — that passes even if streaming is broken. Verify timestamps spread across the generation window.
- **Running on iOS Simulator:** Metal GPU is not available in the Simulator. llama.cpp inference will fail or fall back to CPU-only (no Metal shaders). Always test on physical hardware.
- **Dynamic library on iOS:** Apple prohibits dylib in App Store apps. llama.cpp must be a static `.a` wrapped in an `.xcframework`. Both `llama_cpp_dart` and `fllama` should handle this, but verify `Embed & Sign` is NOT set (use "Do Not Embed" for static XCFramework).
- **Ignoring Android 16KB alignment:** Do not build with NDK r26 or lower. NDK r28+ compiles 16KB-aligned by default. Verify with `llvm-objdump -p lib/arm64-v8a/libllama.so | grep LOAD` — all segments must show `align 2**14`.
- **Setting test timeout to default:** Flutter's default 10-minute timeout will fire during long multilingual inference runs. Always set `binding.defaultTestTimeout = Timeout.none`.
- **Hardcoding API keys:** LLM-as-judge scripts must read from `Platform.environment['ANTHROPIC_API_KEY']` and `Platform.environment['GOOGLE_GENAI_API_KEY']`, never hardcoded.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| llama.cpp FFI bindings | Custom C FFI glue code | `llama_cpp_dart` or `fllama` | Platform-specific builds, Metal/NDK integration, memory management — weeks of work already done |
| Background file download with resume | Custom HTTP download with file writing | `background_downloader` 9.5.2 | iOS 4-hour background limit, Android 9-minute timeout with auto-pause/resume, notification support — non-trivial edge cases |
| Claude API HTTP client | Raw `http` package + SSE parsing | `anthropic_sdk_dart` 0.3.1 | Server-sent event streaming protocol, retry logic, type-safe request/response models |
| Gemini API HTTP client | Raw `http` package | `googleai_dart` 3.0.0 | Pure Dart, no Firebase, environment variable init, type-safe |
| Streaming token verification | Complex callback wiring | `llama_cpp_dart`'s `generateText()` async generator | Already an idiomatic Dart `Stream` — use `await for` and timestamp each event |

**Key insight:** The entire llama.cpp ecosystem for Flutter is 6–18 months of C++ build system work (CMake, Metal, NDK, XCFramework). The binding choice is the spike's primary investigation, not an implementation task.

---

## Common Pitfalls

### Pitfall 1: Tiny Aya Tokenizer Not in Bundled llama.cpp

**What goes wrong:** The model loads (Cohere2 architecture was added Jan 4, 2025), but generation produces garbage output or incorrect token boundaries because the custom digit-grouping BPE tokenizer for Tiny Aya was only added February 16, 2026 (PR #19611). Output may appear to work but produce subtly wrong tokenization, especially for numbers and multilingual text.

**Why it happens:** Flutter llama.cpp bindings bundle a specific llama.cpp commit. `fllama`'s llama.cpp is frozen at July 5, 2025 (commit fd1234cb) — seven months before the Tiny Aya tokenizer PR. The binding's bundled llama.cpp must be from February 16, 2026 or later for correct Tiny Aya tokenization.

**How to avoid:** Run the spike with the actual Tiny Aya Global Q4_K_M GGUF and inspect outputs. If numbers appear tokenized incorrectly (e.g., "1234567" appears as "1234 567" or similar wrong splits), the tokenizer PR is missing. Fix: update the llama.cpp submodule in the chosen binding to master and rebuild.

**Warning signs:** Numbers in output are split unusually; generation works but multilingual output shows unexpected byte-fallback characters; "architecture not supported" error means Cohere2 is also missing.

### Pitfall 2: iOS Physical Device Build Failures

**What goes wrong:** The app builds but crashes on launch, or the XCFramework link fails with undefined symbols. Common causes: (a) dylib instead of static library, (b) Metal framework not linked, (c) Extended Virtual Addressing (EVA) not enabled.

**Why it happens:** llama.cpp on iOS requires arm64 only (no x86_64 for physical device), static linking (not dylib), and Metal framework linkage (`-framework Metal` in `OTHER_LDFLAGS`). Missing EVA limits addressable memory on iOS, which matters for a 2.14 GB model.

**How to avoid:**
- Enable EVA in Xcode: Entitlements → `com.apple.developer.kernel.extended-virtual-addressing = true`
- Verify XCFramework embed setting: "Do Not Embed" (for static .a)
- Add `-framework Metal` to `OTHER_LDFLAGS` in Xcode build settings
- Build for `arm64` only (not universal); Simulator requires separate build with `-DGGML_METAL=OFF`

**Warning signs:** `dyld: Library not loaded` on device launch; `Undefined symbol: _MTLCreateSystemDefaultDevice`; app loads but immediately crashes with SIGABRT on model load.

### Pitfall 3: Android NDK Version Mismatch

**What goes wrong:** The `.so` files in the APK are 4KB-aligned, causing Play Store rejection. Or the build fails with NDK compatibility errors.

**Why it happens:** NDK r26 and below produce 4KB-aligned `.so` files. NDK r27 requires an explicit opt-in flag. Only NDK r28+ compiles 16KB-aligned by default.

**How to avoid:** Pin NDK version in `android/app/build.gradle`:
```groovy
android {
  ndkVersion "28.0.12674087"
}
```
Verify alignment after build:
```bash
llvm-objdump -p build/app/intermediates/merged_native_libs/release/out/lib/arm64-v8a/libllama.so | grep LOAD
# All LOAD segments must show: align 2**14
```

**Warning signs:** Play Store console shows 16KB alignment warning; `zipalign` verification fails; llama.cpp `.so` in APK shows `align 2**12`.

### Pitfall 4: Flutter Test Timeout on Long Inference

**What goes wrong:** The integration test suite times out with `TimeoutException after 0:10:00` mid-inference, even though the model is generating correctly.

**Why it happens:** Flutter's `IntegrationTestWidgetsFlutterBinding` has a 10-minute default timeout. On a 3B model with CPU fallback (no Metal/GPU), inference for 70+ language tests can take 30–90 minutes total.

**How to avoid:** Add to every integration test file:
```dart
final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
binding.defaultTestTimeout = Timeout.none;
```
And to every `testWidgets` call: `timeout: Timeout.none`.

**Warning signs:** Test suite exits cleanly but with `TIMEOUT` status rather than PASS/FAIL; inference was running at the cutoff.

### Pitfall 5: Cantonese Conflation with Standard Chinese

**What goes wrong:** The test for Cantonese passes because the model outputs Chinese characters, but the output is actually Mandarin, not Cantonese. The test is then a false positive.

**Why it happens:** Models frequently output Mandarin Chinese when asked for "Chinese (Traditional)" or even "Cantonese" without a very explicit system prompt. The scripts overlap heavily; Cantonese-specific particles (㗎、囉、喇) and vocabulary (行唔行, 係唔係) are the distinguishing markers.

**How to avoid:** Test prompt must explicitly specify "Cantonese (廣東話/粵語, Yue Chinese) — NOT Mandarin." Validation checks for Cantonese-specific particles `[㗎囉喇嘅咁咋㖖㗎]` using regex. The LLM-as-judge prompt must also specifically ask "Is this Cantonese or Mandarin?"

**Warning signs:** Output is valid Chinese characters but lacks particles like 㗎, 喇; uses Mandarin negation (不, 没) instead of Cantonese (唔, 冇).

### Pitfall 6: Memory Pressure with 2.14 GB Model on Mobile

**What goes wrong:** The app crashes with `EXC_RESOURCE` (iOS) or OOM (Android) when loading the Q4_K_M model, even if the device has enough RAM in theory.

**Why it happens:** The Q4_K_M GGUF is 2.14 GB on disk but peaks higher in RAM during KV cache allocation. iPhone models with 4 GB RAM may OOM under normal OS conditions. Android varies significantly by device.

**How to avoid:** Use minimum viable `nCtx` (context window) for the spike — 512 or 1024, not 4096+. Set `nGpuLayers` to push layers to Metal (iOS) or OpenCL (Android) to reduce CPU RAM pressure. The spike is a go/no-go test, not a performance benchmark; minimize context size.

**Warning signs:** App crashes 2–5 seconds after initiating model load; Xcode shows `JETSAM` or memory pressure events; Android logcat shows `LowMemoryKiller`.

---

## Code Examples

Verified patterns from official sources:

### Model Load + Stream (llama_cpp_dart)
```dart
// Source: https://github.com/netdur/llama_cpp_dart/blob/main/doc/llama.md

final llama = Llama(
  '/path/to/tiny-aya-global-q4_k_m.gguf',
  contextParams: ContextParams()
    ..nCtx = 512       // minimal context for spike
    ..nBatch = 256,
  verbose: true,
);

try {
  llama.setPrompt(
    '<|START_OF_TURN_TOKEN|><|USER_TOKEN|>Translate "Hello, where is the nearest restaurant?" into Thai.<|END_OF_TURN_TOKEN|><|CHATBOT_TOKEN|>'
  );

  final tokens = <String>[];
  final firstTokenTime = <DateTime>[];

  await for (final text in llama.generateText()) {
    tokens.add(text);
    if (firstTokenTime.isEmpty) firstTokenTime.add(DateTime.now());
  }

  // Go/no-go checks:
  expect(tokens, isNotEmpty);  // Architecture loaded
  expect(tokens.any((t) => RegExp(r'[\u0E00-\u0E7F]').hasMatch(t)), isTrue);  // Thai script
} finally {
  llama.dispose();
}
```

### Integration Test File Structure
```dart
// integration_test/spike_binding_load_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.defaultTestTimeout = Timeout.none;

  group('Phase 1 Spike: Binding Load', () {
    testWidgets('Tiny Aya Global Q4_K_M loads without architecture error',
        (tester) async {
      // ... test body
    }, timeout: Timeout.none);

    testWidgets('tokens stream one-at-a-time (not buffered)',
        (tester) async {
      // ... streaming verification
    }, timeout: Timeout.none);
  });
}
```

### Judge Script: Skip When API Key Absent
```dart
// tool/judge_quick.dart

import 'dart:io';
import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart';

void main() async {
  final apiKey = Platform.environment['ANTHROPIC_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    stderr.writeln('''
ANTHROPIC_API_KEY not set — skipping quick coherence check.
To enable: export ANTHROPIC_API_KEY=sk-ant-...
''');
    exit(0);  // exit 0 = soft skip, not failure
  }

  final client = AnthropicClient(apiKey: apiKey);
  // ... process results JSON
}
```

### 16KB Alignment Verification Script
```bash
# Run after: flutter build apk --release

NDK_PATH="$HOME/Library/Android/sdk/ndk/28.0.12674087"
APK="build/app/outputs/flutter-apk/app-release.apk"
LLVM_OBJDUMP="$NDK_PATH/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-objdump"

unzip -o "$APK" "lib/arm64-v8a/libllama.so" -d /tmp/apk_check
"$LLVM_OBJDUMP" -p /tmp/apk_check/lib/arm64-v8a/libllama.so | grep -A1 LOAD
# Expected: "align 2**14" for all LOAD segments
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `flutter_driver` for on-device tests | `integration_test` package | Flutter 2.x → 3.x | `flutter_driver` deprecated; `integration_test` is the canonical approach, works with `flutter test` |
| `google_generative_ai` Dart package | `googleai_dart` (server/CLI) or `firebase_ai` (Flutter app) | 2025 | Google officially deprecated `google_generative_ai`; spike tool scripts use `googleai_dart`; never use `firebase_ai` for a standalone Dart judge script |
| Cohere Command-R (Cohere1) architecture | Cohere2 architecture | Jan 4, 2025 (llama.cpp PR #10900) | Tiny Aya uses Cohere2; any llama.cpp build before this date will reject the model with "architecture not supported" |
| No Tiny Aya tokenizer support | Custom BPE with digit-grouping regex | Feb 16, 2026 (llama.cpp PR #19611) | Without this, number tokenization is incorrect; impacts multilingual generation quality |
| NDK r26 (4KB default alignment) | NDK r28+ (16KB default alignment) | NDK r27 opt-in, r28 default | Play Store mandatory May 31, 2026 for all updates; build toolchain must use NDK r28+ |
| `google_generative_ai` 0.4.7 | `googleai_dart` 3.0.0 | 2025 | Direct API key support without Firebase; `fromEnvironment()` reads `GOOGLE_GENAI_API_KEY` |

**Deprecated/outdated:**
- `claude_dart_flutter`: 22 months old, no streaming, unverified publisher — do not use
- `google_generative_ai`: Officially deprecated by Google in 2025 — do not use
- `firebase_vertexai`: Replaced by `firebase_ai` as of Google I/O 2025 — not applicable to spike tooling

---

## Open Questions

1. **Does llama_cpp_dart 0.2.2 include the Tiny Aya tokenizer PR (Feb 16, 2026)?**
   - What we know: llama_cpp_dart 0.2.2 was published ~46 days before Feb 19, 2026 (i.e., ~Jan 4, 2026). The Tiny Aya tokenizer PR merged Feb 16, 2026 — six weeks after 0.2.2 published.
   - What's unclear: Whether the llama.cpp submodule in 0.2.2 was pinned to a specific commit at publish time, or if it continues to track master (in which case it may need a fresh build from source).
   - Recommendation: The spike must build llama_cpp_dart from source (not pub.dev cached prebuilts) to ensure the llama.cpp submodule is at or after Feb 16, 2026. Use `git submodule update --remote` and rebuild native libs.

2. **Does fllama's llama.cpp (July 2025 commit fd1234cb) support Cohere2 at all?**
   - What we know: Cohere2 merged Jan 4, 2025. fllama's llama.cpp is from July 2025 — six months after Cohere2 support. So Cohere2 architecture should work in fllama.
   - What's unclear: Whether fllama will produce correct output with Tiny Aya (the tokenizer is missing as of July 2025). Output may generate but be subtly wrong.
   - Recommendation: Test fllama with Tiny Aya as the secondary candidate. Expect architecture load to succeed but tokenization to potentially be incorrect for numbers and multilingual boundary cases. If fllama tokenizes correctly despite the missing PR, note this.

3. **Does Tiny Aya Global include Cantonese as a distinct language?**
   - What we know: Tiny Aya Global supports 70+ languages including "Chinese" in the East Asian category. The model card does not separately enumerate Cantonese (Yue). The research found Tiny Aya supports 67 languages on the HuggingFace model card (slightly different from the 70+ marketing number).
   - What's unclear: Whether the model distinguishes Cantonese from Mandarin at inference time, or collapses them to Standard Chinese. The spike's Cantonese test will determine this empirically.
   - Recommendation: Use an explicit Cantonese-forcing prompt. If the model cannot produce distinct Cantonese output, record this as a finding in the spike report — it informs whether Cantonese can be a supported language for the product.

4. **What is the model's on-device performance on minimum-spec hardware?**
   - What we know: Tiny Aya is 3.35B parameters; Q4_K_M is 2.14 GB. iPhone minimum from fllama's README is "2023 iPhones or better" for 7B models, suggesting 3B should run on older hardware.
   - What's unclear: Actual tokens-per-second on the target test device. The spike should measure and record this.
   - Recommendation: Record token generation speed (tokens/second) during spike — this is useful context for production phase planning even if not a success criterion.

---

## The Binding Decision Framework

The spike must answer: **Which binding has a sufficiently current llama.cpp for Tiny Aya?**

```
Decision tree:
├── llama_cpp_dart (primary)
│   ├── Build from source with submodule at ≥ Feb 16, 2026
│   ├── Test: Model loads without "architecture not supported"  → Cohere2 OK
│   ├── Test: Number tokenization correct in output           → Tiny Aya tokenizer OK
│   └── GO → use llama_cpp_dart
│
└── fllama (fallback, only if llama_cpp_dart fails)
    ├── llama.cpp from July 2025 (fd1234cb)
    ├── Test: Model loads (Cohere2 was added Jan 2025, so should work)
    ├── Test: Tokenization — EXPECT issues with numbers, verify output quality
    └── If acceptable quality → use fllama, else → update fllama submodule
```

---

## Tiny Aya Global: Language Coverage Reference

The following languages are confirmed from the model card for test corpus construction:

**European (31):** English, Dutch, French, Italian, Portuguese, Romanian, Spanish (Latin American Spanish is the required variant), Czech, Polish, Ukrainian, Russian, Greek, German, Danish, Swedish, Norwegian, Catalan, Galician, Welsh, Irish, Basque, Croatian, Latvian, Lithuanian, Slovak, Slovenian, Estonian, Finnish, Hungarian, Serbian, Bulgarian

**Middle Eastern & South Asian (14):** Arabic, Persian, Urdu, Turkish, Maltese, Hebrew, Hindi, Marathi, Bengali, Gujarati, Punjabi, Tamil, Telugu, Nepali

**Southeast Asian & East Asian (14):** Tagalog, Malay, Indonesian, Javanese, Khmer, Thai, Lao, Chinese (Mandarin), Burmese, Japanese, Korean, Vietnamese — plus **Cantonese (test separately as distinct language)**

**African (10):** Amharic, Hausa, Igbo, Malagasy, Shona, Swahili, Wolof, Xhosa, Yoruba, Zulu

**Total confirmed:** ~70 languages. Exact enumeration on HuggingFace model card lists 67.

**Required script families for success criteria (per phase description):**
- Latin: Spanish, French, English (most European languages)
- Arabic (RTL): Arabic, Persian, Urdu
- Thai (no-space complex script): Thai
- CJK: Chinese Mandarin, Cantonese, Japanese, Korean
- Cyrillic: Russian, Ukrainian, Bulgarian
- Devanagari: Hindi, Marathi, Nepali

---

## Sources

### Primary (HIGH confidence)
- [llama.cpp PR #10900](https://github.com/ggml-org/llama.cpp/pull/10900) — Cohere2 architecture support; merged January 4, 2025
- [llama.cpp PR #19611](https://github.com/ggml-org/llama.cpp/pull/19611) — Tiny Aya tokenizer support; merged February 16, 2026 by ngxson
- [CohereLabs/tiny-aya-global-GGUF on HuggingFace](https://huggingface.co/CohereLabs/tiny-aya-global-GGUF) — Model architecture (Cohere2), quantization options (Q4_K_M = 2.14 GB)
- [CohereLabs/tiny-aya-global on HuggingFace](https://huggingface.co/CohereLabs/tiny-aya-global) — Full language list, architecture details (3.35B, 8K context, sliding window + global attention)
- [Android page size guide](https://developer.android.com/guide/practices/page-sizes) — NDK r28+ compiles 16KB-aligned by default; verification via llvm-objdump
- [anthropic_sdk_dart pub.dev](https://pub.dev/packages/anthropic_sdk_dart) — v0.3.1, streaming via createMessageStream(), env var API key
- [googleai_dart pub.dev](https://pub.dev/packages/googleai_dart) — v3.0.0, fromEnvironment(), Gemini Flash support, pure Dart
- [background_downloader pub.dev](https://pub.dev/packages/background_downloader) — v9.5.2, iOS 4-hour limit, Android 9-min timeout with allowPause
- [Flutter integration_test docs](https://docs.flutter.dev/testing/integration-tests) — On-device test setup, timeout handling
- [llama_cpp_dart CHANGELOG](https://github.com/netdur/llama_cpp_dart/blob/main/CHANGELOG.md) — v0.2.2 and v0.2.1 release notes

### Secondary (MEDIUM confidence)
- [fllama GitHub activity](https://github.com/Telosnex/fllama/activity) — Last llama.cpp update July 5, 2025 (commit fd1234cb); last repo commit January 28, 2026
- [fllama pub.dev](https://pub.dev/packages/fllama) — iOS SDK 14+, Android SDK 23+, NDK 28.0.12433566, streaming via onTokenStream
- [llama_cpp_dart doc/llama.md](https://github.com/netdur/llama_cpp_dart/blob/main/doc/llama.md) — generateText() streaming API, slot-based context management
- [Flutter test timeout issue #105913](https://github.com/flutter/flutter/issues/105913) — defaultTestTimeout = Timeout.none pattern
- [Android NDK 16KB Flutter guide](https://dilumdesilva.medium.com/you-have-until-may-31-2026-heres-how-to-fix-16kb-page-size-issue-on-flutter-apps-f2dbf6c2a6a3) — Flutter 3.32.8+, AGP 8.7.x, Gradle 8.9, NDK r28

### Tertiary (LOW confidence — needs validation during spike)
- fllama's llama.cpp version inferred from GitHub activity page commit message (not verified against actual submodule file)
- Cantonese inclusion in Tiny Aya — model card says "Chinese" but doesn't separate Cantonese; requires empirical testing

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all versions verified from official pub.dev and GitHub sources
- Architecture/test structure: HIGH — Flutter integration_test docs are authoritative
- Binding version parity (critical unknown): MEDIUM — inferred from commit timestamps; empirical test required
- Cantonese support: LOW — not explicitly confirmed in model card; must test

**Research date:** 2026-02-19
**Valid until:** 2026-03-05 (14 days — fast-moving: llama.cpp releases daily, bindings update frequently)

**Key action before planning:** Confirm whether llama_cpp_dart's main branch llama.cpp submodule is currently at or after commit `5f28c53d` (the Tiny Aya tokenizer PR from Feb 16, 2026). Run: `git -C path/to/llama_cpp_dart/src/llama.cpp log --oneline | head -5` and check if `5f28c53` or later appears.
