// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'BittyBot';

  @override
  String get settings => 'Einstellungen';

  @override
  String get language => 'Sprache';

  @override
  String get errorToneLabel => 'Stil der Fehlermeldungen';

  @override
  String get errorToneFriendly => 'Freundlich';

  @override
  String get errorToneDirect => 'Direkt';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get ok => 'OK';

  @override
  String get useDeviceLanguage => 'Gerätesprache verwenden';

  @override
  String get loading => 'Laden...';

  @override
  String get modelNotLoadedFriendly =>
      'Einen Moment — das Modell startet noch. Das passiert nur einmal!';

  @override
  String get modelNotLoadedDirect =>
      'Modell nicht geladen. Bitte warten Sie, bis die Einrichtung abgeschlossen ist.';

  @override
  String get inputTooLongFriendly =>
      'Hoppla — diese Nachricht ist ein bisschen zu lang. Versuche sie etwas zu kürzen.';

  @override
  String get inputTooLongDirect =>
      'Die Eingabe überschreitet die maximale Länge. Kürzen Sie Ihre Nachricht und versuchen Sie es erneut.';

  @override
  String get inferenceFailedFriendly =>
      'Hmm, etwas ist schiefgelaufen. Tippe zum Wiederholen.';

  @override
  String get inferenceFailedDirect =>
      'Übersetzung fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get genericErrorFriendly =>
      'Etwas Unerwartetes ist passiert. Nochmal versuchen?';

  @override
  String get genericErrorDirect =>
      'Ein Fehler ist aufgetreten. Bitte versuchen Sie es erneut.';

  @override
  String get modelLoadingTitle => 'Vorbereitung...';

  @override
  String get modelLoadingMessage =>
      'BittyBot wird zum ersten Mal eingerichtet. Das muss nur einmal geschehen.';

  @override
  String get modelLoadingError => 'Einrichtung fehlgeschlagen';

  @override
  String get translate => 'Übersetzen';

  @override
  String get chat => 'Chat';

  @override
  String get translationInputHint => 'Etwas zum Übersetzen eingeben';

  @override
  String get translationEmptyState => 'Etwas zum Übersetzen eingeben';

  @override
  String get chatInputHint => 'Nachricht eingeben';

  @override
  String get chatEmptyState => 'Gespräch beginnen';

  @override
  String get newSession => 'Neue Sitzung';

  @override
  String get targetLanguage => 'Zielsprache';

  @override
  String get searchLanguages => 'Sprachen suchen';

  @override
  String get popularLanguages => 'Beliebt';

  @override
  String get recentLanguages => 'Zuletzt';

  @override
  String get copied => 'Kopiert';

  @override
  String get copyTranslation => 'Übersetzung kopieren';

  @override
  String get copyMessage => 'Nachricht kopieren';

  @override
  String get contextFullBanner =>
      'Die Sitzung wird lang. Starte eine neue Sitzung für beste Ergebnisse.';

  @override
  String get characterLimitWarning => 'Zeichenlimit wird erreicht';

  @override
  String get chatHistory => 'Chatverlauf';

  @override
  String get newChat => 'Neuer Chat';

  @override
  String get chatHistoryEmpty => 'Noch keine Unterhaltungen';

  @override
  String get deleteSession => 'Unterhaltung löschen?';

  @override
  String get deleteSessionConfirm =>
      'Diese Unterhaltung wird dauerhaft gelöscht.';

  @override
  String get justNow => 'Gerade eben';

  @override
  String minutesAgo(int count) {
    return 'vor $count Min.';
  }

  @override
  String hoursAgo(int count) {
    return 'vor $count Std.';
  }

  @override
  String get yesterday => 'Gestern';

  @override
  String get webSearchMode => 'Webmodus';

  @override
  String get switchToWebSearch => 'Zur Websuche wechseln';

  @override
  String get switchToChat => 'Zum Chat wechseln';

  @override
  String get webSearchInputHint =>
      'Fügen Sie eine URL zum Übersetzen oder Zusammenfassen ein';

  @override
  String get webSearchPrompt =>
      'Übersetze und fasse den folgenden Webseiteninhalt zusammen:';

  @override
  String get noInternetConnection => 'Keine Internetverbindung';

  @override
  String get fetchingPage => 'Seite wird geladen...';

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
  String get downloadOnCellularDataTitle => 'Über mobile Daten herunterladen?';

  @override
  String downloadOnCellularDataMessage(String sizeGb) {
    return 'Dieser Download ist ~$sizeGb. Über mobile Daten fortfahren?';
  }

  @override
  String get waitForWifi => 'Auf WLAN warten';

  @override
  String get downloadNow => 'Jetzt herunterladen';

  @override
  String get resumeDownloadTitle => 'Download fortsetzen?';

  @override
  String get modelRequiredOfflineMessage =>
      'BittyBot benötigt dieses Sprachmodell, um offline zu übersetzen und zu chatten.';

  @override
  String downloadProgressComplete(int progressPercent) {
    return 'Download ist zu $progressPercent% abgeschlossen';
  }

  @override
  String get startOver => 'Von vorn beginnen';

  @override
  String get resumeAction => 'Fortsetzen';

  @override
  String downloadingLanguageModelForOfflineUse(String sizeGb) {
    return 'Sprachmodell für die Offline-Nutzung wird heruntergeladen ($sizeGb)';
  }

  @override
  String get checkingForLanguageModel => 'Sprachmodell wird geprüft...';

  @override
  String get preparingDownload => 'Download wird vorbereitet...';

  @override
  String get awaitingYourChoice => 'Warte auf deine Auswahl...';

  @override
  String get verifyingDownload => 'Download wird verifiziert...';

  @override
  String get loadingLanguageModel => 'Sprachmodell wird geladen...';

  @override
  String get readyStatus => 'Bereit!';

  @override
  String downloadSpeedAndRemaining(String speed, String eta) {
    return '$speed - $eta verbleibend';
  }

  @override
  String get notEnoughStorage => 'Nicht genügend Speicherplatz';

  @override
  String storageRequirementMessage(String neededGb, String availableGb) {
    return 'BittyBot benötigt $neededGb GB freien Speicher. Verfügbar: $availableGb GB.';
  }

  @override
  String get freeUpSpaceAndTryAgain =>
      'Speicher freigeben und erneut versuchen';

  @override
  String get lowMemoryWarning => 'Warnung: wenig Arbeitsspeicher';

  @override
  String lowMemoryWarningMessage(int availableMb) {
    return 'Dein Gerät hat $availableMb MB RAM. Die Leistung kann schlecht sein oder die App funktioniert auf diesem Gerät möglicherweise nicht.';
  }

  @override
  String get continueAnyway => 'Trotzdem fortfahren';

  @override
  String get downloadFailed => 'Download fehlgeschlagen';

  @override
  String get calculating => 'Wird berechnet...';

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours Std $minutes Min';
  }

  @override
  String durationMinutesSeconds(int minutes, int seconds) {
    return '$minutes Min $seconds Sek';
  }

  @override
  String durationSeconds(int seconds) {
    return '$seconds Sek';
  }

  @override
  String get stopTooltip => 'Stopp';

  @override
  String get sendTooltip => 'Senden';

  @override
  String get chatSettings => 'Chat';

  @override
  String get autoClearHistory => 'Verlauf automatisch löschen';

  @override
  String get autoClearDescription => 'Alte Unterhaltungen automatisch löschen';

  @override
  String get autoClearPeriod => 'Unterhaltungen löschen, die älter sind als';

  @override
  String daysCount(int count) {
    return '$count Tage';
  }

  @override
  String get dangerZone => 'Daten';

  @override
  String get clearAllHistory => 'Gesamten Verlauf löschen';

  @override
  String get clearAllHistoryConfirm =>
      'Sind Sie sicher? Alle Unterhaltungen werden dauerhaft gelöscht. Dies kann nicht rückgängig gemacht werden.';

  @override
  String get clearAllHistoryAction => 'Alles löschen';

  @override
  String get historyCleared => 'Gesamter Verlauf gelöscht';
}
