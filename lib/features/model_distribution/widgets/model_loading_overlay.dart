import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model_distribution_state.dart';
import '../providers.dart';

// ─── Placeholder colours ──────────────────────────────────────────────────────

/// Forest green used as the placeholder icon colour when model is ready.
const _kForestGreen = Color(0xFF2D6A4F); // TODO(phase-3): Replace with design system color

/// Background tint for the loading overlay.
const _kOverlayBackground = Color(0xE6121212); // 90% opaque dark background

// ─── Model loading overlay ────────────────────────────────────────────────────

/// Overlay widget that shows the model loading state on top of the main screen.
///
/// Watches [modelDistributionProvider] and:
/// - Shows a greyscale BittyBot logo + "Loading language model..." text while
///   the model is checking, verifying, or loading.
/// - Crossfades the logo from greyscale to full colour when [ModelReadyState]
///   is reached.
/// - Fades out the overlay entirely once the model is ready, revealing the
///   main app content underneath.
///
/// Per user decisions:
/// - The greyscale-to-colour logo transition IS the "ready" signal — no toast
///   or banner is shown.
/// - The same overlay is shown for both first-launch-after-download AND every
///   subsequent launch.
/// - [ColorFiltered] with [BlendMode.saturation] is intentionally NOT used
///   due to Flutter bug #179606 (greyscales the entire screen).
///   Instead, two separate assets are used with [AnimatedCrossFade].
class ModelLoadingOverlay extends ConsumerWidget {
  const ModelLoadingOverlay({super.key, required this.child});

  /// The main app content rendered beneath the overlay.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelState = ref.watch(modelDistributionProvider);

    final isReady = modelState is ModelReadyState;
    final isLoading = modelState is LoadingModelState ||
        modelState is VerifyingState ||
        modelState is CheckingModelState;

    return Stack(
      children: [
        // Main app content — always present in the widget tree
        child,

        // Loading overlay — fades out when model is ready
        AnimatedOpacity(
          opacity: isReady ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 400),
          // Use IgnorePointer so the (now-invisible) overlay does not block
          // input events after it fades out
          child: IgnorePointer(
            ignoring: isReady,
            child: Container(
              color: _kOverlayBackground,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── BittyBot logo ──────────────────────────────────────
                    // TODO: Replace with actual logo assets when user supplies
                    // them. Use:
                    //   firstChild: Image.asset(
                    //     'assets/logo_greyscale.png', width: 120)
                    //   secondChild: Image.asset(
                    //     'assets/logo_color.png', width: 120)
                    // Do NOT use ColorFiltered(BlendMode.saturation) —
                    // Flutter bug #179606 greyscales the entire screen.
                    AnimatedCrossFade(
                      firstChild: const Icon(
                        Icons.smart_toy,
                        size: 80,
                        color: Colors.grey, // greyscale placeholder
                      ),
                      secondChild: const Icon(
                        Icons.smart_toy,
                        size: 80,
                        color: _kForestGreen, // colour placeholder (forest green)
                      ),
                      crossFadeState: isReady
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 600),
                    ),

                    const SizedBox(height: 24),

                    // ── Loading text ───────────────────────────────────────
                    AnimatedOpacity(
                      opacity: isLoading ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: const Text(
                        'Loading language model...',
                        style: TextStyle(
                          color: Color(0xFFB0B0B0),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
