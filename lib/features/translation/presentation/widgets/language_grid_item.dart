import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';

import '../../domain/supported_language.dart';
import '../../../../core/theme/app_colors.dart';

/// A single language entry in the language picker grid.
///
/// Renders a country flag icon above a localized language name.
/// Tapping triggers [onTap]. When [isSelected] is true, the tile is
/// highlighted with [AppColors.primaryContainer].
///
/// Layout (vertical stack within a Material [InkWell]):
/// 1. [CountryFlag.fromCountryCode] — flag SVG (32x24dp, rounded corners)
/// 2. 4dp vertical spacing
/// 3. Language name in [TextTheme.bodySmall], centered, max 2 lines
///
/// The minimum height is 72dp to satisfy Material touch-target guidelines.
/// All padding uses [EdgeInsetsDirectional] for RTL-readiness.
class LanguageGridItem extends StatelessWidget {
  const LanguageGridItem({
    super.key,
    required this.language,
    required this.displayName,
    required this.countryCode,
    required this.isSelected,
    required this.onTap,
  });

  /// The language this grid item represents.
  final SupportedLanguage language;

  /// Localized language name to display (from flutter_localized_locales,
  /// falling back to [SupportedLanguage.englishName]).
  final String displayName;

  /// Resolved ISO 3166-1 alpha-2 country code (device locale variant applied).
  final String countryCode;

  /// Whether this language is currently selected as the target language.
  final bool isSelected;

  /// Called when the user taps this language item.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: isSelected ? AppColors.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsetsDirectional.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CountryFlag.fromCountryCode(
                  countryCode,
                  theme: const ImageTheme(
                    height: 24,
                    width: 32,
                    shape: RoundedRectangle(4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayName,
                  style: textTheme.bodySmall?.copyWith(
                    color: isSelected
                        ? AppColors.onPrimaryContainer
                        : AppColors.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
