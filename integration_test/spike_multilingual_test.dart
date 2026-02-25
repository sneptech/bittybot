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
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/language_corpus.dart';
import 'helpers/model_loader.dart';
import 'helpers/pump_test_overlay.dart';
import 'helpers/report_writer.dart';
import 'helpers/test_progress_controller.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Disable the global timeout — inference on-device is slow and unbounded.
  binding.defaultTestTimeout = Timeout.none;

  final progress = TestProgressController.instance;
  late ModelLoader loader;
  final reportWriter = ReportWriter();

  setUpAll(() async {
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

            // Per-prompt assertion: correct script for non-English languages.
            // English is validated by the judge (Latin script is too broad to
            // distinguish English from other Latin-script languages).
            if (lang.languageCode != 'en') {
              expect(
                scriptOk,
                isTrue,
                reason:
                    '${lang.languageName} output should contain '
                    '${lang.scriptFamily.name} script characters. '
                    'Source: "${testPrompt.sourceText}". '
                    'Got: "${output.substring(0, output.length.clamp(0, 100))}"',
              );
            }
          }

          // Cantonese-specific check: output must contain Cantonese-specific
          // particles (㗎, 囉, 喇, 嘅, 咁, 咋, 㖖) that distinguish it from
          // standard Mandarin Chinese.
          if (lang.languageName.contains('Cantonese')) {
            final allOutput =
                promptResults.map((r) => r.generatedOutput).join(' ');
            final cantoneseParticles = RegExp(r'[㗎囉喇嘅咁咋㖖]');
            final hasCantoneseParticles =
                cantoneseParticles.hasMatch(allOutput);
            expect(
              hasCantoneseParticles,
              isTrue,
              reason:
                  'Cantonese output should contain Cantonese-specific particles '
                  '(㗎, 囉, 喇, 嘅, 咁, 咋, 㖖), not just standard Mandarin CJK. '
                  'Got: "${allOutput.substring(0, allOutput.length.clamp(0, 200))}"',
            );
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
          final testName = '${lang.languageName} [${langIdx + 1}/${standardLanguages.length}]';
          progress.logTestStart(testName);
          final sw = Stopwatch()..start();

          final promptResults = <PromptResultData>[];

          for (final testPrompt in lang.prompts) {
            progress.log('  PROMPT: ${testPrompt.sourceText}');
            await refreshOverlay(tester);

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

            // Script validation: only assert for non-Latin-script languages.
            // Latin-script validation is too broad (English is also Latin), so
            // we rely on the LLM-as-judge to catch language switches there.
            if (lang.scriptFamily != ScriptFamily.latin) {
              expect(
                scriptOk,
                isTrue,
                reason:
                    '${lang.languageName} (${lang.scriptFamily.name}) output '
                    'should contain target script characters. '
                    'Source: "${testPrompt.sourceText}". '
                    'Got: "${output.substring(0, output.length.clamp(0, 100))}"',
              );
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
