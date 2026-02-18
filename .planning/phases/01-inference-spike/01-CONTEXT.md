# Phase 1: Inference Spike - Context

**Gathered:** 2026-02-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Validate that the Cohere2 architecture (Tiny Aya Global Q4_K_M GGUF) loads and runs in a Flutter llama.cpp binding on real iOS and Android hardware. Produce a working proof-of-concept that streams multilingual tokens. Bootstrap the Flutter project with correct platform toolchain settings. This is a go/no-go gate before production code.

</domain>

<decisions>
## Implementation Decisions

### Test languages and coverage
- Must-have languages: Chinese Mandarin, Cantonese (tested separately from Chinese Traditional), Latin American Spanish, English
- Test ALL 70+ Aya-supported languages, not just a handful
- Cantonese gets its own explicit test — prompt specifically for Cantonese translation, don't conflate with Chinese (Traditional)
- Cover diverse script families: CJK, Latin, Arabic (RTL), Thai (no-space complex script), Cyrillic, Devanagari, etc.

### Test prompts
- Must-have languages: travel phrases (directions, food ordering, emergencies, greetings, prices) PLUS basic sentences, questions, requests, and responses
- Broader 70+ language coverage: simple reference sentences for verifiable correctness
- Mix of both styles to stress-test translation quality across use cases

### Test-first approach
- Write test suites BEFORE writing implementation code — TDD style
- Be thorough with tests; comprehensive coverage is explicitly desired

### Coherence validation (LLM-as-judge)
- Two-tier automated validation:
  1. **Quick check:** Sonnet 4.6 for basic coherence verification (script correctness + grammatical plausibility)
  2. **Full suite:** Gemini 3.0 Flash for comprehensive automated coherence checking across all 70+ languages
- Both API keys (Anthropic, Google) read from env vars, gracefully skip if not set with clear instructions
- Build the automation tooling as part of the spike

### Test report format
- Structured report with two sections:
  1. **Summary scorecard:** At-a-glance pass/fail scores per language at the top — scannable
  2. **Expanded details:** Full per-language results with sample translations, coherence scores, and failure details underneath

### Claude's Discretion
- Test file location (Flutter test/ vs separate spike/ directory) — choose what makes sense for reuse
- Exact test framework and assertion patterns
- Coherence scoring rubric design
- Which simple reference sentences to use for the 70+ language coverage

</decisions>

<specifics>
## Specific Ideas

- "Don't be shy with writing test suites before writing code" — comprehensive testing is a core value
- Travel phrases should cover real tourist scenarios: directions, food, emergencies, greetings, prices, plus basic conversational sentences
- The coherence report should be readable at a glance — scores first, details second
- Cantonese is a distinct priority language, not a variant of Chinese Traditional

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-inference-spike*
*Context gathered: 2026-02-19*
