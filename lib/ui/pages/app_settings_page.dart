// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../services/app_paths.dart';
import '../../state/preferences_store.dart';
import '../../state/process_store.dart';
import '../widgets/readable_width.dart';
import '../widgets/settings_tiles.dart';

/// How the application itself behaves: appearance, language, scratch space.
///
/// Deliberately short. Everything that decides how a video is encoded moved
/// to the panel beside the queue, where it is one click away from the files
/// it applies to; what is left here is set once and then left alone, which is
/// why it is worth a page of its own rather than a place in that panel.
class AppSettingsPage extends StatelessWidget {
  const AppSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final PreferencesStore preferences = context.watch<PreferencesStore>();

    return ReadableWidth(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: <Widget>[
          SettingsGroup(
            icon: Icons.palette_outlined,
            title: strings.settingsGroupApp,
            children: <Widget>[
              SegmentedSettingTile<ThemeMode>(
                title: strings.uiTheme,
                description: strings.helpTheme,
                selected: preferences.themeMode,
                segments: <ButtonSegment<ThemeMode>>[
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.system,
                    label: Text(strings.uiSystemMode),
                    icon: const Icon(Icons.brightness_auto_outlined),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.light,
                    label: Text(strings.uiLightMode),
                    icon: const Icon(Icons.light_mode_outlined),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.dark,
                    label: Text(strings.uiDarkMode),
                    icon: const Icon(Icons.dark_mode_outlined),
                  ),
                ],
                onChanged: (ThemeMode mode) =>
                    context.read<PreferencesStore>().setThemeMode(mode),
              ),
              SegmentedSettingTile<String>(
                title: strings.uiLanguage,
                description: strings.helpLanguage,
                // The empty string stands for "no pinned language".
                selected: preferences.preferredLocale?.languageCode ?? '',
                segments: <ButtonSegment<String>>[
                  ButtonSegment<String>(
                    value: '',
                    label: Text(strings.uiSystemMode),
                    icon: const Icon(Icons.language),
                  ),
                  const ButtonSegment<String>(
                    value: 'en',
                    label: Text('English'),
                  ),
                  const ButtonSegment<String>(
                    value: 'it',
                    label: Text('Italiano'),
                  ),
                ],
                onChanged: (String code) => context
                    .read<PreferencesStore>()
                    .setPreferredLocale(code.isEmpty ? null : Locale(code)),
              ),
            ],
          ),

          SettingsGroup(
            icon: Icons.folder_outlined,
            title: strings.preferenceWorkingDir,
            children: const <Widget>[_WorkingDirectoryTile()],
          ),
        ],
      ),
    );
  }
}

/// Where the intermediate fragments go, with its size and a way to empty it.
class _WorkingDirectoryTile extends StatefulWidget {
  const _WorkingDirectoryTile();

  @override
  State<_WorkingDirectoryTile> createState() => _WorkingDirectoryTileState();
}

class _WorkingDirectoryTileState extends State<_WorkingDirectoryTile> {
  int? _bytes;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final int bytes = await AppPaths.directoryBytes(
      context.read<PreferencesStore>().workingDirectory,
    );
    if (!mounted) return;
    setState(() => _bytes = bytes);
  }

  Future<void> _browse() async {
    final PreferencesStore preferences = context.read<PreferencesStore>();
    final String? chosen = await FilePicker.getDirectoryPath(
      dialogTitle: AppLocalizations.of(context).preferenceChooseWorkingDir,
      initialDirectory: preferences.workingDirectory,
    );
    if (chosen == null) return;
    await preferences.setWorkingDirectory(chosen);
    await _refresh();
  }

  Future<void> _clear() async {
    setState(() => _busy = true);
    await AppPaths.emptyDirectory(
      context.read<PreferencesStore>().workingDirectory,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final PreferencesStore preferences = context.watch<PreferencesStore>();
    final bool locked = context.watch<ProcessStore>().isRunning;
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            strings.preferenceWorkingDirHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          // The path gets a line to itself: it is long, and a button beside
          // it would either be cramped or push the row past the window.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              preferences.workingDirectory,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontFamilyFallback: const <String>[
                  'Consolas',
                  'Menlo',
                  'monospace',
                ],
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: locked ? null : _browse,
                icon: const Icon(Icons.folder_open_outlined, size: 18),
                label: Text(strings.preferenceChangeWorkingDir),
              ),
              TextButton.icon(
                onPressed: locked || _busy || _bytes == null || _bytes == 0
                    ? null
                    : _clear,
                icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                label: Text(strings.preferenceClearTemporary),
              ),
              Text(
                strings.preferenceTemporaryFiles(
                  _bytes == null ? '…' : _formatBytes(_bytes!),
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    const List<String> units = <String>['KB', 'MB', 'GB', 'TB'];
    double value = bytes / 1024;
    int unit = 0;
    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024;
      unit++;
    }
    return '${value.toStringAsFixed(value >= 10 ? 0 : 1)} ${units[unit]}';
  }
}
