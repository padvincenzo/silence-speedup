// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../models/media_entry.dart';
import '../../state/log_store.dart';
import '../../state/queue_store.dart';
import '../layout.dart';
import '../shortcuts.dart';
import '../widgets/entry_list.dart';
import '../widgets/log_console.dart';
import '../widgets/progress_footer.dart';
import '../widgets/scrolled_under.dart';

/// Room left below the queue so the floating action button never sits on top
/// of the last row.
const double kQueueBottomInset = 88;

/// The main screen: import, destination and the queue.
///
/// Starting and stopping live on the shell's floating action button, which is
/// where Material puts the one action a screen is for. Progress and the log
/// live in [QueueStatusBar], which the shell puts in the Scaffold's bottom
/// slot so the button has somewhere to float that covers nothing. The rates
/// and the way into the encoding settings are one control in the app bar, so
/// this page carries neither.
class QueuePage extends StatefulWidget {
  const QueuePage({
    super.key,
    required this.onOpenFiles,
    required this.onOpenFolder,
    required this.onRevealOutput,
    required this.onPreview,
  });

  final VoidCallback onOpenFiles;
  final VoidCallback onOpenFolder;
  final void Function(MediaEntry entry) onRevealOutput;
  final void Function(MediaEntry entry) onPreview;

  @override
  State<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> {
  /// Whether the queue has been scrolled off its top.
  ///
  /// What the rows pass under is the toolbar, not the app bar above it, so
  /// the toolbar is what lifts. The app bar is told to ignore the scroll.
  bool _scrolled = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ScrolledUnder(
          lifted: _scrolled,
          child: _Toolbar(
            onOpenFiles: widget.onOpenFiles,
            onOpenFolder: widget.onOpenFolder,
          ),
        ),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification notification) {
              final bool scrolled = ScrolledUnder.isScrolled(notification);
              if (scrolled != _scrolled) {
                setState(() => _scrolled = scrolled);
              }
              return false;
            },
            child: EntryList(
              onRevealOutput: widget.onRevealOutput,
              onPreview: widget.onPreview,
            ),
          ),
        ),
      ],
    );
  }
}

/// The status strip pinned under the queue: progress, and the log when it is
/// showing.
class QueueStatusBar extends StatelessWidget {
  const QueueStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final bool logVisible = context.watch<LogStore>().visible;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Divider(),
        const ProgressFooter(),
        if (logVisible) const LogConsole(),
      ],
    );
  }
}

/// What goes into the queue, and what empties it.
///
/// Filling it and emptying it pull in opposite directions, so they sit at
/// opposite ends of the row, with the count beside the one that would throw
/// it away. Nothing else belongs here: the export destination used to, in a
/// row of its own with a path field across the whole window, and it is a
/// setting about exporting, so it moved to the encoding settings.
class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.onOpenFiles, required this.onOpenFolder});

  final VoidCallback onOpenFiles;
  final VoidCallback onOpenFolder;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final QueueStore queue = context.watch<QueueStore>();

    return SizedBox(
      // As tall as the encoding panel's title bar beside it, so the rules
      // under the two line up.
      height: kHeaderStripHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: <Widget>[
            _AddMenu(
              enabled: queue.canImport,
              onOpenFiles: onOpenFiles,
              onOpenFolder: onOpenFolder,
            ),
            const Spacer(),
            if (queue.entries.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  strings.queueCount(queue.entries.length),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            IconButton(
              onPressed: queue.canImport && !queue.isEmpty
                  ? context.read<QueueStore>().clear
                  : null,
              icon: const Icon(Icons.playlist_remove),
              tooltip: strings.menuClearQueue,
            ),
          ],
        ),
      ),
    );
  }
}

/// One button for both kinds of import.
///
/// They were two buttons side by side, which is a lot of row for one idea:
/// what goes in is either some files or a folder of them, and the choice is
/// made once you have already decided to add something. The menu states the
/// keyboard shortcuts, which do both directly and are the fast path along
/// with dropping files on the window.
class _AddMenu extends StatelessWidget {
  const _AddMenu({
    required this.enabled,
    required this.onOpenFiles,
    required this.onOpenFolder,
  });

  final bool enabled;
  final VoidCallback onOpenFiles;
  final VoidCallback onOpenFolder;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);

    return MenuAnchor(
      menuChildren: <Widget>[
        MenuItemButton(
          leadingIcon: const Icon(Icons.movie_outlined),
          shortcut: kOpenFilesShortcut,
          onPressed: onOpenFiles,
          child: Text(strings.menuOpenFile),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.folder_open_outlined),
          shortcut: kOpenFolderShortcut,
          onPressed: onOpenFolder,
          child: Text(strings.menuOpenFolder),
        ),
      ],
      builder:
          (BuildContext context, MenuController controller, Widget? child) {
            return FilledButton.icon(
              onPressed: !enabled
                  ? null
                  : () => controller.isOpen
                        ? controller.close()
                        : controller.open(),
              icon: const Icon(Icons.add),
              label: Text(strings.menuAdd),
            );
          },
    );
  }
}
