import 'dart:async';

/// Singleton controller for streaming test progress messages to the on-device
/// overlay.
///
/// Integration tests call [log], [logTestStart], and [logTestResult] to push
/// status lines. The [TestOverlayApp] widget listens to [lines] and renders
/// them in a scrolling monospace display.
///
/// This is test-mode-only infrastructure -- never imported by production code.
class TestProgressController {
  TestProgressController._();

  static final TestProgressController instance = TestProgressController._();

  /// All log lines accumulated so far (kept in memory for the overlay to
  /// rebuild from).
  final List<String> _lines = [];

  /// Broadcast stream that fires the full list of lines on every new message.
  final StreamController<List<String>> _controller =
      StreamController<List<String>>.broadcast();

  /// Stream of accumulated log lines. Each event is the full list (not just
  /// the latest line) so that the overlay can rebuild completely.
  Stream<List<String>> get lines => _controller.stream;

  /// Current snapshot of all lines (for initial data in StreamBuilder).
  List<String> get currentLines => List.unmodifiable(_lines);

  /// Append a raw line to the log.
  void log(String message) {
    final timestamp = DateTime.now();
    final ts =
        '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
    _lines.add('[$ts] $message');
    _controller.add(List.unmodifiable(_lines));
  }

  /// Log the start of a named test.
  void logTestStart(String testName) {
    log('START  $testName');
  }

  /// Log the result of a completed test.
  void logTestResult(
    String testName, {
    required bool passed,
    Duration? duration,
  }) {
    final status = passed ? 'PASS ' : 'FAIL ';
    final durationStr =
        duration != null ? ' (${duration.inMilliseconds}ms)' : '';
    log('$status $testName$durationStr');
  }

  /// Log a section header (e.g., group name).
  void logSection(String sectionName) {
    log('');
    log('--- $sectionName ---');
  }

  /// Reset all state. Useful between test suites if needed.
  void reset() {
    _lines.clear();
    _controller.add(const []);
  }

  /// Close the stream controller. Call in tearDownAll.
  void dispose() {
    _controller.close();
  }
}
