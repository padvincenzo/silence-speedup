// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../services/speedup_engine.dart';
import '../../state/process_store.dart';

/// Height the strip needs, not counting the window's own title bar.
///
/// Two lines of content — what is being worked on, and how far it has got —
/// plus the buttons at their compact size. The window used to be told to be
/// 56 pixels tall in total, and since a window is measured with its title
/// bar, the strip itself was left with about twenty: everything in it was
/// squeezed or clipped.
const double kCompactContentHeight = 64;

/// Width the strip opens at.
const double kCompactWidth = 720;

/// Narrowest it may be dragged to. The file name gives way first.
const double kCompactMinimumWidth = 420;

/// The slim always-on-top strip the Electron build opened as a second window.
///
/// Flutter desktop runs one window, so instead of a new window the main one is
/// shrunk to this bar — same purpose, and it keeps the run in one place.
class CompactProgressView extends StatelessWidget {
  const CompactProgressView({super.key, required this.onExpand});

  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ProcessStore process = context.watch<ProcessStore>();
    final RunProgress progress = process.progress;
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Scaffold(
      // A tooltip is drawn in the app's own overlay, so it cannot leave the
      // window — and this window is 64 pixels tall. Left to itself it opens
      // below the button and is cut off by the bottom edge. Compact, close
      // to the button and above it, one fits.
      body: TooltipTheme(
        data: TooltipThemeData(
          preferBelow: false,
          verticalOffset: 6,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          textStyle: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onInverseSurface,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Row(
            children: <Widget>[
              Text(
                '${progress.completed}/${progress.total}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurface,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      progress.entryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // The whole batch, not the file: the file's own share is
                    // the percentage to the right, and what someone watching
                    // an always-on-top strip wants is how far the run has got.
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress.queueFraction.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: scheme.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Room held for the widest reading, so the buttons beside it do
              // not shuffle every time FFmpeg reports.
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 52),
                child: Text(
                  progress.fraction == null
                      ? '-.- %'
                      : '${(progress.fraction! * 100).toStringAsFixed(1)} %',
                  textAlign: TextAlign.end,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onSurface,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => context.read<ProcessStore>().stop(),
                icon: const Icon(Icons.stop),
                iconSize: 20,
                visualDensity: VisualDensity.compact,
                tooltip: strings.processStop,
              ),
              IconButton(
                onPressed: onExpand,
                icon: const Icon(Icons.open_in_full),
                iconSize: 20,
                visualDensity: VisualDensity.compact,
                tooltip: strings.menuWindowMode,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
