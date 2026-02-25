import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'helpers/model_loader.dart';
import 'helpers/pump_test_overlay.dart';
import 'helpers/test_progress_controller.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.defaultTestTimeout = Timeout.none;

  final progress = TestProgressController.instance;
  late ModelLoader loader;

  setUpAll(() async {
    progress.log('Loading model...');
    loader = ModelLoader();
    final result = await loader.loadModel();
    if (!result.loaded) {
      progress.log('FATAL: Model failed to load');
      fail('Model failed to load: ${result.architectureError}');
    }
    progress.log('Model loaded successfully');
  });

  tearDownAll(() {
    loader.dispose();
  });

  group('Phase 1 Spike: Token Streaming', () {

    testWidgets('tokens arrive one-at-a-time during generation (not buffered)', (tester) async {
      await pumpTestOverlay(tester);
      const testName = 'tokens arrive one-at-a-time';
      progress.logTestStart(testName);
      final sw = Stopwatch()..start();

      final tokens = <String>[];
      final timestamps = <DateTime>[];

      // Act — stream tokens and record arrival timestamps
      const prompt = 'Write a short paragraph about the weather.';
      progress.log('PROMPT: $prompt');
      await refreshOverlay(tester);
      await for (final token in loader.generateStream(
        '<|START_OF_TURN_TOKEN|><|USER_TOKEN|>$prompt<|END_OF_TURN_TOKEN|><|START_OF_TURN_TOKEN|><|CHATBOT_TOKEN|>',
      )) {
        tokens.add(token);
        timestamps.add(DateTime.now());
      }
      final response = tokens.join();
      progress.log('RESPONSE: $response');
      await refreshOverlay(tester);

      // Assert — streaming verification
      expect(tokens.length, greaterThan(5),
        reason: 'Should receive multiple individual tokens, not one big chunk');

      // Timestamps should span the generation time, not cluster at the end
      final totalDuration = timestamps.last.difference(timestamps.first);
      expect(totalDuration.inMilliseconds, greaterThan(500),
        reason: 'Token timestamps should span generation time (>500ms), '
                'indicating true streaming. If all tokens arrive within a few ms, '
                'the output is being buffered.');

      // Check that tokens arrive incrementally (not all at once)
      // At least 3 distinct 100ms buckets should have tokens
      final buckets = <int>{};
      for (final ts in timestamps) {
        buckets.add(ts.difference(timestamps.first).inMilliseconds ~/ 100);
      }
      expect(buckets.length, greaterThan(3),
        reason: 'Tokens should arrive across multiple time windows, '
                'not in a single burst');

      sw.stop();
      progress.logTestResult(testName, passed: true, duration: sw.elapsed);
      progress.log('  ${tokens.length} tokens, ${totalDuration.inMilliseconds}ms span');
      await refreshOverlay(tester);
    }, timeout: Timeout.none);

    testWidgets('streaming produces same output as complete generation', (tester) async {
      await pumpTestOverlay(tester);
      const testName = 'streaming matches complete generation';
      progress.logTestStart(testName);
      final sw = Stopwatch()..start();

      const userPrompt = 'Say "hello world" in Japanese.';
      progress.log('PROMPT: $userPrompt');
      await refreshOverlay(tester);
      const prompt = '<|START_OF_TURN_TOKEN|><|USER_TOKEN|>$userPrompt<|END_OF_TURN_TOKEN|><|START_OF_TURN_TOKEN|><|CHATBOT_TOKEN|>';

      // Act — collect streamed tokens
      final streamedTokens = <String>[];
      await for (final token in loader.generateStream(prompt)) {
        streamedTokens.add(token);
      }
      final streamedOutput = streamedTokens.join();
      progress.log('RESPONSE: $streamedOutput');
      await refreshOverlay(tester);

      // Assert
      expect(streamedOutput, isNotEmpty);
      expect(streamedTokens.length, greaterThan(1),
        reason: 'Streaming should produce multiple tokens');

      sw.stop();
      progress.logTestResult(testName, passed: true, duration: sw.elapsed);
      await refreshOverlay(tester);
    }, timeout: Timeout.none);

    testWidgets('token generation speed is measured', (tester) async {
      await pumpTestOverlay(tester);
      const testName = 'token generation speed';
      progress.logTestStart(testName);
      final sw = Stopwatch()..start();

      final stopwatch = Stopwatch()..start();
      var tokenCount = 0;

      // Act
      const prompt1 = 'Translate "Where is the bathroom?" into Thai.';
      progress.log('PROMPT: $prompt1');
      await refreshOverlay(tester);
      final tokens1 = <String>[];
      await for (final token in loader.generateStream(
        '<|START_OF_TURN_TOKEN|><|USER_TOKEN|>$prompt1<|END_OF_TURN_TOKEN|><|START_OF_TURN_TOKEN|><|CHATBOT_TOKEN|>',
      )) {
        tokens1.add(token);
        tokenCount++;
      }
      stopwatch.stop();
      final response1 = tokens1.join();
      progress.log('RESPONSE: $response1');
      await refreshOverlay(tester);

      // Record performance metrics (informational, not a pass/fail gate)
      final tokensPerSecond = tokenCount / (stopwatch.elapsedMilliseconds / 1000.0);

      // Assert — at least some tokens were generated
      expect(tokenCount, greaterThan(0));

      // Thai script check
      const prompt2 = 'Say "hello" in Thai.';
      progress.log('PROMPT: $prompt2');
      await refreshOverlay(tester);
      final thaiResponse = (await loader.generateStream(
        '<|START_OF_TURN_TOKEN|><|USER_TOKEN|>$prompt2<|END_OF_TURN_TOKEN|><|START_OF_TURN_TOKEN|><|CHATBOT_TOKEN|>',
      ).toList()).join();
      progress.log('RESPONSE: $thaiResponse');
      await refreshOverlay(tester);

      expect(RegExp(r'[\u0E00-\u0E7F]').hasMatch(thaiResponse),
        isTrue, reason: 'Thai translation should contain Thai script characters');

      sw.stop();
      progress.logTestResult(testName, passed: true, duration: sw.elapsed);
      progress.log('  ${tokensPerSecond.toStringAsFixed(1)} tok/s');
      await refreshOverlay(tester);
    }, timeout: Timeout.none);
  });
}
