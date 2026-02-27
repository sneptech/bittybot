import 'package:bittybot/features/inference/application/inference_isolate.dart';
import 'package:test/test.dart';

void main() {
  group('filterInferenceToken', () {
    test('strips special tokens in <|...|> format', () {
      expect(filterInferenceToken('<|START_OF_TURN_TOKEN|>'), isEmpty);
    });

    test('strips special tokens in |<...>| format', () {
      expect(filterInferenceToken('|<START_RESPONSE>|'), isEmpty);
    });

    test('keeps normal text unchanged', () {
      expect(filterInferenceToken('Hello world'), 'Hello world');
    });

    test('cleans mixed token and text', () {
      expect(filterInferenceToken('<|END_OF_TURN_TOKEN|>Hello'), 'Hello');
    });

    test('flags empty result after filtering so caller can skip send', () {
      final filtered = filterInferenceToken('<|CHATBOT_TOKEN|>');
      expect(shouldSendFilteredToken(filtered), isFalse);
    });

    test('strips all matching tokens when multiple appear', () {
      expect(
        filterInferenceToken(
          '<|USER_TOKEN|>Hello|<START_RESPONSE>|<|END_OF_TURN_TOKEN|>',
        ),
        'Hello',
      );
    });

    test('does not strip partial matches', () {
      expect(filterInferenceToken('<|incomplete'), '<|incomplete');
      expect(filterInferenceToken('|partial'), '|partial');
    });

    test('returns empty for empty input and marks as not sendable', () {
      final filtered = filterInferenceToken('');
      expect(filtered, isEmpty);
      expect(shouldSendFilteredToken(filtered), isFalse);
    });

    test('preserves surrounding whitespace when stripping tokens', () {
      expect(filterInferenceToken('<|FOO|> '), ' ');
    });

    test('strips consecutive tokens with no text between', () {
      expect(filterInferenceToken('<|A_TOKEN|><|B_TOKEN|>'), isEmpty);
    });

    test('strips tokens while preserving unicode text', () {
      expect(filterInferenceToken('<|USER_TOKEN|>مرحبا'), 'مرحبا');
    });

    test('does not strip lowercase or digit token names', () {
      expect(filterInferenceToken('<|foo123|>'), '<|foo123|>');
    });
  });
}
