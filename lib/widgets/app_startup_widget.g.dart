// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_startup_widget.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Eagerly initialises all async startup dependencies.
///
/// Currently awaits [settingsProvider] (locale and error tone).
/// Phase 4 will extend this to also await model readiness:
///   await ref.watch(modelReadyProvider.future);
///
/// [keepAlive: true] prevents disposal when no widget is watching —
/// the startup future should run exactly once per app session.

@ProviderFor(appStartup)
final appStartupProvider = AppStartupProvider._();

/// Eagerly initialises all async startup dependencies.
///
/// Currently awaits [settingsProvider] (locale and error tone).
/// Phase 4 will extend this to also await model readiness:
///   await ref.watch(modelReadyProvider.future);
///
/// [keepAlive: true] prevents disposal when no widget is watching —
/// the startup future should run exactly once per app session.

final class AppStartupProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Eagerly initialises all async startup dependencies.
  ///
  /// Currently awaits [settingsProvider] (locale and error tone).
  /// Phase 4 will extend this to also await model readiness:
  ///   await ref.watch(modelReadyProvider.future);
  ///
  /// [keepAlive: true] prevents disposal when no widget is watching —
  /// the startup future should run exactly once per app session.
  AppStartupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appStartupProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appStartupHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return appStartup(ref);
  }
}

String _$appStartupHash() => r'd9acbf35cc9632c0bd10bb1a71b37b3a9f62b97b';
