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
  String get contextFullBanner => 'セッションが長くなっています。最良の結果のために新しいセッションを開始してください。';

  @override
  String get characterLimitWarning => '文字数制限に近づいています';
}
