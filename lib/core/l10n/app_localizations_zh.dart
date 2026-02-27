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
  String get chatInputHint => '输入消息';

  @override
  String get chatEmptyState => '开始对话';

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
  String get copyMessage => '复制消息';

  @override
  String get contextFullBanner => '会话内容过长，建议开启新会话以获得最佳效果。';

  @override
  String get characterLimitWarning => '即将达到字符限制';

  @override
  String get chatHistory => '聊天记录';

  @override
  String get newChat => '新聊天';

  @override
  String get chatHistoryEmpty => '还没有对话';

  @override
  String get deleteSession => '删除对话？';

  @override
  String get deleteSessionConfirm => '此对话将被永久删除。';

  @override
  String get justNow => '刚刚';

  @override
  String minutesAgo(int count) {
    return '$count分钟前';
  }

  @override
  String hoursAgo(int count) {
    return '$count小时前';
  }

  @override
  String get yesterday => '昨天';

  @override
  String get webSearchMode => '网页模式';

  @override
  String get switchToWebSearch => '切换到网页搜索';

  @override
  String get switchToChat => '切换到聊天';

  @override
  String get webSearchInputHint => '粘贴一个 URL 进行翻译或总结';

  @override
  String get webSearchPrompt => '请翻译并总结以下网页内容：';

  @override
  String get noInternetConnection => '无互联网连接';

  @override
  String get fetchingPage => '正在获取页面...';

  @override
  String get stopTooltip => '停止';

  @override
  String get sendTooltip => '发送';

  @override
  String get chatSettings => '聊天';

  @override
  String get autoClearHistory => '自动清理历史记录';

  @override
  String get autoClearDescription => '自动删除旧对话';

  @override
  String get autoClearPeriod => '删除超过以下时长的对话';

  @override
  String daysCount(int count) {
    return '$count天';
  }

  @override
  String get dangerZone => '数据';

  @override
  String get clearAllHistory => '清空全部历史记录';

  @override
  String get clearAllHistoryConfirm => '确定吗？所有对话将被永久删除，且无法撤销。';

  @override
  String get clearAllHistoryAction => '全部删除';

  @override
  String get historyCleared => '已清空全部历史记录';
}
