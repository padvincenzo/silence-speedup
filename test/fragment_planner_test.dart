// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'package:flutter_test/flutter_test.dart';
import 'package:silence_speedup/models/audio_levels.dart';
import 'package:silence_speedup/models/media_entry.dart';
import 'package:silence_speedup/models/options.dart';
import 'package:silence_speedup/models/processing_settings.dart';
import 'package:silence_speedup/services/fragment_planner.dart';

/// Reads the value that follows [flag] in an argument list.
String? argumentAfter(List<String> arguments, String flag) {
  final int index = arguments.indexOf(flag);
  if (index < 0 || index + 1 >= arguments.length) return null;
  return arguments[index + 1];
}

void main() {
  group('FragmentPlanner.outputSeconds', () {
    // A minute of video with two ten-second pauses in it.
    const List<SilenceRange> silences = <SilenceRange>[
      SilenceRange(10, 20),
      SilenceRange(40, 50),
    ];

    test('leaves the source alone when nothing is sped up', () {
      // 1x over the lot: every fragment plays at its own length.
      const ProcessingSettings settings = ProcessingSettings(
        silenceSpeedIndex: 2,
        playbackSpeedIndex: 2,
      );
      expect(settings.silenceSpeed.factor, 1.0);

      expect(
        FragmentPlanner.outputSeconds(
          silences: silences,
          sourceSeconds: 60,
          settings: settings,
        ),
        closeTo(60, 0.001),
      );
    });

    test('shortens each fragment by its own rate', () {
      // Silences at 8x, speech untouched: 40 spoken seconds stay, and the
      // 20 quiet ones become 2.5.
      const ProcessingSettings settings = ProcessingSettings();
      expect(settings.silenceSpeed.factor, 8.0);

      expect(
        FragmentPlanner.outputSeconds(
          silences: silences,
          sourceSeconds: 60,
          settings: settings,
        ),
        closeTo(42.5, 0.001),
      );
    });

    test('counts a removed silence as nothing at all', () {
      final ProcessingSettings settings = const ProcessingSettings()
          .copyWith(silenceSpeedIndex: kSpeedOptions.length - 1);
      expect(settings.dropsSilence, isTrue);

      expect(
        FragmentPlanner.outputSeconds(
          silences: silences,
          sourceSeconds: 60,
          settings: settings,
        ),
        closeTo(40, 0.001),
      );
    });

    test('is the source length when no silence was found', () {
      expect(
        FragmentPlanner.outputSeconds(
          silences: const <SilenceRange>[],
          sourceSeconds: 60,
          settings: const ProcessingSettings(),
        ),
        closeTo(60, 0.001),
      );
    });
  });

  group('ProcessingSettings.detectsLike', () {
    test('ignores everything that cannot move a boundary', () {
      const ProcessingSettings a = ProcessingSettings();
      // Container, quality and speeds do not change what was detected.
      final ProcessingSettings b = a.copyWith(
        crf: 18,
        outputFormat: 'mkv',
        silenceSpeedIndex: 3,
      );
      expect(a.detectsLike(b), isTrue);
    });

    test('notices the three that can', () {
      const ProcessingSettings a = ProcessingSettings();
      expect(a.detectsLike(a.copyWith(thresholdDb: -40)), isFalse);
      expect(a.detectsLike(a.copyWith(silenceMinDuration: 0.5)), isFalse);
      expect(a.detectsLike(a.copyWith(silenceMargin: 0.2)), isFalse);
    });
  });

  group('buildRanges', () {
    test('trims every range by the margin, including the first', () {
      final SilenceParseResult result = FragmentPlanner.buildRanges(
        starts: <double>[10, 30],
        ends: <double>[20, 40],
        margin: 0.5,
        from: 0,
        to: 60,
      );

      expect(result.boundariesMismatched, isFalse);
      expect(result.ranges, hasLength(2));
      expect(result.ranges[0].start, closeTo(10.5, 1e-9));
      expect(result.ranges[0].end, closeTo(19.5, 1e-9));
      expect(result.ranges[1].start, closeTo(30.5, 1e-9));
      expect(result.ranges[1].end, closeTo(39.5, 1e-9));
    });

    test('never lets the margin push a range before the start of the file', () {
      final SilenceParseResult result = FragmentPlanner.buildRanges(
        starts: <double>[0],
        ends: <double>[5],
        margin: 1,
        from: 0,
        to: 60,
      );

      expect(result.ranges.single.start, closeTo(1, 1e-9));
      expect(result.ranges.single.start, greaterThanOrEqualTo(0));
    });

    test('closes a silence that runs to the end of the file', () {
      final SilenceParseResult result = FragmentPlanner.buildRanges(
        starts: <double>[10, 50],
        ends: <double>[20],
        margin: 0,
        from: 0,
        to: 60,
      );

      expect(result.boundariesMismatched, isFalse);
      expect(result.ranges, hasLength(2));
      expect(result.ranges.last.end, closeTo(60, 1e-9));
    });

    test('reports a mismatch it cannot repair', () {
      final SilenceParseResult result = FragmentPlanner.buildRanges(
        starts: <double>[10],
        ends: <double>[20, 30, 40],
        margin: 0,
        from: 0,
        to: 60,
      );

      expect(result.boundariesMismatched, isTrue);
      expect(result.ranges, isEmpty);
    });

    test('drops a range the margin has eaten entirely', () {
      final SilenceParseResult result = FragmentPlanner.buildRanges(
        starts: <double>[10],
        ends: <double>[10.4],
        margin: 0.3,
        from: 0,
        to: 60,
      );

      expect(result.ranges, isEmpty);
    });
  });

  group('plan', () {
    const double mediaSeconds = 100;

    test('alternates speech and silence and covers the whole timeline', () {
      final List<Fragment> plan = FragmentPlanner.plan(
        silences: const <SilenceRange>[
          SilenceRange(10, 20),
          SilenceRange(50, 60),
        ],
        from: 0,
        to: mediaSeconds,
        dropSilence: false,
      );

      expect(
        plan.map((Fragment f) => '${f.start}-${f.end}:${f.isSilence}'),
        <String>[
          '0.0-10.0:false',
          '10.0-20.0:true',
          '20.0-50.0:false',
          '50.0-60.0:true',
          '60.0-100.0:false',
        ],
      );

      // Nothing may be lost or double-counted between the pieces.
      double covered = 0;
      for (final Fragment fragment in plan) {
        covered += fragment.duration;
      }
      expect(covered, closeTo(mediaSeconds, 1e-9));
    });

    test('omits the silent stretches when they are removed', () {
      final List<Fragment> plan = FragmentPlanner.plan(
        silences: const <SilenceRange>[SilenceRange(10, 20)],
        from: 0,
        to: mediaSeconds,
        dropSilence: true,
      );

      expect(plan.every((Fragment fragment) => !fragment.isSilence), isTrue);
      expect(plan, hasLength(2));
    });

    test('skips a leading playback fragment when the file opens in silence',
        () {
      final List<Fragment> plan = FragmentPlanner.plan(
        silences: const <SilenceRange>[SilenceRange(0, 20)],
        from: 0,
        to: mediaSeconds,
        dropSilence: false,
      );

      expect(plan.first.isSilence, isTrue);
      expect(plan, hasLength(2));
    });

    test('skips a trailing playback fragment when the file ends in silence',
        () {
      final List<Fragment> plan = FragmentPlanner.plan(
        silences: const <SilenceRange>[SilenceRange(90, mediaSeconds)],
        from: 0,
        to: mediaSeconds,
        dropSilence: false,
      );

      expect(plan.last.isSilence, isTrue);
      expect(plan, hasLength(2));
    });
  });

  group('exportArguments', () {
    const ProcessingSettings base = ProcessingSettings();

    test('positions the cut with absolute input timestamps', () {
      final List<String> arguments = FragmentPlanner.exportArguments(
        input: 'in.mp4',
        output: 'out.mp4',
        fragment: const Fragment(start: 12.5, end: 20, isSilence: false),
        settings: base,
      );

      expect(argumentAfter(arguments, '-ss'), '12.500000');
      expect(argumentAfter(arguments, '-to'), '20.000000');
      // Both must precede -i to act as input options.
      expect(
        arguments.indexOf('-ss'),
        lessThan(arguments.indexOf('-i')),
      );
      expect(arguments.last, 'out.mp4');
    });

    test('a 1x fragment gets the fps filter and no tempo filter', () {
      final List<String> arguments = FragmentPlanner.exportArguments(
        input: 'in.mp4',
        output: 'out.mp4',
        // Default playback speed is 1x.
        fragment: const Fragment(start: 0, end: 5, isSilence: false),
        settings: base,
      );

      expect(argumentAfter(arguments, '-vf'), 'fps=fps=30:round=near');
      expect(arguments.contains('-af'), isFalse);
    });

    test('a sped-up silence chains setpts and atempo before the fps filter',
        () {
      final List<String> arguments = FragmentPlanner.exportArguments(
        input: 'in.mp4',
        output: 'out.mp4',
        fragment: const Fragment(start: 0, end: 5, isSilence: true),
        // Default silence speed is 8x.
        settings: base,
      );

      expect(
        argumentAfter(arguments, '-vf'),
        'setpts=0.125*PTS,fps=fps=30:round=near',
      );
      expect(argumentAfter(arguments, '-af'), 'atempo=2,atempo=2,atempo=2');
    });

    test('muting keeps the tempo filter so audio and video stay the same '
        'length', () {
      final List<String> arguments = FragmentPlanner.exportArguments(
        input: 'in.mp4',
        output: 'out.mp4',
        fragment: const Fragment(start: 0, end: 5, isSilence: true),
        settings: base.copyWith(muteSilences: true),
      );

      expect(
        argumentAfter(arguments, '-af'),
        'atempo=2,atempo=2,atempo=2,volume=0',
      );
    });

    test('mute does not leak onto the spoken fragments', () {
      final List<String> arguments = FragmentPlanner.exportArguments(
        input: 'in.mp4',
        output: 'out.mp4',
        fragment: const Fragment(start: 0, end: 5, isSilence: false),
        settings: base.copyWith(muteSilences: true, playbackSpeedIndex: 5),
      );

      expect(argumentAfter(arguments, '-af'), 'atempo=2');
    });

    test('optional encoder settings appear only when chosen', () {
      final List<String> defaults = FragmentPlanner.exportArguments(
        input: 'in.mp4',
        output: 'out.mp4',
        fragment: const Fragment(start: 0, end: 5, isSilence: false),
        settings: base,
      );
      expect(defaults.contains('-tune'), isFalse);
      expect(defaults.contains('-ar'), isFalse);

      final List<String> tuned = FragmentPlanner.exportArguments(
        input: 'in.mp4',
        output: 'out.mp4',
        fragment: const Fragment(start: 0, end: 5, isSilence: false),
        settings: base.copyWith(tuneIndex: 1, audioRateIndex: 3, crf: 18),
      );
      expect(argumentAfter(tuned, '-tune'), 'film');
      expect(argumentAfter(tuned, '-ar'), '48000');
      expect(argumentAfter(tuned, '-crf'), '18');
    });

    test('encodes with the codecs the concat step can copy', () {
      final List<String> arguments = FragmentPlanner.exportArguments(
        input: 'in.mp4',
        output: 'out.mp4',
        fragment: const Fragment(start: 0, end: 5, isSilence: false),
        settings: base,
      );

      expect(argumentAfter(arguments, '-c:v'), kVideoCodec);
      expect(argumentAfter(arguments, '-c:a'), kAudioCodec);
      expect(argumentAfter(arguments, '-vsync'), 'cfr');
    });
  });

  group('concat list', () {
    test('rewrites Windows separators the demuxer would read as escapes', () {
      expect(
        FragmentPlanner.concatListEntry(r'C:\tmp\run\f_000001.mp4'),
        "file 'C:/tmp/run/f_000001.mp4'",
      );
    });

    test('escapes a single quote in the path', () {
      expect(
        FragmentPlanner.concatListEntry("/home/vin/it's/f_0.mp4"),
        r"file '/home/vin/it'\''s/f_0.mp4'",
      );
    });

    test('copies streams instead of re-encoding', () {
      final List<String> arguments = FragmentPlanner.concatArguments(
        listPath: 'list.txt',
        output: 'out.mp4',
      );

      expect(argumentAfter(arguments, '-c:v'), 'copy');
      expect(argumentAfter(arguments, '-c:a'), 'copy');
      expect(argumentAfter(arguments, '-safe'), '0');
      expect(argumentAfter(arguments, '-f'), 'concat');
    });
  });

  group('levelArguments and parseLevels', () {
    /// What astats prints for a stereo file: each channel, then the overall
    /// figures for all of them together.
    const String output = '''
[Parsed_astats_0 @ 000001] Channel: 1
[Parsed_astats_0 @ 000001] Peak level dB: -4.100000
[Parsed_astats_0 @ 000001] RMS level dB: -19.700000
[Parsed_astats_0 @ 000001] Noise floor dB: -46.100000
[Parsed_astats_0 @ 000001] Channel: 2
[Parsed_astats_0 @ 000001] Peak level dB: -4.900000
[Parsed_astats_0 @ 000001] RMS level dB: -20.300000
[Parsed_astats_0 @ 000001] Noise floor dB: -47.900000
[Parsed_astats_0 @ 000001] Overall
[Parsed_astats_0 @ 000001] Peak level dB: -4.100000
[Parsed_astats_0 @ 000001] RMS level dB: -20.000000
[Parsed_astats_0 @ 000001] Noise floor dB: -47.000000
''';

    test('decodes the audio of the voice track and writes nothing', () {
      final List<String> arguments = FragmentPlanner.levelArguments(
        input: 'in.mp4',
      );

      expect(argumentAfter(arguments, '-i'), 'in.mp4');
      // The same track the silences are detected on, or the reading would
      // describe a different sound than the one being cut.
      expect(argumentAfter(arguments, '-map'), '0:a:0');
      expect(argumentAfter(arguments, '-af'), 'astats=metadata=1:reset=0');
      expect(arguments, contains('-vn'));
      expect(argumentAfter(arguments, '-f'), 'null');
    });

    test('reads the overall figures, not the first channel', () {
      final AudioLevels? levels = FragmentPlanner.parseLevels(
        output.split('\n'),
      );

      expect(levels, isNotNull);
      expect(levels!.noiseFloorDb, closeTo(-47, 0.001));
      expect(levels.rmsDb, closeTo(-20, 0.001));
    });

    test('suggests a threshold between the hiss and the voice', () {
      final AudioLevels levels = FragmentPlanner.parseLevels(
        output.split('\n'),
      )!;

      // Halfway in decibels, which is the scale the ear and the filter both
      // work on.
      expect(levels.isUsable, isTrue);
      expect(levels.suggestedThresholdDb, -34);
    });

    test('says nothing about a file it could not measure', () {
      expect(FragmentPlanner.parseLevels(const <String>[]), isNull);
      expect(
        FragmentPlanner.parseLevels(const <String>[
          '[Parsed_astats_0 @ 000001] RMS level dB: -20.000000',
        ]),
        isNull,
        reason: 'one of the two figures is not a reading',
      );
    });

    test('will not choose for a recording whose hiss is as loud as its voice',
        () {
      const AudioLevels noisy = AudioLevels(
        noiseFloorDb: -22,
        rmsDb: -20,
      );

      // Nothing separates them, so offering a number would be a pretence.
      expect(noisy.isUsable, isFalse);
    });
  });

  group('detectArguments', () {
    test('widens the detection window by twice the margin', () {
      const ProcessingSettings settings = ProcessingSettings(
        silenceMinDuration: 0.3,
        silenceMargin: 0.1,
        thresholdDb: -34,
      );

      final List<String> arguments = FragmentPlanner.detectArguments(
        input: 'in.mp4',
        settings: settings,
      );

      // 0.3 + 2 * 0.1: what survives the trim is still the requested minimum.
      expect(argumentAfter(arguments, '-af'), 'silencedetect=n=-34dB:d=0.5');
      expect(arguments.contains('-vn'), isTrue);
      expect(argumentAfter(arguments, '-f'), 'null');
    });
  });

  group('silencePattern', () {
    test('reads both boundaries out of real silencedetect output', () {
      const String output =
          '[silencedetect @ 0000021b] silence_start: 12.3456\n'
          '[silencedetect @ 0000021b] silence_end: 18.9 | silence_duration: 6.55';

      final List<String> found = FragmentPlanner.silencePattern
          .allMatches(output)
          .map((RegExpMatch m) => '${m.group(1)}=${m.group(2)}')
          .toList();

      expect(found, <String>['start=12.3456', 'end=18.9']);
    });

    test('reads a negative start, which FFmpeg can emit at the head of a file',
        () {
      final RegExpMatch? match = FragmentPlanner.silencePattern.firstMatch(
        'silence_start: -0.008',
      );
      expect(match?.group(2), '-0.008');
    });
  });
}
