// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../widgets/readable_width.dart';

/// The GPLv3, in full, from the copy the app ships.
///
/// The button used to open gnu.org, which is an odd thing for the one licence
/// that actually governs this program when every dependency's licence is
/// readable in the app already. It also asked for a network and a browser to
/// read a document the app is required to carry.
///
/// The text is the repository's own `LICENSE`, declared as an asset, so there
/// is one copy: the file the installer shows, the file GitHub reads, and the
/// file shown here cannot drift apart.
class LicenseTextPage extends StatelessWidget {
  const LicenseTextPage({super.key});

  /// The licence as shipped. Not translated: a translated GPL is not the GPL,
  /// which the licence itself is firm about.
  static const String assetPath = 'LICENSE';

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('GNU General Public License v3'),
            Text(
              strings.aboutCopyright,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<String>(
        future: DefaultAssetBundle.of(context).loadString(assetPath),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasError) {
            return _Message(text: strings.licensesEmpty);
          }
          final String? text = snapshot.data;
          if (text == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return ReadableWidth(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: SelectableText(
                text,
                // The file wraps its own lines at about seventy columns, so
                // it is shown as written rather than re-wrapped: the
                // paragraph numbering and the indents are part of the
                // document.
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  height: 1.45,
                  fontFamily: 'monospace',
                  fontFamilyFallback: const <String>[
                    'Consolas',
                    'Menlo',
                    'monospace',
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
