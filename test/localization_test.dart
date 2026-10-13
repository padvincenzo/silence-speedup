// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:silence_speedup/l10n/gen/app_localizations.dart';
import 'package:silence_speedup/l10n/labels.dart';
import 'package:silence_speedup/l10n/locale_controller.dart';
import 'package:silence_speedup/models/media_entry.dart';
import 'package:silence_speedup/models/options.dart';
import 'package:silence_speedup/models/processing_settings.dart';

/// Reads an ARB catalogue, dropping the `@`-prefixed metadata entries.
Map<String, Object?> readArb(String languageCode) {
  final File file = File('lib/l10n/arb/app_$languageCode.arb');
  expect(file.existsSync(), isTrue, reason: 'missing ${file.path}');
  final Map<String, dynamic> decoded =
      jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  decoded.removeWhere((String key, _) => key.startsWith('@'));
  return decoded;
}

void main() {
  group('locale resolution', () {
    test('follows the system when nothing is pinned', () {
      expect(
        LocaleController.resolve(
          null,
          systemLocales: <Locale>[const Locale('it', 'IT')],
        ),
        const Locale('it'),
      );
    });

    test('defaults to English for a language the app does not have', () {
      expect(
        LocaleController.resolve(
          null,
          systemLocales: <Locale>[const Locale('de'), const Locale('fr')],
        ),
        const Locale('en'),
      );
    });

    test('takes the first system language it supports', () {
      // The platform list is ordered by the user's own preference.
      expect(
        LocaleController.resolve(
          null,
          systemLocales: <Locale>[
            const Locale('de'),
            const Locale('it'),
            const Locale('en'),
          ],
        ),
        const Locale('it'),
      );
    });

    test('defaults to English when the system reports nothing', () {
      expect(
        LocaleController.resolve(null, systemLocales: <Locale>[]),
        const Locale('en'),
      );
    });

    test('a pinned language overrides the system', () {
      expect(
        LocaleController.resolve(
          const Locale('en'),
          systemLocales: <Locale>[const Locale('it')],
        ),
        const Locale('en'),
      );
    });

    test('an unsupported pin is ignored and the system decides again', () {
      expect(
        LocaleController.resolve(
          const Locale('de'),
          systemLocales: <Locale>[const Locale('it')],
        ),
        const Locale('it'),
      );
    });

    test('matches on language alone, ignoring the region', () {
      expect(LocaleController.isSupported(const Locale('it', 'CH')), isTrue);
      expect(LocaleController.isSupported(const Locale('en', 'AU')), isTrue);
      expect(LocaleController.isSupported(const Locale('es')), isFalse);
      expect(LocaleController.isSupported(null), isFalse);
    });

    test('exactly English and Italian are supported', () {
      expect(
        AppLocalizations.supportedLocales.map((Locale l) => l.languageCode),
        containsAll(<String>['en', 'it']),
      );
      expect(AppLocalizations.supportedLocales, hasLength(2));
      expect(LocaleController.fallbackLocale, const Locale('en'));
    });
  });

  group('ARB catalogues', () {
    test('Italian translates every English key, and adds none', () {
      final Set<String> english = readArb('en').keys.toSet();
      final Set<String> italian = readArb('it').keys.toSet();

      expect(
        italian.difference(english),
        isEmpty,
        reason: 'keys in Italian that the template does not define',
      );
      expect(
        english.difference(italian),
        isEmpty,
        reason: 'untranslated keys — these would fall back to English',
      );
    });

    test('no value was left as a copy of the English text', () {
      final Map<String, Object?> english = readArb('en');
      final Map<String, Object?> italian = readArb('it');

      // Deliberate exceptions: technical tokens, words that are the same in
      // both languages, and a value that is only a number and a unit.
      const Set<String> sharedByDesign = <String>{
        'settingsCrf',
        'settingsFps',
        'settingsPreset',
        'settingsGroupAudio',
        'previewSeconds',
        // Same string in both languages on purpose: what differs between them
        // is the decimal separator, and that comes from the number format,
        // not from the text.
        'settingsSecondsValue',
        'silencesPercent',
        'settingsNoiseValue',
        'aboutCopyright',
      };

      final List<String> copied = <String>[];
      for (final String key in english.keys) {
        if (sharedByDesign.contains(key)) continue;
        if (english[key] == italian[key]) copied.add(key);
      }

      expect(copied, isEmpty, reason: 'still in English: $copied');
    });
  });

  group('label resolution', () {
    late AppLocalizations english;
    late AppLocalizations italian;

    setUp(() async {
      english = await AppLocalizations.delegate.load(const Locale('en'));
      italian = await AppLocalizations.delegate.load(const Locale('it'));
    });

    test('every translated option label resolves in both languages', () {
      for (final OptionLabel label in OptionLabel.values) {
        expect(localizedLabel(label, english), isNotEmpty, reason: '$label');
        expect(localizedLabel(label, italian), isNotEmpty, reason: '$label');
      }
    });

    test('every status resolves in both languages', () {
      for (final EntryStatus status in EntryStatus.values) {
        expect(statusText(status, english), isNotEmpty, reason: '$status');
        expect(statusText(status, italian), isNotEmpty, reason: '$status');
      }
    });

    test('a group summary is empty until something is changed', () {
      const ProcessingSettings defaults = ProcessingSettings();

      expect(speedChanges(defaults, english), isEmpty);
      expect(audioChanges(defaults, english), isEmpty);
      expect(detectionChanges(defaults, english), isEmpty);
      expect(exportChanges(defaults, english), isEmpty);
      expect(previewChanges(defaults, english), isEmpty);
    });

    test('a group summary names the setting and its new value', () {
      const ProcessingSettings changed = ProcessingSettings(
        silenceSpeedIndex: 4,
        crf: 20,
      );

      expect(
        speedChanges(changed, english).single,
        allOf(contains('Silence speed'), contains(kSpeedOptions[4].label)),
      );
      expect(exportChanges(changed, english).single, contains('20'));
      // A change in one group says nothing about the others.
      expect(audioChanges(changed, english), isEmpty);
    });

    test('muting is summarised only while there is silence to mute', () {
      const ProcessingSettings muted = ProcessingSettings(muteSilences: true);
      expect(audioChanges(muted, english).single, 'Mute silences');

      // Removing the silences makes muting meaningless, and the summary has
      // to agree with what the run will actually do.
      final ProcessingSettings removed = muted.copyWith(
        silenceSpeedIndex: kSpeedOptions.length - 1,
      );
      expect(removed.dropsSilence, isTrue);
      expect(audioChanges(removed, english), isEmpty);
    });

    test('a duration in a summary uses the separator of the language', () {
      const ProcessingSettings margin = ProcessingSettings(
        silenceMargin: 0.25,
      );

      expect(detectionChanges(margin, english).single, contains('0.25'));
      expect(detectionChanges(margin, italian).single, contains('0,25'));
    });

    test('rates keep their numeric label, and only remove is translated', () {
      for (final SpeedOption option in kSpeedOptions) {
        if (option.isRemove) {
          expect(speedText(option, english), 'Remove');
          expect(speedText(option, italian), 'Rimuovi');
        } else {
          expect(speedText(option, english), option.label);
          expect(speedText(option, italian), option.label);
        }
      }
    });

    test('technical option values are not translated away', () {
      // The ffmpeg tokens must survive intact; only the words change.
      expect(optionText(kPresets[5], english), 'Medium');
      expect(optionText(kPresets[5], italian), 'Medium');
      expect(optionText(kFormats[0], english), 'Keep');
      expect(optionText(kFormats[0], italian), 'Mantieni');
      expect(optionText(kTunes[0], italian), 'Nessuno');
    });
  });

  group('formatted messages', () {
    test('numbers follow the locale, so Italian uses a decimal comma', () async {
      final AppLocalizations english = await AppLocalizations.delegate.load(
        const Locale('en'),
      );
      final AppLocalizations italian = await AppLocalizations.delegate.load(
        const Locale('it'),
      );

      expect(english.logSilencePercentage(12.5), contains('12.50'));
      expect(italian.logSilencePercentage(12.5), contains('12,50'));
      expect(english.statusSilenceShare(7.25), contains('7.3'));
      expect(italian.statusSilenceShare(7.25), contains('7,3'));
    });

    test('the file count is pluralised, not glued to a number', () async {
      final AppLocalizations english = await AppLocalizations.delegate.load(
        const Locale('en'),
      );

      expect(english.logFilesAdded(0), 'No files added.');
      expect(english.logFilesAdded(1), '1 file added.');
      expect(english.logFilesAdded(4), '4 files added.');
    });

    test('placeholders are substituted, not printed', () async {
      final AppLocalizations italian = await AppLocalizations.delegate.load(
        const Locale('it'),
      );

      expect(italian.logStarted('lezione.mp4'), contains('lezione.mp4'));
      expect(italian.logStarted('lezione.mp4'), isNot(contains('{')));
      expect(italian.menuVersion('0.9.0'), contains('0.9.0'));
      expect(
        italian.logOutputDirError('C:/out', 'accesso negato'),
        allOf(contains('C:/out'), contains('accesso negato')),
      );
    });
  });
}
