// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get aboutAiAssisted => 'Escrita con ayuda de IA';

  @override
  String get aboutAiNotice =>
      'Partes del código se escribieron con un asistente de IA y luego el autor, que es su responsable, las revisó y las mantiene. La app en sí no contiene IA y no envía nada a ningún sitio: los silencios se encuentran midiendo el nivel de audio con FFmpeg.';

  @override
  String get aboutBuiltWith => 'Hecha con Flutter, basada en FFmpeg';

  @override
  String get aboutCopyright => 'Copyright (C) 2026 Vincenzo Padula';

  @override
  String get aboutLicenseSection => 'Licencia';

  @override
  String get aboutOpenInBrowser => 'Se abre en el navegador';

  @override
  String get appIntro =>
      'Importa algunos videos, elige la configuración y pulsa Iniciar para acelerar (o eliminar) sus silencios.';

  @override
  String get ffmpegAlreadyRunning =>
      'FFmpeg sigue en ejecución; no se puede iniciar otro proceso.';

  @override
  String ffmpegDurationError(String name) {
    return 'No se pudo leer la duración de $name.';
  }

  @override
  String get ffmpegSpeed => 'Velocidad';

  @override
  String get ffmpegTime => 'Tiempo';

  @override
  String get fileAnalyze => 'Medir los silencios sin exportar';

  @override
  String get fileSilences => 'Mostrar los silencios detectados';

  @override
  String get fileDialogUnavailable =>
      'No se pudo abrir el selector de archivos del sistema. En Linux lo proporciona xdg-desktop-portal.';

  @override
  String get fileOpenDir => 'Selecciona una carpeta';

  @override
  String get fileOpenFile => 'Selecciona uno o más videos';

  @override
  String get filePreview => 'Generar una breve muestra de vista previa';

  @override
  String get filePreviewSuffix => ' (vista previa)';

  @override
  String get fileRemove => 'Quitar este video de la lista';

  @override
  String get fileReveal => 'Mostrar el archivo exportado';

  @override
  String get helpAudioRate =>
      'Remuestrea el audio. Mantener lo deja exactamente como está, que casi siempre es lo correcto.';

  @override
  String get helpAudioTracks =>
      'Lleva a la salida todas las pistas de audio del original. Los silencios se siguen detectando solo en la primera pista, que en una grabación multipista es la de la voz.';

  @override
  String get helpBackgroundNoise =>
      'Cuánto ruido hay en el ambiente. Súbelo si un leve siseo se confunde con habla.';

  @override
  String get helpCredits => 'Créditos';

  @override
  String get helpCrf =>
      'Constant Rate Factor: más bajo significa mejor calidad y un archivo más grande. 23 es un buen valor.';

  @override
  String get helpFfmpegNotice =>
      'FFmpeg viene incluido en esta app bajo la licencia GPLv3. No hay nada que instalar ni configurar.';

  @override
  String get helpFormat =>
      'Contenedor del archivo exportado. Mantener reutiliza el del original.';

  @override
  String get helpFps =>
      'Frecuencia de fotogramas a la que se normaliza cada fragmento, para unir las partes sin recodificar.';

  @override
  String get helpGplNotice =>
      'Este programa no ofrece ninguna garantía. Es software libre y puedes redistribuirlo bajo las condiciones de la GNU General Public License versión 3 o posterior.';

  @override
  String get helpIcons => 'Iconos';

  @override
  String get helpIconsCredit =>
      'Iconos de creazilla.com bajo la licencia CC BY 4.0.';

  @override
  String get helpIntro =>
      'Acelera tus videos acelerando (o eliminando) los silencios, con FFmpeg. Hecha con Flutter.';

  @override
  String get helpLanguage =>
      'Sigue el idioma del sistema; si no está disponible, usa el inglés. Fija uno para cambiarlo.';

  @override
  String get helpLicense =>
      'Este programa no ofrece ninguna garantía. Es software libre y puedes redistribuirlo bajo ciertas condiciones; consulta la licencia para más detalles.';

  @override
  String get helpMuteSilences =>
      'Silencia el audio de las partes sin voz en lugar de dejar pasar el siseo acelerado.';

  @override
  String get helpOutputFolder =>
      'Dónde se guarda el video terminado. Junto al original deja cada uno en su carpeta; si no, van todos a la carpeta que elijas.';

  @override
  String get helpPlaybackSpeed =>
      'Velocidad de las partes en las que alguien habla. Déjala en 1x para que la voz suene natural.';

  @override
  String get helpPreset =>
      'Cuánto trabaja x264. Los presets más lentos dan archivos más pequeños con la misma calidad.';

  @override
  String get helpPreviewDuration =>
      'Cuánto del video toma la vista previa. Se toma a un tercio de la duración, donde la grabación es más representativa.';

  @override
  String get helpReadLicense => 'Leer la licencia';

  @override
  String get helpSilenceMargin =>
      'Tiempo que se conserva a cada lado de cada silencio, para no cortar palabras.';

  @override
  String get helpSilenceMinDuration =>
      'Cuánto debe durar una pausa para contar como silencio.';

  @override
  String get helpSilenceSpeed =>
      'Velocidad de las partes sin voz. Elige Eliminar para quitarlas por completo.';

  @override
  String get helpTheme => 'Sigue al sistema, o fija el tema claro u oscuro.';

  @override
  String get helpTune =>
      'Una pista para x264 sobre el tipo de contenido: Still image para diapositivas, Film para grabaciones de cámara.';

  @override
  String licensesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count licencias',
      one: '1 licencia',
    );
    return '$_temp0';
  }

  @override
  String get licensesEmpty =>
      'No se encontró información de licencias en esta compilación.';

  @override
  String licensesPackages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paquetes',
      one: '1 paquete',
    );
    return '$_temp0';
  }

  @override
  String get logAllDone => 'Todo listo.';

  @override
  String logAlreadyExists(String name) {
    return 'No se puede cargar $name: ese nombre de archivo ya está en la cola.';
  }

  @override
  String logCompleted(String name) {
    return '$name completado.';
  }

  @override
  String get logConcatenationError => 'Error al unir los fragmentos.';

  @override
  String get logDataError =>
      'Error de datos: los límites de los silencios no se emparejan.';

  @override
  String logFileMissing(String name) {
    return '$name ya no está donde estaba; se omite.';
  }

  @override
  String logFilesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos añadidos.',
      one: '1 archivo añadido.',
      zero: 'No se añadió ningún archivo.',
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

    return 'No se pudo codificar el fragmento [$startString - $endString].';
  }

  @override
  String logFragmentsKept(String path) {
    return 'Fragmentos conservados en $path para revisarlos.';
  }

  @override
  String logLinkError(String url) {
    return 'No se pudo abrir $url';
  }

  @override
  String logMeasureDetail(int code, int collected, int streamed) {
    return 'FFmpeg terminó con $code; imprimió $collected líneas, $streamed de ellas en directo, y ningún nivel entre ellas.';
  }

  @override
  String logMeasureFailed(String name) {
    return 'No se pudieron leer los niveles de $name.';
  }

  @override
  String logMeasuring(String name) {
    return 'Midiendo los niveles de $name...';
  }

  @override
  String get logNoSilenceDetected =>
      'No se detectaron silencios, se pasa al siguiente.';

  @override
  String logOutputDirError(String path, String error) {
    return 'No se puede escribir en $path. $error';
  }

  @override
  String logPreviewReady(String name) {
    return 'Vista previa lista: $name';
  }

  @override
  String logPreviewTooShort(String name) {
    return '$name es más corto que la vista previa; se toma entero.';
  }

  @override
  String get logQueueEmpty => 'No hay videos en la cola.';

  @override
  String logSilencePercentage(double percentage) {
    final intl.NumberFormat percentageNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 2,
        );
    final String percentageString = percentageNumberFormat.format(percentage);

    return 'El $percentageString % del video se detectó como silencio.';
  }

  @override
  String get logSkipNoSilences => 'El análisis falló, se pasa al siguiente.';

  @override
  String logStarted(String name) {
    return 'Procesando $name.';
  }

  @override
  String get logStopping => 'Deteniendo...';

  @override
  String get menuAbout => 'Acerca de';

  @override
  String get menuCleanShell => 'Vaciar registro';

  @override
  String get menuAdd => 'Añadir';

  @override
  String get menuClearQueue => 'Vaciar la cola';

  @override
  String get menuDonate => 'Invítame a un café';

  @override
  String get menuHideShell => 'Ocultar registro';

  @override
  String get menuIssue => 'Informar de un problema';

  @override
  String get menuLicense => 'Ver licencia';

  @override
  String get menuOpenFile => 'Añadir videos';

  @override
  String get menuOpenFolder => 'Añadir carpeta';

  @override
  String get menuPrivacy => 'Política de privacidad';

  @override
  String get menuProgress => 'Progreso compacto';

  @override
  String get menuQuit => 'Salir';

  @override
  String get menuReferences => 'Enlaces';

  @override
  String get menuShowShell => 'Mostrar registro';

  @override
  String get menuSourceCode => 'Código fuente';

  @override
  String get menuThirdPartyLicenses => 'Licencias de terceros';

  @override
  String get menuUpdate => 'Hay una actualización disponible';

  @override
  String menuVersion(String version) {
    return 'Versión $version';
  }

  @override
  String get menuWindowMode => 'Volver a la ventana';

  @override
  String get navAbout => 'Acerca de';

  @override
  String get navQueue => 'Cola';

  @override
  String get navSection => 'Más';

  @override
  String get navSettings => 'Configuración de la app';

  @override
  String get noiseHigh => 'Alto';

  @override
  String get noiseLow => 'Bajo';

  @override
  String get noiseMid => 'Medio';

  @override
  String get optionKeep => 'Mantener';

  @override
  String get optionNone => 'Ninguno';

  @override
  String get outputAlongsideSource => 'Junto al original';

  @override
  String get outputFixedDirectory => 'Una carpeta que elija';

  @override
  String get outputChooseFolder => 'Elegir la carpeta de exportación';

  @override
  String get outputFolder => 'Exportar a';

  @override
  String get preferenceBundledFfmpeg =>
      'FFmpeg viene incluido en la app: no hay ninguna ruta que configurar.';

  @override
  String get preferenceChooseExportDir =>
      'Selecciona dónde exportar los videos';

  @override
  String get preferenceChangeWorkingDir => 'Cambiar carpeta';

  @override
  String get preferenceChooseWorkingDir =>
      'Selecciona dónde guardar los fragmentos intermedios';

  @override
  String get preferenceClearTemporary => 'Vaciar';

  @override
  String get preferenceExportDir => 'Carpeta de exportación';

  @override
  String get preferenceReset => 'Restablecer';

  @override
  String get preferenceSave => 'Guardar';

  @override
  String preferenceTemporaryFiles(String size) {
    return 'Archivos temporales: $size';
  }

  @override
  String get preferenceWorkingDir => 'Carpeta de trabajo';

  @override
  String get preferenceWorkingDirHint =>
      'Los fragmentos intermedios se escriben aquí durante el procesamiento y luego se eliminan. Ponla en un disco rápido y con espacio de sobra.';

  @override
  String previewSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get processStart => 'Iniciar';

  @override
  String get processStop => 'Detener';

  @override
  String queueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count videos',
      one: '1 video',
      zero: 'Ningún video',
    );
    return '$_temp0';
  }

  @override
  String get settingsAdvanced => 'Configuración avanzada';

  @override
  String get settingsAudioRate => 'Frecuencia de audio';

  @override
  String get settingsAudioTracks => 'Mantener todas las pistas de audio';

  @override
  String get settingsBackgroundNoise => 'Ruido de fondo';

  @override
  String get settingsBasic => 'Configuración básica';

  @override
  String get settingsCrf => 'CRF';

  @override
  String get settingsDefault => 'Predeterminado';

  @override
  String get settingsFilterPreview => 'Filtro de detección';

  @override
  String get settingsFormat => 'Formato de video';

  @override
  String get settingsFps => 'FPS';

  @override
  String get settingsEncodingHide => 'Ocultar la configuración de codificación';

  @override
  String get settingsEncodingShow => 'Mostrar la configuración de codificación';

  @override
  String get settingsEncodingTitle => 'Configuración de codificación';

  @override
  String get settingsGroupApp => 'Aplicación';

  @override
  String get settingsGroupAudio => 'Audio';

  @override
  String get settingsGroupDetection => 'Detección de silencios';

  @override
  String get settingsGroupExport => 'Exportación';

  @override
  String get settingsGroupPreview => 'Vista previa';

  @override
  String get settingsGroupSpeed => 'Velocidad';

  @override
  String get settingsMuteSilences => 'Silenciar las pausas';

  @override
  String get settingsNoiseFailed =>
      'No se pudieron leer los niveles de este video. El registro muestra lo que respondió FFmpeg.';

  @override
  String settingsNoiseMeasure(String name) {
    return 'Medir $name';
  }

  @override
  String settingsNoiseMeasured(String name, int floor, int voice) {
    return '$name: siseo a $floor dB, voz a $voice dB';
  }

  @override
  String settingsNoiseMeasuring(String name) {
    return 'Midiendo $name...';
  }

  @override
  String get settingsNoiseTooClose =>
      'Aquí el siseo es casi tan fuerte como la voz, así que ningún umbral los separa limpiamente.';

  @override
  String settingsNoiseUse(int db) {
    return 'Sugerido: $db dB';
  }

  @override
  String settingsNoiseValue(int db) {
    return '$db dB';
  }

  @override
  String get settingsPlaybackSpeed => 'Velocidad del habla';

  @override
  String get settingsPreset => 'Preset';

  @override
  String get settingsPreviewDuration => 'Duración de la vista previa';

  @override
  String get settingsReset => 'Restablecer';

  @override
  String get settingsResetDone => 'Configuración de codificación restablecida';

  @override
  String get settingsResetProcessing =>
      'Restablecer la configuración de codificación';

  @override
  String get settingsResetProcessingHint =>
      'Devuelve a su valor predeterminado cada ajuste de velocidad, detección y exportación.';

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
  String get settingsSilence => 'Detección de silencios';

  @override
  String get settingsSilenceMargin => 'Margen de silencio';

  @override
  String get settingsSilenceMinDuration => 'Duración mínima del silencio';

  @override
  String get settingsSilenceSpeed => 'Velocidad del silencio';

  @override
  String get settingsSpeedRemove => 'Eliminar';

  @override
  String get settingsSpeedRemoveShort => 'fuera';

  @override
  String get settingsTune => 'Tune';

  @override
  String get silencesFit => 'Todo el video';

  @override
  String get silencesEmpty => 'No se encontraron silencios en este video.';

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
      other: '$count silencios',
      one: '1 silencio',
      zero: 'Ningún silencio',
    );
    return '$_temp0';
  }

  @override
  String get silencesRedetect => 'Detectar de nuevo';

  @override
  String get silencesReveal => 'Mostrarlo en la línea de tiempo';

  @override
  String get silencesSaved => 'Tiempo ahorrado';

  @override
  String get silencesShare => 'Del original';

  @override
  String get silencesStale =>
      'La configuración de detección cambió después de encontrar estos silencios.';

  @override
  String get silencesTitle => 'Silencios detectados';

  @override
  String get silencesTotal => 'Silencio';

  @override
  String get silencesOutput => 'Resultado estimado';

  @override
  String get silencesZoomIn => 'Acercar';

  @override
  String get silencesZoomOut => 'Alejar';

  @override
  String get statusAnalyzing => 'Detectando silencios...';

  @override
  String get statusCompleted => 'Completado';

  @override
  String get statusConcatenating => 'Uniendo fragmentos...';

  @override
  String get statusExporting => 'Exportando...';

  @override
  String get statusFailed => 'Error';

  @override
  String get statusInterrupted => 'Interrumpido';

  @override
  String statusLoaded(String duration) {
    return 'Cargado [$duration]';
  }

  @override
  String get statusLoading => 'Cargando...';

  @override
  String get statusQueued => 'En cola';

  @override
  String get statusReady => 'Listo';

  @override
  String statusSilenceShare(double percentage) {
    final intl.NumberFormat percentageNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String percentageString = percentageNumberFormat.format(percentage);

    return '$percentageString % de silencio';
  }

  @override
  String get uiCancel => 'Cancelar';

  @override
  String get uiClose => 'Cerrar';

  @override
  String get uiDarkMode => 'Oscuro';

  @override
  String get uiDropVideo => 'Suelta los videos aquí';

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
    return 'La versión $version está disponible.';
  }

  @override
  String get updateDetails => 'Detalles';

  @override
  String get updateDownload => 'Descargar';
}
