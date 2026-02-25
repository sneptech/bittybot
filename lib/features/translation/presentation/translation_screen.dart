import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../application/translation_notifier.dart';
import 'widgets/translation_bubble_list.dart';
import 'widgets/translation_input_bar.dart';

/// Translation screen — the primary user-facing screen where translation happens.
///
/// Scaffold layout:
/// - [AppBar]: target language button (placeholder for Plan 03 picker) + new
///   session [IconButton].
/// - Context-full banner: shown when [TranslationState.isContextFull] is true.
/// - [TranslationBubbleList]: expanded, fills available space.
/// - [TranslationInputBar]: multi-line expandable input with send/stop.
///
/// Keyboard avoidance: [Scaffold.resizeToAvoidBottomInset] defaults to true.
/// The input bar is wrapped in [SafeArea] (bottom: true) inside [TranslationInputBar].
///
/// RTL-ready: all padding uses [EdgeInsetsDirectional].
class TranslationScreen extends ConsumerWidget {
  const TranslationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(translationProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        // Target language button — placeholder for Plan 03 language picker.
        title: TextButton.icon(
          onPressed: null, // Plan 03 will wire this to open the language picker.
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.onSurfaceVariant,
          ),
          label: Text(
            state.targetLanguage,
            style: textTheme.titleMedium?.copyWith(
              color: AppColors.onSurface,
            ),
          ),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
          ),
        ),
        actions: [
          // New session button.
          IconButton(
            onPressed: state.isTranslating
                ? null
                : () => ref
                    .read(translationProvider.notifier)
                    .startNewSession(),
            icon: const Icon(Icons.note_add_outlined),
            tooltip: l10n.newSession,
            color: state.isTranslating
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
                  .read(translationProvider.notifier)
                  .startNewSession(),
              l10n: l10n,
            ),

          // Bubble list — fills available space.
          const Expanded(
            child: TranslationBubbleList(),
          ),

          // Input bar — hugs the bottom with SafeArea inside.
          const TranslationInputBar(),
        ],
      ),
    );
  }
}

/// Subtle warning banner shown when the translation context approaches
/// the model's limit (~90% of nCtx=2048 tokens).
class _ContextFullBanner extends StatelessWidget {
  const _ContextFullBanner({
    required this.onNewSession,
    required this.l10n,
  });

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
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
