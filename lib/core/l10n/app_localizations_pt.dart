// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'BittyBot';

  @override
  String get settings => 'Configurações';

  @override
  String get language => 'Idioma';

  @override
  String get errorToneLabel => 'Estilo das mensagens de erro';

  @override
  String get errorToneFriendly => 'Amigável';

  @override
  String get errorToneDirect => 'Direto';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get cancel => 'Cancelar';

  @override
  String get ok => 'OK';

  @override
  String get useDeviceLanguage => 'Usar idioma do dispositivo';

  @override
  String get loading => 'Carregando...';

  @override
  String get modelNotLoadedFriendly =>
      'Aguarda — o modelo ainda está se preparando. Isso só acontece uma vez!';

  @override
  String get modelNotLoadedDirect =>
      'Modelo não carregado. Aguarde a conclusão da configuração.';

  @override
  String get inputTooLongFriendly =>
      'Ops — essa mensagem está um pouco longa demais. Tente encurtá-la um pouco.';

  @override
  String get inputTooLongDirect =>
      'A entrada excede o comprimento máximo. Encurte sua mensagem e tente novamente.';

  @override
  String get inferenceFailedFriendly =>
      'Hmm, algo deu errado. Toque para tentar novamente.';

  @override
  String get inferenceFailedDirect =>
      'Tradução falhou. Por favor, tente novamente.';

  @override
  String get genericErrorFriendly =>
      'Algo inesperado aconteceu. Quer tentar de novo?';

  @override
  String get genericErrorDirect =>
      'Ocorreu um erro. Por favor, tente novamente.';

  @override
  String get modelLoadingTitle => 'Preparando...';

  @override
  String get modelLoadingMessage =>
      'Configurando o BittyBot pela primeira vez. Isso só precisa acontecer uma vez.';

  @override
  String get modelLoadingError => 'Falha na configuração';

  @override
  String get translate => 'Traduzir';

  @override
  String get chat => 'Chat';

  @override
  String get translationInputHint => 'Digite algo para traduzir';

  @override
  String get translationEmptyState => 'Digite algo para traduzir';

  @override
  String get chatInputHint => 'Digite uma mensagem';

  @override
  String get chatEmptyState => 'Inicie uma conversa';

  @override
  String get newSession => 'Nova sessão';

  @override
  String get targetLanguage => 'Idioma de destino';

  @override
  String get searchLanguages => 'Pesquisar idiomas';

  @override
  String get popularLanguages => 'Populares';

  @override
  String get recentLanguages => 'Recentes';

  @override
  String get copied => 'Copiado';

  @override
  String get copyTranslation => 'Copiar tradução';

  @override
  String get copyMessage => 'Copiar mensagem';

  @override
  String get contextFullBanner =>
      'A sessão está ficando longa. Inicie uma nova sessão para melhores resultados.';

  @override
  String get characterLimitWarning => 'Aproximando-se do limite de caracteres';

  @override
  String characterCount(int current, int max) {
    return '$current / $max';
  }

  @override
  String get chatHistory => 'Histórico de conversas';

  @override
  String get newChat => 'Novo chat';

  @override
  String get chatHistoryEmpty => 'Ainda não há conversas';

  @override
  String get deleteSession => 'Excluir conversa?';

  @override
  String get deleteSessionConfirm =>
      'Esta conversa será excluída permanentemente.';

  @override
  String get justNow => 'Agora mesmo';

  @override
  String minutesAgo(int count) {
    return 'há $count min';
  }

  @override
  String hoursAgo(int count) {
    return 'há $count h';
  }

  @override
  String get yesterday => 'Ontem';

  @override
  String get noInternetConnection => 'Sem conexão com a internet';

  @override
  String get fetchingPage => 'Buscando página...';

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
  String get downloadOnCellularDataTitle => 'Baixar usando dados móveis?';

  @override
  String downloadOnCellularDataMessage(String sizeGb) {
    return 'Este download tem ~$sizeGb. Continuar usando dados móveis?';
  }

  @override
  String get waitForWifi => 'Esperar por Wi-Fi';

  @override
  String get downloadNow => 'Baixar agora';

  @override
  String get resumeDownloadTitle => 'Retomar download?';

  @override
  String get modelRequiredOfflineMessage =>
      'O BittyBot precisa deste modelo de idioma para traduzir e conversar offline.';

  @override
  String downloadProgressComplete(int progressPercent) {
    return 'O download está $progressPercent% concluído';
  }

  @override
  String get startOver => 'Começar de novo';

  @override
  String get resumeAction => 'Retomar';

  @override
  String downloadingLanguageModelForOfflineUse(String sizeGb) {
    return 'Baixando modelo de idioma para uso offline ($sizeGb)';
  }

  @override
  String get checkingForLanguageModel => 'Verificando modelo de idioma...';

  @override
  String get preparingDownload => 'Preparando download...';

  @override
  String get awaitingYourChoice => 'Aguardando sua escolha...';

  @override
  String get verifyingDownload => 'Verificando download...';

  @override
  String get loadingLanguageModel => 'Carregando modelo de idioma...';

  @override
  String get readyStatus => 'Pronto!';

  @override
  String downloadSpeedAndRemaining(String speed, String eta) {
    return '$speed - $eta restantes';
  }

  @override
  String get notEnoughStorage => 'Espaço de armazenamento insuficiente';

  @override
  String storageRequirementMessage(String neededGb, String availableGb) {
    return 'O BittyBot precisa de $neededGb GB livres. Você tem $availableGb GB disponíveis.';
  }

  @override
  String get freeUpSpaceAndTryAgain => 'Libere espaço e tente novamente';

  @override
  String get lowMemoryWarning => 'Aviso de pouca memória';

  @override
  String lowMemoryWarningMessage(int availableMb) {
    return 'Seu dispositivo tem $availableMb MB de RAM. O desempenho pode ser ruim ou o app pode não funcionar neste dispositivo.';
  }

  @override
  String get continueAnyway => 'Continuar mesmo assim';

  @override
  String get downloadFailed => 'Falha no download';

  @override
  String get downloadErrorNoInternet =>
      'Sem conexão com a internet. Conecte-se ao Wi-Fi ou aos dados móveis para baixar o modelo de idioma.';

  @override
  String get downloadErrorFailed => 'Falha no download. Tente novamente.';

  @override
  String get downloadErrorNotFound =>
      'Arquivo do modelo não encontrado no servidor. Verifique sua conexão com a internet e tente novamente.';

  @override
  String get downloadErrorVerificationFailed =>
      'A verificação do download falhou. O arquivo pode estar corrompido. Tente novamente.';

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
  String get stopTooltip => 'Parar';

  @override
  String get sendTooltip => 'Enviar';

  @override
  String get chatSettings => 'Chat';

  @override
  String get autoClearHistory => 'Limpar histórico automaticamente';

  @override
  String get autoClearDescription =>
      'Excluir automaticamente conversas antigas';

  @override
  String get autoClearPeriod => 'Excluir conversas com mais de';

  @override
  String daysCount(int count) {
    return '$count dias';
  }

  @override
  String get dangerZone => 'Dados';

  @override
  String get clearAllHistory => 'Limpar todo o histórico';

  @override
  String get clearAllHistoryConfirm =>
      'Tem certeza? Todas as conversas serão excluídas permanentemente. Esta ação não pode ser desfeita.';

  @override
  String get clearAllHistoryAction => 'Excluir tudo';

  @override
  String get historyCleared => 'Todo o histórico foi limpo';
}
