// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ocr_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(OcrNotifier)
final ocrProvider = OcrNotifierProvider._();

final class OcrNotifierProvider
    extends $NotifierProvider<OcrNotifier, OcrState> {
  OcrNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ocrProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ocrNotifierHash();

  @$internal
  @override
  OcrNotifier create() => OcrNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OcrState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OcrState>(value),
    );
  }
}

String _$ocrNotifierHash() => r'3aa4a4c376b9fb4b05d1ed9683011f2b03641082';

abstract class _$OcrNotifier extends $Notifier<OcrState> {
  OcrState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<OcrState, OcrState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<OcrState, OcrState>,
              OcrState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
