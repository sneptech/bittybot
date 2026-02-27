// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'BittyBot';

  @override
  String get settings => '設定';

  @override
  String get language => '言語';

  @override
  String get errorToneLabel => 'エラーメッセージのスタイル';

  @override
  String get errorToneFriendly => 'やさしい';

  @override
  String get errorToneDirect => 'シンプル';

  @override
  String get retry => '再試行';

  @override
  String get cancel => 'キャンセル';

  @override
  String get ok => 'OK';

  @override
  String get useDeviceLanguage => '端末の言語を使用';

  @override
  String get loading => '読み込み中...';

  @override
  String get modelNotLoadedFriendly => '少々お待ちください——モデルがまだ準備中です。これは一度だけ起こります！';

  @override
  String get modelNotLoadedDirect => 'モデルが読み込まれていません。セットアップが完了するまでお待ちください。';

  @override
  String get inputTooLongFriendly => 'おっと——そのメッセージは少し長すぎます。短くしてみてください。';

  @override
  String get inputTooLongDirect => '入力が最大文字数を超えています。メッセージを短くして再試行してください。';

  @override
  String get inferenceFailedFriendly => 'うーん、何か問題が発生しました。タップして再試行してください。';

  @override
  String get inferenceFailedDirect => '翻訳に失敗しました。再試行してください。';

  @override
  String get genericErrorFriendly => '予期しないことが起きました。もう一度試してみますか？';

  @override
  String get genericErrorDirect => 'エラーが発生しました。もう一度お試しください。';

  @override
  String get modelLoadingTitle => '準備中...';

  @override
  String get modelLoadingMessage => 'BittyBotを初めてセットアップしています。これは一度だけ必要です。';

  @override
  String get modelLoadingError => 'セットアップに失敗しました';

  @override
  String get translate => '翻訳';

  @override
  String get chat => 'チャット';

  @override
  String get translationInputHint => '翻訳するテキストを入力';

  @override
  String get translationEmptyState => '翻訳するテキストを入力';

  @override
  String get chatInputHint => 'メッセージを入力';

  @override
  String get chatEmptyState => '会話を始める';

  @override
  String get newSession => '新しいセッション';

  @override
  String get targetLanguage => '翻訳先の言語';

  @override
  String get searchLanguages => '言語を検索';

  @override
  String get popularLanguages => '人気';

  @override
  String get recentLanguages => '最近';

  @override
  String get copied => 'コピーしました';

  @override
  String get copyTranslation => '翻訳をコピー';

  @override
  String get copyMessage => 'メッセージをコピー';

  @override
  String get contextFullBanner => 'セッションが長くなっています。最良の結果のために新しいセッションを開始してください。';

  @override
  String get characterLimitWarning => '文字数制限に近づいています';

  @override
  String get chatHistory => 'チャット履歴';

  @override
  String get newChat => '新しいチャット';

  @override
  String get chatHistoryEmpty => 'まだ会話はありません';

  @override
  String get deleteSession => '会話を削除しますか？';

  @override
  String get deleteSessionConfirm => 'この会話は完全に削除されます。';

  @override
  String get justNow => 'たった今';

  @override
  String minutesAgo(int count) {
    return '$count分前';
  }

  @override
  String hoursAgo(int count) {
    return '$count時間前';
  }

  @override
  String get yesterday => '昨日';

  @override
  String get webSearchMode => 'ウェブモード';

  @override
  String get switchToWebSearch => 'ウェブ検索に切り替え';

  @override
  String get switchToChat => 'チャットに切り替え';

  @override
  String get webSearchInputHint => '翻訳または要約するURLを貼り付け';

  @override
  String get webSearchPrompt => '次のウェブページ内容を翻訳して要約してください:';

  @override
  String get noInternetConnection => 'インターネット接続がありません';

  @override
  String get fetchingPage => 'ページを取得中...';

  @override
  String get stopTooltip => '停止';

  @override
  String get sendTooltip => '送信';

  @override
  String get chatSettings => 'チャット';

  @override
  String get autoClearHistory => '履歴を自動削除';

  @override
  String get autoClearDescription => '古い会話を自動的に削除します';

  @override
  String get autoClearPeriod => '次の日数より古い会話を削除';

  @override
  String daysCount(int count) {
    return '$count日';
  }

  @override
  String get dangerZone => 'データ';

  @override
  String get clearAllHistory => '履歴をすべて削除';

  @override
  String get clearAllHistoryConfirm =>
      '本当によろしいですか？すべての会話が完全に削除されます。この操作は元に戻せません。';

  @override
  String get clearAllHistoryAction => 'すべて削除';

  @override
  String get historyCleared => 'すべての履歴を削除しました';
}
