// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'BittyBot';

  @override
  String get settings => 'Configuración';

  @override
  String get language => 'Idioma';

  @override
  String get errorToneLabel => 'Estilo de mensajes de error';

  @override
  String get errorToneFriendly => 'Amigable';

  @override
  String get errorToneDirect => 'Directo';

  @override
  String get retry => 'Reintentar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get ok => 'Aceptar';

  @override
  String get useDeviceLanguage => 'Usar idioma del dispositivo';

  @override
  String get loading => 'Cargando...';

  @override
  String get modelNotLoadedFriendly =>
      'Un momento — el modelo todavía se está iniciando. ¡Esto solo ocurre una vez!';

  @override
  String get modelNotLoadedDirect =>
      'Modelo no cargado. Espera a que la configuración termine.';

  @override
  String get inputTooLongFriendly =>
      'Vaya — ese mensaje es un poco largo. Intenta acortarlo un poco.';

  @override
  String get inputTooLongDirect =>
      'La entrada supera la longitud máxima. Acorta el mensaje e inténtalo de nuevo.';

  @override
  String get inferenceFailedFriendly =>
      'Hmm, algo salió mal. Toca para reintentar.';

  @override
  String get inferenceFailedDirect =>
      'La traducción falló. Por favor, reintenta.';

  @override
  String get genericErrorFriendly =>
      'Algo inesperado ocurrió. ¿Lo intentas de nuevo?';

  @override
  String get genericErrorDirect =>
      'Se produjo un error. Por favor, inténtalo de nuevo.';

  @override
  String get modelLoadingTitle => 'Preparándose...';

  @override
  String get modelLoadingMessage =>
      'Configurando BittyBot por primera vez. Solo necesita hacerse una vez.';

  @override
  String get modelLoadingError => 'Error de configuración';
}
