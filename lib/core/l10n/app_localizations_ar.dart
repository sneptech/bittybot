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
  String get contextFullBanner =>
      'الجلسة تطول. ابدأ جلسة جديدة للحصول على أفضل النتائج.';

  @override
  String get characterLimitWarning => 'اقتراب من حد الأحرف';
}
