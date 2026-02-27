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
  String get webSearchMode => 'वेब मोड';

  @override
  String get switchToWebSearch => 'वेब खोज पर स्विच करें';

  @override
  String get switchToChat => 'चैट पर स्विच करें';

  @override
  String get webSearchInputHint => 'अनुवाद या सारांश के लिए URL पेस्ट करें';

  @override
  String get webSearchPrompt =>
      'निम्न वेब पेज सामग्री का अनुवाद और सारांश करें:';

  @override
  String get noInternetConnection => 'इंटरनेट कनेक्शन नहीं है';

  @override
  String get fetchingPage => 'पेज प्राप्त किया जा रहा है...';

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
