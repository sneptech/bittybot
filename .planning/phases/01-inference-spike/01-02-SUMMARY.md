---
phase: 01-inference-spike
plan: 02
subsystem: testing
tags: [dart, llm-as-judge, anthropic, gemini, claude-sonnet, gemini-flash, evaluation, coherence-scoring]

# Dependency graph
requires: []
provides:
  - "Standalone Dart CLI package (tool/) for LLM-as-judge evaluation of on-device inference results"
  - "judge_quick.dart: Tier-1 coherence check via Claude Sonnet using anthropic_sdk_dart"
  - "judge_full.dart: Tier-2 comprehensive evaluation via Gemini Flash using googleai_dart, batching 70+ languages"
  - "generate_report.dart: structured report with summary scorecard + expanded details, 3 output formats"
  - "Shared types (LanguageResult, PromptResult, JudgeScore, SpikeReport) with JSON serialization"
  - "Coherence rubric: 1-5 scoring on script/grammar/coherence with pass threshold >= 3"
affects:
  - 01-03
  - 01-04
  - 01-05

# Tech tracking
tech-stack:
  added:
    - "anthropic_sdk_dart 0.3.1 — Anthropic Claude API client"
    - "googleai_dart 3.0.0 — Google Gemini API client"
  patterns:
    - "dart:io aliased as 'io' prefix to avoid File class conflict with googleai_dart's own File model"
    - "googleai_dart imported with 'gai' prefix to prevent type ambiguity"
    - "Graceful API key gate pattern: check env var, print instructions, exit 0 (soft skip)"
    - "Batch evaluation pattern: group languages into chunks of 8 for Gemini Flash"
    - "Script-validation-only fallback when no judge scores present (PASS* label)"

key-files:
  created:
    - "tool/pubspec.yaml — standalone Dart package, anthropic_sdk_dart + googleai_dart deps"
    - "tool/lib/result_types.dart — PromptResult, LanguageResult, JudgeScore, SpikeReport with fromJson/toJson"
    - "tool/lib/coherence_rubric.dart — 1-5 rubric constants, passesRubric(), kRubricPrompt, kBatchRubricPrompt"
    - "tool/judge_quick.dart — Tier-1 judge via Claude Sonnet (must-have + script family reps)"
    - "tool/judge_full.dart — Tier-2 judge via Gemini Flash (all 70+ languages, batched)"
    - "tool/generate_report.dart — report generator: markdown/json/text, scorecard + expanded details"
  modified: []

key-decisions:
  - "Used dart:io with 'io' prefix alias because googleai_dart exports its own File class; prefix alias avoids ambiguity"
  - "Used Model.modelId('claude-sonnet-4-6') string form in anthropic_sdk_dart because SDK enum does not yet enumerate claude-sonnet-4-6"
  - "Anthropic response message content accessed via pattern matching on sealed MessageContent (MessageContentBlocks / MessageContentText), not .whereType<TextBlock>()"
  - "Report pass criterion: script validation >= 80% AND judge dimension scores >= 3 when available"
  - "googleai_dart prefix 'gai' prevents type collision; TextPart accessed as gai.TextPart"

patterns-established:
  - "Import prefix pattern: dart:io as 'io', googleai_dart as 'gai' — follow in any future Dart tool scripts"
  - "API key gate: always check env var first, exit 0 with instructions if absent (not exit 1)"
  - "Batch prompt pattern for Gemini: 8 languages per request, JSON array response with error padding"

requirements-completed: [MODL-06]

# Metrics
duration: 9min
completed: 2026-02-18
---

# Phase 1 Plan 02: Judge Tooling Summary

**LLM-as-judge evaluation CLI in Dart: Claude Sonnet quick check + Gemini Flash full suite + structured report generator, with graceful soft-skip when API keys absent**

## Performance

- **Duration:** 9 min
- **Started:** 2026-02-18T17:34:24Z
- **Completed:** 2026-02-18T17:43:30Z
- **Tasks:** 2
- **Files modified:** 6 created

## Accomplishments

- Standalone `tool/` Dart package with anthropic_sdk_dart and googleai_dart dependencies, resolving cleanly with `dart pub get`
- Quick judge script (Claude Sonnet) evaluates must-have languages and one representative per script family; exits 0 with setup instructions when ANTHROPIC_API_KEY absent
- Full judge script (Gemini Flash) batches all 70+ languages 8 at a time; exits 0 with setup instructions when GOOGLE_GENAI_API_KEY absent
- Report generator produces two-section markdown reports: summary scorecard (pass/fail at a glance) and expanded details with per-prompt sample translations, token throughput, and judge notes; also supports JSON and text formats
- All files analyze cleanly with zero Dart analyzer warnings

## Task Commits

1. **Task 1: Judge package, shared types, rubric, and both judge scripts** - `da4d682` (feat)
2. **Task 2: Report generator** - `7db74be` (feat)

**Plan metadata:** (pending)

## Files Created/Modified

- `tool/pubspec.yaml` — standalone Dart package with anthropic_sdk_dart + googleai_dart
- `tool/pubspec.lock` — resolved dependency lock file
- `tool/lib/result_types.dart` — shared data types: PromptResult, LanguageResult, JudgeScore, SpikeReport with JSON serialization
- `tool/lib/coherence_rubric.dart` — 1-5 rubric for script/grammar/coherence, passesRubric(), prompt text constants
- `tool/judge_quick.dart` — Tier-1 judge via Claude Sonnet, evaluates subset, writes -quick-judge.json
- `tool/judge_full.dart` — Tier-2 judge via Gemini Flash, evaluates all languages in batches, writes -full-judge.json
- `tool/generate_report.dart` — report generator with scorecard, family rollups, failures table, expanded details

## Decisions Made

- Used `dart:io` with `io` prefix alias (not bare import) to avoid `File` class collision with googleai_dart's exported `File` model
- Used `Model.modelId('claude-sonnet-4-6')` string form because the anthropic_sdk_dart 0.3.1 Models enum only enumerates up to claude-sonnet-4-5; string IDs are always accepted by the API
- Accessed Anthropic response content via Dart pattern matching on sealed `MessageContent` (`MessageContentBlocks` / `MessageContentText`) rather than `.whereType<TextBlock>()` which doesn't work on a sealed class
- Imported googleai_dart as `gai` prefix to prevent type ambiguity; `gai.TextPart` instead of `TextPart`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed dart:io File collision with googleai_dart**
- **Found during:** Task 1 (judge script creation)
- **Issue:** `googleai_dart` exports its own `File` model class, causing the bare `dart:io` import to conflict — `File(...).existsSync()` produced analyzer errors because it resolved to googleai_dart's File which has no such method
- **Fix:** Changed `import 'dart:io'` to `import 'dart:io' as io` in both judge scripts; all `File()`, `exit()`, `stdout`, `stderr`, `Platform` calls prefixed with `io.`; imported `googleai_dart` as `gai` prefix
- **Files modified:** tool/judge_full.dart, tool/judge_quick.dart
- **Verification:** `dart analyze tool/` reports no issues
- **Committed in:** da4d682 (Task 1 commit)

**2. [Rule 1 - Bug] Fixed MessageContent response text extraction**
- **Found during:** Task 1 (judge_quick.dart response parsing)
- **Issue:** Plan suggested `.whereType<TextBlock>()` on `response.content`, but `Message.content` is a sealed `MessageContent` class (not a List), so `whereType` doesn't exist on it
- **Fix:** Used Dart pattern matching: `switch(content) { case MessageContentText(value: final text): ... case MessageContentBlocks(value: final blocks): blocks.whereType<TextBlock>() ... }`
- **Files modified:** tool/judge_quick.dart
- **Verification:** `dart analyze tool/` reports no issues
- **Committed in:** da4d682 (Task 1 commit)

---

**Total deviations:** 2 auto-fixed (both Rule 1 — API type bugs from SDK version differences)
**Impact on plan:** Both fixes necessary for compilation and correctness. No scope creep. All plan features delivered as specified.

## Issues Encountered

- anthropic_sdk_dart 0.3.1 does not enumerate claude-sonnet-4-6 in its `Models` enum (latest is claude-sonnet-4-5). Used `Model.modelId('claude-sonnet-4-6')` string form instead, which the API accepts. This is a library version lag, not a functional issue.

## User Setup Required

None — judge scripts soft-skip when API keys are absent. When ready to run evaluations:

```bash
export ANTHROPIC_API_KEY=sk-ant-...
export GOOGLE_GENAI_API_KEY=...
```

## Next Phase Readiness

- Tool package is complete and ready to evaluate on-device test results once Phase 3 (on-device tests) produces results JSON
- Phase 1 plan 03 (on-device integration tests) can be run independently; its JSON output feeds directly into these judge scripts
- Report generator accepts results from plan 03 and judge outputs from this plan to produce the go/no-go spike report

---
*Phase: 01-inference-spike*
*Completed: 2026-02-18*

## Self-Check: PASSED

All created files verified present:
- tool/pubspec.yaml: FOUND
- tool/lib/result_types.dart: FOUND
- tool/lib/coherence_rubric.dart: FOUND
- tool/judge_quick.dart: FOUND
- tool/judge_full.dart: FOUND
- tool/generate_report.dart: FOUND
- .planning/phases/01-inference-spike/01-02-SUMMARY.md: FOUND

Task commits verified:
- da4d682: feat(01-02) judge package — FOUND
- 7db74be: feat(01-02) report generator — FOUND
