// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'BittyBot';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get errorToneLabel => 'Error message style';

  @override
  String get errorToneFriendly => 'Friendly';

  @override
  String get errorToneDirect => 'Direct';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get useDeviceLanguage => 'Use device language';

  @override
  String get loading => 'Loading...';

  @override
  String get modelNotLoadedFriendly =>
      'Hang on — the model is still warming up. This only happens once!';

  @override
  String get modelNotLoadedDirect =>
      'Model not loaded. Please wait for setup to complete.';

  @override
  String get inputTooLongFriendly =>
      'Oops — that message is a bit too long. Try shortening it a little.';

  @override
  String get inputTooLongDirect =>
      'Input exceeds maximum length. Shorten your message and try again.';

  @override
  String get inferenceFailedFriendly =>
      'Hmm, something went wrong. Tap to retry.';

  @override
  String get inferenceFailedDirect => 'Translation failed. Please retry.';

  @override
  String get genericErrorFriendly =>
      'Something unexpected happened. Give it another try?';

  @override
  String get genericErrorDirect => 'An error occurred. Please try again.';

  @override
  String get modelLoadingTitle => 'Getting ready...';

  @override
  String get modelLoadingMessage =>
      'Setting up BittyBot for the first time. This only needs to happen once.';

  @override
  String get modelLoadingError => 'Setup failed';

  @override
  String get translate => 'Translate';

  @override
  String get chat => 'Chat';

  @override
  String get translationInputHint => 'Type something to translate';

  @override
  String get translationEmptyState => 'Type something to translate';

  @override
  String get chatInputHint => 'Type a message';

  @override
  String get chatEmptyState => 'Start a conversation';

  @override
  String get newSession => 'New session';

  @override
  String get targetLanguage => 'Target language';

  @override
  String get searchLanguages => 'Search languages';

  @override
  String get popularLanguages => 'Popular';

  @override
  String get recentLanguages => 'Recent';

  @override
  String get copied => 'Copied';

  @override
  String get copyTranslation => 'Copy translation';

  @override
  String get copyMessage => 'Copy message';

  @override
  String get contextFullBanner =>
      'Session is getting long. Start a new session for best results.';

  @override
  String get characterLimitWarning => 'Approaching character limit';

  @override
  String characterCount(int current, int max) {
    return '$current / $max';
  }

  @override
  String get chatHistory => 'Chat History';

  @override
  String get newChat => 'New Chat';

  @override
  String get chatHistoryEmpty => 'No conversations yet';

  @override
  String get deleteSession => 'Delete conversation?';

  @override
  String get deleteSessionConfirm =>
      'This conversation will be permanently deleted.';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String hoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String get yesterday => 'Yesterday';

  @override
  String get webSearchMode => 'Web mode';

  @override
  String get switchToWebSearch => 'Switch to web search';

  @override
  String get switchToChat => 'Switch to chat';

  @override
  String get webSearchInputHint => 'Paste a URL to translate or summarize';

  @override
  String get webSearchPrompt =>
      'Translate and summarize the following web page content:';

  @override
  String get noInternetConnection => 'No internet connection';

  @override
  String get fetchingPage => 'Fetching page...';

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
  String get downloadOnCellularDataTitle => 'Download on cellular data?';

  @override
  String downloadOnCellularDataMessage(String sizeGb) {
    return 'This download is ~$sizeGb. Continue on cellular?';
  }

  @override
  String get waitForWifi => 'Wait for Wi-Fi';

  @override
  String get downloadNow => 'Download now';

  @override
  String get resumeDownloadTitle => 'Resume download?';

  @override
  String get modelRequiredOfflineMessage =>
      'BittyBot needs this language model to translate and chat offline.';

  @override
  String downloadProgressComplete(int progressPercent) {
    return 'Download is $progressPercent% complete';
  }

  @override
  String get startOver => 'Start over';

  @override
  String get resumeAction => 'Resume';

  @override
  String downloadingLanguageModelForOfflineUse(String sizeGb) {
    return 'Downloading language model for offline use ($sizeGb)';
  }

  @override
  String get checkingForLanguageModel => 'Checking for language model...';

  @override
  String get preparingDownload => 'Preparing download...';

  @override
  String get awaitingYourChoice => 'Awaiting your choice...';

  @override
  String get verifyingDownload => 'Verifying download...';

  @override
  String get loadingLanguageModel => 'Loading language model...';

  @override
  String get readyStatus => 'Ready!';

  @override
  String downloadSpeedAndRemaining(String speed, String eta) {
    return '$speed - $eta remaining';
  }

  @override
  String get notEnoughStorage => 'Not enough storage';

  @override
  String storageRequirementMessage(String neededGb, String availableGb) {
    return 'BittyBot needs $neededGb GB free. You have $availableGb GB available.';
  }

  @override
  String get freeUpSpaceAndTryAgain => 'Free up space and try again';

  @override
  String get lowMemoryWarning => 'Low memory warning';

  @override
  String lowMemoryWarningMessage(int availableMb) {
    return 'Your device has $availableMb MB of RAM. Performance may be poor or the app may not function at all on this device.';
  }

  @override
  String get continueAnyway => 'Continue anyway';

  @override
  String get downloadFailed => 'Download failed';

  @override
  String get downloadErrorNoInternet =>
      'No internet connection. Connect to Wi-Fi or cellular data to download the language model.';

  @override
  String get downloadErrorFailed => 'Download failed. Please try again.';

  @override
  String get downloadErrorNotFound =>
      'Model file not found on the server. Please check your internet connection and try again.';

  @override
  String get downloadErrorVerificationFailed =>
      'Download verification failed. The file may be corrupted. Please try again.';

  @override
  String get calculating => 'Calculating...';

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String durationMinutesSeconds(int minutes, int seconds) {
    return '${minutes}m ${seconds}s';
  }

  @override
  String durationSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String get stopTooltip => 'Stop';

  @override
  String get sendTooltip => 'Send';

  @override
  String get chatSettings => 'Chat';

  @override
  String get autoClearHistory => 'Auto-clear history';

  @override
  String get autoClearDescription => 'Automatically delete old conversations';

  @override
  String get autoClearPeriod => 'Delete conversations older than';

  @override
  String daysCount(int count) {
    return '$count days';
  }

  @override
  String get dangerZone => 'Data';

  @override
  String get clearAllHistory => 'Clear all history';

  @override
  String get clearAllHistoryConfirm =>
      'Are you sure? All conversations will be permanently deleted. This cannot be undone.';

  @override
  String get clearAllHistoryAction => 'Delete all';

  @override
  String get historyCleared => 'All history cleared';
}
