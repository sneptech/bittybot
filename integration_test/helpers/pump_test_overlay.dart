import 'package:flutter_test/flutter_test.dart';

import 'test_overlay_app.dart';

/// Pumps the [TestOverlayApp] widget so that the device screen shows live
/// test progress instead of the default blank "Test starting..." banner.
///
/// Call this at the start of each `testWidgets` callback:
///
/// ```dart
/// testWidgets('my test', (tester) async {
///   await pumpTestOverlay(tester);
///   // ... rest of test
/// });
/// ```
///
/// The overlay is rebuilt on each pump, picking up the latest log lines from
/// [TestProgressController].
Future<void> pumpTestOverlay(WidgetTester tester) async {
  await tester.pumpWidget(const TestOverlayApp());
  // Allow one frame for the StreamBuilder to pick up initial data.
  await tester.pump();
}

/// Pumps a single frame so the overlay can redraw with new log lines.
///
/// Call this after logging progress if you want the screen to update
/// mid-test (e.g., after each language in the multilingual test).
/// Not strictly required -- the overlay updates automatically via the
/// stream -- but forces an immediate visual refresh.
Future<void> refreshOverlay(WidgetTester tester) async {
  await tester.pump();
}
