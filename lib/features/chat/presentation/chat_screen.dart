import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../application/chat_notifier.dart';
import 'widgets/chat_bubble_list.dart';
import 'widgets/chat_history_drawer.dart';
import 'widgets/chat_input_bar.dart';

/// Chat screen — the primary user-facing screen where multi-turn chat happens.
///
/// Scaffold layout:
/// - [AppBar]: title + new session [IconButton].
/// - Context-full banner: shown when [ChatState.isContextFull] is true.
/// - [ChatBubbleList]: expanded, fills available space.
/// - [ChatInputBar]: multi-line expandable input with send/stop.
///
/// Keyboard avoidance: [Scaffold.resizeToAvoidBottomInset] defaults to true.
/// The input bar is wrapped in [SafeArea] (bottom: true) inside [ChatInputBar].
///
/// RTL-ready: all padding uses [EdgeInsetsDirectional].
class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(chatProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      drawer: const ChatHistoryDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu),
            color: AppColors.onSurface,
          ),
        ),
        title: Text(
          l10n.chat,
          style: textTheme.titleMedium?.copyWith(color: AppColors.onSurface),
        ),
        actions: [
          IconButton(
            onPressed: state.isGenerating
                ? null
                : () => ref.read(chatProvider.notifier).startNewSession(),
            icon: const Icon(Icons.note_add_outlined),
            tooltip: l10n.newSession,
            color: state.isGenerating
                ? AppColors.onSurfaceVariant
                : AppColors.onSurface,
          ),
        ],
      ),
      body: Column(
        children: [
          // Context-full banner.
          if (state.isContextFull)
            _ContextFullBanner(
              onNewSession: () => ref
                  .read(chatProvider.notifier)
                  .startNewSessionWithCarryForward(),
              l10n: l10n,
            ),

          // Bubble list — fills available space.
          const Expanded(child: ChatBubbleList()),

          // Input bar — hugs the bottom with SafeArea inside.
          const ChatInputBar(),
        ],
      ),
    );
  }
}

/// Subtle warning banner shown when the chat context approaches
/// the model's limit (~90% of nCtx=2048 tokens).
class _ContextFullBanner extends StatelessWidget {
  const _ContextFullBanner({required this.onNewSession, required this.l10n});

  final VoidCallback onNewSession;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      color: AppColors.secondaryContainer,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.contextFullBanner,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.onSecondaryContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: onNewSession,
            child: Text(
              l10n.newSession,
              style: textTheme.labelSmall?.copyWith(color: AppColors.secondary),
            ),
          ),
        ],
      ),
    );
  }
}
