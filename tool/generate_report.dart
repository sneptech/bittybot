/// Report generator for the BittyBot inference spike.
///
/// Reads on-device test results and optional LLM judge scores, then produces
/// a structured report with two sections:
///   1. Summary Scorecard — scannable pass/fail overview
///   2. Expanded Details — full per-language data with sample translations
///
/// Usage:
///   dart run tool/generate_report.dart \
///     --results <path>            (required)
///     [--quick-judge <path>]      (optional)
///     [--full-judge <path>]       (optional)
///     [--output <path>]           (default: stdout)
///     [--format text|json|markdown]  (default: markdown)
///     [--help]
library generate_report;

import 'dart:convert';
import 'dart:io' as io;

import 'lib/result_types.dart';

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

Future<void> main(List<String> args) async {
  final opts = _parseArgs(args);

  if (opts.help) {
    io.stdout.writeln(_usage());
    io.exit(0);
  }

  if (opts.resultsPath == null) {
    io.stderr.writeln('Error: --results is required.\n');
    io.stderr.writeln(_usage());
    io.exit(1);
  }

  // --- Load results ---
  final results = await _loadLanguageResults(opts.resultsPath!);
  if (results == null) io.exit(1);

  // --- Load optional judge scores ---
  final quickScores = opts.quickJudgePath != null
      ? await _loadJudgeScores(opts.quickJudgePath!, label: 'quick-judge')
      : null;

  final fullScores = opts.fullJudgePath != null
      ? await _loadJudgeScores(opts.fullJudgePath!, label: 'full-judge')
      : null;

  // --- Build report ---
  final report = _buildReport(
    results: results,
    quickScores: quickScores,
    fullScores: fullScores,
  );

  // --- Render ---
  final rendered = switch (opts.format) {
    _Format.markdown => _renderMarkdown(report),
    _Format.json => _renderJson(report),
    _Format.text => _renderText(report),
  };

  // --- Write output ---
  if (opts.outputPath != null) {
    final outFile = io.File(opts.outputPath!);
    await outFile.writeAsString(rendered);
    io.stderr.writeln('Report written to: ${opts.outputPath}');
  } else {
    io.stdout.write(rendered);
  }
}

// ---------------------------------------------------------------------------
// Report data model
// ---------------------------------------------------------------------------

enum _PassStatus { pass, fail, scriptOnly }

class _LanguageRow {
  final LanguageResult result;
  final JudgeScore? quickScore;
  final JudgeScore? fullScore;
  final _PassStatus status;
  final String statusLabel;

  const _LanguageRow({
    required this.result,
    this.quickScore,
    this.fullScore,
    required this.status,
    required this.statusLabel,
  });
}

class _ScriptFamilyRollup {
  final String scriptFamily;
  final int total;
  final int passed;
  final int failed;

  const _ScriptFamilyRollup({
    required this.scriptFamily,
    required this.total,
    required this.passed,
    required this.failed,
  });

  double get passRate => total == 0 ? 0.0 : passed / total;
}

class _ReportData {
  final String timestamp;
  final String bindingUsed;
  final String deviceInfo;
  final List<_LanguageRow> rows;
  final List<_LanguageRow> priorityRows;
  final List<_ScriptFamilyRollup> scriptFamilyRollups;
  final List<_LanguageRow> failures;
  final int totalLanguages;
  final int passedLanguages;
  final int failedLanguages;
  final int skippedLanguages;
  final bool hasQuickJudge;
  final bool hasFullJudge;

  const _ReportData({
    required this.timestamp,
    required this.bindingUsed,
    required this.deviceInfo,
    required this.rows,
    required this.priorityRows,
    required this.scriptFamilyRollups,
    required this.failures,
    required this.totalLanguages,
    required this.passedLanguages,
    required this.failedLanguages,
    required this.skippedLanguages,
    required this.hasQuickJudge,
    required this.hasFullJudge,
  });

  double get passRate =>
      totalLanguages == 0 ? 0.0 : passedLanguages / totalLanguages;

  String get passRateString =>
      '${(passRate * 100).toStringAsFixed(1)}%';
}

// ---------------------------------------------------------------------------
// Report building logic
// ---------------------------------------------------------------------------

/// A language passes if:
///   - Script validation >= 80% of prompts
///   - AND (if judge scores exist) all applicable judge scores >= 3
_PassStatus _computeStatus({
  required LanguageResult result,
  JudgeScore? quickScore,
  JudgeScore? fullScore,
}) {
  final scriptOk = result.scriptValidationRate >= 0.8;
  if (!scriptOk) return _PassStatus.fail;

  // If we have any judge score, apply it
  final judgeScore = fullScore ?? quickScore;
  if (judgeScore == null) {
    // Script-only mode — pass based on script validation alone
    return _PassStatus.scriptOnly;
  }

  return judgeScore.passes ? _PassStatus.pass : _PassStatus.fail;
}

String _statusLabel(_PassStatus status) => switch (status) {
  _PassStatus.pass => 'PASS',
  _PassStatus.fail => 'FAIL',
  _PassStatus.scriptOnly => 'PASS*',
};

_ReportData _buildReport({
  required List<LanguageResult> results,
  List<JudgeScore>? quickScores,
  List<JudgeScore>? fullScores,
}) {
  // Index judge scores by language name
  final quickByName = <String, JudgeScore>{};
  final fullByName = <String, JudgeScore>{};
  for (final s in quickScores ?? []) {
    quickByName[s.languageName] = s;
  }
  for (final s in fullScores ?? []) {
    fullByName[s.languageName] = s;
  }

  // Build per-language rows
  // Sort: priority order then alphabetical
  final sortedResults = [...results];
  sortedResults.sort((a, b) {
    final ap = _priorityOrder(a.priority);
    final bp = _priorityOrder(b.priority);
    if (ap != bp) return ap - bp;
    return a.languageName.compareTo(b.languageName);
  });

  final rows = <_LanguageRow>[];
  for (final r in sortedResults) {
    final qs = quickByName[r.languageName];
    final fs = fullByName[r.languageName];
    final status = _computeStatus(result: r, quickScore: qs, fullScore: fs);
    rows.add(
      _LanguageRow(
        result: r,
        quickScore: qs,
        fullScore: fs,
        status: status,
        statusLabel: _statusLabel(status),
      ),
    );
  }

  // Priority rows (must-have and high)
  final priorityRows = rows
      .where((r) => r.result.priority == 'must-have' || r.result.priority == 'high')
      .toList();

  // Script family rollups
  final familyMap = <String, List<_LanguageRow>>{};
  for (final row in rows) {
    familyMap.putIfAbsent(row.result.scriptFamily, () => []).add(row);
  }
  final rollups = familyMap.entries.map((entry) {
    final passed = entry.value.where((r) => r.status != _PassStatus.fail).length;
    return _ScriptFamilyRollup(
      scriptFamily: entry.key,
      total: entry.value.length,
      passed: passed,
      failed: entry.value.length - passed,
    );
  }).toList()
    ..sort((a, b) => b.total.compareTo(a.total));

  // Failures
  final failures = rows.where((r) => r.status == _PassStatus.fail).toList();

  // Aggregate counts
  final passed = rows.where((r) => r.status != _PassStatus.fail).length;
  final failed = failures.length;

  return _ReportData(
    timestamp: DateTime.now().toUtc().toIso8601String(),
    bindingUsed: 'TBD (see device results)',
    deviceInfo: 'See on-device test results',
    rows: rows,
    priorityRows: priorityRows,
    scriptFamilyRollups: rollups,
    failures: failures,
    totalLanguages: rows.length,
    passedLanguages: passed,
    failedLanguages: failed,
    skippedLanguages: 0,
    hasQuickJudge: quickScores != null && quickScores.isNotEmpty,
    hasFullJudge: fullScores != null && fullScores.isNotEmpty,
  );
}

int _priorityOrder(String priority) => switch (priority) {
  'must-have' => 0,
  'high' => 1,
  _ => 2,
};

// ---------------------------------------------------------------------------
// Markdown renderer
// ---------------------------------------------------------------------------

String _renderMarkdown(_ReportData r) {
  final sb = StringBuffer();

  // Header
  sb.writeln('# BittyBot Inference Spike Report');
  sb.writeln('Generated: ${r.timestamp}');
  if (r.bindingUsed.isNotEmpty) sb.writeln('Binding: ${r.bindingUsed}');
  if (r.deviceInfo.isNotEmpty) sb.writeln('Device: ${r.deviceInfo}');
  if (!r.hasQuickJudge && !r.hasFullJudge) {
    sb.writeln('');
    sb.writeln(
      '> **Note:** No judge scores provided. Pass/fail based on script validation '
      'only (>= 80% prompts use correct script). Results marked with * are '
      'script-only passes.',
    );
  }

  // -------------------------------------------------------------------------
  // Section 1: Summary Scorecard
  // -------------------------------------------------------------------------
  sb.writeln('');
  sb.writeln('## Summary Scorecard');
  sb.writeln('');
  sb.writeln('Total languages tested: ${r.totalLanguages}');
  sb.writeln(
    'Passed: ${r.passedLanguages} (${r.passRateString})',
  );
  sb.writeln('Failed: ${r.failedLanguages}');
  if (r.skippedLanguages > 0) {
    sb.writeln('Skipped: ${r.skippedLanguages}');
  }

  // Priority languages table
  if (r.priorityRows.isNotEmpty) {
    sb.writeln('');
    sb.writeln('### Priority Languages');
    sb.writeln('');
    sb.writeln(
      '| Language | Script | Grammar | Coherence | Correct Lang | Status |',
    );
    sb.writeln(
      '|----------|--------|---------|-----------|--------------|--------|',
    );
    for (final row in r.priorityRows) {
      final qs = row.quickScore;
      final fs = row.fullScore;
      final judgeScore = fs ?? qs;
      final script = judgeScore != null ? '${judgeScore.scriptScore}/5' : '—';
      final grammar = judgeScore != null ? '${judgeScore.grammarScore}/5' : '—';
      final coherence = judgeScore != null ? '${judgeScore.coherenceScore}/5' : '—';
      final correct = judgeScore != null
          ? (judgeScore.isCorrectLanguage ? 'Yes' : 'No')
          : '—';
      sb.writeln(
        '| ${row.result.languageName} | $script | $grammar | $coherence '
        '| $correct | ${row.statusLabel} |',
      );
    }
  }

  // Script family rollup table
  sb.writeln('');
  sb.writeln('### By Script Family');
  sb.writeln('');
  sb.writeln(
    '| Script Family | Languages | Passed | Failed | Pass Rate |',
  );
  sb.writeln(
    '|---------------|-----------|--------|--------|-----------|',
  );
  for (final rollup in r.scriptFamilyRollups) {
    sb.writeln(
      '| ${rollup.scriptFamily} | ${rollup.total} | ${rollup.passed} '
      '| ${rollup.failed} | ${(rollup.passRate * 100).toStringAsFixed(1)}% |',
    );
  }

  // Quick failures
  if (r.failures.isNotEmpty) {
    sb.writeln('');
    sb.writeln('### Quick Failures');
    sb.writeln('');
    sb.writeln('| Language | Issue | Notes |');
    sb.writeln('|----------|-------|-------|');
    for (final row in r.failures) {
      final judgeScore = row.fullScore ?? row.quickScore;
      String issue;
      String notes;
      if (judgeScore != null) {
        issue = judgeScore.isCorrectLanguage ? 'Low scores' : 'Wrong language';
        notes = judgeScore.notes.isNotEmpty ? judgeScore.notes : '—';
      } else {
        final rate = (row.result.scriptValidationRate * 100).toStringAsFixed(0);
        issue = 'Script validation: $rate%';
        notes = '—';
      }
      sb.writeln(
        '| ${row.result.languageName} | $issue | ${notes.replaceAll('|', '/')} |',
      );
    }
  }

  // -------------------------------------------------------------------------
  // Section 2: Expanded Details
  // -------------------------------------------------------------------------
  sb.writeln('');
  sb.writeln('## Expanded Details');

  for (final row in r.rows) {
    final lang = row.result;
    final judgeScore = row.fullScore ?? row.quickScore;

    sb.writeln('');
    sb.writeln('---');
    sb.writeln('');
    sb.writeln('### ${lang.languageName} — ${row.statusLabel}');
    sb.writeln(
      'Script: ${lang.scriptFamily} | Priority: ${lang.priority}',
    );
    sb.writeln('Prompts tested: ${lang.prompts.length}');
    if (lang.prompts.isNotEmpty) {
      sb.writeln(
        'Average tokens/sec: '
        '${lang.averageTokensPerSecond.toStringAsFixed(1)}',
      );
      sb.writeln(
        'Script validation: '
        '${(lang.scriptValidationRate * 100).toStringAsFixed(0)}% passed',
      );
    }

    // Group prompts by category
    final byCategory = <String, List<PromptResult>>{};
    for (final p in lang.prompts) {
      byCategory.putIfAbsent(p.category, () => []).add(p);
    }

    for (final catEntry in byCategory.entries) {
      sb.writeln('');
      sb.writeln('#### ${_titleCase(catEntry.key)}');
      sb.writeln('');
      sb.writeln(
        '| Category | Source | Output | Script OK | Tokens/s |',
      );
      sb.writeln(
        '|----------|--------|--------|-----------|---------|',
      );
      for (final p in catEntry.value) {
        final src = _truncate(p.sourceText, 40);
        final out = _truncate(p.generatedOutput, 40);
        final scriptOk = p.scriptValidationPassed ? 'Yes' : 'No';
        final tps = p.tokensPerSecond.toStringAsFixed(1);
        sb.writeln(
          '| ${p.category} | $src | $out | $scriptOk | $tps |',
        );
      }
    }

    // Judge notes
    if (judgeScore != null) {
      sb.writeln('');
      sb.writeln('#### Judge Notes');
      if (row.quickScore != null) {
        sb.writeln('Quick (Sonnet): "${row.quickScore!.notes}"');
      }
      if (row.fullScore != null) {
        sb.writeln('Full (Gemini Flash): "${row.fullScore!.notes}"');
      }
    }
  }

  return sb.toString();
}

// ---------------------------------------------------------------------------
// JSON renderer
// ---------------------------------------------------------------------------

String _renderJson(_ReportData r) {
  final doc = {
    'timestamp': r.timestamp,
    'bindingUsed': r.bindingUsed,
    'deviceInfo': r.deviceInfo,
    'summary': {
      'totalLanguages': r.totalLanguages,
      'passedLanguages': r.passedLanguages,
      'failedLanguages': r.failedLanguages,
      'skippedLanguages': r.skippedLanguages,
      'passRate': r.passRateString,
    },
    'scriptFamilyRollups': r.scriptFamilyRollups.map((rollup) => {
      'scriptFamily': rollup.scriptFamily,
      'total': rollup.total,
      'passed': rollup.passed,
      'failed': rollup.failed,
      'passRate': '${(rollup.passRate * 100).toStringAsFixed(1)}%',
    }).toList(),
    'languages': r.rows.map((row) => {
      'languageName': row.result.languageName,
      'languageCode': row.result.languageCode,
      'scriptFamily': row.result.scriptFamily,
      'priority': row.result.priority,
      'status': row.statusLabel,
      'scriptValidationRate':
          '${(row.result.scriptValidationRate * 100).toStringAsFixed(0)}%',
      'averageTokensPerSecond':
          row.result.averageTokensPerSecond.toStringAsFixed(1),
      'promptCount': row.result.prompts.length,
      'quickJudge': row.quickScore?.toJson(),
      'fullJudge': row.fullScore?.toJson(),
      'prompts': row.result.prompts.map((p) => p.toJson()).toList(),
    }).toList(),
    'failures': r.failures.map((row) => {
      'languageName': row.result.languageName,
      'issue': _describeFailure(row),
    }).toList(),
  };

  return const JsonEncoder.withIndent('  ').convert(doc);
}

String _describeFailure(_LanguageRow row) {
  final judgeScore = row.fullScore ?? row.quickScore;
  if (judgeScore != null) {
    if (!judgeScore.isCorrectLanguage) return 'Wrong language';
    return 'Low judge scores (${judgeScore.scriptScore}/${judgeScore.grammarScore}/${judgeScore.coherenceScore})';
  }
  return 'Script validation ${(row.result.scriptValidationRate * 100).toStringAsFixed(0)}% < 80%';
}

// ---------------------------------------------------------------------------
// Text renderer (aligned columns)
// ---------------------------------------------------------------------------

String _renderText(_ReportData r) {
  final sb = StringBuffer();

  sb.writeln('BittyBot Inference Spike Report');
  sb.writeln('=' * 60);
  sb.writeln('Generated: ${r.timestamp}');
  sb.writeln('');

  // Summary
  sb.writeln('SUMMARY SCORECARD');
  sb.writeln('-' * 40);
  sb.writeln('Total languages: ${r.totalLanguages}');
  sb.writeln('Passed:          ${r.passedLanguages} (${r.passRateString})');
  sb.writeln('Failed:          ${r.failedLanguages}');
  sb.writeln('');

  // Priority languages
  if (r.priorityRows.isNotEmpty) {
    sb.writeln('PRIORITY LANGUAGES');
    sb.writeln('-' * 40);
    for (final row in r.priorityRows) {
      final name = row.result.languageName.padRight(30);
      sb.writeln('${row.statusLabel.padRight(8)} $name');
    }
    sb.writeln('');
  }

  // Script family rollup
  sb.writeln('BY SCRIPT FAMILY');
  sb.writeln('-' * 40);
  sb.writeln(
    '${'Family'.padRight(20)} ${'Total'.padRight(8)} ${'Passed'.padRight(8)} ${'Failed'.padRight(8)} Rate',
  );
  for (final rollup in r.scriptFamilyRollups) {
    sb.writeln(
      '${rollup.scriptFamily.padRight(20)} '
      '${rollup.total.toString().padRight(8)} '
      '${rollup.passed.toString().padRight(8)} '
      '${rollup.failed.toString().padRight(8)} '
      '${(rollup.passRate * 100).toStringAsFixed(1)}%',
    );
  }
  sb.writeln('');

  // Failures
  if (r.failures.isNotEmpty) {
    sb.writeln('FAILURES');
    sb.writeln('-' * 40);
    for (final row in r.failures) {
      sb.writeln('  ${row.result.languageName}: ${_describeFailure(row)}');
    }
    sb.writeln('');
  }

  // Per-language details
  sb.writeln('EXPANDED DETAILS');
  sb.writeln('=' * 60);
  for (final row in r.rows) {
    final lang = row.result;
    sb.writeln('');
    sb.writeln(
      '${row.statusLabel.padRight(8)} ${lang.languageName} '
      '(${lang.scriptFamily} | ${lang.priority})',
    );
    sb.writeln('  Prompts: ${lang.prompts.length}');
    if (lang.prompts.isNotEmpty) {
      sb.writeln(
        '  Avg tok/s: ${lang.averageTokensPerSecond.toStringAsFixed(1)}',
      );
      sb.writeln(
        '  Script OK: ${(lang.scriptValidationRate * 100).toStringAsFixed(0)}%',
      );
    }
    final judgeScore = row.fullScore ?? row.quickScore;
    if (judgeScore != null) {
      sb.writeln(
        '  Judge: script=${judgeScore.scriptScore} '
        'grammar=${judgeScore.grammarScore} '
        'coherence=${judgeScore.coherenceScore} '
        'correct=${judgeScore.isCorrectLanguage}',
      );
      if (judgeScore.notes.isNotEmpty) {
        sb.writeln('  Notes: ${judgeScore.notes}');
      }
    }

    // Sample translations
    final samples = lang.prompts.take(2).toList();
    for (final p in samples) {
      sb.writeln('');
      sb.writeln('  [${p.category}]');
      sb.writeln('    Source: ${_truncate(p.sourceText, 70)}');
      sb.writeln('    Output: ${_truncate(p.generatedOutput, 70)}');
    }
  }

  return sb.toString();
}

// ---------------------------------------------------------------------------
// Data loading helpers
// ---------------------------------------------------------------------------

/// Load LanguageResult list from a JSON file.
///
/// Returns null on error (errors printed to stderr).
Future<List<LanguageResult>?> _loadLanguageResults(String path) async {
  final file = io.File(path);
  if (!file.existsSync()) {
    io.stderr.writeln('Error: results file not found: $path');
    return null;
  }
  try {
    final raw = await file.readAsString();
    final decoded = jsonDecode(raw) as List;
    return decoded
        .map((e) => LanguageResult.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e) {
    io.stderr.writeln('Warning: failed to parse results file ($path): $e');
    return null;
  }
}

/// Load JudgeScore list from a JSON file.
///
/// Returns null on error (errors printed to stderr as warnings — caller
/// continues without judge scores).
Future<List<JudgeScore>?> _loadJudgeScores(
  String path, {
  required String label,
}) async {
  final file = io.File(path);
  if (!file.existsSync()) {
    io.stderr.writeln('Warning: $label file not found: $path — skipping');
    return null;
  }
  try {
    final raw = await file.readAsString();
    final decoded = jsonDecode(raw) as List;
    return decoded
        .map((e) => JudgeScore.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e) {
    io.stderr.writeln('Warning: failed to parse $label file ($path): $e');
    return null;
  }
}

// ---------------------------------------------------------------------------
// Argument parsing
// ---------------------------------------------------------------------------

enum _Format { markdown, json, text }

class _Options {
  final String? resultsPath;
  final String? quickJudgePath;
  final String? fullJudgePath;
  final String? outputPath;
  final _Format format;
  final bool help;

  const _Options({
    this.resultsPath,
    this.quickJudgePath,
    this.fullJudgePath,
    this.outputPath,
    this.format = _Format.markdown,
    this.help = false,
  });
}

_Options _parseArgs(List<String> args) {
  String? results;
  String? quickJudge;
  String? fullJudge;
  String? output;
  var format = _Format.markdown;
  var help = false;

  var i = 0;
  while (i < args.length) {
    switch (args[i]) {
      case '--help' || '-h':
        help = true;
      case '--results':
        i++;
        if (i < args.length) results = args[i];
      case '--quick-judge':
        i++;
        if (i < args.length) quickJudge = args[i];
      case '--full-judge':
        i++;
        if (i < args.length) fullJudge = args[i];
      case '--output':
        i++;
        if (i < args.length) output = args[i];
      case '--format':
        i++;
        if (i < args.length) {
          format = switch (args[i]) {
            'json' => _Format.json,
            'text' => _Format.text,
            _ => _Format.markdown,
          };
        }
      default:
        io.stderr.writeln('Warning: unknown argument: ${args[i]}');
    }
    i++;
  }

  return _Options(
    resultsPath: results,
    quickJudgePath: quickJudge,
    fullJudgePath: fullJudge,
    outputPath: output,
    format: format,
    help: help,
  );
}

String _usage() => '''
Usage: dart run tool/generate_report.dart [options]

Generates a structured inference spike report from on-device test results
and optional LLM judge scores.

Options:
  --results <path>         Path to on-device test results JSON (required)
  --quick-judge <path>     Path to quick (Claude Sonnet) judge scores JSON
  --full-judge <path>      Path to full (Gemini Flash) judge scores JSON
  --output <path>          Write report to file (default: stdout)
  --format <fmt>           Output format: markdown | json | text (default: markdown)
  --help                   Show this help message

The report has two sections:
  1. Summary Scorecard  — at-a-glance pass/fail per language and script family
  2. Expanded Details   — per-language sample translations, scores, and notes

A language passes if:
  - Script validation passes for >= 80% of prompts
  - AND (if judge scores available) all judge dimension scores >= 3

Without judge scores, the report runs in script-validation-only mode
(pass/fail based purely on Unicode script validation).''';

// ---------------------------------------------------------------------------
// Formatting utilities
// ---------------------------------------------------------------------------

String _truncate(String s, int maxLen) {
  if (s.length <= maxLen) return s;
  return '${s.substring(0, maxLen - 3)}...';
}

String _titleCase(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1).toLowerCase();
}
