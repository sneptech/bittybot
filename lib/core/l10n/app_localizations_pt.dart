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
  String get contextFullBanner =>
      'A sessão está ficando longa. Inicie uma nova sessão para melhores resultados.';

  @override
  String get characterLimitWarning => 'Aproximando-se do limite de caracteres';
}
