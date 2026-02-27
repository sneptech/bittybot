import 'dart:convert';
import 'dart:developer' as developer;

/// Singleton performance monitor for inference pipeline metrics.
///
/// Collects timing data for model load, per-request inference, and download
/// progress. Emits structured log lines prefixed with `[PERF]`.
class PerformanceMonitor {
  PerformanceMonitor._();

  static final PerformanceMonitor instance = PerformanceMonitor._();

  DateTime? _modelLoadStartTime;
  Duration? _lastModelLoadDuration;

  final Map<int, _RequestMetrics> _activeRequests = {};
  InferenceMetrics? _lastInferenceMetrics;

  DateTime? _lastProgressCallbackTime;
  int _progressCallbackCount = 0;
  double _lastProgressValue = 0.0;
  int _progressRegressionCount = 0;

  Duration? get lastModelLoadDuration => _lastModelLoadDuration;
  InferenceMetrics? get lastInferenceMetrics => _lastInferenceMetrics;
  int get progressCallbackCount => _progressCallbackCount;
  int get progressRegressionCount => _progressRegressionCount;
  DateTime? get lastProgressCallbackTime => _lastProgressCallbackTime;

  void markModelLoadStart() {
    _modelLoadStartTime = DateTime.now();
  }

  void markModelLoadEnd() {
    final start = _modelLoadStartTime;
    if (start == null) {
      return;
    }
    _lastModelLoadDuration = DateTime.now().difference(start);
    _modelLoadStartTime = null;
    _emitMetric(
      'model_load',
      {'duration_ms': _lastModelLoadDuration!.inMilliseconds},
    );
  }

  void markRequestStart(int requestId) {
    _activeRequests[requestId] = _RequestMetrics(startTime: DateTime.now());
  }

  void markFirstToken(int requestId) {
    final metrics = _activeRequests[requestId];
    if (metrics == null || metrics.firstTokenTime != null) {
      return;
    }
    metrics.firstTokenTime = DateTime.now();
    metrics.timeToFirstToken = metrics.firstTokenTime!.difference(
      metrics.startTime,
    );
  }

  void markToken(int requestId) {
    final metrics = _activeRequests[requestId];
    if (metrics != null) {
      metrics.tokenCount++;
    }
  }

  InferenceMetrics? markRequestEnd(int requestId) {
    final metrics = _activeRequests.remove(requestId);
    if (metrics == null) {
      return null;
    }

    final totalDuration = DateTime.now().difference(metrics.startTime);
    final tokensPerSecond =
        metrics.tokenCount > 0 && totalDuration.inMilliseconds > 0
        ? metrics.tokenCount / (totalDuration.inMilliseconds / 1000.0)
        : 0.0;

    final snapshot = InferenceMetrics(
      requestId: requestId,
      totalDuration: totalDuration,
      timeToFirstToken: metrics.timeToFirstToken ?? Duration.zero,
      tokenCount: metrics.tokenCount,
      tokensPerSecond: tokensPerSecond,
    );
    _lastInferenceMetrics = snapshot;

    _emitMetric('inference_request', {
      'request_id': requestId,
      'total_ms': totalDuration.inMilliseconds,
      'ttft_ms': (metrics.timeToFirstToken ?? Duration.zero).inMilliseconds,
      'token_count': metrics.tokenCount,
      'tokens_per_sec': tokensPerSecond.toStringAsFixed(2),
    });

    return snapshot;
  }

  void recordProgressCallback(double progress) {
    _progressCallbackCount++;
    _lastProgressCallbackTime = DateTime.now();

    if (progress < _lastProgressValue) {
      _progressRegressionCount++;
      _emitMetric('progress_regression', {
        'callback_num': _progressCallbackCount,
        'old_value': _lastProgressValue.toStringAsFixed(4),
        'new_value': progress.toStringAsFixed(4),
      });
    }

    _lastProgressValue = progress;
  }

  void resetProgressMetrics() {
    _lastProgressCallbackTime = null;
    _progressCallbackCount = 0;
    _lastProgressValue = 0.0;
    _progressRegressionCount = 0;
  }

  void reset() {
    _modelLoadStartTime = null;
    _lastModelLoadDuration = null;
    _activeRequests.clear();
    _lastInferenceMetrics = null;
    resetProgressMetrics();
  }

  void _emitMetric(String category, Map<String, Object> data) {
    final payload = <String, Object>{
      'perf': category,
      'ts': DateTime.now().toIso8601String(),
      ...data,
    };
    final line = '[PERF] ${jsonEncode(payload)}';
    // ignore: avoid_print
    print(line); // Also print to logcat (developer.log only goes to DevTools)
    developer.log(line, name: 'PerformanceMonitor');
  }
}

class _RequestMetrics {
  _RequestMetrics({required this.startTime});

  final DateTime startTime;
  DateTime? firstTokenTime;
  Duration? timeToFirstToken;
  int tokenCount = 0;
}

class InferenceMetrics {
  const InferenceMetrics({
    required this.requestId,
    required this.totalDuration,
    required this.timeToFirstToken,
    required this.tokenCount,
    required this.tokensPerSecond,
  });

  final int requestId;
  final Duration totalDuration;
  final Duration timeToFirstToken;
  final int tokenCount;
  final double tokensPerSecond;

  @override
  String toString() {
    return 'InferenceMetrics(req=$requestId, '
        'total=${totalDuration.inMilliseconds}ms, '
        'ttft=${timeToFirstToken.inMilliseconds}ms, '
        'tokens=$tokenCount, '
        'tok/s=${tokensPerSecond.toStringAsFixed(2)})';
  }
}
