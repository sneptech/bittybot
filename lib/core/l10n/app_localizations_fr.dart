// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'BittyBot';

  @override
  String get settings => 'Paramètres';

  @override
  String get language => 'Langue';

  @override
  String get errorToneLabel => 'Style des messages d\'erreur';

  @override
  String get errorToneFriendly => 'Convivial';

  @override
  String get errorToneDirect => 'Direct';

  @override
  String get retry => 'Réessayer';

  @override
  String get cancel => 'Annuler';

  @override
  String get ok => 'OK';

  @override
  String get useDeviceLanguage => 'Utiliser la langue du téléphone';

  @override
  String get loading => 'Chargement...';

  @override
  String get modelNotLoadedFriendly =>
      'Patience — le modèle est encore en train de démarrer. Ça n\'arrive qu\'une fois !';

  @override
  String get modelNotLoadedDirect =>
      'Modèle non chargé. Veuillez attendre la fin de la configuration.';

  @override
  String get inputTooLongFriendly =>
      'Oups — ce message est un peu trop long. Essaie de le raccourcir un peu.';

  @override
  String get inputTooLongDirect =>
      'La saisie dépasse la longueur maximale. Raccourcissez votre message et réessayez.';

  @override
  String get inferenceFailedFriendly =>
      'Hmm, quelque chose s\'est mal passé. Appuie pour réessayer.';

  @override
  String get inferenceFailedDirect =>
      'La traduction a échoué. Veuillez réessayer.';

  @override
  String get genericErrorFriendly =>
      'Quelque chose d\'inattendu s\'est produit. Tu veux réessayer ?';

  @override
  String get genericErrorDirect =>
      'Une erreur est survenue. Veuillez réessayer.';

  @override
  String get modelLoadingTitle => 'Préparation en cours...';

  @override
  String get modelLoadingMessage =>
      'Configuration de BittyBot pour la première fois. Cela n\'a besoin de se faire qu\'une seule fois.';

  @override
  String get modelLoadingError => 'Échec de la configuration';

  @override
  String get translate => 'Traduire';

  @override
  String get chat => 'Chat';

  @override
  String get translationInputHint => 'Écrivez quelque chose à traduire';

  @override
  String get translationEmptyState => 'Écrivez quelque chose à traduire';

  @override
  String get newSession => 'Nouvelle session';

  @override
  String get targetLanguage => 'Langue cible';

  @override
  String get searchLanguages => 'Rechercher des langues';

  @override
  String get popularLanguages => 'Populaires';

  @override
  String get recentLanguages => 'Récentes';

  @override
  String get copied => 'Copié';

  @override
  String get copyTranslation => 'Copier la traduction';

  @override
  String get contextFullBanner =>
      'La session devient longue. Démarrez une nouvelle session pour de meilleurs résultats.';

  @override
  String get characterLimitWarning => 'Limite de caractères presque atteinte';
}
