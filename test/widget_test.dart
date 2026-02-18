// Basic Flutter widget test for BittyBot scaffold.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bittybot/main.dart';

void main() {
  testWidgets('BittyBot scaffold renders placeholder screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const BittyBotApp());

    expect(find.text('BittyBot'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
