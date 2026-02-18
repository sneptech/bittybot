/// Shared coherence scoring rubric for BittyBot LLM-as-judge evaluation.
///
/// This rubric is injected into every judge LLM call so that scores from
/// Claude Sonnet (quick check) and Gemini Flash (full suite) are comparable.
library coherence_rubric;

// ---------------------------------------------------------------------------
// Score descriptions
// ---------------------------------------------------------------------------

/// Script correctness dimension (1–5).
///
/// Measures whether the output uses the correct writing system for the target
/// language. For example, a Japanese response should use kanji/kana, not Latin.
const Map<int, String> kScriptScoreDescriptions = {
  1: 'Wrong script entirely (e.g., Latin output for Arabic)',
  2: 'Mixed scripts — some correct but majority wrong',
  3: 'Correct script but with unusual or out-of-place characters',
  4: 'Correct script with only minor issues (e.g., a stray punctuation mark)',
  5: 'Correct script throughout — no issues',
};

/// Grammatical plausibility dimension (1–5).
///
/// Measures how natural and grammatically coherent the output is, independent
/// of translation accuracy.
const Map<int, String> kGrammarScoreDescriptions = {
  1: 'Word salad — no discernible grammatical structure',
  2: 'Some structure but mostly incoherent',
  3: 'Understandable but awkward — native speakers would find it odd',
  4: 'Natural with only minor grammatical errors',
  5: 'Fluent — indistinguishable from native output',
};

/// Coherence / translation quality dimension (1–5).
///
/// Measures how well the output actually conveys the meaning of the source
/// prompt.
const Map<int, String> kCoherenceScoreDescriptions = {
  1: 'Unrelated to the source prompt',
  2: 'Partially related but mostly misses the meaning',
  3: 'Related and understandable, but incomplete or imprecise',
  4: 'Good translation with only minor issues',
  5: 'Excellent translation — fully conveys the source meaning',
};

// ---------------------------------------------------------------------------
// Pass/fail thresholds
// ---------------------------------------------------------------------------

/// Minimum score required for each dimension to count as a pass.
/// A language passes when ALL three dimensions meet or exceed this threshold.
const int kPassThreshold = 3;

/// A language passes the coherence rubric when:
///   scriptScore >= kPassThreshold AND
///   grammarScore >= kPassThreshold AND
///   coherenceScore >= kPassThreshold AND
///   isCorrectLanguage == true
///
/// This function provides the official pass/fail logic for use in both
/// judge scripts and the report generator.
bool passesRubric({
  required int scriptScore,
  required int grammarScore,
  required int coherenceScore,
  required bool isCorrectLanguage,
}) =>
    scriptScore >= kPassThreshold &&
    grammarScore >= kPassThreshold &&
    coherenceScore >= kPassThreshold &&
    isCorrectLanguage;

// ---------------------------------------------------------------------------
// Prompt text
// ---------------------------------------------------------------------------

/// The rubric as a prompt section, injected into judge LLM calls.
///
/// The judge is expected to return a JSON object with the following fields:
///   {
///     "languageName": "...",
///     "scriptScore": 1-5,
///     "grammarScore": 1-5,
///     "coherenceScore": 1-5,
///     "isCorrectLanguage": true/false,
///     "notes": "..."
///   }
const String kRubricPrompt = '''
## Evaluation Rubric

Score each dimension from 1 to 5 using the following criteria.

### Script Correctness (1–5)
1 = Wrong script entirely (e.g., Latin output for Arabic prompt)
2 = Mixed scripts — some correct but majority wrong
3 = Correct script but with unusual or out-of-place characters
4 = Correct script with only minor issues
5 = Correct script throughout — no issues

### Grammatical Plausibility (1–5)
1 = Word salad — no discernible grammatical structure
2 = Some structure but mostly incoherent
3 = Understandable but awkward — native speakers would find it odd
4 = Natural with only minor grammatical errors
5 = Fluent — indistinguishable from native output

### Coherence / Translation Quality (1–5)
1 = Unrelated to the source prompt
2 = Partially related but mostly misses the meaning
3 = Related and understandable, but incomplete or imprecise
4 = Good translation with only minor issues
5 = Excellent translation — fully conveys the source meaning

### Language Identity
isCorrectLanguage = true if the output is in the requested target language.
isCorrectLanguage = false if the model switched languages (e.g., responded in
Mandarin when Cantonese was requested, or in English when Thai was requested).

### Pass/Fail
A language PASSES when: scriptScore >= 3 AND grammarScore >= 3 AND
coherenceScore >= 3 AND isCorrectLanguage = true.

## Response Format

Return a JSON object — no markdown fences, no prose outside the JSON:
{
  "languageName": "<target language name>",
  "scriptScore": <1-5>,
  "grammarScore": <1-5>,
  "coherenceScore": <1-5>,
  "isCorrectLanguage": <true|false>,
  "notes": "<brief explanation of scores>"
}
''';

/// A variant of [kRubricPrompt] for batch evaluation (multiple languages).
///
/// The judge is expected to return a JSON array of score objects.
const String kBatchRubricPrompt = '''
## Evaluation Rubric

For each language sample provided, score each dimension from 1 to 5.

### Script Correctness (1–5)
1 = Wrong script entirely | 2 = Mixed scripts | 3 = Correct but unusual chars
4 = Correct with minor issues | 5 = Correct throughout

### Grammatical Plausibility (1–5)
1 = Word salad | 2 = Some structure but incoherent | 3 = Understandable but awkward
4 = Natural with minor errors | 5 = Fluent

### Coherence / Translation Quality (1–5)
1 = Unrelated | 2 = Partially related | 3 = Related but incomplete
4 = Good with minor issues | 5 = Excellent

### Language Identity
isCorrectLanguage = true only if output is in the specifically requested language.
Important: Cantonese (Yue) and Mandarin are DISTINCT languages. Look for
Cantonese-specific particles (㗎, 囉, 喇, 嘅, 咁, 咋) to confirm Cantonese.

### Pass/Fail
PASS when: scriptScore >= 3 AND grammarScore >= 3 AND coherenceScore >= 3
AND isCorrectLanguage = true.

## Response Format

Return a JSON ARRAY — one object per language sample, in the same order as input.
No markdown fences, no prose outside the JSON array:
[
  {
    "languageName": "<target language name>",
    "scriptScore": <1-5>,
    "grammarScore": <1-5>,
    "coherenceScore": <1-5>,
    "isCorrectLanguage": <true|false>,
    "notes": "<brief explanation>"
  },
  ...
]
''';
