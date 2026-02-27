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

  @override
  String get translate => 'Traducir';

  @override
  String get chat => 'Chat';

  @override
  String get translationInputHint => 'Escribe algo para traducir';

  @override
  String get translationEmptyState => 'Escribe algo para traducir';

  @override
  String get chatInputHint => 'Escribe un mensaje';

  @override
  String get chatEmptyState => 'Inicia una conversación';

  @override
  String get newSession => 'Nueva sesión';

  @override
  String get targetLanguage => 'Idioma destino';

  @override
  String get searchLanguages => 'Buscar idiomas';

  @override
  String get popularLanguages => 'Populares';

  @override
  String get recentLanguages => 'Recientes';

  @override
  String get copied => 'Copiado';

  @override
  String get copyTranslation => 'Copiar traducción';

  @override
  String get copyMessage => 'Copiar mensaje';

  @override
  String get contextFullBanner =>
      'La sesión se está alargando. Inicia una nueva para mejores resultados.';

  @override
  String get characterLimitWarning => 'Acercándose al límite de caracteres';

  @override
  String characterCount(int current, int max) {
    return '$current / $max';
  }

  @override
  String get chatHistory => 'Historial de chat';

  @override
  String get newChat => 'Nuevo chat';

  @override
  String get chatHistoryEmpty => 'Aún no hay conversaciones';

  @override
  String get deleteSession => '¿Eliminar conversación?';

  @override
  String get deleteSessionConfirm =>
      'Esta conversación se eliminará permanentemente.';

  @override
  String get justNow => 'Justo ahora';

  @override
  String minutesAgo(int count) {
    return 'hace $count min';
  }

  @override
  String hoursAgo(int count) {
    return 'hace $count h';
  }

  @override
  String get yesterday => 'Ayer';

  @override
  String get webSearchMode => 'Modo web';

  @override
  String get switchToWebSearch => 'Cambiar a búsqueda web';

  @override
  String get switchToChat => 'Cambiar a chat';

  @override
  String get webSearchInputHint => 'Pega una URL para traducir o resumir';

  @override
  String get webSearchPrompt =>
      'Traduce y resume el siguiente contenido de la página web:';

  @override
  String get noInternetConnection => 'Sin conexión a Internet';

  @override
  String get fetchingPage => 'Obteniendo página...';

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
  String get downloadOnCellularDataTitle => '¿Descargar con datos móviles?';

  @override
  String downloadOnCellularDataMessage(String sizeGb) {
    return 'Esta descarga es de ~$sizeGb. ¿Continuar con datos móviles?';
  }

  @override
  String get waitForWifi => 'Esperar a Wi-Fi';

  @override
  String get downloadNow => 'Descargar ahora';

  @override
  String get resumeDownloadTitle => '¿Reanudar descarga?';

  @override
  String get modelRequiredOfflineMessage =>
      'BittyBot necesita este modelo de idioma para traducir y chatear sin conexión.';

  @override
  String downloadProgressComplete(int progressPercent) {
    return 'La descarga está $progressPercent% completa';
  }

  @override
  String get startOver => 'Empezar de nuevo';

  @override
  String get resumeAction => 'Reanudar';

  @override
  String downloadingLanguageModelForOfflineUse(String sizeGb) {
    return 'Descargando modelo de idioma para uso sin conexión ($sizeGb)';
  }

  @override
  String get checkingForLanguageModel => 'Comprobando el modelo de idioma...';

  @override
  String get preparingDownload => 'Preparando descarga...';

  @override
  String get awaitingYourChoice => 'Esperando tu elección...';

  @override
  String get verifyingDownload => 'Verificando descarga...';

  @override
  String get loadingLanguageModel => 'Cargando modelo de idioma...';

  @override
  String get readyStatus => '¡Listo!';

  @override
  String downloadSpeedAndRemaining(String speed, String eta) {
    return '$speed - quedan $eta';
  }

  @override
  String get notEnoughStorage => 'No hay suficiente almacenamiento';

  @override
  String storageRequirementMessage(String neededGb, String availableGb) {
    return 'BittyBot necesita $neededGb GB libres. Tienes $availableGb GB disponibles.';
  }

  @override
  String get freeUpSpaceAndTryAgain => 'Libera espacio e inténtalo de nuevo';

  @override
  String get lowMemoryWarning => 'Advertencia de memoria baja';

  @override
  String lowMemoryWarningMessage(int availableMb) {
    return 'Tu dispositivo tiene $availableMb MB de RAM. El rendimiento puede ser deficiente o la app puede no funcionar en este dispositivo.';
  }

  @override
  String get continueAnyway => 'Continuar de todos modos';

  @override
  String get downloadFailed => 'Descarga fallida';

  @override
  String get downloadErrorNoInternet =>
      'Sin conexión a Internet. Conéctate a Wi-Fi o datos móviles para descargar el modelo de idioma.';

  @override
  String get downloadErrorFailed => 'La descarga falló. Inténtalo de nuevo.';

  @override
  String get downloadErrorNotFound =>
      'No se encontró el archivo del modelo en el servidor. Revisa tu conexión a Internet e inténtalo de nuevo.';

  @override
  String get downloadErrorVerificationFailed =>
      'La verificación de la descarga falló. Es posible que el archivo esté dañado. Inténtalo de nuevo.';

  @override
  String get calculating => 'Calculando...';

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String durationMinutesSeconds(int minutes, int seconds) {
    return '$minutes min $seconds s';
  }

  @override
  String durationSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get stopTooltip => 'Detener';

  @override
  String get sendTooltip => 'Enviar';

  @override
  String get chatSettings => 'Chat';

  @override
  String get autoClearHistory => 'Borrar historial automáticamente';

  @override
  String get autoClearDescription =>
      'Eliminar automáticamente conversaciones antiguas';

  @override
  String get autoClearPeriod => 'Eliminar conversaciones con más de';

  @override
  String daysCount(int count) {
    return '$count días';
  }

  @override
  String get dangerZone => 'Datos';

  @override
  String get clearAllHistory => 'Borrar todo el historial';

  @override
  String get clearAllHistoryConfirm =>
      '¿Estás seguro? Todas las conversaciones se eliminarán permanentemente. Esta acción no se puede deshacer.';

  @override
  String get clearAllHistoryAction => 'Borrar todo';

  @override
  String get historyCleared => 'Se borró todo el historial';
}
