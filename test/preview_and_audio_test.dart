// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'package:flutter_test/flutter_test.dart';
import 'package:silence_speedup/models/media_entry.dart';
import 'package:silence_speedup/models/options.dart';
import 'package:silence_speedup/models/processing_settings.dart';
import 'package:silence_speedup/models/time_window.dart';
import 'package:silence_speedup/services/fragment_planner.dart';

/// Reads the value that follows [flag] in an argument list.
String? argumentAfter(List<String> arguments, String flag) {
  final int index = arguments.indexOf(flag);
  if (index < 0 || index + 1 >= arguments.length) return null;
  return arguments[index + 1];
}

/// Every value that follows an occurrence of [flag].
List<String> allAfter(List<String> arguments, String flag) {
  final List<String> values = <String>[];
  for (int i = 0; i < arguments.length - 1; i++) {
    if (arguments[i] == flag) values.add(arguments[i + 1]);
  }
  return values;
}

void main() {
  group('TimeWindow.preview', () {
    test('samples the requested length a third of the way in', () {
      final TimeWindow window = TimeWindow.preview(
        mediaSeconds: 900,
        seconds: 60,
      );

      expect(window.duration, closeTo(60, 1e-9));
      expect(window.start, closeTo(280, 1e-9));
      expect(window.end, closeTo(340, 1e-9));
    });

    test('never runs past the end of the file', () {
      final TimeWindow window = TimeWindow.preview(
        mediaSeconds: 70,
        seconds: 60,
      );

      expect(window.start, greaterThanOrEqualTo(0));
      expect(window.end, lessThanOrEqualTo(70));
    });

    test('takes the whole file when it is shorter than the sample', () {
      final TimeWindow window = TimeWindow.preview(
        mediaSeconds: 25,
        seconds: 60,
      );

      expect(window.start, closeTo(0, 1e-9));
      expect(window.end, closeTo(25, 1e-9));
      expect(window.duration, closeTo(25, 1e-9));
    });

    test('offered lengths are ordered and the default is the middle one', () {
      expect(kPreviewDurations, <int>[30, 60, 120]);
      expect(
        kPreviewDurations[const ProcessingSettings().previewIndex],
        60,
      );
    });
  });

  group('detection over a window', () {
    const ProcessingSettings settings = ProcessingSettings();

    test('reads only the sampled stretch, so no clip has to be cut first', () {
      final List<String> arguments = FragmentPlanner.detectArguments(
        input: 'in.mp4',
        settings: settings,
        window: const TimeWindow(start: 280, end: 340),
      );

      expect(argumentAfter(arguments, '-ss'), '280.000000');
      expect(argumentAfter(arguments, '-t'), '60.000000');
      // Both must precede -i to limit what FFmpeg decodes.
      expect(arguments.indexOf('-t'), lessThan(arguments.indexOf('-i')));
    });

    test('a full run passes no duration limit', () {
      final List<String> arguments = FragmentPlanner.detectArguments(
        input: 'in.mp4',
        settings: settings,
      );

      expect(arguments.contains('-t'), isFalse);
      expect(argumentAfter(arguments, '-ss'), '0.000000');
    });

    test('detects on the first audio track only', () {
      final List<String> arguments = FragmentPlanner.detectArguments(
        input: 'in.mp4',
        settings: settings.copyWith(keepAllAudioTracks: true),
      );

      // Even when every track is exported, the pauses come from the voice.
      expect(argumentAfter(arguments, '-map'), '0:a:0');
    });

    test('window positions are made absolute again', () {
      // silencedetect reports relative to its seek, so the offset comes back.
      final SilenceParseResult result = FragmentPlanner.buildRanges(
        starts: <double>[5],
        ends: <double>[15],
        margin: 0,
        from: 280,
        to: 340,
      );

      expect(result.ranges.single.start, closeTo(285, 1e-9));
      expect(result.ranges.single.end, closeTo(295, 1e-9));
    });

    test('a range is clamped to the sampled stretch', () {
      final SilenceParseResult result = FragmentPlanner.buildRanges(
        starts: <double>[50],
        ends: <double>[80],
        margin: 0,
        from: 280,
        to: 340,
      );

      expect(result.ranges.single.start, closeTo(330, 1e-9));
      expect(result.ranges.single.end, closeTo(340, 1e-9));
    });

    test('an unclosed silence closes at the end of the stretch', () {
      final SilenceParseResult result = FragmentPlanner.buildRanges(
        starts: <double>[50],
        ends: <double>[],
        margin: 0,
        from: 280,
        to: 340,
      );

      expect(result.boundariesMismatched, isFalse);
      expect(result.ranges.single.end, closeTo(340, 1e-9));
    });

    test('the plan stays inside the sampled stretch', () {
      final List<Fragment> plan = FragmentPlanner.plan(
        silences: const <SilenceRange>[SilenceRange(300, 310)],
        from: 280,
        to: 340,
        dropSilence: false,
      );

      expect(plan.first.start, closeTo(280, 1e-9));
      expect(plan.last.end, closeTo(340, 1e-9));

      double covered = 0;
      for (final Fragment fragment in plan) {
        covered += fragment.duration;
      }
      expect(covered, closeTo(60, 1e-9));
    });
  });

  group('audio track mapping', () {
    const ProcessingSettings base = ProcessingSettings();
    const Fragment fragment = Fragment(start: 0, end: 5, isSilence: false);

    test('by default the video and the first audio track are exported', () {
      final List<String> arguments = FragmentPlanner.exportArguments(
        input: 'in.mp4',
        output: 'out.mp4',
        fragment: fragment,
        settings: base,
      );

      expect(allAfter(arguments, '-map'), <String>['0:v:0?', '0:a:0?']);
    });

    test('enabling the option exports every audio track', () {
      final List<String> arguments = FragmentPlanner.exportArguments(
        input: 'in.mp4',
        output: 'out.mp4',
        fragment: fragment,
        settings: base.copyWith(keepAllAudioTracks: true),
      );

      expect(allAfter(arguments, '-map'), <String>['0:v:0?', '0:a?']);
    });

    test('mapping is optional, so a file without video still encodes', () {
      final List<String> arguments = FragmentPlanner.exportArguments(
        input: 'in.mp4',
        output: 'out.mp4',
        fragment: fragment,
        settings: base,
      );

      for (final String value in allAfter(arguments, '-map')) {
        expect(value, endsWith('?'), reason: value);
      }
    });

    test('the tempo filter is applied per stream, reaching every track', () {
      final List<String> arguments = FragmentPlanner.exportArguments(
        input: 'in.mp4',
        output: 'out.mp4',
        fragment: const Fragment(start: 0, end: 5, isSilence: true),
        settings: base.copyWith(keepAllAudioTracks: true),
      );

      // `-af` is `-filter:a`: each mapped audio stream gets its own copy.
      expect(argumentAfter(arguments, '-af'), 'atempo=2,atempo=2,atempo=2');
      expect(argumentAfter(arguments, '-c:a'), kAudioCodec);
    });

    test('the join keeps every stream instead of the first of each kind', () {
      final List<String> arguments = FragmentPlanner.concatArguments(
        listPath: 'list.txt',
        output: 'out.mp4',
      );

      // Without this the second audio track is dropped at the last step.
      expect(allAfter(arguments, '-map'), contains('0'));
      expect(argumentAfter(arguments, '-c:a'), 'copy');
    });
  });

  group('preview output naming', () {
    test('a preview does not compete with the real output', () {
      final MediaEntry entry = MediaEntry(r'C:\videos\lecture.mkv');

      expect(entry.outputNameFor(kKeepFormat), 'lecture.mkv');
      expect(
        entry.outputNameFor(kKeepFormat, suffix: ' (preview)'),
        'lecture (preview).mkv',
      );
      expect(
        entry.outputNameFor('mp4', suffix: ' (preview)'),
        'lecture (preview).mp4',
      );
    });

    test('a dotted name keeps its stem intact', () {
      final MediaEntry entry = MediaEntry('/home/vin/talk.2026.01.mov');

      expect(
        entry.outputNameFor(kKeepFormat, suffix: ' (preview)'),
        'talk.2026.01 (preview).mov',
      );
    });
  });
}
