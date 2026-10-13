// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../l10n/labels.dart';
import '../../models/media_entry.dart';
import '../../state/process_store.dart';
import '../pages/queue_page.dart' show kQueueBottomInset;
import '../../state/queue_store.dart';
import '../format.dart';
import '../pages/silences_page.dart';
import '../theme.dart';

/// The queue, or the welcome note when there is nothing in it yet.
class EntryList extends StatelessWidget {
  const EntryList({
    super.key,
    required this.onRevealOutput,
    required this.onPreview,
  });

  /// Opens the finished file's folder.
  final void Function(MediaEntry entry) onRevealOutput;

  /// Builds a short sample and plays it.
  final void Function(MediaEntry entry) onPreview;

  @override
  Widget build(BuildContext context) {
    final QueueStore queue = context.watch<QueueStore>();

    if (queue.isEmpty) return const _EmptyQueueMessage();

    return ListView.separated(
      padding: const EdgeInsets.only(
        left: 12,
        right: 12,
        top: 4,
        bottom: kQueueBottomInset,
      ),
      itemCount: queue.entries.length,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: 4),
      itemBuilder: (BuildContext context, int index) {
        final MediaEntry entry = queue.entries[index];
        return ChangeNotifierProvider<MediaEntry>.value(
          value: entry,
          child: _EntryTile(
            onRevealOutput: onRevealOutput,
            onPreview: onPreview,
          ),
        );
      },
    );
  }
}

class _EmptyQueueMessage extends StatelessWidget {
  const _EmptyQueueMessage();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          color: scheme.secondaryContainer,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.info_outline,
                  size: 32,
                  color: scheme.onSecondaryContainer,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).appIntro,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSecondaryContainer),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One row: name, status, and the actions that make sense right now.
class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.onRevealOutput, required this.onPreview});

  final void Function(MediaEntry entry) onRevealOutput;
  final void Function(MediaEntry entry) onPreview;

  @override
  Widget build(BuildContext context) {
    final MediaEntry entry = context.watch<MediaEntry>();
    final QueueStore queue = context.watch<QueueStore>();
    final ProcessStore process = context.watch<ProcessStore>();
    final StatusPalette palette = StatusPalette.of(context);
    final Color accent = _accentFor(entry.status, palette);

    return Card(
      elevation: 0,
      color: switch (entry.status) {
        EntryStatus.completed || EntryStatus.failed => palette.rowTint(accent),
        _ => Theme.of(context).colorScheme.surfaceContainerLow,
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: <Widget>[
            _StatusIcon(status: entry.status, color: accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Tooltip(
                    message: entry.path,
                    child: Text(
                      entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _statusLine(AppLocalizations.of(context), entry),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: accent),
                  ),
                ],
              ),
            ),
            if (entry.status == EntryStatus.completed &&
                entry.outputPath != null)
              IconButton(
                onPressed: () => onRevealOutput(entry),
                icon: const Icon(Icons.folder_outlined),
                tooltip: AppLocalizations.of(context).fileReveal,
              ),
            // Offered as soon as there is something to draw, which is after
            // an analysis or a finished run: the ranges survive both.
            if (entry.hasSilences)
              IconButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) =>
                        SilencesPage(entry: entry),
                  ),
                ),
                icon: const Icon(Icons.timeline),
                tooltip: AppLocalizations.of(context).fileSilences,
              ),
            if (!process.isRunning) ...<Widget>[
              IconButton(
                onPressed: entry.isProcessable ? () => onPreview(entry) : null,
                icon: const Icon(Icons.play_circle_outline),
                tooltip: AppLocalizations.of(context).filePreview,
              ),
              IconButton(
                onPressed: entry.isProcessable
                    ? () => context.read<ProcessStore>().analyze(entry)
                    : null,
                icon: const Icon(Icons.graphic_eq),
                tooltip: AppLocalizations.of(context).fileAnalyze,
              ),
            ],
            IconButton(
              onPressed: queue.canImport
                  ? () => context.read<QueueStore>().remove(entry)
                  : null,
              icon: const Icon(Icons.delete_outline),
              tooltip: AppLocalizations.of(context).fileRemove,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the second line: the status, plus whatever detail fits with it.
  String _statusLine(AppLocalizations strings, MediaEntry entry) {
    if (entry.status == EntryStatus.ready && entry.duration != null) {
      return strings.statusLoaded(formatDuration(entry.duration!));
    }

    final List<String> parts = <String>[statusText(entry.status, strings)];
    if (entry.detail != null && entry.detail!.isNotEmpty) {
      parts.add(entry.detail!);
    } else if (entry.duration != null) {
      parts.add(formatDuration(entry.duration!));
    }
    return parts.join(' · ');
  }

  static Color _accentFor(EntryStatus status, StatusPalette palette) =>
      switch (status) {
        EntryStatus.completed => palette.success,
        EntryStatus.failed => palette.failure,
        EntryStatus.interrupted => palette.warning,
        EntryStatus.analyzing ||
        EntryStatus.exporting ||
        EntryStatus.concatenating => palette.busy,
        EntryStatus.probing ||
        EntryStatus.ready ||
        EntryStatus.queued => palette.idle,
      };
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status, required this.color});

  final EntryStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final bool busy = switch (status) {
      EntryStatus.probing ||
      EntryStatus.analyzing ||
      EntryStatus.exporting ||
      EntryStatus.concatenating => true,
      _ => false,
    };

    if (busy) {
      return SizedBox.square(
        dimension: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      );
    }

    return Icon(
      switch (status) {
        EntryStatus.completed => Icons.check_circle_outline,
        EntryStatus.failed => Icons.error_outline,
        EntryStatus.interrupted => Icons.pause_circle_outline,
        _ => Icons.movie_outlined,
      },
      size: 20,
      color: color,
    );
  }
}
