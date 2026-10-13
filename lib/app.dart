// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'l10n/gen/app_localizations.dart';
import 'l10n/locale_controller.dart';
import 'state/preferences_store.dart';
import 'ui/app_shell.dart';
import 'ui/theme.dart';

class SilenceSpeedUpApp extends StatelessWidget {
  const SilenceSpeedUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    final PreferencesStore preferences = context.watch<PreferencesStore>();
    final LocaleController locales = context.watch<LocaleController>();

    return MaterialApp(
      title: 'Silence SpeedUp',
      debugShowCheckedModeBanner: false,
      themeMode: preferences.themeMode,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      // The controller has already resolved the system language against what
      // the app supports, so the choice is passed in rather than left to
      // Flutter's own resolution.
      locale: locales.activeLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const AppShell(),
    );
  }
}
