---
created: 2026-02-25T13:45:00.000Z
title: Two system prompt modes — translation and educational
area: ui
files:
  - integration_test/helpers/language_corpus.dart:116-118
  - lib/features/settings/
---

## Problem

Currently no system prompt is used with the Aya model at all. The chat template goes straight from `<|USER_TOKEN|>` to `<|CHATBOT_TOKEN|>` with no `<|SYSTEM_TOKEN|>` turn. This likely contributes to the model sometimes responding in English instead of the target language (e.g., Mandarin test failure).

## Solution

Two system prompt modes, toggled by the user via a switch/mode in the UI:

### Mode 1: Translation (default)
Straight translation. System prompt should:
- Instruct the model to always respond in the requested target language
- NOT assume the user speaks English — the user's own language may vary
- Keep responses concise and direct

### Mode 2: Educational
Explains translations more pedagogically. System prompt should:
- Provide the translation AND a pronunciation guide
- For different scripts (e.g., English <-> Thai), write out romanization/pinyin-style phonetics
- Explain nuances, formality levels, or context where relevant
- Show a small disclaimer above the text input: "Pronunciation guide may not be fully accurate"

### Notes
- The Aya `<|SYSTEM_TOKEN|>` turn format is: `<|START_OF_TURN_TOKEN|><|SYSTEM_TOKEN|>{message}<|END_OF_TURN_TOKEN|>`
- Placed before the `<|USER_TOKEN|>` turn
- Tiny 3.35B model — educational mode is best-effort, disclaimer needed
- System prompt should be locale-aware (written in the user's UI language, not hardcoded to English)
- Phase 4+ work — depends on Core Inference Architecture being in place
