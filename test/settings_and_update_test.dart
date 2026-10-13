// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:silence_speedup/l10n/locale_controller.dart';
import 'package:silence_speedup/models/media_entry.dart';
import 'package:silence_speedup/models/options.dart';
import 'package:silence_speedup/models/processing_settings.dart';
import 'package:silence_speedup/services/update_checker.dart';
import 'package:silence_speedup/state/preferences_store.dart';

void main() {
  group('PreferencesStore', () {
    // The store reaches the platform for the system language and the
    // temporary folder, so it needs a binding even without a widget.
    setUp(() => TestWidgetsFlutterBinding.ensureInitialized());

    Future<PreferencesStore> load() async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return PreferencesStore.load(
        prefs: prefs,
        locales: await LocaleController.create(),
      );
    }

    test('keeps the encoding panel docked until told otherwise', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final PreferencesStore store = await load();
      expect(store.encodingPanelDocked, isTrue);

      await store.setEncodingPanelDocked(false);
      expect(store.encodingPanelDocked, isFalse);

      // Hiding the panel is a choice about how someone works, so it has to
      // survive a restart rather than coming back on the next launch.
      expect((await load()).encodingPanelDocked, isFalse);
    });
  });

  group('ProcessingSettings', () {
    test('defaults match the shipped configuration', () {
      const ProcessingSettings settings = ProcessingSettings();

      expect(settings.silenceSpeed.label, '8x');
      expect(settings.playbackSpeed.label, '1x');
      expect(settings.preset, 'medium');
      expect(settings.fps, 'fps=30:round=near');
      expect(settings.threshold, '-34dB');
      expect(settings.crf, 23);
      expect(settings.dropsSilence, isFalse);
    });

    test('writes the threshold as decibels for silencedetect', () {
      const ProcessingSettings settings = ProcessingSettings(
        thresholdDb: -34,
      );

      expect(settings.threshold, '-34dB');
      expect(settings.silenceDetectFilter, contains('n=-34dB'));
    });

    test('keeps the room a saved index used to name', () {
      // Three named steps, saved as 0, 1 or 2: they were amplitude ratios
      // of 0.002, 0.02 and 0.1, which are these decibels.
      for (int i = 0; i < kNoiseAnchors.length; i++) {
        final ProcessingSettings restored = ProcessingSettings.fromJson(
          <String, dynamic>{'thresholdIndex': i},
        );
        expect(restored.thresholdDb, kNoiseAnchors[i].db, reason: 'index $i');
      }
    });

    test('refuses a threshold off the scale', () {
      const ProcessingSettings defaults = ProcessingSettings();
      for (final int db in <int>[0, -200, 5]) {
        expect(
          ProcessingSettings.fromJson(<String, dynamic>{
            'thresholdDb': db,
          }).thresholdDb,
          defaults.thresholdDb,
          reason: '$db',
        );
      }
    });

    test('round-trips through JSON', () {
      const ProcessingSettings original = ProcessingSettings(
        thresholdDb: -20,
        silenceMinDuration: 0.45,
        silenceMargin: 0.2,
        silenceSpeedIndex: 11,
        playbackSpeedIndex: 4,
        muteSilences: true,
        outputFormat: 'mkv',
        crf: 19,
        presetIndex: 7,
        fpsIndex: 9,
        audioRateIndex: 3,
        tuneIndex: 2,
      );

      final ProcessingSettings restored = ProcessingSettings.fromJson(
        original.toJson(),
      );

      expect(restored.toJson(), original.toJson());
    });

    test('falls back to defaults for out-of-range persisted values', () {
      final ProcessingSettings restored = ProcessingSettings.fromJson(
        <String, dynamic>{
          'thresholdIndex': 99,
          'silenceSpeedIndex': -1,
          'playbackSpeedIndex': 999,
          'silenceMinDuration': 1000.0,
          'outputFormat': 'not-a-format',
          'crf': 900,
        },
      );

      const ProcessingSettings defaults = ProcessingSettings();
      expect(restored.thresholdDb, defaults.thresholdDb);
      expect(restored.silenceSpeedIndex, defaults.silenceSpeedIndex);
      expect(restored.playbackSpeedIndex, defaults.playbackSpeedIndex);
      expect(restored.silenceMinDuration, defaults.silenceMinDuration);
      expect(restored.outputFormat, defaults.outputFormat);
      expect(restored.crf, defaults.crf);
    });

    test('ignores garbage without throwing', () {
      final ProcessingSettings restored = ProcessingSettings.fromJson(
        <String, dynamic>{'crf': 'twenty', 'muteSilences': 'yes'},
      );

      expect(restored.crf, const ProcessingSettings().crf);
      expect(restored.muteSilences, isFalse);
    });

    test('removing the silence also switches muting off', () {
      const ProcessingSettings settings = ProcessingSettings(
        silenceSpeedIndex: 12,
        muteSilences: true,
      );

      expect(settings.dropsSilence, isTrue);
      expect(settings.mutesSilence, isFalse);
    });

    test('the detection window is the minimum plus both margins', () {
      const ProcessingSettings settings = ProcessingSettings(
        silenceMinDuration: 1.0,
        silenceMargin: 0.25,
      );

      expect(settings.detectionDuration, closeTo(1.5, 1e-9));
      expect(settings.silenceDetectFilter, contains('d=1.5'));
    });
  });

  group('speed catalogue', () {
    test('remove is last, so the playback slider can stop before it', () {
      expect(kSpeedOptions.last.isRemove, isTrue);
      expect(kSpeedOptions[kLastKeptSpeedIndex].isRemove, isFalse);
      expect(kRemoveSpeedIndex, kSpeedOptions.length - 1);
    });

    test('only remove lacks a rate, and only 1x lacks filters', () {
      for (final SpeedOption option in kSpeedOptions) {
        switch (option.kind) {
          case SpeedKind.scaled:
            expect(option.videoFilter, isNotNull, reason: option.label);
            expect(option.audioFilter, isNotNull, reason: option.label);
            expect(option.factor, greaterThan(0), reason: option.label);
          case SpeedKind.normal:
          case SpeedKind.remove:
            expect(option.videoFilter, isNull, reason: option.label);
            expect(option.audioFilter, isNull, reason: option.label);
        }
      }
    });

    test('each scaled option states the rate its label advertises', () {
      for (final SpeedOption option in kSpeedOptions) {
        if (option.kind != SpeedKind.scaled) continue;
        final double advertised = double.parse(
          option.label.replaceAll('x', ''),
        );
        expect(option.factor, closeTo(advertised, 1e-9), reason: option.label);
      }
    });
  });

  group('MediaEntry', () {
    test('accepts the formats the app can export and rejects the rest', () {
      expect(MediaEntry.isSupported(r'C:\videos\lecture.mp4'), isTrue);
      expect(MediaEntry.isSupported('/home/vin/talk.MKV'), isTrue);
      expect(MediaEntry.isSupported('/home/vin/notes.txt'), isFalse);
      expect(MediaEntry.isSupported('/home/vin/noextension'), isFalse);
    });

    test('renames only the extension when the container changes', () {
      final MediaEntry entry = MediaEntry(r'C:\videos\my.lecture.mov');

      expect(entry.name, 'my.lecture.mov');
      expect(entry.outputNameFor(kKeepFormat), 'my.lecture.mov');
      expect(entry.outputNameFor('mp4'), 'my.lecture.mp4');
      expect(entry.outputExtensionFor(kKeepFormat), 'mov');
      expect(entry.outputExtensionFor('mp4'), 'mp4');
    });

    test('reports the share of silence it found', () {
      final MediaEntry entry = MediaEntry('/tmp/a.mp4')
        ..duration = const Duration(seconds: 100)
        ..setSilences(const <SilenceRange>[
          SilenceRange(0, 10),
          SilenceRange(50, 65),
        ]);

      expect(entry.silenceSeconds, closeTo(25, 1e-9));
      expect(entry.silenceRatio, closeTo(0.25, 1e-9));
    });

    test('is not processable until a duration is known', () {
      final MediaEntry entry = MediaEntry('/tmp/a.mp4');
      expect(entry.isProcessable, isFalse);
      expect(entry.silenceRatio, isNull);

      entry.duration = const Duration(seconds: 5);
      expect(entry.isProcessable, isTrue);
    });
  });

  group('UpdateChecker', () {
    test('answers null without a network call when it is switched off', () async {
      // What a Microsoft Store build compiles to: the Store is the update
      // mechanism there, so the app must not go looking. The unreachable
      // feed URL is the assertion — a check that ran would have to fail on
      // it, and this returns null immediately instead.
      const UpdateChecker checker = UpdateChecker(
        feedUrl: 'http://127.0.0.1:9/releases.atom',
        enabled: false,
      );

      expect(await checker.check('0.0.1'), isNull);
    });
  });

  group('UpdateChecker.compareVersions', () {
    test('compares component by component, not as one number', () {
      // The Electron version stripped the dots, making 2.1.0 look older.
      expect(UpdateChecker.compareVersions('2.1.0', '2.0.10'), greaterThan(0));
    });

    test('treats missing components as zero', () {
      expect(UpdateChecker.compareVersions('1.2', '1.2.0'), 0);
      expect(UpdateChecker.compareVersions('1.3', '1.2.9'), greaterThan(0));
    });

    test('ignores a leading v and a pre-release suffix', () {
      expect(UpdateChecker.compareVersions('v1.0.0', '1.0.0'), 0);
      expect(UpdateChecker.compareVersions('1.0.0-beta.2', '1.0.0'), 0);
    });

    test('orders older below newer', () {
      expect(UpdateChecker.compareVersions('0.9.0', '1.0.0'), lessThan(0));
    });
  });
}
