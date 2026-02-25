import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/settings/application/settings_provider.dart';
import 'model_loading_screen.dart';
import 'app_startup_error_screen.dart';

part 'app_startup_widget.g.dart';

/// Eagerly initialises all async startup dependencies.
///
/// Awaits [settingsProvider] (locale and error tone) only.
///
/// **Design decision — model loads independently:**
/// The model ([modelReadyProvider]) is NOT awaited here. On subsequent
/// launches, users can browse chat history and settings while the model
/// loads in the background. Only the input field is disabled until
/// [modelReadyProvider] resolves (partial-access pattern). On first
/// launch, the DownloadScreen gates everything before this widget is shown.
///
/// [keepAlive: true] prevents disposal when no widget is watching —
/// the startup future should run exactly once per app session.
@Riverpod(keepAlive: true)
Future<void> appStartup(Ref ref) async {
  await ref.watch(settingsProvider.future);
}

/// Async gate that shows loading / error / main UI based on startup state.
///
/// Usage:
/// ```dart
/// AppStartupWidget(onLoaded: (_) => const MainShell())
/// ```
///
/// The [onLoaded] callback receives the [BuildContext] and returns the widget
/// to display when all startup dependencies are ready.
class AppStartupWidget extends ConsumerWidget {
  const AppStartupWidget({required this.onLoaded, super.key});

  /// Called with the current [BuildContext] once startup completes.
  /// Return the widget that should become the main UI.
  final Widget Function(BuildContext context) onLoaded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startupState = ref.watch(appStartupProvider);

    return startupState.when(
      loading: () => const ModelLoadingScreen(),
      error: (error, stackTrace) => AppStartupErrorScreen(
        onRetry: () => ref.invalidate(appStartupProvider),
      ),
      data: (_) => onLoaded(context),
    );
  }
}
