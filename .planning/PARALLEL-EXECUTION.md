# Parallel Phase Execution

## How It Works

This project uses git worktrees to run independent GSD phases simultaneously. Each worktree gets its own branch, its own directory, and its own Claude Code session. GSD doesn't know about worktrees — it just commits to whatever branch is checked out.

**Key constraint:** `discuss` and `plan` require user interaction. `execute` is autonomous. Parallelize at the execute boundary.

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/wt-phase.fish <NN> <slug>` | Create worktree + branch for a phase |
| `scripts/wt-merge.fish <branch1> <branch2>` | Merge completed phase branches back |

## Workflow

The optimal pattern is **three terminals**: the predecessor phase executes autonomously while you discuss and plan the next two phases in parallel worktrees. Then when the predecessor finishes, pull its code into the worktrees and execute both.

### 1. Execute predecessor + setup sibling phases (3 terminals)

```fish
# Terminal 1: kick off the predecessor phase on master
cd ~/git/bittybot && claude
  → /gsd:execute-phase 1    # autonomous — runs unattended

# Terminal 2: while Phase 1 runs, discuss + plan Phase 2
fish scripts/wt-phase.fish 02 model-distribution
cd ../bittybot-phase-02 && claude
  → /gsd:discuss-phase 2    # interactive — you answer questions
  → /gsd:plan-phase 2       # interactive — you approve the plan

# Terminal 3: while Phase 1 runs, discuss + plan Phase 3
fish scripts/wt-phase.fish 03 app-foundation
cd ../bittybot-phase-03 && claude
  → /gsd:discuss-phase 3    # interactive — you answer questions
  → /gsd:plan-phase 3       # interactive — you approve the plan
```

By the time you finish planning both sibling phases, Phase 1 may already be done or close to it.

### 2. Pull predecessor results into worktrees

The worktrees were created from HEAD before the predecessor executed, so they don't have its code yet. After Phase 1 finishes on master:

```fish
cd ../bittybot-phase-02 && git merge master
cd ../bittybot-phase-03 && git merge master
```

No conflicts — Phase 1's code is in `lib/`, the planning files from discuss/plan are in disjoint `.planning/phases/` directories.

### 3. Execute sibling phases in parallel (autonomous)

Kick off execution in each worktree's Claude session. With `mode: "yolo"` in config.json, the agents run unattended.

```fish
# Terminal 2 (already in bittybot-phase-02 claude session):
  → /gsd:execute-phase 2

# Terminal 3 (already in bittybot-phase-03 claude session):
  → /gsd:execute-phase 3
```

Both agents now work independently. You can walk away.

### 4. Merge when both finish

From the main worktree:

```fish
cd ~/git/bittybot
fish scripts/wt-merge.fish phase/02-model-distribution phase/03-app-foundation
```

The merge script:
- Merges each branch sequentially into the current branch
- Auto-resolves `.planning/STATE.md` and `.planning/ROADMAP.md` conflicts (takes ours, reminds you to reconcile)
- Halts on source code conflicts (`pubspec.yaml`, `lib/`, etc.) for manual resolution
- Prints worktree cleanup commands for you to review

### 5. Reconcile and continue

After merging, update STATE.md and ROADMAP.md to reflect both phases' progress. Then proceed to the next sequential phase (e.g., Phase 4) on the main branch.

### Generalizing to other windows

The same pattern applies to every parallel window:

| Predecessor executing | You discuss + plan | Then execute in parallel |
|----------------------|-------------------|------------------------|
| Phase 1 on master | Phase 2 + Phase 3 in worktrees | Phase 2 ‖ Phase 3 |
| Phase 4 on master | Phase 5 + Phase 6 in worktrees | Phase 5 ‖ Phase 6 |
| Phase 6 on master | Phase 7 + Phase 9 in worktrees | Phase 7 ‖ Phase 9 |

## What Conflicts and What Doesn't

**No conflict (disjoint paths):**
- `.planning/phases/02-*/*` vs `.planning/phases/03-*/*`
- Phase-specific source code (different services, different widgets)

**Will conflict (expected, handled):**
- `.planning/STATE.md` — both phases update position → auto-resolve, manual reconcile
- `.planning/ROADMAP.md` — both phases update progress table → auto-resolve, manual reconcile
- `pubspec.yaml` — both add dependencies → manual merge (combine deps)
- `lib/main.dart` — both may modify scaffold → manual merge

## Parallel Windows

Only phases with no dependency between them can run in parallel:

| After completing | Run in parallel | Then sequential |
|-----------------|----------------|-----------------|
| Phase 1 | Phase 2 ‖ Phase 3 | Phase 4 (needs both) |
| Phase 4 | Phase 5 ‖ Phase 6 | — |
| Phase 6 | Phase 7 ‖ Phase 9 | Phase 8 (needs Phase 7) |

## Notes

- Both worktrees share the same git object store. Heavy builds in parallel will compete for disk I/O and CPU.
- GSD's `branching_strategy` stays `"none"` — the worktree creates the branch, GSD is oblivious.
- If a phase execution fails mid-way, use `/gsd:resume-work` in that worktree's Claude session.
