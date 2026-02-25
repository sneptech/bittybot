import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/model_distribution/model_distribution_state.dart';
import '../features/model_distribution/providers.dart';
import '../features/model_distribution/widgets/download_screen.dart';
import 'app_startup_widget.dart';
import 'main_shell.dart';

/// Gates the app on model availability.
///
/// First launch: shows [DownloadScreen] until the model is downloaded,
/// verified, and ready. Subsequent launches: model is already on disk,
/// so [AppStartupWidget] is shown immediately.
///
/// Calls [ModelDistributionNotifier.initialize()] exactly once on first build
/// via a post-frame callback.
class ModelGateWidget extends ConsumerStatefulWidget {
  const ModelGateWidget({super.key});

  @override
  ConsumerState<ModelGateWidget> createState() => _ModelGateWidgetState();
}

class _ModelGateWidgetState extends ConsumerState<ModelGateWidget> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Call initialize() once after the first frame so the widget tree is built
    // before state transitions start firing.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialized) {
        _initialized = true;
        ref.read(modelDistributionProvider.notifier).initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final modelState = ref.watch(modelDistributionProvider);

    // Once the model is on disk and loading/loaded into the inference runtime,
    // hand off to AppStartupWidget which gates on settings and shows MainShell.
    //
    // All other states (checking, preflight, downloading, verifying, errors,
    // low-memory warning, etc.) are handled by DownloadScreen which has an
    // exhaustive switch over ModelDistributionState.
    return switch (modelState) {
      LoadingModelState() || ModelReadyState() =>
        AppStartupWidget(onLoaded: (_) => const MainShell()),
      _ => const DownloadScreen(),
    };
  }
}
