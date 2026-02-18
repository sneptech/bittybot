# Parallel Phase Resume Guide

> **STATUS: COMPLETE (2026-02-19)** — All worktrees merged into master. Phase 2 + Phase 3 branches deleted. This document is kept for reference only.

All three phases executed in parallel via git worktrees. All reached human verification checkpoints. This document is the orchestration plan for completing verification and merging.

## Worktree Status

| Phase | Branch | Directory | Status | Checkpoint |
|-------|--------|-----------|--------|------------|
| 1: Inference Spike | `master` | `~/git/bittybot` | Plans 01-01 to 01-04 complete, 01-05 at checkpoint | Android hardware test (model download, integration tests, 16KB alignment) |
| 2: Model Distribution | `phase/02-model-distribution` | `~/git/bittybot-phase-02` | Plans 02-01 to 02-02 complete, 02-03 at checkpoint (task 1/2) | Visual verification of download flow + routing on device |
| 3: App Foundation | `phase/03-app-foundation` | `~/git/bittybot-phase-03` | Plans 03-01 to 03-05 complete (task 3 = visual checkpoint) | Visual verification of dark theme, locale switching, RTL |

## Step 1: Verification Chain (per phase)

Run the post-phase verification workflow from `~/git/ai-agent-tools-and-tips/RECOMMENDED-WORKFLOW-CHAIN.md` in each worktree. Since these are foundation phases (not algorithmic), use the standard tier:

```
/scope-check
/change-summary
/gsd:verify-work
/update-claude-md
```

### Execution order

Run each phase's chain in its own worktree terminal. All three can run in parallel since they're independent branches.

**Phase 1** (most critical — go/no-go gate):
```fish
cd ~/git/bittybot
claude
# Then run: /scope-check, /change-summary, /gsd:verify-work, /update-claude-md
```

**Phase 2:**
```fish
cd ~/git/bittybot-phase-02
claude
# Then run: /scope-check, /change-summary, /gsd:verify-work, /update-claude-md
```

**Phase 3:**
```fish
cd ~/git/bittybot-phase-03
claude
# Then run: /scope-check, /change-summary, /gsd:verify-work, /update-claude-md
```

Each chain writes findings to `.planning/phases/VERIFICATION-CHAIN-P{N}.md` in its worktree.

## Step 2: Human Checkpoints

These require device testing. Can be done before, during, or after the verification chain.

### Phase 1: Android Hardware Test

The tiny-aya-global model (~2.14 GB) is being downloaded. Once ready:

```fish
cd ~/git/bittybot

# Push model to device
adb push tiny-aya-global-q4_k_m.gguf /sdcard/Download/

# Run integration tests
/home/max/Android/flutter/bin/flutter test integration_test/ --timeout none

# Retrieve results
adb shell "find /data/data/com.bittybot.bittybot/files -name 'spike_results.json'"
adb pull <path> ./spike_results_android.json

# Check 16KB page alignment
/home/max/Android/flutter/bin/flutter build apk --release
unzip -o build/app/outputs/flutter-apk/app-release.apk "lib/arm64-v8a/*.so" -d /tmp/apk_check
"$HOME/Android/Sdk/ndk/28.0.12674087/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-objdump" \
  -p /tmp/apk_check/lib/arm64-v8a/libllama.so | grep -A1 LOAD
```

iOS verification is deferred — Android results alone determine go/no-go.

After testing, resume the Phase 1 Claude session and report results. The agent will run LLM-as-judge evaluation and generate the spike report.

### Phase 2: Download Flow Visual Test

```fish
cd ~/git/bittybot-phase-02
/home/max/Android/flutter/bin/flutter run
```

Verify: first-launch download flow, progress bar, background/resume, post-download transition, subsequent launch skip.

### Phase 3: App Foundation Visual Test

```fish
cd ~/git/bittybot-phase-03
/home/max/Android/flutter/bin/flutter run
```

Verify: dark green theme (#0A1A0A), lime progress indicator, Lato font, 16sp body text, Arabic RTL, Japanese text, unsupported locale fallback.

## Step 3: Complete Checkpoints

After visual verification, resume each phase's Claude session and type "approved" (or describe issues). The agents will:
- Phase 1: Run LLM-as-judge, generate spike report, complete 01-05
- Phase 2: Complete 02-03 task 2 (unit tests), write SUMMARY
- Phase 3: Mark 03-05 Task 3 complete, finalize SUMMARY

## Step 4: Merge Worktrees

After all three phases are verified and complete:

```fish
cd ~/git/bittybot  # main worktree, master branch

# Merge Phase 2
git merge phase/02-model-distribution

# Merge Phase 3
git merge phase/03-app-foundation

# Or use the project merge script:
fish scripts/wt-merge.fish phase/02-model-distribution phase/03-app-foundation
```

**Expected conflicts (manual resolution needed):**
- `pubspec.yaml` — combine dependencies from Phase 2 + Phase 3
- `lib/main.dart` — both phases modify the app entry point
- `.planning/STATE.md` — reconcile position from all 3 phases
- `.planning/ROADMAP.md` — reconcile progress table

**No conflict (disjoint paths):**
- `.planning/phases/01-*/*` vs `02-*/*` vs `03-*/*`
- Phase-specific source code (different services, different widgets)

## Step 5: Reconcile State

After merging, update STATE.md and ROADMAP.md to reflect all three phases' progress. Then proceed to Phase 4 (Core Inference Architecture) which depends on both Phase 2 and Phase 3 being complete.

## Step 6: Clean Up Worktrees

```fish
cd ~/git/bittybot
git worktree remove ../bittybot-phase-02
git worktree remove ../bittybot-phase-03
# Also clean the stale one:
git worktree remove ../bittybot-phase-02-phase-03
```

## Notes

- Flutter is at `/home/max/Android/flutter/bin/flutter` (not on PATH)
- Phase 1 is the go/no-go gate: if Cohere2 doesn't load on Android, Phases 2-3 code is still valid but the inference binding choice changes
- Phase 2 and 3 can merge independently — no dependency between them
- Phase 4 requires BOTH Phase 2 and Phase 3 merged before starting
