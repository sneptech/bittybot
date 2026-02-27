import 'package:bittybot/features/model_distribution/model_distribution_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveMonotonicProgress', () {
    test('progress never decreases', () {
      final resolved = resolveMonotonicProgress(
        previousProgress: 0.65,
        incomingProgress: 0.42,
      );

      expect(resolved, 0.65);
    });

    test('rapid callbacks with oscillating values only move forward', () {
      const updates = [0.1, 0.35, 0.28, 0.5, 0.41, 0.74, 0.7, 0.92];
      var progress = 0.0;
      final observed = <double>[];

      for (final update in updates) {
        progress = resolveMonotonicProgress(
          previousProgress: progress,
          incomingProgress: update,
        );
        observed.add(progress);
      }

      expect(observed, [0.1, 0.35, 0.35, 0.5, 0.5, 0.74, 0.74, 0.92]);
    });
  });

  group('resolveResumeProgress', () {
    test('persisted < live uses live progress', () {
      final resolved = resolveResumeProgress(
        persistedProgress: 0.3,
        liveProgress: 0.55,
      );

      expect(resolved, 0.55);
    });
  });
}
