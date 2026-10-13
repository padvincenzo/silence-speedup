// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'dart:math' as math;

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';

import '../l10n/gen/app_localizations.dart';
import '../models/media_entry.dart';
import '../models/options.dart';
import '../models/processing_settings.dart';
import '../services/update_checker.dart';
import '../state/preferences_store.dart';
import '../state/process_store.dart';
import '../state/queue_store.dart';
import 'pages/about_page.dart';
import 'pages/app_settings_page.dart';
import 'pages/queue_page.dart';
import 'messages.dart';
import 'platform.dart';
import 'shortcuts.dart';
import 'widgets/app_drawer.dart';
import 'widgets/compact_progress_view.dart';
import 'widgets/encoding_settings_panel.dart';

/// Window size restored when leaving compact mode, if nothing else is known.
const Size _defaultWindowSize = Size(780, 820);
const Size _minimumWindowSize = Size(640, 480);

/// The app's frame: an app bar, a navigation drawer, and one of three pages.
///
/// This replaces the Electron build's menu bar. Nothing was lost by dropping
/// it — the queue actions moved onto the queue, the settings onto a page of
/// their own, and what is genuinely application-level is in the drawer.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final GlobalKey<ScaffoldState> _scaffold = GlobalKey<ScaffoldState>();

  AppDestination _destination = AppDestination.queue;
  String _version = '';
  AvailableUpdate? _update;
  bool _dragging = false;

  /// Compact state already pushed to the window, so the reconciliation in
  /// `build` does not fire the same resize on every rebuild.
  bool _compactApplied = false;
  Size? _restoreSize;

  @override
  void initState() {
    super.initState();
    _loadVersionAndCheckUpdates();
  }

  Future<void> _loadVersionAndCheckUpdates() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _version = info.version);

    final AvailableUpdate? update = await const UpdateChecker().check(
      info.version,
    );
    if (!mounted || update == null) return;
    setState(() => _update = update);
  }

  void _go(AppDestination destination) {
    if (_destination == destination) return;
    setState(() => _destination = destination);
  }

  bool get _wideEnoughToDock =>
      MediaQuery.sizeOf(context).width >= kEncodingPanelBreakpoint;

  /// Whether the panel is currently part of the queue's layout.
  ///
  /// Docking is a remembered preference; whether it can be honoured is a
  /// question about this window's width.
  bool get _showDockedEncoding =>
      _destination == AppDestination.queue &&
      _wideEnoughToDock &&
      context.read<PreferencesStore>().encodingPanelDocked;

  void _setDocked(bool docked) =>
      context.read<PreferencesStore>().setEncodingPanelDocked(docked);

  /// Shows the encoding settings, or puts them away again.
  ///
  /// On a wide window this docks or undocks the panel; on a narrow one it
  /// opens the side sheet, which the scrim, Escape or its close button all
  /// dismiss. Either way the queue is one gesture away, which is the point:
  /// these settings are changed between runs, not visited.
  void _toggleEncoding() {
    // Reaching them from anywhere else means going back to the queue first.
    if (_destination != AppDestination.queue) {
      _go(AppDestination.queue);
      if (_wideEnoughToDock) {
        _setDocked(true);
        return;
      }
      // The end drawer belongs to the queue's Scaffold slot, so it can only
      // be opened once that page is the one being built.
      WidgetsBinding.instance.addPostFrameCallback(
        (Duration _) => _scaffold.currentState?.openEndDrawer(),
      );
      return;
    }

    if (_wideEnoughToDock) {
      _setDocked(!context.read<PreferencesStore>().encodingPanelDocked);
      return;
    }

    final ScaffoldState? scaffold = _scaffold.currentState;
    if (scaffold == null) return;
    if (scaffold.isEndDrawerOpen) {
      Navigator.of(context).maybePop();
    } else {
      scaffold.openEndDrawer();
    }
  }

  /// Closes the side sheet if it is what is open.
  void _closeEncodingSheet() {
    if (_scaffold.currentState?.isEndDrawerOpen ?? false) {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _openFiles() async {
    final List<PlatformFile> picked = await FilePicker.pickFiles(
      dialogTitle: AppLocalizations.of(context).fileOpenFile,
      type: FileType.custom,
      allowedExtensions: kImportableExtensions.toList(),
    );
    if (picked.isEmpty || !mounted) return;

    final List<String> paths = picked
        .map((PlatformFile file) => file.path)
        .whereType<String>()
        .toList();
    await context.read<QueueStore>().addFiles(paths);
  }

  Future<void> _openFolder() async {
    final String? directory = await FilePicker.getDirectoryPath(
      dialogTitle: AppLocalizations.of(context).fileOpenDir,
    );
    if (directory == null || !mounted) return;
    await context.read<QueueStore>().addDirectory(directory);
  }

  Future<void> _openLink(String url) async {
    if (!await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    )) {
      if (!mounted) return;
      _showMessage(AppLocalizations.of(context).logLinkError(url));
    }
  }

  /// Builds a short sample of [entry] and plays it.
  ///
  /// The point of a preview is to hear the result, so the file is opened as
  /// soon as it exists rather than merely reported in the log.
  Future<void> _preview(MediaEntry entry) async {
    final ProcessStore process = context.read<ProcessStore>();
    await process.preview(entry);

    final MediaEntry? finished = process.takeFinishedPreview();
    final String? output = finished?.outputPath;
    if (output == null || !mounted) return;
    await launchUrl(Uri.file(output));
  }

  /// Opens the folder the finished file was written to.
  Future<void> _revealOutput(MediaEntry entry) async {
    final String? output = entry.outputPath;
    if (output == null) return;
    if (!await launchUrl(Uri.file(p.dirname(output)))) {
      if (!mounted) return;
      _showMessage(
        AppLocalizations.of(context).logLinkError(p.dirname(output)),
      );
    }
  }

  Future<void> _quit() async {
    final ProcessStore process = context.read<ProcessStore>();
    if (process.isRunning) {
      await process.stop();
    }
    if (isDesktop) {
      // close(), not destroy(). The plugin's destroy is PostQuitMessage,
      // which ends the message loop and leaves the window standing: it
      // then sits on screen, frozen, for as long as the engine takes to
      // shut down. close() posts the same WM_CLOSE the title bar does, so
      // the window goes at once and the teardown happens behind it.
      await windowManager.close();
    } else {
      await SystemNavigator.pop();
    }
  }

  Future<void> _handleDrop(DropDoneDetails details) async {
    final QueueStore queue = context.read<QueueStore>();
    if (!queue.canImport) return;

    // desktop_drop tells files and folders apart, so a dropped folder can be
    // walked exactly as Open folder does.
    final List<String> files = <String>[];
    final List<String> directories = <String>[];
    for (final DropItem item in details.files) {
      if (item.path.isEmpty) continue;
      if (item is DropItemDirectory) {
        directories.add(item.path);
      } else {
        files.add(item.path);
      }
    }

    // A drop is an import, so show it happening.
    _go(AppDestination.queue);

    if (files.isNotEmpty) {
      await queue.addFiles(files);
    }
    for (final String directory in directories) {
      await queue.addDirectory(directory);
    }
  }

  void _showMessage(String message) => showAppMessage(context, message);

  /// Shrinks the window to the progress strip, or puts it back.
  ///
  /// `setSize` measures the whole window, title bar included, while the strip
  /// only knows the area it is drawn in. The difference is measured here
  /// rather than guessed: it is not the same at every display scaling, and
  /// guessing it low is what left the strip about twenty pixels to draw in.
  Future<void> _applyCompact(bool compact) async {
    if (!isDesktop) return;
    if (compact) {
      final Size frame = await windowManager.getSize();
      _restoreSize = frame;
      if (!mounted) return;

      final double chrome = (frame.height - MediaQuery.sizeOf(context).height)
          .clamp(0.0, 200.0);
      final Size target = Size(kCompactWidth, kCompactContentHeight + chrome);

      await windowManager.setMinimumSize(
        Size(kCompactMinimumWidth, target.height),
      );
      await windowManager.setSize(target);
      await windowManager.setResizable(false);
      await windowManager.setAlwaysOnTop(true);
    } else {
      await windowManager.setAlwaysOnTop(false);
      await windowManager.setResizable(true);
      await windowManager.setMinimumSize(_minimumWindowSize);
      await windowManager.setSize(_restoreSize ?? _defaultWindowSize);
      await windowManager.center();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ProcessStore process = context.watch<ProcessStore>();
    // Watched, not read: docking the encoding panel is a stored preference,
    // and the shell is what has to rebuild when it changes.
    context.watch<PreferencesStore>();

    // Keep the OS window in step with the mode the store reports.
    if (process.compactMode != _compactApplied) {
      _compactApplied = process.compactMode;
      final bool target = _compactApplied;
      WidgetsBinding.instance.addPostFrameCallback(
        (Duration _) => _applyCompact(target),
      );
    }

    if (process.compactMode) {
      return CompactProgressView(
        onExpand: () => context.read<ProcessStore>().setCompactMode(false),
      );
    }

    return CallbackShortcuts(
      // Declared in shortcuts.dart, because the Add menu advertises two of
      // them and has to be saying the truth.
      bindings: <ShortcutActivator, VoidCallback>{
        kOpenFilesShortcut: _openFiles,
        kOpenFolderShortcut: _openFolder,
        kStopShortcut: () {
          if (process.isRunning) context.read<ProcessStore>().stop();
        },
        kQuitShortcut: _quit,
        kEncodingSettingsShortcut: _toggleEncoding,
        const SingleActivator(LogicalKeyboardKey.escape): _closeEncodingSheet,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          key: _scaffold,
          appBar: AppBar(
            // On the queue the rows pass under the toolbar, not under this,
            // so the toolbar carries the shadow and this stays flat. The
            // settings and about pages scroll directly beneath it, and
            // there the default is right.
            notificationPredicate: _destination == AppDestination.queue
                ? (ScrollNotification _) => false
                : defaultScrollNotificationPredicate,
            // Away from the queue, the way out is back to it. The drawer's
            // own button would offer to open the drawer from inside a place
            // the drawer sent you to, which is a way round rather than a
            // way back; it is on the queue, where there is nothing to go
            // back to.
            leading: _destination == AppDestination.queue
                ? null
                : BackButton(onPressed: () => _go(AppDestination.queue)),
            title: Text(_titleFor(_destination, strings)),
            actions: _actionsFor(_destination, strings),
          ),
          drawer: AppDrawer(
            destination: _destination,
            onSelect: _go,
            onOpenLink: _openLink,
            onQuit: _quit,
            version: _version,
            update: _update,
          ),
          // Only on a window too narrow to dock them: on a wide one the same
          // panel is part of the body, and two ways in at once would be one
          // too many.
          endDrawer: _destination == AppDestination.queue && !_wideEnoughToDock
              ? Drawer(
                  width: kEncodingPanelWidth,
                  child: EncodingSettingsPanel(
                    docked: false,
                    onClose: _closeEncodingSheet,
                  ),
                )
              : null,
          // The status strip is a bottom bar rather than the last row of the
          // page, which is what keeps the button clear of the readouts.
          bottomNavigationBar: _destination == AppDestination.queue
              ? const QueueStatusBar()
              : null,
          floatingActionButton: _destination == AppDestination.queue
              ? _StartStopButton(
                  onStart: () => context.read<ProcessStore>().start(),
                  onStop: () => context.read<ProcessStore>().stop(),
                )
              : null,
          // Kept over the queue rather than over the docked panel, where it
          // would cover a setting instead of the empty strip below the list.
          floatingActionButtonLocation: _showDockedEncoding
              ? const _ShiftedFabLocation(kEncodingPanelWidth)
              : FloatingActionButtonLocation.endFloat,
          // The body is a Scaffold of its own for one reason: a floating
          // snack bar is anchored to the *top* of a FloatingActionButton
          // when the Scaffold showing it has one, which puts a message
          // above the Start button rather than beside it. This one has no
          // button, so the message is placed against the bottom of the body
          // and lands at the button's own level.
          body: ScaffoldMessenger(
            key: bodyMessengerKey,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: DropTarget(
                enable: context.watch<QueueStore>().canImport,
                onDragEntered: (_) => setState(() => _dragging = true),
                onDragExited: (_) => setState(() => _dragging = false),
                onDragDone: (DropDoneDetails details) {
                  setState(() => _dragging = false);
                  _handleDrop(details);
                },
                child: Stack(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: switch (_destination) {
                            AppDestination.queue => QueuePage(
                              onOpenFiles: _openFiles,
                              onOpenFolder: _openFolder,
                              onRevealOutput: _revealOutput,
                              onPreview: _preview,
                            ),
                            AppDestination.settings => const AppSettingsPage(),
                            AppDestination.about => AboutPage(
                              version: _version,
                              onOpenLink: _openLink,
                              update: _update,
                            ),
                          },
                        ),
                        if (_showDockedEncoding)
                          DockedEncodingSettings(
                            onClose: () => _setDocked(false),
                          ),
                      ],
                    ),
                    if (_dragging) const _DropOverlay(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _titleFor(AppDestination destination, AppLocalizations strings) {
    return switch (destination) {
      AppDestination.queue => 'Silence SpeedUp',
      AppDestination.settings => strings.navSettings,
      AppDestination.about => strings.navAbout,
    };
  }

  List<Widget> _actionsFor(
    AppDestination destination,
    AppLocalizations strings,
  ) {
    if (destination != AppDestination.queue) return const <Widget>[];

    final ProcessStore process = context.watch<ProcessStore>();

    // Two actions, and neither is available anywhere else. The log toggle
    // that used to sit here is in the status strip at the bottom, beside the
    // console it opens, and emptying the queue is a queue action, so it is
    // on the queue's own toolbar.
    return <Widget>[
      _EncodingSettingsAction(
        open: _showDockedEncoding,
        onPressed: _toggleEncoding,
      ),
      IconButton(
        onPressed: process.isRunning
            ? () => context.read<ProcessStore>().setCompactMode(true)
            : null,
        icon: const Icon(Icons.picture_in_picture_alt_outlined),
        tooltip: strings.menuProgress,
      ),
      const SizedBox(width: 4),
    ];
  }
}

/// The way into the encoding settings, and the rates it would otherwise
/// duplicate.
///
/// The two speeds are what a user checks before every run, and a chip on the
/// queue that showed them was a second control doing the same job as this
/// one. Carrying them as the button's own label is one control instead of
/// two, and it costs the queue no room at all.
class _EncodingSettingsAction extends StatelessWidget {
  const _EncodingSettingsAction({required this.open, required this.onPressed});

  final bool open;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final ProcessingSettings settings = context
        .watch<PreferencesStore>()
        .settings;

    final String silence = settings.silenceSpeed.isRemove
        ? strings.settingsSpeedRemoveShort
        : settings.silenceSpeed.label;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: open
            ? strings.settingsEncodingHide
            : strings.settingsEncodingShow,
        child: TextButton.icon(
          onPressed: onPressed,
          icon: Icon(open ? Icons.tune : Icons.tune_outlined, size: 18),
          label: Text('$silence / ${settings.playbackSpeed.label}'),
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            backgroundColor: open ? scheme.secondaryContainer : null,
            foregroundColor: open
                ? scheme.onSecondaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// [FloatingActionButtonLocation.endFloat], moved inwards by [inset].
///
/// The docked settings panel is part of the body, so the Scaffold would
/// otherwise float the button over it.
class _ShiftedFabLocation extends FloatingActionButtonLocation {
  const _ShiftedFabLocation(this.inset);

  /// How far in from the trailing edge, past whatever is docked there.
  final double inset;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry geometry) {
    final double x = geometry.textDirection == TextDirection.rtl
        ? kFloatingActionButtonMargin + geometry.minInsets.left + inset
        : geometry.scaffoldSize.width -
              kFloatingActionButtonMargin -
              geometry.minInsets.right -
              geometry.floatingActionButtonSize.width -
              inset;

    // Deliberately not endFloat: that one lifts the button by the height of
    // a floating snack bar, and here a message is laid out beside the
    // button instead of under it. The one control the screen is for should
    // not jump because something was said.
    final double bottom =
        geometry.contentBottom -
        kFloatingActionButtonMargin -
        geometry.floatingActionButtonSize.height;
    final double lowest =
        geometry.scaffoldSize.height -
        geometry.floatingActionButtonSize.height -
        (geometry.scaffoldSize.height - geometry.contentBottom);

    return Offset(x, math.min(bottom, lowest));
  }
}

/// The one action the queue screen is for.
class _StartStopButton extends StatelessWidget {
  const _StartStopButton({required this.onStart, required this.onStop});

  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ProcessStore process = context.watch<ProcessStore>();
    final ColorScheme scheme = Theme.of(context).colorScheme;

    if (process.isRunning) {
      return FloatingActionButton.extended(
        key: startButtonKey,
        onPressed: onStop,
        backgroundColor: scheme.errorContainer,
        foregroundColor: scheme.onErrorContainer,
        icon: const Icon(Icons.stop),
        label: Text(strings.processStop),
      );
    }

    // Disabled rather than hidden: it should be obvious that Start is the
    // point of the screen even before anything is queued.
    final bool enabled = process.canStart;
    return FloatingActionButton.extended(
      key: startButtonKey,
      onPressed: enabled ? onStart : null,
      backgroundColor: enabled ? null : scheme.surfaceContainerHighest,
      foregroundColor: enabled ? null : Theme.of(context).disabledColor,
      icon: const Icon(Icons.play_arrow),
      label: Text(strings.processStart),
    );
  }
}

/// Full-surface hint shown while a drag is over the window.
class _DropOverlay extends StatelessWidget {
  const _DropOverlay();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Positioned.fill(
      child: IgnorePointer(
        child: ColoredBox(
          color: scheme.primary.withValues(alpha: 0.12),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.primary, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.file_download_outlined, color: scheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context).uiDropVideo,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
