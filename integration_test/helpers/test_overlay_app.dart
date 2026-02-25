import 'package:flutter/material.dart';

import 'test_progress_controller.dart';

/// A minimal Flutter app that displays live test progress as scrolling
/// monospace text on the device screen.
///
/// This widget is pumped by [pumpTestOverlay] at the start of each
/// `testWidgets` callback so the tester can see which test is running and
/// its result, rather than staring at a blank "Test starting..." screen.
///
/// This is test-mode-only infrastructure -- never imported by production code.
class TestOverlayApp extends StatelessWidget {
  const TestOverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
      ),
      home: const _TestOverlayScreen(),
    );
  }
}

class _TestOverlayScreen extends StatefulWidget {
  const _TestOverlayScreen();

  @override
  State<_TestOverlayScreen> createState() => _TestOverlayScreenState();
}

class _TestOverlayScreenState extends State<_TestOverlayScreen> {
  final ScrollController _scrollController = ScrollController();
  final _progress = TestProgressController.instance;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    // Schedule the scroll for after the frame is laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: const Color(0xFF16213E),
              child: const Text(
                'BittyBot Integration Tests',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00D4AA),
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFF00D4AA)),
            // Scrolling log output
            Expanded(
              child: StreamBuilder<List<String>>(
                stream: _progress.lines,
                initialData: _progress.currentLines,
                builder: (context, snapshot) {
                  final lines = snapshot.data ?? [];
                  _scrollToBottom();
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: lines.length,
                    itemBuilder: (context, index) {
                      final line = lines[index];
                      return Text(
                        line,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          height: 1.4,
                          color: _colorForLine(line),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pick a colour based on the content of the log line.
  Color _colorForLine(String line) {
    if (line.contains('PASS ')) return const Color(0xFF00E676);
    if (line.contains('FAIL ')) return const Color(0xFFFF5252);
    if (line.contains('START ')) return const Color(0xFF64B5F6);
    if (line.contains('---')) return const Color(0xFFFFD54F);
    return const Color(0xFFB0BEC5);
  }
}
