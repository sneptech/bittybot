import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../application/session_messages_provider.dart';
import '../../application/translation_notifier.dart';
import '../../../chat/domain/chat_message.dart';
import 'typing_indicator.dart';

/// Chat-style bubble list for the Translation screen.
///
/// Message sourcing:
/// - Persisted messages come from [sessionMessagesProvider] (reactive Drift stream).
/// - The in-progress streaming message is shown from [TranslationState.translatedText]
///   with word-level batching during streaming.
///
/// Word-level batching:
/// - Space-delimited scripts (Latin, Arabic, Cyrillic, etc.): display up to the
///   last complete word boundary during streaming; full text when done.
/// - Non-space-delimited scripts (CJK, Japanese kana, Thai, etc.): display
///   token-by-token (full accumulated text).
///
/// Auto-scroll fires after each state update via [addPostFrameCallback],
/// but only if the user is already near the bottom (within 100 pixels).
///
/// RTL-ready: all padding uses [EdgeInsetsDirectional].
class TranslationBubbleList extends ConsumerStatefulWidget {
  const TranslationBubbleList({super.key});

  @override
  ConsumerState<TranslationBubbleList> createState() =>
      _TranslationBubbleListState();
}

class _TranslationBubbleListState extends ConsumerState<TranslationBubbleList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      final current = _scrollController.offset;
      // Only auto-scroll if user is within 100px of the bottom.
      if (max - current <= 100) {
        _scrollController.animateTo(
          max,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Returns true if [text] contains characters from non-space-delimited scripts.
  bool _isSpaceDelimited(String text) {
    // CJK Unified Ideographs
    if (text.contains(RegExp(r'[\u4E00-\u9FFF]'))) return false;
    // Japanese hiragana + katakana
    if (text.contains(RegExp(r'[\u3040-\u30FF]'))) return false;
    // Thai
    if (text.contains(RegExp(r'[\u0E00-\u0E7F]'))) return false;
    // Lao
    if (text.contains(RegExp(r'[\u0E80-\u0EFF]'))) return false;
    // Khmer
    if (text.contains(RegExp(r'[\u1780-\u17FF]'))) return false;
    // Burmese/Myanmar
    if (text.contains(RegExp(r'[\u1000-\u109F]'))) return false;
    return true;
  }

  /// Returns the text to show in the streaming bubble.
  ///
  /// For space-delimited scripts: trim to last complete word during streaming.
  /// For CJK/Thai/etc.: show full accumulated text.
  String _streamingDisplayText(String text, bool isTranslating) {
    if (!isTranslating) return text;
    if (!_isSpaceDelimited(text)) return text;

    // Find the last whitespace boundary.
    final lastSpace = text.lastIndexOf(RegExp(r'\s'));
    if (lastSpace <= 0) return text; // no complete word yet — show as-is
    return text.substring(0, lastSpace + 1);
  }

  Widget _buildUserBubble(String content) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.80,
        ),
        margin: const EdgeInsetsDirectional.fromSTEB(48, 4, 12, 4),
        padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 10),
        decoration: const BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(
          content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurface,
              ),
        ),
      ),
    );
  }

  Widget _buildAssistantBubble(String content, String targetLanguage) {
    final textTheme = Theme.of(context).textTheme;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.80,
        ),
        margin: const EdgeInsetsDirectional.fromSTEB(12, 4, 48, 4),
        padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 10),
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              content,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              targetLanguage,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(translationProvider);

    final sessionId = state.activeSession?.id;

    // Watch persisted messages if a session exists.
    final messagesAsync = sessionId != null
        ? ref.watch(sessionMessagesProvider(sessionId))
        : null;

    final dbMessages = messagesAsync?.value ?? const <ChatMessage>[];

    final isTranslating = state.isTranslating;
    final streamingText = state.translatedText;
    final showTypingIndicator = isTranslating && streamingText.isEmpty;
    final showStreamingBubble = isTranslating && streamingText.isNotEmpty;
    final displayStreamingText =
        _streamingDisplayText(streamingText, isTranslating);

    // Trigger auto-scroll when content changes.
    if (dbMessages.isNotEmpty || showStreamingBubble || showTypingIndicator) {
      _scrollToBottom();
    }

    // Empty state.
    if (dbMessages.isEmpty && !isTranslating) {
      return Center(
        child: Text(
          l10n.translationEmptyState,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Build item list: DB messages + typing indicator + streaming bubble.
    final int typingIndex = dbMessages.length;
    final int streamingIndex = typingIndex + (showTypingIndicator ? 1 : 0);
    final int itemCount =
        dbMessages.length +
        (showTypingIndicator ? 1 : 0) +
        (showStreamingBubble ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsetsDirectional.fromSTEB(0, 8, 0, 8),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // DB message bubble.
        if (index < dbMessages.length) {
          final msg = dbMessages[index];
          if (msg.role == 'user') {
            return _buildUserBubble(msg.content);
          } else {
            return _buildAssistantBubble(
              msg.content,
              state.targetLanguage,
            );
          }
        }

        // Typing indicator.
        if (index == typingIndex && showTypingIndicator) {
          return TypingIndicator(isVisible: showTypingIndicator);
        }

        // Streaming assistant bubble.
        if (index == streamingIndex && showStreamingBubble) {
          return _buildAssistantBubble(
            displayStreamingText,
            state.targetLanguage,
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
