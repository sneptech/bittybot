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
///
/// Brand colours pulled from lib/core/theme/app_colors.dart:
///   surface          #0A1A0A  — near-black green scaffold background
///   surfaceContainer #0F2B0F  — slightly lighter dark green (header)
///   primary          #1B5E20  — forest green
///   secondary        #8BC34A  — lime / yellow-green accent
///   onSurfaceVariant #B0D0B0  — muted green-tinted text
class TestOverlayApp extends StatelessWidget {
  const TestOverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        // Near-black green — matches AppColors.surface.
        scaffoldBackgroundColor: const Color(0xFF0A1A0A),
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
  final _progress = TestProgressController.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header — forest-green brand colour (AppColors.surfaceContainer).
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: const Color(0xFF0F2B0F),
              child: const Text(
                'BittyBot Integration Tests',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  // Lime accent (AppColors.secondary).
                  color: Color(0xFF8BC34A),
                ),
              ),
            ),
            // Border line — lime accent (AppColors.secondary).
            const Divider(height: 1, color: Color(0xFF8BC34A)),
            // Scrolling log output.
            // reverse: true makes new lines appear at the bottom automatically
            // without any ScrollController.jumpTo() logic. The GPU is busy
            // running the model so we avoid animated scrolling entirely.
            Expanded(
              child: StreamBuilder<List<String>>(
                stream: _progress.lines,
                initialData: _progress.currentLines,
                builder: (context, snapshot) {
                  final lines = snapshot.data ?? [];
                  return ListView.builder(
                    // Newest item is at index 0 of a reversed list, which
                    // renders at the bottom of the viewport.
                    reverse: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: lines.length,
                    itemBuilder: (context, index) {
                      // Reverse the index so the last log line is shown first
                      // (i.e. at the bottom with reverse: true).
                      final line = lines[lines.length - 1 - index];
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
  ///
  /// Palette keeps terminal semantics (green=pass, red=fail) while using
  /// brand-adjacent tones that complement the forest-green / lime theme.
  Color _colorForLine(String line) {
    // PASS — bright lime green (on-brand, clearly positive).
    if (line.contains('PASS ')) return const Color(0xFF8BC34A);
    // FAIL — brand error pink-red (AppColors.error).
    if (line.contains('FAIL ')) return const Color(0xFFCF6679);
    // START — soft forest green highlight.
    if (line.contains('START ')) return const Color(0xFF66BB6A);
    // PROMPT — warm amber, stands out from green palette.
    if (line.contains('PROMPT:')) return const Color(0xFFFFAB40);
    // RESPONSE — muted green-white (AppColors.onSurfaceVariant).
    if (line.contains('RESPONSE:')) return const Color(0xFFB0D0B0);
    // Section dividers — lime accent (AppColors.secondary).
    if (line.contains('---')) return const Color(0xFF8BC34A);
    // Default — muted green-tinted text (AppColors.onSurfaceVariant).
    return const Color(0xFFB0D0B0);
  }
}
