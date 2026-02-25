import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../data/language_data.dart';
import '../../domain/supported_language.dart';
import '../../../settings/application/settings_provider.dart';
import 'language_grid_item.dart';

/// Bottom sheet for selecting the translation target language.
///
/// Displays as a [DraggableScrollableSheet] (initial: 70%, min: 40%, max: 95%)
/// with:
/// - A drag handle bar at the top.
/// - A search field that filters by both localized and English language names.
/// - A "Recent" section (up to 3 quick-access chips) hidden during search.
/// - A "Popular" section (top 10 pinned languages) hidden during search.
/// - A full 3-column grid of all 66 supported languages, filtered by search.
///
/// Language names are resolved via [flutter_localized_locales] in the device
/// locale, falling back to [SupportedLanguage.englishName]. Country codes are
/// resolved via [resolveCountryCode] to show locale-appropriate flag variants.
///
/// The [scrollController] from [DraggableScrollableSheet.builder] is passed
/// directly to the [CustomScrollView] to avoid scroll conflicts (Pitfall 4).
///
/// [onLanguageSelected] is called with the selected language; the parent
/// is responsible for calling [Navigator.pop] and updating the notifier.
///
/// RTL-ready: all padding uses [EdgeInsetsDirectional].
class LanguagePickerSheet extends ConsumerStatefulWidget {
  const LanguagePickerSheet({
    super.key,
    required this.scrollController,
    required this.currentLanguage,
    required this.onLanguageSelected,
  });

  /// ScrollController from [DraggableScrollableSheet.builder].
  /// Must be passed to the [CustomScrollView] to avoid scroll conflicts.
  final ScrollController scrollController;

  /// The currently selected target language (English name).
  final String currentLanguage;

  /// Called when the user taps a language item.
  final ValueChanged<SupportedLanguage> onLanguageSelected;

  @override
  ConsumerState<LanguagePickerSheet> createState() =>
      _LanguagePickerSheetState();
}

class _LanguagePickerSheetState extends ConsumerState<LanguagePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  /// Localized name cache — computed once in [didChangeDependencies]
  /// to avoid recomputing on every rebuild. Maps ISO 639-1 code → display name.
  late Map<String, String> _localizedNames;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _buildLocalizedNamesCache();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  /// Builds the localized name cache from [LocaleNames.of(context)].
  ///
  /// Falls back to [SupportedLanguage.englishName] if [nameOf] returns null.
  /// Computed once per [didChangeDependencies] call (device locale change).
  void _buildLocalizedNamesCache() {
    final localeNames = LocaleNames.of(context);
    _localizedNames = {
      for (final lang in kSupportedLanguages)
        lang.code: localeNames?.nameOf(lang.code) ?? lang.englishName,
    };
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  /// Returns languages filtered by [_searchQuery].
  ///
  /// Matches against both the localized name (device locale) and the English
  /// name. Comparison is case-insensitive. Returns all languages when query
  /// is empty.
  List<SupportedLanguage> _getFilteredLanguages() {
    if (_searchQuery.isEmpty) return kSupportedLanguages;

    final query = _searchQuery.toLowerCase();
    return kSupportedLanguages.where((lang) {
      final localized = _localizedNames[lang.code] ?? lang.englishName;
      return localized.toLowerCase().contains(query) ||
          lang.englishName.toLowerCase().contains(query);
    }).toList();
  }

  /// Returns the 10 popular languages as [SupportedLanguage] instances.
  List<SupportedLanguage> _getPopularLanguages() {
    return kPopularLanguages
        .map((name) => kSupportedLanguages.firstWhere(
              (lang) => lang.englishName == name,
            ))
        .toList();
  }

  /// Resolves the country code for [lang] based on the device locale.
  String _resolveCode(SupportedLanguage lang) {
    return resolveCountryCode(lang, Localizations.localeOf(context));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    final settingsAsync = ref.watch(settingsProvider);
    final recentLanguageNames =
        settingsAsync.value?.recentTargetLanguages ?? const [];

    // Resolve recent languages to SupportedLanguage instances (skip unknowns).
    final recentLanguages = recentLanguageNames
        .map((name) {
          try {
            return kSupportedLanguages.firstWhere(
              (lang) => lang.englishName == name,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<SupportedLanguage>()
        .toList();

    final isSearching = _searchQuery.isNotEmpty;
    final filteredLanguages = _getFilteredLanguages();
    final popularLanguages = _getPopularLanguages();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          // Drag handle.
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 12, bottom: 4),
            child: Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // Search bar.
          Padding(
            padding:
                const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              autofocus: false,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.searchLanguages,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.surfaceContainer,
                contentPadding:
                    const EdgeInsetsDirectional.fromSTEB(0, 12, 16, 12),
              ),
            ),
          ),

          // Scrollable language sections.
          Expanded(
            child: CustomScrollView(
              controller: widget.scrollController,
              physics: const ClampingScrollPhysics(),
              slivers: [
                // Recent languages section (hidden during search).
                if (!isSearching && recentLanguages.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          16, 8, 16, 4),
                      child: Text(
                        l10n.recentLanguages,
                        style: textTheme.titleSmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          12, 4, 12, 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: recentLanguages.map((lang) {
                          final displayName =
                              _localizedNames[lang.code] ?? lang.englishName;
                          final countryCode = _resolveCode(lang);
                          return _RecentLanguageChip(
                            lang: lang,
                            displayName: displayName,
                            countryCode: countryCode,
                            isSelected:
                                lang.englishName == widget.currentLanguage,
                            onTap: () => widget.onLanguageSelected(lang),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],

                // Popular languages section (hidden during search).
                if (!isSearching) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          16, 8, 16, 4),
                      child: Text(
                        l10n.popularLanguages,
                        style: textTheme.titleSmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding:
                        const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 0),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final lang = popularLanguages[index];
                          final displayName =
                              _localizedNames[lang.code] ?? lang.englishName;
                          final countryCode = _resolveCode(lang);
                          return LanguageGridItem(
                            language: lang,
                            displayName: displayName,
                            countryCode: countryCode,
                            isSelected:
                                lang.englishName == widget.currentLanguage,
                            onTap: () => widget.onLanguageSelected(lang),
                          );
                        },
                        childCount: popularLanguages.length,
                      ),
                    ),
                  ),

                  // Divider between popular and all languages.
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
                      child: Divider(
                        color: AppColors.surfaceContainer,
                        thickness: 1,
                      ),
                    ),
                  ),
                ],

                // All languages section header.
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        16, 8, 16, 4),
                    child: Text(
                      isSearching
                          ? '' // No header label during search
                          : l10n.language,
                      style: textTheme.titleSmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),

                // All (filtered) languages grid.
                SliverPadding(
                  padding:
                      const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final lang = filteredLanguages[index];
                        final displayName =
                            _localizedNames[lang.code] ?? lang.englishName;
                        final countryCode = _resolveCode(lang);
                        return LanguageGridItem(
                          language: lang,
                          displayName: displayName,
                          countryCode: countryCode,
                          isSelected:
                              lang.englishName == widget.currentLanguage,
                          onTap: () => widget.onLanguageSelected(lang),
                        );
                      },
                      childCount: filteredLanguages.length,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A compact chip shown in the "Recent" section of the language picker.
///
/// Displays a small flag icon and the localized language name inside
/// a styled [ActionChip]-like container.
class _RecentLanguageChip extends StatelessWidget {
  const _RecentLanguageChip({
    required this.lang,
    required this.displayName,
    required this.countryCode,
    required this.isSelected,
    required this.onTap,
  });

  final SupportedLanguage lang;
  final String displayName;
  final String countryCode;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: isSelected
          ? AppColors.primaryContainer
          : AppColors.surfaceContainer,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 14, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CountryFlag.fromCountryCode(
                countryCode,
                theme: const ImageTheme(
                  height: 16,
                  width: 22,
                  shape: RoundedRectangle(3),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                displayName,
                style: textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? AppColors.onPrimaryContainer
                      : AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
