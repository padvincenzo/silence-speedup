// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get aboutAiAssisted => 'Scritta con l\'aiuto dell\'AI';

  @override
  String get aboutAiNotice =>
      'Parti del codice sono state scritte con un assistente AI, poi riviste e mantenute dall\'autore, che ne è responsabile. L\'app in sé non contiene AI e non manda niente da nessuna parte: i silenzi vengono trovati misurando il livello audio con FFmpeg.';

  @override
  String get aboutBuiltWith => 'Realizzata con Flutter, basata su FFmpeg';

  @override
  String get aboutCopyright => 'Copyright (C) 2026 Vincenzo Padula';

  @override
  String get aboutLicenseSection => 'Licenza';

  @override
  String get aboutOpenInBrowser => 'Si apre nel browser';

  @override
  String get appIntro =>
      'Importa dei video, scegli la configurazione e premi Avvia per velocizzare (o rimuovere) i loro silenzi.';

  @override
  String get ffmpegAlreadyRunning =>
      'FFmpeg è ancora in esecuzione; non è possibile avviare un nuovo processo.';

  @override
  String ffmpegDurationError(String name) {
    return 'Impossibile leggere la durata di $name.';
  }

  @override
  String get ffmpegSpeed => 'Velocità';

  @override
  String get ffmpegTime => 'Tempo';

  @override
  String get fileAnalyze => 'Misura i silenzi senza esportare';

  @override
  String get fileSilences => 'Mostra i silenzi rilevati';

  @override
  String get fileOpenDir => 'Seleziona una cartella';

  @override
  String get fileOpenFile => 'Seleziona uno o più video';

  @override
  String get filePreview => 'Genera un breve campione di anteprima';

  @override
  String get filePreviewSuffix => ' (anteprima)';

  @override
  String get fileRemove => 'Rimuovi questo video dalla lista';

  @override
  String get fileReveal => 'Mostra il file esportato';

  @override
  String get helpAudioRate =>
      'Ricampiona l\'audio. Mantieni lo lascia esattamente come è, che è quasi sempre la scelta giusta.';

  @override
  String get helpAudioTracks =>
      'Porta nell\'output tutte le tracce audio del file originale. I silenzi continuano a essere rilevati solo sulla prima traccia, che in una registrazione multitraccia è quella della voce.';

  @override
  String get helpBackgroundNoise =>
      'Quanto è rumoroso l\'ambiente. Alzalo se un leggero fruscio viene confuso con il parlato.';

  @override
  String get helpCredits => 'Crediti';

  @override
  String get helpCrf =>
      'Constant Rate Factor: più basso significa qualità migliore e file più grande. 23 è un buon valore.';

  @override
  String get helpFfmpegNotice =>
      'FFmpeg è incluso nell\'app sotto licenza GPLv3. Non c\'è nulla da installare o configurare.';

  @override
  String get helpFormat =>
      'Contenitore del file esportato. Mantieni riusa quello del file originale.';

  @override
  String get helpFps =>
      'Frame rate a cui viene normalizzato ogni frammento, così i pezzi si uniscono senza ricodificare.';

  @override
  String get helpGplNotice =>
      'Questo programma non offre alcuna garanzia. È software libero e puoi ridistribuirlo alle condizioni della GNU General Public License versione 3 o successiva.';

  @override
  String get helpIcons => 'Icone';

  @override
  String get helpIconsCredit =>
      'Icone da creazilla.com sotto licenza CC BY 4.0.';

  @override
  String get helpIntro =>
      'Velocizza i tuoi video velocizzando (o rimuovendo) i silenzi, usando FFmpeg. Realizzata con Flutter.';

  @override
  String get helpLanguage =>
      'Segue la lingua del sistema, ripiegando sull\'inglese. Fissane una per forzarla.';

  @override
  String get helpLicense =>
      'Questo programma non offre alcuna garanzia. È software libero e la sua ridistribuzione è consentita a determinate condizioni; per i dettagli consulta la licenza.';

  @override
  String get helpMuteSilences =>
      'Azzera l\'audio delle parti silenziose invece di far passare il fruscio accelerato.';

  @override
  String get helpOutputFolder =>
      'Dove viene scritto il video finito. Accanto al sorgente tiene ognuno nella sua cartella; altrimenti vanno tutti nella cartella che scegli.';

  @override
  String get helpPlaybackSpeed =>
      'Velocità delle parti in cui si parla. Lascia 1x per mantenere naturale la voce.';

  @override
  String get helpPreset =>
      'Quanto lavora x264. I preset più lenti danno file più piccoli a pari qualità.';

  @override
  String get helpPreviewDuration =>
      'Quanta parte del video viene campionata dall\'anteprima. Viene presa a un terzo della durata, dove la registrazione è più rappresentativa.';

  @override
  String get helpReadLicense => 'Leggi la licenza';

  @override
  String get helpSilenceMargin =>
      'Tempo conservato ai due lati di ogni silenzio, per non tagliare le parole.';

  @override
  String get helpSilenceMinDuration =>
      'Quanto deve durare una pausa perché conti come silenzio.';

  @override
  String get helpSilenceSpeed =>
      'Velocità delle parti silenziose. Scegli Rimuovi per tagliarle del tutto.';

  @override
  String get helpTheme =>
      'Segui il sistema, oppure fissa il tema chiaro o scuro.';

  @override
  String get helpTune =>
      'Un suggerimento a x264 sul tipo di contenuto: Still image per le slide, Film per le riprese.';

  @override
  String licensesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count licenze',
      one: '1 licenza',
    );
    return '$_temp0';
  }

  @override
  String get licensesEmpty =>
      'Nessuna informazione di licenza trovata in questa build.';

  @override
  String licensesPackages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pacchetti',
      one: '1 pacchetto',
    );
    return '$_temp0';
  }

  @override
  String get logAllDone => 'Tutti i video sono stati completati.';

  @override
  String logAlreadyExists(String name) {
    return 'Impossibile caricare $name: un file con lo stesso nome è già in coda.';
  }

  @override
  String logCompleted(String name) {
    return '$name completato.';
  }

  @override
  String get logConcatenationError => 'Errore durante l\'unione dei frammenti.';

  @override
  String get logDataError =>
      'Errore nei dati: gli estremi dei silenzi non si accoppiano.';

  @override
  String logFileMissing(String name) {
    return '$name non è più al suo posto; lo salto.';
  }

  @override
  String logFilesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count file aggiunti.',
      one: '1 file aggiunto.',
      zero: 'Nessun file aggiunto.',
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

    return 'Errore nella codifica del frammento [$startString - $endString].';
  }

  @override
  String logFragmentsKept(String path) {
    return 'Frammenti lasciati in $path per un controllo.';
  }

  @override
  String logLinkError(String url) {
    return 'Impossibile aprire $url';
  }

  @override
  String logMeasureDetail(int code, int collected, int streamed) {
    return 'FFmpeg è uscito con $code; ha stampato $collected righe, $streamed delle quali in diretta, e fra queste nessun livello.';
  }

  @override
  String logMeasureFailed(String name) {
    return 'Impossibile leggere i livelli di $name.';
  }

  @override
  String logMeasuring(String name) {
    return 'Misurazione dei livelli di $name...';
  }

  @override
  String get logNoSilenceDetected =>
      'Nessun silenzio trovato, passo al successivo.';

  @override
  String logOutputDirError(String path, String error) {
    return 'Impossibile scrivere in $path. $error';
  }

  @override
  String logPreviewReady(String name) {
    return 'Anteprima pronta: $name';
  }

  @override
  String logPreviewTooShort(String name) {
    return '$name è più corto della durata dell\'anteprima; lo campiono per intero.';
  }

  @override
  String get logQueueEmpty => 'Nessun video in coda.';

  @override
  String logSilencePercentage(double percentage) {
    final intl.NumberFormat percentageNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 2,
        );
    final String percentageString = percentageNumberFormat.format(percentage);

    return 'Il $percentageString % del video è stato riconosciuto come silenzio.';
  }

  @override
  String get logSkipNoSilences => 'Analisi fallita, passo al successivo.';

  @override
  String logStarted(String name) {
    return 'Inizio elaborazione di $name.';
  }

  @override
  String get logStopping => 'Interrompendo...';

  @override
  String get menuAbout => 'Informazioni';

  @override
  String get menuCleanShell => 'Svuota log';

  @override
  String get menuAdd => 'Aggiungi';

  @override
  String get menuClearQueue => 'Svuota la coda';

  @override
  String get menuDonate => 'Offrimi un caffè';

  @override
  String get menuHideShell => 'Nascondi log';

  @override
  String get menuIssue => 'Segnala un problema';

  @override
  String get menuLicense => 'Mostra licenza';

  @override
  String get menuOpenFile => 'Importa video';

  @override
  String get menuOpenFolder => 'Importa cartella';

  @override
  String get menuProgress => 'Avanzamento compatto';

  @override
  String get menuQuit => 'Esci';

  @override
  String get menuReferences => 'Collegamenti';

  @override
  String get menuShowShell => 'Mostra log';

  @override
  String get menuSourceCode => 'Codice sorgente';

  @override
  String get menuThirdPartyLicenses => 'Licenze di terze parti';

  @override
  String get menuUpdate => 'È disponibile un aggiornamento';

  @override
  String menuVersion(String version) {
    return 'Versione $version';
  }

  @override
  String get menuWindowMode => 'Torna alla finestra';

  @override
  String get navAbout => 'Informazioni';

  @override
  String get navQueue => 'Coda';

  @override
  String get navSection => 'Altro';

  @override
  String get navSettings => 'Impostazioni app';

  @override
  String get noiseHigh => 'Alta';

  @override
  String get noiseLow => 'Bassa';

  @override
  String get noiseMid => 'Media';

  @override
  String get optionKeep => 'Mantieni';

  @override
  String get optionNone => 'Nessuno';

  @override
  String get outputAlongsideSource => 'Accanto al sorgente';

  @override
  String get outputFixedDirectory => 'Una cartella che scelgo';

  @override
  String get outputChooseFolder => 'Scegli la cartella di esportazione';

  @override
  String get outputFolder => 'Esporta in';

  @override
  String get preferenceBundledFfmpeg =>
      'FFmpeg è incluso nell\'app: non c\'è alcun percorso da configurare.';

  @override
  String get preferenceChooseExportDir =>
      'Seleziona la cartella dove esportare i video';

  @override
  String get preferenceChangeWorkingDir => 'Cambia cartella';

  @override
  String get preferenceChooseWorkingDir =>
      'Seleziona dove tenere i frammenti intermedi';

  @override
  String get preferenceClearTemporary => 'Svuota';

  @override
  String get preferenceExportDir => 'Cartella di esportazione';

  @override
  String get preferenceReset => 'Reimposta';

  @override
  String get preferenceSave => 'Salva';

  @override
  String preferenceTemporaryFiles(String size) {
    return 'File temporanei: $size';
  }

  @override
  String get preferenceWorkingDir => 'Cartella di lavoro';

  @override
  String get preferenceWorkingDirHint =>
      'I frammenti intermedi vengono scritti qui durante l\'elaborazione e poi rimossi. Tienila su un disco veloce e con spazio a disposizione.';

  @override
  String previewSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get processStart => 'Avvia';

  @override
  String get processStop => 'Interrompi';

  @override
  String queueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count video',
      one: '1 video',
      zero: 'Nessun video',
    );
    return '$_temp0';
  }

  @override
  String get settingsAdvanced => 'Impostazioni avanzate';

  @override
  String get settingsAudioRate => 'Frequenza audio';

  @override
  String get settingsAudioTracks => 'Mantieni tutte le tracce audio';

  @override
  String get settingsBackgroundNoise => 'Rumore di fondo';

  @override
  String get settingsBasic => 'Impostazioni base';

  @override
  String get settingsCrf => 'CRF';

  @override
  String get settingsDefault => 'Predefinito';

  @override
  String get settingsFilterPreview => 'Filtro di rilevamento';

  @override
  String get settingsFormat => 'Formato video';

  @override
  String get settingsFps => 'FPS';

  @override
  String get settingsEncodingHide => 'Nascondi le impostazioni di codifica';

  @override
  String get settingsEncodingShow => 'Mostra le impostazioni di codifica';

  @override
  String get settingsEncodingTitle => 'Impostazioni di codifica';

  @override
  String get settingsGroupApp => 'Applicazione';

  @override
  String get settingsGroupAudio => 'Audio';

  @override
  String get settingsGroupDetection => 'Rilevamento dei silenzi';

  @override
  String get settingsGroupExport => 'Esportazione';

  @override
  String get settingsGroupPreview => 'Anteprima';

  @override
  String get settingsGroupSpeed => 'Velocità';

  @override
  String get settingsMuteSilences => 'Muta i silenzi';

  @override
  String get settingsNoiseFailed =>
      'Non è stato possibile leggere i livelli di questo video. Nel log c\'è cosa ha risposto FFmpeg.';

  @override
  String settingsNoiseMeasure(String name) {
    return 'Misura $name';
  }

  @override
  String settingsNoiseMeasured(String name, int floor, int voice) {
    return '$name: fruscio a $floor dB, voce a $voice dB';
  }

  @override
  String settingsNoiseMeasuring(String name) {
    return 'Misurazione di $name...';
  }

  @override
  String get settingsNoiseTooClose =>
      'Qui il fruscio è forte quasi quanto la voce, quindi nessuna soglia li separa davvero.';

  @override
  String settingsNoiseUse(int db) {
    return 'Suggerito: $db dB';
  }

  @override
  String settingsNoiseValue(int db) {
    return '$db dB';
  }

  @override
  String get settingsPlaybackSpeed => 'Velocità del parlato';

  @override
  String get settingsPreset => 'Preset';

  @override
  String get settingsPreviewDuration => 'Durata dell\'anteprima';

  @override
  String get settingsReset => 'Reimposta';

  @override
  String get settingsResetDone => 'Impostazioni di codifica reimpostate';

  @override
  String get settingsResetProcessing => 'Reimposta le impostazioni di codifica';

  @override
  String get settingsResetProcessingHint =>
      'Riporta ai valori predefiniti velocità, rilevamento ed esportazione.';

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
  String get settingsSilence => 'Rilevamento dei silenzi';

  @override
  String get settingsSilenceMargin => 'Margine dai silenzi';

  @override
  String get settingsSilenceMinDuration => 'Durata minima dei silenzi';

  @override
  String get settingsSilenceSpeed => 'Velocità dei silenzi';

  @override
  String get settingsSpeedRemove => 'Rimuovi';

  @override
  String get settingsSpeedRemoveShort => 'via';

  @override
  String get settingsTune => 'Tono';

  @override
  String get silencesFit => 'Tutto il video';

  @override
  String get silencesEmpty => 'Nessun silenzio rilevato in questo video.';

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
      other: '$count silenzi',
      one: '1 silenzio',
      zero: 'Nessun silenzio',
    );
    return '$_temp0';
  }

  @override
  String get silencesRedetect => 'Rileva di nuovo';

  @override
  String get silencesReveal => 'Mostralo sulla timeline';

  @override
  String get silencesSaved => 'Tempo risparmiato';

  @override
  String get silencesShare => 'Del sorgente';

  @override
  String get silencesStale =>
      'Le impostazioni di rilevamento sono cambiate dopo questo rilevamento.';

  @override
  String get silencesTitle => 'Silenzi rilevati';

  @override
  String get silencesTotal => 'Silenzio';

  @override
  String get silencesOutput => 'Output stimato';

  @override
  String get silencesZoomIn => 'Ingrandisci';

  @override
  String get silencesZoomOut => 'Riduci';

  @override
  String get statusAnalyzing => 'Analizzando i silenzi...';

  @override
  String get statusCompleted => 'Completato';

  @override
  String get statusConcatenating => 'Unendo i frammenti...';

  @override
  String get statusExporting => 'Esportando...';

  @override
  String get statusFailed => 'Fallito';

  @override
  String get statusInterrupted => 'Interrotto';

  @override
  String statusLoaded(String duration) {
    return 'Caricato [$duration]';
  }

  @override
  String get statusLoading => 'Caricamento...';

  @override
  String get statusQueued => 'In coda';

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

    return '$percentageString % di silenzio';
  }

  @override
  String get uiCancel => 'Annulla';

  @override
  String get uiClose => 'Chiudi';

  @override
  String get uiDarkMode => 'Scuro';

  @override
  String get uiDropVideo => 'Trascina qui i video';

  @override
  String get uiLanguage => 'Lingua';

  @override
  String get uiLightMode => 'Chiaro';

  @override
  String get uiSystemMode => 'Sistema';

  @override
  String get uiTheme => 'Tema';

  @override
  String updateAvailable(String version) {
    return 'È disponibile la versione $version.';
  }

  @override
  String get updateDetails => 'Dettagli';

  @override
  String get updateDownload => 'Scarica';
}
