import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../widgets/context_full_banner.dart';
import '../application/translation_notifier.dart';
import '../domain/supported_language.dart';
import 'widgets/language_picker_sheet.dart';
import 'widgets/translation_bubble_list.dart';
import 'widgets/translation_input_bar.dart';

/// Translation screen — the primary user-facing screen where translation happens.
///
/// Scaffold layout:
/// - [AppBar]: target language button (opens language picker sheet) + new
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

  /// Opens the [LanguagePickerSheet] as a [DraggableScrollableSheet].
  ///
  /// On language selection: closes the picker and calls
  /// [TranslationNotifier.setTargetLanguage] with the English language name.
  void _showLanguagePicker(BuildContext context, WidgetRef ref, String currentLanguage) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => LanguagePickerSheet(
          scrollController: scrollController,
          currentLanguage: currentLanguage,
          onLanguageSelected: (SupportedLanguage lang) {
            Navigator.pop(context);
            ref
                .read(translationProvider.notifier)
                .setTargetLanguage(lang.englishName);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(translationProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        // Target language button — opens language picker sheet.
        title: TextButton.icon(
          onPressed: () =>
              _showLanguagePicker(context, ref, state.targetLanguage),
          icon: Text(
            state.targetLanguage,
            style: textTheme.titleMedium?.copyWith(
              color: AppColors.onSurface,
            ),
          ),
          label: const Icon(
            Icons.arrow_drop_down,
            size: 20,
            color: AppColors.onSurfaceVariant,
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
            ContextFullBanner(
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
