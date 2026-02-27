import 'dart:developer' as developer;

/// Named profiling spans for Flutter DevTools Timeline integration.
class InferenceProfiler {
  InferenceProfiler._();

  /// Starts a profiling span. Call [ProfileSpan.finish] to close it.
  static ProfileSpan startSpan(String name) {
    final task = developer.TimelineTask(filterKey: 'inference');
    task.start(name);
    return ProfileSpan._(name: name, task: task);
  }
}

/// A running profiling span.
class ProfileSpan {
  ProfileSpan._({required this.name, required developer.TimelineTask task})
    : _task = task;

  final String name;
  final developer.TimelineTask _task;
  final Stopwatch _stopwatch = Stopwatch()..start();

  /// Ends this span and records elapsed time in the timeline.
  void finish() {
    _stopwatch.stop();
    _task.finish(arguments: {'elapsed_ms': _stopwatch.elapsedMilliseconds});
  }

  /// Elapsed duration since span start.
  Duration get elapsed => _stopwatch.elapsed;
}
