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
}
