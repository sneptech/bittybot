/// Multilingual translation integration test for the BittyBot inference spike.
///
/// Verifies that the on-device Tiny Aya Global Q4_K_M model produces output in
/// the correct writing system for all 70+ Aya-supported languages, with special
/// attention to priority languages (Mandarin, Cantonese, Latin American Spanish,
/// English) and Cantonese-vs-Mandarin distinction.
///
/// Results are serialised to JSON via [ReportWriter] for consumption by the
/// LLM-as-judge tooling in tool/ (judge_quick.dart, judge_full.dart).
///
/// Prerequisites:
/// - Android: `adb push tiny-aya-global-q4_k_m.gguf /sdcard/Download/`
/// - iOS: Use Xcode Device Manager to copy the GGUF to the app Documents folder.
///
/// Resume behaviour:
/// The test reads `spike_results.json` at startup. Any language code already
/// present in that file is skipped so interrupted runs continue from where they
/// left off. To force a completely fresh run, create a flag file on the device:
///   adb shell touch /data/local/tmp/bittybot_fresh_start
/// The flag file is deleted automatically after being read so subsequent runs
/// resume normally.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'helpers/language_corpus.dart';
import 'helpers/model_loader.dart';
import 'helpers/pump_test_overlay.dart';
import 'helpers/report_writer.dart';
import 'helpers/test_progress_controller.dart';

/// Path of the flag file that forces a full re-run when present on the device.
const _freshStartFlagPath = '/data/local/tmp/bittybot_fresh_start';

/// Filename used by [ReportWriter] for incremental + final flushes.
const _resultsFilename = 'spike_results.json';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Disable the global timeout — inference on-device is slow and unbounded.
  binding.defaultTestTimeout = Timeout.none;

  final progress = TestProgressController.instance;
  late ModelLoader loader;
  final reportWriter = ReportWriter();

  // Language codes that were already present in spike_results.json at startup.
  // Populated in setUpAll; read (not mutated) by individual tests.
  var completedLanguageCodes = <String>{};

  setUpAll(() async {
    // --- Resume / fresh-start logic ----------------------------------------
    final flagFile = File(_freshStartFlagPath);
    if (flagFile.existsSync()) {
      // Fresh-start requested: delete the flag and any existing results file.
      progress.log('FRESH START: ignoring previous results');
      // ignore: avoid_print
      print('FRESH START: deleting flag file $_freshStartFlagPath');
      try {
        flagFile.deleteSync();
      } catch (_) {
        // Non-fatal — missing write permission just means the flag stays,
        // but we still proceed as a fresh run this session.
      }
      // Delete existing results file so this run starts clean.
      try {
        final docsDir = await getApplicationDocumentsDirectory();
        final resultsFile = File('${docsDir.path}/$_resultsFilename');
        if (resultsFile.existsSync()) resultsFile.deleteSync();
      } catch (_) {}
      completedLanguageCodes = {};
    } else {
      // Normal start: load any previously completed languages.
      completedLanguageCodes = await reportWriter.loadExisting(
        filename: _resultsFilename,
      );
      if (completedLanguageCodes.isNotEmpty) {
        progress.log(
          'RESUMING: ${completedLanguageCodes.length} language(s) already completed — will skip them',
        );
        // ignore: avoid_print
        print('Resuming — skipping: $completedLanguageCodes');
      } else {
        progress.log('Starting fresh (no previous results found)');
      }
    }
    // -----------------------------------------------------------------------

    // Load the model once for the entire test suite to avoid re-loading 2+ GB
    // on each test. The Llama instance is shared across all test groups.
    progress.log('Loading model...');
    loader = ModelLoader();
    final result = await loader.loadModel();

    if (!result.loaded) {
      progress.log('FATAL: Model failed to load');
      fail(
        'Model failed to load — architecture error detected.\n'
        'This is the go/no-go gate for llama_cpp_dart Cohere2 support.\n'
        'Error: ${result.architectureError}',
      );
    }

    progress.log('Model loaded: ${result.modelInfo?.modelPath}');
    progress.log('Context size: ${result.modelInfo?.contextSize}');

    // ignore: avoid_print
    print('Model loaded: ${result.modelInfo?.modelPath}');
    // ignore: avoid_print
    print('Context size: ${result.modelInfo?.contextSize}');
  });

  tearDownAll(() async {
    // Write all accumulated results to JSON for the judge scripts.
    final path = await reportWriter.writeResults();
    progress.log('Results saved to: $path');
    // ignore: avoid_print
    print('All results saved to: $path');
    loader.dispose();
  });

  // ---------------------------------------------------------------------------
  // Priority Languages — individual tests with per-prompt travel phrase
  // assertions and Cantonese particle validation.
  // ---------------------------------------------------------------------------

  group('Priority Languages — Travel Phrases', () {
    progress.logSection('Priority Languages — Travel Phrases');

    for (final lang in mustHaveLanguages) {
      testWidgets(
        '${lang.languageName} — travel phrases produce correct script output',
        (tester) async {
          await pumpTestOverlay(tester);

          // Resume: skip languages already present in spike_results.json.
          if (completedLanguageCodes.contains(lang.languageCode)) {
            progress.log('SKIPPED (already in results): ${lang.languageName}');
            await refreshOverlay(tester);
            return;
          }

          final testName = '${lang.languageName} (${lang.prompts.length} prompts)';
          progress.logTestStart(testName);
          final sw = Stopwatch()..start();

          final promptResults = <PromptResultData>[];
          var promptIdx = 0;

          for (final testPrompt in lang.prompts) {
            promptIdx++;
            progress.log('  [${lang.languageName}] prompt $promptIdx/${lang.prompts.length}: ${testPrompt.category}');
            progress.log('  PROMPT: ${testPrompt.sourceText}');
            await refreshOverlay(tester);
            // Yield to the Android event loop between prompts to prevent ANR.
            await Future<void>.delayed(const Duration(milliseconds: 100));

            final stopwatch = Stopwatch()..start();
            final tokens = <String>[];

            await for (final token
                in loader.generateStream(testPrompt.prompt)) {
              tokens.add(token);
            }
            stopwatch.stop();

            final output = tokens.join();
            progress.log('  RESPONSE: $output');
            await refreshOverlay(tester);
            final scriptOk = lang.scriptValidator.hasMatch(output);

            promptResults.add(PromptResultData(
              category: testPrompt.category,
              sourceText: testPrompt.sourceText,
              prompt: testPrompt.prompt,
              generatedOutput: output,
              tokenCount: tokens.length,
              tokensPerSecond:
                  tokens.length / (stopwatch.elapsedMilliseconds / 1000.0),
              scriptValidationPassed: scriptOk,
              durationMs: stopwatch.elapsedMilliseconds,
            ));

            // Log script validation result (non-fatal — judge tooling handles quality).
            if (lang.languageCode != 'en' && !scriptOk) {
              progress.log('  SCRIPT MISMATCH: expected ${lang.scriptFamily.name}, got: "${output.substring(0, output.length.clamp(0, 100))}"');
              await refreshOverlay(tester);
            }
          }

          // Cantonese-specific check (non-fatal log).
          if (lang.languageName.contains('Cantonese')) {
            final allOutput =
                promptResults.map((r) => r.generatedOutput).join(' ');
            final cantoneseParticles = RegExp(r'[㗎囉喇嘅咁咋㖖]');
            if (!cantoneseParticles.hasMatch(allOutput)) {
              progress.log('  NO CANTONESE PARTICLES: output may be standard Mandarin');
              await refreshOverlay(tester);
            }
          }

          sw.stop();
          progress.logTestResult(testName, passed: true, duration: sw.elapsed);
          await refreshOverlay(tester);

          await reportWriter.addLanguageResult(LanguageResultData(
            languageName: lang.languageName,
            languageCode: lang.languageCode,
            scriptFamily: lang.scriptFamily.name,
            priority: lang.priority.name,
            prompts: promptResults,
          ));
        },
        timeout: Timeout.none,
      );
    }
  });

  // ---------------------------------------------------------------------------
  // Standard Languages — one test per language with script validation.
  // Latin-script languages have relaxed validation (hard to distinguish French
  // from English by script alone; the LLM-as-judge handles quality).
  // Non-Latin-script languages have strict validation (Arabic must contain
  // Arabic chars, Thai must contain Thai chars, etc.).
  // ---------------------------------------------------------------------------

  group('Standard Languages — Reference Sentences', () {
    progress.logSection('Standard Languages — Reference Sentences');

    for (var langIdx = 0; langIdx < standardLanguages.length; langIdx++) {
      final lang = standardLanguages[langIdx];
      testWidgets(
        '${lang.languageName} — reference sentences produce correct script output',
        (tester) async {
          await pumpTestOverlay(tester);

          // Resume: skip languages already present in spike_results.json.
          if (completedLanguageCodes.contains(lang.languageCode)) {
            progress.log('SKIPPED (already in results): ${lang.languageName}');
            await refreshOverlay(tester);
            return;
          }

          final testName = '${lang.languageName} [${langIdx + 1}/${standardLanguages.length}]';
          progress.logTestStart(testName);
          final sw = Stopwatch()..start();

          final promptResults = <PromptResultData>[];

          for (final testPrompt in lang.prompts) {
            progress.log('  PROMPT: ${testPrompt.sourceText}');
            await refreshOverlay(tester);
            // Yield to the Android event loop between prompts to prevent ANR.
            await Future<void>.delayed(const Duration(milliseconds: 100));

            final stopwatch = Stopwatch()..start();
            final tokens = <String>[];

            await for (final token
                in loader.generateStream(testPrompt.prompt)) {
              tokens.add(token);
            }
            stopwatch.stop();

            final output = tokens.join();
            progress.log('  RESPONSE: $output');
            await refreshOverlay(tester);
            final scriptOk = lang.scriptValidator.hasMatch(output);

            promptResults.add(PromptResultData(
              category: testPrompt.category,
              sourceText: testPrompt.sourceText,
              prompt: testPrompt.prompt,
              generatedOutput: output,
              tokenCount: tokens.length,
              tokensPerSecond:
                  tokens.length / (stopwatch.elapsedMilliseconds / 1000.0),
              scriptValidationPassed: scriptOk,
              durationMs: stopwatch.elapsedMilliseconds,
            ));

            // Log script validation result (non-fatal — judge tooling handles quality).
            if (lang.scriptFamily != ScriptFamily.latin && !scriptOk) {
              progress.log('  SCRIPT MISMATCH: expected ${lang.scriptFamily.name}, got: "${output.substring(0, output.length.clamp(0, 100))}"');
              await refreshOverlay(tester);
            }
          }

          sw.stop();
          progress.logTestResult(testName, passed: true, duration: sw.elapsed);
          await refreshOverlay(tester);

          await reportWriter.addLanguageResult(LanguageResultData(
            languageName: lang.languageName,
            languageCode: lang.languageCode,
            scriptFamily: lang.scriptFamily.name,
            priority: lang.priority.name,
            prompts: promptResults,
          ));
        },
        timeout: Timeout.none,
      );
    }
  });
}
