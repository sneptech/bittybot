import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/web_fetch_provider.dart';
import '../../application/chat_notifier.dart';
import '../../data/web_fetch_service.dart';
import 'web_mode_indicator.dart';

/// Multi-line expandable input bar for the Chat screen.
///
/// Features:
/// - [TextField] with minLines: 1, maxLines: 6 — grows as user types.
/// - [TextInputAction.newline] — Enter inserts newline; send is button-only.
/// - Soft character limit: counter shown at 400+, error colour at 500+.
/// - Send/Stop toggle with [AnimatedSwitcher] for smooth icon transition.
/// - Send disabled when input is empty or model not ready.
/// - Stop button calls [ChatNotifier.stopGeneration] during streaming.
///
/// RTL-ready: layout uses [EdgeInsetsDirectional] and [Row] cross-axis
/// alignment to bottom for multi-line behaviour.
class ChatInputBar extends ConsumerStatefulWidget {
  const ChatInputBar({super.key});

  @override
  ConsumerState<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends ConsumerState<ChatInputBar> {
  final TextEditingController _textController = TextEditingController();
  bool _isWebMode = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _onSend(ChatState state) async {
    final text = _textController.text.trim();
    if (text.isEmpty || !state.isModelReady) return;
    _textController.clear();
    if (_isWebMode) {
      await _handleWebFetch(text);
      return;
    }
    await ref.read(chatProvider.notifier).sendMessage(text);
  }

  void _onStop() {
    ref.read(chatProvider.notifier).stopGeneration();
  }

  Future<void> _handleWebFetch(String url) async {
    final l10n = AppLocalizations.of(context);
    final connectivityResults = await Connectivity().checkConnectivity();
    final hasConnectivity = connectivityResults.any(
      (result) => result != ConnectivityResult.none,
    );

    if (!hasConnectivity) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noInternetConnection)),
      );
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.fetchingPage),
          duration: const Duration(seconds: 1),
        ),
      );
    }

    try {
      final webFetchService = ref.read(webFetchServiceProvider);
      final content = await webFetchService.fetchAndExtract(url);
      final notifier = ref.read(chatProvider.notifier);
      await notifier.sendMessage(
        '[Web: $url]\n\n${l10n.webSearchPrompt}\n\n$content',
      );
    } on WebFetchException catch (error) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final message = switch (error.kind) {
        WebFetchErrorKind.invalidUrl => l10n.webErrorInvalidUrl,
        WebFetchErrorKind.httpError => l10n.webErrorHttpStatus(
          error.statusCode ?? 0,
        ),
        WebFetchErrorKind.emptyContent => l10n.webErrorEmptyContent,
        WebFetchErrorKind.networkError => l10n.webErrorNetwork,
        WebFetchErrorKind.timeout => l10n.webErrorTimeout,
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(chatProvider);
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      bottom: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isWebMode) ...[
              const WebModeIndicator(),
              const SizedBox(height: 8),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: state.isGenerating
                      ? null
                      : () => setState(() => _isWebMode = !_isWebMode),
                  icon: Icon(
                    _isWebMode
                        ? Icons.language
                        : Icons.chat_bubble_outline,
                  ),
                  color: _isWebMode
                      ? AppColors.secondary
                      : AppColors.onSurfaceVariant,
                  tooltip: _isWebMode
                      ? l10n.switchToChat
                      : l10n.switchToWebSearch,
                ),
                Expanded(
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _textController,
                    builder: (context, value, _) {
                      return TextField(
                        controller: _textController,
                        minLines: 1,
                        maxLines: 6,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        enabled: state.isModelReady,
                        decoration: InputDecoration(
                          hintText: _isWebMode
                              ? l10n.webSearchInputHint
                              : l10n.chatInputHint,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Send/Stop toggle button.
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _textController,
                  builder: (context, value, _) {
                    final isEmpty = value.text.trim().isEmpty;
                    final canSend = !isEmpty && state.isModelReady;

                    if (state.isGenerating) {
                      return IconButton(
                        onPressed: _onStop,
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                            Icons.stop_circle,
                            key: ValueKey('stop'),
                          ),
                        ),
                        color: AppColors.secondary,
                        tooltip: l10n.stopTooltip,
                      );
                    }

                    return IconButton(
                      onPressed: canSend ? () => _onSend(state) : null,
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                          Icons.send,
                          key: ValueKey('send'),
                        ),
                      ),
                      color: canSend
                          ? AppColors.secondary
                          : AppColors.onSurfaceVariant,
                      tooltip: l10n.sendTooltip,
                    );
                  },
                ),
              ],
            ),
            // Soft character limit counter.
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _textController,
              builder: (context, value, _) {
                final length = value.text.length;
                if (length <= 400) return const SizedBox.shrink();

                final isOverLimit = length > 500;
                final counterText = isOverLimit
                    ? l10n.characterLimitWarning
                    : l10n.characterCount(length, 500);
                return Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(4, 2, 4, 0),
                  child: Text(
                    counterText,
                    style: textTheme.bodySmall?.copyWith(
                      color: isOverLimit
                          ? AppColors.error
                          : AppColors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.end,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
