import 'package:flutter/material.dart';

void main() {
  runApp(const BittyBotApp());
}

/// Minimal app scaffold required for integration_test to launch.
/// Production UI will be added in Phase 3 (App Foundation).
class BittyBotApp extends StatelessWidget {
  const BittyBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BittyBot',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const _PlaceholderScreen(),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BittyBot'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Text(
          'BittyBot — Phase 1 Inference Spike',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
