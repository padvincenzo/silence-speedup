// This file is part of Silence SpeedUp, a Flutter app that speeds up your
// videos by speeding up (or removing) silences, using FFmpeg.
//
// Author: Vincenzo Padula <padvincenzo@gmail.com>
// License: GNU GPL v3 or later <http://www.gnu.org/copyleft/gpl.html>

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// A stretch of a source file, in seconds from its start.
///
/// A run normally covers the whole file. A preview covers one of these
/// instead, which is what lets a sample be produced without first cutting a
/// clip out: FFmpeg is simply asked to read only this part.
@immutable
class TimeWindow {
  const TimeWindow({required this.start, required this.end});

  final double start;
  final double end;

  double get duration => end - start;

  /// The window a preview should sample.
  ///
  /// It starts roughly a third of the way in, because the opening of a
  /// recording is the least representative part of it — intros, titles and
  /// someone settling down before they start talking.
  static TimeWindow preview({
    required double mediaSeconds,
    required double seconds,
  }) {
    final double length = math.min(seconds, mediaSeconds);
    final double latestStart = math.max(0, mediaSeconds - length);
    final double start = math.min(latestStart, (mediaSeconds - length) / 3);
    return TimeWindow(start: math.max(0, start), end: math.max(0, start) + length);
  }

  @override
  String toString() => 'TimeWindow(${start.toStringAsFixed(2)}'
      '-${end.toStringAsFixed(2)})';
}
