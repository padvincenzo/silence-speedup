// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'package:flutter/foundation.dart';

/// Option catalogues ported from the Electron app's `config.json`.
///
/// These describe what the app is able to do rather than what the user picked,
/// so they ship as code instead of an editable file. User choices live in
/// `ProcessingSettings` and are persisted separately.

/// Value used by dropdowns that offer an explicit "leave it alone" entry.
const String kNoneValue = '-';

/// Output format value meaning "same container as the input".
const String kKeepFormat = 'keep';

/// Option labels that are words rather than technical tokens, and so need
/// translating. Resolved by `localizedLabel` in lib/l10n/labels.dart, which
/// keeps this file free of any dependency on the generated localizations.
enum OptionLabel { keep, none, noiseLow, noiseMid, noiseHigh, removeSilence }

/// How a fragment's playback rate is applied.
enum SpeedKind {
  /// Untouched: no `setpts` / `atempo` filter at all.
  normal,

  /// Re-timed through `setpts` (video) and `atempo` (audio).
  scaled,

  /// Dropped from the output entirely.
  remove,
}

@immutable
class SpeedOption {
  const SpeedOption.normal(this.label)
    : kind = SpeedKind.normal,
      factor = 1.0,
      videoFilter = null,
      audioFilter = null,
      translatedLabel = null;

  const SpeedOption.scaled(
    this.label, {
    required this.factor,
    required String video,
    required String audio,
  }) : kind = SpeedKind.scaled,
       videoFilter = video,
       audioFilter = audio,
       translatedLabel = null;

  const SpeedOption.remove({required this.translatedLabel})
    : label = 'remove',
      kind = SpeedKind.remove,
      factor = 1.0,
      videoFilter = null,
      audioFilter = null;

  /// Short label such as `8x`. Not localized: it is a number and a unit.
  final String label;

  final SpeedKind kind;

  /// How much faster than real time this option plays, used to convert an
  /// encoder's output timestamp back into a position in the source file.
  final double factor;

  /// `setpts=...`, or null when the fragment keeps its original timing.
  final String? videoFilter;

  /// `atempo=...`, possibly chained since a single `atempo` caps at 2x.
  final String? audioFilter;

  /// Set only for the entry whose label is a word rather than a rate.
  final OptionLabel? translatedLabel;

  bool get isRemove => kind == SpeedKind.remove;
}

/// Playback rates, slowest first. `remove` must stay last: the playback-speed
/// slider deliberately stops one step short of it.
const List<SpeedOption> kSpeedOptions = <SpeedOption>[
  SpeedOption.scaled(
    '0.5x',
    factor: 0.5,
    video: 'setpts=2*PTS',
    audio: 'atempo=0.5',
  ),
  SpeedOption.scaled(
    '0.8x',
    factor: 0.8,
    video: 'setpts=1.25*PTS',
    audio: 'atempo=0.8',
  ),
  SpeedOption.normal('1x'),
  SpeedOption.scaled(
    '1.25x',
    factor: 1.25,
    video: 'setpts=0.8*PTS',
    audio: 'atempo=1.25',
  ),
  SpeedOption.scaled(
    '1.6x',
    factor: 1.6,
    video: 'setpts=0.625*PTS',
    audio: 'atempo=1.6',
  ),
  SpeedOption.scaled(
    '2x',
    factor: 2,
    video: 'setpts=0.5*PTS',
    audio: 'atempo=2',
  ),
  SpeedOption.scaled(
    '2.5x',
    factor: 2.5,
    video: 'setpts=0.4*PTS',
    audio: 'atempo=2,atempo=1.25',
  ),
  SpeedOption.scaled(
    '4x',
    factor: 4,
    video: 'setpts=0.25*PTS',
    audio: 'atempo=2,atempo=2',
  ),
  SpeedOption.scaled(
    '5x',
    factor: 5,
    video: 'setpts=0.2*PTS',
    audio: 'atempo=2,atempo=2,atempo=1.25',
  ),
  SpeedOption.scaled(
    '8x',
    factor: 8,
    video: 'setpts=0.125*PTS',
    audio: 'atempo=2,atempo=2,atempo=2',
  ),
  SpeedOption.scaled(
    '16x',
    factor: 16,
    video: 'setpts=0.0625*PTS',
    audio: 'atempo=2,atempo=2,atempo=2,atempo=2',
  ),
  SpeedOption.scaled(
    '20x',
    factor: 20,
    video: 'setpts=0.05*PTS',
    audio: 'atempo=2,atempo=2,atempo=2,atempo=2,atempo=1.25',
  ),
  SpeedOption.remove(translatedLabel: OptionLabel.removeSilence),
];

/// Index of the trailing `remove` entry.
final int kRemoveSpeedIndex = kSpeedOptions.length - 1;

/// Highest index that still keeps the silence in the output.
final int kLastKeptSpeedIndex = kSpeedOptions.length - 2;

@immutable
class LabeledOption {
  const LabeledOption(this.label, this.value) : translatedLabel = null;

  /// Variant whose label is a translated word rather than a technical token.
  const LabeledOption.translated(this.translatedLabel, this.value)
    : label = '';

  /// Literal label, for the ffmpeg tokens that are not worth translating.
  final String label;

  /// Set instead of [label] when the text is a word the user reads.
  final OptionLabel? translatedLabel;

  final String value;
}

/// `silencedetect` noise floors, as linear amplitude ratios.
/// Quietest and loudest a room may be called, in decibels below full scale.
///
/// Under -60 dB is below the noise floor of most recordings, so a threshold
/// there finds no silence at all; above -10 dB the threshold is up among the
/// speech and everything counts as silence. Neither end is useful, and the
/// slider stops there.
const int kThresholdDbMin = -60;
const int kThresholdDbMax = -10;

/// Named points on that scale, kept from when it had only these three.
///
/// They are what the numbers mean: a studio, a room, a café. The scale is
/// continuous now, but a reading of "-34 dB" says nothing on its own to
/// someone who has not measured a room before.
const List<NoiseAnchor> kNoiseAnchors = <NoiseAnchor>[
  NoiseAnchor(OptionLabel.noiseLow, -54),
  NoiseAnchor(OptionLabel.noiseMid, -34),
  NoiseAnchor(OptionLabel.noiseHigh, -20),
];

/// A named place on the noise scale.
@immutable
class NoiseAnchor {
  const NoiseAnchor(this.label, this.db);

  final OptionLabel label;

  /// Decibels below full scale, always negative.
  final int db;
}

const List<LabeledOption> kFormats = <LabeledOption>[
  LabeledOption.translated(OptionLabel.keep, kKeepFormat),
  LabeledOption('AVI', 'avi'),
  LabeledOption('FLV', 'flv'),
  LabeledOption('MKV', 'mkv'),
  LabeledOption('MOV', 'mov'),
  LabeledOption('MP4', 'mp4'),
  LabeledOption('WebM', 'webm'),
  LabeledOption('WMV', 'wmv'),
];

/// Extensions accepted on import, derived from the output formats.
final Set<String> kImportableExtensions = kFormats
    .where((LabeledOption format) => format.value != kKeepFormat)
    .map((LabeledOption format) => format.value)
    .toSet();

/// x264 speed/compression presets.
const List<LabeledOption> kPresets = <LabeledOption>[
  LabeledOption('Ultra fast', 'ultrafast'),
  LabeledOption('Super fast', 'superfast'),
  LabeledOption('Very fast', 'veryfast'),
  LabeledOption('Faster', 'faster'),
  LabeledOption('Fast', 'fast'),
  LabeledOption('Medium', 'medium'),
  LabeledOption('Slow', 'slow'),
  LabeledOption('Slower', 'slower'),
  LabeledOption('Very slow', 'veryslow'),
];

/// Values are the `fps` filter's own arguments, so the composed filter reads
/// `fps=fps=30:round=near`.
const List<LabeledOption> kFpsOptions = <LabeledOption>[
  LabeledOption('10', 'fps=10:round=near'),
  LabeledOption('20', 'fps=20:round=near'),
  LabeledOption('24 NTSC', 'fps=24:round=near'),
  LabeledOption('25 PAL', 'fps=25:round=near'),
  LabeledOption('29.97', 'fps=30000/1001:round=near'),
  LabeledOption('30', 'fps=30:round=near'),
  LabeledOption('48', 'fps=48:round=near'),
  LabeledOption('50 PAL', 'fps=50:round=near'),
  LabeledOption('59.94', 'fps=60000/1001:round=near'),
  LabeledOption('60', 'fps=60:round=near'),
  LabeledOption('72', 'fps=72:round=near'),
  LabeledOption('75', 'fps=75:round=near'),
  LabeledOption('90', 'fps=90:round=near'),
  LabeledOption('100', 'fps=100:round=near'),
  LabeledOption('120', 'fps=120:round=near'),
];

const List<LabeledOption> kAudioRates = <LabeledOption>[
  LabeledOption.translated(OptionLabel.keep, kNoneValue),
  LabeledOption('32 kHz', '32000'),
  LabeledOption('44.1 kHz', '44100'),
  LabeledOption('48 kHz', '48000'),
  LabeledOption('88.2 kHz', '88200'),
  LabeledOption('96 kHz', '96000'),
];

const List<LabeledOption> kTunes = <LabeledOption>[
  LabeledOption.translated(OptionLabel.none, kNoneValue),
  LabeledOption('Film', 'film'),
  LabeledOption('Animation', 'animation'),
  LabeledOption('Grain', 'grain'),
  LabeledOption('Still image', 'stillimage'),
  LabeledOption('Fast decode', 'fastdecode'),
  LabeledOption('Zero latency', 'zerolatency'),
];

/// How long a preview sample lasts. Short enough to be quick, long enough to
/// judge whether the pauses sound right.
const List<int> kPreviewDurations = <int>[30, 60, 120];

/// Bounds for the two silence-shaping sliders, in seconds.
const double kSilenceDurationMin = 0.0;
const double kSilenceDurationMax = 10.0;
const double kSilenceDurationStep = 0.05;

const int kCrfMin = 0;
const int kCrfMax = 51;

/// Codecs used for every re-encoded fragment. `libx264` needs the full-GPL
/// FFmpeg build, which is what `ffmpeg_kit_flutter_new` bundles.
const String kAudioCodec = 'aac';
const String kVideoCodec = 'libx264';
