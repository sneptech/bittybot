import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../application/translation_notifier.dart';

/// Multi-line expandable input bar for the Translation screen.
///
/// Features:
/// - [TextField] with minLines: 1, maxLines: 6 — grows as user types.
/// - [TextInputAction.newline] — Enter inserts newline; send is button-only.
/// - Soft character limit: counter shown at 400+, error colour at 500+.
/// - Send/Stop toggle with [AnimatedSwitcher] for smooth icon transition.
/// - Send disabled when input is empty or model not ready.
/// - Stop button calls [TranslationNotifier.stopTranslation] during streaming.
///
/// RTL-ready: layout uses [EdgeInsetsDirectional] and [Row] cross-axis
/// alignment to bottom for multi-line behaviour.
class TranslationInputBar extends ConsumerStatefulWidget {
  const TranslationInputBar({super.key});

  @override
  ConsumerState<TranslationInputBar> createState() =>
      _TranslationInputBarState();
}

class _TranslationInputBarState extends ConsumerState<TranslationInputBar> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onSend(TranslationState state) {
    final text = _textController.text.trim();
    if (text.isEmpty || !state.isModelReady) return;
    _textController.clear();
    ref.read(translationProvider.notifier).translate(text);
  }

  void _onStop() {
    ref.read(translationProvider.notifier).stopTranslation();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(translationProvider);
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      bottom: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
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
                          hintText: l10n.translationInputHint,
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

                    if (state.isTranslating) {
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
                        tooltip: 'Stop',
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
                      tooltip: 'Send',
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
                    : '$length / 500';
                return Padding(
                  padding:
                      const EdgeInsetsDirectional.fromSTEB(4, 2, 4, 0),
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
