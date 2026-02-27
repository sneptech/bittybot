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
