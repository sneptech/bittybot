import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../translation/presentation/widgets/typing_indicator.dart';
import '../../application/chat_notifier.dart';
import '../../application/chat_session_messages_provider.dart';

/// Chat-style bubble list for the Chat screen.
///
/// Message sourcing:
/// - Persisted messages come from [chatSessionMessagesProvider] (reactive Drift
///   stream).
/// - The in-progress streaming message is shown from
///   [ChatState.currentResponse] with word-level batching during streaming.
///
/// Word-level batching:
/// - Space-delimited scripts (Latin, Arabic, Cyrillic, etc.): display up to
///   the last complete word boundary during streaming; full text when done.
/// - Non-space-delimited scripts (CJK, Japanese kana, Thai, etc.): display
///   token-by-token (full accumulated text).
///
/// Auto-scroll fires after each state update via [addPostFrameCallback], but
/// only if the user is already near the bottom (within 100 pixels).
///
/// RTL-ready: all padding uses [EdgeInsetsDirectional].
class ChatBubbleList extends ConsumerStatefulWidget {
  const ChatBubbleList({super.key});

  @override
  ConsumerState<ChatBubbleList> createState() => _ChatBubbleListState();
}

class _ChatBubbleListState extends ConsumerState<ChatBubbleList> {
  final ScrollController _scrollController = ScrollController();
  static final _cjkPattern = RegExp(r'[\u4E00-\u9FFF]');
  static final _japanesePattern = RegExp(r'[\u3040-\u30FF]');
  static final _thaiPattern = RegExp(r'[\u0E00-\u0E7F]');
  static final _laoPattern = RegExp(r'[\u0E80-\u0EFF]');
  static final _khmerPattern = RegExp(r'[\u1780-\u17FF]');
  static final _myanmarPattern = RegExp(r'[\u1000-\u109F]');

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

  /// Returns true if [text] contains characters from non-space-delimited
  /// scripts.
  bool _isSpaceDelimited(String text) {
    // CJK Unified Ideographs
    if (text.contains(_cjkPattern)) return false;
    // Japanese hiragana + katakana
    if (text.contains(_japanesePattern)) return false;
    // Thai
    if (text.contains(_thaiPattern)) return false;
    // Lao
    if (text.contains(_laoPattern)) return false;
    // Khmer
    if (text.contains(_khmerPattern)) return false;
    // Burmese/Myanmar
    if (text.contains(_myanmarPattern)) return false;
    return true;
  }

  /// Returns the text to show in the streaming bubble.
  ///
  /// For space-delimited scripts: trim to last complete word during streaming.
  /// For CJK/Thai/etc.: show full accumulated text.
  String _streamingDisplayText(String text, bool isGenerating) {
    if (!isGenerating) return text;
    if (!_isSpaceDelimited(text)) return text;

    // Find the last whitespace boundary.
    final lastSpace = text.lastIndexOf(RegExp(r'\s'));
    if (lastSpace <= 0) return text; // no complete word yet — show as-is
    return text.substring(0, lastSpace + 1);
  }

  /// Shows a bottom sheet context menu for [content] with a copy action.
  ///
  /// Writes [content] to the clipboard via [Clipboard.setData] and shows a
  /// brief "Copied" [SnackBar] on success.
  void _showBubbleMenu(BuildContext context, String content) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy, color: AppColors.onSurface),
              title: Text(
                l10n.copyMessage,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurface,
                    ),
              ),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: content));
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.copied),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserBubble(String content) {
    return GestureDetector(
      onLongPress: () => _showBubbleMenu(context, content),
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.80,
          ),
          margin: const EdgeInsetsDirectional.fromSTEB(48, 4, 12, 4),
          padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 10),
          decoration: const BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadiusDirectional.only(
              topStart: Radius.circular(16),
              topEnd: Radius.circular(16),
              bottomStart: Radius.circular(16),
              bottomEnd: Radius.circular(4),
            ),
          ),
          child: Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurface,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssistantBubble(String content, {bool allowCopy = true}) {
    final bubble = Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.80,
        ),
        margin: const EdgeInsetsDirectional.fromSTEB(12, 4, 48, 4),
        padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 10),
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadiusDirectional.only(
            topStart: Radius.circular(16),
            topEnd: Radius.circular(16),
            bottomStart: Radius.circular(4),
            bottomEnd: Radius.circular(16),
          ),
        ),
        child: MarkdownBody(
          data: content,
          styleSheet: MarkdownStyleSheet(
            p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurface,
                ),
            strong: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
            listBullet: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurface,
                ),
          ),
          onTapLink: (_, _, _) {},
          selectable: false,
        ),
      ),
    );

    if (!allowCopy) return bubble;

    return GestureDetector(
      onLongPress: () => _showBubbleMenu(context, content),
      child: bubble,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(chatProvider);

    final sessionId = state.activeSession?.id;

    // Watch persisted messages if a session exists.
    final messagesAsync = sessionId != null
        ? ref.watch(chatSessionMessagesProvider(sessionId))
        : null;

    final dbMessages = messagesAsync?.value ?? state.messages;

    final isGenerating = state.isGenerating;
    final streamingText = state.currentResponse;
    final showTypingIndicator = isGenerating && streamingText.isEmpty;
    final showStreamingBubble = isGenerating && streamingText.isNotEmpty;
    final displayStreamingText =
        _streamingDisplayText(streamingText, isGenerating);

    // Trigger auto-scroll when content changes.
    if (dbMessages.isNotEmpty || showStreamingBubble || showTypingIndicator) {
      _scrollToBottom();
    }

    // Empty state.
    if (dbMessages.isEmpty && !isGenerating) {
      return Center(
        child: Text(
          l10n.chatEmptyState,
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
            return KeyedSubtree(
              key: ValueKey('msg-${msg.id}'),
              child: _buildUserBubble(msg.content),
            );
          }
          return KeyedSubtree(
            key: ValueKey('msg-${msg.id}'),
            child: _buildAssistantBubble(msg.content),
          );
        }

        // Typing indicator.
        if (index == typingIndex && showTypingIndicator) {
          return TypingIndicator(isVisible: showTypingIndicator);
        }

        // Streaming assistant bubble — copy disabled during active streaming.
        if (index == streamingIndex && showStreamingBubble) {
          return _buildAssistantBubble(
            displayStreamingText,
            allowCopy: false,
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
