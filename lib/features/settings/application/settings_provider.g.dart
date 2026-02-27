// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod AsyncNotifier that persists locale override and error tone
/// via [SharedPreferencesWithCache].
///
/// Kept alive so settings are never disposed while the app is running,
/// even when no widgets are actively listening.
///
/// Usage:
/// ```dart
/// // Read settings
/// final settings = await ref.watch(settingsProvider.future);
///
/// // Mutations (call from notifier or gesture handlers)
/// ref.read(settingsProvider.notifier).setLocale(Locale('ar'));
/// ref.read(settingsProvider.notifier).setErrorTone(ErrorTone.direct);
/// ```

@ProviderFor(Settings)
final settingsProvider = SettingsProvider._();

/// Riverpod AsyncNotifier that persists locale override and error tone
/// via [SharedPreferencesWithCache].
///
/// Kept alive so settings are never disposed while the app is running,
/// even when no widgets are actively listening.
///
/// Usage:
/// ```dart
/// // Read settings
/// final settings = await ref.watch(settingsProvider.future);
///
/// // Mutations (call from notifier or gesture handlers)
/// ref.read(settingsProvider.notifier).setLocale(Locale('ar'));
/// ref.read(settingsProvider.notifier).setErrorTone(ErrorTone.direct);
/// ```
final class SettingsProvider
    extends $AsyncNotifierProvider<Settings, AppSettings> {
  /// Riverpod AsyncNotifier that persists locale override and error tone
  /// via [SharedPreferencesWithCache].
  ///
  /// Kept alive so settings are never disposed while the app is running,
  /// even when no widgets are actively listening.
  ///
  /// Usage:
  /// ```dart
  /// // Read settings
  /// final settings = await ref.watch(settingsProvider.future);
  ///
  /// // Mutations (call from notifier or gesture handlers)
  /// ref.read(settingsProvider.notifier).setLocale(Locale('ar'));
  /// ref.read(settingsProvider.notifier).setErrorTone(ErrorTone.direct);
  /// ```
  SettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsHash();

  @$internal
  @override
  Settings create() => Settings();
}

String _$settingsHash() => r'e587ce225fd46ebb94d52ec99ae3a5b8f3b2510b';

/// Riverpod AsyncNotifier that persists locale override and error tone
/// via [SharedPreferencesWithCache].
///
/// Kept alive so settings are never disposed while the app is running,
/// even when no widgets are actively listening.
///
/// Usage:
/// ```dart
/// // Read settings
/// final settings = await ref.watch(settingsProvider.future);
///
/// // Mutations (call from notifier or gesture handlers)
/// ref.read(settingsProvider.notifier).setLocale(Locale('ar'));
/// ref.read(settingsProvider.notifier).setErrorTone(ErrorTone.direct);
/// ```

abstract class _$Settings extends $AsyncNotifier<AppSettings> {
  FutureOr<AppSettings> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AppSettings>, AppSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AppSettings>, AppSettings>,
              AsyncValue<AppSettings>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
