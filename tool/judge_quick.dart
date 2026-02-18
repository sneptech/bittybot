/// Tier-1 quick coherence check via Claude Sonnet.
///
/// Reads on-device test results (JSON) and evaluates a representative subset
/// of languages using the Anthropic Claude API. Writes judge scores to a JSON
/// file in the same directory as the input.
///
/// Usage:
///   dart run tool/judge_quick.dart <results.json>
///
/// Environment:
///   ANTHROPIC_API_KEY — Anthropic API key. If absent, script exits 0 with
///   instructions (soft skip, not failure).
library judge_quick;

import 'dart:convert';
import 'dart:io' as io;

import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart';

import 'lib/coherence_rubric.dart';
import 'lib/result_types.dart';

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

Future<void> main(List<String> args) async {
  // --- API key gate ---
  final apiKey = io.Platform.environment['ANTHROPIC_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    io.stdout.writeln(
      'ANTHROPIC_API_KEY not set — skipping quick coherence check.\n'
      'To enable: export ANTHROPIC_API_KEY=sk-ant-...',
    );
    io.exit(0);
  }

  // --- Argument validation ---
  if (args.isEmpty) {
    io.stderr.writeln(
      'Usage: dart run tool/judge_quick.dart <results.json>\n'
      '\n'
      'Evaluates a subset of languages from on-device test results using\n'
      'Claude Sonnet for quick coherence checking.\n'
      '\n'
      'Arguments:\n'
      '  results.json  Path to on-device test results (List<LanguageResult> JSON)',
    );
    io.exit(1);
  }

  final resultsPath = args[0];
  final resultsFile = io.File(resultsPath);
  if (!resultsFile.existsSync()) {
    io.stderr.writeln('Error: file not found: $resultsPath');
    io.exit(1);
  }

  // --- Load results ---
  final List<LanguageResult> allResults;
  try {
    final raw = await resultsFile.readAsString();
    final decoded = jsonDecode(raw) as List;
    allResults =
        decoded
            .map((e) => LanguageResult.fromJson(e as Map<String, dynamic>))
            .toList();
  } catch (e) {
    io.stderr.writeln('Error reading results file: $e');
    io.exit(1);
  }

  io.stdout.writeln(
    'Quick Judge: evaluating ${allResults.length} languages (subset)...',
  );

  // --- Select languages to judge ---
  final toJudge = _selectLanguagesForQuickCheck(allResults);
  io.stdout.writeln(
    'Checking ${toJudge.length} languages: '
    '${toJudge.map((l) => l.languageName).join(", ")}',
  );

  // --- Run evaluation ---
  final client = AnthropicClient(apiKey: apiKey);
  final judgeScores = <JudgeScore>[];
  var passed = 0;
  var failed = 0;

  for (final lang in toJudge) {
    io.stdout.write('  Checking ${lang.languageName}... ');
    try {
      final score = await _judgeLanguage(client, lang);
      judgeScores.add(score);
      if (score.passes) {
        passed++;
        io.stdout.writeln(
          'PASS (${score.scriptScore}/${score.grammarScore}/${score.coherenceScore})',
        );
      } else {
        failed++;
        io.stdout.writeln(
          'FAIL (${score.scriptScore}/${score.grammarScore}/${score.coherenceScore})'
          ' — ${score.notes}',
        );
      }
    } catch (e) {
      io.stderr.writeln('ERROR — $e');
      // Continue with remaining languages
    }
  }

  // --- Write output ---
  final outputPath = _outputPath(resultsPath);
  final outputFile = io.File(outputPath);
  await outputFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(
      judgeScores.map((s) => s.toJson()).toList(),
    ),
  );

  // --- Summary ---
  io.stdout.writeln('');
  io.stdout.writeln('Quick Judge Summary:');
  io.stdout.writeln('  Checked: ${toJudge.length} languages');
  io.stdout.writeln('  Passed:  $passed');
  io.stdout.writeln('  Failed:  $failed');
  io.stdout.writeln('  Scores written to: $outputPath');
}

// ---------------------------------------------------------------------------
// Language selection logic
// ---------------------------------------------------------------------------

/// Must-have language names to always include.
const _mustHaveLanguages = {
  'Chinese (Mandarin)',
  'Cantonese',
  'Latin American Spanish',
  'Spanish (Latin America)',
  'English',
};

/// One representative per script family for broader coverage.
///
/// Key = script family name (as stored in LanguageResult.scriptFamily),
/// Value = preferred language name to represent that family.
const _scriptFamilyRepresentatives = {
  'Arabic': 'Arabic',
  'Thai': 'Thai',
  'Cyrillic': 'Russian',
  'Devanagari': 'Hindi',
  'Hebrew': 'Hebrew',
  'Japanese': 'Japanese',
  'Korean': 'Korean',
  'Georgian': 'Georgian',
  'Armenian': 'Armenian',
};

/// Select the subset of languages for the quick check.
///
/// Always includes must-have languages plus one representative per script family.
List<LanguageResult> _selectLanguagesForQuickCheck(
  List<LanguageResult> all,
) {
  final selected = <LanguageResult>[];

  // Index by name for lookup
  final byName = <String, LanguageResult>{};
  for (final lang in all) {
    byName[lang.languageName] = lang;
  }

  // 1. Must-have languages
  for (final lang in all) {
    if (_mustHaveLanguages.contains(lang.languageName)) {
      selected.add(lang);
    }
  }

  // 2. Script family representatives
  for (final entry in _scriptFamilyRepresentatives.entries) {
    final scriptFamily = entry.key;
    final preferredName = entry.value;

    // Skip if this family is already represented by a must-have
    if (selected.any((l) => l.scriptFamily == scriptFamily)) {
      continue;
    }

    // Try preferred name first, then any language from this family
    final candidate =
        byName[preferredName] ??
        all.where((l) => l.scriptFamily == scriptFamily).firstOrNull;

    if (candidate != null &&
        !selected.any((l) => l.languageName == candidate.languageName)) {
      selected.add(candidate);
    }
  }

  return selected;
}

// ---------------------------------------------------------------------------
// Judge call
// ---------------------------------------------------------------------------

/// Build the judge prompt for a single language.
String _buildJudgePrompt(LanguageResult lang) {
  final sb = StringBuffer();
  sb.writeln('You are a multilingual translation quality evaluator.');
  sb.writeln('');
  sb.writeln(
    'Evaluate the following generated output for the target language: '
    '**${lang.languageName}** (${lang.languageCode}).',
  );
  sb.writeln('');

  if (lang.languageName.toLowerCase().contains('cantonese')) {
    sb.writeln(
      '**IMPORTANT**: This evaluation is specifically for Cantonese (Yue Chinese), '
      'NOT Mandarin. Look for Cantonese-specific particles such as 㗎, 囉, 喇, 嘅, '
      '咁, 咋. If these are absent and the text reads like Mandarin, set '
      'isCorrectLanguage = false.',
    );
    sb.writeln('');
  }

  // Include up to 3 prompt samples
  final samples = lang.prompts.take(3).toList();
  for (var i = 0; i < samples.length; i++) {
    final p = samples[i];
    sb.writeln('### Sample ${i + 1} (${p.category})');
    sb.writeln('Source (English): ${p.sourceText}');
    sb.writeln('Generated output: ${p.generatedOutput}');
    sb.writeln('Script validation passed: ${p.scriptValidationPassed}');
    sb.writeln('');
  }

  sb.writeln(kRubricPrompt);
  return sb.toString();
}

/// Extract text from an Anthropic Message response.
///
/// The response content is a sealed MessageContent — either blocks (List<Block>)
/// or raw text. For Messages API responses, it's always blocks.
String _extractResponseText(Message response) {
  final content = response.content;
  switch (content) {
    case MessageContentText(value: final text):
      return text.trim();
    case MessageContentBlocks(value: final blocks):
      return blocks
          .whereType<TextBlock>()
          .map((b) => b.text)
          .join('\n')
          .trim();
  }
}

/// Call Claude Sonnet to evaluate a single language and return a JudgeScore.
Future<JudgeScore> _judgeLanguage(
  AnthropicClient client,
  LanguageResult lang,
) async {
  final prompt = _buildJudgePrompt(lang);

  final response = await client.createMessage(
    request: CreateMessageRequest(
      // Use a string model ID to specify the model version directly.
      // The SDK's Models enum may not enumerate every release; the string
      // form is always accepted by the API.
      model: const Model.modelId('claude-sonnet-4-6'),
      maxTokens: 512,
      messages: [
        Message(
          role: MessageRole.user,
          content: MessageContent.text(prompt),
        ),
      ],
    ),
  );

  final responseText = _extractResponseText(response);
  return _parseJudgeResponse(lang.languageName, responseText);
}

/// Parse the judge LLM's JSON response into a JudgeScore.
///
/// Handles responses that may include stray prose before/after the JSON object.
JudgeScore _parseJudgeResponse(String languageName, String rawResponse) {
  // Extract JSON object from response
  final jsonStart = rawResponse.indexOf('{');
  final jsonEnd = rawResponse.lastIndexOf('}');

  if (jsonStart == -1 || jsonEnd == -1) {
    // Fallback: return a failing score with the raw response as notes
    return JudgeScore(
      languageName: languageName,
      scriptScore: 1,
      grammarScore: 1,
      coherenceScore: 1,
      isCorrectLanguage: false,
      notes: 'Parse error — raw response: $rawResponse',
    );
  }

  try {
    final jsonStr = rawResponse.substring(jsonStart, jsonEnd + 1);
    final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

    return JudgeScore(
      languageName: (decoded['languageName'] as String?) ?? languageName,
      scriptScore: (decoded['scriptScore'] as num?)?.toInt() ?? 1,
      grammarScore: (decoded['grammarScore'] as num?)?.toInt() ?? 1,
      coherenceScore: (decoded['coherenceScore'] as num?)?.toInt() ?? 1,
      isCorrectLanguage: decoded['isCorrectLanguage'] as bool? ?? false,
      notes: (decoded['notes'] as String?) ?? '',
    );
  } catch (e) {
    return JudgeScore(
      languageName: languageName,
      scriptScore: 1,
      grammarScore: 1,
      coherenceScore: 1,
      isCorrectLanguage: false,
      notes: 'JSON parse error: $e — raw: $rawResponse',
    );
  }
}

// ---------------------------------------------------------------------------
// Output path helper
// ---------------------------------------------------------------------------

/// Derive the output path from the input results path.
///
/// e.g. "results/spike-results.json" -> "results/spike-results-quick-judge.json"
String _outputPath(String inputPath) {
  final file = io.File(inputPath);
  final dir = file.parent.path;
  final segments = file.uri.pathSegments;
  final name = segments.isNotEmpty ? segments.last : inputPath;
  final base = name.endsWith('.json') ? name.substring(0, name.length - 5) : name;
  return '$dir/$base-quick-judge.json';
}
