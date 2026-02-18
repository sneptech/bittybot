// Placeholder widget test — full tests will be added in later plans.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: Text('BittyBot'))),
    ));
    expect(find.text('BittyBot'), findsOneWidget);
  });
}
