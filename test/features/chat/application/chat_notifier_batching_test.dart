import 'dart:async';

import 'package:bittybot/features/chat/application/chat_notifier.dart';
import 'package:bittybot/features/chat/application/chat_repository_provider.dart';
import 'package:bittybot/features/chat/data/chat_repository.dart';
import 'package:bittybot/features/chat/domain/chat_message.dart';
import 'package:bittybot/features/chat/domain/chat_session.dart';
import 'package:bittybot/features/inference/application/llm_service.dart';
import 'package:bittybot/features/inference/application/llm_service_provider.dart';
import 'package:bittybot/features/inference/data/inference_repository_impl.dart';
import 'package:bittybot/features/inference/domain/inference_message.dart';
import 'package:bittybot/features/inference/domain/inference_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _FakeModelReady extends ModelReady {
  @override
  Future<LlmService> build() async {
    return LlmService(modelPath: '/tmp/fake-model.gguf');
  }
}

class _FakeInferenceRepository implements InferenceRepository {
  final StreamController<InferenceResponse> _controller =
      StreamController<InferenceResponse>.broadcast(sync: true);

  int _nextRequestId = 1;
  int? lastRequestId;

  @override
  int generate({required String prompt, required int nPredict}) {
    final requestId = _nextRequestId++;
    lastRequestId = requestId;
    return requestId;
  }

  @override
  void stop(int requestId) {}

  @override
  void clearContext() {}

  @override
  bool get isGenerating => false;

  @override
  Stream<InferenceResponse> get responseStream => _controller.stream;

  void emit(InferenceResponse response) {
    _controller.add(response);
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}

class _FakeChatRepository implements ChatRepository {
  final Map<int, ChatSession> _sessions = <int, ChatSession>{};
  final Map<int, List<ChatMessage>> _messagesBySession = <int, List<ChatMessage>>{};
  int _nextSessionId = 1;
  int _nextMessageId = 1;

  @override
  Future<ChatSession> createSession({required String mode, String? title}) async {
    final now = DateTime.now();
    final session = ChatSession(
      id: _nextSessionId++,
      title: title,
      mode: mode,
      createdAt: now,
      updatedAt: now,
    );
    _sessions[session.id] = session;
    _messagesBySession.putIfAbsent(session.id, () => <ChatMessage>[]);
    return session;
  }

  @override
  Future<ChatSession?> getSession(int id) async {
    return _sessions[id];
  }

  @override
  Future<void> updateSessionTitle(int sessionId, String title) async {
    final current = _sessions[sessionId];
    if (current == null) return;
    _sessions[sessionId] = ChatSession(
      id: current.id,
      title: title,
      mode: current.mode,
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteSession(int sessionId) async {
    _sessions.remove(sessionId);
    _messagesBySession.remove(sessionId);
  }

  @override
  Stream<List<ChatSession>> watchAllSessions() {
    return Stream<List<ChatSession>>.value(_sessions.values.toList());
  }

  @override
  Future<ChatMessage> insertMessage({
    required int sessionId,
    required String role,
    required String content,
    bool isTruncated = false,
  }) async {
    final message = ChatMessage(
      id: _nextMessageId++,
      sessionId: sessionId,
      role: role,
      content: content,
      isTruncated: isTruncated,
      createdAt: DateTime.now(),
    );
    _messagesBySession.putIfAbsent(sessionId, () => <ChatMessage>[]).add(message);
    return message;
  }

  @override
  Future<void> updateMessageContent(int messageId, String content) async {}

  @override
  Future<void> markMessageTruncated(int messageId) async {}

  @override
  Future<List<ChatMessage>> getMessagesForSession(int sessionId) async {
    return List<ChatMessage>.from(_messagesBySession[sessionId] ?? const <ChatMessage>[]);
  }

  @override
  Stream<List<ChatMessage>> watchMessagesForSession(int sessionId) {
    return Stream<List<ChatMessage>>.value(
      List<ChatMessage>.from(_messagesBySession[sessionId] ?? const <ChatMessage>[]),
    );
  }

  @override
  Future<void> deleteAllSessions() async {
    _sessions.clear();
    _messagesBySession.clear();
  }

  @override
  Future<int> deleteSessionsOlderThan(DateTime cutoff) async {
    return 0;
  }
}

void main() {
  late ProviderContainer container;
  late _FakeChatRepository chatRepository;
  late _FakeInferenceRepository inferenceRepository;
  late ProviderSubscription<ChatState> keepAlive;

  setUp(() {
    chatRepository = _FakeChatRepository();
    inferenceRepository = _FakeInferenceRepository();
    container = ProviderContainer(
      overrides: [
        chatRepositoryProvider.overrideWithValue(chatRepository),
        inferenceRepositoryProvider.overrideWithValue(inferenceRepository),
        modelReadyProvider.overrideWith(_FakeModelReady.new),
      ],
    );
    keepAlive = container.listen<ChatState>(
      chatProvider,
      (_, __) {},
      fireImmediately: true,
    );
  });

  tearDown(() async {
    keepAlive.close();
    container.dispose();
    await inferenceRepository.dispose();
  });

  group('Token batching', () {
    test('multiple rapid tokens result in fewer state updates than token count', () async {
      final notifier = container.read(chatProvider.notifier);

      var currentResponseUpdates = 0;
      final sub = container.listen<ChatState>(
        chatProvider,
        (previous, next) {
          if (previous == null) return;
          if (previous.currentResponse != next.currentResponse) {
            currentResponseUpdates++;
          }
        },
        fireImmediately: true,
      );

      await notifier.startNewSession();
      await notifier.sendMessage('hello');
      final requestId = inferenceRepository.lastRequestId!;

      for (var i = 0; i < 20; i++) {
        inferenceRepository.emit(TokenResponse(requestId: requestId, token: 'a'));
      }
      inferenceRepository.emit(DoneResponse(requestId: requestId, stopped: false));

      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(currentResponseUpdates, lessThan(20));
      sub.close();
    });

    test('buffered tokens are flushed on generation complete', () async {
      final notifier = container.read(chatProvider.notifier);
      await notifier.startNewSession();
      await notifier.sendMessage('hello');
      final requestId = inferenceRepository.lastRequestId!;

      inferenceRepository.emit(TokenResponse(requestId: requestId, token: 'A'));
      inferenceRepository.emit(TokenResponse(requestId: requestId, token: 'B'));
      inferenceRepository.emit(TokenResponse(requestId: requestId, token: 'C'));
      inferenceRepository.emit(DoneResponse(requestId: requestId, stopped: false));

      await Future<void>.delayed(const Duration(milliseconds: 120));

      final state = container.read(chatProvider);
      expect(state.messages.last.role, 'assistant');
      expect(state.messages.last.content, 'ABC');
      expect(state.currentResponse, isEmpty);
    });

    test('buffered tokens are flushed on error', () async {
      final notifier = container.read(chatProvider.notifier);
      await notifier.startNewSession();
      await notifier.sendMessage('hello');
      final requestId = inferenceRepository.lastRequestId!;

      inferenceRepository.emit(TokenResponse(requestId: requestId, token: 'X'));
      inferenceRepository.emit(TokenResponse(requestId: requestId, token: 'Y'));
      inferenceRepository.emit(
        ErrorResponse(requestId: requestId, message: 'inference failed'),
      );

      await Future<void>.delayed(const Duration(milliseconds: 120));

      final state = container.read(chatProvider);
      expect(state.messages.last.role, 'assistant');
      expect(state.messages.last.content, 'XY');
      expect(state.messages.last.isTruncated, isTrue);
      expect(state.isGenerating, isFalse);
    });
  });
}
