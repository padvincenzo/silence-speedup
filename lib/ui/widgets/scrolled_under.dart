// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'package:flutter/material.dart';

/// A strip that lifts once content starts passing beneath it.
///
/// Material's own scrolled-under effect belongs to the app bar, and an app
/// bar takes it for any scroll notification that reaches it — with no regard
/// for whether the content is going under *it*. On these screens it is not:
/// there is a toolbar, a title bar or a heading in between, and that is what
/// the rows disappear behind. So the app bar is told to ignore the scroll and
/// the strip below it carries the shadow.
///
/// A rule while nothing is under it, a shadow once something is: a shadow
/// over nothing is not a seam, and both at once is one too many.
class ScrolledUnder extends StatelessWidget {
  const ScrolledUnder({
    super.key,
    required this.lifted,
    required this.child,
  });

  /// Whether anything is currently scrolled under this strip.
  final bool lifted;

  final Widget child;

  /// True when [notification] says its scrollable has left its own start.
  ///
  /// Handed a notification from a `NotificationListener<ScrollNotification>`
  /// around the scrollable in question. Nested scrollables are ignored: a
  /// horizontally scrolling row of chips inside the strip is not content
  /// passing under it.
  static bool isScrolled(ScrollNotification notification) =>
      notification.depth == 0 && notification.metrics.extentBefore > 0;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: scheme.shadow,
      // Material animates a change of elevation, which is what makes the
      // shadow arrive as a fade rather than a jump.
      elevation: lifted ? 3 : 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          child,
          if (!lifted) Divider(height: 1, color: scheme.outlineVariant),
        ],
      ),
    );
  }
}
