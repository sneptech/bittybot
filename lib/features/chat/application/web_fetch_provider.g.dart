// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'web_fetch_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the stateless [WebFetchService] used by chat web-search mode.

@ProviderFor(webFetchService)
final webFetchServiceProvider = WebFetchServiceProvider._();

/// Provides the stateless [WebFetchService] used by chat web-search mode.

final class WebFetchServiceProvider
    extends
        $FunctionalProvider<WebFetchService, WebFetchService, WebFetchService>
    with $Provider<WebFetchService> {
  /// Provides the stateless [WebFetchService] used by chat web-search mode.
  WebFetchServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'webFetchServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$webFetchServiceHash();

  @$internal
  @override
  $ProviderElement<WebFetchService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WebFetchService create(Ref ref) {
    return webFetchService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WebFetchService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WebFetchService>(value),
    );
  }
}

String _$webFetchServiceHash() => r'07dc9b4dbb95370ea7be4cc0d6a3c4395a21fd49';
