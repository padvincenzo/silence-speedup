// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../l10n/labels.dart';
import '../../models/audio_levels.dart';
import '../../models/media_entry.dart';
import '../../models/options.dart';
import '../../state/process_store.dart';
import '../../state/queue_store.dart';

/// The one setting that cannot be chosen by reading its own label.
///
/// How loud a room is allowed to be before it stops counting as silence
/// depends on the recording, not on taste: a threshold under the hiss finds
/// no pauses at all, one over the speech makes the whole video a pause. It
/// used to be three named steps twenty decibels apart, which is neither
/// precise enough to aim with nor informative enough to aim by.
///
/// So it is a scale in decibels — the unit FFmpeg documents and the unit any
/// other audio tool would show — and, on request, the app measures a video
/// and says where its hiss and its voice actually fall. Choosing then means
/// putting a number between two known numbers, which is a different act from
/// guessing.
class NoiseThresholdTile extends StatelessWidget {
  const NoiseThresholdTile({
    super.key,
    required this.thresholdDb,
    required this.enabled,
    required this.onChanged,
  });

  final int thresholdDb;
  final bool enabled;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    final Color labelColour = enabled ? scheme.onSurface : theme.disabledColor;
    final Color quietColour = enabled
        ? scheme.onSurfaceVariant
        : theme.disabledColor;

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  strings.settingsBackgroundNoise,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: labelColour,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _Badge(
                text: strings.settingsNoiseValue(thresholdDb),
                enabled: enabled,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              strings.helpBackgroundNoise,
              style: theme.textTheme.bodySmall?.copyWith(color: quietColour),
            ),
          ),
          Slider(
            value: thresholdDb.toDouble().clamp(
              kThresholdDbMin.toDouble(),
              kThresholdDbMax.toDouble(),
            ),
            min: kThresholdDbMin.toDouble(),
            max: kThresholdDbMax.toDouble(),
            divisions: kThresholdDbMax - kThresholdDbMin,
            label: strings.settingsNoiseValue(thresholdDb),
            onChanged: onChanged == null
                ? null
                : (double value) => onChanged!(value.round()),
          ),
          // The named steps this used to have, kept as what the numbers
          // mean: a reading of "-34 dB" says nothing on its own to someone
          // who has not measured a room before.
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                for (final NoiseAnchor anchor in kNoiseAnchors)
                  Text(
                    localizedLabel(anchor.label, strings),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: quietColour,
                    ),
                  ),
              ],
            ),
          ),
          _Measurement(enabled: enabled, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// What the app knows about an actual file, and how to find out.
class _Measurement extends StatelessWidget {
  const _Measurement({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    final ProcessStore process = context.watch<ProcessStore>();
    final QueueStore queue = context.watch<QueueStore>();

    // The first file that can be processed: with a queue of takes from one
    // camera, any of them answers the question, and asking which would be a
    // question about nothing.
    final MediaEntry? subject = queue.processableEntries.isEmpty
        ? null
        : queue.processableEntries.first;

    if (subject == null) {
      return const SizedBox(height: 4);
    }

    if (process.isMeasuring) {
      return _Line(
        icon: Icons.hourglass_empty,
        text: strings.settingsNoiseMeasuring(subject.name),
      );
    }

    return ListenableBuilder(
      listenable: subject,
      builder: (BuildContext context, Widget? child) {
        final AudioLevels? levels = subject.levels;

        if (levels == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Named, because the queue may hold several and the answer is
              // about one of them.
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: enabled
                      ? () => context.read<ProcessStore>().measure(subject)
                      : null,
                  icon: const Icon(Icons.graphic_eq, size: 18),
                  label: Text(
                    strings.settingsNoiseMeasure(subject.name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // A measurement that found nothing says so. It used to put the
              // button back and look like a press that had not registered.
              if (process.measureFailed)
                _Line(
                  icon: Icons.warning_amber_outlined,
                  text: strings.settingsNoiseFailed,
                ),
            ],
          );
        }

        if (!levels.isUsable) {
          return _Line(
            icon: Icons.warning_amber_outlined,
            text: strings.settingsNoiseTooClose,
          );
        }

        // The reading and the number it points to are one answer, so they
        // are one card: the suggestion means nothing without the two
        // figures it sits between.
        final int suggestion = levels.suggestedThresholdDb;
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      Icons.graphic_eq,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        strings.settingsNoiseMeasured(
                          subject.name,
                          levels.noiseFloorDb.round(),
                          levels.rmsDb.round(),
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(
                    onPressed: enabled && onChanged != null
                        ? () => onChanged!(suggestion)
                        : null,
                    child: Text(strings.settingsNoiseUse(suggestion)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The value, in the same pill the other settings use.
class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.enabled});

  final String text;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 64),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: enabled
            ? scheme.secondaryContainer
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 1,
        style: theme.textTheme.labelMedium?.copyWith(
          color: enabled ? scheme.onSecondaryContainer : theme.disabledColor,
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
