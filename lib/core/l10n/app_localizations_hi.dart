// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'BittyBot';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get language => 'भाषा';

  @override
  String get errorToneLabel => 'त्रुटि संदेश शैली';

  @override
  String get errorToneFriendly => 'मित्रवत';

  @override
  String get errorToneDirect => 'सीधा';

  @override
  String get retry => 'पुनः प्रयास';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get ok => 'ठीक है';

  @override
  String get useDeviceLanguage => 'डिवाइस की भाषा उपयोग करें';

  @override
  String get loading => 'लोड हो रहा है...';

  @override
  String get modelNotLoadedFriendly =>
      'थोड़ा इंतज़ार करें — मॉडल अभी तैयार हो रहा है। ऐसा सिर्फ एक बार होता है!';

  @override
  String get modelNotLoadedDirect =>
      'मॉडल लोड नहीं हुआ। कृपया सेटअप पूरा होने तक प्रतीक्षा करें।';

  @override
  String get inputTooLongFriendly =>
      'अरे — वह संदेश थोड़ा बहुत लंबा है। ज़रा छोटा करके देखें।';

  @override
  String get inputTooLongDirect =>
      'इनपुट अधिकतम लंबाई से अधिक है। संदेश छोटा करें और पुनः प्रयास करें।';

  @override
  String get inferenceFailedFriendly =>
      'हम्म, कुछ गड़बड़ हो गई। पुनः प्रयास के लिए टैप करें।';

  @override
  String get inferenceFailedDirect =>
      'अनुवाद विफल हुआ। कृपया पुनः प्रयास करें।';

  @override
  String get genericErrorFriendly =>
      'कुछ अप्रत्याशित हो गया। फिर से कोशिश करें?';

  @override
  String get genericErrorDirect => 'एक त्रुटि हुई। कृपया पुनः प्रयास करें।';

  @override
  String get modelLoadingTitle => 'तैयार हो रहा है...';

  @override
  String get modelLoadingMessage =>
      'पहली बार BittyBot सेट हो रहा है। यह केवल एक बार करना होता है।';

  @override
  String get modelLoadingError => 'सेटअप विफल हुआ';

  @override
  String get translate => 'अनुवाद करें';

  @override
  String get chat => 'चैट';

  @override
  String get translationInputHint => 'अनुवाद के लिए कुछ टाइप करें';

  @override
  String get translationEmptyState => 'अनुवाद के लिए कुछ टाइप करें';

  @override
  String get chatInputHint => 'संदेश टाइप करें';

  @override
  String get chatEmptyState => 'बातचीत शुरू करें';

  @override
  String get newSession => 'नया सत्र';

  @override
  String get targetLanguage => 'लक्ष्य भाषा';

  @override
  String get searchLanguages => 'भाषाएं खोजें';

  @override
  String get popularLanguages => 'लोकप्रिय';

  @override
  String get recentLanguages => 'हाल की';

  @override
  String get copied => 'कॉपी हो गया';

  @override
  String get copyTranslation => 'अनुवाद कॉपी करें';

  @override
  String get copyMessage => 'संदेश कॉपी करें';

  @override
  String get contextFullBanner =>
      'सत्र लंबा हो रहा है। बेहतर परिणामों के लिए नया सत्र शुरू करें।';

  @override
  String get characterLimitWarning => 'वर्ण सीमा के करीब';

  @override
  String characterCount(int current, int max) {
    return '$current / $max';
  }

  @override
  String get chatHistory => 'चैट इतिहास';

  @override
  String get newChat => 'नई चैट';

  @override
  String get chatHistoryEmpty => 'अभी तक कोई बातचीत नहीं';

  @override
  String get deleteSession => 'बातचीत हटाएँ?';

  @override
  String get deleteSessionConfirm => 'यह बातचीत स्थायी रूप से हटा दी जाएगी।';

  @override
  String get justNow => 'अभी-अभी';

  @override
  String minutesAgo(int count) {
    return '$count मि पहले';
  }

  @override
  String hoursAgo(int count) {
    return '$count घं पहले';
  }

  @override
  String get yesterday => 'कल';

  @override
  String get noInternetConnection => 'इंटरनेट कनेक्शन नहीं है';

  @override
  String get fetchingPage => 'पेज प्राप्त किया जा रहा है...';

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
  String get downloadOnCellularDataTitle => 'मोबाइल डेटा पर डाउनलोड करें?';

  @override
  String downloadOnCellularDataMessage(String sizeGb) {
    return 'यह डाउनलोड लगभग $sizeGb का है। क्या मोबाइल डेटा पर जारी रखें?';
  }

  @override
  String get waitForWifi => 'Wi-Fi का इंतज़ार करें';

  @override
  String get downloadNow => 'अभी डाउनलोड करें';

  @override
  String get resumeDownloadTitle => 'डाउनलोड फिर से शुरू करें?';

  @override
  String get modelRequiredOfflineMessage =>
      'BittyBot को ऑफलाइन अनुवाद और चैट के लिए यह भाषा मॉडल चाहिए।';

  @override
  String downloadProgressComplete(int progressPercent) {
    return 'डाउनलोड $progressPercent% पूरा हो चुका है';
  }

  @override
  String get startOver => 'फिर से शुरू करें';

  @override
  String get resumeAction => 'जारी रखें';

  @override
  String downloadingLanguageModelForOfflineUse(String sizeGb) {
    return 'ऑफलाइन उपयोग के लिए भाषा मॉडल डाउनलोड हो रहा है ($sizeGb)';
  }

  @override
  String get checkingForLanguageModel => 'भाषा मॉडल जांचा जा रहा है...';

  @override
  String get preparingDownload => 'डाउनलोड तैयार किया जा रहा है...';

  @override
  String get awaitingYourChoice => 'आपके चयन की प्रतीक्षा है...';

  @override
  String get verifyingDownload => 'डाउनलोड सत्यापित किया जा रहा है...';

  @override
  String get loadingLanguageModel => 'भाषा मॉडल लोड हो रहा है...';

  @override
  String get readyStatus => 'तैयार!';

  @override
  String downloadSpeedAndRemaining(String speed, String eta) {
    return '$speed - $eta शेष';
  }

  @override
  String get notEnoughStorage => 'स्टोरेज पर्याप्त नहीं है';

  @override
  String storageRequirementMessage(String neededGb, String availableGb) {
    return 'BittyBot को $neededGb GB खाली जगह चाहिए। आपके पास $availableGb GB उपलब्ध है।';
  }

  @override
  String get freeUpSpaceAndTryAgain => 'जगह खाली करें और फिर कोशिश करें';

  @override
  String get lowMemoryWarning => 'कम मेमोरी चेतावनी';

  @override
  String lowMemoryWarningMessage(int availableMb) {
    return 'आपके डिवाइस में $availableMb MB RAM है। प्रदर्शन खराब हो सकता है या यह ऐप इस डिवाइस पर ठीक से काम न करे।';
  }

  @override
  String get continueAnyway => 'फिर भी जारी रखें';

  @override
  String get downloadFailed => 'डाउनलोड विफल';

  @override
  String get downloadErrorNoInternet =>
      'इंटरनेट कनेक्शन नहीं है। भाषा मॉडल डाउनलोड करने के लिए Wi-Fi या मोबाइल डेटा से कनेक्ट करें।';

  @override
  String get downloadErrorFailed => 'डाउनलोड विफल हुआ। कृपया पुनः प्रयास करें।';

  @override
  String get downloadErrorNotFound =>
      'सर्वर पर मॉडल फ़ाइल नहीं मिली। कृपया अपना इंटरनेट कनेक्शन जांचें और पुनः प्रयास करें।';

  @override
  String get downloadErrorVerificationFailed =>
      'डाउनलोड सत्यापन विफल हुआ। फ़ाइल क्षतिग्रस्त हो सकती है। कृपया पुनः प्रयास करें।';

  @override
  String get calculating => 'गणना की जा रही है...';

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hoursघं $minutesमि';
  }

  @override
  String durationMinutesSeconds(int minutes, int seconds) {
    return '$minutesमि $secondsसे';
  }

  @override
  String durationSeconds(int seconds) {
    return '$secondsसे';
  }

  @override
  String get stopTooltip => 'रोकें';

  @override
  String get sendTooltip => 'भेजें';

  @override
  String get chatSettings => 'चैट';

  @override
  String get autoClearHistory => 'इतिहास अपने-आप साफ करें';

  @override
  String get autoClearDescription => 'पुरानी बातचीत अपने-आप हटाएँ';

  @override
  String get autoClearPeriod => 'इतने दिनों से पुरानी बातचीत हटाएँ';

  @override
  String daysCount(int count) {
    return '$count दिन';
  }

  @override
  String get dangerZone => 'डेटा';

  @override
  String get clearAllHistory => 'सारा इतिहास साफ करें';

  @override
  String get clearAllHistoryConfirm =>
      'क्या आप सुनिश्चित हैं? सभी बातचीत स्थायी रूप से हट जाएँगी। इसे वापस नहीं किया जा सकता।';

  @override
  String get clearAllHistoryAction => 'सब हटाएँ';

  @override
  String get historyCleared => 'सारा इतिहास साफ कर दिया गया';
}
