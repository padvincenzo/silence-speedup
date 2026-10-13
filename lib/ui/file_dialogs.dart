// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';

import '../l10n/gen/app_localizations.dart';
import 'messages.dart';

/// The system's file dialogs, and what to say when there is none.
///
/// On Linux, file_picker asks the XDG desktop portal for its dialog over the
/// session bus. A desktop without the portal, such as a bare window manager,
/// answers with an exception. An exception thrown from a button press ends
/// up nowhere the user can see, so the press would look ignored. Each of
/// these answers null instead and says why.
Future<List<String>?> pickFiles(
  BuildContext context, {
  required String title,
  required List<String> extensions,
}) async {
  try {
    final List<PlatformFile> picked = await FilePicker.pickFiles(
      dialogTitle: title,
      type: FileType.custom,
      allowedExtensions: extensions,
    );
    return picked
        .map((PlatformFile file) => file.path)
        .whereType<String>()
        .toList();
  } catch (error) {
    if (context.mounted) _sayUnavailable(context, error);
    return null;
  }
}

/// A folder chosen in the system's dialog, or null; see [pickFiles].
Future<String?> pickDirectory(
  BuildContext context, {
  required String title,
  String? initialDirectory,
}) async {
  try {
    return await FilePicker.getDirectoryPath(
      dialogTitle: title,
      initialDirectory: initialDirectory,
    );
  } catch (error) {
    if (context.mounted) _sayUnavailable(context, error);
    return null;
  }
}

void _sayUnavailable(BuildContext context, Object error) {
  debugPrint('File dialog failed: $error');
  showAppMessage(context, AppLocalizations.of(context).fileDialogUnavailable);
}
