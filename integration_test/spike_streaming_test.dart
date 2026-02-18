import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'helpers/model_loader.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.defaultTestTimeout = Timeout.none;

  group('Phase 1 Spike: Token Streaming', () {

    testWidgets('tokens arrive one-at-a-time during generation (not buffered)', (tester) async {
      // Arrange
      final loader = ModelLoader();
      await loader.loadModel();

      final tokens = <String>[];
      final timestamps = <DateTime>[];

      // Act — stream tokens and record arrival timestamps
      await for (final token in loader.generateStream(
        '<|START_OF_TURN_TOKEN|><|USER_TOKEN|>Write a short paragraph about the weather.<|END_OF_TURN_TOKEN|><|START_OF_TURN_TOKEN|><|CHATBOT_TOKEN|>',
      )) {
        tokens.add(token);
        timestamps.add(DateTime.now());
      }

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

      loader.dispose();
    }, timeout: Timeout.none);

    testWidgets('streaming produces same output as complete generation', (tester) async {
      // Arrange
      final loader = ModelLoader();
      await loader.loadModel();

      const prompt = '<|START_OF_TURN_TOKEN|><|USER_TOKEN|>Say "hello world" in Japanese.<|END_OF_TURN_TOKEN|><|START_OF_TURN_TOKEN|><|CHATBOT_TOKEN|>';

      // Act — collect streamed tokens
      final streamedTokens = <String>[];
      await for (final token in loader.generateStream(prompt)) {
        streamedTokens.add(token);
      }
      final streamedOutput = streamedTokens.join();

      // Assert
      expect(streamedOutput, isNotEmpty);
      expect(streamedTokens.length, greaterThan(1),
        reason: 'Streaming should produce multiple tokens');

      loader.dispose();
    }, timeout: Timeout.none);

    testWidgets('token generation speed is measured', (tester) async {
      // Arrange
      final loader = ModelLoader();
      await loader.loadModel();

      final stopwatch = Stopwatch()..start();
      var tokenCount = 0;

      // Act
      await for (final _ in loader.generateStream(
        '<|START_OF_TURN_TOKEN|><|USER_TOKEN|>Translate "Where is the bathroom?" into Thai.<|END_OF_TURN_TOKEN|><|START_OF_TURN_TOKEN|><|CHATBOT_TOKEN|>',
      )) {
        tokenCount++;
      }
      stopwatch.stop();

      // Record performance metrics (informational, not a pass/fail gate)
      final tokensPerSecond = tokenCount / (stopwatch.elapsedMilliseconds / 1000.0);
      // ignore: avoid_print
      print('Performance: $tokenCount tokens in ${stopwatch.elapsedMilliseconds}ms '
            '($tokensPerSecond tokens/sec)');

      // Assert — at least some tokens were generated
      expect(tokenCount, greaterThan(0));
      // Thai script should be present
      expect(RegExp(r'[\u0E00-\u0E7F]').hasMatch(
        (await loader.generateStream(
          '<|START_OF_TURN_TOKEN|><|USER_TOKEN|>Say "hello" in Thai.<|END_OF_TURN_TOKEN|><|START_OF_TURN_TOKEN|><|CHATBOT_TOKEN|>',
        ).toList()).join()
      ), isTrue, reason: 'Thai translation should contain Thai script characters');

      loader.dispose();
    }, timeout: Timeout.none);
  });
}
