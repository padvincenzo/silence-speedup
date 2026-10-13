// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'package:flutter/foundation.dart';

import 'options.dart';

/// Everything the user can tune about a run, and nothing else.
///
/// Immutable so a run can capture the settings as they were when Start was
/// pressed, leaving the UI free to keep editing them.
@immutable
class ProcessingSettings {
  const ProcessingSettings({
    this.thresholdDb = -34,
    this.silenceMinDuration = 0.3,
    this.silenceMargin = 0.1,
    this.silenceSpeedIndex = 9,
    this.playbackSpeedIndex = 2,
    this.muteSilences = false,
    this.outputFormat = kKeepFormat,
    this.crf = 23,
    this.presetIndex = 5,
    this.fpsIndex = 5,
    this.audioRateIndex = 0,
    this.tuneIndex = 0,
    this.keepAllAudioTracks = false,
    this.previewIndex = 1,
  });

  /// How loud the room is allowed to be before it stops counting as
  /// silence, in decibels below full scale. Always negative.
  ///
  /// It used to be an index into three named steps twenty decibels apart,
  /// which left nothing between a studio and a living room — where most
  /// recordings actually sit.
  final int thresholdDb;

  /// Seconds a quiet stretch must last before it counts as silence.
  final double silenceMinDuration;

  /// Seconds kept on each side of a detected silence, so words are not clipped.
  final double silenceMargin;

  /// Index into [kSpeedOptions] for silent stretches.
  final int silenceSpeedIndex;

  /// Index into [kSpeedOptions] for spoken stretches.
  final int playbackSpeedIndex;

  /// Silence the audio of silent stretches instead of speeding it up audibly.
  final bool muteSilences;

  /// Container for the output, or [kKeepFormat] to match the input.
  final String outputFormat;

  final int crf;
  final int presetIndex;
  final int fpsIndex;
  final int audioRateIndex;
  final int tuneIndex;

  /// Carry every audio track of the source into the output instead of just the
  /// first. Silences are still detected on the first track alone — with a
  /// multi-track recording that track is the voice, and the others are game or
  /// system audio that should not decide where the pauses are.
  final bool keepAllAudioTracks;

  /// Index into [kPreviewDurations]: how long a preview sample lasts.
  final int previewIndex;

  SpeedOption get silenceSpeed => kSpeedOptions[silenceSpeedIndex];

  SpeedOption get playbackSpeed => kSpeedOptions[playbackSpeedIndex];

  /// True when silent stretches are cut out rather than sped up.
  bool get dropsSilence => silenceSpeed.isRemove;

  /// Muting only means something while the silence is still there.
  bool get mutesSilence => !dropsSilence && muteSilences;

  /// The threshold as `silencedetect` wants it written.
  String get threshold => '${thresholdDb}dB';

  String get preset => kPresets[presetIndex].value;

  String get fps => kFpsOptions[fpsIndex].value;

  String get audioRate => kAudioRates[audioRateIndex].value;

  String get tune => kTunes[tuneIndex].value;

  /// Length of a preview sample, in seconds.
  int get previewSeconds => kPreviewDurations[previewIndex];

  /// True when [other] would find the same silences.
  ///
  /// Only these three decide what `silencedetect` reports and how each range
  /// is then trimmed, so a view of detected silences is out of date when one
  /// of them has moved and not otherwise — changing the export container
  /// does not invalidate a detection.
  bool detectsLike(ProcessingSettings other) =>
      thresholdDb == other.thresholdDb &&
      silenceMinDuration == other.silenceMinDuration &&
      silenceMargin == other.silenceMargin;

  /// Window handed to `silencedetect`. It is widened by the margin on both
  /// sides so that, once each detected range is trimmed back by the margin,
  /// what survives is still at least [silenceMinDuration] long.
  double get detectionDuration => silenceMinDuration + 2 * silenceMargin;

  /// The `silencedetect` filter string.
  String get silenceDetectFilter =>
      'silencedetect=n=$threshold:d=${_trim(detectionDuration)}';

  ProcessingSettings copyWith({
    int? thresholdDb,
    double? silenceMinDuration,
    double? silenceMargin,
    int? silenceSpeedIndex,
    int? playbackSpeedIndex,
    bool? muteSilences,
    String? outputFormat,
    int? crf,
    int? presetIndex,
    int? fpsIndex,
    int? audioRateIndex,
    int? tuneIndex,
    bool? keepAllAudioTracks,
    int? previewIndex,
  }) {
    return ProcessingSettings(
      thresholdDb: thresholdDb ?? this.thresholdDb,
      silenceMinDuration: silenceMinDuration ?? this.silenceMinDuration,
      silenceMargin: silenceMargin ?? this.silenceMargin,
      silenceSpeedIndex: silenceSpeedIndex ?? this.silenceSpeedIndex,
      playbackSpeedIndex: playbackSpeedIndex ?? this.playbackSpeedIndex,
      muteSilences: muteSilences ?? this.muteSilences,
      outputFormat: outputFormat ?? this.outputFormat,
      crf: crf ?? this.crf,
      presetIndex: presetIndex ?? this.presetIndex,
      fpsIndex: fpsIndex ?? this.fpsIndex,
      audioRateIndex: audioRateIndex ?? this.audioRateIndex,
      tuneIndex: tuneIndex ?? this.tuneIndex,
      keepAllAudioTracks: keepAllAudioTracks ?? this.keepAllAudioTracks,
      previewIndex: previewIndex ?? this.previewIndex,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'thresholdDb': thresholdDb,
    'silenceMinDuration': silenceMinDuration,
    'silenceMargin': silenceMargin,
    'silenceSpeedIndex': silenceSpeedIndex,
    'playbackSpeedIndex': playbackSpeedIndex,
    'muteSilences': muteSilences,
    'outputFormat': outputFormat,
    'crf': crf,
    'presetIndex': presetIndex,
    'fpsIndex': fpsIndex,
    'audioRateIndex': audioRateIndex,
    'tuneIndex': tuneIndex,
    'keepAllAudioTracks': keepAllAudioTracks,
    'previewIndex': previewIndex,
  };

  /// Rebuilds settings from persisted JSON, clamping every index so that a
  /// stale preference file cannot crash the app after a catalogue changes.
  factory ProcessingSettings.fromJson(Map<String, dynamic> json) {
    const ProcessingSettings defaults = ProcessingSettings();
    return ProcessingSettings(
      thresholdDb: _readThresholdDb(json, defaults.thresholdDb),
      silenceMinDuration: _clampDouble(
        json['silenceMinDuration'],
        defaults.silenceMinDuration,
      ),
      silenceMargin: _clampDouble(
        json['silenceMargin'],
        defaults.silenceMargin,
      ),
      silenceSpeedIndex: _clampInt(
        json['silenceSpeedIndex'],
        defaults.silenceSpeedIndex,
        kSpeedOptions.length - 1,
      ),
      playbackSpeedIndex: _clampInt(
        json['playbackSpeedIndex'],
        defaults.playbackSpeedIndex,
        kLastKeptSpeedIndex,
      ),
      muteSilences: json['muteSilences'] is bool
          ? json['muteSilences'] as bool
          : defaults.muteSilences,
      outputFormat:
          kFormats.any(
            (LabeledOption format) => format.value == json['outputFormat'],
          )
          ? json['outputFormat'] as String
          : defaults.outputFormat,
      crf: _clampInt(json['crf'], defaults.crf, kCrfMax),
      presetIndex: _clampInt(
        json['presetIndex'],
        defaults.presetIndex,
        kPresets.length - 1,
      ),
      fpsIndex: _clampInt(
        json['fpsIndex'],
        defaults.fpsIndex,
        kFpsOptions.length - 1,
      ),
      audioRateIndex: _clampInt(
        json['audioRateIndex'],
        defaults.audioRateIndex,
        kAudioRates.length - 1,
      ),
      tuneIndex: _clampInt(
        json['tuneIndex'],
        defaults.tuneIndex,
        kTunes.length - 1,
      ),
      keepAllAudioTracks: json['keepAllAudioTracks'] is bool
          ? json['keepAllAudioTracks'] as bool
          : defaults.keepAllAudioTracks,
      previewIndex: _clampInt(
        json['previewIndex'],
        defaults.previewIndex,
        kPreviewDurations.length - 1,
      ),
    );
  }

  /// Reads the noise threshold, converting a setting saved by a version
  /// that had three named steps instead of a scale.
  ///
  /// The three were amplitude ratios -- 0.002, 0.02 and 0.1 -- which are
  /// -54, -34 and -20 decibels. Someone who had picked one of them keeps
  /// the room they picked.
  static int _readThresholdDb(Map<String, dynamic> json, int fallback) {
    final Object? db = json['thresholdDb'];
    if (db is num) {
      final int value = db.toInt();
      if (value >= kThresholdDbMin && value <= kThresholdDbMax) return value;
      return fallback;
    }

    final Object? index = json['thresholdIndex'];
    if (index is num) {
      final int at = index.toInt();
      if (at >= 0 && at < kNoiseAnchors.length) return kNoiseAnchors[at].db;
    }
    return fallback;
  }

  static int _clampInt(Object? raw, int fallback, int max) {
    if (raw is! num) return fallback;
    final int value = raw.toInt();
    if (value < 0 || value > max) return fallback;
    return value;
  }

  static double _clampDouble(Object? raw, double fallback) {
    if (raw is! num) return fallback;
    final double value = raw.toDouble();
    if (value < kSilenceDurationMin || value > kSilenceDurationMax) {
      return fallback;
    }
    return value;
  }

  /// Formats a seconds value without a trailing pile of zeroes, which keeps the
  /// generated FFmpeg filter readable in the log.
  static String _trim(double seconds) {
    final String text = seconds.toStringAsFixed(3);
    return text.contains('.')
        ? text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')
        : text;
  }
}
