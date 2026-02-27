// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'BittyBot';

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get errorToneLabel => 'أسلوب رسائل الخطأ';

  @override
  String get errorToneFriendly => 'ودّي';

  @override
  String get errorToneDirect => 'مباشر';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get ok => 'موافق';

  @override
  String get useDeviceLanguage => 'استخدام لغة الجهاز';

  @override
  String get loading => 'جارٍ التحميل...';

  @override
  String get modelNotLoadedFriendly =>
      'لحظة من فضلك — النموذج لا يزال يُعدّ نفسه. هذا يحدث مرة واحدة فقط!';

  @override
  String get modelNotLoadedDirect =>
      'النموذج غير محمّل. يُرجى انتظار اكتمال الإعداد.';

  @override
  String get inputTooLongFriendly =>
      'عذراً — هذه الرسالة طويلة بعض الشيء. حاول تقصيرها قليلاً.';

  @override
  String get inputTooLongDirect =>
      'تجاوز الإدخال الحد الأقصى للطول. قصّر رسالتك وحاول مجدداً.';

  @override
  String get inferenceFailedFriendly => 'حدث خطأ ما. انقر للمحاولة مجدداً.';

  @override
  String get inferenceFailedDirect => 'فشلت الترجمة. يُرجى إعادة المحاولة.';

  @override
  String get genericErrorFriendly =>
      'حدث شيء غير متوقع. هل تريد المحاولة مجدداً؟';

  @override
  String get genericErrorDirect => 'حدث خطأ. يُرجى المحاولة مجدداً.';

  @override
  String get modelLoadingTitle => 'جارٍ الإعداد...';

  @override
  String get modelLoadingMessage =>
      'إعداد BittyBot لأول مرة. لا يحتاج هذا إلا أن يتم مرة واحدة.';

  @override
  String get modelLoadingError => 'فشل الإعداد';

  @override
  String get translate => 'ترجمة';

  @override
  String get chat => 'محادثة';

  @override
  String get translationInputHint => 'اكتب شيئاً للترجمة';

  @override
  String get translationEmptyState => 'اكتب شيئاً للترجمة';

  @override
  String get chatInputHint => 'اكتب رسالة';

  @override
  String get chatEmptyState => 'ابدأ محادثة';

  @override
  String get newSession => 'جلسة جديدة';

  @override
  String get targetLanguage => 'لغة الهدف';

  @override
  String get searchLanguages => 'البحث عن لغات';

  @override
  String get popularLanguages => 'الأكثر شيوعاً';

  @override
  String get recentLanguages => 'الأخيرة';

  @override
  String get copied => 'تم النسخ';

  @override
  String get copyTranslation => 'نسخ الترجمة';

  @override
  String get copyMessage => 'نسخ الرسالة';

  @override
  String get contextFullBanner =>
      'الجلسة تطول. ابدأ جلسة جديدة للحصول على أفضل النتائج.';

  @override
  String get characterLimitWarning => 'اقتراب من حد الأحرف';

  @override
  String characterCount(int current, int max) {
    return '$current / $max';
  }

  @override
  String get chatHistory => 'سجل الدردشة';

  @override
  String get newChat => 'دردشة جديدة';

  @override
  String get chatHistoryEmpty => 'لا توجد محادثات بعد';

  @override
  String get deleteSession => 'حذف المحادثة؟';

  @override
  String get deleteSessionConfirm => 'سيتم حذف هذه المحادثة نهائيًا.';

  @override
  String get justNow => 'الآن';

  @override
  String minutesAgo(int count) {
    return 'منذ $count د';
  }

  @override
  String hoursAgo(int count) {
    return 'منذ $count س';
  }

  @override
  String get yesterday => 'أمس';

  @override
  String get webSearchMode => 'وضع الويب';

  @override
  String get switchToWebSearch => 'التبديل إلى البحث على الويب';

  @override
  String get switchToChat => 'التبديل إلى الدردشة';

  @override
  String get webSearchInputHint => 'ألصق رابطًا للترجمة أو التلخيص';

  @override
  String get webSearchPrompt => 'ترجم ولخّص محتوى صفحة الويب التالية:';

  @override
  String get noInternetConnection => 'لا يوجد اتصال بالإنترنت';

  @override
  String get fetchingPage => 'جارٍ جلب الصفحة...';

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
  String get downloadOnCellularDataTitle => 'التنزيل عبر بيانات الهاتف؟';

  @override
  String downloadOnCellularDataMessage(String sizeGb) {
    return 'حجم هذا التنزيل حوالي $sizeGb. هل تريد المتابعة عبر بيانات الهاتف؟';
  }

  @override
  String get waitForWifi => 'الانتظار حتى Wi-Fi';

  @override
  String get downloadNow => 'تنزيل الآن';

  @override
  String get resumeDownloadTitle => 'استئناف التنزيل؟';

  @override
  String get modelRequiredOfflineMessage =>
      'يحتاج BittyBot إلى نموذج اللغة هذا للترجمة والدردشة دون اتصال.';

  @override
  String downloadProgressComplete(int progressPercent) {
    return 'اكتمل التنزيل بنسبة $progressPercent%';
  }

  @override
  String get startOver => 'البدء من جديد';

  @override
  String get resumeAction => 'استئناف';

  @override
  String downloadingLanguageModelForOfflineUse(String sizeGb) {
    return 'جارٍ تنزيل نموذج اللغة للاستخدام دون اتصال ($sizeGb)';
  }

  @override
  String get checkingForLanguageModel => 'جارٍ التحقق من نموذج اللغة...';

  @override
  String get preparingDownload => 'جارٍ تجهيز التنزيل...';

  @override
  String get awaitingYourChoice => 'بانتظار اختيارك...';

  @override
  String get verifyingDownload => 'جارٍ التحقق من التنزيل...';

  @override
  String get loadingLanguageModel => 'جارٍ تحميل نموذج اللغة...';

  @override
  String get readyStatus => 'جاهز!';

  @override
  String downloadSpeedAndRemaining(String speed, String eta) {
    return '$speed - المتبقي $eta';
  }

  @override
  String get notEnoughStorage => 'مساحة التخزين غير كافية';

  @override
  String storageRequirementMessage(String neededGb, String availableGb) {
    return 'يحتاج BittyBot إلى $neededGb جيجابايت مساحة خالية. المتاح لديك $availableGb جيجابايت.';
  }

  @override
  String get freeUpSpaceAndTryAgain => 'افرغ مساحة ثم حاول مرة أخرى';

  @override
  String get lowMemoryWarning => 'تحذير: ذاكرة منخفضة';

  @override
  String lowMemoryWarningMessage(int availableMb) {
    return 'يحتوي جهازك على $availableMb ميجابايت من الذاكرة RAM. قد يكون الأداء ضعيفًا أو قد لا يعمل التطبيق على هذا الجهاز.';
  }

  @override
  String get continueAnyway => 'متابعة على أي حال';

  @override
  String get downloadFailed => 'فشل التنزيل';

  @override
  String get downloadErrorNoInternet =>
      'لا يوجد اتصال بالإنترنت. اتصل بشبكة Wi-Fi أو بيانات الهاتف لتنزيل نموذج اللغة.';

  @override
  String get downloadErrorFailed => 'فشل التنزيل. يُرجى المحاولة مرة أخرى.';

  @override
  String get downloadErrorNotFound =>
      'ملف النموذج غير موجود على الخادم. يُرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.';

  @override
  String get downloadErrorVerificationFailed =>
      'فشل التحقق من التنزيل. قد يكون الملف تالفًا. يُرجى المحاولة مرة أخرى.';

  @override
  String get calculating => 'جارٍ الحساب...';

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours س $minutes د';
  }

  @override
  String durationMinutesSeconds(int minutes, int seconds) {
    return '$minutes د $seconds ث';
  }

  @override
  String durationSeconds(int seconds) {
    return '$seconds ث';
  }

  @override
  String get stopTooltip => 'إيقاف';

  @override
  String get sendTooltip => 'إرسال';

  @override
  String get chatSettings => 'الدردشة';

  @override
  String get autoClearHistory => 'المسح التلقائي للسجل';

  @override
  String get autoClearDescription => 'احذف المحادثات القديمة تلقائيًا';

  @override
  String get autoClearPeriod => 'احذف المحادثات الأقدم من';

  @override
  String daysCount(int count) {
    return '$count يومًا';
  }

  @override
  String get dangerZone => 'البيانات';

  @override
  String get clearAllHistory => 'مسح كل السجل';

  @override
  String get clearAllHistoryConfirm =>
      'هل أنت متأكد؟ سيتم حذف جميع المحادثات نهائيًا. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get clearAllHistoryAction => 'حذف الكل';

  @override
  String get historyCleared => 'تم مسح كل السجل';
}
