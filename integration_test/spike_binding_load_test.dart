import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'helpers/model_loader.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.defaultTestTimeout = Timeout.none;

  group('Phase 1 Spike: Binding Load', () {

    testWidgets('Tiny Aya Global Q4_K_M loads without architecture error', (tester) async {
      // Arrange
      final loader = ModelLoader();

      // Act — this is the critical go/no-go check
      final result = await loader.loadModel();

      // Assert
      expect(result.loaded, isTrue,
        reason: 'Model must load without architecture error. '
                'If this fails, the llama.cpp version in the binding '
                'does not support Cohere2 architecture.');
      expect(result.architectureError, isNull,
        reason: 'No architecture error should be reported');
      expect(result.modelInfo, isNotNull);
      expect(result.modelInfo!.contextSize, greaterThan(0));
    }, timeout: Timeout.none);

    testWidgets('model generates non-empty text from a simple English prompt', (tester) async {
      // Arrange
      final loader = ModelLoader();
      await loader.loadModel();

      // Act
      final output = await loader.generateComplete(
        'Translate "Hello" into French.',
      );

      // Assert
      expect(output, isNotEmpty,
        reason: 'Model must produce non-empty output from a simple prompt');
      expect(output.length, greaterThan(2),
        reason: 'Output should be more than just whitespace or a single character');

      // Cleanup
      loader.dispose();
    }, timeout: Timeout.none);

    testWidgets('model handles Aya chat template format', (tester) async {
      // Arrange
      final loader = ModelLoader();
      await loader.loadModel();

      // Act — use the full Aya chat template
      final output = await loader.generateComplete(
        '<|START_OF_TURN_TOKEN|><|USER_TOKEN|>Translate "Good morning" into Spanish.<|END_OF_TURN_TOKEN|><|START_OF_TURN_TOKEN|><|CHATBOT_TOKEN|>',
      );

      // Assert
      expect(output, isNotEmpty);
      // Spanish output should contain Latin characters
      expect(RegExp(r'[a-záéíóúñü]', caseSensitive: false).hasMatch(output), isTrue,
        reason: 'Spanish translation should contain Latin characters');

      loader.dispose();
    }, timeout: Timeout.none);
  });
}
