import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
  ];

  /// No description provided for @aboutAiAssisted.
  ///
  /// In en, this message translates to:
  /// **'Written with AI assistance'**
  String get aboutAiAssisted;

  /// No description provided for @aboutAiNotice.
  ///
  /// In en, this message translates to:
  /// **'Parts of the code were written with an AI assistant, then reviewed and maintained by the author, who is responsible for it. The app itself contains no AI and sends nothing anywhere: silences are found by measuring the audio level with FFmpeg.'**
  String get aboutAiNotice;

  /// No description provided for @aboutBuiltWith.
  ///
  /// In en, this message translates to:
  /// **'Built with Flutter, powered by FFmpeg'**
  String get aboutBuiltWith;

  /// No description provided for @aboutCopyright.
  ///
  /// In en, this message translates to:
  /// **'Copyright (C) 2026 Vincenzo Padula'**
  String get aboutCopyright;

  /// No description provided for @aboutLicenseSection.
  ///
  /// In en, this message translates to:
  /// **'Licence'**
  String get aboutLicenseSection;

  /// No description provided for @aboutOpenInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Opens in your browser'**
  String get aboutOpenInBrowser;

  /// No description provided for @appIntro.
  ///
  /// In en, this message translates to:
  /// **'Import some videos, choose the configuration and then press Start to speed up (or remove) their silences.'**
  String get appIntro;

  /// No description provided for @ffmpegAlreadyRunning.
  ///
  /// In en, this message translates to:
  /// **'FFmpeg is still running; cannot start another process.'**
  String get ffmpegAlreadyRunning;

  /// No description provided for @ffmpegDurationError.
  ///
  /// In en, this message translates to:
  /// **'Could not read the duration of {name}.'**
  String ffmpegDurationError(String name);

  /// No description provided for @ffmpegSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get ffmpegSpeed;

  /// No description provided for @ffmpegTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get ffmpegTime;

  /// No description provided for @fileAnalyze.
  ///
  /// In en, this message translates to:
  /// **'Measure the silences without exporting'**
  String get fileAnalyze;

  /// No description provided for @fileSilences.
  ///
  /// In en, this message translates to:
  /// **'Show the detected silences'**
  String get fileSilences;

  /// No description provided for @fileOpenDir.
  ///
  /// In en, this message translates to:
  /// **'Select a folder'**
  String get fileOpenDir;

  /// No description provided for @fileOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Select one or more videos'**
  String get fileOpenFile;

  /// No description provided for @filePreview.
  ///
  /// In en, this message translates to:
  /// **'Generate a short preview sample'**
  String get filePreview;

  /// No description provided for @filePreviewSuffix.
  ///
  /// In en, this message translates to:
  /// **' (preview)'**
  String get filePreviewSuffix;

  /// No description provided for @fileRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove this video from the list'**
  String get fileRemove;

  /// No description provided for @fileReveal.
  ///
  /// In en, this message translates to:
  /// **'Show the exported file'**
  String get fileReveal;

  /// No description provided for @helpAudioRate.
  ///
  /// In en, this message translates to:
  /// **'Resample the audio. Keep leaves it exactly as it is, which is almost always right.'**
  String get helpAudioRate;

  /// No description provided for @helpAudioTracks.
  ///
  /// In en, this message translates to:
  /// **'Carry every audio track of the source into the output. Silences are still detected on the first track only, which is the voice track in a multi-track recording.'**
  String get helpAudioTracks;

  /// No description provided for @helpBackgroundNoise.
  ///
  /// In en, this message translates to:
  /// **'How loud the room is. Raise it when a quiet hiss is being mistaken for speech.'**
  String get helpBackgroundNoise;

  /// No description provided for @helpCredits.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get helpCredits;

  /// No description provided for @helpCrf.
  ///
  /// In en, this message translates to:
  /// **'Constant Rate Factor: lower means better quality and a bigger file. 23 is a good default.'**
  String get helpCrf;

  /// No description provided for @helpFfmpegNotice.
  ///
  /// In en, this message translates to:
  /// **'FFmpeg is bundled with this app under the GPLv3 licence. There is nothing to install or configure.'**
  String get helpFfmpegNotice;

  /// No description provided for @helpFormat.
  ///
  /// In en, this message translates to:
  /// **'Container for the exported file. Keep reuses the source container.'**
  String get helpFormat;

  /// No description provided for @helpFps.
  ///
  /// In en, this message translates to:
  /// **'Frame rate every fragment is normalised to, so the pieces can be joined without re-encoding.'**
  String get helpFps;

  /// No description provided for @helpGplNotice.
  ///
  /// In en, this message translates to:
  /// **'This program comes with absolutely no warranty. It is free software, and you are welcome to redistribute it under the conditions of the GNU General Public License version 3 or later.'**
  String get helpGplNotice;

  /// No description provided for @helpIcons.
  ///
  /// In en, this message translates to:
  /// **'Icons'**
  String get helpIcons;

  /// No description provided for @helpIconsCredit.
  ///
  /// In en, this message translates to:
  /// **'Icons from creazilla.com under the CC BY 4.0 licence.'**
  String get helpIconsCredit;

  /// No description provided for @helpIntro.
  ///
  /// In en, this message translates to:
  /// **'Speed up your videos by speeding up (or removing) silences, using FFmpeg. Built with Flutter.'**
  String get helpIntro;

  /// No description provided for @helpLanguage.
  ///
  /// In en, this message translates to:
  /// **'Follows the system language, falling back to English. Pin one to override it.'**
  String get helpLanguage;

  /// No description provided for @helpLicense.
  ///
  /// In en, this message translates to:
  /// **'This program comes with absolutely no warranty. It is free software, and you are welcome to redistribute it under certain conditions; see the licence for details.'**
  String get helpLicense;

  /// No description provided for @helpMuteSilences.
  ///
  /// In en, this message translates to:
  /// **'Silence the audio of the quiet parts instead of letting the sped-up hiss through.'**
  String get helpMuteSilences;

  /// No description provided for @helpOutputFolder.
  ///
  /// In en, this message translates to:
  /// **'Where a finished video is written. Beside its source keeps each one in its own folder; otherwise they all go to the folder you choose.'**
  String get helpOutputFolder;

  /// No description provided for @helpPlaybackSpeed.
  ///
  /// In en, this message translates to:
  /// **'Rate for the parts where someone is speaking. Leave at 1x to keep speech natural.'**
  String get helpPlaybackSpeed;

  /// No description provided for @helpPreset.
  ///
  /// In en, this message translates to:
  /// **'How hard x264 works. Slower presets give smaller files for the same quality.'**
  String get helpPreset;

  /// No description provided for @helpPreviewDuration.
  ///
  /// In en, this message translates to:
  /// **'How much of the video a preview samples. It is taken from a third of the way in, where the recording is most representative.'**
  String get helpPreviewDuration;

  /// No description provided for @helpReadLicense.
  ///
  /// In en, this message translates to:
  /// **'Read the licence'**
  String get helpReadLicense;

  /// No description provided for @helpSilenceMargin.
  ///
  /// In en, this message translates to:
  /// **'Time kept on each side of every silence, so words are not clipped.'**
  String get helpSilenceMargin;

  /// No description provided for @helpSilenceMinDuration.
  ///
  /// In en, this message translates to:
  /// **'How long a pause must last before it counts as silence.'**
  String get helpSilenceMinDuration;

  /// No description provided for @helpSilenceSpeed.
  ///
  /// In en, this message translates to:
  /// **'Rate for the quiet parts. Pick Remove to cut them out entirely.'**
  String get helpSilenceSpeed;

  /// No description provided for @helpTheme.
  ///
  /// In en, this message translates to:
  /// **'Follow the system, or pin light or dark.'**
  String get helpTheme;

  /// No description provided for @helpTune.
  ///
  /// In en, this message translates to:
  /// **'A hint to x264 about the kind of content: Still image for slides, Film for camera footage.'**
  String get helpTune;

  /// No description provided for @licensesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 licence} other{{count} licences}}'**
  String licensesCount(int count);

  /// No description provided for @licensesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No licence information was found in this build.'**
  String get licensesEmpty;

  /// No description provided for @licensesPackages.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 package} other{{count} packages}}'**
  String licensesPackages(int count);

  /// No description provided for @logAllDone.
  ///
  /// In en, this message translates to:
  /// **'All done.'**
  String get logAllDone;

  /// No description provided for @logAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Cannot load {name}: that file name is already queued.'**
  String logAlreadyExists(String name);

  /// No description provided for @logCompleted.
  ///
  /// In en, this message translates to:
  /// **'{name} completed.'**
  String logCompleted(String name);

  /// No description provided for @logConcatenationError.
  ///
  /// In en, this message translates to:
  /// **'Error while joining the fragments.'**
  String get logConcatenationError;

  /// No description provided for @logDataError.
  ///
  /// In en, this message translates to:
  /// **'Data error: silence boundaries do not pair up.'**
  String get logDataError;

  /// No description provided for @logFileMissing.
  ///
  /// In en, this message translates to:
  /// **'{name} is no longer where it was; skipping it.'**
  String logFileMissing(String name);

  /// No description provided for @logFilesAdded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No files added.} =1{1 file added.} other{{count} files added.}}'**
  String logFilesAdded(int count);

  /// No description provided for @logFragmentError.
  ///
  /// In en, this message translates to:
  /// **'Fragment [{start} - {end}] failed to encode.'**
  String logFragmentError(double start, double end);

  /// No description provided for @logFragmentsKept.
  ///
  /// In en, this message translates to:
  /// **'Fragments left in {path} for inspection.'**
  String logFragmentsKept(String path);

  /// No description provided for @logLinkError.
  ///
  /// In en, this message translates to:
  /// **'Could not open {url}'**
  String logLinkError(String url);

  /// No description provided for @logMeasureDetail.
  ///
  /// In en, this message translates to:
  /// **'FFmpeg exited {code}; it printed {collected} lines, {streamed} of them live, and no levels among them.'**
  String logMeasureDetail(int code, int collected, int streamed);

  /// No description provided for @logMeasureFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read the levels of {name}.'**
  String logMeasureFailed(String name);

  /// No description provided for @logMeasuring.
  ///
  /// In en, this message translates to:
  /// **'Measuring the levels of {name}...'**
  String logMeasuring(String name);

  /// No description provided for @logNoSilenceDetected.
  ///
  /// In en, this message translates to:
  /// **'No silences detected, moving on to the next.'**
  String get logNoSilenceDetected;

  /// No description provided for @logOutputDirError.
  ///
  /// In en, this message translates to:
  /// **'Cannot write to {path}. {error}'**
  String logOutputDirError(String path, String error);

  /// No description provided for @logPreviewReady.
  ///
  /// In en, this message translates to:
  /// **'Preview ready: {name}'**
  String logPreviewReady(String name);

  /// No description provided for @logPreviewTooShort.
  ///
  /// In en, this message translates to:
  /// **'{name} is shorter than the preview length; sampling all of it.'**
  String logPreviewTooShort(String name);

  /// No description provided for @logQueueEmpty.
  ///
  /// In en, this message translates to:
  /// **'No video queued.'**
  String get logQueueEmpty;

  /// No description provided for @logSilencePercentage.
  ///
  /// In en, this message translates to:
  /// **'{percentage} % of the video detected as silence.'**
  String logSilencePercentage(double percentage);

  /// No description provided for @logSkipNoSilences.
  ///
  /// In en, this message translates to:
  /// **'Analysis failed, moving on to the next.'**
  String get logSkipNoSilences;

  /// No description provided for @logStarted.
  ///
  /// In en, this message translates to:
  /// **'Started working on {name}.'**
  String logStarted(String name);

  /// No description provided for @logStopping.
  ///
  /// In en, this message translates to:
  /// **'Stopping...'**
  String get logStopping;

  /// No description provided for @menuAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get menuAbout;

  /// No description provided for @menuCleanShell.
  ///
  /// In en, this message translates to:
  /// **'Clear log'**
  String get menuCleanShell;

  /// No description provided for @menuAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get menuAdd;

  /// No description provided for @menuClearQueue.
  ///
  /// In en, this message translates to:
  /// **'Clear queue'**
  String get menuClearQueue;

  /// No description provided for @menuDonate.
  ///
  /// In en, this message translates to:
  /// **'Buy me a coffee'**
  String get menuDonate;

  /// No description provided for @menuHideShell.
  ///
  /// In en, this message translates to:
  /// **'Hide log'**
  String get menuHideShell;

  /// No description provided for @menuIssue.
  ///
  /// In en, this message translates to:
  /// **'Report an issue'**
  String get menuIssue;

  /// No description provided for @menuLicense.
  ///
  /// In en, this message translates to:
  /// **'View licence'**
  String get menuLicense;

  /// No description provided for @menuOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Add video(s)'**
  String get menuOpenFile;

  /// No description provided for @menuOpenFolder.
  ///
  /// In en, this message translates to:
  /// **'Add folder'**
  String get menuOpenFolder;

  /// No description provided for @menuProgress.
  ///
  /// In en, this message translates to:
  /// **'Compact progress'**
  String get menuProgress;

  /// No description provided for @menuQuit.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get menuQuit;

  /// No description provided for @menuReferences.
  ///
  /// In en, this message translates to:
  /// **'References'**
  String get menuReferences;

  /// No description provided for @menuShowShell.
  ///
  /// In en, this message translates to:
  /// **'Show log'**
  String get menuShowShell;

  /// No description provided for @menuSourceCode.
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get menuSourceCode;

  /// No description provided for @menuThirdPartyLicenses.
  ///
  /// In en, this message translates to:
  /// **'Third-party licences'**
  String get menuThirdPartyLicenses;

  /// No description provided for @menuUpdate.
  ///
  /// In en, this message translates to:
  /// **'An update is available'**
  String get menuUpdate;

  /// No description provided for @menuVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String menuVersion(String version);

  /// No description provided for @menuWindowMode.
  ///
  /// In en, this message translates to:
  /// **'Back to window'**
  String get menuWindowMode;

  /// No description provided for @navAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get navAbout;

  /// No description provided for @navQueue.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get navQueue;

  /// No description provided for @navSection.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navSection;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'App settings'**
  String get navSettings;

  /// No description provided for @noiseHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get noiseHigh;

  /// No description provided for @noiseLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get noiseLow;

  /// No description provided for @noiseMid.
  ///
  /// In en, this message translates to:
  /// **'Mid'**
  String get noiseMid;

  /// No description provided for @optionKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get optionKeep;

  /// No description provided for @optionNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get optionNone;

  /// No description provided for @outputAlongsideSource.
  ///
  /// In en, this message translates to:
  /// **'Beside the source'**
  String get outputAlongsideSource;

  /// No description provided for @outputFixedDirectory.
  ///
  /// In en, this message translates to:
  /// **'A folder I pick'**
  String get outputFixedDirectory;

  /// No description provided for @outputChooseFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose the export folder'**
  String get outputChooseFolder;

  /// No description provided for @outputFolder.
  ///
  /// In en, this message translates to:
  /// **'Export to'**
  String get outputFolder;

  /// No description provided for @preferenceBundledFfmpeg.
  ///
  /// In en, this message translates to:
  /// **'FFmpeg is bundled with the app: there is no path to configure.'**
  String get preferenceBundledFfmpeg;

  /// No description provided for @preferenceChooseExportDir.
  ///
  /// In en, this message translates to:
  /// **'Select where to export videos'**
  String get preferenceChooseExportDir;

  /// No description provided for @preferenceChangeWorkingDir.
  ///
  /// In en, this message translates to:
  /// **'Change folder'**
  String get preferenceChangeWorkingDir;

  /// No description provided for @preferenceChooseWorkingDir.
  ///
  /// In en, this message translates to:
  /// **'Select where to keep the intermediate fragments'**
  String get preferenceChooseWorkingDir;

  /// No description provided for @preferenceClearTemporary.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get preferenceClearTemporary;

  /// No description provided for @preferenceExportDir.
  ///
  /// In en, this message translates to:
  /// **'Export directory'**
  String get preferenceExportDir;

  /// No description provided for @preferenceReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get preferenceReset;

  /// No description provided for @preferenceSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get preferenceSave;

  /// No description provided for @preferenceTemporaryFiles.
  ///
  /// In en, this message translates to:
  /// **'Temporary files: {size}'**
  String preferenceTemporaryFiles(String size);

  /// No description provided for @preferenceWorkingDir.
  ///
  /// In en, this message translates to:
  /// **'Working directory'**
  String get preferenceWorkingDir;

  /// No description provided for @preferenceWorkingDirHint.
  ///
  /// In en, this message translates to:
  /// **'Intermediate fragments are written here while a run is in progress, then removed. Put it on a fast drive with room to spare.'**
  String get preferenceWorkingDirHint;

  /// No description provided for @previewSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String previewSeconds(int seconds);

  /// No description provided for @processStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get processStart;

  /// No description provided for @processStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get processStop;

  /// No description provided for @queueCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No videos} =1{1 video} other{{count} videos}}'**
  String queueCount(int count);

  /// No description provided for @settingsAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced settings'**
  String get settingsAdvanced;

  /// No description provided for @settingsAudioRate.
  ///
  /// In en, this message translates to:
  /// **'Audio rate'**
  String get settingsAudioRate;

  /// No description provided for @settingsAudioTracks.
  ///
  /// In en, this message translates to:
  /// **'Keep all audio tracks'**
  String get settingsAudioTracks;

  /// No description provided for @settingsBackgroundNoise.
  ///
  /// In en, this message translates to:
  /// **'Background noise'**
  String get settingsBackgroundNoise;

  /// No description provided for @settingsBasic.
  ///
  /// In en, this message translates to:
  /// **'Basic settings'**
  String get settingsBasic;

  /// No description provided for @settingsCrf.
  ///
  /// In en, this message translates to:
  /// **'CRF'**
  String get settingsCrf;

  /// No description provided for @settingsDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get settingsDefault;

  /// No description provided for @settingsFilterPreview.
  ///
  /// In en, this message translates to:
  /// **'Detection filter'**
  String get settingsFilterPreview;

  /// No description provided for @settingsFormat.
  ///
  /// In en, this message translates to:
  /// **'Video format'**
  String get settingsFormat;

  /// No description provided for @settingsFps.
  ///
  /// In en, this message translates to:
  /// **'FPS'**
  String get settingsFps;

  /// No description provided for @settingsEncodingHide.
  ///
  /// In en, this message translates to:
  /// **'Hide the encoding settings'**
  String get settingsEncodingHide;

  /// No description provided for @settingsEncodingShow.
  ///
  /// In en, this message translates to:
  /// **'Show the encoding settings'**
  String get settingsEncodingShow;

  /// No description provided for @settingsEncodingTitle.
  ///
  /// In en, this message translates to:
  /// **'Encoding settings'**
  String get settingsEncodingTitle;

  /// No description provided for @settingsGroupApp.
  ///
  /// In en, this message translates to:
  /// **'Application'**
  String get settingsGroupApp;

  /// No description provided for @settingsGroupAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get settingsGroupAudio;

  /// No description provided for @settingsGroupDetection.
  ///
  /// In en, this message translates to:
  /// **'Silence detection'**
  String get settingsGroupDetection;

  /// No description provided for @settingsGroupExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get settingsGroupExport;

  /// No description provided for @settingsGroupPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get settingsGroupPreview;

  /// No description provided for @settingsGroupSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get settingsGroupSpeed;

  /// No description provided for @settingsMuteSilences.
  ///
  /// In en, this message translates to:
  /// **'Mute silences'**
  String get settingsMuteSilences;

  /// No description provided for @settingsNoiseFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read the levels of this video. The log says what FFmpeg answered.'**
  String get settingsNoiseFailed;

  /// No description provided for @settingsNoiseMeasure.
  ///
  /// In en, this message translates to:
  /// **'Measure {name}'**
  String settingsNoiseMeasure(String name);

  /// No description provided for @settingsNoiseMeasured.
  ///
  /// In en, this message translates to:
  /// **'{name}: hiss at {floor} dB, voice at {voice} dB'**
  String settingsNoiseMeasured(String name, int floor, int voice);

  /// No description provided for @settingsNoiseMeasuring.
  ///
  /// In en, this message translates to:
  /// **'Measuring {name}...'**
  String settingsNoiseMeasuring(String name);

  /// No description provided for @settingsNoiseTooClose.
  ///
  /// In en, this message translates to:
  /// **'The hiss is nearly as loud as the voice here, so no threshold separates them cleanly.'**
  String get settingsNoiseTooClose;

  /// No description provided for @settingsNoiseUse.
  ///
  /// In en, this message translates to:
  /// **'Suggested: {db} dB'**
  String settingsNoiseUse(int db);

  /// No description provided for @settingsNoiseValue.
  ///
  /// In en, this message translates to:
  /// **'{db} dB'**
  String settingsNoiseValue(int db);

  /// No description provided for @settingsPlaybackSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speech speed'**
  String get settingsPlaybackSpeed;

  /// No description provided for @settingsPreset.
  ///
  /// In en, this message translates to:
  /// **'Preset'**
  String get settingsPreset;

  /// No description provided for @settingsPreviewDuration.
  ///
  /// In en, this message translates to:
  /// **'Preview length'**
  String get settingsPreviewDuration;

  /// No description provided for @settingsReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get settingsReset;

  /// No description provided for @settingsResetDone.
  ///
  /// In en, this message translates to:
  /// **'Encoding settings reset'**
  String get settingsResetDone;

  /// No description provided for @settingsResetProcessing.
  ///
  /// In en, this message translates to:
  /// **'Reset the encoding settings'**
  String get settingsResetProcessing;

  /// No description provided for @settingsResetProcessingHint.
  ///
  /// In en, this message translates to:
  /// **'Puts every speed, detection and export setting back to its default.'**
  String get settingsResetProcessingHint;

  /// No description provided for @settingsSecondsValue.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String settingsSecondsValue(double seconds);

  /// No description provided for @settingsSilence.
  ///
  /// In en, this message translates to:
  /// **'Silence detection'**
  String get settingsSilence;

  /// No description provided for @settingsSilenceMargin.
  ///
  /// In en, this message translates to:
  /// **'Silence margin'**
  String get settingsSilenceMargin;

  /// No description provided for @settingsSilenceMinDuration.
  ///
  /// In en, this message translates to:
  /// **'Silence min duration'**
  String get settingsSilenceMinDuration;

  /// No description provided for @settingsSilenceSpeed.
  ///
  /// In en, this message translates to:
  /// **'Silence speed'**
  String get settingsSilenceSpeed;

  /// No description provided for @settingsSpeedRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get settingsSpeedRemove;

  /// No description provided for @settingsSpeedRemoveShort.
  ///
  /// In en, this message translates to:
  /// **'cut'**
  String get settingsSpeedRemoveShort;

  /// No description provided for @settingsTune.
  ///
  /// In en, this message translates to:
  /// **'Tune'**
  String get settingsTune;

  /// No description provided for @silencesFit.
  ///
  /// In en, this message translates to:
  /// **'The whole video'**
  String get silencesFit;

  /// No description provided for @silencesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No silence was found in this video.'**
  String get silencesEmpty;

  /// No description provided for @silencesPercent.
  ///
  /// In en, this message translates to:
  /// **'{percentage} %'**
  String silencesPercent(double percentage);

  /// No description provided for @silencesRanges.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No silences} =1{1 silence} other{{count} silences}}'**
  String silencesRanges(int count);

  /// No description provided for @silencesRedetect.
  ///
  /// In en, this message translates to:
  /// **'Detect again'**
  String get silencesRedetect;

  /// No description provided for @silencesReveal.
  ///
  /// In en, this message translates to:
  /// **'Show it on the timeline'**
  String get silencesReveal;

  /// No description provided for @silencesSaved.
  ///
  /// In en, this message translates to:
  /// **'Time saved'**
  String get silencesSaved;

  /// No description provided for @silencesShare.
  ///
  /// In en, this message translates to:
  /// **'Of the source'**
  String get silencesShare;

  /// No description provided for @silencesStale.
  ///
  /// In en, this message translates to:
  /// **'The detection settings have changed since these silences were found.'**
  String get silencesStale;

  /// No description provided for @silencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Detected silences'**
  String get silencesTitle;

  /// No description provided for @silencesTotal.
  ///
  /// In en, this message translates to:
  /// **'Silence'**
  String get silencesTotal;

  /// No description provided for @silencesOutput.
  ///
  /// In en, this message translates to:
  /// **'Estimated output'**
  String get silencesOutput;

  /// No description provided for @silencesZoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get silencesZoomIn;

  /// No description provided for @silencesZoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get silencesZoomOut;

  /// No description provided for @statusAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Detecting silences...'**
  String get statusAnalyzing;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusConcatenating.
  ///
  /// In en, this message translates to:
  /// **'Joining fragments...'**
  String get statusConcatenating;

  /// No description provided for @statusExporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting...'**
  String get statusExporting;

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get statusFailed;

  /// No description provided for @statusInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Interrupted'**
  String get statusInterrupted;

  /// No description provided for @statusLoaded.
  ///
  /// In en, this message translates to:
  /// **'Loaded [{duration}]'**
  String statusLoaded(String duration);

  /// No description provided for @statusLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get statusLoading;

  /// No description provided for @statusQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get statusQueued;

  /// No description provided for @statusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get statusReady;

  /// No description provided for @statusSilenceShare.
  ///
  /// In en, this message translates to:
  /// **'{percentage} % silence'**
  String statusSilenceShare(double percentage);

  /// No description provided for @uiCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get uiCancel;

  /// No description provided for @uiClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get uiClose;

  /// No description provided for @uiDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get uiDarkMode;

  /// No description provided for @uiDropVideo.
  ///
  /// In en, this message translates to:
  /// **'Drop videos here'**
  String get uiDropVideo;

  /// No description provided for @uiLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get uiLanguage;

  /// No description provided for @uiLightMode.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get uiLightMode;

  /// No description provided for @uiSystemMode.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get uiSystemMode;

  /// No description provided for @uiTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get uiTheme;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is available.'**
  String updateAvailable(String version);

  /// No description provided for @updateDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get updateDetails;

  /// No description provided for @updateDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get updateDownload;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
