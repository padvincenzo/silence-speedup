// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:silence_speedup/app.dart';
import 'package:silence_speedup/l10n/gen/app_localizations.dart';
import 'package:silence_speedup/l10n/locale_controller.dart';
import 'package:silence_speedup/models/media_entry.dart';
import 'package:silence_speedup/models/processing_settings.dart';
import 'package:silence_speedup/services/ffmpeg_runner.dart';
import 'package:silence_speedup/state/log_store.dart';
import 'package:silence_speedup/state/preferences_store.dart';
import 'package:silence_speedup/state/process_store.dart';
import 'package:silence_speedup/state/queue_store.dart';
import 'package:silence_speedup/ui/pages/about_page.dart';
import 'package:silence_speedup/ui/messages.dart';
import 'package:silence_speedup/ui/pages/app_settings_page.dart';
import 'package:silence_speedup/ui/pages/license_text_page.dart';
import 'package:silence_speedup/ui/pages/licenses_page.dart';
import 'package:silence_speedup/ui/pages/queue_page.dart';
import 'package:silence_speedup/ui/pages/silences_page.dart';
import 'package:silence_speedup/ui/widgets/compact_progress_view.dart';
import 'package:silence_speedup/ui/widgets/encoding_settings_panel.dart';
import 'package:silence_speedup/ui/widgets/output_destination.dart';
import 'package:silence_speedup/ui/widgets/readable_width.dart';
import 'package:silence_speedup/ui/widgets/scrolled_under.dart';
import 'package:silence_speedup/ui/widgets/silence_timeline.dart';
import 'package:silence_speedup/ui/widgets/encoding_settings_view.dart';
import 'package:silence_speedup/ui/theme.dart';

/// An [FFmpegRunner] that never touches an encoder.
///
/// The interface exists so the app can be driven without one; this is the
/// fixture that takes advantage of it.
class FakeFFmpegRunner implements FFmpegRunner {
  int cancels = 0;
  final List<List<String>> invocations = <List<String>>[];

  /// What a run reports having printed, for the runs that are asked.
  String output = '';

  @override
  Future<Duration?> probeDuration(String path) async =>
      const Duration(minutes: 10);

  @override
  Future<FFmpegResult> run(
    List<String> arguments, {
    void Function(String line)? onLine,
    void Function(FFmpegProgress progress)? onProgress,
    bool collectOutput = false,
  }) async {
    invocations.add(arguments);
    return FFmpegResult(
      succeeded: true,
      cancelled: false,
      exitCode: 0,
      output: collectOutput ? output : '',
    );
  }

  @override
  Future<void> cancel() async => cancels++;
}

/// The five stores the UI reads, wired the way `main` wires them.
class TestHarness {
  TestHarness._(
    this.locales,
    this.preferences,
    this.log,
    this.queue,
    this.process,
    this.runner,
  );

  final LocaleController locales;
  final PreferencesStore preferences;
  final LogStore log;
  final QueueStore queue;
  final ProcessStore process;
  final FakeFFmpegRunner runner;

  static Future<TestHarness> create({Locale? preferred}) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final LocaleController locales = await LocaleController.create(
      preferred: preferred,
    );
    final PreferencesStore preferences = await PreferencesStore.load(
      prefs: prefs,
      locales: locales,
    );

    final FakeFFmpegRunner runner = FakeFFmpegRunner();
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

    return TestHarness._(locales, preferences, log, queue, process, runner);
  }

  List<SingleChildWidget> get providers => <SingleChildWidget>[
    ChangeNotifierProvider<LocaleController>.value(value: locales),
    ChangeNotifierProvider<PreferencesStore>.value(value: preferences),
    ChangeNotifierProvider<LogStore>.value(value: log),
    ChangeNotifierProvider<QueueStore>.value(value: queue),
    ChangeNotifierProvider<ProcessStore>.value(value: process),
  ];

  /// Wraps [child] in the providers and a MaterialApp, for testing one page.
  ///
  /// The real theme is installed rather than Flutter's default: the app's
  /// own tile and text styles are part of what these tests are watching.
  Widget wrap(Widget child, {Brightness brightness = Brightness.light}) {
    return MultiProvider(
      providers: providers,
      child: MaterialApp(
        theme: buildAppTheme(brightness),
        locale: locales.activeLocale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(body: child),
      ),
    );
  }

  /// The whole app, as `main` assembles it.
  Widget get app =>
      MultiProvider(providers: providers, child: const SilenceSpeedUpApp());
}

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Silence SpeedUp',
      packageName: 'com.padvincenzo.silence_speedup',
      version: '0.9.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  /// A desktop-sized surface, so a layout that only fits on a phone fails.
  Future<void> useDesktopSurface(WidgetTester tester, {Size? size}) async {
    tester.view.physicalSize = size ?? const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  group('app shell', () {
    testWidgets('opens on the queue with Start and the import actions', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(tester);
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Silence SpeedUp'), findsWidgets);
      expect(find.text('Start'), findsOneWidget);

      // One button for both kinds of import, and both behind it.
      expect(find.text('Add'), findsOneWidget);
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(find.text('Add video(s)'), findsOneWidget);
      expect(find.text('Add folder'), findsOneWidget);
      // It says which keys do the same thing without the menu.
      expect(find.textContaining('Ctrl'), findsWidgets);

      // The button closes what it opened.
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(find.text('Add folder'), findsNothing);
      // The queue starts empty, so Start has nothing to do yet.
      expect(
        tester
            .widget<FloatingActionButton>(find.byType(FloatingActionButton))
            .onPressed,
        isNull,
      );
    });

    testWidgets('has no menu bar left over from the Electron build', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(tester);
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();

      expect(find.byType(MenuBar), findsNothing);
      // Navigation is a drawer instead.
      expect(find.byIcon(Icons.menu), findsOneWidget);
    });

    testWidgets('a page reached from the drawer offers the way back', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(tester);
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();

      // The queue is where the drawer is opened from.
      expect(find.byIcon(Icons.menu), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('App settings'));
      await tester.pumpAndSettle();

      // Offering the drawer again from a page the drawer sent you to is a
      // way round, not a way back.
      expect(find.byType(BackButton), findsOneWidget);
      expect(find.byIcon(Icons.menu), findsNothing);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Add'), findsOneWidget);
      expect(find.byIcon(Icons.menu), findsOneWidget);
    });

    testWidgets('quitting closes the window the way the title bar does', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(tester);
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      final List<String> calls = <String>[];
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('window_manager'),
              null,
            ),
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('window_manager'),
            (MethodCall call) async {
              calls.add(call.method);
              return null;
            },
          );

      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quit'));
      await tester.pumpAndSettle();

      // The plugin's destroy() is PostQuitMessage: it ends the message loop
      // and leaves the window on screen for the whole of the engine's
      // shutdown, which is what made quitting look slow. close() posts the
      // WM_CLOSE the title bar posts, and that path measures 154ms.
      expect(calls, contains('close'));
      expect(calls, isNot(contains('destroy')));
    });

    testWidgets('the drawer navigates to settings and to about', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(tester);
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationDrawer), findsOneWidget);

      await tester.tap(find.text('App settings'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // The application page carries what is set once, and nothing that
      // decides how a video is encoded.
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Silence speed'), findsNothing);

      // Back to the queue first: a page the drawer sent you to shows the
      // way back rather than the drawer again.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Version 0.9.0'), findsWidgets);
    });

    testWidgets('one control shows the rates and opens the settings', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(tester);
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();

      // The defaults are 8x for silences and 1x for speech, and there is
      // exactly one place that says so: the app bar button that opens the
      // panel. A second control on the queue used to duplicate it.
      expect(find.text('8x / 1x'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('8x / 1x'),
        ),
        findsOneWidget,
      );

      await harness.preferences.updateSettings(
        harness.preferences.settings.copyWith(silenceSpeedIndex: 4),
      );
      await tester.pumpAndSettle();
      expect(find.text('8x / 1x'), findsNothing);
      expect(find.textContaining('/ 1x'), findsOneWidget);
    });
  });

  group('what a message is beside', () {
    testWidgets('sits at the Start button level, and stops short of it', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(tester, size: const Size(1400, 900));
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();

      showAppMessage(tester.element(find.byType(QueuePage)), 'Done');
      await tester.pumpAndSettle();

      final Rect button = tester.getRect(find.byType(FloatingActionButton));
      // The visible pill, not the snack bar's box: the box carries the
      // margin that puts the pill where it is.
      final Rect pill = tester.getRect(
        find
            .descendant(
              of: find.byType(SnackBar),
              matching: find.byType(Material),
            )
            .first,
      );

      // A floating snack bar is anchored above a FloatingActionButton by the
      // Scaffold showing it, which is why the body has a Scaffold of its own
      // without one.
      expect(pill.bottom, closeTo(button.bottom, 1));
      expect(pill.right, lessThanOrEqualTo(button.left));
      expect(pill.width, greaterThan(200));
    });
  });

  group('two strips, one rule', () {
    testWidgets('the queue toolbar and the panel title bar line up', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(tester, size: const Size(1400, 900));
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();

      double ruleUnder(Finder strip) => tester
          .getRect(
            find.descendant(of: strip, matching: find.byType(Divider)).first,
          )
          .top;

      // Side by side on a wide window, so a four-pixel difference between
      // the two rules is invisible until it is seen, and then it is all
      // that can be seen.
      expect(
        ruleUnder(find.byType(QueuePage)),
        ruleUnder(find.byType(DockedEncodingSettings)),
      );
    });
  });

  group('queue toolbar', () {
    testWidgets('filling and emptying sit at opposite ends of one row', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(tester, size: const Size(1400, 900));
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final Rect add = tester.getRect(find.text('Add'));
      final Rect clear = tester.getRect(find.byIcon(Icons.playlist_remove));
      final Rect page = tester.getRect(find.byType(QueuePage));

      // Same row, and pushed apart: they pull in opposite directions.
      expect(clear.center.dy, add.center.dy);
      expect(add.left - page.left, lessThan(60));
      expect(page.right - clear.right, lessThan(60));

      // Emptying the queue is an icon: a once-in-a-while action, and it was
      // an icon in the app bar before it came here.
      expect(find.text('Clear queue'), findsNothing);

      // The destination is a setting about exporting, and it moved there.
      expect(find.byType(OutputDestination), findsNothing);
    });

    testWidgets('the destination is a setting in the export group', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(tester, size: const Size(1400, 900));
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();

      // The panel is docked at this width, with Export closed and nothing
      // to report: exports follow their source unless told otherwise.
      expect(find.byType(OutputDestination), findsNothing);

      await harness.preferences.setFixedDirectory('/media/Renders');
      await tester.pumpAndSettle();

      // A chosen folder is a change from the default, so the closed group
      // says so -- by its name, since the whole path would not fit.
      expect(find.text('Export to Renders'), findsOneWidget);

      await tester.tap(find.text('Export'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(OutputDestination), findsOneWidget);
      // The path is editable once a folder is what is wanted.
      expect(find.byType(TextField), findsOneWidget);

      // And the toggle fits the panel: with icons it ran past the window,
      // and a control that has to be scrolled sideways to be read is worse
      // than a short label.
      expect(
        tester.getSize(find.byType(SegmentedButton<OutputMode>)).width,
        lessThanOrEqualTo(kEncodingPanelWidth - 32),
      );

      // Both choices are named and on screen, with the live one pressed:
      // as a single chip, the off state meant something without saying
      // what. Going back to the source hides the path with it.
      expect(find.text('Beside the source'), findsOneWidget);
      expect(find.text('A folder I pick'), findsOneWidget);

      await tester.tap(find.text('Beside the source'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Export to Renders'), findsNothing);
    });

    testWidgets('the toolbar takes the shadow, not the app bar', (
      WidgetTester tester,
    ) async {
      // Short, so a handful of rows overflows it.
      await useDesktopSurface(tester, size: const Size(900, 480));
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );
      await harness.queue.addFiles(<String>[
        for (int i = 0; i < 12; i++) '/videos/clip$i.mp4',
      ]);

      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();

      double elevationOf(Finder of) => tester
          .widget<Material>(
            find.descendant(of: of, matching: find.byType(Material)).first,
          )
          .elevation;

      expect(elevationOf(find.byType(ScrolledUnder)), 0);
      expect(elevationOf(find.byType(AppBar)), 0);

      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();

      // The rows go under the toolbar, so the toolbar lifts and the bar
      // above it -- which nothing is passing under -- stays flat.
      expect(elevationOf(find.byType(ScrolledUnder)), greaterThan(0));
      expect(elevationOf(find.byType(AppBar)), 0);
    });

    testWidgets('the log has one switch, and it is not in the app bar', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(tester);
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();

      // It lives in the status strip, beside the console it opens.
      expect(find.byIcon(Icons.terminal_outlined), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byIcon(Icons.terminal_outlined),
        ),
        findsNothing,
      );
      // And so does emptying the queue, which is a queue action.
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byIcon(Icons.playlist_remove),
        ),
        findsNothing,
      );
    });
  });

  group('silence detection', () {
    testWidgets('reads the silences from the whole log, not the stream', (
      WidgetTester tester,
    ) async {
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );
      // A file that exists, because a run skips one that has gone missing.
      final Directory folder = Directory.systemTemp.createTempSync('ssu_');
      addTearDown(() => folder.deleteSync(recursive: true));
      final File video = File('${folder.path}${Platform.pathSeparator}talk.mp4')
        ..writeAsBytesSync(<int>[0]);
      await harness.queue.addFiles(<String>[video.path]);
      final MediaEntry entry = harness.queue.entries.single;

      // The fake streams nothing, which is what a session that finished
      // with its log still in flight looks like from the callback: once,
      // that kept one silence of six. Every boundary is in the log the
      // session hands back.
      harness.runner.output = '''
[silencedetect @ 0x1] silence_start: 2
[silencedetect @ 0x1] silence_end: 5 | silence_duration: 3
[silencedetect @ 0x1] silence_start: 7
[silencedetect @ 0x1] silence_end: 10 | silence_duration: 3
[silencedetect @ 0x1] silence_start: 12
[silencedetect @ 0x1] silence_end: 15 | silence_duration: 3
''';

      // Real time rather than the test clock: the run waits on futures that
      // a frame pump would never complete.
      await tester.runAsync(() => harness.process.analyze(entry));

      expect(entry.silences, hasLength(3));
    });
  });

  group('encoding settings', () {
    testWidgets('are docked beside the queue on a wide window', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(tester, size: const Size(1280, 900));
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();

      // Docked from the start: on a window this wide there is no reason to
      // make someone ask for them.
      expect(find.byType(DockedEncodingSettings), findsOneWidget);
      expect(find.text('Silence speed'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Start floats over the queue, not over a setting.
      expect(
        tester.getBottomRight(find.byType(FloatingActionButton)).dx,
        lessThan(tester.getTopLeft(find.byType(DockedEncodingSettings)).dx),
      );

      // Scoped to the app bar: the panel's own header carries the same
      // tooltip, since hiding it is exactly what its close button does.
      Finder barButton(String tooltip) => find.descendant(
        of: find.byType(AppBar),
        matching: find.byTooltip(tooltip),
      );

      await tester.tap(barButton('Hide the encoding settings'));
      await tester.pumpAndSettle();
      expect(find.byType(DockedEncodingSettings), findsNothing);

      await tester.tap(barButton('Show the encoding settings'));
      await tester.pumpAndSettle();
      expect(find.byType(DockedEncodingSettings), findsOneWidget);
    });

    testWidgets('open as a side sheet on a narrow window, and close again', (
      WidgetTester tester,
    ) async {
      // The minimum window size the app allows.
      await useDesktopSurface(tester, size: const Size(640, 480));
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();

      expect(find.byType(DockedEncodingSettings), findsNothing);
      expect(find.text('Silence speed'), findsNothing);

      // The rates chip is the shortcut in: it is what a user looks at
      // before every run anyway.
      await tester.tap(find.text('8x / 1x'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Encoding settings'), findsOneWidget);
      expect(find.text('Silence speed'), findsOneWidget);

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Silence speed'), findsNothing);
    });

    testWidgets('closed groups say what was changed inside them', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(tester);
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      await tester.pumpWidget(harness.wrap(const EncodingSettingsView()));
      await tester.pumpAndSettle();

      // Only the speeds start open, so the other four groups are one line
      // each -- and with nothing changed, that line is a single word.
      expect(find.text('Default'), findsNWidgets(4));
      expect(find.text('CRF'), findsNothing);

      await harness.preferences.updateSettings(
        harness.preferences.settings.copyWith(crf: 20),
      );
      await tester.pumpAndSettle();

      expect(find.text('Default'), findsNWidgets(3));
      expect(find.text('CRF 20'), findsOneWidget);
      // Still closed: the summary is what it says while shut.
      expect(find.byType(Slider), findsNWidgets(2));
    });

    testWidgets('opening a group reveals its controls, and is remembered', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(tester);
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      await tester.pumpWidget(harness.wrap(const EncodingSettingsView()));
      await tester.pumpAndSettle();

      expect(harness.preferences.openEncodingGroups, <String>{'speed'});

      await tester.tap(find.text('Export'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('CRF'), findsOneWidget);
      expect(
        harness.preferences.openEncodingGroups,
        containsAll(<String>['speed', 'export']),
      );

      // Closing it puts the summary back and takes the controls away.
      await tester.tap(find.text('Export'));
      await tester.pumpAndSettle();
      expect(find.text('CRF'), findsNothing);
      expect(harness.preferences.openEncodingGroups, isNot(contains('export')));
    });

    testWidgets('detection comes before the audio it decides for', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(tester);
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      await tester.pumpWidget(harness.wrap(const EncodingSettingsView()));
      await tester.pumpAndSettle();

      // Detection decides what a silence is; the audio settings act on what
      // it found.
      expect(
        tester.getRect(find.text('Silence detection')).top,
        lessThan(tester.getRect(find.text('Audio')).top),
      );
      expect(
        tester.getRect(find.text('Speed')).top,
        lessThan(tester.getRect(find.text('Silence detection')).top),
      );
    });

    testWidgets('an open group keeps its heading in view while it scrolls', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(tester, size: const Size(1400, 700));
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      // Two groups open, so there is a heading to be pushed off by another.
      await harness.preferences.setEncodingGroupOpen('detection', true);

      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();

      // Scoped to the panel: the status strip has a Speed readout of its
      // own, which is a different Speed entirely.
      final Finder heading = find.descendant(
        of: find.byType(DockedEncodingSettings),
        matching: find.text('Speed'),
      );
      final double headingTop = tester.getRect(heading).top;

      await tester.drag(
        find.byType(CustomScrollView).last,
        const Offset(0, -120),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Its own controls have moved up under it; the heading has not moved.
      expect(heading, findsOneWidget);
      expect(tester.getRect(heading).top, headingTop);
      expect(find.text('Silence speed'), findsOneWidget);
    });

    testWidgets('a pinned heading lifts once its controls pass under it', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(tester, size: const Size(1400, 700));
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();

      final Finder title = find.descendant(
        of: find.byType(DockedEncodingSettings),
        matching: find.text('Speed'),
      );
      double headingElevation() => tester
          .widget<Material>(
            find.ancestor(of: title, matching: find.byType(Material)).first,
          )
          .elevation;

      // At the top of the panel the heading has controls below it, not
      // under it.
      expect(headingElevation(), 0);

      await tester.drag(
        find.byType(CustomScrollView).last,
        const Offset(0, -60),
      );
      await tester.pumpAndSettle();

      // The framework cannot tell a pinned header this: the overlapsContent
      // it is handed means another pinned sliver is over it, which is a
      // different thing and false here.
      expect(headingElevation(), greaterThan(0));
    });

    testWidgets('a heading in the middle of the list stays flat', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(tester, size: const Size(1400, 700));
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      // Detection open, the speeds shut: its heading starts well down the
      // panel, with two shut groups above it.
      await harness.preferences.setEncodingGroupOpen('speed', false);
      await harness.preferences.setEncodingGroupOpen('detection', true);

      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();

      final Finder title = find.descendant(
        of: find.byType(DockedEncodingSettings),
        matching: find.text('Silence detection'),
      );
      double headingElevation() => tester
          .widget<Material>(
            find.ancestor(of: title, matching: find.byType(Material)).first,
          )
          .elevation;

      final Finder panelScroll = find.descendant(
        of: find.byType(DockedEncodingSettings),
        matching: find.byType(CustomScrollView),
      );

      // Scrolled a little: the panel has moved, but this heading has not
      // reached the top and nothing is passing under it. Asking whether the
      // panel had scrolled at all shadowed it here, which is wrong.
      await tester.drag(panelScroll, const Offset(0, -30));
      await tester.pumpAndSettle();
      expect(headingElevation(), 0);

      // Far enough for its own controls to start going under it.
      await tester.drag(panelScroll, const Offset(0, -260));
      await tester.pumpAndSettle();
      expect(headingElevation(), greaterThan(0));
    });

    testWidgets('open headings take turns rather than piling up', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(tester, size: const Size(1400, 700));
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      // Every group open: the case where pinned headings, left to
      // themselves, end as a stack of five with no room for the controls.
      for (final String group in <String>[
        'speed',
        'audio',
        'detection',
        'export',
        'preview',
      ]) {
        await harness.preferences.setEncodingGroupOpen(group, true);
      }

      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();

      final Finder panel = find.byType(DockedEncodingSettings);
      expect(
        find.descendant(of: panel, matching: find.text('Speed')),
        findsOneWidget,
      );

      await tester.drag(
        find.byType(CustomScrollView).last,
        const Offset(0, -700),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Its own controls are long gone, so its heading went with them.
      expect(
        find.descendant(of: panel, matching: find.text('Speed')),
        findsNothing,
      );
      // At most the one holding the top, plus whichever is arriving to take
      // it. Pinned slivers of a viewport accumulate if nothing scopes them,
      // and five headings on a 700-pixel panel leave no room for controls.
      final int headings =
          <String>['Speed', 'Audio', 'Silence detection', 'Export', 'Preview']
              .map(
                (String label) => find
                    .descendant(of: panel, matching: find.text(label))
                    .evaluate()
                    .length,
              )
              .reduce((int a, int b) => a + b);

      expect(headings, greaterThan(0));
      expect(headings, lessThanOrEqualTo(2));
    });

    testWidgets('the noise threshold is a scale, measured against a file', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(tester);
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );
      await harness.preferences.setEncodingGroupOpen('detection', true);
      await harness.queue.addFiles(<String>['/videos/talk.mp4']);

      await tester.pumpWidget(harness.wrap(const EncodingSettingsView()));
      await tester.pumpAndSettle();

      // A number with a unit, not one of three names twenty decibels apart,
      // and it says which video it is offering to measure.
      expect(find.text('-34 dB'), findsOneWidget);
      expect(find.text('Measure talk.mp4'), findsOneWidget);

      // What FFmpeg prints, and when it prints it: the summary comes out as
      // the filter closes, which is why the run is asked for its collected
      // output instead of what the streaming callback happened to deliver.
      harness.runner.output = '''
[Parsed_astats_0 @ 000001] Channel: 1
[Parsed_astats_0 @ 000001] RMS level dB: -18.000000
[Parsed_astats_0 @ 000001] Noise floor dB: -48.000000
[Parsed_astats_0 @ 000001] Overall
[Parsed_astats_0 @ 000001] RMS level dB: -18.000000
[Parsed_astats_0 @ 000001] Noise floor dB: -48.000000
''';

      await tester.tap(find.text('Measure talk.mp4'));
      await tester.pumpAndSettle();

      // It asked FFmpeg for the levels of that file.
      expect(
        harness.runner.invocations.last,
        containsAllInOrder(<String>['-af', 'astats=metadata=1:reset=0']),
      );
      // And said so where someone would look for it.
      expect(
        harness.log.lines.map((LogLine line) => line.message),
        contains('Measuring the levels of talk.mp4...'),
      );

      expect(
        find.text('talk.mp4: hiss at -48 dB, voice at -18 dB'),
        findsOneWidget,
      );

      // Halfway between the two, named rather than ordered about, and in
      // the same card as the reading it comes from.
      expect(
        find.ancestor(
          of: find.text('Suggested: -33 dB'),
          matching: find.ancestor(
            of: find.textContaining('hiss at -48 dB'),
            matching: find.byType(Container),
          ),
        ),
        findsWidgets,
      );

      await tester.tap(find.text('Suggested: -33 dB'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(harness.preferences.settings.thresholdDb, -33);
      expect(find.text('-33 dB'), findsOneWidget);
    });

    testWidgets('a measurement that reads nothing says so', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(tester);
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );
      await harness.preferences.setEncodingGroupOpen('detection', true);
      await harness.queue.addFiles(<String>['/videos/silent.mp4']);

      await tester.pumpWidget(harness.wrap(const EncodingSettingsView()));
      await tester.pumpAndSettle();

      // A file with no audio prints no levels.
      harness.runner.output = '';
      await tester.tap(find.text('Measure silent.mp4'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Not the button back as though nothing had happened -- and not a
      // claim about the file either: the app knows it could not read the
      // levels, not that there was nothing to read.
      expect(find.textContaining('Could not read the levels'), findsOneWidget);

      final List<String> logged = harness.log.lines
          .map((LogLine line) => line.message)
          .toList();
      expect(logged, contains('Could not read the levels of silent.mp4.'));
      // With what FFmpeg actually answered, because a failure that explains
      // nothing has to be reproduced to be understood.
      expect(logged.any((String line) => line.contains('FFmpeg exited')), isTrue);
    });

    testWidgets('the reset asks first, and only then puts everything back', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(tester);
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );
      await harness.preferences.updateSettings(
        harness.preferences.settings.copyWith(crf: 20),
      );

      await tester.pumpWidget(harness.wrap(const EncodingSettingsView()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      // There is no undo for it, so it asks -- and says what it will undo.
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Reset the encoding settings'), findsOneWidget);
      expect(find.textContaining('back to its default'), findsOneWidget);

      final Finder confirm = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Reset'),
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(harness.preferences.settings.crf, 20, reason: 'cancel undid it');

      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(harness.preferences.settings, const ProcessingSettings());
      expect(find.text('Encoding settings reset'), findsOneWidget);
    });

    testWidgets('lay out every group with its explanations', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(tester);
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      await tester.pumpWidget(harness.wrap(const EncodingSettingsView()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      for (final String group in <String>[
        'Speed',
        'Audio',
        'Silence detection',
        'Export',
        'Preview',
      ]) {
        expect(find.text(group), findsOneWidget, reason: group);
      }

      // Descriptions are visible text, not tooltips -- in the group that
      // starts open, which is the speeds.
      expect(
        find.textContaining('Pick Remove to cut them out entirely'),
        findsOneWidget,
      );
    });

    testWidgets('changing a slider writes through to the store', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(tester);
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );
      final int before = harness.preferences.settings.silenceSpeedIndex;

      await tester.pumpWidget(harness.wrap(const EncodingSettingsView()));
      await tester.pumpAndSettle();

      // Drag the first slider - silence speed - towards its minimum.
      await tester.drag(find.byType(Slider).first, const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(harness.preferences.settings.silenceSpeedIndex, lessThan(before));
    });

    testWidgets('render in Italian too', (WidgetTester tester) async {
      await useDesktopSurface(tester);
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('it'),
      );

      await tester.pumpWidget(harness.wrap(const EncodingSettingsView()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Velocità'), findsOneWidget);
      expect(find.text('Velocità dei silenzi'), findsOneWidget);
    });

    testWidgets('fit the panel width without overflowing', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(tester, size: const Size(640, 480));
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      // The panel is the tightest place these tiles ever have to work in:
      // a dropdown beside its label would not fit, so it goes under it.
      await tester.pumpWidget(
        harness.wrap(
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: kEncodingPanelWidth,
              child: EncodingSettingsPanel(onClose: () {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.text('Export'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('app settings page', () {
    testWidgets('shows the application group and the working directory', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(tester);
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      await tester.pumpWidget(harness.wrap(const AppSettingsPage()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Application'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.byType(SegmentedButton<ThemeMode>), findsOneWidget);
      // Encoding lives in its own panel now.
      expect(find.text('Speed'), findsNothing);
      expect(find.text('Export'), findsNothing);
    });

    testWidgets('fits a narrow window without overflowing', (
      WidgetTester tester,
    ) async {
      // The minimum window size the app allows.
      await useDesktopSurface(tester, size: const Size(640, 480));
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      await tester.pumpWidget(harness.wrap(const AppSettingsPage()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('about page', () {
    testWidgets('shows the version, credits and licence notice', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(tester);
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      await tester.pumpWidget(
        harness.wrap(AboutPage(version: '0.9.0', onOpenLink: (String _) {})),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Version 0.9.0'), findsOneWidget);
      expect(find.text('Credits'), findsOneWidget);
      expect(find.textContaining('absolutely no warranty'), findsOneWidget);
      expect(find.text('FFmpeg'), findsWidgets);
      // Said in the credits, where someone looks to find out what the app
      // is made of -- and it says the app contains no AI, which is the part
      // a reader of the phrase actually wants to know.
      expect(find.text('Written with AI assistance'), findsOneWidget);
      expect(find.textContaining('contains no AI'), findsOneWidget);
      // Every reference is shown without the part every address has, and
      // none of them is written out beside its link -- which is how one of
      // the three came to be showing its scheme and the others not.
      expect(find.textContaining('https://'), findsNothing);
      expect(
        find.text('github.com/padvincenzo/silence-speedup/issues'),
        findsOneWidget,
      );
    });

    testWidgets('fits a narrow window without overflowing', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(tester, size: const Size(640, 480));
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      await tester.pumpWidget(
        harness.wrap(AboutPage(version: '0.9.0', onOpenLink: (String _) {})),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('silences page', () {
    /// An entry with a known shape: a minute long, two ten-second pauses.
    MediaEntry entryWithSilences() {
      final MediaEntry entry = MediaEntry('/videos/talk.mp4')
        ..duration = const Duration(minutes: 1);
      entry.setSilences(const <SilenceRange>[
        SilenceRange(10, 20),
        SilenceRange(40, 50),
      ], detectedWith: const ProcessingSettings());
      return entry;
    }

    testWidgets('draws the ranges and states what the run will produce', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(tester);
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      await tester.pumpWidget(
        harness.wrap(SilencesPage(entry: entryWithSilences())),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('talk.mp4'), findsOneWidget);
      expect(find.byType(SilenceTimeline), findsOneWidget);

      // Twenty seconds of silence in sixty, sped up eightfold by default:
      // forty spoken seconds and two and a half quiet ones, so a 42-second
      // export and 17 seconds saved. The hours are dropped under an hour.
      expect(find.text('00:20'), findsOneWidget);
      expect(find.text('33.3 %'), findsOneWidget);
      expect(find.text('00:42'), findsOneWidget);
      expect(find.text('00:17'), findsOneWidget);
      // The timeline opens on the whole video, and says so.
      expect(find.text('00:00  →  01:00'), findsOneWidget);
    });

    testWidgets('lists every range without being asked', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(tester);
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      await tester.pumpWidget(
        harness.wrap(SilencesPage(entry: entryWithSilences())),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('2 silences'), findsOneWidget);
      // One row per range, each saying where it is and what happens to it.
      expect(find.text('00:10  →  00:20'), findsOneWidget);
      expect(find.text('00:40  →  00:50'), findsOneWidget);
      expect(find.text('8x'), findsNWidgets(2));
    });

    testWidgets('scrolls the list and leaves the timeline where it is', (
      WidgetTester tester,
    ) async {
      // Short enough that a hundred rows cannot possibly fit.
      await useDesktopSurface(tester, size: const Size(900, 520));
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      final MediaEntry busy = MediaEntry('/videos/chatty.mp4')
        ..duration = const Duration(minutes: 20);
      busy.setSilences(
        List<SilenceRange>.generate(
          100,
          (int i) => SilenceRange(i * 12, i * 12 + 1),
        ),
        detectedWith: const ProcessingSettings(),
      );

      await tester.pumpWidget(harness.wrap(SilencesPage(entry: busy)));
      await tester.pumpAndSettle();

      final Rect before = tester.getRect(find.byType(SilenceTimeline));

      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // The list moved; what the list is about did not.
      expect(tester.getRect(find.byType(SilenceTimeline)), before);
      expect(find.text('00:00  →  20:00'), findsOneWidget);
    });

    testWidgets('lifts the block the rows pass under, not the app bar', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(tester, size: const Size(900, 520));
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      final MediaEntry busy = MediaEntry('/videos/chatty.mp4')
        ..duration = const Duration(minutes: 20);
      busy.setSilences(
        List<SilenceRange>.generate(
          100,
          (int i) => SilenceRange(i * 12, i * 12 + 1),
        ),
        detectedWith: const ProcessingSettings(),
      );

      await tester.pumpWidget(harness.wrap(SilencesPage(entry: busy)));
      await tester.pumpAndSettle();

      /// The surface holding the timeline, the figures and the heading.
      double blockElevation() => tester
          .widget<Material>(
            find
                .ancestor(
                  of: find.byType(SilenceTimeline),
                  matching: find.byType(Material),
                )
                .first,
          )
          .elevation;

      /// The app bar's own surface.
      double barElevation() => tester
          .widget<Material>(
            find
                .descendant(
                  of: find.byType(AppBar),
                  matching: find.byType(Material),
                )
                .first,
          )
          .elevation;

      expect(blockElevation(), 0, reason: 'a shadow over nothing, at rest');
      expect(barElevation(), 0);

      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      // The rows slide under the block, so the block is what lifts. The app
      // bar used to take the shadow instead, having been told about a scroll
      // that was not passing beneath it.
      expect(blockElevation(), greaterThan(0));
      expect(barElevation(), 0);
    });

    testWidgets('the zoom buttons narrow the view and put it back', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(tester);
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      await tester.pumpWidget(
        harness.wrap(SilencesPage(entry: entryWithSilences())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pumpAndSettle();

      // Half the video, around the middle: what was in the centre stays in
      // the centre, which is what makes repeated zooming predictable.
      expect(find.text('00:15  →  00:45'), findsOneWidget);

      await tester.tap(find.byTooltip('The whole video'));
      await tester.pumpAndSettle();
      expect(find.text('00:00  →  01:00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a row of the list frames its own range', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(tester);
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      // Four tenths of a second in a minute of video: half a pixel at
      // whole-video scale, which is precisely what a row has to be able to
      // point at.
      final MediaEntry entry = MediaEntry('/videos/brief.mp4')
        ..duration = const Duration(minutes: 1);
      entry.setSilences(const <SilenceRange>[
        SilenceRange(30, 30.4),
      ], detectedWith: const ProcessingSettings());

      await tester.pumpWidget(harness.wrap(SilencesPage(entry: entry)));
      await tester.pumpAndSettle();

      expect(find.text('00:00  →  01:00'), findsOneWidget);

      await tester.tap(find.text('1 silence'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('00:30  →  00:30'));
      await tester.pumpAndSettle();

      // Two and a half seconds around it: six times its own length.
      expect(tester.takeException(), isNull);
      expect(find.text('00:29  →  00:31'), findsOneWidget);
    });

    testWidgets('says so when the detection settings have moved since', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(tester);
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      await tester.pumpWidget(
        harness.wrap(SilencesPage(entry: entryWithSilences())),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('have changed'), findsNothing);

      // The container has nothing to do with where a boundary falls.
      await harness.preferences.updateSettings(
        harness.preferences.settings.copyWith(outputFormat: 'mkv'),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('have changed'), findsNothing);

      // The margin does.
      await harness.preferences.updateSettings(
        harness.preferences.settings.copyWith(silenceMargin: 0.25),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('have changed'), findsOneWidget);
      expect(find.text('Detect again'), findsOneWidget);
    });

    testWidgets('has something to say about a video with no silence', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(tester);
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      final MediaEntry quiet = MediaEntry('/videos/quiet.mp4')
        ..duration = const Duration(minutes: 1);

      await tester.pumpWidget(harness.wrap(SilencesPage(entry: quiet)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('No silence was found'), findsOneWidget);
      expect(find.byType(SilenceTimeline), findsNothing);
    });
  });

  group('silence timeline controller', () {
    test('opens on the whole video', () {
      final SilenceTimelineController view = SilenceTimelineController(
        sourceSeconds: 600,
      );

      expect(view.start, 0);
      expect(view.span, 600);
      expect(view.isFit, isTrue);
    });

    test('zooms around the middle by default', () {
      final SilenceTimelineController view = SilenceTimelineController(
        sourceSeconds: 600,
      );

      view.zoom(0.5);
      expect(view.span, 300);
      expect(view.start, 150, reason: 'the middle stayed put');
      expect(view.isFit, isFalse);
    });

    test('zooms where the pointer is', () {
      final SilenceTimelineController view = SilenceTimelineController(
        sourceSeconds: 600,
      );

      // Pointer three quarters along: the frame under it must not move.
      view.zoom(0.5, anchor: 0.75);
      expect(view.start + view.span * 0.75, closeTo(450, 0.001));
    });

    test('narrows far enough to see a tenth of a second, and no further', () {
      final SilenceTimelineController view = SilenceTimelineController(
        sourceSeconds: 3600,
      );

      for (int i = 0; i < 40; i++) {
        view.zoom(0.5);
      }

      // All the way in, a tenth of a second is a twentieth of the width:
      // visible and easy to aim at, without the view having turned into a
      // microscope that shows one pause and none of its surroundings.
      expect(view.span, SilenceTimelineController.minimumSpan);
      expect(0.1 / view.span, greaterThan(0.02));
      expect(0.1 / view.span, lessThan(0.2));
    });

    test('a press outside the visible part centres on it', () {
      final SilenceTimelineController view = SilenceTimelineController(
        sourceSeconds: 600,
      );

      view.zoom(0.1);
      view.centreOn(500);
      expect(view.start + view.span / 2, closeTo(500, 0.001));

      // And it stops at the ends rather than showing past them.
      view.centreOn(0);
      expect(view.start, 0);
      view.centreOn(600);
      expect(view.end, closeTo(600, 0.001));
    });

    test('never leaves the video', () {
      final SilenceTimelineController view = SilenceTimelineController(
        sourceSeconds: 600,
      );

      view.zoom(0.1);
      view.panSeconds(-1000);
      expect(view.start, 0);

      view.panSeconds(10000);
      expect(view.end, closeTo(600, 0.001));

      // Zooming back out cannot leave a window hanging off the end either.
      view.fit();
      expect(view.start, 0);
      expect(view.span, 600);
    });

    test('frames a range with some room around it', () {
      final SilenceTimelineController view = SilenceTimelineController(
        sourceSeconds: 600,
      );

      view.reveal(const SilenceRange(300, 300.4));
      expect(view.span, closeTo(2.4, 0.001), reason: 'six times its length');
      expect(view.start + view.span / 2, closeTo(300.2, 0.001));
    });

    test('a range shorter than the smallest span still gets the minimum', () {
      final SilenceTimelineController view = SilenceTimelineController(
        sourceSeconds: 600,
      );

      view.reveal(const SilenceRange(10, 10.02));
      expect(view.span, SilenceTimelineController.minimumSpan);
    });
  });

  group('compact progress strip', () {
    testWidgets('fits the height it asks the window for', (
      WidgetTester tester,
    ) async {
      // Exactly the room the strip declares it needs. The window is told to
      // be this tall plus its title bar; when that addition was missing the
      // strip had about twenty pixels and everything in it was clipped.
      await useDesktopSurface(
        tester,
        size: const Size(kCompactWidth, kCompactContentHeight),
      );
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      await tester.pumpWidget(
        harness.wrap(CompactProgressView(onExpand: () {})),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsOneWidget);
      expect(find.byIcon(Icons.open_in_full), findsOneWidget);
    });

    testWidgets('keeps a tooltip inside the window', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(
        tester,
        size: const Size(kCompactWidth, kCompactContentHeight),
      );
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      await tester.pumpWidget(
        harness.wrap(CompactProgressView(onExpand: () {})),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();

      // A tooltip lives in the app's overlay, so it cannot escape a 64px
      // window: left to itself it opened below the button and the bottom
      // edge cut it in half.
      final Rect tip = tester.getRect(find.text('Stop').last);
      expect(tip.top, greaterThanOrEqualTo(0));
      expect(tip.bottom, lessThanOrEqualTo(kCompactContentHeight));
    });

    testWidgets('survives being dragged to its narrowest', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(
        tester,
        size: const Size(kCompactMinimumWidth, kCompactContentHeight),
      );
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      await tester.pumpWidget(
        harness.wrap(CompactProgressView(onExpand: () {})),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('readable width', () {
    /// Centred, and no wider than a page of text should be.
    void expectHeldToWidth(WidgetTester tester, Finder content) {
      final Rect held = tester.getRect(content);
      final Size window =
          tester.view.physicalSize / tester.view.devicePixelRatio;

      expect(held.width, lessThanOrEqualTo(kReadableWidth));
      expect(held.center.dx, closeTo(window.width / 2, 1));
    }

    testWidgets('the about page holds its cards to it, centred', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(tester, size: const Size(1920, 1000));
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      await tester.pumpWidget(
        harness.wrap(AboutPage(version: '0.9.12', onOpenLink: (String _) {})),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expectHeldToWidth(tester, find.byType(ListView));
    });

    testWidgets('the app settings page does too', (WidgetTester tester) async {
      await useDesktopSurface(tester, size: const Size(1920, 1000));
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      await tester.pumpWidget(harness.wrap(const AppSettingsPage()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expectHeldToWidth(tester, find.byType(ListView));
    });

    testWidgets('a narrow window is left alone', (WidgetTester tester) async {
      await useDesktopSurface(tester, size: const Size(640, 480));
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      await tester.pumpWidget(harness.wrap(const AppSettingsPage()));
      await tester.pumpAndSettle();

      // Nothing to give away at this size: the content takes the window.
      expect(tester.getRect(find.byType(ListView)).width, 640);
    });
  });

  group('the licence itself', () {
    testWidgets('is read in the app, not on a website', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(tester);
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      await tester.pumpWidget(harness.wrap(const LicenseTextPage()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // The real file, shipped as an asset: its first lines and the clause
      // the app's own notice paraphrases.
      expect(find.textContaining('GNU GENERAL PUBLIC LICENSE'), findsOneWidget);
      expect(find.textContaining('Version 3, 29 June 2007'), findsOneWidget);
      expect(find.textContaining('NO WARRANTY'), findsOneWidget);
    });
  });

  group('licences page', () {
    setUp(() {
      // Deterministic contents: the registry would otherwise hold whatever
      // the binding managed to read out of the asset bundle.
      LicenseRegistry.reset();
      LicenseRegistry.addLicense(() async* {
        yield const LicenseEntryWithLineBreaks(<String>[
          'silence_speedup',
        ], 'GNU GPL v3 or later');
        yield const LicenseEntryWithLineBreaks(<String>[
          'ffmpeg_kit_flutter_new',
        ], 'LGPL, or GPL with libx264');
        yield const LicenseEntryWithLineBreaks(<String>[
          'ffmpeg_kit_flutter_new',
        ], 'A second notice for the same package');
      });
    });

    tearDown(LicenseRegistry.reset);

    testWidgets('keeps the name and version in view while the list scrolls', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(tester, size: const Size(640, 480));
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      await tester.pumpWidget(
        harness.wrap(const LicensesPage(version: '0.9.3')),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // A large app bar carries the title twice, collapsed and expanded, and
      // cross-fades between them.
      expect(find.text('Silence SpeedUp 0.9.3'), findsWidgets);
      expect(find.text('2 packages'), findsOneWidget);
      // One package carries two notices, and the row says so.
      expect(find.text('2 licences'), findsOneWidget);

      // The heading is pinned, so scrolling the list past it does not take
      // it away -- which is the whole reason this page exists.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(find.text('Silence SpeedUp 0.9.3'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows the document beside the list on a wide window', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(tester, size: const Size(1400, 900));
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      await tester.pumpWidget(
        harness.wrap(const LicensesPage(version: '0.9.4')),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // The first package is shown without being asked for, so the pane is
      // never a blank half of the window. Both its notices are there.
      expect(find.textContaining('libx264'), findsOneWidget);
      expect(
        find.textContaining('A second notice for the same package'),
        findsOneWidget,
      );

      // Picking another one swaps the document and leaves the list in place:
      // no route is pushed, so the list is still on screen.
      final Finder inList = find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.text('silence_speedup'),
      );
      await tester.tap(inList);
      await tester.pumpAndSettle();

      expect(find.textContaining('GNU GPL v3 or later'), findsOneWidget);
      expect(find.textContaining('libx264'), findsNothing);
      expect(find.text('ffmpeg_kit_flutter_new'), findsOneWidget);
    });

    testWidgets('holds the document to a readable width', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(tester, size: const Size(1920, 1000));
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      await tester.pumpWidget(
        harness.wrap(const LicensesPage(version: '0.9.4')),
      );
      await tester.pumpAndSettle();

      // The pane is over 1500 pixels wide here; the licence is not allowed
      // to be, because a line that long cannot be read.
      final Finder document = find.byWidgetPredicate(
        (Widget widget) =>
            widget is ConstrainedBox &&
            widget.constraints.maxWidth == kLicensesDocumentWidth,
      );
      expect(
        tester.getSize(document).width,
        lessThanOrEqualTo(kLicensesDocumentWidth),
      );
    });

    testWidgets('opens the licence as its own page when narrow', (
      WidgetTester tester,
    ) async {
      await useDesktopSurface(tester, size: const Size(640, 480));
      final TestHarness harness = await TestHarness.create(
        preferred: const Locale('en'),
      );

      await tester.pumpWidget(
        harness.wrap(const LicensesPage(version: '0.9.4')),
      );
      await tester.pumpAndSettle();

      // Nothing is preselected: there is no room to show it.
      expect(find.textContaining('libx264'), findsNothing);

      await tester.tap(find.text('ffmpeg_kit_flutter_new'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('libx264'), findsOneWidget);
      expect(
        find.textContaining('A second notice for the same package'),
        findsOneWidget,
      );
      // The list gave way to the document rather than sitting beside it.
      expect(find.text('silence_speedup'), findsNothing);
    });
  });

  group('theme', () {
    // ListTile installs its subtitle style as a DefaultTextStyle, which
    // replaces the ambient one instead of merging with it. A subtitle style
    // without a colour therefore paints in the engine's default black, which
    // is invisible on a dark surface — every setting's description and every
    // line of the about page went that way once.
    testWidgets('gives tile subtitles a colour in both brightnesses', (
      WidgetTester tester,
    ) async {
      for (final Brightness brightness in Brightness.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(brightness),
            home: const Scaffold(
              body: ListTile(title: Text('title'), subtitle: Text('detail')),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final TextStyle style = DefaultTextStyle.of(
          tester.element(find.text('detail')),
        ).style;
        expect(
          style.color,
          isNotNull,
          reason: 'subtitles have no colour in $brightness',
        );
        expect(
          style.color,
          isNot(buildAppTheme(brightness).colorScheme.surface),
        );
      }
    });

    // Material 3 would tint the app bar's background once content scrolls
    // under it, and that tint is baked into the colour at build time: the
    // bar changed shade in one frame while only its elevation animated.
    // A shadow does animate, so the tint is off and the elevation is not.
    test('an app bar lifts on a shadow rather than changing colour', () {
      for (final Brightness brightness in Brightness.values) {
        final ThemeData theme = buildAppTheme(brightness);
        expect(theme.appBarTheme.surfaceTintColor, Colors.transparent);
        expect(theme.appBarTheme.shadowColor, theme.colorScheme.shadow);
        expect(theme.appBarTheme.elevation, 0);
        expect(theme.appBarTheme.scrolledUnderElevation, greaterThan(0));
      }
    });
  });
}
