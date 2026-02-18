# BittyBot

Fully offline multilingual chat and translation app for travelers, powered by Cohere Tiny Aya Global 3.35B on-device via llama.cpp. Built with Flutter.

## GSD Commands

This project uses GSD for structured development. Key commands:

- `/gsd:progress` — Check project status and next action
- `/gsd:discuss-phase N` — Gather context before planning a phase
- `/gsd:plan-phase N` — Create detailed execution plan for a phase
- `/gsd:execute-phase N` — Execute all plans in a phase
- `/gsd:resume-work` — Resume from previous session
- `/gsd:help` — Full command reference

## Parallel Phase Execution

Independent phases run simultaneously via git worktrees. See `.planning/PARALLEL-EXECUTION.md` for the full workflow. Scripts: `scripts/wt-phase.fish`, `scripts/wt-merge.fish`.

**Worktree rules** (when working in a worktree):

1. **Stay on your branch.** Do not checkout, merge, or rebase. GSD commits to whatever branch is checked out — that's your phase branch.
2. **Own your phase directory only.** Only modify files under your phase's `.planning/phases/NN-*/` directory. Do not edit other phases' planning files.
3. **Shared state files are read-only.** Do not manually edit `.planning/STATE.md` or `.planning/ROADMAP.md` — these get reconciled during merge.
4. **Source code is yours to write.** Create and modify `lib/`, `test/`, `pubspec.yaml`, etc. as needed. Conflicts with parallel phases are resolved at merge time.

## Phase Dependency Graph

```
Phase 1: Inference Spike
  ├── Phase 2: Model Distribution        ← can run parallel with Phase 3
  ├── Phase 3: App Foundation             ← can run parallel with Phase 2
  └── Phase 4: Core Inference Arch        ← requires Phase 2 AND Phase 3
        ├── Phase 5: Translation UI       ← can run parallel with Phase 6
        ├── Phase 6: Chat UI              ← can run parallel with Phase 5
        │     ├── Phase 7: Chat History   ← can run parallel with Phase 9
        │     └── Phase 9: Web Search     ← can run parallel with Phase 7
        └── Phase 8: Chat Settings        ← requires Phase 7
```

Parallel windows:
- **After Phase 1:** Phase 2 || Phase 3
- **After Phase 4:** Phase 5 || Phase 6
- **After Phase 6:** Phase 7 || Phase 9

## Code Conventions

- **Language:** Dart / Flutter
- **State management:** Riverpod
- **Local DB:** Drift (SQLite)
- **Inference:** llama.cpp via Flutter binding (TBD in Phase 1)
- **Testing:** TDD — write tests before implementation
- **Commits:** Atomic, one logical change per commit

## Learned Patterns (Phase 2)

- **Do NOT use `ColorFiltered` with `BlendMode.saturation`** for greyscale effects — Flutter bug #179606 greyscales the entire screen. Use two separate image assets with `AnimatedCrossFade` instead.
- **`background_downloader`**: Use `registerCallbacks()+enqueue()` not `download()` — `download()` only provides `void Function(double)` for progress, not full `TaskProgressUpdate` with speed/ETA.
- **Riverpod dialog pattern**: Use `ConsumerStatefulWidget` with a `_dialogVisible` bool to prevent dialogs from double-showing on state rebuild.
- **Chunked SHA-256**: Use `AccumulatorSink` from `package:convert` (not `dart:convert`) with 64KB `RandomAccessFile` chunks in a `compute()` isolate — never load the full file into RAM.
- **Feature structure**: Model distribution code lives under `lib/features/model_distribution/` with `widgets/` subdirectory for UI components.
