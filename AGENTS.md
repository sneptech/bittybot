# BittyBot — Multi-Agent Development Guide

## Project Identity

**What:** Fully offline multilingual chat & translation app for travelers
**Stack:** Flutter/Dart, Riverpod, Drift (SQLite), llama.cpp via llama_cpp_dart
**Model:** Cohere Tiny Aya Global 3.35B (Q4_K_M GGUF, ~2.14 GB on-device)
**Repo:** `/home/agent/git/bittybot` (remote: `https://github.com/sneptech/bittybot.git`)
**Branch:** `mowismtest` (current working branch)

## Agent Roles

| Role | Agent Type | Count | Responsibility |
|------|-----------|-------|----------------|
| **Architect** | Claude Code Opus 4.6 | 1 | Task assignment, design decisions, PR review, coordination |
| **Reviewer** | Claude Code Opus 4.6 | 1 | Code review of Codex output, integration testing, bug investigation |
| **Worker** | Codex GPT 5.2 xhigh | 3 | Feature implementation, one phase/task per worker |

## Current State (2026-02-27)

**Completed:** Phases 1-4 (inference spike, model distribution, app foundation, core inference arch)
**In Progress:** Phase 5 (Translation UI) — 3/4 plans done, Plan 04 paused at device verification
**Not Started:** Phases 6, 7, 8, 9

### Phase Dependency Graph
```
Phase 4 (DONE)
  ├── Phase 5: Translation UI [75% — Plan 04 blocked on device]
  ├── Phase 6: Chat UI [NOT STARTED — can run parallel with Phase 5]
  │     ├── Phase 7: Chat History [requires Phase 6]
  │     └── Phase 9: Web Search [requires Phase 6]
  └── Phase 8: Chat Settings [requires Phase 7]
```

### Known Bugs (code-verified in S5-T3 on 2026-02-27)
1. **VERIFIED FIXED (S5-T3): Wrong screen displayed** — startup path routes `ModelGateWidget -> AppStartupWidget -> MainShell -> TranslationScreen`; no `Phase 1`/`Inference Spike` UI text in startup files.
2. **VERIFIED FIXED (S5-T3): App icon reset** — custom `ic_launcher.png` assets confirmed in all Android mipmap densities (mdpi 1823 B, hdpi 3300 B, xhdpi 4233 B, xxhdpi 5926 B, xxxhdpi 7989 B).

## Task Assignment — Sprint 5: Page Residency + Cold Start Polish

**Full plan:** `.planning/sprint-5-page-residency.md`
**Profiling data:** `.planning/PROFILING-RESULTS.md`

| Task ID | Task | Priority | Assigned Manager | Worker Pane | Files |
|---------|------|----------|-----------------|-------------|-------|
| S5-T1 | `posix_fadvise(POSIX_FADV_WILLNEED)` via Dart FFI — keep model pages resident | CRITICAL | Manager pane 1 | Pane 3 | NEW: `lib/features/inference/data/native_memory_advisor.dart`, EDIT: `lib/features/inference/application/inference_isolate.dart` |
| S5-T2 | Fix 2nd cold start frame skip regression (184→<50) | HIGH | Manager pane 1 | Pane 4 | `lib/features/model_distribution/model_distribution_notifier.dart`, `lib/features/inference/application/inference_isolate.dart` |
| S5-T3 | Verify P1 bugs fixed (wrong screen, app icon), clean up dead code | MEDIUM | Manager pane 0 | Pane 5 | Read-only verification of startup path + AGENTS.md update |

### Previous Sprints (complete)
| Sprint | Tasks | Status |
|--------|-------|--------|
| Sprint 1-2 | Phases 1-9 features + performance monitoring | Complete |
| Sprint 3 | OOM fix (mmap), cold start (SHA-256 skip), nCtx, loading indicator | Complete |
| Sprint 4 | Q3_K_S quantization, nThreads 6, startup jank fix, page warmup | Complete |

## Coordination Protocol

### MCP Agent Mail (REQUIRED)
All agents MUST use MCP Agent Mail. Project key: `/home/agent/git/bittybot`

**On session start:**
1. `register_agent(project_key="/home/agent/git/bittybot", program="<your_program>", model="<your_model>")`
2. `fetch_inbox(project_key="/home/agent/git/bittybot", agent_name="<your_name>", include_bodies=true)`
3. Acknowledge any messages with `ack_required=true`
4. Check file reservations before editing

**Before editing files:**
- `file_reservation_paths(project_key="/home/agent/git/bittybot", agent_name="<your_name>", paths=["lib/features/chat/**"], ttl_seconds=3600, exclusive=true, reason="T-03")`

**When starting a task:**
- `send_message(project_key="/home/agent/git/bittybot", sender_name="<your_name>", to=["BlueMountain"], subject="[T-XX] Starting: <title>", body_md="Claiming T-XX. Reserving files: [list]. Plan: [brief].", broadcast=false)`

**When finishing a task:**
- `send_message(project_key="/home/agent/git/bittybot", sender_name="<your_name>", to=["BlueMountain"], subject="[T-XX] Complete: <title>", body_md="Summary of changes. Files modified: [list]. Tests: [status].", broadcast=true)`
- `release_file_reservations(project_key="/home/agent/git/bittybot", agent_name="<your_name>")`

### File Ownership Boundaries

Agents MUST reserve files before editing and MUST NOT edit files reserved by others.

| Area | Owner | Glob Pattern |
|------|-------|-------------|
| Translation feature | Reviewer | `lib/features/translation/**` |
| Chat presentation (new) | Worker-2 | `lib/features/chat/presentation/**` |
| Chat history UI (new) | Worker-3 | `lib/widgets/chat_drawer/**` |
| Settings feature | (T-06 assignee) | `lib/features/settings/**` |
| App shell / startup | Reviewer | `lib/widgets/app_startup_widget.dart`, `lib/widgets/main_shell.dart`, `lib/app.dart`, `lib/main.dart` |
| Model distribution | (stable, don't touch) | `lib/features/model_distribution/**` |
| Inference core | (stable, don't touch) | `lib/features/inference/**` |
| Android config | Worker-1 | `android/**` |
| iOS config | Worker-1 | `ios/**` |

## Code Conventions

### Flutter/Dart
- **State management:** Riverpod 3.1.0 (pinned — do NOT upgrade)
- **Database:** Drift 2.31.0 with code gen
- **Imports:** Use `import 'app_database.dart' as db` to disambiguate Drift row types from domain types
- **Padding:** `EdgeInsetsDirectional` everywhere (RTL-ready)
- **Providers:** `@Riverpod(keepAlive: true)` for persistent state, `@riverpod` (auto-dispose) for screen-scoped state
- **Error handling:** `resolveErrorMessage()` with Dart 3 record pattern switch on `(AppError, ErrorTone)`
- **Fonts:** Offline only — `GoogleFonts.config.allowRuntimeFetching = false`
- **Localization:** ARB files in `lib/core/l10n/`, use `AppLocalizations.of(context).key`

### Architecture Patterns
- **Partial-access:** `appStartupProvider` awaits settings only; model loads independently via `modelReadyProvider`
- **Inference isolate:** Long-lived, never respawned per request. `InferenceRepository` bridges main thread ↔ isolate
- **ChatNotifier:** Auto-dispose, reloads from DB per screen entry
- **TranslationNotifier:** keepAlive, persists language pair across navigation
- **Streaming:** Word-level batching for space-delimited scripts, token-by-token for CJK/Thai/etc.

### Feature Structure
```
lib/features/<feature_name>/
  ├── application/    # Riverpod notifiers + providers
  ├── data/           # Repository implementations
  ├── domain/         # Models, interfaces
  └── presentation/   # Screens, widgets
```

### Commit Style
- Atomic, one logical change per commit
- Prefix: `feat:`, `fix:`, `docs:`, `chore:`, `wip:`
- Include task ID: `feat(chat-ui): [T-03] implement chat screen with streaming`

### Build
- **Android NDK:** 29.0.14033849 (16KB page alignment)
- **iOS:** platform 14.0, physical device only (no Simulator)
- **Verify after changes:** `cd /home/agent/git/bittybot && flutter analyze && flutter build apk --debug`
- **Code gen:** `dart run build_runner build --delete-conflicting-outputs` after Drift/Riverpod changes

## Phase 6: Chat UI — Design Brief

**Goal:** Multi-turn chat screen with streaming, stop button, and ChatGPT-style UX.

**Success Criteria:**
1. User sends message → appears immediately → model streams reply word-by-word
2. Stop button visible during generation → halts and shows partial text
3. 10+ turn conversation without UI slowdown
4. Input disabled while model not ready (via `modelReadyProvider`)

**Implementation Notes:**
- Reuse `ChatNotifier` from Phase 4 (`lib/features/chat/application/chat_notifier.dart`)
- Reuse `ChatRepository` / `DriftChatRepository` for persistence
- Create `lib/features/chat/presentation/chat_screen.dart` + widgets
- Follow `TranslationScreen` patterns from Phase 5 for streaming bubble display
- `ChatNotifier` is auto-dispose — state reloads from Drift DB per screen entry
- `nPredict=512` for chat mode (vs 128 for translation)
- Aya chat template: `<|START_OF_TURN_TOKEN|><|USER_TOKEN|>...<|END_OF_TURN_TOKEN|><|START_OF_TURN_TOKEN|><|CHATBOT_TOKEN|>`

## Phase 7: Chat History — Design Brief

**Goal:** Slide-out drawer listing previous chat sessions, loaded from Drift DB.

**Success Criteria:**
1. Swipe from left edge or tap menu icon → drawer with session list
2. Tap session → loads full message history
3. Messages persist across force-quit
4. "New Chat" button in drawer

**Implementation Notes:**
- `DriftChatRepository.watchAllSessions()` already exists (Phase 4)
- `insertMessage` already touches parent `updatedAt` for sort order
- Session title = first user message (truncated)
- Use `Scaffold.drawer` or `NavigationDrawer` widget

## Key Files Reference

| File | Purpose |
|------|---------|
| `lib/main.dart` | Entry point, `ProviderScope`, `runApp` |
| `lib/app.dart` | `MaterialApp`, theme, locale, routing |
| `lib/widgets/app_startup_widget.dart` | Async gate: loading → error → loaded |
| `lib/widgets/main_shell.dart` | `NavigationBar` shell (translation tab, chat tab TBD) |
| `lib/widgets/model_gate_widget.dart` | Disables input until model ready |
| `lib/features/inference/application/llm_service.dart` | Isolate lifecycle |
| `lib/features/inference/application/inference_isolate.dart` | Isolate entry point |
| `lib/features/inference/domain/prompt_builder.dart` | Aya chat template |
| `lib/features/chat/application/chat_notifier.dart` | Chat state manager |
| `lib/features/chat/data/chat_repository_impl.dart` | Drift-backed persistence |
| `lib/features/translation/presentation/translation_screen.dart` | Reference for streaming UI patterns |
| `lib/core/db/app_database.dart` | Drift schema |
| `.planning/STATE.md` | Current project state |
| `.planning/ROADMAP.md` | Phase descriptions and success criteria |
| `.planning/PROJECT.md` | Requirements and decisions |
| `CLAUDE.md` | Learned patterns and conventions |

## Rules

1. **Read this file, CLAUDE.md, and README.md before any coding work**
2. **Register with Agent Mail immediately** — no work without coordination
3. **Reserve files before editing** — check reservations first, reserve your files, work, release
4. **One task at a time** — go deep, finish, then move on
5. **Never delete files without explicit human permission**
6. **Never rewrite or transform code via scripts** — manual edits only
7. **Do not touch stable phases** (inference core, model distribution) unless fixing a verified bug
8. **Commit frequently** — atomic commits with task IDs
9. **Check inbox regularly** — other agents may have context you need
10. **When blocked, message the Architect** (BlueMountain) instead of guessing
