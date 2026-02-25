// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'BittyBot';

  @override
  String get settings => '设置';

  @override
  String get language => '语言';

  @override
  String get errorToneLabel => '错误消息风格';

  @override
  String get errorToneFriendly => '亲切';

  @override
  String get errorToneDirect => '直接';

  @override
  String get retry => '重试';

  @override
  String get cancel => '取消';

  @override
  String get ok => '好的';

  @override
  String get useDeviceLanguage => '使用设备语言';

  @override
  String get loading => '加载中...';

  @override
  String get modelNotLoadedFriendly => '稍等一下——模型还在预热中，这只会发生一次！';

  @override
  String get modelNotLoadedDirect => '模型未加载，请等待初始化完成。';

  @override
  String get inputTooLongFriendly => '哎呀，这条消息有点太长了，试着缩短一下吧。';

  @override
  String get inputTooLongDirect => '输入内容超过最大长度，请缩短消息后重试。';

  @override
  String get inferenceFailedFriendly => '嗯，好像出了点问题，点击重试。';

  @override
  String get inferenceFailedDirect => '翻译失败，请重试。';

  @override
  String get genericErrorFriendly => '出现了意外情况，要再试一次吗？';

  @override
  String get genericErrorDirect => '发生错误，请重试。';

  @override
  String get modelLoadingTitle => '准备中...';

  @override
  String get modelLoadingMessage => '正在首次配置 BittyBot，只需要进行这一次。';

  @override
  String get modelLoadingError => '配置失败';

  @override
  String get translate => '翻译';

  @override
  String get chat => '聊天';

  @override
  String get translationInputHint => '输入要翻译的内容';

  @override
  String get translationEmptyState => '输入要翻译的内容';

  @override
  String get newSession => '新会话';

  @override
  String get targetLanguage => '目标语言';

  @override
  String get searchLanguages => '搜索语言';

  @override
  String get popularLanguages => '热门';

  @override
  String get recentLanguages => '最近';

  @override
  String get copied => '已复制';

  @override
  String get copyTranslation => '复制翻译';

  @override
  String get contextFullBanner => '会话内容过长，建议开启新会话以获得最佳效果。';

  @override
  String get characterLimitWarning => '即将达到字符限制';
}
