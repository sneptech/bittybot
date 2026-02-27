// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => 'BittyBot';

  @override
  String get settings => '설정';

  @override
  String get language => '언어';

  @override
  String get errorToneLabel => '오류 메시지 스타일';

  @override
  String get errorToneFriendly => '친근하게';

  @override
  String get errorToneDirect => '간결하게';

  @override
  String get retry => '다시 시도';

  @override
  String get cancel => '취소';

  @override
  String get ok => '확인';

  @override
  String get useDeviceLanguage => '기기 언어 사용';

  @override
  String get loading => '로딩 중...';

  @override
  String get modelNotLoadedFriendly =>
      '잠깐만요 — 모델이 아직 준비 중이에요. 이건 딱 한 번만 있는 일이에요!';

  @override
  String get modelNotLoadedDirect => '모델이 로드되지 않았습니다. 설정이 완료될 때까지 기다려 주세요.';

  @override
  String get inputTooLongFriendly => '앗 — 메시지가 조금 너무 길어요. 줄여서 다시 해보세요.';

  @override
  String get inputTooLongDirect => '입력이 최대 길이를 초과했습니다. 메시지를 줄이고 다시 시도하세요.';

  @override
  String get inferenceFailedFriendly => '음, 문제가 발생했어요. 탭해서 다시 시도해 보세요.';

  @override
  String get inferenceFailedDirect => '번역에 실패했습니다. 다시 시도해 주세요.';

  @override
  String get genericErrorFriendly => '예상치 못한 일이 생겼어요. 다시 한번 시도해 볼까요?';

  @override
  String get genericErrorDirect => '오류가 발생했습니다. 다시 시도해 주세요.';

  @override
  String get modelLoadingTitle => '준비 중...';

  @override
  String get modelLoadingMessage => 'BittyBot을 처음으로 설정하고 있습니다. 한 번만 필요한 과정이에요.';

  @override
  String get modelLoadingError => '설정 실패';

  @override
  String get translate => '번역';

  @override
  String get chat => '채팅';

  @override
  String get translationInputHint => '번역할 내용을 입력하세요';

  @override
  String get translationEmptyState => '번역할 내용을 입력하세요';

  @override
  String get chatInputHint => '메시지를 입력하세요';

  @override
  String get chatEmptyState => '대화를 시작하세요';

  @override
  String get newSession => '새 세션';

  @override
  String get targetLanguage => '목표 언어';

  @override
  String get searchLanguages => '언어 검색';

  @override
  String get popularLanguages => '인기';

  @override
  String get recentLanguages => '최근';

  @override
  String get copied => '복사됨';

  @override
  String get copyTranslation => '번역 복사';

  @override
  String get copyMessage => '메시지 복사';

  @override
  String get contextFullBanner => '세션이 길어지고 있어요. 더 나은 결과를 위해 새 세션을 시작하세요.';

  @override
  String get characterLimitWarning => '글자 수 제한에 가까워지고 있어요';

  @override
  String get chatHistory => '채팅 기록';

  @override
  String get newChat => '새 채팅';

  @override
  String get chatHistoryEmpty => '아직 대화가 없습니다';

  @override
  String get deleteSession => '대화를 삭제할까요?';

  @override
  String get deleteSessionConfirm => '이 대화는 영구적으로 삭제됩니다.';

  @override
  String get justNow => '방금 전';

  @override
  String minutesAgo(int count) {
    return '$count분 전';
  }

  @override
  String hoursAgo(int count) {
    return '$count시간 전';
  }

  @override
  String get yesterday => '어제';

  @override
  String get webSearchMode => '웹 모드';

  @override
  String get switchToWebSearch => '웹 검색으로 전환';

  @override
  String get switchToChat => '채팅으로 전환';

  @override
  String get webSearchInputHint => '번역 또는 요약할 URL을 붙여넣으세요';

  @override
  String get webSearchPrompt => '다음 웹페이지 내용을 번역하고 요약하세요:';

  @override
  String get noInternetConnection => '인터넷 연결이 없습니다';

  @override
  String get fetchingPage => '페이지를 불러오는 중...';

  @override
  String get stopTooltip => '중지';

  @override
  String get sendTooltip => '보내기';

  @override
  String get chatSettings => '채팅';

  @override
  String get autoClearHistory => '기록 자동 삭제';

  @override
  String get autoClearDescription => '오래된 대화를 자동으로 삭제합니다';

  @override
  String get autoClearPeriod => '다음 기간보다 오래된 대화 삭제';

  @override
  String daysCount(int count) {
    return '$count일';
  }

  @override
  String get dangerZone => '데이터';

  @override
  String get clearAllHistory => '전체 기록 삭제';

  @override
  String get clearAllHistoryConfirm =>
      '정말로 삭제하시겠어요? 모든 대화가 영구적으로 삭제되며 되돌릴 수 없습니다.';

  @override
  String get clearAllHistoryAction => '모두 삭제';

  @override
  String get historyCleared => '전체 기록이 삭제되었습니다';
}
