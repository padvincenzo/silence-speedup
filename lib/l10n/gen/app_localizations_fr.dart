// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get aboutAiAssisted => 'Écrit avec l\'aide de l\'IA';

  @override
  String get aboutAiNotice =>
      'Une partie du code a été écrite avec un assistant IA, puis relue et maintenue par l\'auteur, qui en est responsable. L\'application elle-même ne contient aucune IA et n\'envoie rien nulle part : les silences sont trouvés en mesurant le niveau audio avec FFmpeg.';

  @override
  String get aboutBuiltWith => 'Réalisé avec Flutter, propulsé par FFmpeg';

  @override
  String get aboutCopyright => 'Copyright (C) 2026 Vincenzo Padula';

  @override
  String get aboutLicenseSection => 'Licence';

  @override
  String get aboutOpenInBrowser => 'S\'ouvre dans votre navigateur';

  @override
  String get appIntro =>
      'Importez des vidéos, choisissez la configuration puis appuyez sur Démarrer pour accélérer (ou supprimer) leurs silences.';

  @override
  String get ffmpegAlreadyRunning =>
      'FFmpeg est encore en cours d\'exécution ; impossible de lancer un autre processus.';

  @override
  String ffmpegDurationError(String name) {
    return 'Impossible de lire la durée de $name.';
  }

  @override
  String get ffmpegSpeed => 'Vitesse';

  @override
  String get ffmpegTime => 'Temps';

  @override
  String get fileAnalyze => 'Mesurer les silences sans exporter';

  @override
  String get fileSilences => 'Afficher les silences détectés';

  @override
  String get fileDialogUnavailable =>
      'La boîte de dialogue de fichiers du système n\'a pas pu s\'ouvrir. Sous Linux, elle est fournie par xdg-desktop-portal.';

  @override
  String get fileOpenDir => 'Sélectionnez un dossier';

  @override
  String get fileOpenFile => 'Sélectionnez une ou plusieurs vidéos';

  @override
  String get filePreview => 'Générer un court extrait d\'aperçu';

  @override
  String get filePreviewSuffix => ' (aperçu)';

  @override
  String get fileRemove => 'Retirer cette vidéo de la liste';

  @override
  String get fileReveal => 'Afficher le fichier exporté';

  @override
  String get helpAudioRate =>
      'Rééchantillonne l\'audio. Conserver le laisse tel quel, ce qui est presque toujours le bon choix.';

  @override
  String get helpAudioTracks =>
      'Reprend toutes les pistes audio de la source dans le fichier final. Les silences restent détectés sur la première piste seulement, celle de la voix dans un enregistrement multipiste.';

  @override
  String get helpBackgroundNoise =>
      'Le niveau sonore de la pièce. Augmentez-le si un léger souffle est pris pour de la parole.';

  @override
  String get helpCredits => 'Crédits';

  @override
  String get helpCrf =>
      'Constant Rate Factor : plus il est bas, meilleure est la qualité et plus le fichier est gros. 23 est une bonne valeur par défaut.';

  @override
  String get helpFfmpegNotice =>
      'FFmpeg est inclus dans cette application sous licence GPLv3. Il n\'y a rien à installer ni à configurer.';

  @override
  String get helpFormat =>
      'Conteneur du fichier exporté. Conserver reprend celui de la source.';

  @override
  String get helpFps =>
      'Fréquence d\'images vers laquelle chaque fragment est normalisé, pour que les morceaux se joignent sans réencodage.';

  @override
  String get helpGplNotice =>
      'Ce programme est fourni sans aucune garantie. C\'est un logiciel libre, et vous pouvez le redistribuer selon les termes de la GNU General Public License version 3 ou ultérieure.';

  @override
  String get helpIcons => 'Icônes';

  @override
  String get helpIconsCredit =>
      'Icônes de creazilla.com sous licence CC BY 4.0.';

  @override
  String get helpIntro =>
      'Raccourcissez vos vidéos en accélérant (ou en supprimant) les silences, avec FFmpeg. Réalisé avec Flutter.';

  @override
  String get helpLanguage =>
      'Suit la langue du système, ou l\'anglais à défaut. Fixez-en une pour la forcer.';

  @override
  String get helpLicense =>
      'Ce programme est fourni sans aucune garantie. C\'est un logiciel libre, et vous pouvez le redistribuer sous certaines conditions ; voir la licence pour les détails.';

  @override
  String get helpMuteSilences =>
      'Coupe le son des passages calmes au lieu de laisser passer le souffle accéléré.';

  @override
  String get helpOutputFolder =>
      'Où une vidéo terminée est écrite. À côté de la source garde chacune dans son dossier ; sinon elles vont toutes dans le dossier choisi.';

  @override
  String get helpPlaybackSpeed =>
      'Vitesse des passages où quelqu\'un parle. Laissez 1x pour garder une voix naturelle.';

  @override
  String get helpPreset =>
      'L\'effort fourni par x264. Les presets plus lents donnent des fichiers plus petits à qualité égale.';

  @override
  String get helpPreviewDuration =>
      'La part de la vidéo qu\'un aperçu échantillonne. Elle est prise au tiers de la durée, là où l\'enregistrement est le plus représentatif.';

  @override
  String get helpReadLicense => 'Lire la licence';

  @override
  String get helpSilenceMargin =>
      'Temps conservé de chaque côté de chaque silence, pour ne pas couper les mots.';

  @override
  String get helpSilenceMinDuration =>
      'Durée minimale d\'une pause pour qu\'elle compte comme un silence.';

  @override
  String get helpSilenceSpeed =>
      'Vitesse des passages calmes. Choisissez Supprimer pour les couper entièrement.';

  @override
  String get helpTheme => 'Suivre le système, ou fixer clair ou sombre.';

  @override
  String get helpTune =>
      'Une indication à x264 sur le type de contenu : Still image pour des diapositives, Film pour des prises de vue.';

  @override
  String licensesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count licences',
      one: '1 licence',
    );
    return '$_temp0';
  }

  @override
  String get licensesEmpty =>
      'Aucune information de licence n\'a été trouvée dans cette build.';

  @override
  String licensesPackages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paquets',
      one: '1 paquet',
    );
    return '$_temp0';
  }

  @override
  String get logAllDone => 'Tout est terminé.';

  @override
  String logAlreadyExists(String name) {
    return 'Impossible de charger $name : ce nom de fichier est déjà dans la file.';
  }

  @override
  String logCompleted(String name) {
    return '$name terminé.';
  }

  @override
  String get logConcatenationError =>
      'Erreur lors de l\'assemblage des fragments.';

  @override
  String get logDataError =>
      'Erreur de données : les bornes des silences ne vont pas par paires.';

  @override
  String logFileMissing(String name) {
    return '$name n\'est plus à son emplacement ; il est ignoré.';
  }

  @override
  String logFilesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers ajoutés.',
      one: '1 fichier ajouté.',
      zero: 'Aucun fichier ajouté.',
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

    return 'Échec de l\'encodage du fragment [$startString - $endString].';
  }

  @override
  String logFragmentsKept(String path) {
    return 'Fragments laissés dans $path pour examen.';
  }

  @override
  String logLinkError(String url) {
    return 'Impossible d\'ouvrir $url';
  }

  @override
  String logMeasureDetail(int code, int collected, int streamed) {
    return 'FFmpeg s\'est terminé avec le code $code ; il a écrit $collected lignes, dont $streamed en direct, et aucun niveau parmi elles.';
  }

  @override
  String logMeasureFailed(String name) {
    return 'Impossible de lire les niveaux de $name.';
  }

  @override
  String logMeasuring(String name) {
    return 'Mesure des niveaux de $name...';
  }

  @override
  String get logNoSilenceDetected =>
      'Aucun silence détecté, passage au suivant.';

  @override
  String logOutputDirError(String path, String error) {
    return 'Impossible d\'écrire dans $path. $error';
  }

  @override
  String logPreviewReady(String name) {
    return 'Aperçu prêt : $name';
  }

  @override
  String logPreviewTooShort(String name) {
    return '$name est plus court que la durée de l\'aperçu ; il est échantillonné en entier.';
  }

  @override
  String get logQueueEmpty => 'Aucune vidéo dans la file.';

  @override
  String logSilencePercentage(double percentage) {
    final intl.NumberFormat percentageNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 2,
        );
    final String percentageString = percentageNumberFormat.format(percentage);

    return '$percentageString % de la vidéo détecté comme silence.';
  }

  @override
  String get logSkipNoSilences => 'Échec de l\'analyse, passage au suivant.';

  @override
  String logStarted(String name) {
    return 'Début du traitement de $name.';
  }

  @override
  String get logStopping => 'Arrêt en cours...';

  @override
  String get menuAbout => 'À propos';

  @override
  String get menuCleanShell => 'Effacer le journal';

  @override
  String get menuAdd => 'Ajouter';

  @override
  String get menuClearQueue => 'Vider la file';

  @override
  String get menuDonate => 'Offrez-moi un café';

  @override
  String get menuHideShell => 'Masquer le journal';

  @override
  String get menuIssue => 'Signaler un problème';

  @override
  String get menuLicense => 'Voir la licence';

  @override
  String get menuOpenFile => 'Ajouter des vidéos';

  @override
  String get menuOpenFolder => 'Ajouter un dossier';

  @override
  String get menuPrivacy => 'Politique de confidentialité';

  @override
  String get menuProgress => 'Progression compacte';

  @override
  String get menuQuit => 'Quitter';

  @override
  String get menuReferences => 'Liens';

  @override
  String get menuShowShell => 'Afficher le journal';

  @override
  String get menuSourceCode => 'Code source';

  @override
  String get menuThirdPartyLicenses => 'Licences tierces';

  @override
  String get menuUpdate => 'Une mise à jour est disponible';

  @override
  String menuVersion(String version) {
    return 'Version $version';
  }

  @override
  String get menuWindowMode => 'Retour à la fenêtre';

  @override
  String get navAbout => 'À propos';

  @override
  String get navQueue => 'File';

  @override
  String get navSection => 'Plus';

  @override
  String get navSettings => 'Paramètres de l\'app';

  @override
  String get noiseHigh => 'Élevé';

  @override
  String get noiseLow => 'Faible';

  @override
  String get noiseMid => 'Moyen';

  @override
  String get optionKeep => 'Conserver';

  @override
  String get optionNone => 'Aucun';

  @override
  String get outputAlongsideSource => 'À côté de la source';

  @override
  String get outputFixedDirectory => 'Un dossier choisi';

  @override
  String get outputChooseFolder => 'Choisir le dossier d\'export';

  @override
  String get outputFolder => 'Exporter vers';

  @override
  String get preferenceBundledFfmpeg =>
      'FFmpeg est inclus dans l\'application : il n\'y a aucun chemin à configurer.';

  @override
  String get preferenceChooseExportDir => 'Choisissez où exporter les vidéos';

  @override
  String get preferenceChangeWorkingDir => 'Changer de dossier';

  @override
  String get preferenceChooseWorkingDir =>
      'Choisissez où garder les fragments intermédiaires';

  @override
  String get preferenceClearTemporary => 'Vider';

  @override
  String get preferenceExportDir => 'Dossier d\'export';

  @override
  String get preferenceReset => 'Réinitialiser';

  @override
  String get preferenceSave => 'Enregistrer';

  @override
  String preferenceTemporaryFiles(String size) {
    return 'Fichiers temporaires : $size';
  }

  @override
  String get preferenceWorkingDir => 'Dossier de travail';

  @override
  String get preferenceWorkingDirHint =>
      'Les fragments intermédiaires sont écrits ici pendant un traitement, puis supprimés. Placez-le sur un disque rapide avec de l\'espace libre.';

  @override
  String previewSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get processStart => 'Démarrer';

  @override
  String get processStop => 'Arrêter';

  @override
  String queueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vidéos',
      one: '1 vidéo',
      zero: 'Aucune vidéo',
    );
    return '$_temp0';
  }

  @override
  String get settingsAdvanced => 'Paramètres avancés';

  @override
  String get settingsAudioRate => 'Fréquence audio';

  @override
  String get settingsAudioTracks => 'Garder toutes les pistes audio';

  @override
  String get settingsBackgroundNoise => 'Bruit de fond';

  @override
  String get settingsBasic => 'Paramètres de base';

  @override
  String get settingsCrf => 'CRF';

  @override
  String get settingsDefault => 'Par défaut';

  @override
  String get settingsFilterPreview => 'Filtre de détection';

  @override
  String get settingsFormat => 'Format vidéo';

  @override
  String get settingsFps => 'FPS';

  @override
  String get settingsEncodingHide => 'Masquer les paramètres d\'encodage';

  @override
  String get settingsEncodingShow => 'Afficher les paramètres d\'encodage';

  @override
  String get settingsEncodingTitle => 'Paramètres d\'encodage';

  @override
  String get settingsGroupApp => 'Application';

  @override
  String get settingsGroupAudio => 'Audio';

  @override
  String get settingsGroupDetection => 'Détection des silences';

  @override
  String get settingsGroupExport => 'Export';

  @override
  String get settingsGroupPreview => 'Aperçu';

  @override
  String get settingsGroupSpeed => 'Vitesse';

  @override
  String get settingsMuteSilences => 'Couper le son des silences';

  @override
  String get settingsNoiseFailed =>
      'Impossible de lire les niveaux de cette vidéo. Le journal indique ce que FFmpeg a répondu.';

  @override
  String settingsNoiseMeasure(String name) {
    return 'Mesurer $name';
  }

  @override
  String settingsNoiseMeasured(String name, int floor, int voice) {
    return '$name : souffle à $floor dB, voix à $voice dB';
  }

  @override
  String settingsNoiseMeasuring(String name) {
    return 'Mesure de $name...';
  }

  @override
  String get settingsNoiseTooClose =>
      'Ici le souffle est presque aussi fort que la voix, donc aucun seuil ne les sépare nettement.';

  @override
  String settingsNoiseUse(int db) {
    return 'Suggéré : $db dB';
  }

  @override
  String settingsNoiseValue(int db) {
    return '$db dB';
  }

  @override
  String get settingsPlaybackSpeed => 'Vitesse de la parole';

  @override
  String get settingsPreset => 'Preset';

  @override
  String get settingsPreviewDuration => 'Durée de l\'aperçu';

  @override
  String get settingsReset => 'Réinitialiser';

  @override
  String get settingsResetDone => 'Paramètres d\'encodage réinitialisés';

  @override
  String get settingsResetProcessing =>
      'Réinitialiser les paramètres d\'encodage';

  @override
  String get settingsResetProcessingHint =>
      'Remet chaque paramètre de vitesse, de détection et d\'export à sa valeur par défaut.';

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
  String get settingsSilence => 'Détection des silences';

  @override
  String get settingsSilenceMargin => 'Marge des silences';

  @override
  String get settingsSilenceMinDuration => 'Durée min. des silences';

  @override
  String get settingsSilenceSpeed => 'Vitesse des silences';

  @override
  String get settingsSpeedRemove => 'Supprimer';

  @override
  String get settingsSpeedRemoveShort => 'coupé';

  @override
  String get settingsTune => 'Optimisation';

  @override
  String get silencesFit => 'Toute la vidéo';

  @override
  String get silencesEmpty => 'Aucun silence n\'a été trouvé dans cette vidéo.';

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
      other: '$count silences',
      one: '1 silence',
      zero: 'Aucun silence',
    );
    return '$_temp0';
  }

  @override
  String get silencesRedetect => 'Détecter à nouveau';

  @override
  String get silencesReveal => 'Le montrer sur la timeline';

  @override
  String get silencesSaved => 'Temps gagné';

  @override
  String get silencesShare => 'De la source';

  @override
  String get silencesStale =>
      'Les paramètres de détection ont changé depuis que ces silences ont été trouvés.';

  @override
  String get silencesTitle => 'Silences détectés';

  @override
  String get silencesTotal => 'Silence';

  @override
  String get silencesOutput => 'Résultat estimé';

  @override
  String get silencesZoomIn => 'Zoom avant';

  @override
  String get silencesZoomOut => 'Zoom arrière';

  @override
  String get statusAnalyzing => 'Détection des silences...';

  @override
  String get statusCompleted => 'Terminé';

  @override
  String get statusConcatenating => 'Assemblage des fragments...';

  @override
  String get statusExporting => 'Export en cours...';

  @override
  String get statusFailed => 'Échec';

  @override
  String get statusInterrupted => 'Interrompu';

  @override
  String statusLoaded(String duration) {
    return 'Chargé [$duration]';
  }

  @override
  String get statusLoading => 'Chargement...';

  @override
  String get statusQueued => 'En attente';

  @override
  String get statusReady => 'Prêt';

  @override
  String statusSilenceShare(double percentage) {
    final intl.NumberFormat percentageNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String percentageString = percentageNumberFormat.format(percentage);

    return '$percentageString % de silence';
  }

  @override
  String get uiCancel => 'Annuler';

  @override
  String get uiClose => 'Fermer';

  @override
  String get uiDarkMode => 'Sombre';

  @override
  String get uiDropVideo => 'Déposez des vidéos ici';

  @override
  String get uiLanguage => 'Langue';

  @override
  String get uiLightMode => 'Clair';

  @override
  String get uiSystemMode => 'Système';

  @override
  String get uiTheme => 'Thème';

  @override
  String updateAvailable(String version) {
    return 'La version $version est disponible.';
  }

  @override
  String get updateDetails => 'Détails';

  @override
  String get updateDownload => 'Télécharger';
}
