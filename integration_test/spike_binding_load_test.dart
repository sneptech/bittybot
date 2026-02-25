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
  late ModelLoadResult loadResult;

  setUpAll(() async {
    // Load model once for all tests — 2 GB model on 4 GB device cannot be
    // loaded multiple times concurrently.
    progress.log('Loading model...');
    loader = ModelLoader();
    loadResult = await loader.loadModel();
    progress.log('Model loaded: ${loadResult.loaded}');
  });

  tearDownAll(() {
    loader.dispose();
  });

  group('Phase 1 Spike: Binding Load', () {

    testWidgets('Tiny Aya Global Q4_K_M loads without architecture error', (tester) async {
      await pumpTestOverlay(tester);
      const testName = 'loads without architecture error';
      progress.logTestStart(testName);
      final sw = Stopwatch()..start();

      // Assert — model was loaded in setUpAll
      expect(loadResult.loaded, isTrue,
        reason: 'Model must load without architecture error. '
                'If this fails, the llama.cpp version in the binding '
                'does not support Cohere2 architecture.');
      expect(loadResult.architectureError, isNull,
        reason: 'No architecture error should be reported');
      expect(loadResult.modelInfo, isNotNull);
      expect(loadResult.modelInfo!.contextSize, greaterThan(0));

      sw.stop();
      progress.logTestResult(testName, passed: true, duration: sw.elapsed);
      await refreshOverlay(tester);
    }, timeout: Timeout.none);

    testWidgets('model generates non-empty text from a simple English prompt', (tester) async {
      await pumpTestOverlay(tester);
      const testName = 'generates non-empty English text';
      progress.logTestStart(testName);
      final sw = Stopwatch()..start();

      // Act
      final output = await loader.generateComplete(
        'Translate "Hello" into French.',
      );

      // Assert
      expect(output, isNotEmpty,
        reason: 'Model must produce non-empty output from a simple prompt');
      expect(output.length, greaterThan(2),
        reason: 'Output should be more than just whitespace or a single character');

      sw.stop();
      progress.logTestResult(testName, passed: true, duration: sw.elapsed);
      await refreshOverlay(tester);
    }, timeout: Timeout.none);

    testWidgets('model handles Aya chat template format', (tester) async {
      await pumpTestOverlay(tester);
      const testName = 'handles Aya chat template';
      progress.logTestStart(testName);
      final sw = Stopwatch()..start();

      // Act — use the full Aya chat template
      final output = await loader.generateComplete(
        '<|START_OF_TURN_TOKEN|><|USER_TOKEN|>Translate "Good morning" into Spanish.<|END_OF_TURN_TOKEN|><|START_OF_TURN_TOKEN|><|CHATBOT_TOKEN|>',
      );

      // Assert
      expect(output, isNotEmpty);
      // Spanish output should contain Latin characters
      expect(RegExp(r'[a-záéíóúñü]', caseSensitive: false).hasMatch(output), isTrue,
        reason: 'Spanish translation should contain Latin characters');

      sw.stop();
      progress.logTestResult(testName, passed: true, duration: sw.elapsed);
      await refreshOverlay(tester);
    }, timeout: Timeout.none);
  });
}
