import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/model_distribution/model_distribution_state.dart';
import 'features/model_distribution/providers.dart';
import 'features/model_distribution/widgets/download_screen.dart';
import 'features/model_distribution/widgets/model_loading_overlay.dart';

// ─── Placeholder colours ──────────────────────────────────────────────────────

/// Dark background matching the download screen.
const _kBackground = Color(0xFF121212); // TODO(phase-3): Replace with design system color

// ─── App root ─────────────────────────────────────────────────────────────────

/// Root application widget.
///
/// Wraps everything in [MaterialApp] and delegates routing to [_AppRouter].
/// Phase 3 (App Foundation) will replace the theme and may add GoRouter.
class BittyBotApp extends ConsumerWidget {
  const BittyBotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'BittyBot',
      debugShowCheckedModeBanner: false,
      // TODO(phase-3): Replace with design system theme
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _kBackground,
      ),
      home: const _AppRouter(),
    );
  }
}

// ─── App router ───────────────────────────────────────────────────────────────

/// Routes between [DownloadScreen] and the main app screen based on model state.
///
/// On app start, calls [ModelDistributionNotifier.initialize] via a
/// post-frame callback so the first [build] sees [CheckingModelState].
///
/// Routing rules:
/// - [LoadingModelState] or [ModelReadyState]: show main app screen
/// - Any other state: show [DownloadScreen]
class _AppRouter extends ConsumerStatefulWidget {
  const _AppRouter();

  @override
  ConsumerState<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends ConsumerState<_AppRouter> {
  @override
  void initState() {
    super.initState();
    // Initialize after first frame so the notifier's build() has already run
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(modelDistributionProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final modelState = ref.watch(modelDistributionProvider);

    // Show the main app screen once model is verified and loading (or ready).
    // Any download-related state shows the download screen instead.
    final showMainScreen =
        modelState is LoadingModelState || modelState is ModelReadyState;

    if (showMainScreen) {
      return const _MainAppScreen();
    }
    return const DownloadScreen();
  }
}

// ─── Main app screen (placeholder) ───────────────────────────────────────────

/// Placeholder main app screen for Phase 2.
///
/// Renders [ModelLoadingOverlay] on top of a minimal scaffold so the
/// greyscale-to-color logo transition and disabled text field are visible.
///
/// Phase 3 (App Foundation) and Phase 6 (Chat UI) will replace this with the
/// real app structure. For now the body exists only to give the overlay
/// something to overlay.
class _MainAppScreen extends ConsumerWidget {
  const _MainAppScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isReady = ref.watch(modelDistributionProvider) is ModelReadyState;

    return ModelLoadingOverlay(
      child: Scaffold(
        backgroundColor: _kBackground,
        appBar: AppBar(
          backgroundColor: _kBackground,
          title: const Text(
            'BittyBot',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Expanded(
                child: Center(
                  child: Text(
                    // TODO(phase-6): Replace with real chat message list
                    'Chat messages will appear here',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ),
              // Text input — disabled until model is ready
              TextField(
                enabled: isReady,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  // TODO(phase-6): Refine placeholder text and styling
                  hintText: isReady ? 'Type a message...' : 'Loading model...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
