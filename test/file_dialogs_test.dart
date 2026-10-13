// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:silence_speedup/l10n/gen/app_localizations.dart';
import 'package:silence_speedup/ui/file_dialogs.dart';
import 'package:silence_speedup/ui/theme.dart';

/// A platform with no dialog to offer, as a Linux desktop without
/// xdg-desktop-portal is: every call throws, which is what the interface's
/// own unimplemented methods do.
class _NoDialog extends FilePickerPlatform with MockPlatformInterfaceMixin {}

void main() {
  late FilePickerPlatform original;

  setUp(() {
    original = FilePickerPlatform.instance;
    FilePickerPlatform.instance = _NoDialog();
  });

  tearDown(() => FilePickerPlatform.instance = original);

  Future<BuildContext> pumpHost(WidgetTester tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        // The app's own theme, which is what makes its messages float.
        theme: buildAppTheme(Brightness.light),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              captured = context;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    return captured;
  }

  testWidgets('a file dialog that cannot open says so instead of nothing', (
    WidgetTester tester,
  ) async {
    final BuildContext context = await pumpHost(tester);

    final List<String>? paths = await pickFiles(
      context,
      title: 'Videos',
      extensions: <String>['mp4'],
    );
    await tester.pump();

    expect(paths, isNull);
    expect(
      find.text(AppLocalizations.of(context).fileDialogUnavailable),
      findsOneWidget,
    );
  });

  testWidgets('so does a folder dialog', (WidgetTester tester) async {
    final BuildContext context = await pumpHost(tester);

    final String? directory = await pickDirectory(context, title: 'Folder');
    await tester.pump();

    expect(directory, isNull);
    expect(
      find.text(AppLocalizations.of(context).fileDialogUnavailable),
      findsOneWidget,
    );
  });
}
