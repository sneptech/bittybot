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
}
