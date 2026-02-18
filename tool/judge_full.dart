/// Tier-2 comprehensive evaluation via Gemini Flash.
///
/// Reads on-device test results (JSON) and evaluates ALL languages in batches
/// using the Google AI Gemini API. Writes judge scores to a JSON file in the
/// same directory as the input.
///
/// Usage:
///   dart run tool/judge_full.dart <results.json>
///
/// Environment:
///   GOOGLE_GENAI_API_KEY — Google AI API key. If absent, script exits 0 with
///   instructions (soft skip, not failure).
library judge_full;

import 'dart:convert';
import 'dart:io' as io;

// Import googleai_dart with a prefix to avoid the File/dart:io naming conflict.
// The googleai_dart package exports its own `File` model class.
import 'package:googleai_dart/googleai_dart.dart' as gai;

import 'lib/coherence_rubric.dart';
import 'lib/result_types.dart';

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

/// Number of languages per batch. Gemini Flash handles long prompts well.
const _batchSize = 8;

/// Gemini model to use for evaluation.
const _geminiModel = 'gemini-2.0-flash';

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

Future<void> main(List<String> args) async {
  // --- API key gate ---
  final apiKey = io.Platform.environment['GOOGLE_GENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    io.stdout.writeln(
      'GOOGLE_GENAI_API_KEY not set — skipping full coherence check.\n'
      'To enable: export GOOGLE_GENAI_API_KEY=...',
    );
    io.exit(0);
  }

  // --- Argument validation ---
  if (args.isEmpty) {
    io.stderr.writeln(
      'Usage: dart run tool/judge_full.dart <results.json>\n'
      '\n'
      'Evaluates ALL languages from on-device test results using\n'
      'Gemini Flash for comprehensive coherence checking.\n'
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
    'Full Judge: evaluating all ${allResults.length} languages '
    'in batches of $_batchSize...',
  );

  // --- Run evaluation in batches ---
  final client = gai.GoogleAIClient(
    config: gai.GoogleAIConfig(authProvider: gai.ApiKeyProvider(apiKey)),
  );
  final judgeScores = <JudgeScore>[];
  var passed = 0;
  var failed = 0;

  // Split into batches
  final batches = <List<LanguageResult>>[];
  for (var i = 0; i < allResults.length; i += _batchSize) {
    final end = (i + _batchSize < allResults.length)
        ? i + _batchSize
        : allResults.length;
    batches.add(allResults.sublist(i, end));
  }

  io.stdout.writeln('Processing ${batches.length} batches...');

  for (var batchIndex = 0; batchIndex < batches.length; batchIndex++) {
    final batch = batches[batchIndex];
    final start = batchIndex * _batchSize + 1;
    final end = start + batch.length - 1;
    io.stdout.write(
      '  Batch ${batchIndex + 1}/${batches.length} '
      '(languages $start-$end of ${allResults.length})... ',
    );

    try {
      final batchScores = await _judgeBatch(client, batch);
      judgeScores.addAll(batchScores);

      for (final score in batchScores) {
        if (score.passes) {
          passed++;
        } else {
          failed++;
        }
      }

      io.stdout.writeln(
        'done — '
        '${batchScores.where((s) => s.passes).length}/${batchScores.length} passed',
      );
    } catch (e) {
      io.stderr.writeln('ERROR — $e');
      // Continue with next batch
    }
  }

  client.close();

  // --- Write output ---
  final outputPath = _outputPath(resultsPath);
  final outputFile = io.File(outputPath);
  await outputFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(
      judgeScores.map((s) => s.toJson()).toList(),
    ),
  );

  // --- Print per-language summary ---
  io.stdout.writeln('');
  io.stdout.writeln('Full Judge Results:');
  for (final score in judgeScores) {
    final status = score.passes ? 'PASS' : 'FAIL';
    io.stdout.writeln(
      '  ${score.languageName.padRight(30)} $status '
      '(script=${score.scriptScore}, grammar=${score.grammarScore}, '
      'coherence=${score.coherenceScore})',
    );
  }

  io.stdout.writeln('');
  io.stdout.writeln('Full Judge Summary:');
  io.stdout.writeln('  Total:   ${allResults.length} languages');
  io.stdout.writeln('  Judged:  ${judgeScores.length}');
  io.stdout.writeln('  Passed:  $passed');
  io.stdout.writeln('  Failed:  $failed');
  io.stdout.writeln('  Scores written to: $outputPath');
}

// ---------------------------------------------------------------------------
// Batch evaluation logic
// ---------------------------------------------------------------------------

/// Build a batch prompt that asks Gemini to evaluate multiple languages at once.
String _buildBatchPrompt(List<LanguageResult> batch) {
  final sb = StringBuffer();
  sb.writeln('You are a multilingual translation quality evaluator.');
  sb.writeln('');
  sb.writeln(
    'Evaluate the following ${batch.length} language samples. '
    'Return scores for EACH language in the same order as listed.',
  );
  sb.writeln('');

  for (var i = 0; i < batch.length; i++) {
    final lang = batch[i];
    sb.writeln('---');
    sb.writeln(
      '## Language ${i + 1}: ${lang.languageName} (${lang.languageCode})',
    );

    if (lang.languageName.toLowerCase().contains('cantonese')) {
      sb.writeln(
        '**IMPORTANT**: This is specifically Cantonese (Yue Chinese), NOT Mandarin. '
        'Look for Cantonese-specific particles: 㗎, 囉, 喇, 嘅, 咁, 咋. '
        'Set isCorrectLanguage=false if these are absent and text reads as Mandarin.',
      );
    }

    // Include up to 2 prompt samples per language (to keep batch prompt concise)
    final samples = lang.prompts.take(2).toList();
    for (var j = 0; j < samples.length; j++) {
      final p = samples[j];
      sb.writeln('Sample ${j + 1} (${p.category}):');
      sb.writeln('  Source: ${p.sourceText}');
      sb.writeln('  Output: ${p.generatedOutput}');
    }
    sb.writeln('');
  }

  sb.writeln('---');
  sb.writeln(kBatchRubricPrompt);
  return sb.toString();
}

/// Call Gemini Flash to evaluate a batch of languages.
///
/// Returns a list of JudgeScore objects in the same order as the input batch.
Future<List<JudgeScore>> _judgeBatch(
  gai.GoogleAIClient client,
  List<LanguageResult> batch,
) async {
  final prompt = _buildBatchPrompt(batch);

  final response = await client.models.generateContent(
    model: _geminiModel,
    request: gai.GenerateContentRequest(
      contents: [gai.Content.text(prompt)],
    ),
  );

  final responseText = _extractText(response);
  return _parseBatchResponse(batch, responseText);
}

/// Extract text from a GenerateContentResponse.
String _extractText(gai.GenerateContentResponse response) {
  final candidates = response.candidates;
  if (candidates == null || candidates.isEmpty) return '';

  final parts = candidates.first.content?.parts ?? [];
  final textParts = parts.whereType<gai.TextPart>();
  return textParts.map((p) => p.text).join('\n').trim();
}

/// Parse a batch judge response into a list of JudgeScore objects.
///
/// Handles partial responses — if fewer scores are returned than expected,
/// fills remaining entries with error scores.
List<JudgeScore> _parseBatchResponse(
  List<LanguageResult> batch,
  String rawResponse,
) {
  // Extract JSON array from response
  final jsonStart = rawResponse.indexOf('[');
  final jsonEnd = rawResponse.lastIndexOf(']');

  if (jsonStart == -1 || jsonEnd == -1) {
    // Fallback: return failing scores for all languages in this batch
    return batch
        .map(
          (lang) => JudgeScore(
            languageName: lang.languageName,
            scriptScore: 1,
            grammarScore: 1,
            coherenceScore: 1,
            isCorrectLanguage: false,
            notes: 'Parse error — no JSON array in response',
          ),
        )
        .toList();
  }

  try {
    final jsonStr = rawResponse.substring(jsonStart, jsonEnd + 1);
    final decoded = jsonDecode(jsonStr) as List;
    final scores = decoded
        .map((e) => JudgeScore.fromJson(e as Map<String, dynamic>))
        .toList();

    // Pad with error scores if fewer entries than expected
    while (scores.length < batch.length) {
      final missingIndex = scores.length;
      scores.add(
        JudgeScore(
          languageName: batch[missingIndex].languageName,
          scriptScore: 1,
          grammarScore: 1,
          coherenceScore: 1,
          isCorrectLanguage: false,
          notes: 'Missing from batch response',
        ),
      );
    }

    // Fix up empty/placeholder language names using batch order
    for (var i = 0; i < scores.length && i < batch.length; i++) {
      if (scores[i].languageName.isEmpty ||
          scores[i].languageName == '<target language name>') {
        scores[i] = JudgeScore(
          languageName: batch[i].languageName,
          scriptScore: scores[i].scriptScore,
          grammarScore: scores[i].grammarScore,
          coherenceScore: scores[i].coherenceScore,
          isCorrectLanguage: scores[i].isCorrectLanguage,
          notes: scores[i].notes,
        );
      }
    }

    return scores.take(batch.length).toList();
  } catch (e) {
    return batch
        .map(
          (lang) => JudgeScore(
            languageName: lang.languageName,
            scriptScore: 1,
            grammarScore: 1,
            coherenceScore: 1,
            isCorrectLanguage: false,
            notes: 'JSON parse error: $e',
          ),
        )
        .toList();
  }
}

// ---------------------------------------------------------------------------
// Output path helper
// ---------------------------------------------------------------------------

/// Derive the output path from the input results path.
///
/// e.g. "results/spike-results.json" -> "results/spike-results-full-judge.json"
String _outputPath(String inputPath) {
  final file = io.File(inputPath);
  final dir = file.parent.path;
  final segments = file.uri.pathSegments;
  final name = segments.isNotEmpty ? segments.last : inputPath;
  final base = name.endsWith('.json') ? name.substring(0, name.length - 5) : name;
  return '$dir/$base-full-judge.json';
}
