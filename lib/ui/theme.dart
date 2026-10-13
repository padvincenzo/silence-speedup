// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'package:flutter/material.dart';

/// Seed taken from the Bootstrap primary the Electron UI was built on, so the
/// two versions of the app still look related.
const Color _seed = Color(0xFF0D6EFD);

/// Colour reserved for finished rows.
const Color _goColor = Color(0xFF198754);

ThemeData buildAppTheme(Brightness brightness) {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: _seed,
    brightness: brightness,
  );

  // The text theme is needed to build the tile styles below, and asking the
  // framework for it is the only way to get the platform's own typography.
  final TextTheme text = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
  ).textTheme;

  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: scheme.surface,

    // A shadow, not a tint, once a list scrolls under the bar.
    //
    // Material 3 would tint the background instead, and that tint is folded
    // into the colour when the bar is built: the elevation animates but the
    // colour does not, so the bar turns grey in a single frame the moment
    // scrolling starts. With the tint suppressed the only thing that changes
    // is the elevation, which does animate — the bar keeps its colour and
    // grows a soft shadow.
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: scheme.shadow,
      elevation: 0,
      scrolledUnderElevation: 3,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
    ),

    navigationDrawerTheme: NavigationDrawerThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      elevation: 1,
      indicatorColor: scheme.secondaryContainer,
    ),

    // The settings page is a long list of tiles; a tighter line height keeps a
    // group readable as a group.
    //
    // The subtitle style has to be a complete one taken from the text theme.
    // ListTile installs it as a DefaultTextStyle, which *replaces* the
    // ambient style rather than merging with it: a partial TextStyle here
    // leaves the subtitle with no colour at all, which paints it black on a
    // dark surface and makes every description invisible.
    listTileTheme: ListTileThemeData(
      minVerticalPadding: 8,
      subtitleTextStyle: text.bodySmall!.copyWith(
        color: scheme.onSurfaceVariant,
        height: 1.35,
      ),
    ),

    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),

    sliderTheme: const SliderThemeData(
      trackHeight: 4,
      showValueIndicator: ShowValueIndicator.onDrag,
    ),

    inputDecorationTheme: const InputDecorationTheme(
      isDense: true,
      border: OutlineInputBorder(),
    ),

    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: const WidgetStatePropertyAll<TextStyle>(
          TextStyle(fontSize: 13),
        ),
      ),
    ),

    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
    ),

    cardTheme: const CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
  );
}

/// Palette for the queue's status column, derived from the active scheme so it
/// stays legible in both themes.
class StatusPalette {
  const StatusPalette(this._scheme);

  final ColorScheme _scheme;

  static StatusPalette of(BuildContext context) =>
      StatusPalette(Theme.of(context).colorScheme);

  Color get success => Color.alphaBlend(
    _goColor.withValues(alpha: _scheme.brightness == Brightness.dark ? 0.6 : 1),
    _scheme.surface,
  );

  Color get failure => _scheme.error;

  Color get warning => Color.alphaBlend(
    const Color(0xFFFFC107).withValues(alpha: 0.9),
    _scheme.surface,
  );

  Color get busy => _scheme.primary;

  Color get idle => _scheme.onSurfaceVariant;

  /// Tint used behind a completed or failed row.
  Color rowTint(Color base) => base.withValues(alpha: 0.10);
}
