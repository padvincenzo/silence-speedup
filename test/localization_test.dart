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

/// Values that are the same in English and in every translation on purpose:
/// technical tokens, and values that are only a number and a unit — what
/// differs between languages there is the decimal separator, and that comes
/// from the number format, not from the text.
const Set<String> _sharedByDesign = <String>{
  'settingsCrf',
  'settingsFps',
  'settingsPreset',
  'previewSeconds',
  'settingsSecondsValue',
  'silencesPercent',
  'settingsNoiseValue',
  'aboutCopyright',
};

/// Words a particular language shares with English. `settingsTune` is x264's
/// own name for the option, which German, Spanish and Japanese keep as it is.
const Map<String, Set<String>> _sharedInLanguage = <String, Set<String>>{
  'de': <String>{
    'menuVersion',
    'processStart',
    'settingsGroupAudio',
    'settingsGroupExport',
    'settingsTune',
    'uiSystemMode',
    'updateDetails',
  },
  'es': <String>{'settingsGroupAudio', 'settingsTune'},
  'fr': <String>{
    'aboutLicenseSection',
    'licensesCount',
    'menuVersion',
    'settingsGroupApp',
    'settingsGroupAudio',
    'settingsGroupExport',
    'silencesTotal',
  },
  'it': <String>{'settingsGroupAudio'},
  'ja': <String>{'settingsTune'},
};

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
          systemLocales: <Locale>[const Locale('ko'), const Locale('zh')],
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
            const Locale('ko'),
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
          const Locale('ko'),
          systemLocales: <Locale>[const Locale('it')],
        ),
        const Locale('it'),
      );
    });

    test('matches on language alone, ignoring the region', () {
      expect(LocaleController.isSupported(const Locale('it', 'CH')), isTrue);
      expect(LocaleController.isSupported(const Locale('en', 'AU')), isTrue);
      expect(LocaleController.isSupported(const Locale('ko')), isFalse);
      expect(LocaleController.isSupported(null), isFalse);
    });

    test('the picker names exactly the languages the app has', () {
      expect(
        AppLocalizations.supportedLocales
            .map((Locale l) => l.languageCode)
            .toSet(),
        kLanguageNames.keys.toSet(),
      );
      expect(LocaleController.fallbackLocale, const Locale('en'));
    });
  });

  group('ARB catalogues', () {
    final List<String> translations = kLanguageNames.keys
        .where((String code) => code != 'en')
        .toList();

    for (final String code in translations) {
      test('$code translates every English key, and adds none', () {
        final Set<String> english = readArb('en').keys.toSet();
        final Set<String> translated = readArb(code).keys.toSet();

        expect(
          translated.difference(english),
          isEmpty,
          reason: 'keys in $code that the template does not define',
        );
        expect(
          english.difference(translated),
          isEmpty,
          reason: 'untranslated keys — these would fall back to English',
        );
      });

      test('$code keeps every placeholder of the English text', () {
        final Map<String, Object?> english = readArb('en');
        final Map<String, Object?> translated = readArb(code);

        // A placeholder renamed or dropped in a translation is not a build
        // error: gen-l10n prints the literal braces instead.
        final RegExp placeholder = RegExp(r'\{(\w+)[,}]');
        Set<String> names(Object? value) => placeholder
            .allMatches('$value')
            .map((RegExpMatch m) => m.group(1)!)
            .toSet();

        final List<String> broken = <String>[];
        for (final String key in english.keys) {
          if (names(english[key])
              .difference(names(translated[key]))
              .isNotEmpty) {
            broken.add(key);
          }
        }

        expect(broken, isEmpty, reason: 'placeholders lost in $code: $broken');
      });

      test('$code left no value as a copy of the English text', () {
        final Map<String, Object?> english = readArb('en');
        final Map<String, Object?> translated = readArb(code);

        final Set<String> shared = <String>{
          ..._sharedByDesign,
          ...?_sharedInLanguage[code],
        };

        final List<String> copied = <String>[];
        for (final String key in english.keys) {
          if (shared.contains(key)) continue;
          if (english[key] == translated[key]) copied.add(key);
        }

        expect(copied, isEmpty, reason: 'still in English in $code: $copied');
      });
    }
  });

  group('label resolution', () {
    late AppLocalizations english;
    late AppLocalizations italian;
    late List<AppLocalizations> all;

    setUp(() async {
      english = await AppLocalizations.delegate.load(const Locale('en'));
      italian = await AppLocalizations.delegate.load(const Locale('it'));
      all = <AppLocalizations>[
        for (final Locale locale in AppLocalizations.supportedLocales)
          await AppLocalizations.delegate.load(locale),
      ];
    });

    test('every translated option label resolves in every language', () {
      for (final AppLocalizations strings in all) {
        for (final OptionLabel label in OptionLabel.values) {
          expect(
            localizedLabel(label, strings),
            isNotEmpty,
            reason: '${strings.localeName} $label',
          );
        }
      }
    });

    test('every status resolves in every language', () {
      for (final AppLocalizations strings in all) {
        for (final EntryStatus status in EntryStatus.values) {
          expect(
            statusText(status, strings),
            isNotEmpty,
            reason: '${strings.localeName} $status',
          );
        }
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
      const ProcessingSettings margin = ProcessingSettings(silenceMargin: 0.25);

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
    test(
      'numbers follow the locale, so Italian uses a decimal comma',
      () async {
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
      },
    );

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
