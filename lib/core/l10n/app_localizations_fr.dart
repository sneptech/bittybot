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
  String get chatInputHint => 'Saisissez un message';

  @override
  String get chatEmptyState => 'Démarrer une conversation';

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
  String get copyMessage => 'Copier le message';

  @override
  String get contextFullBanner =>
      'La session devient longue. Démarrez une nouvelle session pour de meilleurs résultats.';

  @override
  String get characterLimitWarning => 'Limite de caractères presque atteinte';

  @override
  String characterCount(int current, int max) {
    return '$current / $max';
  }

  @override
  String get chatHistory => 'Historique des discussions';

  @override
  String get newChat => 'Nouvelle discussion';

  @override
  String get chatHistoryEmpty => 'Aucune conversation pour le moment';

  @override
  String get deleteSession => 'Supprimer la conversation ?';

  @override
  String get deleteSessionConfirm =>
      'Cette conversation sera supprimée définitivement.';

  @override
  String get justNow => 'À l’instant';

  @override
  String minutesAgo(int count) {
    return 'il y a $count min';
  }

  @override
  String hoursAgo(int count) {
    return 'il y a $count h';
  }

  @override
  String get yesterday => 'Hier';

  @override
  String get webSearchMode => 'Mode web';

  @override
  String get switchToWebSearch => 'Passer à la recherche web';

  @override
  String get switchToChat => 'Revenir au chat';

  @override
  String get webSearchInputHint => 'Collez une URL pour traduire ou résumer';

  @override
  String get webSearchPrompt =>
      'Traduisez et résumez le contenu de la page web suivante :';

  @override
  String get noInternetConnection => 'Pas de connexion Internet';

  @override
  String get fetchingPage => 'Récupération de la page...';

  @override
  String get webErrorInvalidUrl =>
      'Invalid URL. Please enter a valid web address.';

  @override
  String webErrorHttpStatus(int statusCode) {
    return 'Failed to load page (HTTP $statusCode).';
  }

  @override
  String get webErrorEmptyContent => 'No text content found on this page.';

  @override
  String get webErrorNetwork => 'Network error. Please check your connection.';

  @override
  String get webErrorTimeout => 'Request timed out. Please try again.';

  @override
  String get downloadOnCellularDataTitle =>
      'Télécharger via les données mobiles ?';

  @override
  String downloadOnCellularDataMessage(String sizeGb) {
    return 'Ce téléchargement fait ~$sizeGb. Continuer via les données mobiles ?';
  }

  @override
  String get waitForWifi => 'Attendre le Wi-Fi';

  @override
  String get downloadNow => 'Télécharger maintenant';

  @override
  String get resumeDownloadTitle => 'Reprendre le téléchargement ?';

  @override
  String get modelRequiredOfflineMessage =>
      'BittyBot a besoin de ce modèle de langue pour traduire et discuter hors ligne.';

  @override
  String downloadProgressComplete(int progressPercent) {
    return 'Le téléchargement est terminé à $progressPercent %';
  }

  @override
  String get startOver => 'Recommencer';

  @override
  String get resumeAction => 'Reprendre';

  @override
  String downloadingLanguageModelForOfflineUse(String sizeGb) {
    return 'Téléchargement du modèle de langue pour une utilisation hors ligne ($sizeGb)';
  }

  @override
  String get checkingForLanguageModel => 'Vérification du modèle de langue...';

  @override
  String get preparingDownload => 'Préparation du téléchargement...';

  @override
  String get awaitingYourChoice => 'En attente de votre choix...';

  @override
  String get verifyingDownload => 'Vérification du téléchargement...';

  @override
  String get loadingLanguageModel => 'Chargement du modèle de langue...';

  @override
  String get readyStatus => 'Prêt !';

  @override
  String downloadSpeedAndRemaining(String speed, String eta) {
    return '$speed - reste $eta';
  }

  @override
  String get notEnoughStorage => 'Stockage insuffisant';

  @override
  String storageRequirementMessage(String neededGb, String availableGb) {
    return 'BittyBot a besoin de $neededGb Go libres. Vous avez $availableGb Go disponibles.';
  }

  @override
  String get freeUpSpaceAndTryAgain => 'Libérez de l\'espace et réessayez';

  @override
  String get lowMemoryWarning => 'Avertissement de mémoire faible';

  @override
  String lowMemoryWarningMessage(int availableMb) {
    return 'Votre appareil dispose de $availableMb Mo de RAM. Les performances peuvent être faibles ou l\'application peut ne pas fonctionner sur cet appareil.';
  }

  @override
  String get continueAnyway => 'Continuer quand même';

  @override
  String get downloadFailed => 'Échec du téléchargement';

  @override
  String get downloadErrorNoInternet =>
      'Pas de connexion Internet. Connectez-vous au Wi-Fi ou aux données mobiles pour télécharger le modèle de langue.';

  @override
  String get downloadErrorFailed =>
      'Le téléchargement a échoué. Veuillez réessayer.';

  @override
  String get downloadErrorNotFound =>
      'Fichier du modèle introuvable sur le serveur. Vérifiez votre connexion Internet et réessayez.';

  @override
  String get downloadErrorVerificationFailed =>
      'La vérification du téléchargement a échoué. Le fichier est peut-être corrompu. Veuillez réessayer.';

  @override
  String get calculating => 'Calcul...';

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String durationMinutesSeconds(int minutes, int seconds) {
    return '$minutes min $seconds s';
  }

  @override
  String durationSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get stopTooltip => 'Arrêter';

  @override
  String get sendTooltip => 'Envoyer';

  @override
  String get chatSettings => 'Discussion';

  @override
  String get autoClearHistory => 'Effacer automatiquement l’historique';

  @override
  String get autoClearDescription =>
      'Supprimer automatiquement les anciennes conversations';

  @override
  String get autoClearPeriod => 'Supprimer les conversations datant de plus de';

  @override
  String daysCount(int count) {
    return '$count jours';
  }

  @override
  String get dangerZone => 'Données';

  @override
  String get clearAllHistory => 'Effacer tout l’historique';

  @override
  String get clearAllHistoryConfirm =>
      'Êtes-vous sûr ? Toutes les conversations seront supprimées définitivement. Cette action est irréversible.';

  @override
  String get clearAllHistoryAction => 'Tout supprimer';

  @override
  String get historyCleared => 'Tout l’historique a été effacé';
}
