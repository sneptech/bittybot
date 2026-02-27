// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_startup_widget.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(appStartup)
final appStartupProvider = AppStartupProvider._();

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

final class AppStartupProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
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

String _$appStartupHash() => r'496d861fd9f99441ccd7623db4888be1ff504067';
