# Context Handoff Failure Analysis

**Case study:** BittyBot (9-phase Flutter app, 5 phases completed, 138 commits)
**Audience:** Mowism workflow harness developers
**Purpose:** Document systemic failures in how the orchestration system propagates context between phases, with actionable fixes

---

## 1. Executive Summary

The code is fine. The documentation handoff is broken.

BittyBot's 5 completed phases produced a healthy, well-structured codebase: 0 merge conflicts on source files, 0 reverts, 0 deleted source files, and clean additive extension patterns across all shared files (settings provider grew from 2 fields to 4, ARB localization files grew from 65 keys to 87, all without overwrites). The architecture is sound.

The problem is that the orchestration system fails to propagate context upward from phase-level artifacts to project-level canonical documents. Each phase produces rich context -- learned patterns, architectural decisions, API surfaces, research findings -- but this context stays buried in phase-level SUMMARY.md, CONTEXT.md, and RESEARCH.md files. The project-level documents that executor agents actually read (CLAUDE.md, PROJECT.md) become progressively more stale and contradictory as phases accumulate.

The result: later phases operate with incomplete or incorrect reference documentation. The code still works (because agents read the actual source files they modify), but debugging time increases, architectural intent is lost, and orphaned code accumulates silently.

Five distinct failure modes were identified, all stemming from the same root cause: the workflow has no enforced propagation step after phase completion.

---

## 2. Failure Mode 1: Canonical Reference Document Not Updated After Phase Completion

### The Problem

The project's canonical reference document (CLAUDE.md in BittyBot's case) is the first file every executor agent reads. It contains code conventions, learned patterns, build configuration, and architectural decisions. It is the primary mechanism for transmitting institutional knowledge across agent sessions.

After a phase completes, learned patterns and decisions remain in phase-level SUMMARY.md files and the STATE.md accumulated context section. No automated or enforced step propagates them upward to the canonical reference document.

### Evidence from BittyBot

**Phase 4 (Core Inference Architecture)** produced 21 architectural decisions, all documented in STATE.md's "Accumulated Context" section (lines 87-102). These include critical patterns like:

- Drift row type naming collision resolution (`import 'app_database.dart' as db`)
- Inference isolate must be a top-level function for `Isolate.spawn`
- Manual nPredict counting (ContextParams.nPredict is construction-time only)
- Cooperative stop via closure-scope flag pattern
- modelReadyProvider uses WidgetsBindingObserver for OS-kill recovery

CLAUDE.md has **zero** Phase 4 learned patterns. It ends at "Learned Patterns (Phase 3)". An agent executing Phase 6 (Chat UI) -- which directly consumes Phase 4's providers -- would read CLAUDE.md and find no documentation of the inference architecture's patterns, conventions, or API surface.

**Phase 1 (Inference Spike)** produced extensive infrastructure: a judge tooling ecosystem (Claude Sonnet + Gemini Flash evaluation harness), a 70-language test corpus, timestamp-bucket streaming verification, and Cantonese particle validation. Only 4 lines about Phase 1 exist in CLAUDE.md (binding choice, NDK version, model params, Aya template). The test infrastructure, evaluation patterns, and research findings are invisible to later phases.

### Impact

Agents in later phases operate with stale reference documentation. They must independently rediscover patterns that were already established, or worse, they implement conflicting approaches because they don't know the established pattern exists.

### Systemic Pattern

This failure occurs in any multi-phase project where:
1. The canonical reference document is manually maintained
2. Phase completion verification does not check whether the reference document was updated
3. Phase-level artifacts are the only place decisions are recorded

---

## 3. Failure Mode 2: Stale and Contradictory Information in Canonical Reference

### The Problem

When a phase makes a decision that changes or contradicts a previous phase's documented pattern, the canonical reference document is not updated. Worse, phases sometimes write speculative forward references ("Phase N+1 will do X") that become incorrect when the future phase makes a different decision.

### Evidence from BittyBot

CLAUDE.md line 87 states:

> `appStartupProvider` is a `@Riverpod(keepAlive: true) Future<void>` function-provider. **Phase 4 extends it by adding `await ref.watch(modelReadyProvider.future)`.**

This was written during Phase 3 planning as a forward-looking statement about Phase 4's intended approach. Phase 4 explicitly decided NOT to do this. Instead, it implemented a "partial-access pattern" where the model loads independently via `modelReadyProvider`, and `appStartupProvider` remains settings-only. The Phase 4 verification report confirms this (line 66 of 04-VERIFICATION.md):

> `appStartupProvider` remains settings-only [...] Design comment explains partial-access rationale. No `modelReadyProvider` dependency.

The contradiction is still live in CLAUDE.md. An agent reading it would implement startup integration incorrectly -- awaiting `modelReadyProvider` inside `appStartupProvider`, which would block app startup on model load (~85 seconds on the target device).

STATE.md also contains the stale forward reference (line 86) AND the correction (line 96), making it internally contradictory:

> Line 86: `appStartupProvider is @Riverpod(keepAlive: true) Future<void> -- Phase 4 extends with modelReadyProvider`
> Line 96: `appStartupProvider remains settings-only: model loads independently via modelReadyProvider (partial-access pattern)`

### Impact

Contradictory documentation is worse than missing documentation. Missing information forces an agent to investigate; contradictory information gives it confidence in the wrong answer.

### Systemic Pattern

This failure occurs when:
1. Planning phases write speculative forward references about future phases' behavior
2. The future phase makes a different decision but only records it in its own artifacts
3. No reconciliation step checks the canonical reference for stale forward references

---

## 4. Failure Mode 3: Architectural Replacements Not Documented

### The Problem

When Phase N completely replaces Phase N-1's architectural approach to a subsystem, the replacement is not documented in any project-level artifact. The replaced code becomes orphaned -- it exists in the codebase, compiles, but is never called. No mechanism detects that Phase N's integration plan conflicts with Phase N-1's exported API surface.

### Evidence from BittyBot

**Phase 2 (Model Distribution)** built a complete download orchestration system:
- `ModelDistributionNotifier` with an 11-state sealed class state machine
- `DownloadScreen` UI with progress indicators, speed/ETA display, retry logic
- App routing in `app.dart` that gates on download state

**Phase 3 (App Foundation)** completely replaced `app.dart` with a different startup flow:
- `AppStartupWidget` pattern that gates on `appStartupProvider`
- `ModelLoadingScreen` (a different loading screen, not Phase 2's `DownloadScreen`)
- `MainShell` as the post-startup container

The merge log in STATE.md (line 168) documents the conflict resolution:

> `app.dart: Phase 3's version used as canonical shell; Phase 2's model distribution routing deferred to Phase 4 wiring`

But "deferred to Phase 4 wiring" never happened. Phase 4 built the inference architecture but did not re-wire Phase 2's download flow into Phase 3's startup flow. The result:

- `ModelDistributionNotifier.initialize()` is **never called** anywhere in the app
- `DownloadScreen` exists in the codebase but is **never imported or instantiated**
- The first-launch model download flow is **completely non-functional**

This is the most severe integration failure found. A complete subsystem (first-launch download) is broken, and no phase's documentation flags it. The merge log hints at the issue ("deferred to Phase 4 wiring") but does not create a tracked blocker or TODO.

### Impact

Orphaned subsystems accumulate silently. The code compiles and tests pass (because the orphaned code is never exercised). The failure only surfaces at runtime when a user triggers the orphaned flow.

### Systemic Pattern

This failure occurs when:
1. Parallel phases modify the same architectural integration point (e.g., app routing)
2. Merge resolution picks one phase's approach and "defers" the other's re-integration
3. The deferred re-integration is not tracked as a blocking task for a specific future phase
4. No cross-phase integration verification checks that all completed phases' exports are actually reachable from the app entry point

---

## 5. Failure Mode 4: Key Decisions Table Never Updated

### The Problem

PROJECT.md contains a "Key Decisions" table intended to be the authoritative log of project-wide architectural decisions. The table was populated during project initialization and never updated afterward.

### Evidence from BittyBot

PROJECT.md's Key Decisions table contains exactly 5 entries, all from pre-Phase 1 initialization:

| Decision | Status |
|----------|--------|
| Download model on first launch | Revisit |
| Flutter/Dart | Pending |
| Tiny Aya Global model choice | Pending |
| Dark theme with Cohere green palette | Pending |
| Text-only v1 | Pending |

The file's footer reads: `Last updated: 2026-02-19 after research`.

Meanwhile, across 5 phases, the project accumulated 40+ decisions (Phase 1: ~7, Phase 2: ~4, Phase 3: ~9, Phase 4: ~21, Phase 5: ~10). All of these are recorded in STATE.md's "Accumulated Context" section or in phase-level SUMMARY.md files. None were propagated to PROJECT.md.

The "Status" column of every decision still reads "Pending" or "Revisit" despite multiple decisions having been validated by working code.

### Impact

PROJECT.md becomes a dead document. Agents that read it for project-level decision context get only the initial pre-implementation speculation. The actual decisions made during implementation -- which often override the initial speculation -- are invisible at the project level.

### Systemic Pattern

This failure occurs when:
1. Project initialization creates a decisions table with planned/speculative entries
2. No phase completion step appends validated decisions to the table
3. No phase completion step updates the status of decisions that were resolved

---

## 6. Failure Mode 5: Phase-Level Context Not Visible to Later Phases

### The Problem

Phase planning artifacts (CONTEXT.md, RESEARCH.md, SUMMARY.md) contain rich context that later phases need but never see. Executor agents for Phase N read CLAUDE.md and the specific files @-referenced in their PLAN.md. They do not read earlier phases' planning documents unless explicitly directed to do so.

### Evidence from BittyBot

**Phase 1 research findings** include version parity risks between the Cohere2 tokenizer in llama.cpp and the model's expected tokenizer. This is a production correctness risk that affects every phase using inference. The finding exists only in Phase 1's planning artifacts -- it was never resolved, propagated, or even referenced by Phases 4 or 5.

**Phase 1 test infrastructure** includes a judge tooling ecosystem (automated evaluation using Claude Sonnet + Gemini Flash), a 70-language test corpus with 4 must-have languages at 18 prompts each, and timestamp-bucket streaming verification. None of this is documented anywhere that Phase 5 or 6 agents would find it. If Phase 6 needs to write integration tests for the chat UI, the agent would build a new test framework from scratch, unaware that a sophisticated evaluation harness already exists.

**Phase 2 learned patterns** about `background_downloader` (use `registerCallbacks()+enqueue()`, not `download()`) are in CLAUDE.md because they happened to be propagated. But the broader architectural context -- the 11-state download state machine, the retry logic, the SHA-256 verification flow -- is only in Phase 2's planning docs. When a future phase needs to fix the broken download flow, it would need to rediscover this architecture.

### Impact

The @-reference system in PLAN.md is powerful for narrowing agent focus, but it creates tunnel vision. Agents see exactly what the planner referenced and nothing else. If the planner didn't know about Phase 1's test corpus or Phase 2's state machine, those artifacts become invisible.

### Systemic Pattern

This failure occurs when:
1. Phase planning is done by a planner agent with limited context about earlier phases' artifacts
2. The @-reference system in PLAN.md is the sole mechanism for context injection
3. No "exports manifest" exists for completed phases that planners can reference
4. Research findings and infrastructure decisions from earlier phases are not surfaced to planners

---

## 7. Root Cause Analysis

All five failure modes stem from the same structural deficiency: **the workflow has no enforced propagation step after phase completion.**

The current workflow lifecycle is:

```
Plan Phase -> Execute Phase -> Verify Phase -> Mark Complete
```

The missing step is:

```
Plan Phase -> Execute Phase -> Verify Phase -> PROPAGATE CONTEXT -> Mark Complete
```

Specific root causes:

1. **Phase verification checks if code works, not if documentation is current.** The verification step examines source files, test results, and requirement coverage. It does not check whether CLAUDE.md, PROJECT.md, or any project-level document was updated.

2. **Context propagation is manual and optional.** CLAUDE.md updates depend on the executor agent voluntarily adding learned patterns. Some phases do this (Phase 2 and 3 patterns are in CLAUDE.md); others don't (Phase 1 and 4 have no learned patterns section). There is no systematic enforcement.

3. **STATE.md accumulates decisions linearly but does not enforce synchronization.** STATE.md's "Accumulated Context" section grows with each phase, but nothing requires its contents to be reconciled with CLAUDE.md. The two documents diverge over time.

4. **The @-reference system creates a narrow view.** PLAN.md files reference specific source files for the executor to read. This is effective for focused execution but means agents only see what the planner anticipated they would need. Emergent context from earlier phases -- test infrastructure, research risks, architectural patterns -- falls outside the reference window.

5. **Speculative forward references create time bombs.** When Phase N writes "Phase N+1 will do X" in a canonical document, it creates a statement that may become false. No mechanism detects or corrects these statements when Phase N+1 makes a different decision.

6. **Merge conflict resolution creates implicit TODOs that are never tracked.** When parallel phases conflict at merge time, the resolution often defers one phase's integration. This deferral is noted in the merge log but not tracked as a blocking task, allowing it to be silently forgotten.

---

## 8. Recommended Fixes for the Mowism Workflow

### a) Post-Phase Context Propagation Step

After phase verification passes and before the phase is marked complete, require a mandatory propagation step that:

1. **Adds a "Learned Patterns (Phase N)" section to the canonical reference document.** Extract patterns from the phase's SUMMARY.md files. Focus on patterns that affect how future agents should write code (naming conventions, API gotchas, framework quirks, performance constraints).

2. **Scans for and corrects stale forward references.** Search the canonical reference for any mention of the completing phase by number or name. If any statement says "Phase N will do X," replace it with what Phase N actually did.

3. **Appends key decisions to the decisions documentation.** Extract decisions from SUMMARY.md `key-decisions` frontmatter and append them to PROJECT.md's decisions table with a "Validated" status.

4. **Flags orphaned code from replaced approaches.** If the phase modified files originally created by a different phase, check whether the original phase's exported API surface is still reachable from the app entry point. If not, create a tracked TODO.

**Implementation:** This could be a new planner/executor step type (e.g., `propagate-context`) that runs after `verify-phase` and before `mark-complete`. The propagation agent reads the phase's SUMMARY.md files, the current CLAUDE.md, and the current PROJECT.md, then produces diffs to each.

### b) Prohibition on Speculative Forward References

The canonical reference document should never contain statements of the form "Phase N+1 will do X" or "Future phase extends this by doing Y." These statements have a high probability of becoming stale.

**Rule:** Document what IS, not what's planned. Forward-looking architectural intent belongs in ROADMAP.md or phase-level CONTEXT.md, not in the canonical reference that agents trust as ground truth.

**Implementation:** Add a lint rule to the verification step that searches the canonical reference for forward-looking language patterns (e.g., "Phase N will", "Phase N extends", "future phase"). Flag any matches for removal or relocation.

### c) Architectural Replacement Detection

When a phase's PLAN.md modifies files that were originally created by a previous phase, the planner should detect this as a potential architectural replacement and require explicit documentation.

**Trigger conditions:**
- PLAN.md references a file in a different phase's feature directory
- PLAN.md replaces or significantly modifies a file that a previous phase created
- PLAN.md introduces a new implementation of a subsystem that a previous phase already implemented

**Required documentation when triggered:**
- What is being replaced and why
- Whether the replaced code should be removed or preserved
- Whether the replaced code's consumers need to be re-wired
- A tracked TODO if re-wiring is deferred

**Implementation:** During plan generation, cross-reference the files being modified against a registry of which phase created each file. If a cross-phase modification is detected, inject a "Replacement Impact" section into the plan that the executor must address.

### d) Automated Key Decisions Extraction

After each phase completes, automatically extract decisions from SUMMARY.md frontmatter (`key-decisions` field) and append them to PROJECT.md's decisions table.

**Format:**
```
| Decision | Phase | Rationale | Status |
|----------|-------|-----------|--------|
| [extracted from key-decisions] | N | [from SUMMARY.md] | Validated |
```

**Implementation:** A post-phase script that parses SUMMARY.md YAML frontmatter, extracts the `key-decisions` array, and appends rows to PROJECT.md. This is mechanical and does not require agent reasoning.

### e) Phase Exports Manifest

Each completed phase should produce a brief "exports" document listing the artifacts that later phases must be aware of. This document would be automatically injected into the planning context for dependent phases.

**Manifest contents:**
- **Providers:** Name, type (keepAlive/auto-dispose), what they provide, how to access them
- **Widgets:** Name, purpose, required parameters, where they fit in the widget tree
- **Domain types:** Key classes, sealed hierarchies, value objects
- **File ownership:** Which directories/files this phase "owns" and should not be modified without consultation
- **Test infrastructure:** Test utilities, fixtures, evaluation harnesses that later phases can reuse
- **Open risks:** Unresolved research findings that affect downstream phases

**Implementation:** The propagation step (fix a) generates this manifest from the phase's SUMMARY.md files and source code analysis. The manifest is stored at `.planning/phases/NN-name/EXPORTS.md`. The planner for any dependent phase automatically reads it.

### f) Cross-Phase Reference Injection

When planning Phase N, automatically inject a summary of the exports from all completed prerequisite phases into the planning context. This goes beyond the @-reference system, which requires the planner to know what to reference.

**What to inject:**
- The EXPORTS.md manifest from each prerequisite phase (see fix e)
- Any unresolved risks or open TODOs from prerequisite phases
- The list of files each prerequisite phase created or modified

**Implementation:** The `plan-phase` command reads the dependency graph, identifies all transitive prerequisites, collects their EXPORTS.md manifests, and includes them in the planning prompt. This ensures the planner sees the full API surface it is building on, not just the files it guesses it will need.

### g) Verification Scope Expansion

Phase verification currently checks:
- Do the source files exist and compile?
- Are the requirements covered?
- Do the key links (provider wiring, imports) work?

It should additionally check:
- **Documentation currency:** Is the canonical reference document consistent with this phase's decisions? Are there stale forward references?
- **Integration completeness:** Are all previously completed phases' exports still reachable from the app entry point? (Catches the Phase 2 download flow orphaning.)
- **Cross-document consistency:** Do STATE.md, CLAUDE.md, and PROJECT.md agree on key facts, or do they contradict each other?

**Implementation:** Add a "documentation verification" sub-step to the verification agent's checklist. This agent reads CLAUDE.md, STATE.md, and PROJECT.md, compares them against the phase's SUMMARY.md decisions, and flags any contradictions, missing entries, or stale references.

---

## 9. Impact Assessment

### Phases Affected by Bad Context

| Phase | Impact | Description |
|-------|--------|-------------|
| Phase 3 | MEDIUM | Wrote a speculative forward reference about Phase 4's startup behavior that turned out to be wrong. The reference persists in CLAUDE.md and STATE.md. |
| Phase 4 | LOW | Made the correct decision (partial-access pattern) despite the forward reference, but did not correct the canonical docs. The error compounds for future phases. |
| Phase 5 | HIGH | App shows wrong screen on device during human verification. Root cause is the Phase 2/Phase 3 routing replacement that was never re-wired. The download flow is broken, but Phase 5's executor had no visibility into this because the orphaning was never documented. |
| Phase 6 (future) | CRITICAL | Would operate with a CLAUDE.md that has no Phase 4 learned patterns, a contradictory startup description, no provider API surface documentation, and no awareness of the broken download flow. |

### Work Wasted

- **Code waste:** Minimal. The codebase is healthy. Phase 2's download orchestrator is complete and correct code -- it just needs to be wired back into the startup flow. No code needs to be rewritten.
- **Debugging time:** Significant. The Phase 5 "wrong screen" investigation required 6 audit agents analyzing 5 phases to diagnose. The root cause (orphaned Phase 2 routing) could have been caught immediately if the merge resolution had created a tracked blocker.
- **Documentation debt:** 5 phases of accumulated decisions and patterns not in CLAUDE.md. Retroactive propagation is now a larger task than it would have been if done incrementally.

### Risk to Future Phases

Phase 6 (Chat UI) is the next phase to execute. It directly consumes Phase 4's `chatNotifierProvider`, `chatRepositoryProvider`, and `inferenceRepositoryProvider`. Without the recommended fixes:

1. The Phase 6 executor would read CLAUDE.md and find no "Learned Patterns (Phase 4)" section
2. It would read the wrong startup integration pattern (CLAUDE.md line 87)
3. It would have no documentation of the InferenceCommand/InferenceResponse type catalog
4. It would have no awareness of the broken download flow
5. It would potentially build another test framework without knowing Phase 1's evaluation harness exists

The cost of fixing the propagation system now is far lower than the cost of debugging the cascading failures it will produce across Phases 6-9.

---

## Appendix: File References

All paths are relative to the BittyBot project root.

| File | Role | Staleness |
|------|------|-----------|
| `CLAUDE.md` | Canonical agent reference | Stale after Phase 3 (no Phase 4+ patterns, contains contradictory forward reference) |
| `.planning/PROJECT.md` | Key decisions log | Frozen at pre-Phase 1 (5 entries, all "Pending") |
| `.planning/STATE.md` | Accumulated context | Current but internally contradictory (lines 86 vs 96) and not synchronized with CLAUDE.md |
| `.planning/phases/04-core-inference-architecture/04-VERIFICATION.md` | Phase 4 verification | Documents 21 decisions and 15 key links, none propagated to project-level docs |
| `.planning/phases/04-core-inference-architecture/04-05-SUMMARY.md` | Phase 4 Plan 5 summary | Contains key-decisions frontmatter that should have been extracted to PROJECT.md |

---

*Report generated: 2026-02-25*
*Case study: BittyBot (sneptech/bittybot)*
*Intended audience: Mowism workflow harness developers*
