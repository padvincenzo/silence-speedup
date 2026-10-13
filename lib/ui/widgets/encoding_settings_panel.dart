// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../layout.dart';
import 'encoding_settings_view.dart';

/// Width the encoding settings get, docked or as a side sheet.
///
/// Wide enough for a label and its explanation to read as a sentence, narrow
/// enough to leave the queue the larger half of the smallest window that can
/// show both.
const double kEncodingPanelWidth = 380;

/// Below this the window is too narrow to hold the queue and the panel side
/// by side, so the panel becomes a sheet over the queue instead.
const double kEncodingPanelBreakpoint = 1020;

/// The encoding settings with a title bar and a way out.
///
/// The same widget is the docked panel and the contents of the side sheet;
/// only the way it is dismissed differs, which is what [docked] names.
class EncodingSettingsPanel extends StatelessWidget {
  const EncodingSettingsPanel({
    super.key,
    required this.onClose,
    this.docked = true,
  });

  final VoidCallback onClose;
  final bool docked;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          // As tall as the queue's toolbar beside it, so the rules under
          // the two line up.
          height: kHeaderStripHeight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
            child: Row(
              children: <Widget>[
                Icon(Icons.tune, size: 20, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    strings.settingsEncodingTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: Icon(docked ? Icons.close_fullscreen : Icons.close),
                  tooltip: docked
                      ? strings.settingsEncodingHide
                      : strings.uiClose,
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        const Expanded(child: EncodingSettingsView(bottomInset: 24)),
      ],
    );
  }
}

/// The panel as it sits beside the queue on a wide window.
class DockedEncodingSettings extends StatelessWidget {
  const DockedEncodingSettings({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    // A Material rather than a coloured box: the tiles inside paint their
    // ink on the nearest Material ancestor, and a DecoratedBox in between
    // would swallow every splash.
    return SizedBox(
      width: kEncodingPanelWidth,
      child: Material(
        color: scheme.surfaceContainerLow,
        child: DecoratedBox(
          // Painted over the panel, not behind it. A pinned group heading
          // is opaque and spans the full width, so a background border
          // disappeared behind it and the panel ran into the queue.
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: scheme.outlineVariant)),
          ),
          child: EncodingSettingsPanel(onClose: onClose),
        ),
      ),
    );
  }
}
