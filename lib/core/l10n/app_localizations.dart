import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('zh'),
  ];

  /// Application name displayed in app bar and about screen
  ///
  /// In en, this message translates to:
  /// **'BittyBot'**
  String get appName;

  /// Settings screen title and navigation label
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Language selection label in settings
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Label for the error tone preference setting
  ///
  /// In en, this message translates to:
  /// **'Error message style'**
  String get errorToneLabel;

  /// Option label for friendly/warm error message tone
  ///
  /// In en, this message translates to:
  /// **'Friendly'**
  String get errorToneFriendly;

  /// Option label for direct/concise error message tone
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get errorToneDirect;

  /// Button label to retry a failed action
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Button label to cancel an action or dismiss a dialog
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Button label to confirm or acknowledge
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Toggle label to follow the device system locale
  ///
  /// In en, this message translates to:
  /// **'Use device language'**
  String get useDeviceLanguage;

  /// Generic loading state indicator text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Model not yet loaded error; friendly/warm tone
  ///
  /// In en, this message translates to:
  /// **'Hang on — the model is still warming up. This only happens once!'**
  String get modelNotLoadedFriendly;

  /// Model not yet loaded error; direct/concise tone
  ///
  /// In en, this message translates to:
  /// **'Model not loaded. Please wait for setup to complete.'**
  String get modelNotLoadedDirect;

  /// Input exceeds max length error; friendly/warm tone
  ///
  /// In en, this message translates to:
  /// **'Oops — that message is a bit too long. Try shortening it a little.'**
  String get inputTooLongFriendly;

  /// Input exceeds max length error; direct/concise tone
  ///
  /// In en, this message translates to:
  /// **'Input exceeds maximum length. Shorten your message and try again.'**
  String get inputTooLongDirect;

  /// Inference or translation failure; friendly/warm tone
  ///
  /// In en, this message translates to:
  /// **'Hmm, something went wrong. Tap to retry.'**
  String get inferenceFailedFriendly;

  /// Inference or translation failure; direct/concise tone
  ///
  /// In en, this message translates to:
  /// **'Translation failed. Please retry.'**
  String get inferenceFailedDirect;

  /// Generic fallback error; friendly/warm tone
  ///
  /// In en, this message translates to:
  /// **'Something unexpected happened. Give it another try?'**
  String get genericErrorFriendly;

  /// Generic fallback error; direct/concise tone
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get genericErrorDirect;

  /// Title shown on model loading/setup screen
  ///
  /// In en, this message translates to:
  /// **'Getting ready...'**
  String get modelLoadingTitle;

  /// Body text shown during first-launch model setup
  ///
  /// In en, this message translates to:
  /// **'Setting up BittyBot for the first time. This only needs to happen once.'**
  String get modelLoadingMessage;

  /// Error state title on model loading screen
  ///
  /// In en, this message translates to:
  /// **'Setup failed'**
  String get modelLoadingError;

  /// Translation tab label in bottom navigation bar
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get translate;

  /// Chat tab label in bottom navigation bar
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// Placeholder text in the translation input field
  ///
  /// In en, this message translates to:
  /// **'Type something to translate'**
  String get translationInputHint;

  /// Centered empty-state prompt shown when no messages exist
  ///
  /// In en, this message translates to:
  /// **'Type something to translate'**
  String get translationEmptyState;

  /// Placeholder text in the chat input field
  ///
  /// In en, this message translates to:
  /// **'Type a message'**
  String get chatInputHint;

  /// Centered empty-state prompt shown in the chat screen when no messages exist
  ///
  /// In en, this message translates to:
  /// **'Start a conversation'**
  String get chatEmptyState;

  /// Tooltip/label for the new session button in the translation screen top bar
  ///
  /// In en, this message translates to:
  /// **'New session'**
  String get newSession;

  /// Label for the target language selector button in the top bar
  ///
  /// In en, this message translates to:
  /// **'Target language'**
  String get targetLanguage;

  /// Placeholder text in the language search field of the language picker
  ///
  /// In en, this message translates to:
  /// **'Search languages'**
  String get searchLanguages;

  /// Section header for the popular languages group in the language picker
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popularLanguages;

  /// Section header for recently used languages in the language picker
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recentLanguages;

  /// Brief confirmation shown after copying a translation to clipboard
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// Label for the copy action in the long-press context menu on translation bubbles
  ///
  /// In en, this message translates to:
  /// **'Copy translation'**
  String get copyTranslation;

  /// Label for the copy action in the long-press context menu on chat bubbles
  ///
  /// In en, this message translates to:
  /// **'Copy message'**
  String get copyMessage;

  /// Banner shown when the translation context approaches the model's limit
  ///
  /// In en, this message translates to:
  /// **'Session is getting long. Start a new session for best results.'**
  String get contextFullBanner;

  /// Warning shown in the input field when the user approaches the soft character limit
  ///
  /// In en, this message translates to:
  /// **'Approaching character limit'**
  String get characterLimitWarning;

  /// Title shown at the top of the chat history drawer
  ///
  /// In en, this message translates to:
  /// **'Chat History'**
  String get chatHistory;

  /// Button label and fallback title for untitled chat sessions in the drawer
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get newChat;

  /// Empty state text shown in the chat history drawer when no sessions exist
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get chatHistoryEmpty;

  /// Title of the confirmation dialog when deleting a chat session
  ///
  /// In en, this message translates to:
  /// **'Delete conversation?'**
  String get deleteSession;

  /// Body text of the delete session confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'This conversation will be permanently deleted.'**
  String get deleteSessionConfirm;

  /// Relative time label for events less than 1 minute ago
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// Relative time label for events N minutes ago
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String minutesAgo(int count);

  /// Relative time label for events N hours ago
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String hoursAgo(int count);

  /// Relative time label for events that occurred yesterday
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// Indicator label shown when web search mode is active
  ///
  /// In en, this message translates to:
  /// **'Web mode'**
  String get webSearchMode;

  /// Tooltip for the toggle button to enable web search mode
  ///
  /// In en, this message translates to:
  /// **'Switch to web search'**
  String get switchToWebSearch;

  /// Tooltip for the toggle button to return to normal chat mode
  ///
  /// In en, this message translates to:
  /// **'Switch to chat'**
  String get switchToChat;

  /// Placeholder text in the input field when web search mode is active
  ///
  /// In en, this message translates to:
  /// **'Paste a URL to translate or summarize'**
  String get webSearchInputHint;

  /// Prompt prefix sent to the model before fetched web page content
  ///
  /// In en, this message translates to:
  /// **'Translate and summarize the following web page content:'**
  String get webSearchPrompt;

  /// Error shown when attempting web search without network connectivity
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetConnection;

  /// Loading indicator text shown while fetching a web page
  ///
  /// In en, this message translates to:
  /// **'Fetching page...'**
  String get fetchingPage;

  /// Tooltip for the stop generation button in chat and translation input bars
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopTooltip;

  /// Tooltip for the send message button in chat and translation input bars
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendTooltip;

  /// Section header for chat-related settings
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatSettings;

  /// Label for the auto-clear toggle switch in settings
  ///
  /// In en, this message translates to:
  /// **'Auto-clear history'**
  String get autoClearHistory;

  /// Subtitle explaining the auto-clear toggle
  ///
  /// In en, this message translates to:
  /// **'Automatically delete old conversations'**
  String get autoClearDescription;

  /// Label for the auto-clear time period selector
  ///
  /// In en, this message translates to:
  /// **'Delete conversations older than'**
  String get autoClearPeriod;

  /// Time period label showing number of days
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String daysCount(int count);

  /// Section header for destructive data operations in settings
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get dangerZone;

  /// Button label for deleting all chat history
  ///
  /// In en, this message translates to:
  /// **'Clear all history'**
  String get clearAllHistory;

  /// Confirmation dialog body text for clear all history action
  ///
  /// In en, this message translates to:
  /// **'Are you sure? All conversations will be permanently deleted. This cannot be undone.'**
  String get clearAllHistoryConfirm;

  /// Destructive action button label in the clear all confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get clearAllHistoryAction;

  /// Snackbar confirmation shown after all history is deleted
  ///
  /// In en, this message translates to:
  /// **'All history cleared'**
  String get historyCleared;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'hi',
    'ja',
    'ko',
    'pt',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
