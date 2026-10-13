// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'l10n/locale_controller.dart';
import 'services/ffmpeg_runner.dart';
import 'state/log_store.dart';
import 'state/preferences_store.dart';
import 'state/process_store.dart';
import 'state/queue_store.dart';
import 'ui/platform.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Preferences are read first because the language pinned in a previous
  // session decides which catalogue to load before the first frame; with
  // nothing pinned, the controller follows the system and falls back to
  // English.
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final LocaleController locales = await LocaleController.create(
    preferred: PreferencesStore.storedLocale(prefs),
  );
  final PreferencesStore preferences = await PreferencesStore.load(
    prefs: prefs,
    locales: locales,
  );

  if (isDesktop) {
    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(
        size: Size(780, 820),
        minimumSize: Size(640, 480),
        center: true,
        title: 'Silence SpeedUp',
        titleBarStyle: TitleBarStyle.normal,
      ),
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }

  // One FFmpeg runner for the whole app: it is the only thing that knows how
  // to reach an encoder, and cancelling has to reach the running session.
  final FFmpegKitRunner runner = FFmpegKitRunner();
  final LogStore log = LogStore();
  final QueueStore queue = QueueStore(
    runner: runner,
    log: log,
    locales: locales,
  );
  final ProcessStore process = ProcessStore(
    runner: runner,
    queue: queue,
    preferences: preferences,
    log: log,
    locales: locales,
  );

  runApp(
    MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<LocaleController>.value(value: locales),
        ChangeNotifierProvider<PreferencesStore>.value(value: preferences),
        ChangeNotifierProvider<LogStore>.value(value: log),
        ChangeNotifierProvider<QueueStore>.value(value: queue),
        ChangeNotifierProvider<ProcessStore>.value(value: process),
      ],
      child: const SilenceSpeedUpApp(),
    ),
  );
}
