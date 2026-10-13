// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import '../models/media_entry.dart';
import '../models/options.dart';
import '../models/processing_settings.dart';
import 'gen/app_localizations.dart';

/// Turns the models' enums into text.
///
/// This is the only place that maps a model value to a translated string, so
/// `models/` stays free of any dependency on the generated localizations. Every
/// switch here is exhaustive: adding an enum value breaks the build rather than
/// silently rendering nothing.

/// Text for one of the labels that is a word rather than a technical token.
String localizedLabel(OptionLabel label, AppLocalizations strings) {
  return switch (label) {
    OptionLabel.keep => strings.optionKeep,
    OptionLabel.none => strings.optionNone,
    OptionLabel.noiseLow => strings.noiseLow,
    OptionLabel.noiseMid => strings.noiseMid,
    OptionLabel.noiseHigh => strings.noiseHigh,
    OptionLabel.removeSilence => strings.settingsSpeedRemove,
  };
}

/// Label for a dropdown or slider entry, translated when it needs to be.
String optionText(LabeledOption option, AppLocalizations strings) {
  final OptionLabel? translated = option.translatedLabel;
  return translated == null ? option.label : localizedLabel(translated, strings);
}

/// Label for a playback rate: the rate itself, or the word for "remove".
String speedText(SpeedOption option, AppLocalizations strings) {
  final OptionLabel? translated = option.translatedLabel;
  return translated == null ? option.label : localizedLabel(translated, strings);
}

/// Status shown in the queue.
String statusText(EntryStatus status, AppLocalizations strings) {
  return switch (status) {
    EntryStatus.probing => strings.statusLoading,
    EntryStatus.ready => strings.statusReady,
    EntryStatus.queued => strings.statusQueued,
    EntryStatus.analyzing => strings.statusAnalyzing,
    EntryStatus.exporting => strings.statusExporting,
    EntryStatus.concatenating => strings.statusConcatenating,
    EntryStatus.completed => strings.statusCompleted,
    EntryStatus.failed => strings.statusFailed,
    EntryStatus.interrupted => strings.statusInterrupted,
  };
}

/// The settings in a group that differ from what the app ships with.
///
/// Each list is what a collapsed group shows about itself: enough to see at a
/// glance that something was changed, and what to. An empty list means the
/// group is untouched, which the interface says with one word instead.
///
/// The comparison is against `const ProcessingSettings()` rather than a
/// hand-written copy of the defaults, so a changed default cannot leave these
/// summaries lying.
const ProcessingSettings _defaults = ProcessingSettings();

List<String> speedChanges(
  ProcessingSettings settings,
  AppLocalizations strings,
) {
  return <String>[
    if (settings.silenceSpeedIndex != _defaults.silenceSpeedIndex)
      '${strings.settingsSilenceSpeed} ${speedText(settings.silenceSpeed, strings)}',
    if (settings.playbackSpeedIndex != _defaults.playbackSpeedIndex)
      '${strings.settingsPlaybackSpeed} ${speedText(settings.playbackSpeed, strings)}',
  ];
}

List<String> audioChanges(
  ProcessingSettings settings,
  AppLocalizations strings,
) {
  return <String>[
    if (settings.keepAllAudioTracks) strings.settingsAudioTracks,
    // The effective state, not the stored flag: muting means nothing once the
    // silences are being cut out, and a summary that claimed otherwise would
    // be worse than no summary.
    if (settings.mutesSilence) strings.settingsMuteSilences,
    if (settings.audioRateIndex != _defaults.audioRateIndex)
      '${strings.settingsAudioRate} '
          '${optionText(kAudioRates[settings.audioRateIndex], strings)}',
  ];
}

List<String> detectionChanges(
  ProcessingSettings settings,
  AppLocalizations strings,
) {
  return <String>[
    if (settings.thresholdDb != _defaults.thresholdDb)
      '${strings.settingsBackgroundNoise} '
          '${strings.settingsNoiseValue(settings.thresholdDb)}',
    if (settings.silenceMinDuration != _defaults.silenceMinDuration)
      '${strings.settingsSilenceMinDuration} '
          '${strings.settingsSecondsValue(settings.silenceMinDuration)}',
    if (settings.silenceMargin != _defaults.silenceMargin)
      '${strings.settingsSilenceMargin} '
          '${strings.settingsSecondsValue(settings.silenceMargin)}',
  ];
}

List<String> exportChanges(
  ProcessingSettings settings,
  AppLocalizations strings,
) {
  return <String>[
    if (settings.outputFormat != _defaults.outputFormat)
      '${strings.settingsFormat} ${settings.outputFormat}',
    if (settings.crf != _defaults.crf) '${strings.settingsCrf} ${settings.crf}',
    if (settings.fpsIndex != _defaults.fpsIndex)
      '${strings.settingsFps} '
          '${optionText(kFpsOptions[settings.fpsIndex], strings)}',
    if (settings.presetIndex != _defaults.presetIndex)
      '${strings.settingsPreset} '
          '${optionText(kPresets[settings.presetIndex], strings)}',
    if (settings.tuneIndex != _defaults.tuneIndex)
      '${strings.settingsTune} '
          '${optionText(kTunes[settings.tuneIndex], strings)}',
  ];
}

List<String> previewChanges(
  ProcessingSettings settings,
  AppLocalizations strings,
) {
  return <String>[
    if (settings.previewIndex != _defaults.previewIndex)
      '${strings.settingsPreviewDuration} '
          '${strings.previewSeconds(settings.previewSeconds)}',
  ];
}
