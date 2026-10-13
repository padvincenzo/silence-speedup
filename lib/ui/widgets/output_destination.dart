// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../state/preferences_store.dart';
import '../../state/process_store.dart';

/// Where the finished files go, as a tile in the encoding settings.
///
/// It was a row of its own across the top of the queue, and before that it
/// was buried in the Electron build's Preferences window. Neither is right:
/// the destination is part of exporting, so it sits with the container and
/// the quality — one click away on a narrow window, and already on screen
/// beside the queue on a wide one, which is what the old row was for.
///
/// The path and its browse button appear only once a fixed folder is what is
/// wanted. A disabled field holding a path nothing is using is noise.
class OutputDestination extends StatefulWidget {
  const OutputDestination({super.key});

  @override
  State<OutputDestination> createState() => _OutputDestinationState();
}

class _OutputDestinationState extends State<OutputDestination> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  /// The value last written to the store, so a rebuild does not fight the user
  /// while they are typing.
  String _committed = '';

  @override
  void initState() {
    super.initState();
    _committed = context.read<PreferencesStore>().fixedDirectory;
    _controller.text = _committed;
    // A typed path is committed when the field loses focus as well as on
    // Enter: leaving the field and pressing Start should not lose the edit.
    _focus.addListener(() {
      if (!_focus.hasFocus) _commit();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _commit() {
    final String typed = _controller.text.trim();
    if (typed.isEmpty) {
      _controller.text = _committed;
      return;
    }
    if (typed == _committed) return;
    _committed = typed;
    context.read<PreferencesStore>().setFixedDirectory(typed);
  }

  Future<void> _browse() async {
    final PreferencesStore preferences = context.read<PreferencesStore>();
    final String? chosen = await FilePicker.getDirectoryPath(
      dialogTitle: AppLocalizations.of(context).outputChooseFolder,
      initialDirectory: _committed.isEmpty ? null : _committed,
    );
    if (chosen == null) return;
    _committed = chosen;
    _controller.text = chosen;
    await preferences.setFixedDirectory(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final PreferencesStore preferences = context.watch<PreferencesStore>();
    final bool locked = context.watch<ProcessStore>().isRunning;
    final bool alongside = preferences.exportsAlongsideSource;

    // Keep in step with changes made elsewhere, but never mid-edit.
    if (!_focus.hasFocus && preferences.fixedDirectory != _committed) {
      _committed = preferences.fixedDirectory;
      _controller.text = _committed;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            strings.outputFolder,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: locked ? theme.disabledColor : scheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            strings.helpOutputFolder,
            style: theme.textTheme.bodySmall?.copyWith(
              color: locked ? theme.disabledColor : scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          // Both choices on screen, with one of them pressed. As a single
          // chip it was a switch whose off state had no name: turning off
          // "beside the source" plainly meant something, but not what.
          //
          // Given the whole width and no icons, because the panel is 380
          // pixels wide: with icons it ran past the edge, and a control you
          // have to scroll sideways to read is worse than a short label.
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<OutputMode>(
              segments: <ButtonSegment<OutputMode>>[
                ButtonSegment<OutputMode>(
                  value: OutputMode.alongsideSource,
                  label: Text(
                    strings.outputAlongsideSource,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ButtonSegment<OutputMode>(
                  value: OutputMode.fixedDirectory,
                  label: Text(
                    strings.outputFixedDirectory,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              selected: <OutputMode>{preferences.outputMode},
              showSelectedIcon: false,
              onSelectionChanged: locked
                  ? null
                  : (Set<OutputMode> selection) => context
                        .read<PreferencesStore>()
                        .setOutputMode(selection.first),
            ),
          ),
          if (!alongside) ...<Widget>[
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: Tooltip(
                    message: _committed,
                    child: TextField(
                      controller: _controller,
                      focusNode: _focus,
                      enabled: !locked,
                      onSubmitted: (_) => _commit(),
                      style: theme.textTheme.bodySmall,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton.outlined(
                  onPressed: locked ? null : _browse,
                  icon: const Icon(Icons.folder_open_outlined),
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  tooltip: strings.outputChooseFolder,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
