// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'package:flutter/material.dart';

/// Widest a page of settings, cards or prose is allowed to get.
///
/// A window can be two thousand pixels across; a paragraph read at that
/// width loses the reader between the end of one line and the start of the
/// next, and a row with a label at one edge and its control at the other
/// makes the eye cross the whole monitor to connect the two.
///
/// Not every page wants this. The queue is a working list and the silence
/// timeline is more precise the wider it gets: both earn their width.
const double kReadableWidth = 840;

/// Holds its child to a readable width, centred in whatever is left.
class ReadableWidth extends StatelessWidget {
  const ReadableWidth({
    super.key,
    required this.child,
    this.maxWidth = kReadableWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
