# MVP Handoff — BittyBot v1.0 Complete

**Date:** 2026-02-28
**Branch:** `master` (merged from `mowismtest`)
**Commit:** `6284649`
**Build:** debug APK tested on Samsung Galaxy A25 (SM-A256E), Android 14

---

## MVP Status: COMPLETE

All 9 feature phases are code-complete and verified on physical hardware. All 9 known bugs have been fixed and retested. The app is a functional offline multilingual chat and translation tool.

## What's Built

### Features (Phases 1-9)

| Phase | Feature | Status |
|-------|---------|--------|
| 1 | Inference Spike — llama.cpp via FFI, static linking, Q3_K_S model | Complete |
| 2 | Model Distribution — first-launch download, resume, SHA-256 verify | Complete |
| 3 | App Foundation — dark theme, Cohere green palette, 10 UI locales, RTL | Complete |
| 4 | Core Inference Architecture — isolate, LLM service, Drift DB, notifiers | Complete |
| 5 | Translation UI — 66 languages, language picker, streaming, word batching | Complete |
| 6 | Chat UI — multi-turn, markdown rendering, streaming, stop button | Complete |
| 7 | Chat History — session drawer, persistence, swipe-to-delete | Complete |
| 8 | Chat Settings — auto-clear toggle, clear all history, settings screen | Complete |
| 9 | Web Search — URL paste mode, web fetch, mode indicator | Complete |

### Bug Fixes (Sprints 6-9)

| Bug | Description | Fix | Sprint |
|-----|-------------|-----|--------|
| BUG-1 | Chat bubbles show raw markdown | `MarkdownBody` replaces `Text` widget | S6-T2 |
| BUG-2 | Model says "Aya" not "Bittybot" | System prompt identity in `chatSystemPrompt` | S6-T1 |
| BUG-3 | 183-243 frame skips on cold start | Native Android splash screen (dark #121212 + icon) | S7-T2 |
| BUG-4 | Dead `..take(3)` no-op | Removed dead code | S6-T6 |
| BUG-5 | Crash recovery FD leak | ShutdownCommand before isolate kill | S6-T4 |
| BUG-6 | Stale TODO(phase-4) | Removed | S6-T6 |
| BUG-7 | print() not guarded | `if (kDebugMode) print(line)` | S6-T5 |
| BUG-8 | Context limit text + stuck inference | ErrorResponse handling + auto-reset in both notifiers | S7-T1/T4 + S8 |
| BUG-9 | Translation typing indicator stuck after context exhaustion | Reset `isTranslating: false` in `startNewSession()` | S9 |

### Performance (Sprint 9 verified on Galaxy A25)

| Metric | Value |
|--------|-------|
| Model load | 5.9-7.6s |
| Warm TTFT (chat) | 3.2-4.7s, avg 3.8s |
| tok/s (chat) | 2.42-2.61, avg 2.50 |
| Warm TTFT (translation) | 3.9-4.5s |
| tok/s (translation) | 0.86-1.30 |
| Post-context-clear TTFT | 9-13s (accepted hardware limitation) |
| Memory (PSS) | 1.85 GB |
| Memory (RSS) | 1.89 GB |
| Memory (Swap) | < 1 MB |

---

## Architecture Summary

### Tech Stack
- **Language:** Dart / Flutter
- **State management:** Riverpod (flutter_riverpod 3.1.0 + riverpod_generator 4.0.0)
- **Local DB:** Drift (SQLite) — chat sessions, messages
- **Inference:** llama.cpp via llama_cpp_dart ^0.2.2 (FFI, static linking)
- **Model:** Cohere Tiny Aya Global 3.35B, Q3_K_S quantization (~1.55 GB)

### Key Source Directories

```
lib/
├── app.dart                          # App root, MaterialApp, theme, routing
├── core/
│   ├── db/app_database.dart          # Drift schema (ChatSessions, ChatMessages)
│   ├── diagnostics/                  # PerformanceMonitor, InferenceProfiler
│   ├── l10n/                         # 10 ARB files, 87 keys each
│   └── theme/                        # app_colors.dart, app_text_theme.dart, app_theme.dart
├── features/
│   ├── chat/
│   │   ├── application/chat_notifier.dart    # Auto-dispose, nPredict=512
│   │   ├── data/chat_repository_impl.dart    # Drift-backed
│   │   ├── data/web_fetch_service.dart       # Phase 9 web mode
│   │   └── presentation/chat_screen.dart     # Markdown bubbles, history drawer
│   ├── inference/
│   │   ├── application/inference_isolate.dart # Long-lived isolate, token filter
│   │   ├── application/llm_service.dart       # Isolate lifecycle manager
│   │   ├── data/native_memory_advisor.dart    # posix_fadvise FFI
│   │   └── domain/prompt_builder.dart         # Aya chat template, translation prompt
│   ├── model_distribution/
│   │   ├── model_constants.dart               # Q3_K_S URL, hash, size
│   │   └── model_distribution_notifier.dart   # Download flow, SHA-256 skip
│   ├── settings/
│   │   ├── application/settings_provider.dart # SharedPreferencesWithCache, keepAlive
│   │   └── presentation/settings_screen.dart  # Auto-clear, clear all history
│   └── translation/
│       ├── application/translation_notifier.dart  # keepAlive, nPredict=128
│       ├── data/language_data.dart                 # 66 languages, variants
│       └── presentation/translation_screen.dart   # Language picker, bubbles
├── widgets/
│   ├── app_startup_widget.dart       # Async gate (settings only)
│   ├── context_full_banner.dart      # "Session is getting long..." banner
│   ├── main_shell.dart               # NavigationBar (Translate | Chat)
│   └── model_gate_widget.dart        # Disables input until model ready
```

### Inference Pipeline

```
User types → ChatNotifier/TranslationNotifier
  → Queue<String> FIFO
  → GenerateCommand via SendPort → Inference Isolate
  → llama_cpp_dart setPrompt() + getNextWithStatus() loop
  → TokenResponse via ReceivePort → Notifier batches 50ms → UI rebuild
  → DoneResponse → Save to Drift DB
  → ErrorResponse (context full) → startNewSession() → llama.clear()
```

### Model Configuration (Hardcoded)

| Param | Value | Location |
|-------|-------|----------|
| nCtx | 512 | `inference_message.dart:28` |
| nBatch | 256 | `inference_message.dart:29` |
| nThreads | 6 | `inference_message.dart:30` |
| nPredict (chat) | 512 | `chat_notifier.dart:348` |
| nPredict (translation) | 128 | `translation_notifier.dart` |
| nGpuLayers | 0 | `inference_isolate.dart:92` |
| useMemorymap | true | `inference_isolate.dart:94` |

---

## Known Limitations (Not Bugs — Hardware/Design Constraints)

### 1. Context Length: nCtx=512 (CRITICAL for future work)

The model runs with nCtx=512 tokens. This is extremely tight:
- **Chat exhausts after ~7-8 messages** with typical response lengths (50-200 tokens each)
- **Translation exhausts after ~17-20 translations** (system prompt + input/output pairs accumulate)
- When context fills, `ErrorResponse` triggers auto-reset: KV cache cleared, new session starts, old conversation lost
- Post-clear TTFT is 9-13s due to mmap page re-faulting (accepted, rare event)
- **Web mode (Phase 9) is essentially non-functional** at nCtx=512 — a fetched webpage easily exceeds the entire context window, leaving no room for model response

**Why 512:** The Galaxy A25 has 5.5 GB RAM. With the Q3_K_S model (1.55 GB mmap), KV cache scales linearly with nCtx. At nCtx=512 the KV cache is ~16 MB. Doubling to 1024 would be ~32 MB (trivial). The real constraint was set during Phase 1 spike for safety and never re-evaluated.

**Recommendation:** Increase to nCtx=2048 or 4096. The KV cache cost at 2048 is ~64 MB, still well within budget. This would:
- Extend chat to ~30+ messages before exhaustion
- Make translation essentially unlimited for normal use
- Make web mode viable (fetched content + response can fit)
- The only risk is slightly higher memory pressure during inference

**Files to change:** `inference_message.dart:28` (the `nCtx` constant)

### 2. GPU Acceleration Ruled Out

Mali-G68 (Exynos 1280) is 3-16x SLOWER than CPU for LLM inference. No NPU, no I8MM. The ~2.5 tok/s on CPU is the hardware ceiling for this device with a 3.35B model. Do not attempt GPU offloading.

### 3. Frame Skips on Cold Start (~200 frames)

Root cause is Flutter/Impeller Vulkan initialization on main thread (~2.6s). This is a Flutter engine issue, not app code. The native splash screen covers it so users don't see a blank screen.

### 4. Post-Context-Clear TTFT (9-13s)

After `llama.clear()`, mmap pages are partially evicted. `posix_fadvise(WILLNEED)` is advisory-only and the kernel ignores it under memory pressure on this 5.5 GB device. This is a rare event (only after context exhaustion) and accepted.

---

## What's Next: Refinement Phase

The MVP is functional but rough. The next milestone should focus on:

### UI Refinements (Priority)
- Polish language picker UX (search, favorites, recently used)
- Improve chat bubble styling (spacing, timestamps, copy button)
- Better loading states and transitions
- Onboarding flow for first-time users
- Haptic feedback on interactions
- Scroll-to-bottom button during streaming

### Context Length Expansion (High Priority)
- Increase nCtx from 512 to 2048 (or 4096) — single constant change + on-device testing to verify memory budget
- This unblocks web mode and dramatically improves chat usability
- Test: memory snapshot at higher nCtx, verify no OOM, measure TTFT impact

### Other Candidates
- Conversation export (share/copy entire chat)
- Improved multi-turn recall (context management, summary injection)
- Translation history (saved translations list)
- Input method improvements (voice-to-text integration point)
- Release build optimization (ProGuard, --release, size audit)

---

## Build & Test Reference

### Build and Deploy
```bash
cd /home/max/git/bittybot  # or wherever repo is cloned
/home/max/Android/flutter/bin/flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

### Device Test Commands
```bash
# Launch
adb shell am start -n com.bittybot.bittybot/.MainActivity

# Force stop
adb shell am force-stop com.bittybot.bittybot

# Monitor perf
adb logcat -s flutter | grep '\[PERF\]'

# Memory
adb shell dumpsys meminfo com.bittybot.bittybot | head -40

# Frame skips
adb logcat | grep -E 'Skipped.*frames'
```

### Package Name
`com.bittybot.bittybot`

### Model
- Q3_K_S quantization, ~1.55 GB
- GitHub release: `v0.1.0-q3ks`
- Already on test device — no re-download needed for existing installs

---

## Reports Archive

| Report | Content |
|--------|---------|
| `.planning/SPRINT-6-REPORT.md` | S6 bug fixes: identity, markdown, deferred warmup, FD cleanup, print guard, dead code |
| `.planning/SPRINT-7-REPORT.md` | S7 bug fixes: context limit handling, native splash, quote stripping |
| `.planning/SPRINT-8-REPORT.md` | S8: ErrorResponse context-full bug found and fixed |
| `.planning/SPRINT-8-RETEST-REPORT.md` | S8 retest: re-fadvise, context reset snackbar |
| `.planning/SPRINT-9-RETEST-REPORT.md` | S9 retest: BUG-9 fix verified, full regression PASS |
| `.planning/PROFILING-RESULTS.md` | Sprints 2-5 perf data (TTFT, tok/s, memory, mmap) |
| `.planning/PROFILING-GUIDE.md` | Full test protocol reference |
