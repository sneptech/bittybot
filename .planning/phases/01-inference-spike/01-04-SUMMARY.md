---
phase: 01-inference-spike
plan: 04
subsystem: testing
tags: [flutter, multilingual, integration_test, tdd, language_corpus, report_writer, script_validation]

# Dependency graph
requires:
  - phase: 01-01
    provides: Language corpus with 70+ languages and travel phrases
  - phase: 01-03
    provides: ModelLoader helper for on-device inference

enables:
  - phase: 01-05
    provides: Multilingual test suite and JSON report for hardware verification
---

## What Changed

### key-files
created:
  - integration_test/spike_multilingual_test.dart
  - integration_test/helpers/report_writer.dart

### Summary

Multilingual translation integration test covering all 70 Aya-supported languages with script validation, Cantonese particle distinction checks, and JSON result export for LLM-as-judge consumption.

### Details

**Task 1: Multilingual test + report writer**
- `spike_multilingual_test.dart`: Two test groups — Priority Languages (4 mustHave with per-prompt travel phrase assertions) and Standard Languages (66 with reference sentence script validation)
- Model loaded once via `setUpAll()` to avoid re-loading 2.14 GB per test
- Cantonese-specific check validates particles (㗎, 囉, 喇, 嘅, 咁, 咋, 㖖) that distinguish from Mandarin
- Latin-script languages use relaxed validation (LLM-as-judge handles quality); non-Latin scripts have strict Unicode range assertions
- `report_writer.dart`: Collects `LanguageResultData` / `PromptResultData` and writes JSON to app documents directory, compatible with `tool/lib/result_types.dart` schema
- Results written in `tearDownAll()` with `adb pull` instructions printed to console

### Deviations

None — implementation matches plan specification.

## Self-Check: PASSED

- [x] Multilingual test covers all 70 languages from language_corpus.dart
- [x] Priority languages have per-prompt travel phrase assertions
- [x] Cantonese has explicit particle validation
- [x] Non-Latin script languages have strict script validation
- [x] Report writer exports JSON compatible with judge tooling schema
- [x] Model loaded once in setUpAll, results written once in tearDownAll
