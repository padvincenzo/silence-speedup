// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'package:flutter/foundation.dart';

import '../models/audio_levels.dart';

import '../models/media_entry.dart';
import '../models/options.dart';
import '../models/processing_settings.dart';
import '../models/time_window.dart';

/// Fragments shorter than this are dropped: FFmpeg cannot usefully encode them
/// and they only add seams to the concatenation.
const double kMinFragmentSeconds = 0.002;

/// One planned output chunk of a source file.
@immutable
class Fragment {
  const Fragment({
    required this.start,
    required this.end,
    required this.isSilence,
  });

  /// Absolute position in the source, in seconds.
  final double start;
  final double end;

  /// True for a quiet stretch, which is rated and muted differently.
  final bool isSilence;

  double get duration => end - start;

  /// Rate this fragment is played back at.
  SpeedOption speed(ProcessingSettings settings) =>
      isSilence ? settings.silenceSpeed : settings.playbackSpeed;
}

/// Result of pairing up `silencedetect` output.
@immutable
class SilenceParseResult {
  const SilenceParseResult(this.ranges, {required this.boundariesMismatched});

  final List<SilenceRange> ranges;

  /// True when starts and ends could not be paired, which means the detection
  /// output was not usable.
  final bool boundariesMismatched;
}

/// Pure translation of settings and detected silences into FFmpeg invocations.
///
/// Kept free of I/O and of the engine's progress plumbing so the argument
/// lists — the part where an off-by-one is expensive and invisible — can be
/// asserted directly in tests.
class FragmentPlanner {
  const FragmentPlanner._();

  /// Matches both boundary lines `silencedetect` prints.
  static final RegExp silencePattern = RegExp(
    r'silence_(start|end):\s*(-?\d+(?:\.\d+)?)',
  );

  /// Arguments for the detection pass. Decodes audio only and writes nothing.
  ///
  /// Pass a [window] to examine just part of the file, which is how a preview
  /// avoids having to cut a clip out first.
  static List<String> detectArguments({
    required String input,
    required ProcessingSettings settings,
    TimeWindow? window,
  }) {
    return <String>[
      '-hide_banner',
      '-dn',
      '-vn',
      '-ss', timestamp(window?.start ?? 0),
      // Input options, so FFmpeg reads only this stretch rather than decoding
      // the whole file and discarding the rest.
      if (window != null) ...<String>['-t', timestamp(window.duration)],
      '-i', input,
      // The first audio track only. In a multi-track recording that is the
      // voice; the other tracks must not decide where the pauses are.
      '-map', '0:a:0',
      '-af', settings.silenceDetectFilter,
      '-f', 'null',
      '-',
    ];
  }

  /// Arguments that measure how loud a file is, decoding audio and writing
  /// nothing.
  ///
  /// The whole file rather than a sample: the quietest stretch is what the
  /// noise floor is measured from, and there is no telling where it falls.
  /// Only the audio is decoded, which is cheap even for a long recording.
  static List<String> levelArguments({required String input}) {
    return <String>[
      '-hide_banner',
      '-dn',
      '-vn',
      '-i', input,
      // The voice track, the same one the silences are detected on.
      '-map', '0:a:0',
      // metadata=1 makes it print the summary; reset=0 measures the whole
      // file as one stretch rather than starting again every so often.
      '-af', 'astats=metadata=1:reset=0',
      '-f', 'null',
      '-',
    ];
  }

  /// Reads the levels out of what `astats` printed.
  ///
  /// The filter reports each channel and then an `Overall` block that says
  /// the same things about all of them together. Taking the last of each
  /// line therefore takes the overall figure, whatever the channel count.
  /// Returns null when the output held neither number, which is what a file
  /// with no audio at all produces.
  static AudioLevels? parseLevels(Iterable<String> lines) {
    double? floor;
    double? rms;

    for (final String line in lines) {
      final RegExpMatch? match = _statPattern.firstMatch(line);
      if (match == null) continue;
      final double? value = double.tryParse(match.group(2)!);
      if (value == null || !value.isFinite) continue;
      if (match.group(1) == 'Noise floor') {
        floor = value;
      } else {
        rms = value;
      }
    }

    if (floor == null || rms == null) return null;
    return AudioLevels(noiseFloorDb: floor, rmsDb: rms);
  }

  /// Matches the two `astats` lines worth reading.
  static final RegExp _statPattern = RegExp(
    r'(Noise floor|RMS level) dB:\s*(-?\d+(?:\.\d+)?)',
  );

  /// Pairs detected boundaries and trims each range by the margin.
  ///
  /// Unlike the Electron original, which skipped the first boundary of each
  /// list, the margin applies to every range — that asymmetry left the first
  /// silence a margin too wide at both ends.
  /// [from] and [to] bound the stretch that was examined, in absolute source
  /// seconds. `silencedetect` reports positions relative to the seek it was
  /// given, so [from] is added back to make every range absolute.
  static SilenceParseResult buildRanges({
    required List<double> starts,
    required List<double> ends,
    required double margin,
    required double from,
    required double to,
  }) {
    final List<double> closes = List<double>.of(ends);

    // A stretch that fades out into silence can end without a closing
    // boundary; treat its end as the close rather than dropping the run.
    if (starts.isNotEmpty && closes.length == starts.length - 1) {
      closes.add(to - from);
    }

    if (starts.length != closes.length) {
      return const SilenceParseResult(
        <SilenceRange>[],
        boundariesMismatched: true,
      );
    }

    final List<SilenceRange> ranges = <SilenceRange>[];
    double previousEnd = from;
    for (int i = 0; i < starts.length; i++) {
      final double start = (from + starts[i] + margin).clamp(from, to);
      final double end = (from + closes[i] - margin).clamp(from, to);
      if (end - start <= kMinFragmentSeconds) continue;
      // Overlapping ranges would produce fragments that replay the same audio.
      if (start < previousEnd) continue;
      ranges.add(SilenceRange(start, end));
      previousEnd = end;
    }

    return SilenceParseResult(ranges, boundariesMismatched: false);
  }

  /// Walks the stretch between [from] and [to], emitting alternating spoken
  /// and silent fragments that cover it end to end.
  static List<Fragment> plan({
    required List<SilenceRange> silences,
    required double from,
    required double to,
    required bool dropSilence,
  }) {
    final List<Fragment> plan = <Fragment>[];
    double cursor = from;

    void addPlayback(double start, double end) {
      if (end - start > kMinFragmentSeconds) {
        plan.add(Fragment(start: start, end: end, isSilence: false));
      }
    }

    for (final SilenceRange range in silences) {
      addPlayback(cursor, range.start);
      if (!dropSilence && range.duration > kMinFragmentSeconds) {
        plan.add(Fragment(start: range.start, end: range.end, isSilence: true));
      }
      cursor = range.end;
    }
    addPlayback(cursor, to);

    return plan;
  }

  /// Seconds the export will last, with every fragment shortened by its own
  /// rate and the removed ones contributing nothing.
  ///
  /// Derived from the same [plan] the run itself walks, so the figure shown
  /// before a run and the file that comes out cannot disagree about what the
  /// settings mean.
  static double outputSeconds({
    required List<SilenceRange> silences,
    required double sourceSeconds,
    required ProcessingSettings settings,
  }) {
    final List<Fragment> fragments = plan(
      silences: silences,
      from: 0,
      to: sourceSeconds,
      dropSilence: settings.dropsSilence,
    );

    double total = 0;
    for (final Fragment fragment in fragments) {
      final SpeedOption speed = fragment.speed(settings);
      if (speed.isRemove) continue;
      total += fragment.duration / speed.factor;
    }
    return total;
  }

  /// Arguments that encode one fragment at its own rate.
  static List<String> exportArguments({
    required String input,
    required String output,
    required Fragment fragment,
    required ProcessingSettings settings,
  }) {
    final SpeedOption speed = fragment.speed(settings);

    final List<String> arguments = <String>[
      '-hide_banner',
      '-y',
      '-loglevel', 'warning',
      '-stats',
      '-dn',
      // As input options these are absolute positions in the source, which is
      // exactly what the plan produces.
      '-ss', timestamp(fragment.start),
      '-to', timestamp(fragment.end),
      '-i', input,
      // Explicit stream selection. Without it FFmpeg keeps one audio track and
      // silently drops the others, which is what lost the second track of a
      // multi-track recording. The `?` keeps a missing stream from being fatal.
      '-map', '0:v:0?',
      '-map', settings.keepAllAudioTracks ? '0:a?' : '0:a:0?',
      '-map_metadata', '-1',
      '-map_chapters', '-1',
      '-segment_time_metadata', '0',
      '-max_muxing_queue_size', '99999',
      '-c:a', kAudioCodec,
      '-c:v', kVideoCodec,
      '-preset', settings.preset,
      '-crf', '${settings.crf}',
      // Every fragment is normalised to one constant frame rate, which is what
      // lets the concat step copy streams instead of re-encoding them.
      '-vsync', 'cfr',
      '-fflags', '+genpts',
    ];

    if (settings.tune != kNoneValue) {
      arguments.addAll(<String>['-tune', settings.tune]);
    }
    if (settings.audioRate != kNoneValue) {
      arguments.addAll(<String>['-ar', settings.audioRate]);
    }

    arguments.addAll(<String>[
      '-vf',
      <String>[
        if (speed.videoFilter != null) speed.videoFilter!,
        'fps=${settings.fps}',
      ].join(','),
    ]);

    // `-af` is `-filter:a`, a per-stream option: with several audio tracks
    // mapped, each gets its own copy of this graph and stays in step.
    //
    // Muting keeps the tempo filter in place: dropping it would leave the
    // audio longer than the sped-up video and desync everything after it.
    final List<String> audioFilters = <String>[
      if (speed.audioFilter != null) speed.audioFilter!,
      if (fragment.isSilence && settings.mutesSilence) 'volume=0',
    ];
    if (audioFilters.isNotEmpty) {
      arguments.addAll(<String>['-af', audioFilters.join(',')]);
    }

    arguments.add(output);
    return arguments;
  }

  /// Arguments that stitch the fragments together without re-encoding.
  static List<String> concatArguments({
    required String listPath,
    required String output,
  }) {
    return <String>[
      '-hide_banner',
      '-y',
      '-loglevel', 'warning',
      '-stats',
      '-segment_time_metadata', '0',
      '-vsync', 'cfr',
      '-f', 'concat',
      '-safe', '0',
      '-i', listPath,
      // Every stream of the fragments, not just the first of each kind, so a
      // second audio track survives the join.
      '-map', '0',
      '-c:a', 'copy',
      '-c:v', 'copy',
      output,
    ];
  }

  /// Formats one concat-demuxer line.
  ///
  /// Paths are normalised to forward slashes because the demuxer reads a
  /// backslash as an escape character, and single quotes get the escape the
  /// format requires.
  static String concatListEntry(String path) {
    final String normalised = path.replaceAll(r'\', '/');
    final String escaped = normalised.replaceAll("'", r"'\''");
    return "file '$escaped'";
  }

  /// FFmpeg wants plain seconds; six decimals is well past frame accuracy.
  static String timestamp(double seconds) => seconds.toStringAsFixed(6);
}
