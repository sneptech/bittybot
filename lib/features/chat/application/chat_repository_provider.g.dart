// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the single [AppDatabase] instance for the lifetime of the app.
///
/// [keepAlive: true] ensures the database connection is never closed while
/// the app is running. [ref.onDispose] closes it on provider teardown
/// (e.g., during test cleanup).

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

/// Provides the single [AppDatabase] instance for the lifetime of the app.
///
/// [keepAlive: true] ensures the database connection is never closed while
/// the app is running. [ref.onDispose] closes it on provider teardown
/// (e.g., during test cleanup).

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// Provides the single [AppDatabase] instance for the lifetime of the app.
  ///
  /// [keepAlive: true] ensures the database connection is never closed while
  /// the app is running. [ref.onDispose] closes it on provider teardown
  /// (e.g., during test cleanup).
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'59cce38d45eeaba199eddd097d8e149d66f9f3e1';

/// Provides [ChatRepository] backed by the app's [AppDatabase].
///
/// Consumers (ChatNotifier, session drawer) depend on the abstract
/// [ChatRepository] interface — never on [DriftChatRepository] directly.
///
/// [keepAlive: true] keeps the repository alive for the full app session so
/// callers do not recreate it on each watch cycle.

@ProviderFor(chatRepository)
final chatRepositoryProvider = ChatRepositoryProvider._();

/// Provides [ChatRepository] backed by the app's [AppDatabase].
///
/// Consumers (ChatNotifier, session drawer) depend on the abstract
/// [ChatRepository] interface — never on [DriftChatRepository] directly.
///
/// [keepAlive: true] keeps the repository alive for the full app session so
/// callers do not recreate it on each watch cycle.

final class ChatRepositoryProvider
    extends $FunctionalProvider<ChatRepository, ChatRepository, ChatRepository>
    with $Provider<ChatRepository> {
  /// Provides [ChatRepository] backed by the app's [AppDatabase].
  ///
  /// Consumers (ChatNotifier, session drawer) depend on the abstract
  /// [ChatRepository] interface — never on [DriftChatRepository] directly.
  ///
  /// [keepAlive: true] keeps the repository alive for the full app session so
  /// callers do not recreate it on each watch cycle.
  ChatRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatRepositoryHash();

  @$internal
  @override
  $ProviderElement<ChatRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChatRepository create(Ref ref) {
    return chatRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatRepository>(value),
    );
  }
}

String _$chatRepositoryHash() => r'a777992c88c9b8e96982bbc933912ec7c0d509b9';
