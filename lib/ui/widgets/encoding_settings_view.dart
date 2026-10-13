// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../l10n/labels.dart';
import '../../models/options.dart';
import '../../models/processing_settings.dart';
import '../../state/preferences_store.dart';
import '../../state/process_store.dart';
import '../messages.dart';
import 'collapsible_group.dart';
import 'noise_threshold_tile.dart';
import 'output_destination.dart';
import 'settings_tiles.dart';

/// Everything that decides how a video is encoded.
///
/// These are the settings someone changes between one run and the next, so
/// they are not a place to navigate to: the same view is shown docked beside
/// the queue on a wide window and as a side sheet on a narrow one. Whatever
/// is application-level — theme, language, scratch space — lives on the app
/// settings page instead, because it is set once and then forgotten.
///
/// The groups collapse, and a collapsed one states what was changed inside
/// it. Thirteen controls do not fit a panel beside the queue, and most of
/// them are set once; what a user wants at a glance is not every value but
/// the ones that are no longer the default.
class EncodingSettingsView extends StatelessWidget {
  const EncodingSettingsView({super.key, this.bottomInset = 32});

  /// Room left under the last control.
  final double bottomInset;

  /// Keys the open groups are remembered under. Stored, so they must not be
  /// renamed lightly.
  static const String groupSpeed = 'speed';
  static const String groupAudio = 'audio';
  static const String groupDetection = 'detection';
  static const String groupExport = 'export';
  static const String groupPreview = 'preview';

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final PreferencesStore preferences = context.watch<PreferencesStore>();
    final ProcessingSettings settings = preferences.settings;
    final bool locked = context.watch<ProcessStore>().isRunning;

    void update(ProcessingSettings next) =>
        context.read<PreferencesStore>().updateSettings(next);

    final Set<String> open = preferences.openEncodingGroups;
    void toggle(String group, bool expanded) =>
        context.read<PreferencesStore>().setEncodingGroupOpen(group, expanded);

    return CustomScrollView(
      slivers: <Widget>[
        if (locked)
          SliverToBoxAdapter(
            child: LockedNotice(message: strings.ffmpegAlreadyRunning),
          ),

        ...collapsibleGroupSlivers(
          context: context,
          icon: Icons.bolt,
          title: strings.settingsGroupSpeed,
          summary: speedChanges(settings, strings),
          expanded: open.contains(groupSpeed),
          onExpanded: (bool value) => toggle(groupSpeed, value),
          children: <Widget>[
            SliderSettingTile(
              title: strings.settingsSilenceSpeed,
              description: strings.helpSilenceSpeed,
              valueLabel: speedText(settings.silenceSpeed, strings),
              enabled: !locked,
              slider: IndexSlider(
                value: settings.silenceSpeedIndex,
                max: kSpeedOptions.length - 1,
                label: speedText(settings.silenceSpeed, strings),
                onChanged: locked
                    ? null
                    : (int index) =>
                          update(settings.copyWith(silenceSpeedIndex: index)),
              ),
            ),
            SliderSettingTile(
              title: strings.settingsPlaybackSpeed,
              description: strings.helpPlaybackSpeed,
              valueLabel: speedText(settings.playbackSpeed, strings),
              enabled: !locked,
              slider: IndexSlider(
                // Stops one short of `remove`: dropping the spoken parts would
                // leave nothing behind.
                value: settings.playbackSpeedIndex,
                max: kLastKeptSpeedIndex,
                label: speedText(settings.playbackSpeed, strings),
                onChanged: locked
                    ? null
                    : (int index) =>
                          update(settings.copyWith(playbackSpeedIndex: index)),
              ),
            ),
          ],
        ),

        ...collapsibleGroupSlivers(
          context: context,
          icon: Icons.graphic_eq,
          title: strings.settingsGroupDetection,
          summary: detectionChanges(settings, strings),
          expanded: open.contains(groupDetection),
          onExpanded: (bool value) => toggle(groupDetection, value),
          children: <Widget>[
            NoiseThresholdTile(
              thresholdDb: settings.thresholdDb,
              enabled: !locked,
              onChanged: locked
                  ? null
                  : (int db) => update(settings.copyWith(thresholdDb: db)),
            ),
            SliderSettingTile(
              title: strings.settingsSilenceMinDuration,
              description: strings.helpSilenceMinDuration,
              valueLabel: strings.settingsSecondsValue(
                settings.silenceMinDuration,
              ),
              enabled: !locked,
              slider: Slider(
                value: settings.silenceMinDuration.clamp(
                  kSilenceDurationMin,
                  kSilenceDurationMax,
                ),
                min: kSilenceDurationMin,
                max: kSilenceDurationMax,
                divisions: _durationDivisions,
                label: strings.settingsSecondsValue(
                  settings.silenceMinDuration,
                ),
                onChanged: locked
                    ? null
                    : (double value) =>
                          update(settings.copyWith(silenceMinDuration: value)),
              ),
            ),
            SliderSettingTile(
              title: strings.settingsSilenceMargin,
              description: strings.helpSilenceMargin,
              valueLabel: strings.settingsSecondsValue(settings.silenceMargin),
              enabled: !locked,
              slider: Slider(
                value: settings.silenceMargin.clamp(
                  kSilenceDurationMin,
                  kSilenceDurationMax,
                ),
                min: kSilenceDurationMin,
                max: kSilenceDurationMax,
                divisions: _durationDivisions,
                label: strings.settingsSecondsValue(settings.silenceMargin),
                onChanged: locked
                    ? null
                    : (double value) =>
                          update(settings.copyWith(silenceMargin: value)),
              ),
            ),
            _FilterPreview(settings: settings),
          ],
        ),

        ...collapsibleGroupSlivers(
          context: context,
          icon: Icons.headphones_outlined,
          title: strings.settingsGroupAudio,
          summary: audioChanges(settings, strings),
          expanded: open.contains(groupAudio),
          onExpanded: (bool value) => toggle(groupAudio, value),
          children: <Widget>[
            SwitchSettingTile(
              title: strings.settingsAudioTracks,
              description: strings.helpAudioTracks,
              value: settings.keepAllAudioTracks,
              onChanged: locked
                  ? null
                  : (bool value) =>
                        update(settings.copyWith(keepAllAudioTracks: value)),
            ),
            SwitchSettingTile(
              title: strings.settingsMuteSilences,
              description: strings.helpMuteSilences,
              value: settings.mutesSilence,
              onChanged: locked || settings.dropsSilence
                  ? null
                  : (bool value) =>
                        update(settings.copyWith(muteSilences: value)),
            ),
            DropdownSettingTile<int>(
              title: strings.settingsAudioRate,
              description: strings.helpAudioRate,
              value: settings.audioRateIndex,
              items: indexItems(kAudioRates, strings),
              onChanged: locked
                  ? null
                  : (int? index) => index == null
                        ? null
                        : update(settings.copyWith(audioRateIndex: index)),
            ),
          ],
        ),

        ...collapsibleGroupSlivers(
          context: context,
          icon: Icons.movie_creation_outlined,
          title: strings.settingsGroupExport,
          // The destination is not part of ProcessingSettings — it is a
          // preference of its own — so its summary is built here, where the
          // store is at hand, and put in front of the encoder's.
          summary: <String>[
            if (!preferences.exportsAlongsideSource)
              '${strings.outputFolder} '
                  '${p.basename(preferences.fixedDirectory)}',
            ...exportChanges(settings, strings),
          ],
          expanded: open.contains(groupExport),
          onExpanded: (bool value) => toggle(groupExport, value),
          children: <Widget>[
            const OutputDestination(),
            DropdownSettingTile<String>(
              title: strings.settingsFormat,
              description: strings.helpFormat,
              value: settings.outputFormat,
              items: kFormats
                  .map(
                    (LabeledOption format) => DropdownMenuItem<String>(
                      value: format.value,
                      child: Text(optionText(format, strings)),
                    ),
                  )
                  .toList(),
              onChanged: locked
                  ? null
                  : (String? format) => format == null
                        ? null
                        : update(settings.copyWith(outputFormat: format)),
            ),
            SliderSettingTile(
              title: strings.settingsCrf,
              description: strings.helpCrf,
              valueLabel: '${settings.crf}',
              enabled: !locked,
              slider: Slider(
                value: settings.crf.toDouble(),
                min: kCrfMin.toDouble(),
                max: kCrfMax.toDouble(),
                divisions: kCrfMax - kCrfMin,
                label: '${settings.crf}',
                onChanged: locked
                    ? null
                    : (double value) =>
                          update(settings.copyWith(crf: value.round())),
              ),
            ),
            DropdownSettingTile<int>(
              title: strings.settingsFps,
              description: strings.helpFps,
              value: settings.fpsIndex,
              items: indexItems(kFpsOptions, strings),
              onChanged: locked
                  ? null
                  : (int? index) => index == null
                        ? null
                        : update(settings.copyWith(fpsIndex: index)),
            ),
            DropdownSettingTile<int>(
              title: strings.settingsPreset,
              description: strings.helpPreset,
              value: settings.presetIndex,
              items: indexItems(kPresets, strings),
              onChanged: locked
                  ? null
                  : (int? index) => index == null
                        ? null
                        : update(settings.copyWith(presetIndex: index)),
            ),
            DropdownSettingTile<int>(
              title: strings.settingsTune,
              description: strings.helpTune,
              value: settings.tuneIndex,
              items: indexItems(kTunes, strings),
              onChanged: locked
                  ? null
                  : (int? index) => index == null
                        ? null
                        : update(settings.copyWith(tuneIndex: index)),
            ),
          ],
        ),

        ...collapsibleGroupSlivers(
          context: context,
          icon: Icons.play_circle_outline,
          title: strings.settingsGroupPreview,
          summary: previewChanges(settings, strings),
          expanded: open.contains(groupPreview),
          onExpanded: (bool value) => toggle(groupPreview, value),
          children: <Widget>[
            DropdownSettingTile<int>(
              title: strings.settingsPreviewDuration,
              description: strings.helpPreviewDuration,
              value: settings.previewIndex,
              width: 120,
              items: List<DropdownMenuItem<int>>.generate(
                kPreviewDurations.length,
                (int index) => DropdownMenuItem<int>(
                  value: index,
                  child: Text(strings.previewSeconds(kPreviewDurations[index])),
                ),
              ),
              onChanged: locked
                  ? null
                  : (int? index) => index == null
                        ? null
                        : update(settings.copyWith(previewIndex: index)),
            ),
          ],
        ),

        // The reset belongs here rather than with the application settings:
        // what it puts back are the encoding settings above it. It is an
        // action, not a setting, so it is a small button and not a tile --
        // as a tile its title was the largest text in the panel, louder
        // than the groups it undoes.
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: locked ? null : () => _confirmReset(context),
                icon: const Icon(Icons.restart_alt, size: 18),
                label: Text(strings.settingsReset),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: bottomInset)),
      ],
    );
  }

  static const int _durationDivisions =
      (kSilenceDurationMax - kSilenceDurationMin) ~/ kSilenceDurationStep;

  /// Asks before undoing every encoding setting at once.
  ///
  /// There is no undo for it, and the button sits under the groups it would
  /// clear, which is exactly where a stray click lands.
  static Future<void> _confirmReset(BuildContext context) async {
    final AppLocalizations strings = AppLocalizations.of(context);
    final PreferencesStore preferences = context.read<PreferencesStore>();

    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            icon: const Icon(Icons.restart_alt),
            title: Text(strings.settingsResetProcessing),
            content: Text(strings.settingsResetProcessingHint),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(strings.uiCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(strings.settingsReset),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;
    await preferences.resetSettings();
    if (!context.mounted) return;
    showAppMessage(context, strings.settingsResetDone);
  }
}

/// Turns an option catalogue into dropdown entries addressed by index.
List<DropdownMenuItem<int>> indexItems(
  List<LabeledOption> options,
  AppLocalizations strings,
) {
  return List<DropdownMenuItem<int>>.generate(
    options.length,
    (int index) => DropdownMenuItem<int>(
      value: index,
      child: Text(optionText(options[index], strings)),
    ),
  );
}

/// Shows the `silencedetect` filter the current settings produce.
///
/// The detection window is deliberately wider than the minimum duration — by
/// twice the margin — and seeing the real filter string makes that visible
/// instead of surprising.
class _FilterPreview extends StatelessWidget {
  const _FilterPreview({required this.settings});

  final ProcessingSettings settings;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      // Room underneath as well: it is the last thing in its group, and
      // without it the card sat against the heading of the next one.
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            AppLocalizations.of(context).settingsFilterPreview,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          SelectableText(
            settings.silenceDetectFilter,
            style: TextStyle(
              fontFamily: 'monospace',
              fontFamilyFallback: const <String>[
                'Consolas',
                'Menlo',
                'monospace',
              ],
              fontSize: 12,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
