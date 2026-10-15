// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get aboutAiAssisted => 'Escrita com ajuda de IA';

  @override
  String get aboutAiNotice =>
      'Partes do código foram escritas com um assistente de IA e depois revistas e mantidas pelo autor, que é responsável por elas. A aplicação em si não contém IA e não envia nada para lado nenhum: os silêncios são encontrados medindo o nível do áudio com o FFmpeg.';

  @override
  String get aboutBuiltWith => 'Feita com Flutter, com tecnologia FFmpeg';

  @override
  String get aboutCopyright => 'Copyright (C) 2026 Vincenzo Padula';

  @override
  String get aboutLicenseSection => 'Licença';

  @override
  String get aboutOpenInBrowser => 'Abre no browser';

  @override
  String get appIntro =>
      'Importe alguns vídeos, escolha a configuração e prima Iniciar para acelerar (ou remover) os silêncios.';

  @override
  String get ffmpegAlreadyRunning =>
      'O FFmpeg ainda está em execução; não é possível iniciar outro processo.';

  @override
  String ffmpegDurationError(String name) {
    return 'Não foi possível ler a duração de $name.';
  }

  @override
  String get ffmpegSpeed => 'Velocidade';

  @override
  String get ffmpegTime => 'Tempo';

  @override
  String get fileAnalyze => 'Medir os silêncios sem exportar';

  @override
  String get fileSilences => 'Mostrar os silêncios detetados';

  @override
  String get fileDialogUnavailable =>
      'Não foi possível abrir a caixa de diálogo de ficheiros do sistema. No Linux, é fornecida pelo xdg-desktop-portal.';

  @override
  String get fileOpenDir => 'Selecionar uma pasta';

  @override
  String get fileOpenFile => 'Selecionar um ou mais vídeos';

  @override
  String get filePreview => 'Gerar uma amostra curta de pré-visualização';

  @override
  String get filePreviewSuffix => ' (pré-visualização)';

  @override
  String get fileRemove => 'Remover este vídeo da lista';

  @override
  String get fileReveal => 'Mostrar o ficheiro exportado';

  @override
  String get helpAudioRate =>
      'Reamostra o áudio. Manter deixa-o exatamente como está, o que é quase sempre o correto.';

  @override
  String get helpAudioTracks =>
      'Leva todas as faixas de áudio da origem para o resultado. Os silêncios continuam a ser detetados só na primeira faixa, que é a da voz numa gravação multifaixa.';

  @override
  String get helpBackgroundNoise =>
      'O nível de ruído da sala. Aumente-o quando um chiado baixo for confundido com fala.';

  @override
  String get helpCredits => 'Créditos';

  @override
  String get helpCrf =>
      'Constant Rate Factor: mais baixo significa melhor qualidade e ficheiro maior. 23 é um bom valor.';

  @override
  String get helpFfmpegNotice =>
      'O FFmpeg está incluído nesta aplicação sob a licença GPLv3. Não há nada para instalar ou configurar.';

  @override
  String get helpFormat =>
      'Contentor do ficheiro exportado. Manter reutiliza o contentor da origem.';

  @override
  String get helpFps =>
      'Taxa de fotogramas para a qual cada fragmento é normalizado, para as partes se juntarem sem recodificar.';

  @override
  String get helpGplNotice =>
      'Este programa não tem absolutamente nenhuma garantia. É software livre e pode redistribuí-lo nas condições da GNU General Public License versão 3 ou posterior.';

  @override
  String get helpIcons => 'Ícones';

  @override
  String get helpIconsCredit =>
      'Ícones de creazilla.com sob a licença CC BY 4.0.';

  @override
  String get helpIntro =>
      'Encurte os seus vídeos acelerando (ou removendo) os silêncios, com o FFmpeg. Feita com Flutter.';

  @override
  String get helpLanguage =>
      'Segue o idioma do sistema, com inglês como alternativa. Fixe um para o substituir.';

  @override
  String get helpLicense =>
      'Este programa não tem absolutamente nenhuma garantia. É software livre e pode redistribuí-lo sob certas condições; consulte a licença para mais detalhes.';

  @override
  String get helpMuteSilences =>
      'Silencia o áudio das partes calmas em vez de deixar passar o chiado acelerado.';

  @override
  String get helpOutputFolder =>
      'Onde um vídeo terminado é gravado. Junto à origem mantém cada um na sua pasta; caso contrário, vão todos para a pasta escolhida.';

  @override
  String get helpPlaybackSpeed =>
      'Velocidade das partes em que alguém fala. Deixe em 1x para manter a fala natural.';

  @override
  String get helpPreset =>
      'Quanto esforço o x264 faz. Os presets mais lentos dão ficheiros mais pequenos com a mesma qualidade.';

  @override
  String get helpPreviewDuration =>
      'Quanto do vídeo a pré-visualização usa. É retirado a um terço da duração, onde a gravação é mais representativa.';

  @override
  String get helpReadLicense => 'Ler a licença';

  @override
  String get helpSilenceMargin =>
      'Tempo mantido de cada lado de cada silêncio, para não cortar palavras.';

  @override
  String get helpSilenceMinDuration =>
      'Quanto tempo uma pausa tem de durar para contar como silêncio.';

  @override
  String get helpSilenceSpeed =>
      'Velocidade das partes silenciosas. Escolha Remover para as cortar por completo.';

  @override
  String get helpTheme => 'Seguir o sistema, ou fixar claro ou escuro.';

  @override
  String get helpTune =>
      'Uma indicação ao x264 sobre o tipo de conteúdo: Still image para diapositivos, Film para imagens de câmara.';

  @override
  String licensesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count licenças',
      one: '1 licença',
    );
    return '$_temp0';
  }

  @override
  String get licensesEmpty =>
      'Não foram encontradas informações de licença nesta compilação.';

  @override
  String licensesPackages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pacotes',
      one: '1 pacote',
    );
    return '$_temp0';
  }

  @override
  String get logAllDone => 'Tudo concluído.';

  @override
  String logAlreadyExists(String name) {
    return 'Não é possível carregar $name: esse nome de ficheiro já está na fila.';
  }

  @override
  String logCompleted(String name) {
    return '$name concluído.';
  }

  @override
  String get logConcatenationError => 'Erro ao juntar os fragmentos.';

  @override
  String get logDataError =>
      'Erro nos dados: os limites dos silêncios não formam pares.';

  @override
  String logFileMissing(String name) {
    return '$name já não está onde estava; a ignorar.';
  }

  @override
  String logFilesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ficheiros adicionados.',
      one: '1 ficheiro adicionado.',
      zero: 'Nenhum ficheiro adicionado.',
    );
    return '$_temp0';
  }

  @override
  String logFragmentError(double start, double end) {
    final intl.NumberFormat startNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 2,
        );
    final String startString = startNumberFormat.format(start);
    final intl.NumberFormat endNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 2,
        );
    final String endString = endNumberFormat.format(end);

    return 'Falha ao codificar o fragmento [$startString - $endString].';
  }

  @override
  String logFragmentsKept(String path) {
    return 'Fragmentos deixados em $path para inspeção.';
  }

  @override
  String logLinkError(String url) {
    return 'Não foi possível abrir $url';
  }

  @override
  String logMeasureDetail(int code, int collected, int streamed) {
    return 'O FFmpeg terminou com $code; escreveu $collected linhas, $streamed delas em direto, e nenhum nível entre elas.';
  }

  @override
  String logMeasureFailed(String name) {
    return 'Não foi possível ler os níveis de $name.';
  }

  @override
  String logMeasuring(String name) {
    return 'A medir os níveis de $name...';
  }

  @override
  String get logNoSilenceDetected =>
      'Nenhum silêncio detetado, a passar ao seguinte.';

  @override
  String logOutputDirError(String path, String error) {
    return 'Não é possível escrever em $path. $error';
  }

  @override
  String logPreviewReady(String name) {
    return 'Pré-visualização pronta: $name';
  }

  @override
  String logPreviewTooShort(String name) {
    return '$name é mais curto do que a pré-visualização; a usar o vídeo inteiro.';
  }

  @override
  String get logQueueEmpty => 'Nenhum vídeo na fila.';

  @override
  String logSilencePercentage(double percentage) {
    final intl.NumberFormat percentageNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 2,
        );
    final String percentageString = percentageNumberFormat.format(percentage);

    return '$percentageString % do vídeo detetado como silêncio.';
  }

  @override
  String get logSkipNoSilences => 'A análise falhou, a passar ao seguinte.';

  @override
  String logStarted(String name) {
    return 'A processar $name.';
  }

  @override
  String get logStopping => 'A parar...';

  @override
  String get menuAbout => 'Acerca de';

  @override
  String get menuCleanShell => 'Limpar registo';

  @override
  String get menuAdd => 'Adicionar';

  @override
  String get menuClearQueue => 'Limpar fila';

  @override
  String get menuDonate => 'Pague-me um café';

  @override
  String get menuHideShell => 'Ocultar registo';

  @override
  String get menuIssue => 'Comunicar um problema';

  @override
  String get menuLicense => 'Ver licença';

  @override
  String get menuOpenFile => 'Adicionar vídeo(s)';

  @override
  String get menuOpenFolder => 'Adicionar pasta';

  @override
  String get menuPrivacy => 'Política de privacidade';

  @override
  String get menuProgress => 'Progresso compacto';

  @override
  String get menuQuit => 'Sair';

  @override
  String get menuReferences => 'Ligações';

  @override
  String get menuShowShell => 'Mostrar registo';

  @override
  String get menuSourceCode => 'Código-fonte';

  @override
  String get menuThirdPartyLicenses => 'Licenças de terceiros';

  @override
  String get menuUpdate => 'Está disponível uma atualização';

  @override
  String menuVersion(String version) {
    return 'Versão $version';
  }

  @override
  String get menuWindowMode => 'Voltar à janela';

  @override
  String get navAbout => 'Acerca de';

  @override
  String get navQueue => 'Fila';

  @override
  String get navSection => 'Mais';

  @override
  String get navSettings => 'Definições da aplicação';

  @override
  String get noiseHigh => 'Alto';

  @override
  String get noiseLow => 'Baixo';

  @override
  String get noiseMid => 'Médio';

  @override
  String get optionKeep => 'Manter';

  @override
  String get optionNone => 'Nenhum';

  @override
  String get outputAlongsideSource => 'Junto à origem';

  @override
  String get outputFixedDirectory => 'Uma pasta à escolha';

  @override
  String get outputChooseFolder => 'Escolher a pasta de exportação';

  @override
  String get outputFolder => 'Exportar para';

  @override
  String get preferenceBundledFfmpeg =>
      'O FFmpeg está incluído na aplicação: não há caminho para configurar.';

  @override
  String get preferenceChooseExportDir => 'Selecionar onde exportar os vídeos';

  @override
  String get preferenceChangeWorkingDir => 'Mudar pasta';

  @override
  String get preferenceChooseWorkingDir =>
      'Selecionar onde guardar os fragmentos intermédios';

  @override
  String get preferenceClearTemporary => 'Limpar';

  @override
  String get preferenceExportDir => 'Pasta de exportação';

  @override
  String get preferenceReset => 'Repor';

  @override
  String get preferenceSave => 'Guardar';

  @override
  String preferenceTemporaryFiles(String size) {
    return 'Ficheiros temporários: $size';
  }

  @override
  String get preferenceWorkingDir => 'Pasta de trabalho';

  @override
  String get preferenceWorkingDirHint =>
      'Os fragmentos intermédios são escritos aqui durante o processamento e depois removidos. Coloque-a numa unidade rápida com espaço de sobra.';

  @override
  String previewSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get processStart => 'Iniciar';

  @override
  String get processStop => 'Parar';

  @override
  String queueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vídeos',
      one: '1 vídeo',
      zero: 'Nenhum vídeo',
    );
    return '$_temp0';
  }

  @override
  String get settingsAdvanced => 'Definições avançadas';

  @override
  String get settingsAudioRate => 'Taxa de áudio';

  @override
  String get settingsAudioTracks => 'Manter todas as faixas de áudio';

  @override
  String get settingsBackgroundNoise => 'Ruído de fundo';

  @override
  String get settingsBasic => 'Definições básicas';

  @override
  String get settingsCrf => 'CRF';

  @override
  String get settingsDefault => 'Predefinição';

  @override
  String get settingsFilterPreview => 'Filtro de deteção';

  @override
  String get settingsFormat => 'Formato de vídeo';

  @override
  String get settingsFps => 'FPS';

  @override
  String get settingsEncodingHide => 'Ocultar as definições de codificação';

  @override
  String get settingsEncodingShow => 'Mostrar as definições de codificação';

  @override
  String get settingsEncodingTitle => 'Definições de codificação';

  @override
  String get settingsGroupApp => 'Aplicação';

  @override
  String get settingsGroupAudio => 'Áudio';

  @override
  String get settingsGroupDetection => 'Deteção de silêncios';

  @override
  String get settingsGroupExport => 'Exportação';

  @override
  String get settingsGroupPreview => 'Pré-visualização';

  @override
  String get settingsGroupSpeed => 'Velocidade';

  @override
  String get settingsMuteSilences => 'Silenciar silêncios';

  @override
  String get settingsNoiseFailed =>
      'Não foi possível ler os níveis deste vídeo. O registo mostra o que o FFmpeg respondeu.';

  @override
  String settingsNoiseMeasure(String name) {
    return 'Medir $name';
  }

  @override
  String settingsNoiseMeasured(String name, int floor, int voice) {
    return '$name: chiado a $floor dB, voz a $voice dB';
  }

  @override
  String settingsNoiseMeasuring(String name) {
    return 'A medir $name...';
  }

  @override
  String get settingsNoiseTooClose =>
      'Aqui o chiado é quase tão alto como a voz, pelo que nenhum limiar os separa bem.';

  @override
  String settingsNoiseUse(int db) {
    return 'Sugerido: $db dB';
  }

  @override
  String settingsNoiseValue(int db) {
    return '$db dB';
  }

  @override
  String get settingsPlaybackSpeed => 'Velocidade da fala';

  @override
  String get settingsPreset => 'Preset';

  @override
  String get settingsPreviewDuration => 'Duração da pré-visualização';

  @override
  String get settingsReset => 'Repor';

  @override
  String get settingsResetDone => 'Definições de codificação repostas';

  @override
  String get settingsResetProcessing => 'Repor as definições de codificação';

  @override
  String get settingsResetProcessingHint =>
      'Repõe os valores predefinidos de velocidade, deteção e exportação.';

  @override
  String settingsSecondsValue(double seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 2,
        );
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString s';
  }

  @override
  String get settingsSilence => 'Deteção de silêncios';

  @override
  String get settingsSilenceMargin => 'Margem do silêncio';

  @override
  String get settingsSilenceMinDuration => 'Duração mín. do silêncio';

  @override
  String get settingsSilenceSpeed => 'Velocidade do silêncio';

  @override
  String get settingsSpeedRemove => 'Remover';

  @override
  String get settingsSpeedRemoveShort => 'corte';

  @override
  String get settingsTune => 'Afinação';

  @override
  String get silencesFit => 'O vídeo inteiro';

  @override
  String get silencesEmpty => 'Não foi encontrado nenhum silêncio neste vídeo.';

  @override
  String silencesPercent(double percentage) {
    final intl.NumberFormat percentageNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String percentageString = percentageNumberFormat.format(percentage);

    return '$percentageString %';
  }

  @override
  String silencesRanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count silêncios',
      one: '1 silêncio',
      zero: 'Nenhum silêncio',
    );
    return '$_temp0';
  }

  @override
  String get silencesRedetect => 'Detetar novamente';

  @override
  String get silencesReveal => 'Mostrar na linha cronológica';

  @override
  String get silencesSaved => 'Tempo poupado';

  @override
  String get silencesShare => 'Da origem';

  @override
  String get silencesStale =>
      'As definições de deteção mudaram desde que estes silêncios foram encontrados.';

  @override
  String get silencesTitle => 'Silêncios detetados';

  @override
  String get silencesTotal => 'Silêncio';

  @override
  String get silencesOutput => 'Resultado estimado';

  @override
  String get silencesZoomIn => 'Ampliar';

  @override
  String get silencesZoomOut => 'Reduzir';

  @override
  String get statusAnalyzing => 'A detetar silêncios...';

  @override
  String get statusCompleted => 'Concluído';

  @override
  String get statusConcatenating => 'A juntar fragmentos...';

  @override
  String get statusExporting => 'A exportar...';

  @override
  String get statusFailed => 'Falhou';

  @override
  String get statusInterrupted => 'Interrompido';

  @override
  String statusLoaded(String duration) {
    return 'Carregado [$duration]';
  }

  @override
  String get statusLoading => 'A carregar...';

  @override
  String get statusQueued => 'Na fila';

  @override
  String get statusReady => 'Pronto';

  @override
  String statusSilenceShare(double percentage) {
    final intl.NumberFormat percentageNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String percentageString = percentageNumberFormat.format(percentage);

    return '$percentageString % de silêncio';
  }

  @override
  String get uiCancel => 'Cancelar';

  @override
  String get uiClose => 'Fechar';

  @override
  String get uiDarkMode => 'Escuro';

  @override
  String get uiDropVideo => 'Largue os vídeos aqui';

  @override
  String get uiLanguage => 'Idioma';

  @override
  String get uiLightMode => 'Claro';

  @override
  String get uiSystemMode => 'Sistema';

  @override
  String get uiTheme => 'Tema';

  @override
  String updateAvailable(String version) {
    return 'A versão $version está disponível.';
  }

  @override
  String get updateDetails => 'Detalhes';

  @override
  String get updateDownload => 'Transferir';
}
