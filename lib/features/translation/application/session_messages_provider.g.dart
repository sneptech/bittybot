// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_messages_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Reactive stream of messages for a given translation session.
///
/// Used by TranslationScreen to display the bubble list. Auto-updates
/// when new messages are inserted during translation streaming.
///
/// Pass the [sessionId] from [TranslationState.activeSession.id].
///
/// Example:
/// ```dart
/// final sessionId = ref.watch(
///   translationNotifierProvider.select((s) => s.activeSession?.id),
/// );
/// if (sessionId != null) {
///   final messages = ref.watch(sessionMessagesProvider(sessionId));
/// }
/// ```

@ProviderFor(sessionMessages)
final sessionMessagesProvider = SessionMessagesFamily._();

/// Reactive stream of messages for a given translation session.
///
/// Used by TranslationScreen to display the bubble list. Auto-updates
/// when new messages are inserted during translation streaming.
///
/// Pass the [sessionId] from [TranslationState.activeSession.id].
///
/// Example:
/// ```dart
/// final sessionId = ref.watch(
///   translationNotifierProvider.select((s) => s.activeSession?.id),
/// );
/// if (sessionId != null) {
///   final messages = ref.watch(sessionMessagesProvider(sessionId));
/// }
/// ```

final class SessionMessagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ChatMessage>>,
          List<ChatMessage>,
          Stream<List<ChatMessage>>
        >
    with
        $FutureModifier<List<ChatMessage>>,
        $StreamProvider<List<ChatMessage>> {
  /// Reactive stream of messages for a given translation session.
  ///
  /// Used by TranslationScreen to display the bubble list. Auto-updates
  /// when new messages are inserted during translation streaming.
  ///
  /// Pass the [sessionId] from [TranslationState.activeSession.id].
  ///
  /// Example:
  /// ```dart
  /// final sessionId = ref.watch(
  ///   translationNotifierProvider.select((s) => s.activeSession?.id),
  /// );
  /// if (sessionId != null) {
  ///   final messages = ref.watch(sessionMessagesProvider(sessionId));
  /// }
  /// ```
  SessionMessagesProvider._({
    required SessionMessagesFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'sessionMessagesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sessionMessagesHash();

  @override
  String toString() {
    return r'sessionMessagesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<ChatMessage>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ChatMessage>> create(Ref ref) {
    final argument = this.argument as int;
    return sessionMessages(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SessionMessagesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sessionMessagesHash() => r'45b67dd367b86ca206428ae14b453e4b14a9cb75';

/// Reactive stream of messages for a given translation session.
///
/// Used by TranslationScreen to display the bubble list. Auto-updates
/// when new messages are inserted during translation streaming.
///
/// Pass the [sessionId] from [TranslationState.activeSession.id].
///
/// Example:
/// ```dart
/// final sessionId = ref.watch(
///   translationNotifierProvider.select((s) => s.activeSession?.id),
/// );
/// if (sessionId != null) {
///   final messages = ref.watch(sessionMessagesProvider(sessionId));
/// }
/// ```

final class SessionMessagesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<ChatMessage>>, int> {
  SessionMessagesFamily._()
    : super(
        retry: null,
        name: r'sessionMessagesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Reactive stream of messages for a given translation session.
  ///
  /// Used by TranslationScreen to display the bubble list. Auto-updates
  /// when new messages are inserted during translation streaming.
  ///
  /// Pass the [sessionId] from [TranslationState.activeSession.id].
  ///
  /// Example:
  /// ```dart
  /// final sessionId = ref.watch(
  ///   translationNotifierProvider.select((s) => s.activeSession?.id),
  /// );
  /// if (sessionId != null) {
  ///   final messages = ref.watch(sessionMessagesProvider(sessionId));
  /// }
  /// ```

  SessionMessagesProvider call(int sessionId) =>
      SessionMessagesProvider._(argument: sessionId, from: this);

  @override
  String toString() => r'sessionMessagesProvider';
}
