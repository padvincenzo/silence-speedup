// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get aboutAiAssisted => 'Mit KI-Unterstützung geschrieben';

  @override
  String get aboutAiNotice =>
      'Teile des Codes wurden mit einem KI-Assistenten geschrieben und dann vom Autor geprüft und gepflegt, der dafür verantwortlich ist. Die App selbst enthält keine KI und sendet nichts irgendwohin: Pausen werden gefunden, indem FFmpeg den Audiopegel misst.';

  @override
  String get aboutBuiltWith => 'Erstellt mit Flutter, basiert auf FFmpeg';

  @override
  String get aboutCopyright => 'Copyright (C) 2026 Vincenzo Padula';

  @override
  String get aboutLicenseSection => 'Lizenz';

  @override
  String get aboutOpenInBrowser => 'Öffnet sich im Browser';

  @override
  String get appIntro =>
      'Importiere Videos, wähle die Konfiguration und drücke dann Start, um ihre Pausen zu beschleunigen (oder zu entfernen).';

  @override
  String get ffmpegAlreadyRunning =>
      'FFmpeg läuft noch; es kann kein weiterer Prozess gestartet werden.';

  @override
  String ffmpegDurationError(String name) {
    return 'Die Dauer von $name konnte nicht gelesen werden.';
  }

  @override
  String get ffmpegSpeed => 'Tempo';

  @override
  String get ffmpegTime => 'Zeit';

  @override
  String get fileAnalyze => 'Pausen messen, ohne zu exportieren';

  @override
  String get fileSilences => 'Erkannte Pausen anzeigen';

  @override
  String get fileDialogUnavailable =>
      'Der Dateidialog des Systems konnte nicht geöffnet werden. Unter Linux stellt ihn xdg-desktop-portal bereit.';

  @override
  String get fileOpenDir => 'Ordner auswählen';

  @override
  String get fileOpenFile => 'Ein oder mehrere Videos auswählen';

  @override
  String get filePreview => 'Kurzen Vorschauausschnitt erstellen';

  @override
  String get filePreviewSuffix => ' (Vorschau)';

  @override
  String get fileRemove => 'Dieses Video aus der Liste entfernen';

  @override
  String get fileReveal => 'Exportierte Datei anzeigen';

  @override
  String get helpAudioRate =>
      'Tastet das Audio neu ab. Beibehalten lässt es genau so, wie es ist, und das ist fast immer richtig.';

  @override
  String get helpAudioTracks =>
      'Übernimmt alle Audiospuren der Quelle in die Ausgabe. Pausen werden weiterhin nur auf der ersten Spur erkannt, die bei einer Mehrspuraufnahme die Sprachspur ist.';

  @override
  String get helpBackgroundNoise =>
      'Wie laut der Raum ist. Erhöhe den Wert, wenn leises Rauschen für Sprache gehalten wird.';

  @override
  String get helpCredits => 'Danksagungen';

  @override
  String get helpCrf =>
      'Constant Rate Factor: niedriger bedeutet bessere Qualität und eine größere Datei. 23 ist ein guter Standardwert.';

  @override
  String get helpFfmpegNotice =>
      'FFmpeg ist unter der GPLv3-Lizenz in dieser App enthalten. Es gibt nichts zu installieren oder einzurichten.';

  @override
  String get helpFormat =>
      'Container der exportierten Datei. Beibehalten verwendet den Container der Quelle.';

  @override
  String get helpFps =>
      'Bildrate, auf die jedes Fragment vereinheitlicht wird, damit die Teile ohne Neukodierung zusammengefügt werden können.';

  @override
  String get helpGplNotice =>
      'Dieses Programm wird ohne jegliche Gewährleistung bereitgestellt. Es ist freie Software, und du darfst es unter den Bedingungen der GNU General Public License Version 3 oder neuer weitergeben.';

  @override
  String get helpIcons => 'Symbole';

  @override
  String get helpIconsCredit =>
      'Symbole von creazilla.com unter der Lizenz CC BY 4.0.';

  @override
  String get helpIntro =>
      'Beschleunige deine Videos, indem du mit FFmpeg ihre Pausen beschleunigst (oder entfernst). Erstellt mit Flutter.';

  @override
  String get helpLanguage =>
      'Folgt der Systemsprache, sonst Englisch. Lege eine fest, um sie zu überschreiben.';

  @override
  String get helpLicense =>
      'Dieses Programm wird ohne jegliche Gewährleistung bereitgestellt. Es ist freie Software, und du darfst es unter bestimmten Bedingungen weitergeben; Einzelheiten stehen in der Lizenz.';

  @override
  String get helpMuteSilences =>
      'Schaltet den Ton der stillen Abschnitte stumm, statt das beschleunigte Rauschen durchzulassen.';

  @override
  String get helpOutputFolder =>
      'Wohin ein fertiges Video geschrieben wird. Neben der Quelle belässt jedes in seinem eigenen Ordner; sonst landen alle im Ordner deiner Wahl.';

  @override
  String get helpPlaybackSpeed =>
      'Tempo für die Abschnitte, in denen gesprochen wird. Belasse es bei 1x, damit die Sprache natürlich bleibt.';

  @override
  String get helpPreset =>
      'Wie gründlich x264 arbeitet. Langsamere Presets ergeben bei gleicher Qualität kleinere Dateien.';

  @override
  String get helpPreviewDuration =>
      'Wie viel des Videos eine Vorschau erfasst. Der Ausschnitt beginnt nach einem Drittel, wo die Aufnahme am repräsentativsten ist.';

  @override
  String get helpReadLicense => 'Lizenz lesen';

  @override
  String get helpSilenceMargin =>
      'Zeit, die auf beiden Seiten jeder Pause erhalten bleibt, damit keine Wörter abgeschnitten werden.';

  @override
  String get helpSilenceMinDuration =>
      'Wie lange eine Pause dauern muss, damit sie als Stille zählt.';

  @override
  String get helpSilenceSpeed =>
      'Tempo für die stillen Abschnitte. Wähle Entfernen, um sie ganz herauszuschneiden.';

  @override
  String get helpTheme => 'Dem System folgen oder hell bzw. dunkel festlegen.';

  @override
  String get helpTune =>
      'Ein Hinweis an x264 zur Art des Inhalts: Still image für Folien, Film für Kameraaufnahmen.';

  @override
  String licensesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Lizenzen',
      one: '1 Lizenz',
    );
    return '$_temp0';
  }

  @override
  String get licensesEmpty =>
      'In diesem Build wurden keine Lizenzinformationen gefunden.';

  @override
  String licensesPackages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Pakete',
      one: '1 Paket',
    );
    return '$_temp0';
  }

  @override
  String get logAllDone => 'Alles erledigt.';

  @override
  String logAlreadyExists(String name) {
    return '$name kann nicht geladen werden: Dieser Dateiname ist bereits in der Warteschlange.';
  }

  @override
  String logCompleted(String name) {
    return '$name abgeschlossen.';
  }

  @override
  String get logConcatenationError =>
      'Fehler beim Zusammenfügen der Fragmente.';

  @override
  String get logDataError =>
      'Datenfehler: Die Grenzen der Pausen ergeben keine Paare.';

  @override
  String logFileMissing(String name) {
    return '$name ist nicht mehr an seinem Ort; wird übersprungen.';
  }

  @override
  String logFilesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dateien hinzugefügt.',
      one: '1 Datei hinzugefügt.',
      zero: 'Keine Dateien hinzugefügt.',
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

    return 'Fragment [$startString - $endString] konnte nicht kodiert werden.';
  }

  @override
  String logFragmentsKept(String path) {
    return 'Fragmente zur Prüfung in $path belassen.';
  }

  @override
  String logLinkError(String url) {
    return '$url konnte nicht geöffnet werden';
  }

  @override
  String logMeasureDetail(int code, int collected, int streamed) {
    return 'FFmpeg wurde mit $code beendet; es gab $collected Zeilen aus, $streamed davon live, und keine Pegel darunter.';
  }

  @override
  String logMeasureFailed(String name) {
    return 'Die Pegel von $name konnten nicht gelesen werden.';
  }

  @override
  String logMeasuring(String name) {
    return 'Pegel von $name werden gemessen...';
  }

  @override
  String get logNoSilenceDetected =>
      'Keine Pausen erkannt, weiter mit dem nächsten.';

  @override
  String logOutputDirError(String path, String error) {
    return 'In $path kann nicht geschrieben werden. $error';
  }

  @override
  String logPreviewReady(String name) {
    return 'Vorschau fertig: $name';
  }

  @override
  String logPreviewTooShort(String name) {
    return '$name ist kürzer als die Vorschaulänge; es wird ganz verwendet.';
  }

  @override
  String get logQueueEmpty => 'Kein Video in der Warteschlange.';

  @override
  String logSilencePercentage(double percentage) {
    final intl.NumberFormat percentageNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 2,
        );
    final String percentageString = percentageNumberFormat.format(percentage);

    return '$percentageString % des Videos als Stille erkannt.';
  }

  @override
  String get logSkipNoSilences =>
      'Analyse fehlgeschlagen, weiter mit dem nächsten.';

  @override
  String logStarted(String name) {
    return 'Bearbeitung von $name begonnen.';
  }

  @override
  String get logStopping => 'Wird angehalten...';

  @override
  String get menuAbout => 'Info';

  @override
  String get menuCleanShell => 'Protokoll leeren';

  @override
  String get menuAdd => 'Hinzufügen';

  @override
  String get menuClearQueue => 'Warteschlange leeren';

  @override
  String get menuDonate => 'Spendier mir einen Kaffee';

  @override
  String get menuHideShell => 'Protokoll ausblenden';

  @override
  String get menuIssue => 'Problem melden';

  @override
  String get menuLicense => 'Lizenz anzeigen';

  @override
  String get menuOpenFile => 'Video(s) hinzufügen';

  @override
  String get menuOpenFolder => 'Ordner hinzufügen';

  @override
  String get menuPrivacy => 'Datenschutzerklärung';

  @override
  String get menuProgress => 'Kompakter Fortschritt';

  @override
  String get menuQuit => 'Beenden';

  @override
  String get menuReferences => 'Links';

  @override
  String get menuShowShell => 'Protokoll anzeigen';

  @override
  String get menuSourceCode => 'Quellcode';

  @override
  String get menuThirdPartyLicenses => 'Lizenzen von Drittanbietern';

  @override
  String get menuUpdate => 'Ein Update ist verfügbar';

  @override
  String menuVersion(String version) {
    return 'Version $version';
  }

  @override
  String get menuWindowMode => 'Zurück zum Fenster';

  @override
  String get navAbout => 'Info';

  @override
  String get navQueue => 'Warteschlange';

  @override
  String get navSection => 'Mehr';

  @override
  String get navSettings => 'App-Einstellungen';

  @override
  String get noiseHigh => 'Hoch';

  @override
  String get noiseLow => 'Niedrig';

  @override
  String get noiseMid => 'Mittel';

  @override
  String get optionKeep => 'Beibehalten';

  @override
  String get optionNone => 'Keine';

  @override
  String get outputAlongsideSource => 'Neben der Quelle';

  @override
  String get outputFixedDirectory => 'Ein Ordner meiner Wahl';

  @override
  String get outputChooseFolder => 'Exportordner wählen';

  @override
  String get outputFolder => 'Exportieren nach';

  @override
  String get preferenceBundledFfmpeg =>
      'FFmpeg ist in der App enthalten: Es gibt keinen Pfad einzurichten.';

  @override
  String get preferenceChooseExportDir =>
      'Wähle, wohin Videos exportiert werden';

  @override
  String get preferenceChangeWorkingDir => 'Ordner ändern';

  @override
  String get preferenceChooseWorkingDir =>
      'Wähle, wo die Zwischenfragmente abgelegt werden';

  @override
  String get preferenceClearTemporary => 'Leeren';

  @override
  String get preferenceExportDir => 'Exportordner';

  @override
  String get preferenceReset => 'Zurücksetzen';

  @override
  String get preferenceSave => 'Speichern';

  @override
  String preferenceTemporaryFiles(String size) {
    return 'Temporäre Dateien: $size';
  }

  @override
  String get preferenceWorkingDir => 'Arbeitsordner';

  @override
  String get preferenceWorkingDirHint =>
      'Hier werden die Zwischenfragmente während eines Durchlaufs geschrieben und danach entfernt. Lege ihn auf ein schnelles Laufwerk mit genug freiem Platz.';

  @override
  String previewSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get processStart => 'Start';

  @override
  String get processStop => 'Stopp';

  @override
  String queueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Videos',
      one: '1 Video',
      zero: 'Keine Videos',
    );
    return '$_temp0';
  }

  @override
  String get settingsAdvanced => 'Erweiterte Einstellungen';

  @override
  String get settingsAudioRate => 'Abtastrate';

  @override
  String get settingsAudioTracks => 'Alle Audiospuren behalten';

  @override
  String get settingsBackgroundNoise => 'Hintergrundrauschen';

  @override
  String get settingsBasic => 'Grundeinstellungen';

  @override
  String get settingsCrf => 'CRF';

  @override
  String get settingsDefault => 'Standard';

  @override
  String get settingsFilterPreview => 'Erkennungsfilter';

  @override
  String get settingsFormat => 'Videoformat';

  @override
  String get settingsFps => 'FPS';

  @override
  String get settingsEncodingHide => 'Kodiereinstellungen ausblenden';

  @override
  String get settingsEncodingShow => 'Kodiereinstellungen anzeigen';

  @override
  String get settingsEncodingTitle => 'Kodiereinstellungen';

  @override
  String get settingsGroupApp => 'Anwendung';

  @override
  String get settingsGroupAudio => 'Audio';

  @override
  String get settingsGroupDetection => 'Pausenerkennung';

  @override
  String get settingsGroupExport => 'Export';

  @override
  String get settingsGroupPreview => 'Vorschau';

  @override
  String get settingsGroupSpeed => 'Tempo';

  @override
  String get settingsMuteSilences => 'Pausen stummschalten';

  @override
  String get settingsNoiseFailed =>
      'Die Pegel dieses Videos konnten nicht gelesen werden. Im Protokoll steht, was FFmpeg geantwortet hat.';

  @override
  String settingsNoiseMeasure(String name) {
    return '$name messen';
  }

  @override
  String settingsNoiseMeasured(String name, int floor, int voice) {
    return '$name: Rauschen bei $floor dB, Stimme bei $voice dB';
  }

  @override
  String settingsNoiseMeasuring(String name) {
    return '$name wird gemessen...';
  }

  @override
  String get settingsNoiseTooClose =>
      'Das Rauschen ist hier fast so laut wie die Stimme, daher trennt kein Schwellenwert die beiden sauber.';

  @override
  String settingsNoiseUse(int db) {
    return 'Empfohlen: $db dB';
  }

  @override
  String settingsNoiseValue(int db) {
    return '$db dB';
  }

  @override
  String get settingsPlaybackSpeed => 'Sprechtempo';

  @override
  String get settingsPreset => 'Preset';

  @override
  String get settingsPreviewDuration => 'Vorschaulänge';

  @override
  String get settingsReset => 'Zurücksetzen';

  @override
  String get settingsResetDone => 'Kodiereinstellungen zurückgesetzt';

  @override
  String get settingsResetProcessing => 'Kodiereinstellungen zurücksetzen';

  @override
  String get settingsResetProcessingHint =>
      'Setzt alle Tempo-, Erkennungs- und Exporteinstellungen auf den Standard zurück.';

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
  String get settingsSilence => 'Pausenerkennung';

  @override
  String get settingsSilenceMargin => 'Pausenrand';

  @override
  String get settingsSilenceMinDuration => 'Mindestdauer der Pause';

  @override
  String get settingsSilenceSpeed => 'Pausentempo';

  @override
  String get settingsSpeedRemove => 'Entfernen';

  @override
  String get settingsSpeedRemoveShort => 'weg';

  @override
  String get settingsTune => 'Tune';

  @override
  String get silencesFit => 'Ganzes Video';

  @override
  String get silencesEmpty => 'In diesem Video wurde keine Stille gefunden.';

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
      other: '$count Pausen',
      one: '1 Pause',
      zero: 'Keine Pausen',
    );
    return '$_temp0';
  }

  @override
  String get silencesRedetect => 'Erneut erkennen';

  @override
  String get silencesReveal => 'Auf der Zeitleiste zeigen';

  @override
  String get silencesSaved => 'Gesparte Zeit';

  @override
  String get silencesShare => 'Anteil an der Quelle';

  @override
  String get silencesStale =>
      'Die Erkennungseinstellungen haben sich geändert, seit diese Pausen gefunden wurden.';

  @override
  String get silencesTitle => 'Erkannte Pausen';

  @override
  String get silencesTotal => 'Stille';

  @override
  String get silencesOutput => 'Geschätztes Ergebnis';

  @override
  String get silencesZoomIn => 'Vergrößern';

  @override
  String get silencesZoomOut => 'Verkleinern';

  @override
  String get statusAnalyzing => 'Pausen werden erkannt...';

  @override
  String get statusCompleted => 'Abgeschlossen';

  @override
  String get statusConcatenating => 'Fragmente werden zusammengefügt...';

  @override
  String get statusExporting => 'Wird exportiert...';

  @override
  String get statusFailed => 'Fehlgeschlagen';

  @override
  String get statusInterrupted => 'Abgebrochen';

  @override
  String statusLoaded(String duration) {
    return 'Geladen [$duration]';
  }

  @override
  String get statusLoading => 'Wird geladen...';

  @override
  String get statusQueued => 'In Warteschlange';

  @override
  String get statusReady => 'Bereit';

  @override
  String statusSilenceShare(double percentage) {
    final intl.NumberFormat percentageNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String percentageString = percentageNumberFormat.format(percentage);

    return '$percentageString % Stille';
  }

  @override
  String get uiCancel => 'Abbrechen';

  @override
  String get uiClose => 'Schließen';

  @override
  String get uiDarkMode => 'Dunkel';

  @override
  String get uiDropVideo => 'Videos hier ablegen';

  @override
  String get uiLanguage => 'Sprache';

  @override
  String get uiLightMode => 'Hell';

  @override
  String get uiSystemMode => 'System';

  @override
  String get uiTheme => 'Design';

  @override
  String updateAvailable(String version) {
    return 'Version $version ist verfügbar.';
  }

  @override
  String get updateDetails => 'Details';

  @override
  String get updateDownload => 'Herunterladen';
}
