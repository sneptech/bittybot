import 'package:bittybot/core/diagnostics/performance_monitor.dart';
import 'package:test/test.dart';

void main() {
  late PerformanceMonitor monitor;

  setUp(() {
    monitor = PerformanceMonitor.instance;
    monitor.reset();
  });

  group('Model Load Metrics', () {
    test('markModelLoadStart and markModelLoadEnd records duration', () {
      monitor.markModelLoadStart();
      monitor.markModelLoadEnd();

      expect(monitor.lastModelLoadDuration, isNotNull);
      expect(
        monitor.lastModelLoadDuration!.inMilliseconds,
        greaterThanOrEqualTo(0),
      );
    });

    test('markModelLoadEnd without start is a no-op', () {
      monitor.markModelLoadEnd();
      expect(monitor.lastModelLoadDuration, isNull);
    });

    test('reset clears model load metrics', () {
      monitor.markModelLoadStart();
      monitor.markModelLoadEnd();
      expect(monitor.lastModelLoadDuration, isNotNull);

      monitor.reset();
      expect(monitor.lastModelLoadDuration, isNull);
    });
  });

  group('Inference Request Metrics', () {
    test('tracks full request lifecycle', () {
      monitor.markRequestStart(42);
      monitor.markFirstToken(42);
      monitor.markToken(42);
      monitor.markToken(42);
      monitor.markToken(42);

      final metrics = monitor.markRequestEnd(42);

      expect(metrics, isNotNull);
      expect(metrics!.requestId, 42);
      expect(metrics.tokenCount, 3);
      expect(metrics.totalDuration.inMilliseconds, greaterThanOrEqualTo(0));
      expect(metrics.timeToFirstToken.inMilliseconds, greaterThanOrEqualTo(0));
      expect(metrics.tokensPerSecond, greaterThanOrEqualTo(0));
    });

    test('markFirstToken only records once', () {
      monitor.markRequestStart(1);
      monitor.markFirstToken(1);
      monitor.markFirstToken(1);
      monitor.markToken(1);

      final metrics = monitor.markRequestEnd(1);
      expect(metrics, isNotNull);
      expect(metrics!.timeToFirstToken.inMilliseconds, greaterThanOrEqualTo(0));
    });

    test('markRequestEnd for unknown requestId returns null', () {
      final metrics = monitor.markRequestEnd(999);
      expect(metrics, isNull);
    });

    test('markToken increments count correctly', () {
      monitor.markRequestStart(10);
      for (var i = 0; i < 50; i++) {
        monitor.markToken(10);
      }
      monitor.markFirstToken(10);

      final metrics = monitor.markRequestEnd(10);
      expect(metrics!.tokenCount, 50);
    });

    test('lastInferenceMetrics returns most recent completed request', () {
      expect(monitor.lastInferenceMetrics, isNull);

      monitor.markRequestStart(1);
      monitor.markToken(1);
      monitor.markRequestEnd(1);

      expect(monitor.lastInferenceMetrics, isNotNull);
      expect(monitor.lastInferenceMetrics!.requestId, 1);

      monitor.markRequestStart(2);
      monitor.markToken(2);
      monitor.markToken(2);
      monitor.markRequestEnd(2);

      expect(monitor.lastInferenceMetrics!.requestId, 2);
      expect(monitor.lastInferenceMetrics!.tokenCount, 2);
    });

    test('reset clears active requests and last metrics', () {
      monitor.markRequestStart(1);
      monitor.markToken(1);
      monitor.markRequestEnd(1);

      monitor.reset();
      expect(monitor.lastInferenceMetrics, isNull);
    });
  });

  group('Download Progress Metrics', () {
    test('tracks callback count', () {
      expect(monitor.progressCallbackCount, 0);

      monitor.recordProgressCallback(0.1);
      monitor.recordProgressCallback(0.2);
      monitor.recordProgressCallback(0.3);

      expect(monitor.progressCallbackCount, 3);
    });

    test('detects progress regressions', () {
      monitor.recordProgressCallback(0.5);
      monitor.recordProgressCallback(0.3);
      monitor.recordProgressCallback(0.6);
      monitor.recordProgressCallback(0.2);

      expect(monitor.progressRegressionCount, 2);
    });

    test('monotonic progress has zero regressions', () {
      monitor.recordProgressCallback(0.1);
      monitor.recordProgressCallback(0.2);
      monitor.recordProgressCallback(0.5);
      monitor.recordProgressCallback(1.0);

      expect(monitor.progressRegressionCount, 0);
    });

    test('resetProgressMetrics clears all download tracking', () {
      monitor.recordProgressCallback(0.5);
      monitor.recordProgressCallback(0.3);

      monitor.resetProgressMetrics();
      expect(monitor.progressCallbackCount, 0);
      expect(monitor.progressRegressionCount, 0);
    });
  });

  group('InferenceMetrics snapshot', () {
    test('toString produces readable output', () {
      const metrics = InferenceMetrics(
        requestId: 7,
        totalDuration: Duration(milliseconds: 1500),
        timeToFirstToken: Duration(milliseconds: 200),
        tokenCount: 25,
        tokensPerSecond: 16.67,
      );

      final output = metrics.toString();
      expect(output, contains('req=7'));
      expect(output, contains('total=1500ms'));
      expect(output, contains('ttft=200ms'));
      expect(output, contains('tokens=25'));
      expect(output, contains('16.67'));
    });
  });
}
