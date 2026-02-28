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

## Current State (2026-02-28)

**Completed:** Phases 1-9 (all features code-complete), Sprints 1-6 (performance + bug fixes)
**Status:** Sprint 6 COMPLETE — awaiting on-device retest
**Next:** On-device retest of Sprint 6, then Sprint 7 planning based on results

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

## Task Assignment — Sprint 6: Bug Fixes from On-Device Testing

**Full report:** `.planning/SPRINT-6-REPORT.md`
**Profiling data:** `.planning/PROFILING-RESULTS.md`

| Task ID | Task | Priority | Bug | Assigned Manager | Worker Pane | Files |
|---------|------|----------|-----|-----------------|-------------|-------|
| S6-T1 | System prompt identity ("Bittybot" not "Aya") | P1 | BUG-2 | RoseFinch (pane 1) | Pane 3 | `lib/features/inference/domain/prompt_builder.dart` |
| S6-T2 | Markdown rendering in chat bubbles | P1 | BUG-1 | RoseFinch (pane 1) | Pane 3 | `pubspec.yaml`, `lib/features/chat/presentation/widgets/chat_bubble_list.dart` |
| S6-T3 | Defer warmup after ModelReadyResponse (frame skips) | P1 | BUG-3 | RoseFinch (pane 1) | Pane 4 | `lib/features/inference/application/inference_isolate.dart` |
| S6-T4 | Crash recovery FD cleanup | P2 | BUG-5 | RoseFinch (pane 1) | Pane 4 | `lib/features/inference/application/llm_service.dart` |
| S6-T5 | Guard print for release builds | P2 | BUG-7 | WindyRobin (pane 2) | Pane 5 | `lib/core/diagnostics/performance_monitor.dart` |
| S6-T6 | Dead code cleanup (..take(3) + stale TODO) | P3 | BUG-4+6 | WindyRobin (pane 2) | Pane 5 | `lib/features/settings/application/settings_provider.dart`, `lib/features/model_distribution/model_distribution_notifier.dart` |

### Previous Sprints (complete)
| Sprint | Tasks | Status |
|--------|-------|--------|
| Sprint 1-2 | Phases 1-9 features + performance monitoring | Complete |
| Sprint 3 | OOM fix (mmap), cold start (SHA-256 skip), nCtx, loading indicator | Complete |
| Sprint 4 | Q3_K_S quantization, nThreads 6, startup jank fix, page warmup | Complete |
| Sprint 5 | posix_fadvise FFI, frame skip yields, P1 bug verification | Complete |

## Coordination Protocol

### MCP Agent Mail (REQUIRED)
All agents MUST use MCP Agent Mail. Project key: `/home/agent/git/bittybot`

**CRITICAL: Agent Mail does NOT wake other agents.** After sending ANY Agent Mail message, you MUST ALSO run an `ntm send` command to nudge the recipient into reading their inbox. Without this nudge, the recipient will never see your message.

```bash
# After EVERY send_message or reply_message, run this for EACH recipient:
ntm send bittybot --pane=<RECIPIENT_PANE> "You have Agent Mail from <your_name> re: <short subject>. Check inbox."
```

**Pane directory (PERSISTENT — resume these names on next sprint):**
| Pane | Agent Mail Name | Role | Program | Resume Instructions |
|------|----------------|------|---------|---------------------|
| 0 | BlueMountain | Orchestrator | Claude Code Opus 4.6 | `register_agent(name="BlueMountain")`, pull mowismtest, read AGENTS.md + SPRINT report, check inbox |
| 1 | RoseFinch | Manager A (manages panes 3+4) | Claude Code Opus 4.6 | `register_agent(name="RoseFinch")`, pull mowismtest, read AGENTS.md, check inbox, dispatch to panes 3+4 |
| 2 | WindyRobin | Manager B (manages pane 5) | Claude Code Opus 4.6 | `register_agent(name="WindyRobin")`, pull mowismtest, read AGENTS.md, check inbox, dispatch to pane 5 |
| 3 | (Codex worker) | Worker-1 | Codex GPT 5.2 xhigh | Boot via ntm from RoseFinch with explicit task instructions |
| 4 | (Codex worker) | Worker-2 | Codex GPT 5.2 xhigh | Boot via ntm from RoseFinch with explicit task instructions |
| 5 | (Codex worker) | Worker-3 | Codex GPT 5.2 xhigh | Boot via ntm from WindyRobin with explicit task instructions |

**On session start:**
1. `register_agent(project_key="/home/agent/git/bittybot", program="<your_program>", model="<your_model>")`
2. `fetch_inbox(project_key="/home/agent/git/bittybot", agent_name="<your_name>", include_bodies=true)`
3. Acknowledge any messages with `ack_required=true`
4. Check file reservations before editing

**Before editing files:**
- `file_reservation_paths(project_key="/home/agent/git/bittybot", agent_name="<your_name>", paths=["lib/features/chat/**"], ttl_seconds=3600, exclusive=true, reason="T-03")`

**When starting a task:**
- `send_message(...)` to your manager/orchestrator
- **THEN** `ntm send bittybot --pane=<MANAGER_PANE> "Agent Mail from <you>: starting <task>"`

**When finishing a task:**
- `send_message(...)` with completion details
- **THEN** `ntm send bittybot --pane=<MANAGER_PANE> "Agent Mail from <you>: <task> complete, ready for review"`
- `release_file_reservations(project_key="/home/agent/git/bittybot", agent_name="<your_name>")`

**Rule: No send_message without a matching ntm send.** Every Agent Mail message MUST be followed by an ntm nudge to the recipient's pane. This is non-negotiable.

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
