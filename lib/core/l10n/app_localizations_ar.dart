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
