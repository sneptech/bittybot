import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'model_distribution_notifier.dart';
import 'model_distribution_state.dart';

/// Provider for the model distribution lifecycle notifier.
///
/// Watches [ModelDistributionNotifier] and exposes [ModelDistributionState].
///
/// Usage:
/// ```dart
/// // In a ConsumerWidget:
/// final modelState = ref.watch(modelDistributionProvider);
/// final notifier = ref.read(modelDistributionProvider.notifier);
/// await notifier.initialize(); // called once on app start
/// ```
///
/// Note: This uses manual provider declaration (not riverpod_generator codegen).
/// Migration to @riverpod annotation is possible when build_runner is added.
final modelDistributionProvider =
    NotifierProvider<ModelDistributionNotifier, ModelDistributionState>(
  ModelDistributionNotifier.new,
);
