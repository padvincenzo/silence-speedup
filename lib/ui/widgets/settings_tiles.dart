// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'package:flutter/material.dart';

/// Building blocks for the settings page.
///
/// Every setting carries its explanation as a visible subtitle rather than a
/// tooltip. The Electron modal hid the same sentences behind a help icon, which
/// meant nobody read them; on a page there is room to simply say what a setting
/// does.

/// A titled group of settings.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: 4,
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 18, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }
}

/// A setting whose control needs the full width, with the current value shown
/// beside the title so it stays readable while dragging.
class SliderSettingTile extends StatelessWidget {
  const SliderSettingTile({
    super.key,
    required this.title,
    required this.valueLabel,
    required this.slider,
    this.description,
    this.enabled = true,
  });

  final String title;
  final String valueLabel;
  final Widget slider;
  final String? description;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color titleColour = enabled
        ? theme.colorScheme.onSurface
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
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: titleColour,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _ValueBadge(text: valueLabel, enabled: enabled),
            ],
          ),
          if (description != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: enabled
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.disabledColor,
                ),
              ),
            ),
          slider,
        ],
      ),
    );
  }
}

class _ValueBadge extends StatelessWidget {
  const _ValueBadge({required this.text, required this.enabled});

  final String text;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

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
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: enabled
              ? scheme.onSecondaryContainer
              : Theme.of(context).disabledColor,
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// A slider whose stops are indexes into a list.
class IndexSlider extends StatelessWidget {
  const IndexSlider({
    super.key,
    required this.value,
    required this.max,
    required this.onChanged,
    this.min = 0,
    this.label,
  });

  final int value;
  final int min;
  final int max;
  final String? label;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Slider(
      value: value.clamp(min, max).toDouble(),
      min: min.toDouble(),
      max: max.toDouble(),
      divisions: max > min ? max - min : null,
      label: label,
      onChanged: onChanged == null
          ? null
          : (double raw) => onChanged!(raw.round()),
    );
  }
}

/// A boolean setting.
class SwitchSettingTile extends StatelessWidget {
  const SwitchSettingTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.description,
  });

  final String title;
  final String? description;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title),
      subtitle: description == null ? null : Text(description!),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

/// A setting picked from a list.
///
/// Laid out by hand rather than as a [ListTile] trailing widget: a form field
/// in that slot fights the tile over its own height.
class DropdownSettingTile<T> extends StatelessWidget {
  const DropdownSettingTile({
    super.key,
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
    this.description,
    this.width = 200,
  });

  final String title;
  final String? description;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final double width;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool enabled = onChanged != null;

    final Widget label = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: enabled ? theme.colorScheme.onSurface : theme.disabledColor,
          ),
        ),
        if (description != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: enabled
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.disabledColor,
              ),
            ),
          ),
      ],
    );

    final Widget field = DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      isDense: true,
      isExpanded: true,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 10),
      // The same tile has to work across a settings page and a side panel
      // barely wider than the field itself, so beyond a point the control
      // moves under its label rather than squeezing it.
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (constraints.maxWidth < width + _minimumLabelWidth) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[label, const SizedBox(height: 10), field],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(child: label),
              const SizedBox(width: 16),
              SizedBox(width: width, child: field),
            ],
          );
        },
      ),
    );
  }

  /// Room a title and its explanation need before the field is worth putting
  /// beside them rather than under them.
  static const double _minimumLabelWidth = 220;
}

/// A small set of mutually exclusive choices, shown inline.
class SegmentedSettingTile<T> extends StatelessWidget {
  const SegmentedSettingTile({
    super.key,
    required this.title,
    required this.selected,
    required this.segments,
    required this.onChanged,
    this.description,
  });

  final String title;
  final String? description;
  final T selected;
  final List<ButtonSegment<T>> segments;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: theme.textTheme.bodyLarge),
          if (description != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<T>(
                segments: segments,
                selected: <T>{selected},
                showSelectedIcon: false,
                onSelectionChanged: (Set<T> selection) =>
                    onChanged(selection.first),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Says why the settings are read-only, instead of leaving greyed-out
/// controls to be puzzled over.
class LockedNotice extends StatelessWidget {
  const LockedNotice({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.lock_outline, size: 18, color: scheme.onTertiaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onTertiaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
